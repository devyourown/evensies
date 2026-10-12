---
title: Privacy Policy
permalink: /privacy
---
# Privacy Policy (draft — review before store submission)

**Who:** Nari Information (Hyojun Lee), Republic of Korea. Contact: hyojoon56@gmail.com

**What we store:** your display name and the identifier your sign-in provider (Apple or Google) gives us; the groups, members, expenses and payments you and your group enter; the app language you use, so notifications arrive in it; a push-notification token for your device if you allow notifications; server logs (IP address, request path, timestamp) kept for 14 days for abuse prevention.

**Profile photo (optional):** if you add one in Settings, the app re-encodes it on your phone into a JPEG of at most 512 pixels (the camera's location and other metadata are removed before upload), and the server keeps that file on its disk. Only you and people who share a group with you (friends included) can see it. You can remove it at any time in Settings; deleting your account deletes it too.

**Receipt photos (optional):** if you attach a receipt to an expense, the app re-encodes it on your phone into a JPEG of at most 2048 pixels (the camera's location and other metadata are removed before upload), plus a small thumbnail, and the server keeps both files on its disk. Only the members of that group can see them. Removing a receipt deletes its files from the server; the group export (ZIP) includes the receipts.

**Receipt scanning:** "Scan receipt" reads the text of the photo on your phone: with Apple's Vision framework on iPhone, and with Google's ML Kit text recognition on Android. Neither the photo nor its text is sent anywhere for this. On Android the ML Kit library sends Google anonymous usage and diagnostic information about the library itself (for example its version and performance), never images or recognized text.

**Friends and reminders:** your friend code lets someone add you as a friend; you can get a new code on the Friends tab → Add a friend at any time, and the old one stops working. A friend you share expenses with can send you a reminder notification at most once a day; you can turn reminders off in Settings → Notifications.

**On your device:** the app keeps a copy of your groups on your phone so it works offline. The web app keeps the same copy, and your sign-in tokens, in your browser's storage (IndexedDB) for the Evensies site; signing out removes them, while settings such as language and appearance stay in the browser. If you add the home-screen widget, the app also writes your current totals (the net amount per currency and the time of the update, no names) to the widget's storage on the phone; the widget shows them on your home screen (on iPhone it is marked privacy-sensitive, so iOS can hide it on a locked screen), and signing out replaces them with "Sign in to see your balance". App lock uses your phone's Face ID, Touch ID, fingerprint or passcode; Evensies never sees that data.

**Web app:** to draw text, the web app downloads the Roboto and Noto fonts from Google Fonts (fonts.gstatic.com), it loads Google's sign-in script (accounts.google.com) on every visit, and where Google sign-in is offered its button can show your Google profile picture (googleusercontent.com); where Apple sign-in is offered, it also loads Apple's sign-in script (appleid.cdn-apple.com). These requests send your IP address and browser details to Google and Apple under their own privacy policies. Signing in with Apple opens appleid.apple.com. The web app sends no other requests to third parties.

**What we do not do:** no advertising, no analytics SDKs, no selling or sharing of data with third parties. Data is sent to Apple/Google only for sign-in (and, on the web app, the font and sign-in script downloads described above) and to Firebase Cloud Messaging only to deliver push notifications; on Android the receipt scanner's library sends Google the anonymous diagnostics described above.

**Where:** the server runs in the EU (Hetzner, Germany).

**Your rights:** export everything from Settings → Export at any time; delete your account from Settings → Delete account (your name is removed; expenses you entered stay in the group as a placeholder so other members' balances remain correct). Contact us to exercise any further rights under GDPR or Korean PIPA.

**Children:** the app is not directed at children under 13.

**Changes:** we will update this page and the date below. Last updated: 2026-10-12.
