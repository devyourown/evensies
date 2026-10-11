# Phase 6 design — People

Friends are hidden two-person groups (`kind: "friend"`). Because of that, non-group expenses reuse the existing event log, outbox, both appliers, export and Settle up. Everything shown per person (the Friends tab, the overall card, reminders) is the sum of each group's Settle up transfers that involve you, from Phase 4's `groupTransfers`. There is no second ledger.

This phase also brings **the one storage and image pipeline** that avatars, receipts (Phase 7) and covers (Phase 10) share, and the Settle up polish (record any payment, edit a payment).

**Cost: 0.** Files go on the server's existing disk, and FCM is free. Rough size: 2–3 sessions.

### What users get
1. **Friends tab** next to Groups (bottom navigation).
   - Everyone you share a group with appears, plus friends you added.
   - Each row shows the photo or initials, the name, and your balance with them across everything: "owes you €12.00" or "you owe $5.00". With several currencies, the largest is shown, followed by `*`.
   - Placeholders from normal groups appear only while you have a balance with them, with the group name as a subtitle.
2. **Filters and settled sections** on both tabs.
   - A chip row: All · Owes me · I owe.
   - People and groups that are settled in every currency collapse under **Settled up (n)**, closed by default.
3. **Overall card** at the top of both tabs.
   - "You are owed €42.10 · $15.00" and "You owe €8.00", one line per currency.
   - Plus "≈ €61.20 overall" in your home currency (Phase 4).
4. **Add a friend:**
   - share your friend link or QR code (`…/f/K7P4QX`);
   - type a friend's code (the existing "Enter a code" box accepts group and friend codes);
   - or "Someone not on Evensies yet": enter a name, add expenses right away, and invite them later.

   Adding the same person twice, from either side, gives the same friend. The group invite sheet shows a QR code for `/j/{code}` too.
5. **Non-group expenses.**
   - **Add expense** on Home first asks *with whom*: a friend or a group.
   - A friend's page shows the balance, a breakdown ("Non-group: Ben owes you €4.00 · Rome trip: you owe Ben €3.00"), the non-group expenses, and **Settle up**, **Remind** and **Add expense**.
   - It works offline once the friend exists.
6. **Settle up with a friend across everything.**
   - One sheet with every line between you two.
   - Pay the net per currency with their Phase 1 methods.
   - One tap records a payment in every group involved.
7. **Record any payment and edit it.**
   - **Record a payment** on Settle up: any payer, any receiver, any amount, any date.
   - Tapping a payment you sent or received opens the same sheet, where you can edit or delete it.
8. **Move an expense** between a group and a friend, or between two groups, by changing *With* while editing.
9. **Profile photo:** Settings → tap your picture → Take photo / Choose from library / Remove. Only people who share a group with you can see it.
10. **Remind to pay.**
    - **Remind** sends a push: "Anna sent a reminder · You owe Anna €15.00".
    - At most once a day per person, and the recipient can turn reminders off.
    - People not on Evensies get Phase 1's **Request** text.

### How (server)
- **Storage and images** (shared by Phases 6, 7 and 10).
  - **`storage/FileStore.kt`:**
    - `write(key, bytes)`: a temp file in the same directory, then `Files.move(…, ATOMIC_MOVE)`;
    - `path(key): Path?`;
    - `delete(key)`.

    Files live under `EVENSIES_STORAGE_DIR` (default `./data`; the Dockerfile sets `ENV EVENSIES_STORAGE_DIR=/data`, and `deploy/docker-compose.yml` mounts `./data:/data`). Keys are built only from UUIDs Spring has already parsed, so path traversal is not possible. Layout:
    - `avatars/{userId}.jpg`
    - `attachments/{groupId}/{id}.jpg` and `{id}_thumb.jpg` (Phase 7)
    - `covers/{groupId}/{coverId}.jpg` (Phase 10)

    `ponytail:` local disk only; move to S3-compatible storage (proposed with its cost) when the disk passes about 70%.
  - **`storage/Jpeg.kt` `clean(bytes, maxEdge): ByteArray`** (about 50 lines, no image library) walks JPEG markers without decoding pixels:
    - requires SOI, else `NOT_JPEG`;
    - reads the size from SOFn and rejects an edge over `maxEdge` (`IMAGE_TOO_LARGE`);
    - drops APP1–APP13, APP15 and COM (EXIF incl. GPS, XMP, IPTC, embedded thumbnails);
    - keeps APP0 and APP14;
    - handles progressive JPEGs (after SOS, `FF00` and `FFD0`–`FFD7` are data);
    - stops at EOI, dropping trailing bytes.

    **The server never decodes untrusted pixels**: the app has already re-encoded the image.
  - **Errors** for every upload:
    - 400 `NOT_JPEG`;
    - 400 `IMAGE_TOO_LARGE` (pixels);
    - 413 `TOO_LARGE` (bytes; `GlobalExceptionHandler` maps `MaxUploadSizeExceededException` from the existing 5 MB multipart cap, which today falls through to 500).
  - **Downloads** go through the API with the Bearer token, with `X-Content-Type-Options: nosniff`.
  - **Backup:** `./data` is backed up with the DB dumps. At release, Hyojun adds `deploy/data` to the host's rclone cron; self-hosters back up `./data`.
- **Friend group** = a `groups` row with `kind = 'friend'`.
  - It has exactly two members and a name like "Anna & Ben", which shows only in exports. It still gets an invite code, which placeholder claims need.
  - Only `POST /friends` creates friend groups. The server builds the events: `group.created {…, kind: "friend"}`, then two `member.added`.
  - It pushes them with `EventService.push` (trusted, no validator), then calls `PushNotifier.notify(groupId, caller, stored)`. The friend gets a visible `friend_added` push plus the sync data, so their app adopts the new group.
- **`GroupState` gains `kind`** (applier rule 13). The validator, `Activity.meta` and the push title read `state.kind`, so there is one source.
- **Dedupe.** `friendships(user_lo, user_hi) → group_id` holds one canonical friend group per pair of users. `POST /friends` (by code or userId) runs in one transaction:
  1. `SELECT id FROM users WHERE id IN (:a, :b) ORDER BY id FOR UPDATE`.
  2. If the pair row exists, return its group.
  3. Otherwise insert the group, push the events and insert the pair row.

  `user_lo` is the smaller id **as a lowercase string**, which matches Postgres uuid order. Don't use Kotlin `UUID.compareTo`, which compares signed longs.
- **Placeholder friend** (`POST /friends {name}`): a friend group with me plus a placeholder, and no pair row yet.
  - The friend claims it through the group's normal `/j/{code}` link (`member.linked`). After a claim in a friend group, `GroupService.join` inserts the pair row with `ON CONFLICT DO NOTHING`.
  - If the pair already had a group, both stay. The app shows them as one person, and `POST /friends` keeps returning the canonical one.
  - Joining a friend group as a *new* member → 409 `LIMIT_EXCEEDED`.
- **Friend codes** live in `users.friend_code`.
  - 6 characters from `InviteCodes`, created by the first `GET /me/friend-code`, and rotatable.
  - Code generation checks both `users.friend_code` and `groups.invite_code`, and `GroupService.newInviteCode` gets the same two-table check.
  - All code lookups (`GET /friend-invites/{code}`, `/f/{code}`, `POST /friends {code}`) share **one** per-IP limiter with the invite endpoints. The limiter moves from an `InviteController` field to a bean.
- **Validator** (rules read `state.kind`):
  - In a friend group, `member.added` beyond 2 members → 409 `LIMIT_EXCEEDED`; `member.removed` → 400 `VALIDATION`; a `kind` key in `group.updated` → 400 `VALIDATION`.
  - `expense.deleted.movedTo` is optional; when present, both ids must be UUIDs.
  - Friend groups don't count toward the 100-group abuse cap (`countGroupsOfUser` filters `kind = 'group'`). Linked friends have no cap (one per person); placeholder friends are capped at 200 per user (409 `LIMIT_EXCEEDED`, see docs/API.md).
- **Avatars:** `PUT /me/avatar` → `Jpeg.clean(bytes, 1024)` → `FileStore.write("avatars/{userId}.jpg")`.
  - Limited to 10 uploads per user per hour (an in-memory `RateLimiter`).
  - Readable by the user and by anyone with a member row in a common group, with `Cache-Control: private, max-age=3600`.
- **Payment edits:** no new event. An edit is `payment.deleted` plus a new `payment.created`. Phase 1 already allows the payer or receiver to delete, and the server normalizes the new status.
- **Activity** (Phase 2):
  - In a friend group, seq 1 `group.created` is hidden (seq 2 is already hidden), and the seq 3 `member.added` becomes kind **`friend_added`** (`memberId`).
  - Sentences: "{A} added {member} as a friend" / "You added {member} as a friend" / "{A} added you as a friend". Push category `members`.
  - The push title for a friend-group event is the other member's name, not the group name.
- **Reminders** (`POST /friends/{userId}/remind`):
  1. Load every group where both users have a member row (removed ones still count).
  2. Build the ledgers the app builds: `money/Balances.kt` (`ofGroup` = Kotlin port of Phase 4 `balancesOf`, `transfers` = port of `groupTransfers` including Phase 3 `pairwiseDebts`), then `money/Overview.kt` `compute`.
  3. Keep the currencies in which they owe me. If there are none → 409 `NOTHING_OWED`, and the daily slot isn't used.
  4. Take the slot atomically: `INSERT … ON CONFLICT (from_user, to_user) DO UPDATE SET sent_at = now() WHERE reminders.sent_at < now() - interval '24 hours'`. If 0 rows change → 429 `RATE_LIMITED` with `Retry-After`.
  5. Send a visible message through `PushSender` to all their devices, unless `notification_prefs.reminders = false`. The response is the same either way.
  - A group whose balances throw `NotImplementedError` (a Hyojun port not landed) is left out.
- **Account deletion** also deletes the avatar file (after commit), `reminders` in both directions and the user's `friendships`, and sets `friend_code = NULL`. A deleted friend then shows as a placeholder friend with the history intact.

### How (app)
- **drift (schemaVersion 6, then 7):** `Groups.kind` (text, default `'group'`). Version 7 adds `Expenses.moved` (default false) and replays every group (rule 13).
  - Every `GroupRow` built from a `GroupDto` sets it.
  - The Groups tab filters `kind == 'group'`.
  - `GroupState` gains `kind`.
- **Overview** in `app/lib/domain/overview.dart` (Claude): `GroupLedger.of(...)` and `computeOverview(...)` (see Contract changes).
  - `overviewProvider` recomputes from all local groups on any change.
  - `ponytail:` full recompute; cache per group if someone has hundreds.
- **Home** becomes a `NavigationBar` (Groups, Friends) with the overall card on both tabs, the filter chips and the Settled up sections.
  - FAB **Add expense** opens `/expenses/new` with a *With* picker: friends (linked and placeholder friends) and groups.
  - Picking a linked person with no friend group first calls `POST /friends {userId, defaultCurrency: home currency}`, online only.
  - "New group" moves into the Groups app bar.
- **Routes:** `/friends`, `/friends/add`, `/friends/:key`.
  - `key` is a userId, `g:<groupId>` for a placeholder friend, or `m:<memberId>` for a placeholder in a normal group.
  - People = every key in any ledger's `personOf` except me. A person's name is their member name in the friend group, else in the first shared group by name.
  - Several friend groups for one userId merge on one page. New non-group expenses go to the one with the smallest id.
  - A link or push to `/groups/:id` of a friend group redirects to the friend page.
- **Friend page:**
  - header (avatar, net per currency);
  - breakdown rows (tap opens the group);
  - non-group expenses (`ExpenseTile`);
  - **Settle up**;
  - **Remind** (linked person who owes me) or **Request** (placeholder);
  - **Invite** for a placeholder friend (its `/j/` link);
  - overflow: export the non-group expenses as CSV or JSON.
- **Settle up with a friend.** Lines = `overview.byGroup[person]`, handled per currency:
  - **Net < 0 (I owe):** pay chips from `GET /groups/{id}/payment-methods` (friend group, else any shared group), then **I've sent it**. `_pay` and `_bankSheet` move to `features/settle/pay_sheet.dart`.
  - **Net > 0:** **Request** and **Mark as received**.
  - **A currency that is only in an unconverted bucket** shows **Convert first** (the Phase 4 sheet) instead of pay buttons.
  - Recording writes one `payment.created` per line, in that line's group and currency. Lines in the direction of the net follow Phase 1 (`sent`/`confirmed`). Offset lines, where no money actually moves, are `confirmed`.
- **Record / edit payment** (`features/settle/payment_sheet.dart`):
  - From and To (any two different members), Amount (prefilled from a transfer card when opened there), Date (today), currency = group default.
  - Saves `payment.created`.
  - Editing is offered only to the payer's or receiver's user: one local transaction writes `payment.deleted` plus `payment.created` with a new id.
- **Move:** `remapForMove(Expense e, List<Member> source, List<Member> target) → Expense?` (pure).
  - It maps `payers`, `paidBy`, every share and `split.input` keys to the active target member with the same `userId`. It returns null if anyone involved is a placeholder or missing.
  - Online only:
    1. Push `expense.created` to the target directly (new id; `fxRateToDefault` kept only if both groups share a default currency).
    2. Only after that succeeds, queue `expense.deleted {expenseId, movedTo}` in the source outbox.
  - If step 1 fails, nothing has changed.
- **Add friend screen:**
  - my QR (`qr_flutter`), link and code, with Share and Rotate;
  - a code field that previews via `GET /friend-invites/{code}`, then calls `POST /friends {code}`;
  - "Someone not on Evensies yet" → `POST /friends {name}`.

  Code handling:
  - The join-code screen tries `/invites/{code}` first, then `/friend-invites/{code}` on a 404.
  - `extractInviteCode` learns `/f/<code>` and `evensies://f/<code>`.
  - `apple-app-site-association` gets `"/f/*"`, and AndroidManifest gets `host="f"` and `pathPrefix="/f/"`.
- **Images** (`data/images.dart`, shared with Phases 7 and 10).
  - New dependencies: `image_picker` (flutter.dev) and `flutter_image_compress`, both free and open source.
  - `Future<File> prepareJpeg(XFile picked, {required int maxEdge, required int quality})`: applies orientation to the pixels, drops EXIF, converts HEIC → JPEG.
  - Avatars use `maxEdge: 512, quality: 85` (about 50 KB) and show with `BoxFit.cover` in a circle.
  - iOS: `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription`.
  - `avatarProvider.family(userId)` fetches bytes through `ApiClient` (token refresh). Any error → null (initials). Kept for the session; my own is invalidated after an upload.
  - `PersonAvatar(userId?, name)` is used in Friends, the friend page, members, Settle up and Settings.
- **Push:** data `type: "remind"` opens `/friends/{fromUserId}`. A `sync` push for an unknown groupId runs `syncAll()`.
- **Settings:** a reminders switch next to the Phase 2 switches. The export list labels friend groups "Non-group · Ben".
- **`docs/privacy.md`:** a profile photo section (who sees it; a re-encoded 512 px JPEG on the server's disk; deleted with the account).

### Contract changes
**Events.** No new types.

| type | change |
|---|---|
| `group.created` | `+ "kind": "group" \| "friend"`. Server-created only; missing = `"group"`. |
| `group.updated` | must not contain `kind` (400 `VALIDATION`) |
| `expense.deleted` | `+ "movedTo": {"groupId", "expenseId"} \| null`. Optional. Activity shows "moved … to …" with no Restore. |

Applier rule **13**: `group.created` sets `kind` (missing = `"group"`); nothing changes it afterwards. An `expense.deleted` with a `movedTo` object deletes like a plain delete and also sets `moved = true`, which nothing clears; `expense.restored` on a moved expense is ignored (it counts in the other group now). Snapshots and exports carry `moved`.

**DTOs.** `GroupDto`, `GroupSummaryDto`, the snapshot's group and `GET /invites/{code}` gain `"kind"`. `NotificationPrefs` gains `"reminders": bool`, which is optional in `PUT` (missing = unchanged), so Phase 2 clients keep working.

**Endpoints**

| Method | Path | Request | Response and errors |
|---|---|---|---|
| GET | `/me/friend-code` | | `{"friendCode": "K7P4QX", "link": "https://evensies.nariinfo.dev/f/K7P4QX"}`, created on first call |
| POST | `/me/friend-code/rotate` | | same; the old code → 404 from then on |
| GET | `/friend-invites/{code}` | no auth, normalized | `{"displayName": "Anna"}`. 404, 429 |
| GET | `/f/{code}` | no auth | HTML "Anna wants to split expenses with you" with **Open in app** → `evensies://f/{code}`; same template function as `/j/`. 429 |
| POST | `/friends` | exactly one of `{"code"}`, `{"userId"}`, `{"name"}`, plus `"defaultCurrency"` | `GroupDto` with `kind: "friend"`, the same group for repeats and either side. 400 `VALIDATION` (none or more than one; name 1–30 code points after trim), 400 `SELF_FRIEND`, 400 `UNKNOWN_CURRENCY`, 404 (code), 403 (userId with no shared group), 429 |
| PUT | `/me/avatar` | multipart `file`: JPEG, ≤ 300 KB, edges ≤ 1024 | 204. 400 `NOT_JPEG` / `IMAGE_TOO_LARGE`, 413 `TOO_LARGE`, 429 |
| DELETE | `/me/avatar` | | 204 |
| GET | `/users/{userId}/avatar` | | `image/jpeg`, `Cache-Control: private, max-age=3600`. 404 none, 403 no shared group |
| POST | `/friends/{userId}/remind` | | `{"amounts": [{"currency": "EUR", "amount": 1500}]}`. 403 (no shared group, or self), 409 `NOTHING_OWED`, 429 with `Retry-After` |
| POST | `/invites/{code}/join` | unchanged | on a friend group, `newMemberId` → 409 `LIMIT_EXCEEDED`; a claim inserts the pair row |

**Reminder push** (visible):
- Title: "{A} sent a reminder".
- Body: "You owe {A} €15.00 and $12.00." At most two currencies, then "and more".
- Data: `{"type": "remind", "fromUserId": "<uuid>"}`.

**Migration `V7__people.sql`:**
```sql
ALTER TABLE groups ADD COLUMN kind text NOT NULL DEFAULT 'group' CHECK (kind IN ('group', 'friend'));
ALTER TABLE users ADD COLUMN friend_code text UNIQUE;
ALTER TABLE users DROP COLUMN avatar_url;  -- unused since V1; photos are files under EVENSIES_STORAGE_DIR

-- One canonical friend group per pair of users. user_lo < user_hi (uuid order = lowercase string order).
CREATE TABLE friendships (
    user_lo    uuid NOT NULL REFERENCES users (id),
    user_hi    uuid NOT NULL REFERENCES users (id),
    group_id   uuid NOT NULL REFERENCES groups (id),
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (user_lo, user_hi),
    CHECK (user_lo < user_hi)
);

-- Last reminder per pair; the 24-hour rule is one conditional upsert.
CREATE TABLE reminders (
    from_user uuid NOT NULL REFERENCES users (id),
    to_user   uuid NOT NULL REFERENCES users (id),
    sent_at   timestamptz NOT NULL,
    PRIMARY KEY (from_user, to_user)
);

ALTER TABLE notification_prefs ADD COLUMN reminders boolean NOT NULL DEFAULT true;
```

**Migration `V8__moved_expenses.sql`** (rule 13): `expenses.moved boolean NOT NULL DEFAULT false`, backfilled from the log: every expense with an `expense.deleted` whose `movedTo` is an object becomes moved and deleted, as a replay gives.

**Config:** `EVENSIES_STORAGE_DIR` (default `./data`; `/data` in Docker). Back it up together with the database.

**Error codes.** New: `SELF_FRIEND`, `NOTHING_OWED`, `NOT_JPEG`, `IMAGE_TOO_LARGE`, `TOO_LARGE` (413). Reused: `LIMIT_EXCEEDED`, `RATE_LIMITED`, `FORBIDDEN`, `NOT_FOUND`, `VALIDATION`, `UNKNOWN_CURRENCY`.

**Overview rules.** The same rules apply in Dart `domain/overview.dart` and Kotlin `money/Overview.kt`.
```dart
class GroupLedger {
  final String groupId;
  final String myMemberId;
  /// memberId → person key: userId if linked; "g:<groupId>" for a friend group's placeholder; "m:<memberId>" otherwise.
  final Map<String, String> personOf;
  /// currency → groupTransfers(state)[currency] (Phase 4): what Settle up shows, unconverted buckets included.
  final Map<String, List<Transfer>> transfers;
  /// null if no member has userId == [myUserId], or balances can't be computed yet (tryCore).
  static GroupLedger? of({required String groupId, required GroupState state, required String myUserId});
}
class Overview {
  final Map<String, Map<String, int>> people;               // person → currency → amount (+ they owe me)
  final Map<String, Map<String, Map<String, int>>> byGroup; // person → groupId → currency → amount
  final Map<String, int> owedToMe, iOwe;                    // currency → total
}
Overview computeOverview(List<GroupLedger> ledgers);
```
1. `myMemberId` is the first member, in state order, with `userId == myUserId`. Removed members count.
2. For every transfer:
   - `to == myMemberId`: add `+amount` to `personOf[from]`;
   - `from == myMemberId`: add `−amount` to `personOf[to]`;
   - other transfers are ignored.
3. Amounts are summed per person per currency (`people`) and per group (`byGroup`). There is no conversion and no rounding.
4. Zeros are dropped, then empty persons and groups.
5. `owedToMe[c]` = Σ max(0, people[p][c]); `iOwe[c]` = Σ max(0, −people[p][c]).
6. Invariant (tested): `owedToMe[c] − iOwe[c]` = the sum of my balances in c across all ledgers.

### Shared fixtures
**`shared/overview-cases.json`** (new), read by `overview_test.dart` and `OverviewTest`. Each case runs state → `balancesOf` / `groupTransfers` → overview, which also checks the Kotlin `Balances` port.
```json
{
  "_doc": "Overview (Friends tab, overall card, reminders). Per group: groupTransfers(state) (Phase 4 buckets: a foreign expense with fxRateToDefault > 0 converts into the default currency with convertExpense; otherwise it stays in its own currency) → keep the transfers that involve me. Person key: userId if linked; \"g:<groupId>\" for a friend group's placeholder; \"m:<memberId>\" for a placeholder in a normal group. people: person → currency → amount (+ they owe me, − I owe them), summed per currency across groups, zeros dropped. owedToMe / iOwe: per-currency sums of positive / negative person amounts. Missing fxRateToDefault/category = null, payers = [{paidBy, amount}], deleted = false, status = confirmed, simplifyDebts = true.",
  "cases": [
    {"name": "friend group and a shared group net out in one currency", "me": "u-anna",
     "groups": [
      {"id": "g-friend", "kind": "friend", "defaultCurrency": "EUR",
       "members": [{"id": "f1", "name": "Anna", "userId": "u-anna"}, {"id": "f2", "name": "Ben", "userId": "u-ben"}],
       "expenses": [{"id": "x1", "description": "Taxi", "amount": 2000, "currency": "EUR", "paidBy": "f1", "date": "2026-10-01", "shares": [{"memberId": "f1", "amount": 1000}, {"memberId": "f2", "amount": 1000}]}],
       "payments": []},
      {"id": "g-rome", "kind": "group", "defaultCurrency": "EUR",
       "members": [{"id": "r1", "name": "Anna", "userId": "u-anna"}, {"id": "r2", "name": "Ben", "userId": "u-ben"}, {"id": "r3", "name": "Carlo", "userId": null}],
       "expenses": [{"id": "x2", "description": "Hotel", "amount": 9000, "currency": "EUR", "paidBy": "r2", "date": "2026-10-02", "shares": [{"memberId": "r1", "amount": 3000}, {"memberId": "r2", "amount": 3000}, {"memberId": "r3", "amount": 3000}]}],
       "payments": []}],
     "expected": {"people": {"u-ben": {"EUR": -2000}}, "byGroup": {"u-ben": {"g-friend": {"EUR": 1000}, "g-rome": {"EUR": -3000}}},
                  "owedToMe": {}, "iOwe": {"EUR": 2000}}},
    {"name": "currencies never mix; a converted expense counts in EUR, an unconverted one stays in USD", "me": "u-anna", "pending": "hyojun",
     "groups": [
      {"id": "g-friend", "kind": "friend", "defaultCurrency": "EUR",
       "members": [{"id": "f1", "name": "Anna", "userId": "u-anna"}, {"id": "f2", "name": "Ben", "userId": "u-ben"}],
       "expenses": [
        {"id": "x1", "description": "Dinner", "amount": 4000, "currency": "EUR", "paidBy": "f2", "date": "2026-10-01", "shares": [{"memberId": "f1", "amount": 2000}, {"memberId": "f2", "amount": 2000}]},
        {"id": "x2", "description": "Museum", "amount": 1000, "currency": "USD", "fxRateToDefault": 0.9, "paidBy": "f1", "date": "2026-10-02", "shares": [{"memberId": "f1", "amount": 500}, {"memberId": "f2", "amount": 500}]},
        {"id": "x3", "description": "Snacks", "amount": 600, "currency": "USD", "paidBy": "f2", "date": "2026-10-03", "shares": [{"memberId": "f1", "amount": 300}, {"memberId": "f2", "amount": 300}]}],
       "payments": []},
      {"id": "g-ny", "kind": "group", "defaultCurrency": "USD",
       "members": [{"id": "n1", "name": "Anna", "userId": "u-anna"}, {"id": "n2", "name": "Ben", "userId": "u-ben"}, {"id": "n3", "name": "Dana", "userId": "u-dana"}],
       "expenses": [{"id": "x4", "description": "Brunch", "amount": 3000, "currency": "USD", "paidBy": "n1", "date": "2026-10-04", "shares": [{"memberId": "n1", "amount": 1000}, {"memberId": "n2", "amount": 1000}, {"memberId": "n3", "amount": 1000}]}],
       "payments": []}],
     "expected": {"people": {"u-ben": {"EUR": -1550, "USD": 700}, "u-dana": {"USD": 1000}},
                  "byGroup": {"u-ben": {"g-friend": {"EUR": -1550, "USD": -300}, "g-ny": {"USD": 1000}}, "u-dana": {"g-ny": {"USD": 1000}}},
                  "owedToMe": {"USD": 1700}, "iOwe": {"EUR": 1550}}},
    {"name": "placeholders get their own keys; payments count", "me": "u-anna",
     "groups": [
      {"id": "g-pf", "kind": "friend", "defaultCurrency": "JPY",
       "members": [{"id": "p1", "name": "Anna", "userId": "u-anna"}, {"id": "p2", "name": "Ben", "userId": null}],
       "expenses": [{"id": "x1", "description": "Ramen", "amount": 3000, "currency": "JPY", "paidBy": "p1", "date": "2026-10-01", "shares": [{"memberId": "p1", "amount": 1500}, {"memberId": "p2", "amount": 1500}]}],
       "payments": []},
      {"id": "g-trip", "kind": "group", "defaultCurrency": "EUR",
       "members": [{"id": "t1", "name": "Anna", "userId": "u-anna"}, {"id": "t2", "name": "Carlo", "userId": null}],
       "expenses": [{"id": "x2", "description": "Train", "amount": 1000, "currency": "EUR", "paidBy": "t2", "date": "2026-10-02", "shares": [{"memberId": "t1", "amount": 500}, {"memberId": "t2", "amount": 500}]}],
       "payments": [{"id": "y1", "fromMember": "t1", "toMember": "t2", "amount": 200, "currency": "EUR", "date": "2026-10-03"}]}],
     "expected": {"people": {"g:g-pf": {"JPY": 1500}, "m:t2": {"EUR": -300}}, "byGroup": {"g:g-pf": {"g-pf": {"JPY": 1500}}, "m:t2": {"g-trip": {"EUR": -300}}},
                  "owedToMe": {"JPY": 1500}, "iOwe": {"EUR": 300}}},
    {"name": "settled with me: other people's transfers are ignored", "me": "u-anna",
     "groups": [
      {"id": "g-flat", "kind": "group", "defaultCurrency": "EUR",
       "members": [{"id": "a1", "name": "Anna", "userId": "u-anna"}, {"id": "a2", "name": "Ben", "userId": "u-ben"}, {"id": "a3", "name": "Carlo", "userId": "u-carlo"}],
       "expenses": [
        {"id": "x1", "description": "Groceries", "amount": 2000, "currency": "EUR", "paidBy": "a2", "date": "2026-10-01", "shares": [{"memberId": "a2", "amount": 1000}, {"memberId": "a3", "amount": 1000}]},
        {"id": "x2", "description": "Wine", "amount": 1000, "currency": "EUR", "paidBy": "a1", "date": "2026-10-02", "shares": [{"memberId": "a1", "amount": 500}, {"memberId": "a2", "amount": 500}]}],
       "payments": [{"id": "y1", "fromMember": "a2", "toMember": "a1", "amount": 500, "currency": "EUR", "date": "2026-10-03"}]}],
     "expected": {"people": {}, "byGroup": {}, "owedToMe": {}, "iOwe": {}}}
  ]
}
```
- **`shared/sync-cases.json`:**
  - `_doc` default `group.kind` = `"group"`.
  - Case "expense.deleted with movedTo marks deleted and moved": a member, an expense, then `expense.deleted {expenseId: "x1", movedTo: {"groupId": "g2", "expenseId": "x9"}}` → the expense is `deleted: true, moved: true` (`_doc` default `moved = false`).
  - Case "expense.restored on a moved expense is ignored".
  - Case "friend kind set on create; missing kind is group", using `expected.group.kind`.
- **`shared/activity-cases.json`:** `friend_added` in its three variants; a hidden friend-group seq 1; a payment edit (`payment_deleted` + `payment_added` batched as "made 2 changes").

### Tests
- **Server, `FriendTest`** (Testcontainers + HTTP):
  - **By code:** a group with 2 linked members at seq 1–3; a repeat call and the reverse direction give the same id; two parallel calls create one group; own code → `SELF_FRIEND`; a rotated code → 404.
  - **By userId:** 403 without a shared group, 200 with one.
  - **By name, then claim:** a placeholder; the claim inserts the pair row; a claim when the pair exists keeps both groups and returns the canonical one.
  - **Friend group rules:** `newMemberId` join → 409; `member.added` / `member.removed` / `group.updated {kind}` → 409 / 400 / 400.
  - **Other:** 100 friend groups don't hit the cap; the friend's device gets a `friend_added` visible push (fake sender); `GET /groups` includes `kind`; code lookups are limited per IP.
- **Server, `AvatarTest` + `JpegTest`:**
  - a JPEG with EXIF GPS, a COM segment and trailing bytes comes back without them and still decodes at the same size (also progressive);
  - PNG → `NOT_JPEG`; a 5000 px header → `IMAGE_TOO_LARGE`, rejected without decoding;
  - over 300 KB → 413, and 6 MB → 413 (not 500);
  - stranger → 403; no photo → 404; delete works; account deletion removes the file.
- **Server, `ReminderTest`:**
  - owed across a friend group and a shared group in two currencies → 200 with both amounts and exactly one push with the expected text;
  - second reminder within 24 h → 429 with `Retry-After`;
  - nothing owed → 409, and a later valid one still goes through;
  - I owe them → 409; stranger or self → 403;
  - `reminders=false` → 200 and no push;
  - a group whose Kotlin balance port throws `NotImplementedError` is skipped.
- **Server, other:**
  - `OverviewTest` runs the shared file;
  - validator `movedTo` good and bad;
  - `InviteCodesTest`: both generators skip codes taken in the other table;
  - `PUT /me/notifications` without `reminders` keeps it.
- **App:**
  - `overview_test.dart` plus the invariant;
  - `remapForMove`: all linked → mapped, placeholder → null, removed target → null, fx rule, payers and `split.input` remapped;
  - settle-all builder (offset lines are `confirmed`; an unconverted-only currency gets no payment);
  - payment edit writes delete + create;
  - `extractInviteCode` handles `/f/`;
  - widgets: settled sections, filter chips, `*`, overall card, breakdown.
- **Simulator** (light and dark, two users):
  - add a friend by link and by code; a claimed placeholder friend is the same person;
  - a non-group expense added offline syncs;
  - the Friends tab and overall card match each Settle up;
  - settle across a group and a friend in one go;
  - record and edit a custom payment;
  - move an expense to a friend and back;
  - take, choose and remove a photo, which the other account sees;
  - reminder tap routing with `xcrun simctl push`. Real FCM delivery needs a device.

### Hyojun's part
None in this phase. The overview is aggregation (Claude). It uses his functions as inputs:
- **App:** if `balancesOf` returns null for a group, `GroupLedger.of` returns null and the overall card says "1 group not included yet".
- **Server:** groups whose `Balances.ofGroup` throws `NotImplementedError` are skipped in reminders.
- **Home currency:** the "≈ total" line stays hidden while `tryCore` returns null or a rate is missing.

### Dependencies
- **Phase 2:** visible push, `notification_prefs`, the settings screen.
- **Phase 3:** simplify carries through `groupTransfers`. Friend groups have no settings screen and no Leave.
- **Phase 4:** buckets, home currency, Convert first.
- **Phase 7:** reuses `FileStore`, `Jpeg.clean`, `prepareJpeg` and `image_picker`. It also extends `remapForMove` for itemized splits and receipts.
- **Phase 8:** a moved expense drops its series tag.
- **Phase 9:** `/f/` gets "Continue in the browser". Images are served through the API origin, so web needs no CORS or CSP change.
- **Phase 10:** delete friend, block/report, group photos (on this storage).

### Left out (deliberately)
| What | Why, and where it goes |
|---|---|
| Delete a friend (#52) | Phase 10: `group.deleted` on the friend group |
| Block / report (#53) | Phase 10, with the support contact |
| Non-group expense with 2+ friends | Needs pairwise rows across several friend groups; create a group instead |
| Adding a friend straight into a group | Joining exposes payment methods (Phase 1), so it stays consent-based through the invite link |
| Merging duplicate members (#47) | Would rewrite history; claim the placeholder through its invite link (Phase 10 adds a preselected email invite) |
| `payment.updated` | An edit is delete + create; no new event type |
| Object storage | Not needed yet; propose it with its cost when the disk passes 70% |

### Done when
- Two people become friends by link with no duplicates.
- A non-group expense added offline syncs.
- The Friends tab, the overall card and each Settle up show the same per-currency numbers.
- Everything between two people settles in one action, and a custom payment can be recorded and edited.
- Each person sees the other's photo.
- A reminder arrives as a readable push, at most once a day.

---
