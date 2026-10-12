# Evensies — Splitwise parity roadmap

- Written: 2026-10-11 · Status: **approved 2026-10-11; settle-up moved to Phase 1 at Hyojun's request ("송금이 가장 중요")**
- Goal (set by Hyojun 2026-10-11): reach feature parity with Splitwise, keeping our promises (no limits, no ads, no paywall, export always free, public source). Splitwise Pro features are included and stay free in Evensies.
- Licence and funding (decided by Hyojun 2026-10-11): code under FSL-1.1-ALv2 (no competing hosted services; each version becomes Apache-2.0 after two years) with a trademark policy (`TRADEMARKS.md`); the store app talks only to the official server; funded by optional in-app tips (Phase 11). Self-hosting is no longer promoted.
- Each phase is independently shippable and has a design before work starts (Phases 1–2 below, Phases 3–10 in [`phases/`](phases/)) (builds are on hold until parity, see Rules). Phases are ordered by what users hit first on a real trip.

## Out of scope (deliberately)
| Splitwise feature | Why not |
|---|---|
| Splitwise Pay / Splitwise Card (moving money, a card) | Requires a payments/banking licence. We link out to payment apps instead (Phase 8). |
| Bank transaction import | Needs open-banking contracts per country (Plaid etc.), not free. Revisit after launch. |
| Ads, daily limits | Against our promises. |

## Phase overview
| # | Phase | User-visible result | Server | App | Cost |
|---|---|---|---|---|---|
| 1 | **Settle up via payment apps** | "Pay Anna €15" opens PayPal / Wise / Venmo with the amount filled in, Revolut / KakaoPay links, EU bank QR (EPC) and IBAN copy, Korean bank account copy; request money by message; sent → received confirmation | per-user payment methods, visibility to group members only, `payment.confirmed` event, status on payments | payment methods screen, pay sheet on Settle up, request share, confirm/decline | 0 |
| 2 | **Activity & notifications** | Activity feed per group and overall; visible push ("Ben added Dinner €30"); comments on expenses; notes field; restore a deleted expense; notification settings | activity read model over the event log, FCM notification payloads, comment events | Activity tab, comment thread on expense, notes, undo/restore, settings toggles | 0 |
| 3 | **Splitting power** | Split by shares; +/- adjustments; multiple payers; per-group default split; "simplify debts" toggle per group | validation for new payload shape | split UI, payer UI; `computeSplit` gains `shares`/`adjustment` modes (**Hyojun's core logic**) | 0 |
| 4 | **Currencies** | Automatic exchange rates on foreign expenses (editable); each user's home currency; balances shown converted | daily rates via Frankfurter (ECB and other central banks, no key) cached in DB, `GET /fx` | auto-fill rate, home currency setting, converted totals | 0 |
| 5 | **Organize & insights** | Categories with icons (auto-guessed from description); search; charts by category/month/person; group totals | — (client-side over local DB) | category picker, search screen, charts tab | 0 |
| 6 | **People** | Friends: 1:1 expenses outside groups; overall balance across all groups and friends; profile photo; "remind to pay" | friend pairs as 2-person hidden groups (reuses sync), reminders, avatar upload | Friends tab, overall dashboard, reminders | object storage (Phase 6 shares it) |
| 7 | **Receipts** | Attach receipt photos; on-device OCR to itemize a receipt and assign items to people | presigned upload to object storage, attachments table | camera/gallery, viewer, ML Kit text recognition, itemized split | Hetzner Object Storage ≈ €5/month (or local volume to start: 0) |
| 8 | **Recurring expenses** | Repeat weekly / every 2 weeks / monthly / yearly (rent, subscriptions) | scheduler that emits `expense.created` on schedule | recurrence picker, "next on …" | 0 |
| 9 | **Platforms & language** | Web app at `/app/`; 13 languages with local money and date formats; localized push, reminders and landing pages; home-screen widget; appearance toggle; app lock | Web build inside the server image, CSP, CORS (dev only), `GET /info`, `users.language`, `shared/strings.json` | Flutter web + drift wasm, ARB i18n, shared sentence templates, `home_widget`, `local_auth` | 0 |
| 10 | **Email & account polish** | Email notifications/digest for members who turned push off; invite by email; group cover images; group types (trip/home/couple) | transactional email provider | settings, group header | email: free tier (e.g. Resend 3k/month) |
| 11 | **Support Evensies** | Optional tips from Settings (in-app purchase, unlock nothing); the store app talks only to the official server | — | tip screen, `in_app_purchase`, release builds without the Server URL field | stores keep 15% of tips |

Rough size: phases 1–5 are 1–2 working sessions each; 6, 7, 9 are 2–3 each; 8 and 10 are about one each.

## Rules that carry over
- Contract first: every phase updates `docs/API.md` (new event types, endpoints) before code; shared JSON fixtures for any logic both sides implement.
- Sync model stays the same: new data travels as events through `POST /groups/{id}/events`; the applier rules 1–5 stay valid. New event types are added to both appliers and `shared/sync-cases.json`.
- Tests: server Testcontainers + real HTTP, app unit/widget tests; simulator check of every new screen in light and dark mode before a build is uploaded.
- **No releases until parity** (Hyojun, 2026-10-11): no TestFlight/Play builds and no production server deploys until every phase is done. Each phase ends with tests green, a local-server + simulator check, and a commit/push. Release procedure (for later): bump build, clean iOS build (simulator-slice check), TestFlight internal group "Team", Play internal testing, `deploy/update.sh` on the server.
- Secrets stay out of git (gitleaks in CI). Any new paid service is proposed with its monthly cost before it is added.

## Owner split
- **Hyojun writes**: the money logic that interviews ask about — Phase 3 `shares`/`adjustment` split and multi-payer balances (Dart; Claude ports to Kotlin and Hyojun reviews), Phase 4 conversion rounding rules. Everything else Claude implements and Hyojun reviews in TestFlight.
- Hyojun's own time on Evensies stays small; job applications remain the priority in `career/GOALS.md`. Claude's work does not count against that cap.

---

## Phase 1 design — Settle up via payment apps

We never hold or move money. Evensies shows *how* to pay a person and opens the app that does it; the payer marks the payment as sent and the receiver confirms it.

### Payment methods (per user, shown only to members of groups they share)
| type | stored value | what "Pay" does | amount pre-filled |
|---|---|---|---|
| `paypal` | PayPal.me username | opens `https://paypal.me/{user}/{amount}{CUR}` | ✅ |
| `wise` | Wise Quick Pay link (`https://wise.com/pay/...`) | opens link with `?amount=&currency=&description=` | ✅ (documented for Quick Pay links) |
| `venmo` | Venmo username (US) | opens `https://venmo.com/{user}?txn=pay&amount={x}&note={note}` | ✅ (widely used, unofficial) |
| `revolut` | Revolut.me username | opens `https://revolut.me/{user}` | ❌ no documented parameter — amount shown large and copied |
| `kakaopay` | KakaoPay 송금코드 link (`https://qr.kakaopay.com/...`) | opens the link | ❌ — amount shown and copied |
| `iban` | holder name, IBAN, optional BIC | sheet with **EPC QR** (BCD v002, SCT, name, IBAN, EUR amount, remittance "Evensies: {group}") for EU banking apps + copy IBAN / copy amount | ✅ in QR (EUR only) |
| `kr_bank` | bank name, account number, holder | sheet: copy "bank account" (Korean bank and Toss apps detect it on the clipboard) + copy amount | ❌ — clipboard |

Rules: up to 8 methods per user; one per type except `iban`/`kr_bank` (up to 3 each). Validation: usernames `[A-Za-z0-9._-]{1,40}`, Wise/Kakao links must start with their official host, IBAN passes the mod-97 check, KR account digits/hyphens 8–20. Account numbers and IBANs are shown masked in lists (`•••• 1234`) and in full only in the pay sheet.
`toss.me` personal links were discontinued, so Toss is covered by `kr_bank` (copy) rather than a link.

### Payment confirmation
- `payment.created` gains `"status": "sent" | "confirmed"` (missing = `confirmed`, so old clients and old events stay valid). Payer taps **I've sent it** → `sent`. If the receiver is a placeholder (no user) or the payer *is* the receiver's user, it is recorded as `confirmed`.
- New event `payment.confirmed {paymentId}` — only the receiver's user may send it (server: 403 otherwise). **Not received** = `payment.deleted` by the receiver (also allowed for the payer).
- Balances count `sent` and `confirmed` payments alike (the debt shows as settled right away, like Splitwise); the UI marks `sent` ones "waiting for {name} to confirm".
- Applier: `payment.confirmed` on an unknown or deleted payment is ignored (rule 4); on `sent` it sets `confirmed`.

### Requesting money
On Settle up, a creditor's row has **Request**: share sheet text "You owe me €15.00 for {group} on Evensies. Pay with: PayPal https://paypal.me/anna/15EUR · IBAN IT60 X054… · …" built from the creditor's own methods.

### API
- `GET /me/payment-methods`, `PUT /me/payment-methods` (full list replace, validated).
- `GET /groups/{id}/payment-methods` → `{ "<memberId>": [method, …] }` for linked members of that group; caller must be a member.

### App
- Settings → **Ways to get paid**: add/edit/remove methods with per-type forms and validation.
- Settle up: for transfers where I pay, chips for each of the receiver's methods → opens the link (url_launcher) or the bank sheet (EPC QR via `qr_flutter`, copy buttons); then **I've sent it**. Where I receive: **Request** and, for `sent` payments, **Confirm received / Not received**.
- If the receiver has no methods: "Ask {name} to add a way to get paid" + the existing Mark as paid.

### Tests
- Dart: link builders per type (amount formatting per currency decimals, URL encoding of notes), EPC payload exact text for a fixture, IBAN validator, masking.
- Server: method validation (good/bad per type, limits), visibility (non-member 403, only linked members), `payment.confirmed` permission (receiver only), status default for old events.
- Shared sync fixtures: `sent` → `confirmed`, confirm after delete ignored, legacy `payment.created` without status = confirmed.
- Simulator: add methods as receiver; as payer open PayPal/Wise links (Safari opens), EPC QR renders and decodes, copy flows; confirm/decline as receiver.

---

## Phase 2 design — Activity & notifications

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

---

## Phase 3–11 designs
Written 2026-10-11 from a Splitwise feature survey (free and Pro, 2026), one designer per phase, then a cross-phase review for parity gaps and consistency. The numbering table (migrations, drift schema versions, applier rules) and the conventions every later phase follows are at the top of Phase 3. If the tree differs from those numbers when a phase starts, the tree wins and the phase doc is updated.

| Phase | Design |
|---|---|
| 3 | [Splitting power](phases/phase-03-splitting-power.md) — shares, adjustment, multiple payers, refunds, "full amount" shortcuts, default split, simplify toggle, group settings, leave group |
| 4 | [Currencies](phases/phase-04-currencies.md) — daily rates via Frankfurter, home currency, per-currency balances, convert to one currency |
| 5 | [Organize & insights](phases/phase-05-organize-insights.md) — categories, search, totals, charts, edit history, who pays next |
| 6 | [People](phases/phase-06-people.md) — friends and non-group expenses, overall dashboard, avatars, reminders, record any payment |
| 7 | [Receipts](phases/phase-07-receipts.md) — receipt photos, on-device OCR, itemized split |
| 8 | [Recurring expenses](phases/phase-08-recurring-expenses.md) — weekly to yearly series, server scheduler |
| 9 | [Platforms & language](phases/phase-09-platforms-language.md) — web app, 13 languages, widgets, app lock |
| 10 | [Email & account polish](phases/phase-10-email-account-polish.md) — email sign-in and digests, invites by email, group types and covers, delete/restore group, block, export everything |
| 11 | [Support Evensies](phases/phase-11-support-evensies.md) — optional tips (in-app purchase, unlock nothing), official-server-only release app |

## Parity checklist

Status: **have** = in the app today (including Phases 1–5); **partly** = in the app, but the part named in the row still waits; **Phase N** = designed above; **out of scope** = not planned, with the reason; **n/a** = Splitwise doesn't offer it either.

| # | Area | Feature | Splitwise | Status |
|---|---|---|---|---|
| 1 | Split | Equally (untick people) | Free | have (tick boxes since Phase 3) |
| 2 | Split | Exact amounts | Free | have |
| 3 | Split | Percent | Free | have (0% leftover fix by Hyojun) |
| 4 | Split | Shares | Free | have (Phase 3, `computeSplit` by Hyojun) |
| 5 | Split | Adjustment | Free | have (Phase 3, `computeSplit` by Hyojun) |
| 6 | Split | Itemized, manual | Free web / Pro mobile | have (Phase 7, free): Items is a sixth split; tax, tip and discount spread by subtotal |
| 7 | Split | Itemize by receipt scan | Pro | have (Phase 7, free): on-device text recognition (Apple Vision on iOS, ML Kit on Android), lines start unassigned; hidden on web |
| 8 | Split | Reimbursement / refund | Free | have (Phase 3, `computeBalances` by Hyojun) |
| 9 | Split | "Full amount" shortcuts | Free | have (Phase 3) |
| 10 | Split | Multiple payers | Free | have (Phase 3, `computeBalances` by Hyojun) |
| 11 | Split | Default split per group | Pro | have (Phase 3; shares and ± defaults since Hyojun's `computeSplit` landed) |
| 12 | Expense | Description, amount, date, payer | Free | have |
| 13 | Expense | Currency per expense, last one remembered | Free | have (per group since Phase 4) |
| 14 | Expense | Category with icon, auto-guessed | Free | have (Phase 5): Splitwise's 43 subcategories with icons, guessed on the device from the description and the group's history ("auto" until picked); labels in all 13 languages since Phase 9 |
| 15 | Expense | Notes | Free | have (Phase 2) |
| 16 | Expense | Receipt photo | Free (Pro 10 GB) | have (Phase 7): up to 10 per expense, offline upload later, ZIP export with receipts |
| 17 | Expense | Repeat | Free | have (Phase 8): Repeat on the expense form, added by the server at 09:00 in the creator's time zone |
| 18 | Expense | Group or "no group" | Free | have (Phase 6) |
| 19 | Expense | Move between groups / to a friend | Free | have (Phase 6) |
| 20 | Expense | Edit / delete | Free | have |
| 21 | Expense | Restore a deleted expense | Free | have (Phase 2) |
| 22 | Expense | Edit history on the expense | Free | have (Phase 5): History on the expense screen in the Activity sentences, cached for offline; since Phase 10 one chronological thread with the comments (system rows for changes, chat bubbles for comments) |
| 23 | Expense | Comments | Free | have (Phase 2) |
| 24 | Expense | Location | n/a | n/a |
| 25 | Expense | Daily expense cap | Pro removes it | have (no cap) |
| 26 | Groups | Create; add people by name | Free | have |
| 27 | Groups | Group type | Free | have (Phase 10): Trip / Home / Couple / Other, icon and colour band on the list and header |
| 28 | Groups | Cover photo | Free | have (Phase 10): members only, on the header and as the list thumbnail |
| 29 | Groups | Simplify debts toggle | Free | have (Phase 3; per currency since Phase 4) |
| 30 | Groups | Simplify-debts explanation | Free | have (Phase 3) |
| 31 | Groups | Settings: rename, default currency | Free | have (Phase 3; currency locked after the first expense or payment) |
| 32 | Groups | Leave group | Free | have (Phase 3) |
| 33 | Groups | Delete / undelete group | Free | have (Phase 10): any member, for everyone; Undo, Settings → Deleted groups or the activity row restores it, offline edits kept |
| 34 | Groups | Remove member | Free | have |
| 35 | Groups | Balances per member, per currency | Free | have (Phase 4): rated expenses fold into the group currency (Hyojun's `convertExpense`); unrated ones keep a "Not converted · JPY" section per currency on Balances, Settle up and the groups list |
| 36 | Groups | Totals screen | Free | have (Phase 5, Insights): per month or all time, per currency; rated foreign expenses join the group-currency totals (Hyojun's `convertExpense`), unrated ones keep a "Not converted" card per currency |
| 37 | Groups | Charts | Pro | have (Phase 5, free): bars by month (group / mine), by category and by person; no pie chart, on purpose |
| 38 | Groups | Printable summary | Free (web) | have (Phase 5 text, Phase 9 print): share-sheet text with the totals, top categories and balances (copied to the clipboard on the web); on the web, Insights → Print summary opens that text on its own tab with the browser's print dialog |
| 39 | Groups | Whiteboard | legacy | n/a |
| 40 | Groups | Personal (solo) group | Free | have |
| 41 | Invite | Invite link | Free | have |
| 42 | Invite | Short code | n/a | have (extra) |
| 43 | Invite | QR code | n/a | have (Phase 6) |
| 44 | Invite | Invite by email | Free | have (Phase 10): one invite plus one reminder after 3 days, the link preselects the placeholder, the address is deleted after 14 days |
| 45 | Invite | Invite by phone / from contacts | Free | have (system share sheet suggests contacts); phone numbers out of scope (SMS cost) |
| 46 | Invite | Placeholder, claimed later | Free | have |
| 47 | Invite | Merge duplicates | Free (support) | out of scope (would rewrite history; claim flow + Phase 10 preselected invites prevent duplicates) |
| 48 | Friends | 1:1 expenses outside groups | Free | have (Phase 6) |
| 49 | Friends | Friend balance across groups | Free | have (Phase 6) |
| 50 | Friends | Settle all balances with a friend | Free | have (Phase 6) |
| 51 | Friends | Filters; hide settled friends/groups | Free | have (Phase 6) |
| 52 | Friends | Delete friend | Free | have (Phase 10): only once the non-group balance is settled (like Splitwise); adding them again brings the history back |
| 53 | Friends | Block / report user | Free | have (Phase 10): a block mutes the person (no friend request, reminder, push or email from them; shared balances stay); Report emails the operator's support address |
| 54 | Dashboard | Overall you owe / you are owed | Free | have (Phase 6) |
| 55 | Dashboard | "Who should pay next" | Free | have (Phase 5): one line on Balances, from the group-currency balances |
| 56 | Dashboard | Global add-expense button | Free | have (Phase 6) |
| 57 | Activity | Activity feed | Free | have (Phase 2) |
| 58 | Activity | Overall activity | Free | have (Phase 2) |
| 59 | Notifications | Push for others' changes | Free | have (Phase 2); new kinds in Phases 3, 6, 7, 8, 10; in each recipient's language since Phase 9 |
| 60 | Notifications | Delay against noise | Free | have (30 s batching) |
| 61 | Notifications | Per-type settings | Free | have (push per type in Phases 2 and 6); email summary choice in Phase 10 |
| 62 | Notifications | Email notifications | Free | have (Phase 10) as one summary email: Auto (daily without push, else monthly) / Daily / Weekly / Monthly / Off; per-event emails and per-type email toggles out of scope |
| 63 | Notifications | Monthly summary email | Free | have (Phase 10): the Monthly choice, also Auto's default with push on; the balances section uses Hyojun's functions through `Balances.ofGroup` |
| 64 | Notifications | Email before a recurring bill posts | Free | have (Phase 10): 1, 3 or 7 days before, to everyone on the expense with an email, once per occurrence |
| 65 | Reminders | Remind a friend to pay | Free | have (Phase 6) |
| 66 | Settle | Record a payment, any payer and receiver | Free | have (Phase 6) |
| 67 | Settle | Custom amount, date, edit payment | Free | have (Phase 6) |
| 68 | Settle | Undo settlement | Free | have |
| 69 | Settle | PayPal / Venmo | Free | have (+ Wise, Revolut, KakaoPay, EPC QR, IBAN, KR bank) |
| 70 | Settle | Request payment | Free | have |
| 71 | Settle | Sent → confirmed | n/a | have (extra) |
| 72 | Settle | Paytm / UPI | Free | have (Phase 10): UPI links with the amount for INR (Paytm supports UPI) |
| 73 | Settle | Splitwise Pay / Pay by Bank / Card | Free | out of scope (moves money, needs a licence) |
| 74 | Currency | Any currency per expense | Free | have (Phase 4): 155 ISO codes, searchable picker, automatic daily rate via Frankfurter (ECB and other central banks; editable, cached offline); crypto out of scope |
| 75 | Currency | Default (home) currency | Free | have (Phase 4): set in Settings and stored on the account; "≈" lines in it on the groups list, Balances and Settle up |
| 76 | Currency | Convert to one currency | Pro | have (Phase 4 conversion by Hyojun; Phase 6 records payments in any currency) |
| 77 | Currency | Change an expense's currency label | Free | have |
| 78 | Search | Search all expenses | Pro | have (Phase 5, free): all groups or one, offline, accents ignored, amounts, category and month filters; payments and member names are not searched |
| 79 | Recurring | Weekly / fortnightly / monthly / yearly | Free | have (Phase 8): incl. every 2 weeks, month ends clamped, "Delete and stop repeating" |
| 80 | Export | Spreadsheet per group/friend | Free | have (Phases 3–5 add the payers, rate and category columns) |
| 81 | Export | JSON backup of the whole account | Pro | have (Phase 10, free): Export everything, deleted groups included; receipts via the per-group ZIP |
| 82 | Import | Bank/card transactions | Pro | out of scope (open-banking contracts cost money) |
| 83 | Import | From other apps | n/a | have (Splitwise CSV, fixed in Phases 3 and 5) |
| 84 | Platform | Offline add, sync later | Free | have |
| 85 | Platform | Web app | Free | have (Phase 9): the same app at `/app/` on the server; data kept in the browser, tabs share one database; sync on focus and every 60 s instead of push; no receipt scan, widget or app lock; a centred phone-width column on narrow windows; from 1024 px a desktop layout (Phase 10): Dashboard, Activity, All expenses, groups and friends on the left, the page in the middle, balances on the right |
| 86 | Platform | Languages | Free | have (Phase 9): Splitwise's 12 + Korean, from the system or Settings → Language; feed, push and invite pages in each reader's language; local money and date formats; machine-translated, Korean review by Hyojun pending |
| 87 | Platform | Dark mode follows the system | Free | have |
| 88 | Platform | Appearance toggle | Free | have (Phase 9): System / Light / Dark |
| 89 | Platform | Home-screen widget | n/a | have (Phase 9, extra): iOS small/medium, Android 2×2; overall net per currency, refreshed when the app syncs |
| 90 | Account | Sign-in methods | Free | have (Apple, Google; email code since Phase 10, also on web); Facebook out of scope |
| 91 | Account | Email login, password reset, change email | Free | have (Phase 10): 6-digit codes, no passwords to reset; add, change (by code) or remove the account email |
| 92 | Account | Facebook login | Free | out of scope (Meta review and tracking; Apple/Google/email cover users) |
| 93 | Account | Phone number on account | Free | out of scope (SMS cost) |
| 94 | Account | Name | Free | have |
| 95 | Account | Profile photo | Free | have (Phase 6) |
| 96 | Account | Time zone | Free | have (Phase 8): per repeating series, from the device; no account setting |
| 97 | Account | Log out on all devices | Free | have (Phase 10): refresh tokens and devices go at once, access tokens within 15 minutes |
| 98 | Account | Passcode / Face ID lock | Free | have (Phase 9): Face ID / Touch ID / fingerprint with the device passcode as fallback; no separate app passcode |
| 99 | Account | 2FA | n/a | n/a (Apple/Google accounts carry 2FA) |
| 100 | Account | Close account | Free | have (`DELETE /me`; Phases 6 and 10 extend the cleanup) |
| 101 | Privacy | Only people who share a group see it | Free | have |
| 102 | Support | In-app help / contact | Free | have (Phase 10): Help & feedback with GitHub issues, the operator's support email when set, and the privacy policy |
| 103 | Pro | Ad-free | Pro | have (never ads) |
| 104 | Pro | Early access, Trip Pass, Duo plan | Pro | n/a (everything free) |
| 105 | Activity | Unread activity indicator and app-icon badge | Free | have (Phase 6) |
| 106 | Settle | Comments on payments | Free | have (Phase 6) |
| 107 | Expense | List row for an expense with several payers says how many paid (e.g. "2 people paid €300.00"), not "paid by Anna +1" | Free | have (Phase 5) |
| 108 | Expense | Read-only expense detail: who paid how much, each person's share, then Edit | Free | have (Phase 5): with notes, History and comments; Edit opens the form |
| 109 | Friends | Friend page lists shared-group transactions too | Free | have (Phase 7): grouped by group, read-only rows |
| 110 | Settle | Restore a deleted payment | Free | have (Phase 7): Undo after delete, Restore on its detail and in Activity |
