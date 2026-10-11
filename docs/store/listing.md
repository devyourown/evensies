# Evensies — store listing copy

Screenshots: `ios-6.9/` (iPhone 16 Pro Max, 1320×2868, light), `ios-6.9-dark/` (same device, dark). All captured 2026-10-11 from a debug build with the DEBUG banner disabled (see README note at the bottom).

---

## App Store (iOS)

### App name (30)
`Evensies: Split & Settle Up`

### Subtitle (30)
`Share expenses, no limits`

### Promotional text (170)
Expense splitting for trips, flats and friends. Add as many expenses as you like, settle with the fewest transfers, export anytime. No ads, no paywall.

### Description (4000)
Day one of the trip, dinner is paid, and the app you use to split it tells you that you have hit today's limit. Evensies exists so that never happens again.

Evensies is an app for splitting shared costs with friends, roommates and travel companions. Create a group, add what you paid, and everyone sees who owes whom. When the trip is over, Settle up tells you the smallest set of transfers that clears every balance.

WHAT YOU GET
• Groups for a trip, a flat, a weekend or a long-running friend circle
• Placeholder members: add friends who have not installed the app yet; they claim their name later from an invite link
• Equal, exact-amount and percentage splits, with a live "adds up" check
• Per-expense currency with an exchange rate to the group's currency
• Balances at a glance, with a bar for every member
• Settle up: the minimum number of transfers, each one markable as paid
• Offline first: add expenses without signal; they sync when you are back online and conflicts are resolved field by field
• Sign in with Apple or Google; delete your account from Settings at any time
• Export every group as JSON or CSV; import a CSV from your previous expense app

OUR PROMISES
These are written into the project so they cannot quietly change later:
1. No input limits, ever. Not per day, not per group.
2. No ads and no tracking.
3. Export is always available. Your data leaves whenever you do.
4. No paywall. Every feature is free; Evensies is funded by optional tips, and a tip never unlocks anything.
5. The source code stays public.

NO ADS, NO TRACKING
Evensies has no advertising and no analytics SDKs. The server stores your display name, the identifier your sign-in provider gives us, and the expenses your groups enter. That is it.

PUBLIC SOURCE, FUNDED BY TIPS
The source code of the app and the server is public on GitHub, so anyone can check how balances are computed and what is stored. If Evensies saves you an argument, you can leave a tip from Settings → Support Evensies. Tips are optional and unlock nothing.

Evensies is built by one developer who got tired of being nickel-and-dimed for adding a receipt. If something is wrong, open an issue on GitHub and it will be read.

### Keywords (100, comma-separated, no spaces)
`split,expenses,bills,trip,roommates,group,settle,shared,iou,travel,friends,budget,debts`

### What's New (1.0)
First release.
• Groups with invite links and placeholder members
• Equal, exact and percentage splits; per-expense currency
• Balances and Settle up with the minimum number of transfers
• Offline-first sync
• Sign in with Apple / Google, account deletion
• Export JSON / CSV, import CSV

### URLs
- Support URL: https://github.com/devyourown/evensies/issues
- Marketing URL: https://github.com/devyourown/evensies
- Privacy Policy URL: https://devyourown.github.io/evensies/privacy (placeholder — publish `docs/privacy.md` here before submission)

### Category
- Primary: Finance
- Secondary: Travel

### Age rating questionnaire
Answer "None" / "No" to every item (cartoon or realistic violence, sexual content, profanity, horror, medical/treatment info, alcohol/tobacco/drugs, mature themes, gambling, contests, unrestricted web access, simulated gambling, Kids category). Resulting rating: **4+**.

### App Privacy (nutrition label)
Derived from `docs/privacy.md`.

| Data type | Collected | Linked to user | Used for tracking | Purpose |
|---|---|---|---|---|
| Contact info → Name | Yes (display name from Apple/Google sign-in or chosen by the user) | Yes | No | App functionality |
| Contact info → Email address | Yes (only if the sign-in provider shares it; Apple relay addresses are fine) | Yes | No | App functionality |
| User content → Other user content (groups, members, expenses, payments) | Yes | Yes | No | App functionality |
| Identifiers → User ID | Yes (server account id, provider subject) | Yes | No | App functionality |
| Identifiers → Device ID (push-notification token) | Yes, only if the user allows notifications | Yes | No | App functionality |
| Diagnostics | No (server logs keep IP/path/timestamp for 14 days for abuse prevention; not linked to identity in a way the user can be looked up by) | — | — | — |

- Tracking: **No** — no advertising, no analytics SDKs, no data shared with data brokers.
- Third parties receiving data: Apple / Google (sign-in only), Firebase Cloud Messaging (push delivery only).
- Data deletion: Settings → Delete account (name removed; expenses stay as placeholders so other members' balances remain correct).

### Review notes for Apple
Evensies is a group expense-splitting app. Backend: `https://evensies.nariinfo.dev` (EU, Hetzner). Source code: https://github.com/devyourown/evensies.

How to test:
1. Tap "Continue with Apple" and sign in with any Apple ID (Hide My Email is fine). No separate test account is needed; the first sign-in creates the account.
2. On the Groups screen tap "Create group", give it a name and currency.
3. Open the group → people icon (top right) → "Add placeholder member" to add two or three names. The invite link on that screen is how real friends join; placeholder members need no second account.
4. Tap "+ Expense", enter an amount and description, pick who paid, choose Equal / Exact / Percent, Save.
5. Open the "Balances" tab → "Settle up" to see the minimum transfers; "Mark as paid" records a payment.
6. Account deletion: Settings (gear on the Groups screen) → "Delete account".
7. Export: Settings → group row → "Export JSON" / "Export CSV".

The app works offline; expenses added without a connection sync when it returns. The only in-app purchases are optional tips (Settings → Support Evensies); they unlock nothing. No ads, no third-party analytics.

---

## Google Play (Android)

### App name
Evensies: Split & Settle Up

### Short description (80)
Split trip and flat expenses with friends. No limits, no ads, no paywall.

### Full description (4000)
Day one of the trip, dinner is paid, and the app you use to split it tells you that you have hit today's limit. Evensies exists so that never happens again.

Evensies is an app for splitting shared costs with friends, roommates and travel companions. Create a group, add what you paid, and everyone sees who owes whom. When the trip is over, Settle up tells you the smallest set of transfers that clears every balance.

<b>What you get</b>
• Groups for a trip, a flat, a weekend or a long-running friend circle
• Placeholder members: add friends who have not installed the app yet; they claim their name later from an invite link
• Equal, exact-amount and percentage splits, with a live "adds up" check
• Per-expense currency with an exchange rate to the group's currency
• Balances at a glance, with a bar for every member
• Settle up: the minimum number of transfers, each one markable as paid
• Offline first: add expenses without signal; they sync when you are back online and conflicts are resolved field by field
• Sign in with Google or Apple; delete your account from Settings at any time
• Export every group as JSON or CSV; import a CSV from your previous expense app

<b>Our promises</b>
These are written into the project so they cannot quietly change later:
1. No input limits, ever. Not per day, not per group.
2. No ads and no tracking.
3. Export is always available. Your data leaves whenever you do.
4. No paywall. Every feature is free; Evensies is funded by optional tips, and a tip never unlocks anything.
5. The source code stays public.

<b>No ads, no tracking</b>
Evensies has no advertising and no analytics SDKs. The server stores your display name, the identifier your sign-in provider gives us, and the expenses your groups enter. That is it.

<b>Public source, funded by tips</b>
The source code of the app and the server is public on GitHub, so anyone can check how balances are computed and what is stored. If Evensies saves you an argument, you can leave a tip from Settings → Support Evensies. Tips are optional and unlock nothing.

Source code and issue tracker: https://github.com/devyourown/evensies

### Category
Finance (Tags: expense tracker, travel)

### Content rating (IARC questionnaire)
No violence, sexuality, language, controlled substances, gambling, or user-to-user communication beyond shared group data. Expected rating: Everyone / PEGI 3.

### Data safety
- Does the app collect or share user data? **Collects: yes. Shares: no.**
- Is all user data encrypted in transit? **Yes** (HTTPS).
- Can users request deletion? **Yes** — in-app (Settings → Delete account); also via email in the privacy policy.

| Data type | Collected | Shared | Required / optional | Purpose |
|---|---|---|---|---|
| Personal info → Name | Yes | No | Required | App functionality, account management |
| Personal info → Email address | Yes (if provided by sign-in provider) | No | Optional | Account management |
| Personal info → User IDs | Yes | No | Required | App functionality, account management |
| Financial info → Other financial info (expense amounts entered by the user) | Yes | No | Required | App functionality |
| Messages / Other user-generated content (group names, expense descriptions) | Yes | No | Required | App functionality |
| Device or other IDs (push token) | Yes | No | Optional | App functionality (notifications) |
| Location, contacts, photos, health, calendar, app activity, crash logs, diagnostics | No | — | — | — |

Security practices: data encrypted in transit; users can request deletion; no independent security review claimed.

---

## Notes on the screenshots
- `ios-6.9/01-groups.png` — Groups list (Flat 12 "You are owed €978.60", Rome trip "You owe €60.13")
- `ios-6.9/02-expenses.png` — Rome trip → Expenses tab, date-grouped with lent/borrowed lines
- `ios-6.9/03-balances.png` — Balances tab with bars and Settle up button
- `ios-6.9/04-settle-up.png` — Settle up: three transfer cards
- `ios-6.9/05-expense-form.png` — New expense, Exact split with "Adds up" helper
- `ios-6.9/06-members-invite.png` — Members & invite with the production invite link
- `ios-6.9-dark/01-groups.png`, `ios-6.9-dark/03-balances.png` — same screens in dark mode
- Status bar overridden to 9:41 / full battery / full signal (`xcrun simctl status_bar`).
- The group is named "Rome trip" (the flag emoji could not be typed through the simulator's HID input).
- Captured from a debug build: `lib/app.dart` does not set `debugShowCheckedModeBanner: false`, and profile mode is not supported on the simulator, so the capture was made from a throwaway copy of `app/` with that one line added. Nothing under `app/lib` was changed. Consider adding that line to `app/lib/app.dart` before release.
