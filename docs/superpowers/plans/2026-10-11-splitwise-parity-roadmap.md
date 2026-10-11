# Evensies — Splitwise parity roadmap

- Written: 2026-10-11 · Status: **awaiting approval**
- Goal (set by Hyojun 2026-10-11): reach feature parity with Splitwise, keeping our promises (no limits, no ads, export always free, open source, self-hostable). Splitwise Pro features are included and stay free in Evensies.
- Each phase is independently shippable (TestFlight + Play internal build at the end) and gets its own short design section here before work starts. Phases are ordered by what users hit first on a real trip.

## Out of scope (deliberately)
| Splitwise feature | Why not |
|---|---|
| Splitwise Pay / Splitwise Card (moving money, a card) | Requires a payments/banking licence. We link out to payment apps instead (Phase 8). |
| Bank transaction import | Needs open-banking contracts per country (Plaid etc.), not free. Revisit after launch. |
| Ads, daily limits | Against our promises. |

## Phase overview
| # | Phase | User-visible result | Server | App | Cost |
|---|---|---|---|---|---|
| 1 | **Activity & notifications** | Activity feed per group and overall; visible push ("Ben added Dinner €30"); comments on expenses; notes field; restore a deleted expense; notification settings | activity read model over the event log, FCM notification payloads, comment events | Activity tab, comment thread on expense, notes, undo/restore, settings toggles | 0 |
| 2 | **Splitting power** | Split by shares; +/- adjustments; multiple payers; per-group default split; "simplify debts" toggle per group | validation for new payload shape | split UI, payer UI; `computeSplit` gains `shares`/`adjustment` modes (**Hyojun's core logic**) | 0 |
| 3 | **Currencies** | Automatic exchange rates on foreign expenses (editable); each user's home currency; balances shown converted | daily ECB rates (Frankfurter, no key) cached in DB, `GET /fx` | auto-fill rate, home currency setting, converted totals | 0 |
| 4 | **Organize & insights** | Categories with icons (auto-guessed from description); search; charts by category/month/person; group totals | — (client-side over local DB) | category picker, search screen, charts tab | 0 |
| 5 | **People** | Friends: 1:1 expenses outside groups; overall balance across all groups and friends; profile photo; "remind to pay" | friend pairs as 2-person hidden groups (reuses sync), reminders, avatar upload | Friends tab, overall dashboard, reminders | object storage (Phase 6 shares it) |
| 6 | **Receipts** | Attach receipt photos; on-device OCR to itemize a receipt and assign items to people | presigned upload to object storage, attachments table | camera/gallery, viewer, ML Kit text recognition, itemized split | Hetzner Object Storage ≈ €5/month (or local volume to start: 0) |
| 7 | **Recurring expenses** | Repeat weekly/monthly/yearly (rent, subscriptions) | scheduler that emits `expense.created` on schedule | recurrence picker, "next on …" | 0 |
| 8 | **Settle up via payment apps** | "Pay with" buttons: PayPal.me, Revolut, Wise, Toss, KakaoPay, Venmo (US), bank details/IBAN copy; settle-up history | store each user's payment handles | handles in profile, deep links, IBAN copy | 0 |
| 9 | **Platforms & language** | Web app (same Flutter code); Korean, Italian, English (+ ES/FR/DE); home-screen widget with balance | CORS, web auth (Apple/Google on web) | Flutter web build, `intl` ARB files, iOS/Android widgets | static hosting via Caddy: 0 |
| 10 | **Email & account polish** | Email notifications/digest for members who turned push off; invite by email; group cover images; group types (trip/home/couple) | transactional email provider | settings, group header | email: free tier (e.g. Resend 3k/month) |

Rough size: phases 1–4 are 1–2 working sessions each; 5, 6, 9 are 2–3 each; 7, 8, 10 are about one each.

## Rules that carry over
- Contract first: every phase updates `docs/API.md` (new event types, endpoints) before code; shared JSON fixtures for any logic both sides implement.
- Sync model stays the same: new data travels as events through `POST /groups/{id}/events`; the applier rules 1–5 stay valid. New event types are added to both appliers and `shared/sync-cases.json`.
- Tests: server Testcontainers + real HTTP, app unit/widget tests; simulator check of every new screen in light and dark mode before a build is uploaded.
- Release per phase: bump build, clean iOS build (simulator-slice check), TestFlight internal group "Team", Play internal testing.
- Secrets stay out of git (gitleaks in CI). Any new paid service is proposed with its monthly cost before it is added.

## Owner split
- **Hyojun writes**: the money logic that interviews ask about — Phase 2 `shares`/`adjustment` split and multi-payer balances (Dart; Claude ports to Kotlin and Hyojun reviews), Phase 3 conversion rounding rules. Everything else Claude implements and Hyojun reviews in TestFlight.
- Hyojun's own time on Evensies stays small; job applications remain the priority in `career/GOALS.md`. Claude's work does not count against that cap.

---

## Phase 1 design — Activity & notifications

### What users get
1. **Activity tab** in each group (third tab next to Expenses/Balances) and an **overall Activity** entry on the groups screen: a reverse-chronological list — "Ben added *Dinner* · €30.00 · you owe €15.00", "Anna changed *Taxi*: €18.00 → €20.00", "Sofia deleted *Gelato*", "Marco paid Anna €12.00", "Luca joined", "Ben commented on *Hotel*". Tapping opens the expense.
2. **Visible push notifications** for changes made by *other* people in your groups (title = group name, body = the same sentence). Your own changes never notify you.
3. **Comments** on an expense: a thread at the bottom of the expense screen.
4. **Notes** field on an expense (free text, up to 500 chars).
5. **Restore** a deleted expense: from its activity row ("Undo" for 10 seconds after deleting, and "Restore" on the deleted expense's activity entry).
6. **Notification settings** in Settings: on/off for "expenses and payments", "comments", "members joining".

### How (server)
- The event log already records every change with `actorUserId` and `createdAt`. The activity feed is **derived from the log**, not a new table: `GET /groups/{id}/activity?before=<seq>&limit=50` returns events newest-first, each with a server-rendered summary payload (`kind`, `actorMemberId`, `expenseId`, `description`, `amount`, `currency`, `changes[]` for updates) so app and push use the same wording rules. `GET /activity?before=<cursor>` merges across the caller's groups.
- `changes[]` for `expense.updated` is computed by comparing the fields in the event with the applied state just before it (the server already applies events in order inside the push transaction, so it can record the before-values in the event row as `meta`). Migration: `events.meta jsonb NULL`.
- New event types: `comment.added {commentId, expenseId, text}` (1–1000 chars), `comment.deleted {commentId}` (author only), `expense.restored {expenseId}` (clears `deleted`). Applier rule 3 ("delete wins") is refined: `expense.restored` is the only event that can bring a deleted expense back; `updated` on a deleted expense is still ignored.
- `notes` becomes an expense field (in `expense.created` and `expense.updated.fields`). Migration adds `expenses.notes text NULL`.
- Push: after each committed push, for every other member's devices send an FCM **notification + data** message (title/body from the activity summary, data `{type:"sync", groupId, seq}`), respecting per-user settings stored in a new `notification_prefs` table (`user_id`, `expenses`, `comments`, `members`; default all true). `PUT /me/notifications`.
- Rate: at most one notification per group per 30 seconds per recipient (batch "Ben added 3 expenses") so imports or bursts don't spam.

### How (app)
- Activity tab and overall Activity screen read the server feed when online and cache the last page in drift for offline viewing (a new `activity` table keyed by `groupId, seq`).
- Comments live in the local DB via the applier like other events, so they work offline.
- Expense form: notes field; delete shows a SnackBar with **Undo** (sends `expense.restored`).
- Push: request permission after the first group is created or joined (not at launch); tapping a notification opens the group's Activity tab. Foreground notifications show an in-app banner instead of a system alert.
- Settings: three switches bound to `PUT /me/notifications`.

### Tests
- Server: activity summaries for every event type (golden JSON in `shared/activity-cases.json`, also used by the app's formatter test); `changes[]` for partial updates; restore after delete; comment permissions (only author deletes); notification fan-out excludes the actor and respects prefs; burst batching.
- Sync fixtures: new cases for `comment.*`, `expense.restored`, `notes`.
- App: formatter test against the shared golden file; widget test for the comment thread; simulator walkthrough with two users (one in the simulator, one via API) checking the feed, push banner text, restore.

### Done when
Two people in a group see each other's changes in the Activity tab within a few seconds, get a readable push on a real iPhone, can comment and restore a deleted expense, and can turn notification types off.
