# Phase 8 design — Recurring expenses

Repeating expenses (rent, subscriptions, a weekly cleaner) are added by the **server**, so they appear on time even when nobody opens the app. A recurrence is a group entity that travels as events. Every repeat it produces is an ordinary `expense.created`, so balances, export, search and activity work on them unchanged. This phase also adds the server's scheduler (`@EnableScheduling`), which Phases 7 and 10 reuse.

### What users get
1. **Repeat** on the expense form, next to the date: Never / Every week / Every 2 weeks / Every month / Every year.
   - A line shows "Next: Sun, 1 Nov 2026".
   - The saved expense is the first in the series.
2. Each later repeat is added at about **09:00 in the creator's time zone** on its date, with a repeat icon and a push: "“Rent” · €1,200.00 was added (repeats monthly)".
3. **Month ends work.**
   - Monthly from the 31st falls on the last day of shorter months and returns to the 31st (Jan 31 → Feb 28 → Mar 31).
   - Yearly from Feb 29 falls on Feb 28 in other years.
4. **Editing the latest repeat.**
   - "Also change future repeats" (ticked by default) carries amount, split, payers, description, category and notes forward.
   - Changing Repeat or the date with the box ticked restarts the schedule from this expense.
   - Older repeats can only be edited on their own: "To change future repeats, edit the latest one (1 Oct)".
5. **Stopping.** Repeat → Never on the latest repeat, or **Delete and stop repeating** on any repeat (Splitwise's "cancel future recurrences"). Repeats already added stay.
6. **Offline.** Create, edit and stop work offline. No repeat is lost if the device syncs within 30 days.
7. **Free and unlimited**, except an abuse cap of 100 active series per group.

### How (server)
- **New package `recurrence`.**
  - `Schedule.kt` (checked by `shared/recurrence-cases.json`):
    - `occurrenceDate(frequency, startDate, n)` = `plusDays(7n)` / `plusDays(14n)` / `plusMonths(n)` / `plusYears(n)`. Each date is computed **from `startDate` every time**, never from the previous date, so clamping never drifts.
    - `firstOnOrAfter(frequency, startDate, date, minN = 1)`.
    - `dueAt(date, timeZone)` = `ZonedDateTime.of(date, 09:00, ZoneId.of(timeZone)).toInstant()`.
  - `RecurrenceScheduler.kt`: `@Scheduled(fixedDelay = 60_000) fun tick() = runDue(Instant.now())`. `@EnableScheduling` goes on `EvensiesServerApplication`. No new dependency.
- **State and applier.**
  - `GroupState` gains `recurrences: Map<String, RecurrenceDto>` with `RecurrenceDto(id, frequency, startDate, timeZone, template: JsonNode, deleted)`.
  - `ExpenseDto` gains `recurrenceId: String? = null` and `occurrence: Int? = null`.
  - `recurrence.updated` does `template.deepCopy().setAll(fields)`.
  - `GroupStateStore` persists recurrences and the two expense columns.
- **Template** = the `expense.created` payload minus `expenseId`, `date`, `recurrenceId` and `occurrence`, stored as jsonb.
  - Phase 3 payers/refund/split, Phase 2 notes, Phase 4 currency and rate, Phase 5 category and Phase 7 itemized bills pass through with no migration. Attachments are not part of a template.
  - The validator checks a template by building a synthetic `expense.created` (date = `startDate`) and running `validateExpense`.
- **First insert of a recurrence row** (`ON CONFLICT DO UPDATE` touches only `template` and `deleted_at`) sets the scheduler-owned columns:
  - `next_occurrence = firstOnOrAfter(frequency, startDate, localDate(clampedCreatedAt, timeZone)).n`
  - `next_due_at = dueAt(occurrenceDate(next_occurrence))`
  - `clampedCreatedAt` is the event's `createdAt` limited to [now − 30 days, now], so an offline-created series doesn't lose repeats and a bad clock can't cause a burst.
  - `persist(...)` gains a `createdAt: Instant` parameter.
- **`runDue(now)`:**
  1. `SELECT r.id, r.group_id FROM recurrences r WHERE r.deleted_at IS NULL AND r.next_due_at <= :now ORDER BY r.next_due_at LIMIT 200`.
  2. For each row, one repeat per transaction, looping while the next is due:
     - lock the group (`groups.lockForUpdate`), re-read the row, and stop if it is deleted or not due;
     - `n = next_occurrence`, `date = occurrenceDate(n)`;
     - `oid = UUID.nameUUIDFromBytes(HmacSHA256(key = evensies.jwt-secret, "evensies:recurrence:$id:$n"))`, used as both clientId and expenseId (keyed, so nobody can predict and take a future repeat's id);
     - payload = template + `{expenseId: oid, date, recurrenceId: id, occurrence: n}`, and event `createdAt = next_due_at`;
     - **fx:** if the template's currency differs from the group's, its `fxRateToDefault` is non-null, and `FxService.rates(date)` (Phase 4) has both codes, use that day's cross rate (`perEur[D] / perEur[cur]`, 6 significant digits with `BigDecimal(x).round(MathContext(6, HALF_UP))`, the same as Dart `toStringAsPrecision`). Otherwise keep the template's rate. A null template rate stays null (Not converted);
     - `validator.validateAll(state, actor = null, [event])`, then `EventService.push(groupId, actorUserId = null, [event])`;
     - advance `next_occurrence` and `next_due_at`.
  3. After commit, `PushNotifier.notify(groupId, actorUserId = null, stored)`. With a null actor everyone is notified.
- **Why it is safe:**
  - The lock is taken first and the row re-read, so a concurrent stop or edit is always seen.
  - A crash, retry or second instance hits `UNIQUE(group_id, client_id)` with the derived clientId.
  - Downtime catches up on the next tick, in order.
  - A validation failure (only possible through a bug) logs WARN and sets `next_due_at = now + 1h`.
  - `ponytail:` one full `stateStore.load` per repeat; batch per group if catch-ups get large.
- **System actor.**
  - `EventService.push`, `GroupStateStore.persist`, `EventValidator.validateAll`, `Activity.meta` and `PushNotifier.notify` take a nullable user (null = Evensies).
  - Stored events get `actor_user_id NULL`, and expenses `created_by NULL`.
  - The scheduler bypasses the per-user rate limiter.
- **Daily sweep** (`@Scheduled(cron = "0 30 3 * * *")`, `storage/Sweep.kt`) for Phase 7's leftovers:
  - deletes `attachments` rows with `expense_id IS NULL` older than 7 days, and their files;
  - deletes files of rows with `deleted_at` set, in case a crash came between commit and file deletion.
- **Activity** (Phase 2). `ActivityItem` gains `recurrenceId` and `frequency` (both null unless set). New kinds, push category `expenses`:
  - `expense_repeated`: an `expense.created` with `actorUserId` null and a `recurrenceId`. Fields as `expense_added` + `frequency`. Sentence: "“{description}” · {amount} was added (repeats {frequency})" + the owe/lent suffix.
  - `recurrence_created`: `recurrenceId`, `description`/`amount`/`currency` from the template, `frequency`. Sentence: "{A} set “{description}” to repeat {frequency}".
  - `recurrence_updated`: `changes` over the template keys (same order and labels as `expense_updated`). Sentence: "{A} changed future “{description}”: {changes}".
  - `recurrence_deleted`. Sentence: "{A} stopped “{description}” repeating".

  Frequency words: weekly / every 2 weeks / monthly / yearly.
- **Permissions:** any member may create, edit or stop a series, the same as expenses.

### How (app)
- **`domain/models.dart`:**
  - `Recurrence {id, frequency, startDate, timeZone, Map<String,dynamic> template, deleted}` with JSON.
  - `Expense` gains `recurrenceId` and `occurrence` (nullable; `clearRecurrence` in `copyWith`).
  - `GroupState.recurrences` (default `[]`) and a `recurrence(id)` getter.
- **`domain/recurrence.dart`:**
  - `occurrenceDate(String frequency, String startDate, int n) → String`;
  - `firstOccurrenceOnOrAfter(String frequency, String startDate, String onOrAfter, {int minN = 1}) → ({int n, String date})`.
  - Use `DateTime.utc` only: local arithmetic loses a day across DST, and `DateTime(y, m + 1, 31)` overflows. The fixtures catch both.
- **Sync:** `EventTypes` gains the three types; `applyEvent` implements rules 15–16; `expense.updated` accepts `recurrenceId`/`occurrence` (null clears).
- **drift (schemaVersion 9):**
  - `Recurrences` table (`id`, `groupId`, `frequency`, `startDate`, `timeZone`, `templateJson`, `deleted`);
  - `Expenses.recurrenceId` and `Expenses.occurrence`;
  - `unsentOutbox` orders by `createdAt`, then `rowid`, so `recurrence.created` always precedes its expense.
- **`local_writes.dart`:**
  - `createExpense(groupId, e, {String? repeat})`: the recurrence row plus the expense (`occurrence: 0`), queuing `recurrence.created` then `expense.created`.
  - `updateRecurrence(groupId, id, fields)`.
  - `stopRecurrence(groupId, id)`.
  - `repeatFrom(groupId, e, frequency, {String? stop})`: an optional `recurrence.deleted` for the old series, then `recurrence.created` (startDate = `e.date`, template from `e`), then `expense.updated {…changed, recurrenceId: new, occurrence: 0}`.
- **`core/ids.dart`:** `deviceTimeZone()` = `DateTime.now().timeZoneOffset` as `±HH:MM`.
  - No IANA name without a plugin, and no new dependency.
  - Across DST only the posting hour shifts; the date never moves. Web uses the browser's offset.
- **Expense form.**
  - The Repeat dropdown. "Next:" = `firstOccurrenceOnOrAfter(freq, startDate, todayIso(), minN: lastPosted + 1)`.
  - On the latest repeat of an active series, the "Also change future repeats" checkbox. On save:
    - Never → `stopRecurrence` + the expense update;
    - ticked and frequency or date changed → `repeatFrom(…, stop: old)`;
    - ticked, otherwise → `updateExpense` + `updateRecurrence(changed fields minus date)`;
    - unticked → `updateExpense` only.
  - Older repeats: the dropdown is disabled, with the hint.
  - Delete in an active series offers Cancel / Delete this one / Delete and stop repeating (`expense.deleted` + `recurrence.deleted`).
- **Expenses tab:** `Icons.repeat` on expenses whose series is active.
- **Members screen:** removing a member who is in an active template adds a line: "Ben is still in 2 repeating expenses (Rent, Netflix); they keep Ben's share until you edit the latest one."
- **Move (Phase 6):** `remapForMove` drops `recurrenceId`/`occurrence`; the series stays in the source group.
- **Offline:** only the server creates repeats after the first, so two offline phones can never both create the same one.

### Contract changes (`docs/API.md`, before code)
**New event types** (any member):

| type | payload |
|---|---|
| `recurrence.created` | `{"recurrenceId","frequency":"weekly"\|"biweekly"\|"monthly"\|"yearly","startDate":"YYYY-MM-DD","timeZone":string,"template":{…}}` |
| `recurrence.updated` | `{"recurrenceId","fields":{…changed template fields only; shares and payers replaced whole}}` |
| `recurrence.deleted` | `{"recurrenceId"}`: stops the series; there is no restore |

```json
{"type": "recurrence.created", "payload": {
  "recurrenceId": "5b0c…", "frequency": "monthly", "startDate": "2026-10-01", "timeZone": "+02:00",
  "template": {"description": "Rent", "amount": 120000, "currency": "EUR", "fxRateToDefault": null,
               "paidBy": "m1", "payers": [{"memberId": "m1", "amount": 120000}], "refund": false, "split": {"mode": "equal"},
               "category": "home.rent", "notes": null,
               "shares": [{"memberId": "m1", "amount": 60000}, {"memberId": "m2", "amount": 60000}]}}}
```
**Changed:**
- `expense.created` gains `"recurrenceId": string|null` and `"occurrence": int|null` (missing = null).
- `expense.updated.fields` may carry both together.
- A scheduled expense is pulled with `"actorUserId": null` and `"createdAt"` = its due time.

**Applier rules:**
15. **Recurrences.**
    - `recurrence.created` is idempotent; an existing id stays unchanged.
    - `recurrence.updated` merges `fields` into `template` key by key, and is ignored for an unknown or deleted series.
    - `recurrence.deleted` sets `deleted = true`, and is ignored if unknown.
16. **Expense series fields.** Expenses read `recurrenceId`/`occurrence` (missing = null). Template changes never touch repeats already added. Old clients treat `recurrence.*` as unknown types.

**Snapshot and export:** `"recurrences": [{"id","frequency","startDate","timeZone","template":{…},"deleted"}]`, and `expenses[]` gain the two fields. JSON export is the snapshot; CSV is unchanged.

**Endpoints:** none. **New API.md section `반복 지출`** covers:
- the 09:00 local time and the date rules;
- `next_occurrence` from the clamped `createdAt`;
- server-only derived ids;
- the null actor and `createdAt = dueAt`;
- push to every member;
- the fx refresh.

**Migration `V10__recurrences.sql`:**
```sql
CREATE TABLE recurrences (
    id              uuid PRIMARY KEY,
    group_id        uuid NOT NULL REFERENCES groups (id),
    frequency       text NOT NULL CHECK (frequency IN ('weekly', 'biweekly', 'monthly', 'yearly')),
    start_date      date NOT NULL,
    time_zone       text NOT NULL,
    template        jsonb NOT NULL,
    created_by      uuid REFERENCES users (id),
    created_at      timestamptz NOT NULL DEFAULT now(),
    deleted_at      timestamptz,
    next_occurrence int NOT NULL,          -- scheduler-owned, never sent to clients
    next_due_at     timestamptz NOT NULL   -- scheduler-owned
);
CREATE INDEX recurrences_group_id ON recurrences (group_id);
CREATE INDEX recurrences_due ON recurrences (next_due_at) WHERE deleted_at IS NULL;
ALTER TABLE expenses
    ADD COLUMN recurrence_id uuid REFERENCES recurrences (id),
    ADD COLUMN occurrence    int CHECK (occurrence >= 0);
```

**Validation** (the whole batch is rejected):

| event | rule | error |
|---|---|---|
| `recurrence.created` | `recurrenceId` is a UUID; `frequency` is one of the four; `startDate` is valid | 400 `VALIDATION` |
| | `timeZone` is ≤ 64 characters and accepted by `ZoneId.of` (IANA or offset) | 400 `VALIDATION` |
| | `template` is an object without `expenseId`, `date`, `recurrenceId` or `occurrence` | 400 `VALIDATION` |
| | the template validates as an expense (incl. Phase 3 payers and split, Phase 7 itemized shape) | the expense codes |
| | at most 100 non-deleted series per group (abuse cap, added to API.md's caps line) | 409 `LIMIT_EXCEEDED` |
| `recurrence.updated` | `fields` is an object without schedule or identity keys | 400 `VALIDATION` |
| | the merged template validates if the series is active; unknown or stopped → accepted and ignored | as above |
| `recurrence.deleted` | `recurrenceId` is a UUID | 400 `VALIDATION` |
| `expense.created` / `expense.updated` | `recurrenceId` and `occurrence` both set or both null; `occurrence` is an integer, and only `0` from clients | 400 `VALIDATION` |
| | a `recurrenceId` that is not a series of this group is **dropped by `normalize`** (the expense is stored without a series), so a racing offline client never gets stuck. A stopped series is fine | — |

**Deploy order:** server before app (no releases before parity anyway).

### Shared fixtures
- **`shared/recurrence-cases.json`** (Dart `recurrence_test.dart`, Kotlin `ScheduleTest.kt`; `dueAt` is Kotlin only; computed with Python `zoneinfo`):
```json
{"_doc": "kind=dates: dates[n] = occurrenceDate(frequency, startDate, n). kind=next: firstOnOrAfter(frequency, startDate, onOrAfter, minN ?? 1) = {n, date}. kind=dueAt (server only): 09:00 on date in timeZone, as UTC.",
 "cases": [
  {"name": "monthly from the 31st clamps to month end and comes back", "kind": "dates", "frequency": "monthly", "startDate": "2026-01-31",
   "dates": ["2026-01-31", "2026-02-28", "2026-03-31", "2026-04-30", "2026-05-31"]},
  {"name": "yearly from Feb 29", "kind": "dates", "frequency": "yearly", "startDate": "2028-02-29",
   "dates": ["2028-02-29", "2029-02-28", "2030-02-28", "2031-02-28", "2032-02-29"]},
  {"name": "weekly across EU DST start stays on Thursday", "kind": "dates", "frequency": "weekly", "startDate": "2026-03-26", "dates": ["2026-03-26", "2026-04-02"]},
  {"name": "every 2 weeks across EU and US DST end", "kind": "dates", "frequency": "biweekly", "startDate": "2026-10-20", "dates": ["2026-10-20", "2026-11-03"]},
  {"name": "next keeps today, skips the past", "kind": "next", "frequency": "monthly", "startDate": "2026-09-11", "onOrAfter": "2026-10-11", "n": 1, "date": "2026-10-11"},
  {"name": "next never returns occurrence 0", "kind": "next", "frequency": "monthly", "startDate": "2026-10-11", "onOrAfter": "2026-10-11", "n": 1, "date": "2026-11-11"},
  {"name": "next for a weekly started weeks ago", "kind": "next", "frequency": "weekly", "startDate": "2026-09-01", "onOrAfter": "2026-10-11", "n": 6, "date": "2026-10-13"},
  {"name": "next respects minN", "kind": "next", "frequency": "monthly", "startDate": "2026-09-11", "onOrAfter": "2026-10-11", "minN": 2, "n": 2, "date": "2026-11-11"},
  {"name": "09:00 Rome on the DST start day", "kind": "dueAt", "date": "2026-03-29", "timeZone": "Europe/Rome", "dueAt": "2026-03-29T07:00:00Z"},
  {"name": "offset with minutes", "kind": "dueAt", "date": "2026-10-11", "timeZone": "+05:45", "dueAt": "2026-10-11T03:15:00Z"},
  {"name": "UTC+14 posts on the previous UTC day", "kind": "dueAt", "date": "2026-01-01", "timeZone": "Pacific/Kiritimati", "dueAt": "2025-12-31T19:00:00Z"}
 ]}
```
- **`shared/sync-cases.json`.** `_doc` defaults: `recurrences=[]`, expense `recurrenceId`/`occurrence` = null.
```json
{"name": "template edit and stop never touch added expenses; update after stop ignored", "permute": true,
 "events": [
  {"seq": 1, "clientId": "e1", "type": "member.added", "payload": {"memberId": "m1", "name": "Anna", "userId": null}},
  {"seq": 2, "clientId": "e2", "type": "member.added", "payload": {"memberId": "m2", "name": "Ben", "userId": null}},
  {"seq": 3, "clientId": "e3", "type": "recurrence.created", "payload": {"recurrenceId": "r1", "frequency": "monthly", "startDate": "2026-01-31", "timeZone": "Europe/Rome",
    "template": {"description": "Rent", "amount": 120000, "currency": "EUR", "fxRateToDefault": null, "paidBy": "m1", "category": null,
                 "shares": [{"memberId": "m1", "amount": 60000}, {"memberId": "m2", "amount": 60000}]}}},
  {"seq": 4, "clientId": "e4", "type": "expense.created", "payload": {"expenseId": "x0", "description": "Rent", "amount": 120000, "currency": "EUR", "fxRateToDefault": null,
    "paidBy": "m1", "date": "2026-01-31", "category": null, "recurrenceId": "r1", "occurrence": 0,
    "shares": [{"memberId": "m1", "amount": 60000}, {"memberId": "m2", "amount": 60000}]}},
  {"seq": 5, "clientId": "e5", "type": "recurrence.updated", "payload": {"recurrenceId": "r1", "fields": {"amount": 130000,
    "shares": [{"memberId": "m1", "amount": 65000}, {"memberId": "m2", "amount": 65000}]}}},
  {"seq": 6, "clientId": "e6", "type": "recurrence.deleted", "payload": {"recurrenceId": "r1"}},
  {"seq": 7, "clientId": "e7", "type": "recurrence.updated", "payload": {"recurrenceId": "r1", "fields": {"description": "Rent + parking"}}}],
 "expected": {
  "members": [{"id": "m1", "name": "Anna", "userId": null}, {"id": "m2", "name": "Ben", "userId": null}],
  "expenses": [{"id": "x0", "description": "Rent", "amount": 120000, "currency": "EUR", "fxRateToDefault": null, "paidBy": "m1", "date": "2026-01-31",
    "category": null, "deleted": false, "recurrenceId": "r1", "occurrence": 0,
    "shares": [{"memberId": "m1", "amount": 60000}, {"memberId": "m2", "amount": 60000}]}],
  "payments": [],
  "recurrences": [{"id": "r1", "frequency": "monthly", "startDate": "2026-01-31", "timeZone": "Europe/Rome", "deleted": true,
    "template": {"description": "Rent", "amount": 130000, "currency": "EUR", "fxRateToDefault": null, "paidBy": "m1", "category": null,
                 "shares": [{"memberId": "m1", "amount": 65000}, {"memberId": "m2", "amount": 65000}]}}]}}
```
  Further cases:
  - "schedule change moves the expense to a new series; legacy expense has none; unknown stop ignored": weekly r1 is stopped; monthly r2 is created; `expense.updated {recurrenceId: "r2", occurrence: 0}` retags x0; a stop of `r404` is ignored; legacy x9 keeps null fields.
  - "recurrence.created twice keeps the first template".
- **`shared/activity-cases.json`:** `expense_repeated` (null actor, with an owe suffix), `recurrence_created`, `recurrence_updated` ("Ben changed future “Rent”: €1,200.00 → €1,300.00"), `recurrence_deleted`.

### Hyojun's part
None. Repeats copy the template's final per-member amounts, so the server never computes a split. The form keeps using `computeSplit`, and its Phase 3 modes stay behind `tryCore`.

### Tests
- **Server, `RecurrenceTest.kt`** (Testcontainers + HTTP; dates in 2031 or later so the real tick never fires; tests call `runDue(Instant)` and assert on stored events):
  1. `recurrence.created` + the occurrence-0 expense → the snapshot has both, with the expected `next_*`.
  2. One minute before due → nothing. At due → one `expense.created` with clientId = expenseId, null actor, the right date, template values and `occurrence: 1`, which a second member pulls.
  3. `runDue` twice, and two threads at once → exactly one event per repeat.
  4. Three missed periods are caught up in order.
  5. A template update changes the next repeat, not earlier ones.
  6. After a stop nothing more is added, and a later update is ignored.
  7. A Jan 31 monthly series gives Feb 28 and Mar 31.
  8. `+13:00` and `-10:00` series on the same date: an instant between their due times adds only the first.
  9. Offline create 3 days ago gets the repeat due 2 days ago; 200 days ago is clamped to 30.
  10. Every validation row; a failing batch stores nothing.
  11. An expense referencing a stopped series is accepted; an unknown series id is dropped by `normalize`.
  12. A retag persists `recurrence_id`.
  13. JSON export has `recurrences`.
  14. The push fan-out includes the creator.
  15. A JPY template with a rate in a EUR group posts with the stubbed `fx_days` rate for its date.
  16. The sweep deletes a 7-day-old unattached upload and leaves an attached one.
- **Shared:** `ScheduleTest.kt` / `recurrence_test.dart`; both applier tests run the new sync cases; `ActivityTest` and the app formatter run the new goldens.
- **App:**
  - outbox order and payloads for new-repeating, edit-latest-with-future, schedule change, stop, delete-and-stop;
  - `unsentOutbox` tie order;
  - drift 8→9 keeps rows;
  - widgets: Repeat dropdown and "Next:"; an older repeat is disabled with the hint; the delete dialog's choices.
- **Simulator** (light and dark):
  - "Rent" monthly dated today shows "Next:" next month;
  - after 09:00 local, a weekly expense dated 7 days ago gets today's repeat within about a minute, in the simulator and via the API;
  - edit the latest with "future" ticked;
  - delete with stop;
  - create in airplane mode and sync later.

### Done when
- A repeating expense posts on the right date (month ends clamped) at about 09:00 in its creator's time zone without anyone opening the app.
- Each repeat appears exactly once, across retries, restarts and two instances.
- Edits to the latest repeat can carry forward, and stopping works from the form and the delete dialog.
- Offline-created series lose nothing within 30 days, and old events and clients are unaffected.
- The Phase 7 sweep runs.
- `docs/API.md` came first, all tests are green, the simulator check passed, and the work is committed and pushed.
- The roadmap row says "weekly / every 2 weeks / monthly / yearly".

### Dependencies
- **Phase 3:** payers, refund and split ride in the template and are checked by `validateExpense`.
- **Phase 4:** the rate refresh through `FxService`.
- **Phase 6:** friend groups work unchanged; a move drops the series tag.
- **Phase 7:** the sweep lives here; attachments aren't repeated.
- **Phase 9:** activity strings and frequency words go into `strings.json`; web uses the browser's offset.
- **Phase 10:**
  - the scheduler skips deleted groups, and a restore skips the deleted period;
  - the email reminder before a bill posts (`remindDaysBefore`) is added there, on this scheduler.

### Left out (deliberately)
- **Filling in past dates at creation.** The "Next:" line says so. Downtime and offline gaps up to 30 days are still caught up.
- **Posting in the hour of creation.** A fixed 09:00 avoids night pushes.
- **An account time-zone setting (#96).** Each series carries its creator's zone, which is all the scheduler needs.
- **Custom intervals, end dates, weekday-only.** Splitwise has none either.
- **A "Repeating expenses" list screen.**
- **Removing repeats added before an offline stop arrived.** That would mean trusting the device clock.
- **Two people changing one schedule while both offline** can give two series. Client-derived ids would desync the local copy from the server's.

---
