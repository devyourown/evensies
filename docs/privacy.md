---
title: Privacy Policy
permalink: /privacy
---
# Privacy Policy (draft — review before store submission)

**Who:** Nari Information (Hyojun Lee), Republic of Korea. Contact: [support@nariinfo.dev](mailto:support@nariinfo.dev) (also in the app under Settings → Help & feedback → Email support), or [@devyourown on GitHub](https://github.com/devyourown).

**What we store:** your display name and the identifier your sign-in provider (Apple or Google) gives us; the groups, members, expenses and payments you and your group enter; the app language you use, so notifications arrive in it; a push-notification token for your device if you allow notifications; server logs (IP address, request path, timestamp) kept for 14 days for abuse prevention.

**Profile photo (optional):** if you add one in Settings, the app re-encodes it on your phone into a JPEG of at most 512 pixels (the camera's location and other metadata are removed before upload), and the server keeps that file on its disk. Only you and people who share a group with you (friends included) can see it. You can remove it at any time in Settings; deleting your account deletes it too.

**Receipt photos (optional):** if you attach a receipt to an expense, the app re-encodes it on your phone into a JPEG of at most 2048 pixels (the camera's location and other metadata are removed before upload), plus a small thumbnail, and the server keeps both files on its disk. Only the members of that group can see them. Removing a receipt deletes its files from the server; the group export (ZIP) includes the receipts.

**Receipt scanning:** "Scan receipt" reads the text of the photo on your phone: with Apple's Vision framework on iPhone, and with Google's ML Kit text recognition on Android. Neither the photo nor its text is sent anywhere for this. On Android the ML Kit library sends Google anonymous usage and diagnostic information about the library itself (for example its version and performance), never images or recognized text.

**Email (optional):** if you sign in with an email code, add an address in Settings → Email, or Apple or Google tell us your address is verified, we store that address. Other members never see it. We use it only for sign-in codes, the email summary, reminders before a repeating expense is added, and nothing else (no marketing). You can change it (confirmed by a code) or remove it in Settings; once removed, signing in with Apple or Google doesn't add it back. Every summary and reminder has an unsubscribe link, and you can turn the summary off in Settings → Notifications. Emails are plain text without tracking. The Evensies server sends them through Resend (EU region) as its email processor.

**Inviting someone by email:** if you type someone's address to invite them to a group, we send them one invite and at most one reminder, and delete the address after 14 days. They can stop all invites to that address with the link in the email.

**Email records:** to respect unsubscribes and bounces and to stay under sending limits, we keep a list of addresses that must not get email and a log of sent emails. Both store only a one-way hash of the address, not the address itself; the log is deleted after 30 days.

**Group cover photo (optional):** a cover photo is re-encoded like a receipt (location and other metadata removed) and only the group's members can see it.

**Ways to get paid (optional):** if you add a PayPal, Wise, Venmo, Revolut or KakaoPay link or username, a UPI ID, an IBAN or a bank account in Settings → Ways to get paid, we store it and show it to the people you share a group with (friends included) so they can pay you; account numbers and IBANs are masked in lists. Evensies never moves money: paying opens the payment app or shows the details to copy. You can change or remove them at any time; deleting your account deletes them.

**Blocking:** if you block someone, we store that you blocked them so their changes, reminders and friend requests stop reaching you. They are not told. Unblocking or deleting your account removes it.

**Friends and reminders:** your friend code lets someone add you as a friend; you can get a new code on the Friends tab → Add a friend at any time, and the old one stops working. A friend you share expenses with can send you a reminder notification at most once a day; you can turn reminders off in Settings → Notifications.

**On your device:** the app keeps a copy of your groups on your phone so it works offline. The web app keeps the same copy, and your sign-in tokens, in your browser's storage (IndexedDB) for the Evensies site; signing out removes them, while settings such as language and appearance stay in the browser. If you add the home-screen widget, the app also writes your current totals (the net amount per currency and the time of the update, no names) to the widget's storage on the phone; the widget shows them on your home screen (on iPhone it is marked privacy-sensitive, so iOS can hide it on a locked screen), and signing out replaces them with "Sign in to see your balance". App lock uses your phone's Face ID, Touch ID, fingerprint or passcode; Evensies never sees that data.

**Web app:** to draw text, the web app downloads the Roboto and Noto fonts from Google Fonts (fonts.gstatic.com), where Google sign-in is offered, the sign-in page loads Google's sign-in script (accounts.google.com) and its button can show your Google profile picture (googleusercontent.com); where Apple sign-in is offered, it also loads Apple's sign-in script (appleid.cdn-apple.com). These requests send your IP address and browser details to Google and Apple under their own privacy policies. Signing in with Apple opens appleid.apple.com. The web app sends no other requests to third parties.

**What we do not do:** no advertising, no analytics SDKs, no selling or sharing of data with third parties. Data is sent to Apple/Google only for sign-in (and, on the web app, the font and sign-in script downloads described above), to Firebase Cloud Messaging only to deliver push notifications, and to our email processor (Resend) only to deliver the emails described above; on Android the receipt scanner's library sends Google the anonymous diagnostics described above.

**Where:** the server runs in the EU (Hetzner, Germany).

**Your rights:** export everything from Settings → Export at any time ("Export everything" is one JSON file with your profile, payment methods, settings and every group, deleted groups included; receipt photos come with each group's ZIP); sign out on all devices from Settings; delete your account from Settings → Delete account (your name, email address, email settings and blocks are removed; expenses you entered stay in the group as a placeholder so other members' balances remain correct). Contact us to exercise any further rights under GDPR or Korean PIPA.

**Children:** the app is not directed at children under 13.

**Changes:** we will update this page and the date below. Last updated: 2026-10-13.
