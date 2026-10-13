# Evensies — store listing copy

Version 1.0.0 (the first store release) with everything from Phases 1–11. English only; the app itself has 13 languages.

Screenshots: `ios-6.9/` (iPhone 16 Pro Max, 1320×2868, light) and `ios-6.9-dark/` (same device, dark) were captured on 2026-10-11 **before Phases 1–11** and must be retaken at release (see the notes at the bottom).

---

## App Store (iOS)

### App name (30)
`Evensies: Split & Settle Up`

### Subtitle (30)
`Share expenses, no limits`

### Promotional text (170)
Split trips, homes and nights out six ways, in any currency, with pay links and receipt scanning. No limits, no ads, no paywall: every feature is free.

### Description (4000)
Day one of the trip, dinner is paid, and the app you use to split it tells you that you have hit today's limit. Evensies exists so that never happens again.

Evensies splits shared costs with friends, roommates, partners and travel companions. Create a group or add a friend, enter what you paid, and everyone sees who owes whom. When it is time to settle, Evensies works out the fewest transfers and opens the app you pay with.

SPLIT IT ANY WAY
• Six ways to split: equally (untick anyone who wasn't there), exact amounts, percentages, shares, adjustments (more or less for one person) and by item
• Several payers on one bill, refunds, "owes the full amount" shortcuts and a default split per group
• Receipt photos, and receipt scanning: the text is read on your phone, you assign each line, and tax, tip and discount are spread for you
• Repeating expenses for rent and subscriptions: every week, every 2 weeks, every month or every year

ANY CURRENCY
• 155 currencies, a different one per expense if you like
• Exchange rates filled in automatically every day, and you can edit them
• A home currency that your balances are also shown in

GROUPS AND FRIENDS
• Groups for a trip, a home, a couple or anything else, with a cover photo
• Invite by link, code, QR code or email; add friends who haven't installed the app yet as placeholders, and they claim their name later
• Friends: expenses between two people outside any group, and one balance per person across everything you share
• Remind a friend to pay; block or report someone if you need to
• Delete a group and restore it later, with everything in it

SETTLE UP
• The fewest transfers that clear every balance; simplify debts can be turned off per group
• Pay with PayPal, Wise, Venmo, Revolut, KakaoPay or UPI, with the amount filled in where the app allows it, or by bank transfer with an EU payment QR code (EPC) or a copied IBAN or Korean bank account
• "I've sent it" on your side, "received" on theirs
• Request money with a message that lists how to pay you
• Evensies never holds or moves money

STAY IN THE LOOP
• Activity for each group and for all of them, with push notifications for other people's changes
• Comments on expenses and payments, notes and the full edit history
• Restore a deleted expense or payment
• Categories with icons, guessed from the description; search across all expenses; charts by month, category and person
• An email summary (daily, weekly or monthly) if you'd rather not get push

YOUR WAY
• Works offline: add expenses without signal; they sync when you are back and conflicts are resolved field by field
• 13 languages with local money and date formats
• A home-screen widget with your overall balance
• App lock with Face ID or Touch ID
• The same account in your browser with the web app
• Sign in with Apple, Google or a code sent to your email; sign out on all devices; delete your account in Settings
• Export a group as JSON, CSV or a ZIP with its receipts, or everything as one JSON file; import a Splitwise CSV

OUR PROMISES
1. No input limits, ever. Not per day, not per group.
2. No ads and no tracking.
3. Export is always available. Your data leaves whenever you do.
4. No paywall. Every feature is free.
5. Open source (Apache-2.0).

NO ADS, NO TRACKING
Evensies has no advertising and no analytics SDKs. The server keeps only what the app needs to work, and nothing is sold or shared.

OPEN SOURCE
The app and the server are open source on GitHub, so anyone can check how balances are computed and what is stored.

Evensies is built by one developer who got tired of being nickel-and-dimed for adding a receipt. If something is wrong, open an issue on GitHub and it will be read.

### Keywords (100, comma-separated, no spaces)
`expenses,bills,trip,roommates,group,shared,iou,travel,friends,debts,receipt,currency,splitter,owe`

The name already carries "split", "settle" and "up", so they are not repeated here (Apple indexes both).

### What's New (1.0)
App Store Connect shows this field only from the second version; Google Play uses it as the release notes (500 characters).

First release.
• Six ways to split, several payers, refunds
• Any currency with daily exchange rates
• Groups, friends, invites by link, code, QR or email
• Settle up with PayPal, Wise, Venmo, Revolut, KakaoPay, UPI or bank transfer
• Receipt photos and scanning, repeating expenses
• Activity, push, comments, categories, search, charts
• Offline, 13 languages, web app, widget, app lock
• Sign in with Apple, Google or email; export everything

### URLs
- Support URL: https://github.com/devyourown/evensies/issues
- Marketing URL: https://github.com/devyourown/evensies
- Privacy Policy URL: https://devyourown.github.io/evensies/privacy (placeholder — publish `docs/privacy.md` here before submission)

### Category
- Primary: Finance
- Secondary: Travel

### Age rating questionnaire
Answer "None" / "No" to the content items (violence, sexual content, profanity, horror, medical or treatment information, alcohol, tobacco or drugs, mature themes, gambling and simulated gambling, contests) and to unrestricted web access (links open GitHub, the privacy policy and payment apps). Group members can comment on expenses and payments and see each other's names and photos, so answer **Yes** to user-generated content / messaging if the questionnaire asks; people can be blocked and reported (Friends tab → a person → ⋮). Not for the Kids category. Release 1 rated **4+** before comments existed; check the rating the questionnaire gives now.

### App Privacy (nutrition label)
Derived from `docs/privacy.md`. Everything is used for **App Functionality** only, is **linked** to the user's account and is **not used for tracking**.

| Data type | Collected | Notes |
|---|---|---|
| Contact Info → Name | Yes | Display name, from Apple/Google sign-in or typed by the user |
| Contact Info → Email Address | Yes | Email sign-in codes, the address in Settings → Email (or verified by Apple/Google), the summary email and repeating-expense reminders; addresses typed to invite someone are deleted after 14 days. Resend (EU) is the email processor |
| Financial Info → Other Financial Info | Yes | Ways to get paid the user adds (IBAN, bank account number, UPI ID, PayPal/Wise/Venmo/Revolut/KakaoPay link or username) and the amounts of shared expenses and payments |
| Financial Info → Payment Info | No | No in-app purchases; Evensies never takes, holds or moves money |
| User Content → Photos or Videos | Yes | Profile photo, receipt photos and group cover photos (all optional; re-encoded on the phone, location and other metadata removed) |
| User Content → Other User Content | Yes | Groups, members, expenses, notes, comments, payments, repeating expenses |
| Identifiers → User ID | Yes | Server account id, sign-in provider subject |
| Identifiers → Device ID | Yes | Push-notification token, only if the user allows notifications |
| Other Data | Yes | Settings kept on the account: app language, home currency, notification and email-summary choices, the time zone of a repeating expense |
| Purchases, Location, Contacts, Search History, Browsing History, Health & Fitness, Sensitive Info, Usage Data, Audio, Gameplay, Customer Support | No | Search runs on the phone; invites use the system share sheet; Report opens the user's own mail app |
| Diagnostics | No | No crash reporting or analytics SDK; Apple Vision reads receipts on the phone. Server logs (IP address, path, timestamp) are kept 14 days for abuse prevention only |

- Tracking: **No** — no advertising, no analytics SDKs, no data brokers.
- Processors: Apple and Google (sign-in), Firebase Cloud Messaging (push delivery), Resend (email delivery), Hetzner (server, Germany).
- Data deletion: Settings → Delete account, in the app or the web app (name, email, ways to get paid, profile photo, settings and blocks removed; expenses stay as a placeholder so other members' balances remain correct).

### Review notes for Apple
Evensies is a group expense-splitting app. Backend: `https://evensies.nariinfo.dev` (EU, Hetzner). Source code: https://github.com/devyourown/evensies.

Sign-in: "Continue with Apple" with any Apple ID (Hide My Email is fine), or "Continue with email" with any inbox you can read (a 6-digit code arrives; no password). No demo account is needed; the first sign-in creates the account and asks for a display name.

How to test:
1. On the Groups screen tap the group icon (top right) → "New group", give it a name, a type and a currency (a cover photo can be added in the group's settings).
2. In the group, tap the people icon (Members & invite) → "Add placeholder member" for two or three names. The invite link, code and QR on that screen are how real friends join; placeholders need no second account.
3. Tap "+ Expense", enter an amount and description, pick who paid, choose a split (Equal, Exact, %, Shares, ± or Items), Save. "Scan receipt" in the form reads a photographed receipt on the phone.
4. Open the "Balances" tab → "Settle up" to see the fewest transfers; "Mark as paid" records a payment.
5. Account deletion: Settings (gear on the Groups screen) → "Delete account".
6. Export: Settings → "Export everything (JSON)", or the ⋮ on a group's row → "Export JSON" / "Export CSV" / "ZIP with receipts".
7. Block and report: Friends tab → a person you share a group with → ⋮ → "Block" or "Report…" (opens an email to our support address).

The app works offline; expenses added without a connection sync when it returns. There are no in-app purchases. No ads, no third-party analytics.

---

## Google Play (Android)

### App name
Evensies: Split & Settle Up

### Short description (80)
Split trip and home costs with friends, any currency. No limits, ads or paywall.

### Full description (4000)
Day one of the trip, dinner is paid, and the app you use to split it tells you that you have hit today's limit. Evensies exists so that never happens again.

Evensies splits shared costs with friends, roommates, partners and travel companions. Create a group or add a friend, enter what you paid, and everyone sees who owes whom. When it is time to settle, Evensies works out the fewest transfers and opens the app you pay with.

<b>Split it any way</b>
• Six ways to split: equally (untick anyone who wasn't there), exact amounts, percentages, shares, adjustments (more or less for one person) and by item
• Several payers on one bill, refunds, "owes the full amount" shortcuts and a default split per group
• Receipt photos, and receipt scanning: the text is read on your phone, you assign each line, and tax, tip and discount are spread for you
• Repeating expenses for rent and subscriptions: every week, every 2 weeks, every month or every year

<b>Any currency</b>
• 155 currencies, a different one per expense if you like
• Exchange rates filled in automatically every day, and you can edit them
• A home currency that your balances are also shown in

<b>Groups and friends</b>
• Groups for a trip, a home, a couple or anything else, with a cover photo
• Invite by link, code, QR code or email; add friends who haven't installed the app yet as placeholders, and they claim their name later
• Friends: expenses between two people outside any group, and one balance per person across everything you share
• Remind a friend to pay; block or report someone if you need to
• Delete a group and restore it later, with everything in it

<b>Settle up</b>
• The fewest transfers that clear every balance; simplify debts can be turned off per group
• Pay with PayPal, Wise, Venmo, Revolut, KakaoPay or UPI, with the amount filled in where the app allows it, or by bank transfer with an EU payment QR code (EPC) or a copied IBAN or Korean bank account
• "I've sent it" on your side, "received" on theirs
• Request money with a message that lists how to pay you
• Evensies never holds or moves money

<b>Stay in the loop</b>
• Activity for each group and for all of them, with push notifications for other people's changes
• Comments on expenses and payments, notes and the full edit history
• Restore a deleted expense or payment
• Categories with icons, guessed from the description; search across all expenses; charts by month, category and person
• An email summary (daily, weekly or monthly) if you'd rather not get push

<b>Your way</b>
• Works offline: add expenses without signal; they sync when you are back and conflicts are resolved field by field
• 13 languages with local money and date formats
• A home-screen widget with your overall balance
• App lock with your fingerprint, face or device passcode
• The same account in your browser with the web app
• Sign in with Google, Apple or a code sent to your email; sign out on all devices; delete your account in Settings
• Export a group as JSON, CSV or a ZIP with its receipts, or everything as one JSON file; import a Splitwise CSV

<b>Our promises</b>
1. No input limits, ever. Not per day, not per group.
2. No ads and no tracking.
3. Export is always available. Your data leaves whenever you do.
4. No paywall. Every feature is free.
5. Open source (Apache-2.0).

<b>No ads, no tracking</b>
Evensies has no advertising and no analytics SDKs. The server keeps only what the app needs to work, and nothing is sold or shared.

<b>Open source</b>
The app and the server are open source on GitHub, so anyone can check how balances are computed and what is stored.

Source code and issue tracker: https://github.com/devyourown/evensies

### Release notes (500)
Same text as "What's New (1.0)" above.

### Category
Finance (Tags: expense tracker, travel)

### Content rating (IARC questionnaire)
No violence, sexuality, language, controlled substances or gambling. Users interact: group members see each other's names, photos, expenses and comments, and can block and report each other. No digital purchases. No location sharing. Expected rating: Everyone / PEGI 3, with the "Users Interact" notice.

### Data safety
- Does the app collect or share user data? **Collects: yes. Shares: no** (sign-in providers, Firebase Cloud Messaging and Resend process data on our behalf).
- Is all user data encrypted in transit? **Yes** (HTTPS).
- Can users request deletion? **Yes** — Settings → Delete account in the app or in the web app (`https://evensies.nariinfo.dev/app/`), or by email (privacy policy). Use the web app for Play's "delete account" URL.

| Data type | Collected | Shared | Required / optional | Purpose |
|---|---|---|---|---|
| Personal info → Name | Yes | No | Required | App functionality, account management |
| Personal info → Email address | Yes (email sign-in, Settings → Email, or verified by the sign-in provider; invite addresses kept 14 days) | No | Optional | App functionality (sign-in codes, summary and reminder emails, invites), account management |
| Personal info → User IDs | Yes | No | Required | App functionality, account management |
| Financial info → Other financial info | Yes (ways to get paid: IBAN, bank account, UPI ID, payment app usernames; amounts of expenses and payments) | No | Required | App functionality |
| Financial info → User payment info, Purchase history | No (no in-app purchases) | — | — | — |
| Photos and videos → Photos | Yes (profile, receipt and group cover photos, re-encoded without metadata) | No | Optional | App functionality |
| Messages → Other in-app messages | Yes (comments on expenses and payments) | No | Optional | App functionality |
| App activity → Other user-generated content | Yes (groups, members, expense descriptions, notes) | No | Required | App functionality |
| Device or other IDs | Yes (push token) | No | Optional | App functionality (notifications) |
| App info and performance → Diagnostics | **To confirm before submission**: the receipt scanner's ML Kit text recognition sends Google anonymous diagnostics about the library (never images or text). Answer from Google's ML Kit data disclosure guidance (https://developers.google.com/ml-kit/android-data-disclosure), not a plain "No" | — | — | — |
| Location, contacts, health, calendar, audio, files and docs, web browsing, app interactions, in-app search history, crash logs | No (search runs on the phone; an imported Splitwise CSV becomes expenses and is not kept) | — | — | — |

Security practices: data encrypted in transit; users can request deletion; no independent security review claimed.

---

## Before submission
- Retake the screenshots (below) on the current app; the listing describes features the old ones don't show.
- Set `EVENSIES_SUPPORT_EMAIL=support@nariinfo.dev` on the server, or Report… is hidden (Apple's guideline 1.2 asks for a way to report people).
- Store builds pass no `--dart-define`, so they have no Server field and talk only to the official server ([docs/API.md, Official server](../API.md#official-server-app-only)).
- Publish `docs/privacy.md` at the Privacy Policy URL.

## Notes on the screenshots
Captured 2026-10-11 from a debug build of release 1 (before Phases 1–11); retake at release, adding at least receipt scanning or Items, pay links on Settle up and the Friends tab.
- `ios-6.9/01-groups.png` — Groups list (Flat 12 "You are owed €978.60", Rome trip "You owe €60.13")
- `ios-6.9/02-expenses.png` — Rome trip → Expenses tab, date-grouped with lent/borrowed lines
- `ios-6.9/03-balances.png` — Balances tab with bars and Settle up button
- `ios-6.9/04-settle-up.png` — Settle up: three transfer cards
- `ios-6.9/05-expense-form.png` — New expense, Exact split with "Adds up" helper
- `ios-6.9/06-members-invite.png` — Members & invite with the production invite link
- `ios-6.9-dark/01-groups.png`, `ios-6.9-dark/03-balances.png` — same screens in dark mode
- Status bar overridden to 9:41 / full battery / full signal (`xcrun simctl status_bar`).
- The group is named "Rome trip" (the flag emoji could not be typed through the simulator's HID input).
- `lib/app.dart` now sets `debugShowCheckedModeBanner: false`, so a debug build captures without the banner.
