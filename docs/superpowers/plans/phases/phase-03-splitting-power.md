# Phase 3 design — Splitting power

Phase 3 adds fields to events that already exist. It adds no new event types, endpoints, services or dependencies. **Cost: 0.** Offline editing, the outbox and sync keep working as they do now. This phase also sets the conventions that every later phase follows.

### Conventions for Phases 3–10
- **Order and numbering.** Phases land in order, on top of Phase 2. Phase 2 is already in the tree: migration V4, applier rules 1–9, drift `schemaVersion` 3. The numbers below are fixed and need no "next free" lookups.

  | Item | Phase 3 | Phase 4 | Phase 5 | Phase 6 | Phase 7 | Phase 8 | Phase 9 | Phase 10 |
  |---|---|---|---|---|---|---|---|---|
  | Server migration | V5 | V6 | none | V7 | V8 | V9 | V10 | V11 |
  | drift `schemaVersion` | 4 | 5 | — | 6 | 7 | 8 | — | 9 |
  | Applier rules | 10–12 | — | — | 13 | 14 | 15–16 | — | 17–18 |
- **Pending fixtures.** A shared case marked `"pending": "hyojun"` needs a Hyojun function that hasn't landed yet. It is reported as **skipped**, never as failed:
  - Dart: `skip: c['pending'] == null ? null : 'pending: hyojun'`
  - Kotlin: `assumeTrue(case["pending"] == null)`

  The push that lands his function removes every pending key it satisfies. Claude's Kotlin port goes into the same push. Parity is done when `grep -r '"pending"' shared/` finds nothing.
- **`shared/sync-cases.json` defaults.** The file's `_doc` lists the default for every key that an expected object may leave out. Today that is `removed=false`, `notes=null`, `comments=[]`. Each phase adds to that list and leaves old cases alone.
  - `expected.group` is optional. When it is present, only the keys it contains are compared.
  - The comparison is against `GroupState.groupJson()` in Dart and `actual()["group"]` in Kotlin.
  - Today those objects hold `{name, defaultCurrency}`. Later phases add keys to them.
- **Text.** Every new activity kind or change label gets three things: an English sentence in `ActivityText.kt`, the same sentence in `domain/activity.dart`, and a golden in `shared/activity-cases.json`. Phase 9 moves all of them into `shared/strings.json`.
  - The server sends the feed as structured data, and the app renders it.
  - Push and email text is always rendered by the server, for each recipient.
- **No 400 for state an offline client can't know about.** Use an applier rule or a validator `normalize` step instead. The safety net is the rejected-event handling defined in this phase.
- **Hyojun stubs.**
  - Dart stubs throw `UnimplementedError`, and callers wrap them in `tryCore`.
  - Kotlin stubs are `TODO()`, which throws `NotImplementedError`. Server callers catch only that error and degrade.
- **Verification.** Every phase is checked with:
  - server tests on Testcontainers over real HTTP;
  - app unit and widget tests;
  - the local server and the iOS simulator, in light and dark mode.

  No phase needs a paid account to be built or tested. Steps that need a person in a console are listed per phase, and they are all release-time.

### What users get
1. **Five ways to split.**
   - **Equal**, now with a tick box per person so people can be left out.
   - **Exact.**
   - **Percent.**
   - **Shares**, e.g. "Anna 2 · Ben 1 · Kid 0", with the live amount on each row.
   - **Adjustment**, e.g. "Cara +€10.00, the rest split equally".
2. **Full-amount shortcuts** when the group has exactly two active members: "Ben owes the full amount" and "I owe Ben the full amount". Each chip sets the payer and the split in one tap.
3. **Multiple payers.** "Paid by" gets a **Several people** chip. It opens per-person amount fields with an "€12.00 left to assign" line.
4. **Refunds.** A **Refund** chip, for cases like "the hotel gave €60 back to Anna". The labels change to "Received by" and "Split back to", and the refund lowers what people owe.
5. **Edits keep the split method.** An expense split by shares, adjustment, percent or a ticked subset reopens in that mode with the numbers that were typed.
6. **Group settings screen** (gear icon in the group's app bar). Any member can change these settings; there are no admins.
   - Rename the group.
   - Change the default currency, but only while the group has no expenses or payments, deleted ones included.
   - **Simplify debts** switch, on by default. The text under it reads: "Combines debts so the group needs fewer payments. Nobody's total changes, only who pays whom."
   - **Default split** (percent or shares).
   - **Leave group**, enabled only when your balance is zero. Otherwise it shows "Settle up first".
7. **Simplify debts off.** Settle up then lists debts the way they arose: each expense on its own, netted per pair of people. Example: "Ben owes Anna €10, Cara owes Ben €10".
8. **One rejected change no longer blocks the rest.** If the server refuses a change, the app drops only that change and says why ("A change couldn't be saved: the payers don't add up"). Everything else syncs.

### How (server)
- **No new endpoints.**
  - Group settings travel in `group.updated`.
  - Expense fields travel in `expense.created` / `expense.updated`.
  - Leaving a group is `member.removed` sent for your own member. `requireMember` already ignores removed members, so the group drops out of `GET /groups` and returns 403 afterwards.
- **Migration `V5__splitting_power.sql`** (see Contract changes) adds:
  - `expense_payers`, backfilled from `paid_by`;
  - `expenses.refund` and `expenses.split`;
  - `groups.simplify_debts` and `groups.default_split`.

  `expenses.paid_by` stays `NOT NULL` and holds the **primary payer**.
- **EventApplier (Kotlin).**
  - `ExpenseDto` gains `payers: List<ShareDto>`, `refund: Boolean` and `split: JsonNode?`. The applier fills `paidBy` with `primaryPayer(payers)`.
  - `GroupState` gains `simplifyDebts = true` and `defaultSplit: JsonNode? = null`.
  - Rules 10–12 are under Contract changes. `split` and `defaultSplit` are stored as raw JSON.
- **EventValidator.**
  - Payer, refund and split checks go in `validateExpense`. Type checks run on the raw payload; sum checks run on the applied expense.
  - `group.updated` gets checks for its new keys. There is **no** currency-lock error: rule 12 ignores a late `defaultCurrency`, because an offline client can't know that someone already added an expense.
  - `normalize` also rewrites `paidBy` to the primary payer whenever the payload or `fields` carries `payers`.
- **GroupStateStore.**
  - Payers are saved by delete-and-reinsert, as shares are.
  - `refund` is saved as a column, and `split` with `CAST(:split AS jsonb)`.
  - The group branch also writes `simplify_debts` and `default_split`.
  - `Group` / `GroupDto` carry `simplifyDebts` and `defaultSplit`. They appear in `POST /groups`, `GET /groups/{id}` and the snapshot.
- **Activity** (Phase 2 `Activity.kt` + `ActivityText.kt`): the new kind and change labels listed under Contract changes.
- **CSV export.**
  - The `paidBy` cell holds the payer's name, or `Anna 60.00; Ben 40.00` when several people paid.
  - Refund rows get a negative `amount` and negative share cells.
- **Splitwise import fix** (an existing bug).
  - Splitwise's CSV gives each person's net per row (paid − owed). Today the importer takes the largest net as the payer and drops every other positive net. Example: Cost 100.00 with nets Anna +26.66, Ben +6.67, Cara −33.33 imports with Ben at 0 and no error.
  - New rule:
    - Every member with a positive net pays that net.
    - The member with the largest net also pays and owes the slack `s = Cost − Σ positive nets`.
    - Members with a negative net owe −net.
    - The row is rejected if `s < 0`.
  - For the example: payers Anna 93.33 and Ben 6.67; shares Cara 33.33 and Anna 66.67.
  - Rows with one positive net import exactly as today.
- **Kotlin money ports** (`Split.compute` SHARES/ADJUSTMENT, `Settlement.balances` with payers and refunds).
  - Claude ports Hyojun's Dart in the same push that lands it, and Hyojun reviews.
  - Until then they are `TODO()` stubs and their cases are `pending`.
  - They have no runtime caller until Phase 6 (reminders) and Phase 10 (digest).

### How (app)
- **Models** (`domain/models.dart`).
  - `Expense` takes `payers: List<Share>`. `paidBy` becomes a getter that returns the primary payer. New fields `refund` and `split: SplitSpec?`.
  - `class SplitSpec { final SplitMode mode; final Map<String, double>? input; }` with JSON.
  - `GroupState` gains `simplifyDebts` and `defaultSplit`.
  - `GroupState.groupJson()` returns `{name, defaultCurrency, simplifyDebts, defaultSplit}`.
  - `fromJson` defaults: missing `payers` → `[{paidBy, amount}]`, `refund` → false, `split` → null, `simplifyDebts` → true.
- **Applier** (`apply_event.dart`): rules 10–12, written by Claude.
- **drift (schemaVersion 4).**
  - New table `ExpensePayers`, a copy of `ExpenseShares`.
  - New columns `Expenses.refund`, `Expenses.splitJson`, `Groups.simplifyDebts`, `Groups.defaultSplitJson` and `Outbox.rejected` (text, nullable).
  - `onUpgrade` backfills with `INSERT INTO expense_payers (expense_id, member_id, amount) SELECT id, paid_by, amount FROM expenses`.
  - `GroupStateStore`, `LocalWrites.createExpense` / `updateExpense`, `deleteGroupData` and `adoptFromSnapshot` handle the new fields.
- **Split editor** (`features/expense_form/split_editor.dart`). The per-member rows move into one widget, which the default-split sheet reuses.
  - Equal: a tick box per member.
  - Shares: a count field per member (default 1) plus the live amount.
  - Adjustment: a signed money field per member plus the live amount.
  - The existing "remaining / over by / Adds up" line also shows split errors (`NEGATIVE_SHARE` → "Adjustments don't fit the total").
  - Segmented control: Equal · Exact · % · Shares · ±.
- **Expense form.**
  - **Paid by:** one chip per member plus **Several people**. That opens payer fields with their own "left to assign" line. Empty or zero fields are dropped, and Save requires the payers to sum to the amount.
  - **Refund:** a `FilterChip` next to Category.
  - **Full-amount chips** appear only in two-active-member groups. Each sets one payer plus equal with one participant ticked.
  - **What goes into `shares`:** equal → only the ticked members; other modes → every member shown, zeros included.
  - **What goes into `split`:** `{"mode":"equal"}` for equal, the typed numbers for percent / shares / adjustment, and `null` for exact.
  - **New expense:** starts from `group.defaultSplit` if set, otherwise equal with everyone ticked.
  - **Editing:**
    - recompute `computeSplit(amount, split.mode, shares' memberIds, split.input)`;
    - if it matches the stored shares (ignoring zero entries), open in that mode;
    - otherwise, or if `tryCore` returns null, open in exact.
  - **Sending updates:** when any money field changes (`amount`, `payers`, `shares`, `split`, `refund`), `fields` carries all of them plus `paidBy`.
- **Expense tile.**
  - Several payers: "paid by Anna +1".
  - Refund: "refund to Anna".
  - "you lent / you borrowed" uses `sign × (myPaid − myShare)`, where sign = −1 for a refund.
- **Group settings screen** (`features/group_settings/group_settings_screen.dart`, route `/groups/:id/settings`).
  - Fields: name; currency dropdown (disabled with "Can't change after the first expense or payment" once any expense or payment exists, deleted ones included); Simplify debts `SwitchListTile` with its explanation; Default split (a sheet with the split editor limited to % and Shares, plus "Use equal"); Leave group.
  - Writes go through `LocalWrites.updateGroup(…, simplifyDebts:, defaultSplit:, clearDefaultSplit:)`, which sends only the keys that are present.
- **Leave group** (`LocalWrites.leaveGroup`), online only:
  1. Run `sync(groupId)`. It throws when offline: "You need to be online to leave".
  2. Run `api.pushEvents([member.removed {memberId: me}])` directly, not through the outbox.
  3. Run `db.deleteGroupData(groupId)` and go to the groups list.
  - `SyncService.syncAll` also deletes local groups that are missing from a successful `GET /groups`. This covers leaving on another device, or someone removing you.
- **Rejected events** (`SyncService.sync`).
  1. When the push gets 400 or 409, the app re-pushes that batch one event at a time, in order.
  2. Each event that is still refused is deleted from the outbox, and the app shows "A change couldn't be saved: {message for code}".
  3. The group is then rebuilt: `adoptFromSnapshot`, then re-apply the remaining unsent outbox events in order.
  - 401, 429, 5xx and network errors keep today's retry.
  - Accepted single events are stored idempotently by clientId, so the one-by-one pass is safe.
- **Balances** (`balancesOf`).
  - It builds `ExpenseLine(payers:, amount:, shares:, refund:)`. Payers are converted the same way as shares.
  - `BalanceResult` also returns the lines and payments it used, plus an `unsupported` count.
  - The balance function becomes a parameter (default `computeBalances`) so a test can pass a throwing stub.
- **Pairwise debts** (`pairwiseDebts`, Claude, `domain/settlement.dart`).
  - It only composes Hyojun's two functions: each line and each payment is settled on its own with `simplifyDebts(computeBalances(members, [line], []))`, or `([], [payment])` for a payment.
  - Transfers are summed per (from, to) and netted per pair. Zero pairs are dropped. The result is sorted by `from`, then `to`.
- **Settle up.**
  - Transfers are `group.simplifyDebts ? simplifyDebts(balances) : pairwiseDebts(lines, payments)`.
  - With simplify off, the header reads "Debts as recorded · simplify debts is off".
- **Degrading until Hyojun's code lands.**
  - New helper `bool implemented(void Function() f)` in `core/core_guard.dart`. It returns false only on `UnimplementedError`.
  - The Shares and ± segments are disabled (tooltip `notImplementedLabel`) while `implemented(() => computeSplit(amount: 0, mode: m, members: const ['a'], input: const {'a': 0}))` is false. A shares default split falls back to equal.
  - If `computeBalances` throws, `balancesOf` retries with only single-payer, non-refund lines. The others are counted as `unsupported`, and a card says "N expenses with several payers or refunds aren't counted yet".
  - Creating and syncing multi-payer and refund expenses works from day one.

### Contract changes
**Events** (`docs/API.md`, Korean prose with English identifiers).

`expense.created` gains `payers`, `refund` and `split`. `paidBy` is still sent and is the primary payer.
```json
{"expenseId": "…", "description": "Hotel", "amount": 10000, "currency": "EUR", "fxRateToDefault": null,
 "paidBy": "m-anna",
 "payers": [{"memberId": "m-anna", "amount": 6000}, {"memberId": "m-ben", "amount": 4000}],
 "refund": false,
 "split": {"mode": "shares", "input": {"m-anna": 2, "m-ben": 1, "m-cara": 1}},
 "date": "2026-10-11", "category": null, "notes": null,
 "shares": [{"memberId": "m-anna", "amount": 5000}, {"memberId": "m-ben", "amount": 2500}, {"memberId": "m-cara", "amount": 2500}]}
```
- `expense.updated`: `fields` may also contain `payers`, `refund` and `split`. The app sends `amount`, `paidBy`, `payers`, `shares`, `split` and `refund` together whenever any of them changes.
- `group.updated`: `{"name"?, "defaultCurrency"?, "simplifyDebts"?: bool, "defaultSplit"?: SplitSpec | null}`.
- `SplitSpec`: `{"mode": "equal" | "percent" | "shares" | "adjustment", "input"?: {"<memberId>": number}}`.
  - `input` is percent for percent, share count for shares, and minor units for adjustment. Equal has none.
  - An exact split is `split: null`.
  - `defaultSplit` allows only `percent` and `shares`.
  - Phase 7 adds mode `itemized`.

**Response shapes.**
```
GroupDto  {"id","name","defaultCurrency","inviteCode","createdAt","latestSeq","myMemberId","simplifyDebts","defaultSplit"}
snapshot expenses[] {…,"paidBy","payers":[{"memberId","amount"}],"refund","split",…}
```
`format=json` export is the snapshot, so it picks these up.

**Applier rules** (both appliers):
10. **Payers, refund, split.**
    - `payers` is the source of truth. `paidBy` is derived: the payer with the largest amount; on a tie, the lowest memberId.
    - `expense.created` without `payers` means `[{paidBy, amount}]`.
    - In `expense.updated`:
      - (a) `fields.payers` replaces the payers;
      - (b) otherwise `fields.paidBy` gives `[{paidBy, amount after this update}]`;
      - (c) otherwise `fields.amount` with exactly one payer moves that payer to the new amount;
      - (d) otherwise payers are unchanged.
    - A missing `refund` means false.
    - A missing `split` means null. An update that changes `shares` or `amount` without sending `split` sets it to null.
11. **Group settings.** In `group.updated`, an absent key means unchanged, and `"defaultSplit": null` clears it. Defaults: `simplifyDebts` true, `defaultSplit` null.
12. **Currency lock.** `group.updated.defaultCurrency` is ignored once the state has any expense or payment, deleted ones included (Phase 2 can restore them). `name` in the same event still applies. The server accepts the event.
    - Why: every `fxRateToDefault` and every payment amount is relative to the group currency.

**Validation** (400, whole batch):

| code | when |
|---|---|
| `PAYERS_SUM_MISMATCH` | Σ `payers[].amount` ≠ `amount` after the event is applied |
| `UNKNOWN_MEMBER` | a payer, a `split.input` key or a `defaultSplit.input` key is not in the group |
| `NEGATIVE_AMOUNT` | a payer amount < 0 |
| `SUM_MISMATCH` | `defaultSplit` in percent mode doesn't total 100 (±0.001) |
| `VALIDATION` | `payers` is not a non-empty array, or repeats a member; `refund` is not a boolean; `split` / `defaultSplit` is neither an object nor null; the mode is not allowed; an input value is not finite; a percent or share value < 0; an adjustment value is not whole; `defaultSplit` shares total 0; `simplifyDebts` is not a boolean |

The server does **not** recompute `shares` from `split`. `split` is a hint, and the editor verifies it when it loads.

**Activity** (API.md "활동·알림"):
- **New kind `member_left`.** A `member.removed` whose `memberId` is the actor's own member becomes `member_left` (fills `memberId`). Sentence: `{member} left the group`, with the member at the start. Push category `members`.
- **`group_updated` changes** add `simplifyDebts` (from/to booleans) and `defaultSplit` (from/to null).
  - Order: `name, defaultCurrency, simplifyDebts, defaultSplit`.
  - Labels: `simplify debts on` / `simplify debts off`, `default split`.
  - A `defaultCurrency` ignored by rule 12 is not a change.
- **`expense_updated` changes** add `payers` (from/to null), `refund` (booleans) and `split` (from/to null).
  - Order: `description, amount, currency, fxRateToDefault, paidBy, payers, refund, date, category, shares, split, notes`.
  - Labels:
    - `payers` → `payers`, left out when `amount` or `paidBy` also changed;
    - `refund` → `refund on` / `refund off`;
    - `split` → `split`, left out when `shares` or `amount` also changed.
- **`myDelta`** = sign × (my payer amount − my share), where sign = −1 for a refund.

**Migration `V5__splitting_power.sql`:**
```sql
-- Multiple payers (docs/API.md rule 10). expenses.paid_by stays as the primary payer for old readers and the CSV.
CREATE TABLE expense_payers (
    expense_id uuid     NOT NULL REFERENCES expenses (id) ON DELETE CASCADE,
    member_id  uuid     NOT NULL REFERENCES members (id),
    amount     bigint   NOT NULL,
    position   smallint NOT NULL,
    PRIMARY KEY (expense_id, member_id)
);
INSERT INTO expense_payers (expense_id, member_id, amount, position) SELECT id, paid_by, amount, 0 FROM expenses;
ALTER TABLE expenses ADD COLUMN refund boolean NOT NULL DEFAULT false, ADD COLUMN split jsonb;
ALTER TABLE groups ADD COLUMN simplify_debts boolean NOT NULL DEFAULT true, ADD COLUMN default_split jsonb;
```

### Shared fixtures
- **`settlement-cases.json` `_doc`.**
  - Fix the sign: it currently says "+ 받은 송금 − 보낸 송금", but the code and the cases use "+ sent − received".
  - Document `payers`, `refund`, `expectedPairwise` and `pending`.
- **`shared/split-cases.json`.** Modes now include `shares` and `adjustment`. Every new case is `pending`; the full list is under Hyojun's part. Four examples:
```json
{"name": "shares 2/1/0, leftover to lowest id with a share", "amount": 1000, "mode": "shares", "members": ["a", "b", "c"], "input": {"a": 2, "b": 1, "c": 0}, "expected": {"a": 667, "b": 333, "c": 0}, "pending": "hyojun"},
{"name": "shares leftover skips a zero-share lower id, unsorted input", "amount": 100, "mode": "shares", "members": ["c", "a", "b"], "input": {"a": 0, "b": 1, "c": 2}, "expected": {"a": 0, "b": 34, "c": 66}, "pending": "hyojun"},
{"name": "adjustment negative with remainder", "amount": 1000, "mode": "adjustment", "members": ["a", "b", "c"], "input": {"b": -100}, "expected": {"a": 367, "b": 267, "c": 366}, "pending": "hyojun"},
{"name": "percent leftover skips 0% members", "amount": 100, "mode": "percent", "members": ["a", "b", "c"], "input": {"a": 0, "b": 33.33, "c": 66.67}, "expected": {"a": 0, "b": 34, "c": 66}, "pending": "hyojun"}
```
- **`shared/settlement-cases.json`.**
  - An expense is either `{"paidBy"…}` (legacy) or `{"payers": {…}}`, plus an optional `"refund": true`.
  - `expectedPairwise` is checked only by Claude's `pairwiseDebts` test.
  - "chain collapses" gains `"expectedPairwise": [{"from": "b", "to": "a", "amount": 1000}, {"from": "c", "to": "b", "amount": 1000}]`.
  - New case "pairwise nets a pair across an expense and a payment", not pending:
    - Anna pays 1000, split 500/500;
    - Ben pays 600, split 300/300;
    - payment b→a 100;
    - balances a +100, b −100; transfers and pairwise both `[b→a 100]`.
```json
{"name": "multiple payers", "pending": "hyojun", "members": ["a", "b", "c"],
 "expenses": [{"payers": {"a": 6000, "b": 4000}, "amount": 10000, "shares": {"a": 3334, "b": 3333, "c": 3333}}], "payments": [],
 "expectedBalances": {"a": 2666, "b": 667, "c": -3333},
 "expectedTransfers": [{"from": "c", "to": "a", "amount": 2666}, {"from": "c", "to": "b", "amount": 667}],
 "expectedPairwise": [{"from": "c", "to": "a", "amount": 2666}, {"from": "c", "to": "b", "amount": 667}]},
{"name": "refund reverses the effect", "pending": "hyojun", "members": ["a", "b", "c"],
 "expenses": [{"paidBy": "a", "amount": 30000, "shares": {"a": 10000, "b": 10000, "c": 10000}},
              {"payers": {"a": 6000}, "amount": 6000, "shares": {"a": 2000, "b": 2000, "c": 2000}, "refund": true}], "payments": [],
 "expectedBalances": {"a": 16000, "b": -8000, "c": -8000},
 "expectedTransfers": [{"from": "b", "to": "a", "amount": 8000}, {"from": "c", "to": "a", "amount": 8000}]},
{"name": "multiple payers, simplify off keeps per-expense pairs", "pending": "hyojun", "members": ["a", "b", "c", "d"],
 "expenses": [{"paidBy": "a", "amount": 1000, "shares": {"b": 1000}},
              {"payers": {"b": 500, "c": 500}, "amount": 1000, "shares": {"d": 1000}}], "payments": [],
 "expectedBalances": {"a": 1000, "b": -500, "c": 500, "d": -1000},
 "expectedTransfers": [{"from": "d", "to": "a", "amount": 1000}, {"from": "b", "to": "c", "amount": 500}],
 "expectedPairwise": [{"from": "b", "to": "a", "amount": 1000}, {"from": "d", "to": "b", "amount": 500}, {"from": "d", "to": "c", "amount": 500}]}
```
- **`shared/sync-cases.json`** (Claude's, so nothing is pending).
  - `_doc` defaults gain: `payers` → `[{"memberId": paidBy, "amount": amount}]`, `refund` → false, `split` → null.
  - The harness gains the optional `expected.group` comparison.
  - Legacy event payloads stay as they are, so they double as backward-compatibility tests.
```json
{"name": "legacy expense without payers: single payer follows the amount, split stays null",
 "events": [
  {"seq": 1, "clientId": "e1", "type": "member.added", "payload": {"memberId": "m1", "name": "Anna", "userId": null}},
  {"seq": 2, "clientId": "e2", "type": "member.added", "payload": {"memberId": "m2", "name": "Ben", "userId": null}},
  {"seq": 3, "clientId": "e3", "type": "expense.created", "payload": {"expenseId": "x1", "description": "Taxi", "amount": 2000, "currency": "EUR", "fxRateToDefault": null, "paidBy": "m1", "date": "2026-10-11", "category": null, "shares": [{"memberId": "m1", "amount": 1000}, {"memberId": "m2", "amount": 1000}]}},
  {"seq": 4, "clientId": "e4", "type": "expense.updated", "payload": {"expenseId": "x1", "fields": {"amount": 3000, "shares": [{"memberId": "m1", "amount": 1500}, {"memberId": "m2", "amount": 1500}]}}}],
 "expected": {"members": [{"id": "m1", "name": "Anna", "userId": null}, {"id": "m2", "name": "Ben", "userId": null}],
  "expenses": [{"id": "x1", "description": "Taxi", "amount": 3000, "currency": "EUR", "fxRateToDefault": null, "paidBy": "m1",
   "payers": [{"memberId": "m1", "amount": 3000}], "refund": false, "split": null, "date": "2026-10-11", "category": null, "deleted": false,
   "shares": [{"memberId": "m1", "amount": 1500}, {"memberId": "m2", "amount": 1500}]}], "payments": []}},
{"name": "multiple payers: payers win over a stale paidBy, a shares edit without split clears split",
 "events": [
  {"seq": 1, "clientId": "e1", "type": "member.added", "payload": {"memberId": "m1", "name": "Anna", "userId": null}},
  {"seq": 2, "clientId": "e2", "type": "member.added", "payload": {"memberId": "m2", "name": "Ben", "userId": null}},
  {"seq": 3, "clientId": "e3", "type": "expense.created", "payload": {"expenseId": "x1", "description": "Hotel", "amount": 2000, "currency": "EUR", "fxRateToDefault": null, "paidBy": "m2", "payers": [{"memberId": "m1", "amount": 1200}, {"memberId": "m2", "amount": 800}], "refund": false, "split": {"mode": "shares", "input": {"m1": 1, "m2": 1}}, "date": "2026-10-11", "category": null, "shares": [{"memberId": "m1", "amount": 1000}, {"memberId": "m2", "amount": 1000}]}},
  {"seq": 4, "clientId": "e4", "type": "expense.updated", "payload": {"expenseId": "x1", "fields": {"shares": [{"memberId": "m1", "amount": 1500}, {"memberId": "m2", "amount": 500}]}}}],
 "expected": {"members": [{"id": "m1", "name": "Anna", "userId": null}, {"id": "m2", "name": "Ben", "userId": null}],
  "expenses": [{"id": "x1", "description": "Hotel", "amount": 2000, "currency": "EUR", "fxRateToDefault": null, "paidBy": "m1",
   "payers": [{"memberId": "m1", "amount": 1200}, {"memberId": "m2", "amount": 800}], "refund": false, "split": null, "date": "2026-10-11", "category": null, "deleted": false,
   "shares": [{"memberId": "m1", "amount": 1500}, {"memberId": "m2", "amount": 500}]}], "payments": []}},
{"name": "group settings: absent keys keep, null clears",
 "events": [
  {"seq": 1, "clientId": "e1", "type": "group.created", "payload": {"name": "Trip", "defaultCurrency": "EUR"}},
  {"seq": 2, "clientId": "e2", "type": "group.updated", "payload": {"simplifyDebts": false, "defaultSplit": {"mode": "percent", "input": {"m1": 60, "m2": 40}}}},
  {"seq": 3, "clientId": "e3", "type": "group.updated", "payload": {"name": "Rome"}},
  {"seq": 4, "clientId": "e4", "type": "group.updated", "payload": {"defaultSplit": null}}],
 "expected": {"group": {"name": "Rome", "defaultCurrency": "EUR", "simplifyDebts": false, "defaultSplit": null}, "members": [], "expenses": [], "payments": []}},
{"name": "default currency change ignored once an expense exists",
 "events": [
  {"seq": 1, "clientId": "e1", "type": "group.created", "payload": {"name": "Trip", "defaultCurrency": "EUR"}},
  {"seq": 2, "clientId": "e2", "type": "member.added", "payload": {"memberId": "m1", "name": "Anna", "userId": null}},
  {"seq": 3, "clientId": "e3", "type": "expense.created", "payload": {"expenseId": "x1", "description": "Ramen", "amount": 1000, "currency": "JPY", "fxRateToDefault": 0.00616, "paidBy": "m1", "date": "2026-10-10", "category": null, "shares": [{"memberId": "m1", "amount": 1000}]}},
  {"seq": 4, "clientId": "e4", "type": "group.updated", "payload": {"name": "Japan", "defaultCurrency": "USD"}}],
 "expected": {"group": {"name": "Japan", "defaultCurrency": "EUR"}, "members": [{"id": "m1", "name": "Anna", "userId": null}],
  "expenses": [{"id": "x1", "description": "Ramen", "amount": 1000, "currency": "JPY", "fxRateToDefault": 0.00616, "paidBy": "m1", "date": "2026-10-10", "category": null, "deleted": false, "shares": [{"memberId": "m1", "amount": 1000}]}], "payments": []}}
```
  Further cases, listed by name:
  - "legacy paidBy update collapses payers to one" (rule 10b);
  - "refund set by create, cleared by update";
  - "group defaultSplit set and kept across a name update";
  - "default currency change applies while the group has no expenses or payments";
  - "deleted expense still locks the default currency";
  - "a payment alone locks the default currency".
- **`shared/activity-cases.json`** gains goldens for:
  - `member_left`;
  - "Anna changed the group: simplify debts off";
  - "Ben changed the group: default split";
  - an expense update with `payers` + `refund` changes;
  - a split-mode-only edit → "split".

### Hyojun's part
About 1–2 hours in total: two functions in Dart. Claude adds the enum values, the `ExpenseLine` fields, the doc comments and the stubs. Hyojun writes the `TODO(효준)` bodies.

**1. `computeSplit`: shares, adjustment, and a percent fix** (`app/lib/domain/split.dart`). The signature is unchanged.
```dart
enum SplitMode { equal, exact, percent, shares, adjustment }

/// Codes: SUM_MISMATCH, NEGATIVE_AMOUNT, NO_MEMBERS, INVALID_INPUT, NEGATIVE_SHARE.
class SplitException implements Exception { … }

/// equal / exact: unchanged.
/// percent: unchanged, except that leftover minor units go only to members whose percent is > 0
///   (memberId ascending). A 0% member always gets 0. Today a 0% member can be charged 1 cent.
/// shares: input[memberId] is a share count (≥ 0, may be fractional, missing = 0).
///   Negative, NaN or infinite → 'INVALID_INPUT'. Weights w = (count * 100).round(), W = Σ w over [members].
///   W == 0 → 'NO_MEMBERS'. Each share = amount * w ~/ W (integer math, no doubles).
///   Leftover = amount − Σ shares: +1 each to members with w > 0, memberId ascending (always fewer than them).
/// adjustment: input[memberId] is an adjustment in minor units (may be negative, missing = 0).
///   Not a whole number, NaN or infinite → 'INVALID_INPUT'. base = amount − Σ adj over [members].
///   base < 0 → 'NEGATIVE_SHARE'. Split base exactly like equal over all [members], then add each member's adj.
///   Any result < 0 → 'NEGATIVE_SHARE'.
/// shares/adjustment: input keys not in [members] are ignored.
/// Always: the result has every member as a key (0 included) and sums to amount.
Map<String, int> computeSplit({required int amount, required SplitMode mode, required List<String> members, Map<String, double>? input});
```
Stub: the final `else { throw UnimplementedError('TODO(효준): ${mode.name}'); }`.

Cases (all `pending` until done):

| name | amount | members | input | expected |
|---|---|---|---|---|
| shares 2/1/0, leftover to lowest id with a share | 1000 | a,b,c | a2 b1 c0 | a667 b333 c0 |
| shares leftover skips a zero-share lower id, unsorted input | 100 | c,a,b | a0 b1 c2 | a0 b34 c66 |
| shares fractional counts | 1000 | a,b,c | a1.5 b1 c0.5 | a501 b333 c166 |
| shares missing input counts as 0 | 500 | a,b | a1 | a500 b0 |
| shares all zero rejected | 100 | a,b | a0 b0 | NO_MEMBERS |
| shares negative count rejected | 100 | a,b | a−1 b2 | INVALID_INPUT |
| adjustment +10 on one person | 10000 | a,b,c | a1000 | a4000 b3000 c3000 |
| adjustment negative with remainder | 1000 | a,b,c | b−100 | a367 b267 c366 |
| adjustment larger than the bill rejected | 1000 | a,b | a1200 | NEGATIVE_SHARE |
| adjustment pushing someone below zero rejected | 1000 | a,b | b−1200 | NEGATIVE_SHARE |
| adjustment must be whole minor units | 1000 | a,b | a10.5 | INVALID_INPUT |
| percent leftover skips 0% members | 100 | a,b,c | a0 b33.33 c66.67 | a0 b34 c66 |

The existing cases stay green.

**2. `computeBalances`: multiple payers and refunds** (`app/lib/domain/settlement.dart`).
```dart
class ExpenseLine {
  /// memberId → amount paid (for a refund: amount received). Sums to [amount].
  final Map<String, int> payers;
  final int amount;
  /// memberId → amount owed (for a refund: amount it is split back to). Sums to [amount].
  final Map<String, int> shares;
  /// Money that came back (a refund): its effect on balances is the reverse of an expense.
  final bool refund;
  ExpenseLine({String? paidBy, Map<String, int>? payers, required this.amount, required this.shares, this.refund = false})
      : assert((paidBy == null) != (payers == null), 'pass paidBy or payers'),
        payers = payers ?? {paidBy!: amount};
}

/// Balance per member. Positive = gets money back, negative = owes.
/// - For each line, sign = refund ? −1 : +1:  balance[m] += sign × payers[m] for every payer,
///   balance[m] −= sign × shares[m] for every share.
/// - Payments unchanged: balance[from] += amount, balance[to] −= amount.
/// - Every member in [members] is a key (0 if no activity). Lines come validated
///   (Σ payers == Σ shares == amount, ids in members): no checks here. Σ balances == 0.
Map<String, int> computeBalances(List<String> members, List<ExpenseLine> expenses, List<PaymentLine> payments);
```
- Stub inside the loop:
  ```dart
  if (expense.payers.length != 1 || expense.refund) throw UnimplementedError('TODO(효준): multi-payer / refund');
  ```
  The single-payer path keeps working through the stub.
- Cases he must pass:
  - "multiple payers": a +2666, b +667, c −3333;
  - "refund reverses the effect": a +16000, b −8000, c −8000;
  - "multiple payers, simplify off keeps per-expense pairs": a +1000, b −500, c +500, d −1000;
  - all existing cases;
  - a property test: random lines whose payers come from `computeSplit(exact)` must sum to 0.

### Tests
- **Dart, Claude:**
  - `apply_event_test` runs the new sync cases, including the idempotent and permute checks.
  - `pairwise_test.dart` checks `expectedPairwise`. Property tests: every balance is settled, at most one transfer per pair, deterministic.
  - `balancesOf` with a throwing stub: unsupported lines are excluded and counted.
  - Rejected events: a fake API refuses one event in a batch of three. The other two are stored, the bad one is removed and reported, and local state matches the snapshot.
  - Expense form widget tests:
    - multi-payer "left to assign" line and Save gating;
    - equal with an unticked member;
    - full-amount chips only in two-member groups;
    - Shares/± disabled while stubbed;
    - editing reopens in the stored mode, and falls back to exact on a mismatch;
    - default split pre-fills;
    - all money fields are sent together.
  - Group settings: currency locked once an expense or payment exists; Leave disabled when the balance isn't zero.
  - Activity formatter goldens.
- **Dart, Hyojun's runners** (`test/hyojun/split_test.dart`, `settlement_test.dart`): Claude adds `payers`/`refund` parsing and the `pending` skip.
- **Server:**
  - `EventValidationTest`:
    - one assertion per new error code;
    - a legacy single-payer amount update passes;
    - a legacy amount-only update on a multi-payer expense → `PAYERS_SUM_MISMATCH`;
    - a late `defaultCurrency` → 200, and the snapshot keeps EUR.
  - `EventSyncTest`:
    - the pulled `paidBy` is rewritten to the primary payer;
    - the snapshot carries the new fields;
    - an expense pushed in the legacy shape reads back with one payer.
  - `ExportImportTest`: several payers in one cell; a negative refund row; the two-positive-net Splitwise row imports with exact balances.
  - `ActivityTest`: the new goldens.
  - `SplitTest`, `SettlementTest` and `EventApplierTest` parse the new fields; pending cases are skipped.
- **Simulator** (light and dark), with Anna in the simulator and Ben and Cara via the API:
  - shares 2/1/1;
  - multiple payers;
  - refund;
  - +€10 adjustment;
  - the simplify toggle on both devices;
  - default split;
  - leave blocked, then allowed;
  - the group disappears on a second device;
  - a forced rejection (curl-made bad event in the outbox) shows the message and unblocks.

### Done when
- In a three-person group on the simulator, these expenses sync to a second user:
  - "Hotel" €300 paid by Anna €200 + Ben €100, split by shares 2/1/1;
  - a €60 refund to Anna split equally;
  - "Drinks" with Cara +€10.
- With Hyojun's code in, Balances and Settle up match numbers worked out by hand.
- The simplify toggle switches between per-pair debts and fewest payments on both phones.
- A 2/1/1 default split pre-fills new expenses, and editing reopens in shares.
- Leaving works only when settled.
- One refused event no longer blocks the outbox.
- All tests are green, and no Phase 3 `pending` keys are left (Hyojun done, Kotlin ported).

### Dependencies and deliberately left out
- **Phase 4:**
  - converts payers and shares with `convertExpense`, so both sum to the same converted total;
  - makes balances per currency (Leave then requires zero in every currency);
  - makes Settle up and pairwise run per currency.
- **Phase 5:** counts a refund as negative spend, and "you paid" as your payer amount.
- **Phase 6:**
  - friend groups get the full-amount chips for free;
  - `pairwiseDebts` gets its Kotlin port there (reminders);
  - friend groups have no settings screen and no Leave.
- **Phase 7:** adds the `itemized` mode to `SplitSpec`.
- **Left out:**
  - Old clients see a multi-payer or refund expense as paid in full by `paidBy` (no releases before parity).
  - The server never recomputes shares from `split`.
  - Leave is blocked by balance on the client only, matching Splitwise's UI. Rejoining creates a new member.
  - Splitwise refund rows with a negative Cost aren't imported until a real export has one.

---
