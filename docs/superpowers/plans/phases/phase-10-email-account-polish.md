# Phase 10 design — Email & account polish

Email is optional. With `EVENSIES_SMTP_HOST` empty, the server works as it does today, every email feature turns off, and the app hides them. Every email is plain text, has no tracking, says why the person got it, and is written in the reader's language (Phase 9 `users.language`, `shared/strings.json` `email.*`).

Rough size: about 2 sessions, in two halves that ship separately.
- **10a, email:** mailer, email sign-in, account email, invite by email, digest, recurring-bill reminder.
- **10b, groups & account:** group type, cover, delete/restore (incl. delete friend), block/report, export everything, sign out everywhere, UPI, help.

### What users get
1. **Sign in with email.** "Continue with email" sends a 6-digit code. There are no passwords, so nothing to reset. The same verified address as an Apple/Google account lands in that account. Self-hosters without Apple/Google ids can still sign in, on web too.
2. **Account email** in Settings. It is filled from Apple/Google when they say it is verified. You can add, change (confirmed by code) or remove it. Other members never see it.
3. **Email summary** (Settings → Notifications):
   - **Auto** (default): daily when none of your devices can show notifications, otherwise monthly;
   - **Daily**, **Weekly**, **Monthly**;
   - **Off**.

   It lists what others changed, in the push sentences, plus your balances per group and currency. Every summary has an unsubscribe link.
4. **Invite by email.**
   - When adding a placeholder, or later from its row.
   - One invite, plus one reminder after 3 days if they haven't joined.
   - The link opens the join screen with their name preselected.
   - The address is deleted after 14 days.
5. **Reminder before a repeating bill posts** (#64). In the expense form under Repeat: "Email a reminder: Never / 1 day before / 3 days before / 7 days before". Everyone on the expense who has an email gets it.
6. **Group type:** Trip / Home / Couple / Other (icon and colour band).
7. **Group cover photo**, visible only to members, on the header and as the list thumbnail.
8. **Delete a group and restore it.**
   - Any member can delete; it is deleted for everyone.
   - Restore via Undo (10 s), Settings → Deleted groups, or the activity row.
   - Nothing is lost: offline edits made after the deletion still arrive.
9. **Delete a friend** (#52). On the friend page: deletes your non-group expenses for both of you, and they can be restored the same way. Adding them again brings them back.
10. **Block or report someone** (#53).
    - Blocked people can't add you as a friend, can't send you reminders, and their changes stop notifying or emailing you.
    - **Report** opens an email to the server's support address.
11. **Export everything:** one JSON with your profile, payment methods, settings and every group, deleted ones included. Receipt images come with the per-group ZIP (Phase 7).
12. **Sign out on all devices.**
13. **UPI** (India, covers Paytm) as a way to get paid. It opens the UPI app with the amount filled for INR.
14. **Help & feedback:** GitHub issues, the operator's contact email if set, and the privacy policy.
15. **Delete account** also clears your email, name, email settings and blocks.

### Cost
| Item | Monthly | Notes |
|---|---|---|
| Resend **Free**, hosted server only | **€0** | 3,000 a month, **100 a day**, 1 domain, EU region. Not needed before release: tests use a capturing sender, local runs use Mailpit |
| When `email_log` shows more than 80 a day for a week | Amazon SES ≈ $0.10/1,000 (about $1–3), or Resend Pro $20 | Plain SMTP, so only env vars change; proposed with the cost then |
| Self-hosters | €0 | Their own SMTP, or none |
| Mailpit | €0 | `docker-compose.dev.yml` only |
| Cover images | €0 | Phase 6 disk storage |
| Apple private-relay sender registration | €0 | Existing Apple Developer account |

At 1,000 active users: about 2,800 emails a month. `EVENSIES_EMAIL_DAILY_LIMIT` keeps a busy day under 100.

### How (server)
- **Mailer** (`email/Mailer.kt` on `JavaMailSender`). The only new dependency is `spring-boot-starter-mail`.
  - `EmailConfig` builds a `JavaMailSenderImpl` only when `evensies.email.smtp-host` is set (not `spring.mail.host`, because Boot treats an empty value as present).
  - TLS: `starttls` (default, required), `ssl` (465), or `none` (Mailpit only). Connect, read and write timeouts are 10 s.
  - `send(kind, to, chargedUserId, Email)` gates, in order:
    1. suppression (codes skip it);
    2. the daily budget;
    3. an `email_log` row (hashed address);
    4. send.
  - A synchronous 5xx rejection (`SendFailedException.invalidAddresses`) → a `bounce` suppression + `EMAIL_REJECTED`. Any other failure → `EMAIL_UNAVAILABLE`.
  - Every message is `text/plain; charset=UTF-8` with `Auto-Submitted: auto-generated`. Invites, digests and recurring reminders carry `List-Unsubscribe` and `List-Unsubscribe-Post: List-Unsubscribe=One-Click` (RFC 8058).
  - CR/LF is stripped from user text. Names are cut to 40 characters and comments to 80.
- **Templates** (`email/EmailTemplates.kt`): pure functions per kind, reading `strings.json` `email.*` through Phase 9's `Sentences` (money notation and fallback rules included).
  - Language: the recipient's `users.language`; invites to a non-user use the inviter's language.
  - A `java.time.Clock` bean is injected.
- **Tokens** (`email/EmailTokens.kt`, `javax.crypto`). `K = HMAC-SHA256(EVENSIES_JWT_SECRET, "evensies-email")`, so there is no new secret.
  - Code hash: `HMAC(K, email + ":" + code)`, compared in constant time.
  - Unsubscribe token: `base64url("{kind}:{subject}") + "." + base64url(first 16 bytes of HMAC(K, same))`. Kinds: `digest` (subject = userId; also covers recurring reminders) and `invites` (subject = sha256 of the address).
  - Tokens never expire. Rotating the JWT secret breaks old links, and the page then says to change the setting in the app.
- **Account email.**
  - `IdTokenVerifier` returns `email` only when `email_verified` is true (Apple may send `"true"` as a string).
  - On Apple/Google login, `users.email` is set only if it is null and no other active user holds the address. A unique-index race is caught and ignored, so accounts are never merged automatically.
- **Email sign-in** (`/auth/email/*`, under `permitAll` on `/auth/**`):
  - `start`: a 6-digit `SecureRandom` code, TTL 10 minutes, 5 attempts, single use; a new code replaces the old.
  - `verify`: the active user with that `email`, else `users.findOrCreate("email", email, "")` and set `email`. A new user gets an empty name, so the name screen appears.
  - A successful verify deletes the address's suppression.
- **Digest** (`email/DigestBuilder.kt`, pure with goldens; `email/EmailJobs.kt` `@Scheduled(cron = "0 5 * * * *")` on Phase 8's `@EnableScheduling`).
  - **Candidates:** active users with an email, not suppressed, `email_digest <> 'off'`. A missing `notification_prefs` row is created with `last_digest_at = now()` and the current max `feed_id`, which starts the clock without sending.
  - **Auto** = daily when the user has **no push-capable device**, else monthly. Push-capable = an FCM token, `notifications_allowed`, `last_seen_at` within 60 days, and FCM configured. All three Phase 2 push switches off counts as no push.
  - **When due:** `nextDue(last, mode)` gives daily → the next 17:00 UTC; weekly → the next Monday 17:00 UTC; monthly → the 1st at 09:00 UTC. Due means `now >= nextDue`, so missed runs catch up. `ponytail:` UTC only (Phase 8 stores a zone per series, not per user); add `users.time_zone` if people ask.
  - **Window:** events with `feed_id > last_digest_feed_id` (Phase 2's global storage order, so no new column on `events`), in groups where the user is an active linked member and the group isn't deleted, actor ≠ the user, actor not blocked by the user. At most 500 per user per run.
  - **Lines:**
    - Phase 9 `Sentences` in the user's language; kinds with no sentence are dropped;
    - an expense created and deleted inside the window drops out;
    - a group deleted at send time contributes only its `group.deleted` line, if inside the window;
    - at most 10 lines per group and 30 in total, then "…and N more in {group}";
    - groups are ordered by newest event.
  - **Balances:** `Balances.ofGroup(state)` (Phase 6 port, per currency bucket). One line per group and currency with a non-zero balance. A `NotImplementedError` leaves the section out.
  - **Sending rules:** daily and weekly need at least 1 line; monthly needs at least 1 line or a non-zero balance.
  - **After a run:** `last_digest_at = now` and `last_digest_feed_id` = the run's max, on send or on nothing to say. They don't advance on a budget skip or a failed send.
  - Changing `emailDigest` resets the clock. Digests stop at 80% of `EVENSIES_EMAIL_DAILY_LIMIT`.
  - `ponytail:` loads all candidates hourly on one instance; page by due time and take `pg_try_advisory_lock` past 10k users or more than one instance.
- **Recurring-bill reminder** (same hourly job):
  - `SELECT … FROM recurrences r JOIN groups g ON g.id = r.group_id AND g.deleted_at IS NULL WHERE r.deleted_at IS NULL AND r.remind_days_before IS NOT NULL AND r.reminded_occurrence < r.next_occurrence AND r.next_due_at - r.remind_days_before * interval '1 day' <= now()`.
  - It emails every linked, active member who appears in the template's payers or shares and has an email, isn't suppressed, has `email_digest <> 'off'` and hasn't blocked the series creator. Then `reminded_occurrence = next_occurrence`.
- **Other hourly work:**
  - **Invite reminders:** rows with `reminded_at IS NULL` and `sent_at < now − 3 days`, where the member is still unlinked and not removed, the group not deleted, the address not suppressed. One reminder each.
  - **Purge:** expired `email_codes`; `email_invites` older than 14 days; `email_log` older than 30 days.
- **Invite by email** (`POST /groups/{id}/members/{memberId}/invite-email`).
  - The caller is an active member; the member belongs to the group and is neither removed nor linked.
  - 204 **without sending** (revealing nothing) when the address is suppressed, a row already exists for the member, or the address got 3 invites in 7 days.
  - Existing users are never linked automatically.
  - `/j/{code}` passes an optional UUID-shaped `m` on to `evensies://join/{code}?m=…` and `/app/#/join/{code}?m=…`.
- **Groups.**
  - `GroupState` gains `type` (default `"other"`), `coverImageId` (default null) and `deleted` (default false).
  - `GroupStateStore` persists `type`, `cover_image_id` and `deleted_at` (`COALESCE(deleted_at, now())` on delete, `NULL` on restore).
  - `pushAsMember` refuses a client `group.updated` with a non-null `coverImageId` (400 `VALIDATION`).
  - Events after `group.deleted` are **not** rejected; they apply normally.
  - Notifications for a deleted group: visible push and digest lines stay quiet, except `group.deleted` / `group.restored`; silent sync still goes out.
  - `countGroupsOfUser` counts non-deleted groups of kind `group`, so a restore is never blocked by the abuse cap.
  - Invite preview, join and landing of a deleted group → 404.
  - **Phase 8 scheduler:**
    - `runDue` joins `groups` and skips `deleted_at IS NOT NULL`;
    - on `group.restored`, the store moves each active series' `next_occurrence` to `firstOnOrAfter(today)`, so the deleted period isn't posted in a burst.
  - **Friend groups:** `POST /friends` for a pair whose canonical group is deleted appends a server-built `group.restored` (actor = caller) and returns the group.
- **Cover** (Phase 6 pipeline):
  1. `PUT /groups/{id}/cover` → `Jpeg.clean(bytes, 2048)`.
  2. `FileStore.write("covers/{groupId}/{coverId}.jpg")`.
  3. Push `group.updated {coverImageId}` through `pushValidated` as the caller.
  4. After commit, delete the previous file.
  - A client `coverImageId: null` deletes the file after commit.
  - Phase 8's daily sweep also deletes cover files that aren't their group's current id.
  - 20 uploads per user per hour.
  - `GET /groups/{id}/cover/{coverId}` serves members only, for the current id only, with `Cache-Control: private, max-age=31536000, immutable`.
- **Blocks** (`user_blocks`). Effects for the blocker:
  - `POST /friends` from the blocked user → 404 (code) / 403 (userId), the same as unknown;
  - their reminders → 200 with no push;
  - their events give the blocker no visible push and no digest lines;
  - no recurring reminders for series they created.

  Money stays visible: shared groups and balances are unchanged.
- **Account.**
  - `POST /me/logout-all` deletes the user's refresh tokens and devices. `ponytail:` access tokens stay valid ≤ 15 min; add `users.tokens_valid_after` checked in `JwtAuthFilter` if instant revoke is needed.
  - `GET /me/export` builds `SnapshotService.snapshot` for every active membership, deleted groups included. 3 per user per hour.
  - `DELETE /me` additionally sets `display_name = ''` and `email = NULL`, and deletes `notification_prefs`, `email_codes`, the `email_invites` the user sent, and `user_blocks` in both directions.
- **Unsubscribe and bounces** (`email/EmailController.kt`; `/email/unsubscribe` and `/webhooks/email` added to `permitAll`):
  - **GET** shows an HTML page in the landing style (language from `Accept-Language`) with one button. It changes nothing, because link scanners prefetch.
  - **POST** applies it: `digest` → `email_digest = 'off'`; `invites` → an `unsubscribe` suppression.
  - **Webhook** `POST /webhooks/email` verifies Resend's Svix signature:
    - signed content = `svix-id + "." + svix-timestamp + "." + body`;
    - key = base64 after `whsec_`;
    - the header holds `v1,<sig>` entries;
    - the timestamp must be within 5 minutes.

    `email.bounced` → a `bounce` suppression per `data.to`; `email.complained` → `complaint` + `email_digest = 'off'`.
  - Other relays get synchronous 5xx handling only.
- **`GET /info`** (Phase 9) adds `emailLogin`, `appleLogin`, `googleLogin` and `supportEmail`.
- **Payment methods:** `upi` (Contract changes).
- **Dev only:** `POST /dev/jobs/email` runs the hourly job ignoring due times. It exists only when `evensies.auth.dev-login=true`.

### How (app)
- **Startup:** `serverInfoProvider` (`GET /info`). Offline or an old server falls back to `{emailLogin: false, appleLogin: true, googleLogin: true}`. The login screen hides what the server can't do.
- **Email sign-in:** route `/login/email` (`features/auth/email_login_screen.dart`). Shared `features/auth/email_code_form.dart`:
  - a 6-digit field with `AutofillHints.oneTimeCode`;
  - **Resend** after 30 s;
  - **Use a different email**.

  Success stores the session.
- **Settings → Account:**
  - **Email** row (or "Add email") → `/settings/email` with the code form and Remove. When `emailBounced`, it shows "Emails to this address bounce — change it or verify it again". Hidden when `!emailLogin`.
  - **Sign out everywhere:** confirm → `POST /me/logout-all` → local sign-out.
  - **Blocked people:** list with Unblock.
  - **Help & feedback:** `https://github.com/devyourown/evensies/issues/new`; `mailto:{supportEmail}` when set; the privacy policy.
  - Delete account adds "Tip: Export everything first."
- **Settings → Notifications** adds **Email summary**: Auto (shows `emailDigestEffective`, e.g. "Auto — daily, because notifications are off"), Daily, Weekly, Monthly, Off. Disabled with a hint when there is no email or the server has email off.
- **Export & import:** **Export everything (JSON)** → `GET /me/export` → `evensies-export-YYYY-MM-DD.json` (downloads on web).
- **Deleted groups** (Settings, when any exist) with **Restore**.
- **Push status:** `push.dart` sends `notificationsAllowed` with `POST /devices`, and again on resume when it changed.
- **drift (schemaVersion 9):** `Groups.type` (default `'other'`), `Groups.coverImageId`, `Groups.deleted`.
  - `watchGroups` filters out deleted groups; `watchDeletedGroups` lists them.
  - **Deleted groups are left out of** the Friends tab and overall card (Phase 6), search (Phase 5) and the widget (Phase 9).
- **Local writes:** `updateGroup` gains `type` and `removeCover`; new `deleteGroup` and `restoreGroup`, both offline-capable.
- **Create group:** type `ChoiceChip`s (Trip `flight_takeoff`, Home `home_outlined`, Couple `favorite_border`, Other `groups_outlined`), sent as `type`.
- **Group settings** (Phase 3 screen) gains:
  - type chips;
  - **Change cover** (`image_picker` → `prepareJpeg(maxEdge: 1600, quality: 82)` → `PUT /groups/{id}/cover`);
  - **Remove cover**;
  - **Delete group**: confirm "Deleted for everyone. Any member can restore it from Settings → Deleted groups." → back to the list with an **Undo** SnackBar that sends `group.restored`.
- **Friend page overflow:**
  - **Delete friend** → `group.deleted` on every friend group with that person;
  - **Block** / **Unblock**;
  - **Report…** → `mailto:{supportEmail}?subject=Evensies report&body=User id: {userId}` (hidden without `supportEmail`).
- **Covers in the UI:**
  - `core/cover.dart` `CoverCache` fetches through `ApiClient` into `{appSupport}/covers/{coverId}.jpg` (ids never change); the old file is deleted when the id changes;
  - `GroupCover` widget: the image, or the type gradient plus icon;
  - group detail uses it in `AppBar.flexibleSpace` with a scrim;
  - the list shows a 48×48 thumbnail;
  - a deleted group shows a `MaterialBanner`: "This group is deleted · Restore".
- **Members screen:**
  - "Add member" gets an optional **Email** field: "We'll email them an invite link. Only used for this invite."
  - Placeholder rows get **Invite by email…**.
  - Flow: add locally → `await sync(groupId)` → `inviteByEmail`.
  - Offline: "Member added. Inviting by email needs a connection — try again from the member list."
  - Hidden when `!emailLogin`.
- **Expense form (Phase 8 Repeat):** a reminder dropdown (Never / 1 / 3 / 7 days before), shown when `emailLogin`. It writes `remindDaysBefore` on `recurrence.created` / `recurrence.updated`.
- **Deep links:** `?m=` becomes `/join/$code?m=$m`. The placeholder is preselected only if it is unlinked; the user still confirms.
- **UPI:**
  - `PaymentTypes.upi` with UPI ID and optional name.
  - `payLink`: `upi://pay?pa={vpa}&pn={holder}&tn={note ≤ 50 chars}`, plus `&am={plainAmount}&cu=INR` only for INR. `prefillsAmount(type, currency)` gains the currency argument.
  - If `launchUrl` returns false: "No UPI app found" plus copy buttons.
- **Strings:** new UI text goes into ARB in all 13 languages (Claude translates; Phase 9's l10n tests enforce).

### Contract changes
**Events** (`docs/API.md`):

| type | payload |
|---|---|
| `group.created` | `{"name","defaultCurrency","kind"?,"type"?: "trip"\|"home"\|"couple"\|"other"}`; missing `type` = `"other"` |
| `group.updated` | `{"name"?, "defaultCurrency"?, "simplifyDebts"?, "defaultSplit"?, "type"?, "coverImageId"?: string\|null}`. Clients may send only `coverImageId: null`; a non-null value comes only from `PUT /groups/{id}/cover` |
| `group.deleted` | `{}`, any active member |
| `group.restored` | `{}`, any active member |
| `recurrence.created` | `+ "remindDaysBefore"?: 1..7 \| null` (missing = null) |
| `recurrence.updated` | `+ "remindDaysBefore"?: 1..7 \| null`, a sibling of `fields` (present → set, null clears) |

```json
{"clientId": "5f0c…", "type": "group.updated", "payload": {"type": "trip"}, "createdAt": "2026-11-02T09:00:00Z"}
{"clientId": "7a1d…", "type": "group.deleted", "payload": {}, "createdAt": "2026-11-02T09:01:00Z"}
```

**Applier rules:**
17. **Group type, cover, deleted.**
    - `group.created` sets `type`, and a present `group.updated.type` replaces it.
    - `coverImageId`: present → replaced (null clears), missing → kept.
    - `group.deleted` sets `deleted = true` and `group.restored` sets it false; the last in seq order wins. Neither touches members, expenses or payments.
    - The app shows an unknown `type` as Other.
18. **Reminder setting.** `RecurrenceDto` gains `remindDaysBefore` (default null), set by `recurrence.created` and by a present `recurrence.updated.remindDaysBefore` (ignored for an unknown or deleted series).

Old events get the defaults. Old apps ignore the new types and fields (no releases before parity).

**Activity:**
- New kinds `group_deleted` and `group_restored` (fill `name`), push category `members`. Sentences: "{A} deleted the group “{name}”", "{A} restored the group “{name}”".
- `group_updated` changes add `type` ("type {to}", using `words.groupType`: Trip / Home / Couple / Other) and `coverImageId` ("cover photo").
- The `group_deleted` activity row offers **Restore** in the app.

**DTOs:**
```
GroupDto        {"id","name","defaultCurrency","inviteCode","createdAt","latestSeq","myMemberId","simplifyDebts","defaultSplit","kind","type","coverImageId","deleted"}
GroupSummaryDto {"id","name","defaultCurrency","latestSeq","memberCount","kind","type","coverImageId","deleted"}   (GET /groups includes deleted groups)
UserDto         {"id","displayName","homeCurrency","language","email": string|null,"emailBounced": bool}
NotificationPrefs {"expenses","comments","members","reminders","emailDigest": "auto","emailDigestEffective": "daily"}
                  (emailDigest optional in PUT, missing = unchanged; emailDigestEffective read-only: "daily"|"weekly"|"monthly"|"off", "off" when there is no email)
AccountExport   {"exportedAt","user":{"id","displayName","email","homeCurrency","language"},"paymentMethods":[PaymentMethod],
                 "notifications": NotificationPrefs,"groups":[SnapshotDto, …]}
```

**Endpoints:**

| Method | Path | Auth | Request | Response / errors |
|---|---|---|---|---|
| GET | `/info` | public | | Phase 9 keys + `"emailLogin","appleLogin","googleLogin","supportEmail"` |
| POST | `/groups` | ✓ | adds `"type"?` | as before; bad type → 400 `VALIDATION` |
| POST | `/auth/email/start` | public | `{"email"}` | 204 whether or not an account exists. 400 `VALIDATION` / `EMAIL_NOT_CONFIGURED` / `EMAIL_REJECTED`, 429, 503 `EMAIL_UNAVAILABLE` |
| POST | `/auth/email/verify` | public | `{"email","code"}` | `AuthResponse`. 400 `CODE_INVALID` (wrong, expired, used, or too many attempts), 429 |
| POST | `/me/email` | ✓ | `{"email"}` | 204 (code sent to the new address); errors as `start` |
| POST | `/me/email/verify` | ✓ | `{"email","code"}` | `UserDto`. 400 `CODE_INVALID`; 409 `EMAIL_TAKEN` |
| DELETE | `/me/email` | ✓ | | 204. 409 `EMAIL_REQUIRED` when email is the only sign-in |
| GET / PUT | `/me/notifications` | ✓ | `NotificationPrefs` | `NotificationPrefs`. Bad value → 400 `VALIDATION` |
| POST | `/devices` | ✓ | adds `"notificationsAllowed"?: bool` (missing = true) | 204 |
| POST | `/me/logout-all` | ✓ | | 204 |
| GET | `/me/export` | ✓ | | `AccountExport` with `Content-Disposition: attachment; filename="evensies-export-YYYY-MM-DD.json"`. 429 |
| GET | `/me/blocks` | ✓ | | `[{"userId","displayName"}]` |
| PUT / DELETE | `/me/blocks/{userId}` | ✓ | | 204. 400 `VALIDATION` (self); 404 unknown user |
| POST | `/groups/{id}/members/{memberId}/invite-email` | member | `{"email"}` | 204 (also when silently skipped). 400 `VALIDATION` / `EMAIL_NOT_CONFIGURED` / `EMAIL_REJECTED`, 404 (member, or group deleted), 409 `MEMBER_TAKEN`, 429, 503 |
| PUT | `/groups/{id}/cover` | member | multipart `file`: JPEG, ≤ 1 MB, edges ≤ 2048 | `{"coverImageId","latestSeq"}`. 400 `NOT_JPEG` / `IMAGE_TOO_LARGE`, 413 `TOO_LARGE`, 403, 429 |
| GET | `/groups/{id}/cover/{coverId}` | member | | `image/jpeg`. 403; 404 if not current |
| GET / POST | `/email/unsubscribe?t=` | public | POST body may be `List-Unsubscribe=One-Click` | `text/html`; a bad token → a 400 HTML page |
| POST | `/webhooks/email` | Svix signature | Resend event JSON (only `type` and `data.to` are read) | 204; 401 bad or old signature; 404 when the secret is empty |
| POST | `/dev/jobs/email` | dev-login only | | 204 |

**Validation:**
- **Email:** trimmed and lower-cased; ≤ 254 characters; `^[^\s@]{1,64}@[a-z0-9-]+(\.[a-z0-9-]+)+$` (no SMTPUTF8).
- **Code:** `^\d{6}$`.
- **Group type:** one of the four; a present `type: null` → 400.
- **`remindDaysBefore`:** an integer 1–7 or null, else 400 `VALIDATION`.
- **UPI:**

  | type | value | extra fields | check | limit |
  |---|---|---|---|---|
  | `upi` | UPI ID (VPA) | `holder` optional, 1–70 characters | `^[A-Za-z0-9._-]{2,256}@[A-Za-z][A-Za-z0-9]{1,63}$` | 1 per user (total still 8) |

**Rate limits** (anti-spam caps, not product limits):

| What | Limit | Over the limit |
|---|---|---|
| `/auth/email/start`, `/auth/email/verify` | 10 per minute per IP (own `RateLimiter`) | 429 |
| Codes per address | 5 per hour (`email_log`) | 429 |
| Wrong code | 5 attempts, then the code is dead | 400 `CODE_INVALID` |
| Invite emails per inviter | 20 per 24 h | 429 |
| Invite emails per address | 3 per 7 days; per member 1 invite + 1 reminder | skipped silently, 204 |
| Cover uploads | 20 per user per hour | 429 |
| Account export | 3 per user per hour | 429 |
| `EVENSIES_EMAIL_DAILY_LIMIT` (rolling 24 h, 0 = off) | digests and recurring reminders stop at 80%, invites at 100%; codes are always sent | wait for the next run; invites → 429 "Email limit reached for today — share the link instead" |

`docs/API.md` and `docs/index.md` also describe the 50-member and 100-group caps publicly as abuse caps: "far above any real group, ask if you hit them".

**Templates** (`strings.json` `email.*`, en shown; all 13 languages; plain text; From: `EVENSIES_EMAIL_FROM`):

| kind | Subject | Body | Unsubscribe |
|---|---|---|---|
| `login_code` | `{code} is your Evensies code` | "Your sign-in code is {code}. It expires in 10 minutes. If you didn't ask for it, ignore this email — nobody can sign in without the code." | none |
| `change_code` | `{code} is your Evensies code` | "Enter {code} in the app to use this address for your Evensies account. It expires in 10 minutes." | none |
| `invite` | `{inviter} invited you to "{group}" on Evensies` | "Hi {placeholder name},\n\n{inviter} added you to "{group}" on Evensies, an app for splitting shared expenses.\n\nJoin the group: {publicUrl}/j/{code}?m={memberId}\nOr install Evensies and enter the code {ABC-DEF}.\n\nEvensies is free and open source, with no ads.\n\n—\nYou got this email because {inviter} entered your address. We keep it for 14 days to send one reminder, then delete it.\nDon't want invites from Evensies? {unsubscribeUrl}" | `invites` |
| `invite_reminder` | `Reminder: {inviter} invited you to "{group}"` | same as `invite` | `invites` |
| `recurring_reminder` | `"{description}" ({amount}) will be added on {date}` | "Hi {name},\n\n"{description}" in {group} repeats {frequency} and will be added on {date}. Your share: {share}.\nTo change or stop it, edit the latest one in the app.\n\n—\nYou get this because {creator} turned on reminders for this repeating expense.\nUnsubscribe: {unsubscribeUrl}" | `digest` |
| `digest` | daily/weekly: `{n} update(s) in {group}` or `{n} updates in {group} and {k} other group(s)`; monthly: `Your Evensies summary for {Month YYYY}` | "Hi {name},\n\n{Group}\n• {sentence}\n…\n\nYour balances\n• {Group}: you owe €15.00\n\nOpen the Evensies app to see details.\n\n—\n{reason}\nUnsubscribe: {unsubscribeUrl}". `{reason}` = "You get this daily because notifications are off on your devices." (auto) or "You get this {daily\|weekly\|monthly} summary because you chose it in Settings → Notifications." | `digest` |

**New error codes:** `EMAIL_NOT_CONFIGURED` 400, `EMAIL_REJECTED` 400, `CODE_INVALID` 400, `EMAIL_TAKEN` 409, `EMAIL_REQUIRED` 409, `EMAIL_UNAVAILABLE` 503. Images reuse Phase 6's codes.

**Migration `V11__email_and_account.sql`:**
```sql
-- Account email. Only verified addresses are stored: an id-token claim with email_verified, or a code we sent.
ALTER TABLE users ADD COLUMN email text;
CREATE UNIQUE INDEX users_email_active ON users (email) WHERE deleted_at IS NULL;

-- Group type, cover, delete/restore. archived_at was never read or written. Cover files live in FileStore covers/.
ALTER TABLE groups RENAME COLUMN archived_at TO deleted_at;
ALTER TABLE groups ADD COLUMN type text NOT NULL DEFAULT 'other' CHECK (type IN ('trip', 'home', 'couple', 'other'));
ALTER TABLE groups ADD COLUMN cover_image_id uuid;

-- Whether the OS lets this device show notifications ("auto" digests go to people who can't get push).
ALTER TABLE devices ADD COLUMN notifications_allowed boolean NOT NULL DEFAULT true;

-- Digest choice and window (window = events.feed_id from Phase 2).
ALTER TABLE notification_prefs ADD COLUMN email_digest text NOT NULL DEFAULT 'auto'
    CHECK (email_digest IN ('auto', 'daily', 'weekly', 'monthly', 'off'));
ALTER TABLE notification_prefs ADD COLUMN last_digest_at timestamptz;
ALTER TABLE notification_prefs ADD COLUMN last_digest_feed_id bigint NOT NULL DEFAULT 0;

-- Reminder email before a repeating bill posts (rule 18).
ALTER TABLE recurrences ADD COLUMN remind_days_before smallint CHECK (remind_days_before BETWEEN 1 AND 7);
ALTER TABLE recurrences ADD COLUMN reminded_occurrence int NOT NULL DEFAULT 0;   -- scheduler-owned

CREATE TABLE user_blocks (
    blocker    uuid NOT NULL REFERENCES users (id),
    blocked    uuid NOT NULL REFERENCES users (id),
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (blocker, blocked)
);

CREATE TABLE email_codes (
    email      text NOT NULL,
    purpose    text NOT NULL CHECK (purpose IN ('login', 'change')),
    user_id    uuid REFERENCES users (id),      -- 'change': who asked
    code_hash  text NOT NULL,                   -- HMAC, never the code
    expires_at timestamptz NOT NULL,
    attempts   int NOT NULL DEFAULT 0,
    PRIMARY KEY (email, purpose)
);

-- Third-party addresses typed by an inviter; purged 14 days after sent_at.
CREATE TABLE email_invites (
    member_id   uuid PRIMARY KEY REFERENCES members (id),
    group_id    uuid NOT NULL REFERENCES groups (id),
    email       text NOT NULL,
    invited_by  uuid NOT NULL REFERENCES users (id),
    sent_at     timestamptz NOT NULL DEFAULT now(),
    reminded_at timestamptz
);

-- Addresses we must not email except for codes they request. sha256 hex of the lower-cased address.
CREATE TABLE email_suppressions (
    email_hash text PRIMARY KEY,
    reason     text NOT NULL CHECK (reason IN ('unsubscribe', 'bounce', 'complaint')),
    created_at timestamptz NOT NULL DEFAULT now()
);

-- One row per sent email; drives budgets and per-address limits. Purged after 30 days.
CREATE TABLE email_log (
    id      bigserial PRIMARY KEY,
    kind    text NOT NULL,                      -- login_code, change_code, invite, invite_reminder, digest, recurring_reminder
    to_hash text NOT NULL,
    user_id uuid,                               -- account charged: the inviter for invites, the recipient otherwise
    sent_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX email_log_to_hash ON email_log (to_hash, sent_at);
CREATE INDEX email_log_sent_at ON email_log (sent_at);
```

**Environment** (`docs/API.md`, `deploy/.env.example`; Mailpit in `docker-compose.dev.yml`):

| Variable | Default | Meaning |
|---|---|---|
| `EVENSIES_SMTP_HOST` | (empty) | Empty turns all email off. Resend: `smtp.resend.com`; dev: `localhost` (Mailpit) |
| `EVENSIES_SMTP_PORT` | `587` | |
| `EVENSIES_SMTP_USER` / `EVENSIES_SMTP_PASSWORD` | | Resend: `resend` / API key (a secret: `.env` only) |
| `EVENSIES_SMTP_TLS` | `starttls` | `starttls`, `ssl`, `none` (Mailpit only) |
| `EVENSIES_EMAIL_FROM` | `Evensies <no-reply@localhost>` | Must be on a verified domain |
| `EVENSIES_EMAIL_DAILY_LIMIT` | `0` | 0 = no cap; `100` on Resend Free |
| `EVENSIES_EMAIL_WEBHOOK_SECRET` | | Resend `whsec_…`; empty turns the webhook off |
| `EVENSIES_SUPPORT_EMAIL` | | Help & feedback and Report; empty = GitHub only, no Report |

**Release-time setup, Hyojun only** (about 15 minutes; not needed before parity):
1. Create a Resend account in the EU region.
2. Add domain `evensies.nariinfo.dev` with SPF, DKIM and DMARC `p=none`.
3. Put the API key in `deploy/.env`.
4. Add the webhook to `/webhooks/email`.
5. Register `no-reply@evensies.nariinfo.dev` with Apple (Sign in with Apple → Email Communication), so `@privaterelay.appleid.com` addresses get mail.
6. Set `EVENSIES_SUPPORT_EMAIL`.

Everything else runs locally: the capturing sender in tests, and Mailpit on the simulator.

**`docs/privacy.md`** adds:
- the email address (verified, never shown to other members);
- Resend as processor (EU);
- invite addresses kept at most 14 days;
- suppressions and the log stored as hashes, the log for 30 days;
- blocks;
- export everything.

### Shared fixtures
- **`shared/sync-cases.json`.**
  - `_doc` defaults: `group.type` = `"other"`, `group.coverImageId` = null, `group.deleted` = false, recurrence `remindDaysBefore` = null.
  - `GroupState.groupJson()` / `actual()` gain the three keys.
```json
{"name": "legacy group.created without type is other; name update keeps type",
 "events": [
  {"seq": 1, "clientId": "g1", "type": "group.created", "payload": {"name": "Flat", "defaultCurrency": "EUR"}},
  {"seq": 2, "clientId": "g2", "type": "group.updated", "payload": {"name": "Flat 3B"}}],
 "expected": {"group": {"name": "Flat 3B", "defaultCurrency": "EUR", "type": "other", "coverImageId": null, "deleted": false}, "members": [], "expenses": [], "payments": []}},
{"name": "type set on create; cover kept when only type changes",
 "events": [
  {"seq": 1, "clientId": "g1", "type": "group.created", "payload": {"name": "Rome", "defaultCurrency": "EUR", "type": "trip"}},
  {"seq": 2, "clientId": "g2", "type": "group.updated", "payload": {"coverImageId": "c1"}},
  {"seq": 3, "clientId": "g3", "type": "group.updated", "payload": {"type": "home"}}],
 "expected": {"group": {"name": "Rome", "defaultCurrency": "EUR", "type": "home", "coverImageId": "c1", "deleted": false}, "members": [], "expenses": [], "payments": []}},
{"name": "deleted group still takes offline edits; restore shows them", "permute": true,
 "events": [
  {"seq": 1, "clientId": "g1", "type": "group.created", "payload": {"name": "Rome", "defaultCurrency": "EUR", "type": "trip"}},
  {"seq": 2, "clientId": "g2", "type": "member.added", "payload": {"memberId": "m1", "name": "Anna", "userId": null}},
  {"seq": 3, "clientId": "g3", "type": "group.deleted", "payload": {}},
  {"seq": 4, "clientId": "g4", "type": "expense.created", "payload": {"expenseId": "x1", "description": "Taxi", "amount": 1200, "currency": "EUR", "fxRateToDefault": null, "paidBy": "m1", "date": "2026-11-02", "category": null, "shares": [{"memberId": "m1", "amount": 1200}]}},
  {"seq": 5, "clientId": "g5", "type": "group.restored", "payload": {}}],
 "expected": {"group": {"name": "Rome", "defaultCurrency": "EUR", "type": "trip", "coverImageId": null, "deleted": false},
  "members": [{"id": "m1", "name": "Anna", "userId": null}],
  "expenses": [{"id": "x1", "description": "Taxi", "amount": 1200, "currency": "EUR", "fxRateToDefault": null, "paidBy": "m1", "date": "2026-11-02", "category": null, "deleted": false, "shares": [{"memberId": "m1", "amount": 1200}]}],
  "payments": []}},
{"name": "deleting twice stays deleted; null coverImageId clears the cover",
 "events": [
  {"seq": 1, "clientId": "g1", "type": "group.created", "payload": {"name": "Flat", "defaultCurrency": "EUR", "type": "home"}},
  {"seq": 2, "clientId": "g2", "type": "group.updated", "payload": {"coverImageId": "c1"}},
  {"seq": 3, "clientId": "g3", "type": "group.deleted", "payload": {}},
  {"seq": 4, "clientId": "g4", "type": "group.deleted", "payload": {}},
  {"seq": 5, "clientId": "g5", "type": "group.updated", "payload": {"coverImageId": null}}],
 "expected": {"group": {"name": "Flat", "defaultCurrency": "EUR", "type": "home", "coverImageId": null, "deleted": true}, "members": [], "expenses": [], "payments": []}}
```
  Plus "remindDaysBefore set on create, changed by update, ignored after stop".
- **`shared/activity-cases.json`:** `group_deleted`, `group_restored`, "Ben changed the group: type Trip", "Ben changed the group: cover photo", in en plus one `localized` case.
- **`server/src/test/resources/digest-cases.json`** (server only). Input: recipient, mode, each group's full event log, and `windowAfterSeq`.
```json
{"name": "daily: others' changes only, add-then-delete dropped, balances footer",
 "recipient": {"userId": "u1", "name": "Anna", "language": null},
 "mode": "daily", "reason": "auto",
 "groups": [{"windowAfterSeq": 3, "events": [
   {"seq": 1, "actorUserId": "u1", "type": "group.created", "payload": {"name": "Rome trip", "defaultCurrency": "EUR", "type": "trip"}},
   {"seq": 2, "actorUserId": "u1", "type": "member.added", "payload": {"memberId": "m1", "name": "Anna", "userId": "u1"}},
   {"seq": 3, "actorUserId": "u2", "type": "member.added", "payload": {"memberId": "m2", "name": "Ben", "userId": "u2"}},
   {"seq": 4, "actorUserId": "u2", "type": "expense.created", "payload": {"expenseId": "x1", "description": "Dinner", "amount": 3000, "currency": "EUR", "fxRateToDefault": null, "paidBy": "m2", "date": "2026-11-01", "category": null, "shares": [{"memberId": "m1", "amount": 1500}, {"memberId": "m2", "amount": 1500}]}},
   {"seq": 5, "actorUserId": "u2", "type": "expense.created", "payload": {"expenseId": "x2", "description": "Oops", "amount": 100, "currency": "EUR", "fxRateToDefault": null, "paidBy": "m2", "date": "2026-11-01", "category": null, "shares": [{"memberId": "m1", "amount": 50}, {"memberId": "m2", "amount": 50}]}},
   {"seq": 6, "actorUserId": "u2", "type": "expense.deleted", "payload": {"expenseId": "x2"}}]}],
 "expected": {"subject": "1 update in Rome trip",
  "text": "Hi Anna,\n\nRome trip\n• Ben added “Dinner” · €30.00 · you owe €15.00\n\nYour balances\n• Rome trip: you owe €15.00\n\nOpen the Evensies app to see details.\n\n—\nYou get this daily because notifications are off on your devices.\nUnsubscribe: {unsubscribeUrl}"}}
```
  Further cases:
  - "daily with no activity by others" → `"expected": null`;
  - "monthly with no activity but a non-zero balance" → subject `Your Evensies summary for November 2026`, balances only;
  - "de recipient" → German sentences and notation;
  - "blocked actor's lines are left out".

### Tests
- **Server.** Testcontainers and real HTTP. A capturing `JavaMailSender` bean records each message and can be set to throw `SendFailedException`. A fixed `Clock` bean controls time.
  - **`EmailLoginTest`:**
    - round trip; same address → same user;
    - a verified Google address X + email X → the same user; an unverified Google address isn't stored;
    - known and unknown addresses both return 204;
    - 5 wrong codes kill the code; expired fails; the 6th code in an hour → 429;
    - no plain code in the DB;
    - SMTP off → `EMAIL_NOT_CONFIGURED` and `/info.emailLogin=false`;
    - a 5xx → `EMAIL_REJECTED` and a suppression;
    - a `ko` user's code email is Korean.
  - **`AccountEmailTest`:** change with code; `EMAIL_TAKEN`; `EMAIL_REQUIRED`; verify clears suppression; `emailBounced`.
  - **`DigestBuilderTest`:** goldens.
  - **`NextDueTest`:** daily, weekly, monthly, month ends.
  - **`DigestJobTest`:**
    - Auto → daily without a push-capable device, monthly with one, daily when FCM is off;
    - the window advances on send and on nothing to say, not on budget or failure;
    - suppressed → nothing;
    - a deleted group → only its delete line;
    - the 80% budget stop;
    - `NotImplementedError` from balances still sends the lines.
  - **`RecurringReminderTest`:**
    - a 3-days-before series emails each involved member with an email exactly once per occurrence;
    - none after a stop, for a deleted group, or with `email_digest = 'off'`;
    - a blocked creator → none.
  - **`InviteEmailTest`:**
    - send; a second invite to the same member is a no-op;
    - the 4th to the same address in 7 days is silent; the inviter's 21st → 429;
    - `MEMBER_TAKEN`; a deleted group → 404;
    - one reminder after 3 days, none after linking;
    - purge at 14 days;
    - `?m=` passes through, and a non-UUID is dropped.
  - **`UnsubscribeTest`:** GET changes nothing; POST and one-click do; tampered → 400; `digest` → off; `invites` → suppression; headers only on invites, digests and recurring reminders.
  - **`EmailWebhookTest`:** valid bounce or complaint → suppression (complaint also turns the digest off); bad or old signature → 401; empty secret → 404.
  - **`GroupTypeCoverDeleteTest`:**
    - create with type; invalid type → 400;
    - client non-null `coverImageId` → 400;
    - a cover upload writes an event and a member can GET it; non-member → 403; old id → 404;
    - GPS EXIF stripped; a 20000 px header → `IMAGE_TOO_LARGE` without decoding;
    - delete and restore by any member; events after a deletion are stored and applied;
    - the abuse cap ignores deleted groups;
    - the scheduler skips a deleted group, and a restore doesn't post the missed period;
    - a friend-pair `POST /friends` on a deleted friend group appends `group.restored`.
  - **`BlockTest`:**
    - a blocked user's `POST /friends` by code → 404 and by userId → 403;
    - their reminder → 200 with no push;
    - their events → no visible push and no digest line for the blocker; data-only sync still goes out;
    - unblock restores all of these;
    - account deletion removes block rows in both directions.
  - **`AccountTest`:**
    - logout-all makes both devices' refresh tokens fail;
    - export contains every group, deleted ones included;
    - delete account clears email, name, prefs, sent invites and blocks.
  - **`PaymentMethodsTest`:** valid and invalid UPI IDs; a second `upi` → 400.
  - **`EventApplierTest`:** the new shared cases, with the group comparison.
- **App:**
  - `apply_event_test`: the new cases and the `groupJson` comparison.
  - `payment_methods_test`: the UPI link with an INR amount, no amount for EUR, encoded `pn`/`tn`.
  - Widget tests:
    - the email code form takes 6 digits only, and Resend unlocks after 30 s;
    - the create-group type chips send `type`;
    - email fields are hidden when `!emailLogin`;
    - the reminder dropdown sends `remindDaysBefore`;
    - deleted groups are left out of the groups list, Friends tab, overall card, search and widget payload.
  - drift 8→9 migration on an in-memory database keeps rows and adds the defaults.
- **Simulator** (local server + Mailpit at `localhost:8025`, light and dark):
  1. Sign in with an email code, on the simulator and in Chrome at `/app/`.
  2. Add and change the account email.
  3. Invite a placeholder by email. Open the Mailpit link in Safari: the app opens with the name preselected.
  4. `POST /dev/jobs/email` with the clock moved forward: the reminder arrives once.
  5. With dev-login user B's push off, B's daily digest has the right sentences and balances.
  6. A repeating expense with "3 days before" sends one reminder email.
  7. Unsubscribe page: GET, then the button.
  8. Set the type and cover; check the header and list thumbnail.
  9. Delete a group: it disappears for both users; restore it from Settings.
  10. Delete a friend and add them again: the history comes back.
  11. Block a user: their reminder doesn't arrive.
  12. Export everything.
  13. Sign out everywhere: a second session is logged out.
  14. UPI link: Safari reports the scheme, which shows the right link was built.

### Hyojun's part
None. This phase writes no money logic. It calls his functions in one place: the digest's "Your balances" section, through `Balances.ofGroup` (Phase 6). That uses the Kotlin ports of his Phase 3 multi-payer balances and Phase 4 conversion rounding.
- Until those ports exist they throw `NotImplementedError`. The digest catches only that error and leaves the balances section out; the activity lines still go.
- A monthly digest with no activity is then skipped.
- The recurring reminder's "Your share" comes from the template's stored shares, not from his functions.

### Depends on other phases
- **Phase 2:** the feed meta and `feed_id`, `notification_prefs`, the activity Restore row.
- **Phase 3:** the group settings screen (it gains type, cover and delete) and rule 11's key handling.
- **Phase 4:** per-currency balances in the digest.
- **Phase 6:** `FileStore`, `Jpeg.clean`, `prepareJpeg`, friend groups (delete friend), reminders (blocks), `Balances.ofGroup`.
- **Phase 7:** group delete keeps receipt files; receipts are exported through the per-group ZIP.
- **Phase 8:** the scheduler, `@EnableScheduling`, the daily sweep (covers), and `remindDaysBefore` on its series.
- **Phase 9:** `users.language`, `strings.json` (`email.*` plus the new kinds in all 13 languages), `GET /info`, the web build (email sign-in works on web).

### Left out (deliberately)
| What | Why |
|---|---|
| Passwords, password reset | Email codes replace both, and there is no password store to leak |
| Magic links | Codes work across devices and need no universal-link routing |
| Phone number on the account, SMS invites (#93, #45) | SMS costs money per message; the system share sheet already reaches Messages, WhatsApp and contacts |
| Contacts plugin and permission | The share sheet suggests contacts; no new dependency and no permission prompt |
| Auto-linking existing users by email | It would put a person into a group without consent; they claim the placeholder instead |
| Instant per-event emails, per-type email toggles | Noisy and they burn the free tier; push plus one digest cover it |
| HTML emails | Plain text renders everywhere |
| Marketing or "news" emails | Against the promises |
| Hiding shared groups of a blocked user | Balances must stay visible; the block mutes the person instead |
| Merging duplicate members (#47) | Would rewrite history; the claim flow and the preselected email invite prevent duplicates |
| Instant access-token revocation | 15-minute ceiling, marked `ponytail:` |
| Hard purge of deleted groups | Restore must always work, and members can export |
| Cover moderation | Covers are visible only to the group's members |
| Async bounces from relays other than Resend | Synchronous 5xx only |
| A per-user time zone | Digests use UTC; Phase 8 keeps a zone per series |
| Raising the 50/100 caps | Documented as abuse caps instead |

### Done when
- A server with no SMTP settings runs exactly as before: no email UI, no errors in the log.
- With Mailpit, on the simulator:
  - email-code sign-in and adding or changing the account email work;
  - an invite link opens the join screen with the placeholder preselected;
  - the single invite reminder arrives on a forced job run;
  - a user whose devices can't show notifications gets a daily digest in their language with correct balances;
  - a repeating bill's reminder arrives once;
  - both unsubscribe links work.
- Group types and covers show on the list and header in light and dark mode.
- Deleting a group or a friend hides it for every member, and any member can restore it with nothing lost.
- Blocking mutes the person.
- "Export everything" produces one JSON file with all groups.
- "Sign out everywhere" ends a second session.
- A UPI link carries the INR amount.
- All server and app tests are green, including the new sync cases on both appliers.
- `docs/API.md`, `docs/privacy.md` and `deploy/.env.example` were updated before the code.

---
