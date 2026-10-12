# Phase 9 design — Platforms & language

One Flutter codebase runs on phones and in the browser. The app is translated into 13 languages, with local money and date formats. This phase also adds a home-screen widget, an appearance toggle and an app lock.

**Cost: 0.** There are no new event types. The appliers, `sync-cases.json`, `split-cases.json` and `settlement-cases.json` don't change. Rough size: 3 sessions (web; i18n and translations; widget, lock and appearance).

**Text decision:**
- The server sends the feed as structured data, and the app renders it in its UI language.
- Push, email and the landing pages are rendered by the server **per recipient**, from `shared/strings.json`, in `users.language`.
- Both sides read the same templates, so every phone and the server produce the same sentence.

### What users get
1. **Web app** (#85) at `https://evensies.nariinfo.dev/app/`, and at `/app/` on every self-hosted server, because it ships inside the server image.
   - The same screens as the phone app, signed in with Apple or Google (email codes from Phase 10).
   - Data is kept in the browser and syncs when online. Two tabs are safe, and it can be installed as an app.
   - Not on web: push, the widget, app lock, receipt OCR (Phase 7).
   - `/j/{code}` and `/f/{code}` get **Continue in the browser**.
2. **13 languages** (#86): English, Korean, Dutch, French, German, Indonesian, Italian, Japanese, Polish, Portuguese (Brazil), Spanish, Swedish and Thai. That is Splitwise's 12 plus Korean.
   - The app follows the system language, and **Settings → Language** overrides it.
   - The feed, push and landing pages appear in each reader's own language.
3. **Money and dates the local way.**
   - Examples: `1.234,56 €` (de), `1 234,56 €` (fr), `999,00 kr` (sv), `₩15,000` (ko).
   - Typing `12,50` means €12.50. Today it silently saves **€1,250.00**, and a rate typed as `1,08` is lost.
   - Shared symbols are spelled out: `CA$`, `A$`, `CN¥`, `SEK`.
4. **Home-screen widget** (iOS small/medium, Android 2×2): "You are owed €42.10 · You owe ₩12,000" plus "Updated 10:42". Amounts are redacted while the iPhone is locked.
5. **Appearance** (#88): System, Light or Dark.
6. **App lock** (#98).
   - Face ID, Touch ID or fingerprint, with the device passcode as fallback.
   - Locks at launch and after 1 minute in the background; the app switcher shows a cover.
   - **Sign out** on the lock screen is the "forgot passcode" path.

### How (server)
**Web app inside the server image** (so the single-image self-hosting promise holds; no Caddy volume).
- **Dockerfile:**
  - a first stage `FROM ghcr.io/cirruslabs/flutter:3.41.4 AS web`, with CI's `subosito/flutter-action` pinned to the same version;
  - it copies `app/pubspec.yaml`, `app/pubspec.lock`, `app/l10n.yaml`, `app/analysis_options.yaml`, `app/lib`, `app/web` and `app/assets`, then runs `flutter build web --release --base-href /app/ --no-web-resources-cdn --csp`;
  - the Gradle stage copies `build/web/` into `server/src/main/resources/static/app/` (gitignored) before `bootJar`.
- **Serving:**
  - `WebConfig` adds `GET /` → 302 `/app/`, `GET /app` → 302 `/app/`, `/app/` → `forward:/app/index.html`;
  - `spring.web.resources.cache.cachecontrol.no-cache: true`;
  - Tomcat already maps `.wasm` (checked in 11.0.24);
  - `/`, `/app` and `/app/**` are `permitAll`;
  - Caddy and the `/j/*` and `/f/*` links are unchanged.
- **Root `.dockerignore`:** `app/build`, `app/ios/Pods`, `app/.dart_tool`, `**/*.jks`, `**/key.properties`, `deploy/secrets`, `deploy/backups`, `deploy/data`.
- **Release checklist** (not now): CI builds and pushes `ghcr.io/devyourown/evensies-server`, and `update.sh` switches to `docker compose pull`. Building Flutter on the 4 GB server would be heavy.

**CSP on every response**, through Spring Security `headers { contentSecurityPolicy }` (exact string under Contract changes).
- Tokens live in IndexedDB, so no third-party script may run on our origin.
- Flutter web loads Roboto and the Noto fallbacks from `fonts.gstatic.com`. This is allowed and disclosed in `docs/privacy.md`.
- **All images** (Phase 6 avatars, Phase 7 receipts, Phase 10 covers) come from the API origin through `ApiClient` and are shown with `Image.memory`. No CORS or CSP change is needed for them.

**CORS for development only.** `EVENSIES_CORS_ORIGINS` (exact origins, default empty) feeds a `CorsConfigurationSource`. The `dev` profile sets `http://localhost:7357`. No wildcards and no credentials.

**Web sign-in.**
- Apple's JS SDK returns `aud` = a **Services ID**, and Google Identity Services returns `aud` = the **web client id**.
- `appleServicesId` and `googleWebClientId` are added to the verifiers' audience lists.
- New public **`GET /info`** returns them plus `devLogin`, so one prebuilt bundle works on any server. Phase 10 adds keys to the same endpoint.
- The Services ID is grouped under the primary App ID, so Apple returns the same `sub` as on iOS. Google's `sub` is per account.

**User language.** `users.language` (`NULL` = English), set by `PATCH /me`, returned by `GET /me`, and used for push now and email in Phase 10.

**`shared/strings.json`** is copied to `server/src/main/resources/strings.json` and checked for equality.
- `Sentences.render(lang, items, viewer, groupKind)` replaces Phase 2's English-only `ActivityText` and covers every kind from Phases 2–8.
- The push fan-out (`PushNotifier`) groups recipients by `users.language` and sends one FCM multicast per language.
- Titles: the group name; for friend groups, the other member's name.
- The reminder push (Phase 6) uses `remind.*` in the recipient's language.
- `/j/{code}` and `/f/{code}` pick a language from `Accept-Language` with `Locale.lookupTag(ranges, languagesInStringsJson)`, default `en`, set `<html lang>`, and add the browser link.

### How (app)
#### Web build
- **Platform folder:** `flutter create --platforms web .` creates `app/web/`.
  - `index.html`: title, description, `<meta name="color-scheme" content="light dark">`, and the Apple JS SDK `<script src="https://appleid.cdn-apple.com/appleauth/static/jsapi/appleid/1/en_US/appleid.auth.js">`.
  - `manifest.json`: name, teal theme colour, icons.
- **drift on web:** `DriftWebOptions(sqlite3Wasm: Uri.parse('sqlite3-3.5.2.wasm'), driftWorker: Uri.parse('drift_worker-2.34.4.js'), onResult: …)`.
  - Both files are committed in `app/web/`; their versions match `pubspec.lock`, and a test enforces this.
  - No COOP/COEP, so drift uses IndexedDB in a shared worker and all tabs share one database. `ponytail:` OPFS needs cross-origin isolation, which breaks the sign-in popups.
  - Chrome on Android falls back to per-tab IndexedDB.
- **No `dart:io` left in `lib/`:**
  - `appleAvailable` = `kIsWeb || iOS || macOS`;
  - `initPush` and `_listenDeepLinks` are skipped on web;
  - export uses `XFile.fromData` with `fileNameOverrides`;
  - import uses `pickFiles(withData: true)` + `MultipartFile.fromBytes` (`importSplitwise(String groupId, List<int> bytes)`);
  - receipt and avatar files use the in-memory paths;
  - the direct `path_provider` and `path` dependencies are removed.
- **Images on web:** `image_picker` with `maxWidth`/`maxHeight`/`imageQuality`, which resizes on a canvas and drops EXIF. `flutter_image_compress` is mobile only (behind `kIsWeb`). A non-JPEG result is refused in the app: "Choose a JPEG photo". `ponytail:` canvas-encode PNGs if people hit it.
- **Server URL on web:** `Uri.base.origin`, unless `--dart-define=EVENSIES_SERVER_URL` is given (dev). The Settings → Server field is hidden on web.
- **Sign-in on web** reads `GET /info`:
  - **Apple** (if `appleServicesId` is set): `getAppleIDCredential(…, webAuthenticationOptions: WebAuthenticationOptions(clientId: servicesId, redirectUri: Uri.parse('${Uri.base.origin}/app/')))`. Apple rejects localhost.
  - **Google:** `GoogleSignIn.instance.initialize(clientId: googleWebClientId)` plus `renderButton()` from `package:google_sign_in_web/web_only.dart`, behind a `dart.library.js_interop` conditional import. `google_sign_in_web` 1.1.3 becomes a direct dependency.
  - **Dev login** when `devLogin` or `DEV_LOGIN` is set.
- **Token refresh.** Concurrent 401s share one refresh `Future`. If a refresh fails and the stored refresh token has changed (another tab refreshed), retry with the stored access token instead of `clearSession()`. This also fixes a phone race.
- **Freshness without web push:** `syncAll()` on tab focus and every 60 s while visible.
- **Share text on web:** copied to the clipboard with a snackbar.
- **Layout on web:** centred in a 640 px column on `surfaceContainerLow`.
- **Routes keep their target through sign-in:** `/login?next=…`, only if it starts with `/`.
- **URLs:** hash URLs (`/app/#/groups/<id>`).
- **Feature limits on web:**
  - Phase 7 "Scan receipt" is hidden; manual Items works.
  - The widget and app lock don't exist on web.
  - Phase 8 uses the browser's offset.
  - Phase 6 QR codes render with `qr_flutter`.

#### String extraction plan
**1. Setup.**
- `flutter_localizations` and `flutter: generate: true`.
- `app/l10n.yaml`:
  ```yaml
  arb-dir: lib/l10n
  template-arb-file: app_en.arb
  output-localization-file: app_localizations.dart
  nullable-getter: false
  required-resource-attributes: true   # every key needs an @description for translators
  preferred-supported-locales: [en]
  ```
- The generated files are committed.
- `MaterialApp.router` gets `localizationsDelegates`, `supportedLocales`, `locale: ref.watch(languageProvider)` and `onGenerateTitle`.
- Access is through `context.l` (`lib/core/l10n.dart`, which also holds the endonym map).
- Tests use `test/app_harness.dart` in English.

**2. What goes where.**

| Text | Where |
|---|---|
| All UI text in `lib/features/**` and `lib/core/**`, including Phases 3–8 screens (split editor, group settings, currency picker, insights, category labels by key, friends, itemize, repeat) | ARB |
| Messages for error codes (server `code`, `SplitException`, `FxException`, payment-method validation) | ARB; unknown code → `errorGeneric(code)`; the server `message` is never shown |
| Share texts (invite, Request, Phase 5 summary), widget labels, lock screen | ARB, in the sender's language |
| Activity, push, reminder, landing and Phase 10 email text | `shared/strings.json` |
| User content; brand and provider names; currency codes and symbols; ISO dates in change lists | Not translated |

**3. Message rules** (written into the `@description` entries):
- whole sentences with placeholders, never concatenated fragments;
- ICU plurals (`one`/`other`, plus `few`/`many` for Polish);
- amounts arrive as formatted strings;
- names are phrased gender-neutrally;
- register: informal for de, es, it, nl, sv, pl, pt; formal for fr (vous), ja (です/ます) and ko (해요체).

**4. Domain code stays string-free.** `methodFieldError` and `methodsError` return codes (`USERNAME`, `LINK_PREFIX`, `TOO_LONG`, `IBAN`, `HOLDER`, `BIC`, `KR_ACCOUNT`, `BANK`, `UNKNOWN_TYPE`, `TOO_MANY`, Phase 10 `UPI`). `requestText` takes localized parts.

**5. Order of work:**
1. infra;
2. move strings file by file (English output byte-identical);
3. domain codes;
4. turn on the guard tests;
5. Claude agents translate ARB and `strings.json`, using a fixed term list (expense, balance, settle up, owe, owed, share, split, group, payment, refund, receipt, repeat);
6. Hyojun reviews Korean; the README marks the others "machine-translated — reviews welcome".

**6. iOS:** `CFBundleLocalizations` lists `en ko nl fr de id it ja pl pt es sv th`.

#### Money and dates
- **Formatting.**
  - `formatMoney(int minor, String currency, {String? lang})` implements notation `M(x)` (Contract changes) without intl. `lang` defaults to `Money.lang`.
  - Dates: `Intl.defaultLocale` is the device locale if it has the same language, else the UI locale; `DateFormat.yMMMEd()` / `MMMEd()`; `initializeDateFormatting()` in `main()`.
- **Input.**
  - `parseMoney(text, currency, {lang})` (rule below).
  - `parseDecimal(text)` for percent, fx rate and share counts: the last separator is the decimal mark, the other kind is grouping, and a repeat of the same kind → null.
  - `inputAmount(minor, currency, {lang})` writes the language's decimal and no grouping (prefills, hints, **Copy amount**).
  - `plainAmount` stays `.` for URLs and the EPC QR.
  - No `toStringAsFixed` or number `toString()` in UI.
- **`parseMoney` rule** (money safety):
  1. Drop whitespace (incl. U+00A0, U+202F), `'` and `’`, and anything other than digits, `.`, `,` or a leading `-`.
  2. No separator → whole units.
  3. With `c` = the last separator, `k` = the digits after it, `D` = the language's decimal character and `d` = the currency's decimals:
     - `c == D` → decimal mark; null if `k > d`;
     - `c ≠ D` and `k == 3` → grouping with no decimals; null if `D` appears anywhere;
     - otherwise → decimal mark (lenient); null if `k > d`.
  4. Before a decimal mark, the same character may not appear again. The other separator is dropped.
- **Language sync:** after login, and whenever the resolved language changes, `PATCH /me {"language": "<code>"}` (fire-and-forget, `sentLanguage` in prefs, cleared on sign-out).

#### Home-screen widget
- **Dependency:** `home_widget` 0.9.3 (BSD-3). Not used on web.
- **Payload.** One pre-formatted, pre-translated JSON built from Phase 6's `Overview`.
  - Per-currency nets, zeros dropped, sorted by |net| descending then currency, at most 4.
  - A single converted line if Phase 4's home-currency conversion works for every line.
  - Stored under key `summary` (`group.dev.nariinfo.evensies` on iOS, home_widget prefs on Android).
  ```json
  {"v": 1,
   "lines": [{"text": "You are owed", "amount": "€42.10", "tone": "owed"},
             {"text": "You owe", "amount": "₩12,000", "tone": "owe"}],
   "empty": null,
   "updated": "Updated 11 Oct, 10:42"}
  ```
  - Signed out: `lines: []`, `empty: "Sign in to see your balance"`.
  - All zero: `empty` = "All settled up".
  - Never written: the widget shows only "Evensies".
- **When the app writes:** on overview or language changes, debounced 1 s, and only when the content changed. Then `HomeWidget.updateWidget(iOSName: 'EvensiesWidget', androidName: 'BalanceWidgetProvider')`. Sign-out and account deletion write the signed-out payload. There is no background refresh.
- **iOS:**
  - Widget Extension `EvensiesWidget` in SwiftUI (the extension needs iOS 17; the app stays at 15.5 from Phase 7);
  - App Group `group.dev.nariinfo.evensies`;
  - `.systemSmall` with 2 lines and `.systemMedium` with 4; timeline `.never`;
  - `.privacySensitive()`; teal for owed, red for owe; "…" when lines don't fit.
- **Android:** `BalanceWidgetProvider : HomeWidgetProvider` with `org.json`; layout `balance_widget.xml` (title, 3 lines, updated); `balance_widget_info.xml` (2×2, resizable, `updatePeriodMillis="0"`); `values-night` colours; tap → `HomeWidgetLaunchIntent.getActivity`.

#### Appearance and app lock
- **Appearance:** `themeModeProvider` (prefs `themeMode`) drives `MaterialApp.themeMode`, set from a segmented control in Settings.
- **App lock:** `local_auth` 3.x.
  - Settings → Security → **App lock**, shown only when `isDeviceSupported()` and never on web.
  - Turning it on requires one successful `authenticate(localizedReason: l.lockReason, biometricOnly: false)`.
  - The overlay sits in `MaterialApp.builder`, above the navigator: locked at cold start; a cover while `inactive`/`hidden`/`paused`; on resume it locks after 60 s or more away.
  - Buttons: **Unlock** (prompts once automatically) and **Sign out** (with a confirm).
  - Android's `MainActivity` becomes `FlutterFragmentActivity()`; iOS gets `NSFaceIDUsageDescription`.

### Contract changes
1. **`GET /info`** (public):
   ```
   200 {"appleServicesId": "dev.nariinfo.evensies.web" | null,
        "googleWebClientId": "735984614718-p2ga7bem68i1tbs6se9tmfrcrepfnggt.apps.googleusercontent.com" | null,
        "devLogin": false}
   ```
   Phase 10 adds `emailLogin`, `appleLogin`, `googleLogin` and `supportEmail`.
2. **Accepted audiences:**
   - `/auth/apple`: `aud` ∈ {`EVENSIES_APPLE_CLIENT_ID`, `EVENSIES_APPLE_SERVICES_ID`};
   - `/auth/google`: `aud` ∈ `EVENSIES_GOOGLE_CLIENT_IDS` ∪ {`EVENSIES_GOOGLE_WEB_CLIENT_ID`}.
3. **`UserDto`:** `{"id","displayName","homeCurrency","language": string|null}` in `GET /me` and the `/auth/*` `user`.
4. **`PATCH /me`:** `{"displayName"?, "homeCurrency"?, "language"?: "ko" | null}`.
   - At least one key; `language` must match `^[a-z]{2,3}$`; null clears it (English).
   - A language without strings is stored and rendered as English.
5. **Migration `V11__user_language.sql`:**
   ```sql
   -- Language for server-rendered text (push now, email in Phase 10). NULL = English.
   ALTER TABLE users ADD COLUMN language text CHECK (language ~ '^[a-z]{2,3}$');
   ```
6. **Environment:**

   | Variable | Default | Description |
   |---|---|---|
   | `EVENSIES_APPLE_SERVICES_ID` | | Apple Services ID for web sign-in |
   | `EVENSIES_GOOGLE_WEB_CLIENT_ID` | | Google web OAuth client id |
   | `EVENSIES_CORS_ORIGINS` | (empty) | Development only |
7. **Web routes:** `/` and `/app` → 302 `/app/`; `/app/**` is public and `no-cache`. Every response carries:
   ```
   Content-Security-Policy: default-src 'self'; script-src 'self' 'wasm-unsafe-eval' https://accounts.google.com/gsi/client https://appleid.cdn-apple.com; style-src 'self' 'unsafe-inline' https://accounts.google.com/gsi/style; img-src 'self' data: blob: https://*.googleusercontent.com; font-src 'self' https://fonts.gstatic.com; connect-src 'self' blob: https://fonts.gstatic.com https://accounts.google.com/gsi/; frame-src https://accounts.google.com/gsi/ https://appleid.apple.com; worker-src 'self' blob:; object-src 'none'; base-uri 'self'; frame-ancestors 'none'
   ```
   A violation found in the browser check is fixed in the same commit.
8. **CORS:** only listed origins; methods `GET, POST, PUT, PATCH, DELETE`; headers `Authorization, Content-Type`; max age 3600; no credentials; other preflights → 403.
9. **Money notation `M(x)`** (replaces Phase 2's English-only notation):
   - The number is |minor| split at `decimals[currency]`, grouped by 3 with the language's `group`, plus `decimal` and the fraction.
   - The symbol is the language's `money.symbols[c]`, else `currencies.json` `symbols[c]`, else the ISO code. That covers Phase 4's ~155 codes.
   - The text is `pattern` with `{s}` and `{n}`. If the pattern is `{s}{n}` and `s` ends in a Latin letter, U+00A0 goes between them. Negatives get a leading `-`.

     | Language | Pattern | Group | Decimal | EUR 123456 |
     |---|---|---|---|---|
     | en, ko, ja, th | `{s}{n}` | `,` | `.` | `€1,234.56` |
     | id | `{s}{n}` | `.` | `,` | `€1.234,56` |
     | nl, pt | `{s}␣{n}` | `.` | `,` | `€ 1.234,56` |
     | de, it, es | `{n}␣{s}` | `.` | `,` | `1.234,56 €` |
     | fr | `{n}␣{s}` | U+202F | `,` | `1 234,56 €` |
     | pl, sv | `{n}␣{s}` | U+00A0 | `,` | `1 234,56 €` (sv `SEK` → `kr`) |

     ␣ = U+00A0.
   - `currencies.json` symbol changes (removing symbols that several currencies shared):
     - CAD → `CA$`, AUD → `A$`, SGD → `S$`, HKD → `HK$`, MXN → `MX$`, CLP → `CLP`;
     - CNY → `CN¥`;
     - SEK, NOK, DKK, ISK → their ISO code;
     - KWD, BHD → their ISO code; AED → `AED`;
     - USD `$` and JPY `¥` stay.
10. **Sentences** (both sides, per language):
    - **Variant selection:**
      - The subject is `actorMemberId`, except `member_joined` / `member_left` (`memberId`) and `payment_added` (`fromMember`).
      - `self` if the subject is the viewer.
      - `you` if the kind has one and its object is the viewer. Objects: `member_added`, `member_removed`, `friend_added` → `memberId`; `payment_added` → `toMember`; `payment_confirmed` → `fromMember`; `waiting` → `toMember`.
      - Otherwise `other`.
    - **Placeholders:** remaining viewer placeholders become `words.you`; an unknown member becomes `words.someone`; sentence-initial `words` are capitalized.
    - **Suffixes**, in order: `owe`/`lent`, then `waiting`.
    - **Changes** are joined with `changes.joiner`; booleans use the `On`/`Off` keys.
    - **Fallbacks:** a missing language → `en`; a missing key → the `en` key.
    - English stays byte-identical to the existing goldens, apart from the symbol changes in item 9.
11. **Push and landing pages:** bodies use the recipient's `users.language`. `/j/{code}` gets `<a href="/app/#/join/{CODE}">`; `/f/{code}` gets `<a href="/app/#/friends/add?code={CODE}">` (`landing.openWeb`).
12. **Unchanged:** events, applier rules, snapshot, pull, `sync-cases.json`. Old apps keep English.

### Shared fixtures
**`shared/strings.json`** (new). It is copied to `app/assets/` and `server/src/main/resources/`. The `en` block is the contract and covers every server-rendered string through Phase 8; Phase 10 adds `email` and its kinds.
```json
{
  "_doc": "Text both sides render (activity sentences in the app and in push) plus server-only pages and push. {placeholders} only, no ICU. Every language has every key and variant of \"en\" with the same placeholders. A {name}-like placeholder can hold a member name, words.you or words.someone: don't attach affixes that only fit names (e.g. Korean 님) to placeholders that can hold words.you. Batch sentences must read correctly for every n >= 2.",
  "en": {
    "money": {"pattern": "{s}{n}", "group": ",", "decimal": ".", "symbols": {}},
    "words": {"you": "you", "someone": "someone",
              "frequency": {"weekly": "weekly", "biweekly": "every 2 weeks", "monthly": "monthly", "yearly": "yearly"}},
    "activity": {
      "group_created":      {"other": "{A} created the group “{name}”", "self": "You created the group “{name}”"},
      "group_updated":      {"other": "{A} changed the group: {changes}", "self": "You changed the group: {changes}"},
      "member_added":       {"other": "{A} added {member}", "self": "You added {member}", "you": "{A} added you"},
      "member_joined":      {"other": "{member} joined", "self": "You joined"},
      "member_left":        {"other": "{member} left the group", "self": "You left the group"},
      "member_removed":     {"other": "{A} removed {member}", "self": "You removed {member}", "you": "{A} removed you"},
      "friend_added":       {"other": "{A} added {member} as a friend", "self": "You added {member} as a friend", "you": "{A} added you as a friend"},
      "expense_added":      {"other": "{A} added “{description}” · {amount}", "self": "You added “{description}” · {amount}"},
      "expense_repeated":   {"other": "“{description}” · {amount} was added (repeats {frequency})"},
      "expense_updated":    {"other": "{A} changed “{description}”: {changes}", "self": "You changed “{description}”: {changes}"},
      "expense_deleted":    {"other": "{A} deleted “{description}”", "self": "You deleted “{description}”"},
      "expense_restored":   {"other": "{A} restored “{description}”", "self": "You restored “{description}”"},
      "comment_added":      {"other": "{A} commented on “{description}”: {text}", "self": "You commented on “{description}”: {text}"},
      "receipt_added":      {"other": "{A} added a receipt to “{description}”", "self": "You added a receipt to “{description}”"},
      "receipt_removed":    {"other": "{A} removed a receipt from “{description}”", "self": "You removed a receipt from “{description}”"},
      "recurrence_created": {"other": "{A} set “{description}” to repeat {frequency}", "self": "You set “{description}” to repeat {frequency}"},
      "recurrence_updated": {"other": "{A} changed future “{description}”: {changes}", "self": "You changed future “{description}”: {changes}"},
      "recurrence_deleted": {"other": "{A} stopped “{description}” repeating", "self": "You stopped “{description}” repeating"},
      "payment_added":      {"other": "{from} paid {to} {amount}", "self": "You paid {to} {amount}", "you": "{from} paid you {amount}"},
      "payment_confirmed":  {"other": "{A} confirmed receiving {amount} from {from}", "self": "You confirmed receiving {amount} from {from}", "you": "{A} confirmed receiving {amount} from you"},
      "payment_deleted":    {"other": "{A} deleted a payment of {amount} from {from} to {to}", "self": "You deleted a payment of {amount} from {from} to {to}"}
    },
    "suffix": {"owe": " · you owe {amount}", "lent": " · you lent {amount}",
               "waiting": {"other": " · waiting for {to} to confirm", "you": " · waiting for you to confirm"}},
    "changes": {"joiner": ", ", "name": "name “{from}” → “{to}”", "defaultCurrency": "currency {from} → {to}",
                "simplifyDebtsOn": "simplify debts on", "simplifyDebtsOff": "simplify debts off", "defaultSplit": "default split",
                "description": "description “{from}” → “{to}”", "amount": "{from} → {to}", "currency": "currency {from} → {to}",
                "fxRateToDefault": "exchange rate", "paidBy": "paid by {from} → {to}", "payers": "payers",
                "refundOn": "refund on", "refundOff": "refund off", "date": "date {from} → {to}",
                "category": "category", "shares": "split", "split": "split", "notes": "notes"},
    "batch": {"expenses": "{A} added {n} expenses", "comments": "{A} added {n} comments", "changes": "{A} made {n} changes", "mixed": "{n} new changes"},
    "remind": {"title": "{A} sent a reminder", "body": "You owe {A} {amounts}.", "and": " and ", "more": "{list} and more"},
    "landing": {"title": "Join {group} on Evensies", "invited": "You’re invited to split expenses in this group.", "members": "Members: {count}",
                "friendTitle": "{name} wants to split expenses with you on Evensies",
                "code": "Invite code", "openApp": "Open in the app", "openWeb": "Continue in the browser",
                "hint": "Have the app? Open it, tap “Join with a code” and enter {code}.",
                "appStore": "App Store (coming soon)", "googlePlay": "Google Play (coming soon)"}
  }
}
```
An excerpt of other languages (the real file has every key):
```json
{
  "de": {"money": {"pattern": "{n}\u00a0{s}", "group": ".", "decimal": ",", "symbols": {}},
         "words": {"you": "du", "someone": "jemand"},
         "activity": {"expense_added": {"other": "{A} hat „{description}“ hinzugefügt · {amount}", "self": "Du hast „{description}“ hinzugefügt · {amount}"}},
         "suffix": {"owe": " · du schuldest {amount}", "lent": " · du bekommst {amount} zurück",
                    "waiting": {"other": " · wartet auf Bestätigung von {to}", "you": " · wartet auf deine Bestätigung"}}},
  "ko": {"money": {"pattern": "{s}{n}", "group": ",", "decimal": ".", "symbols": {}},
         "words": {"you": "나", "someone": "알 수 없는 멤버"},
         "activity": {"payment_added": {"other": "{from} → {to} 송금 · {amount}", "self": "{to}에게 송금했어요 · {amount}", "you": "{from}님이 나에게 송금했어요 · {amount}"}},
         "suffix": {"waiting": {"other": " · {to}의 확인을 기다리는 중", "you": " · 내 확인을 기다리는 중"}}},
  "sv": {"money": {"pattern": "{n}\u00a0{s}", "group": "\u00a0", "decimal": ",", "symbols": {"SEK": "kr"}}}
}
```
**`shared/currencies.json`:** the symbol changes in item 9.

**`shared/activity-cases.json`:**
- `money[]` cases gain an optional `"lang"`. Three English goldens change: `CHF\u00a012.50`, `SEK\u00a0999.00`, `KWD\u00a01,234.567`. New cases:
  ```json
  {"minor": 123456, "currency": "EUR", "lang": "de", "text": "1.234,56\u00a0€"},
  {"minor": 123456, "currency": "EUR", "lang": "fr", "text": "1\u202f234,56\u00a0€"},
  {"minor": 99900,  "currency": "SEK", "lang": "sv", "text": "999,00\u00a0kr"},
  {"minor": 1234,   "currency": "CAD",                "text": "CA$12.34"},
  {"minor": 1234,   "currency": "PYG",                "text": "PYG\u00a01,234"}
  ```
- A new `localized[]` section, with goldens that are part of the translation review:
  ```json
  {"name": "de: other actor, symbol after the number, owe suffix", "lang": "de", "me": "m2", "names": {"m1": "Anna", "m2": "Ben"},
   "items": [{"seq": 5, "kind": "expense_added", "createdAt": "2026-10-11T08:05:00Z", "actorMemberId": "m1", "expenseId": "x1",
              "description": "Dinner", "amount": 3000, "currency": "EUR", "myDelta": -1500}],
   "text": "Anna hat „Dinner“ hinzugefügt · 30,00\u00a0€ · du schuldest 15,00\u00a0€"},
  {"name": "ko: viewer is the receiver of a sent payment (you variants)", "lang": "ko", "me": "m2", "names": {"m1": "Anna", "m2": "Ben"},
   "items": [{"seq": 9, "kind": "payment_added", "createdAt": "2026-10-11T08:09:00Z", "actorMemberId": "m1", "paymentId": "p1",
              "fromMember": "m1", "toMember": "m2", "amount": 1200, "currency": "EUR", "status": "sent"}],
   "text": "Anna님이 나에게 송금했어요 · €12.00 · 내 확인을 기다리는 중"}
  ```
  Plus one `localized` case each for `friend_added` (you), `expense_repeated` (ja) and a `remind` body (de).

### Hyojun's part
None (his work is in Phases 3 and 4). Two places degrade:
- **Widget:** if any group's `balancesOf` is null, the payload is `lines: []` with `empty = l.notImplemented`.
- **Single home-currency line:** if `tryCore` returns null for Phase 4 conversion, the per-currency lines show instead.

### Owner-only setup (accounts, free, release-time)
1. **Apple Developer:**
   - Services ID `dev.nariinfo.evensies.web` with Sign in with Apple, grouped under `dev.nariinfo.evensies`, domain `evensies.nariinfo.dev`, return URL `https://evensies.nariinfo.dev/app/`;
   - App Group `group.dev.nariinfo.evensies` on the app and widget App IDs (Xcode automatic signing can do this).
2. **Google Cloud:** JavaScript origins `https://evensies.nariinfo.dev`, `http://localhost:7357` and `http://localhost:8080`.
3. **Korean review.**

Everything else is tested locally: dev login and Google on localhost, and Apple at release.

### Tests
- **Server:**
  - **`WebHostingTest`:**
    - redirects; `/app/` serves HTML without a token;
    - `.wasm` is `application/wasm`;
    - `no-cache`; CSP with `frame-ancestors 'none'` on every response;
    - `GET /groups` without a token is still 401 JSON.
  - **`CorsTest`:** an allowed preflight → 200 with ACAO and no credentials; `https://evil.example` → 403; no property → no ACAO.
  - **`InfoTest` + `AppleGoogleVerifierTest`:** ids are returned when set and null when unset; the Services ID and web client ids are accepted, other `aud` → 401; the same Apple `sub` gives the same user.
  - **`UserLanguageTest`:** set, keep, clear; `"de_AT"`, `"x"`, `"deutsch"`, `"<b>"` and `{}` → 400; the legacy body works; `language` is in the auth `user`.
  - **`StringsTest`:**
    - copy equality;
    - every language has `en`'s keys, variants and placeholders;
    - every currency in `decimals` renders;
    - all of `activity-cases.json` (incl. `localized[]`) passes in Kotlin.
  - **`InviteLandingTest`:** `ko-KR` → Korean with `<html lang="ko">`; `fr-CA` → French; `xx` → English; the browser links for `/j/` and `/f/`; names are still escaped.
  - **Push language:** `ko` and `de` recipients get their own bodies and batch sentences; null → English; the reminder push is localized.
- **App:**
  - the formatter runs `money[]` and `localized[]`;
  - `strings_test.dart`: copy equality, and the languages match `supportedLocales`;
  - `l10n_test.dart`: the same keys and placeholders per ARB file, `@description` in English, all 13 locales load;
  - `hardcoded_strings_test.dart` scans `lib/features/**` and `lib/core/**`:
    - patterns: `Text\(\s*'[^']*[A-Za-z]`, `(labelText|hintText|helperText|tooltip|title|label|subtitle|message|confirmLabel):\s*(const )?'[^']*[A-Za-z]`, `showInfo\(context,\s*'`, `toStringAsFixed\(`;
    - allowlist: `'Evensies'`, the endonym map, the DEV-login block;
  - `locale_layout_test.dart`: 13 locales × login, groups list, group detail (both tabs), expense form (4 members, Shares mode), group settings, settle, friends tab, friend page, insights, search, itemize, settings, at 320×640 with `textScaler` 1.3, with no exception;
  - `money_input_test.dart` (minor units, or null):

    | lang | currency | text | minor |
    |---|---|---|---|
    | en | EUR | `1,234.56` | 123456 |
    | de | EUR | `1.234,56` | 123456 |
    | de | EUR | `12,5` | 1250 |
    | de | EUR | `12.50` | 1250 |
    | de | EUR | `12.345` | 1234500 |
    | en | EUR | `12.345` | null |
    | fr | EUR | `1 234,56` (U+202F) | 123456 |
    | en | KRW | `1,234` | 1234 |
    | ko | KRW | `12.3` | null |
    | en | KWD | `1,234` | 1234000 |
    | de | KWD | `1,234` | 1234 |
    | en | EUR | `1.2.3` | null |
    | de | EUR | `12,` | 1200 |
    | de | EUR | `-10,00` (adjustment) | -1000 |

    Also `parseDecimal('1,0842')` = 1.0842, `parseDecimal('33,33')` = 33.33, and `inputAmount(1250, 'EUR', lang: 'de')` = `12,50`;
  - `widget_summary_test.dart`: sums, sort, cap of 4, the null-balance payload, signed out, goldens in en and de, no write when unchanged, no-op on web;
  - `app_lock_test.dart` (fake authenticator and clock): 59 s / 61 s, a failed auth stays locked, sign-out wipes and turns the lock off, enabling needs a success;
  - `api_refresh_test.dart`: two 401s → one refresh; a changed token → retry; unchanged → sign-out;
  - `router_next_test.dart`;
  - `web_assets_test.dart`;
  - existing widget tests through `app_harness.dart`.
  - **CI:** the `app` job adds `flutter build web --release --base-href /app/ --no-web-resources-cdn --csp`.
- **Manual** (iOS simulator, light and dark):
  - Korean, German, Japanese and Thai via Settings and via the device language; walk login → group → expense → settle → settings; German keyboard `12,50` saves €12.50 and shows `12,50 €`.
  - Widget: small and medium; updates after an expense; dark mode; signed-out text.
  - App lock: Features → Face ID → Enrolled, then Matching / Non-matching; relocks after a minute; the switcher cover.
  - Appearance: System / Light / Dark.
  - Web:
    - `flutter run -d chrome --web-port 7357` against `bootRun` with the dev profile: CORS and Google sign-in on localhost;
    - build the image locally (`docker compose -f deploy/docker-compose.yml build server`) and open `http://localhost:8080/app/` in Chrome and Safari: dev login; survives a reload; an expense added in DevTools offline syncs; a second tab sees it within 60 s; CSV export downloads and import works; the PayPal link opens a tab; the EPC QR renders; landing → Continue in the browser → join; an avatar upload from a JPEG; drift reports `sharedIndexedDb`; no CSP violations.
  - Android: `flutter build apk --debug` compiles the widget and `FlutterFragmentActivity`.

### Done when
- `./gradlew test`, `flutter analyze` and `flutter test` are green, and CI builds web.
- The locally built image serves `/app/` same-origin and passes every web check in Chrome and Safari.
- All 13 languages are complete per the tests, and switching language updates every screen without a restart. Hyojun has reviewed Korean.
- Push, reminder and landing-page language tests pass.
- `12,50` saves €12.50, and the feed, push, widget and UI show the same notation.
- Widget, appearance and lock work on the simulator, and Android compiles.
- Docs are updated:
  - `docs/API.md` (the items above);
  - `README.md` (Languages table, "Translating", web self-hosting);
  - `app/README.md` (web dev commands);
  - `docs/privacy.md` (browser storage, Google Fonts on web, the widget's on-device balance copy).

### Dependencies and deliberate omissions
- **Depends on:**
  - Phase 2's renderer (refactored onto `strings.json`, English unchanged except symbols) and its fan-out (grouped by language);
  - Phases 3 and 4 through `tryCore`;
  - Phase 5 category labels in ARB by key;
  - Phase 6 overview for the widget, `/f/`, and API-origin images;
  - Phase 7 (Scan hidden on web);
  - Phase 8 kinds and frequency words.
- **Phase 10** adds `email.*` to `strings.json` in all languages, plus `group_deleted` / `group_restored` and the `type`/`coverImageId` change labels.
- **Left out:**
  - **Web:** web push (focus sync and a 60 s poll cover it); a service-worker offline shell; `--wasm`; desktop layout and desktop apps; self-hosted fonts (~20 MB).
  - **Languages:** RTL and Chinese; regional variants; localized currency names; Android `localeConfig`; a localized `NSFaceIDUsageDescription`.
  - **Widget:** background refresh; lock-screen and StandBy families.
  - **App lock:** a separate passcode.

**Roadmap table, row 9, becomes:**

| # | Phase | User-visible result | Server | App | Cost |
|---|---|---|---|---|---|
| 9 | **Platforms & language** | Web app at `/app/`; 13 languages with local money and date formats; localized push, reminders and landing pages; home-screen widget; appearance toggle; app lock | Web build inside the server image, CSP, CORS (dev only), `GET /info`, `users.language`, `shared/strings.json` | Flutter web + drift wasm, ARB i18n, shared sentence templates, `home_widget`, `local_auth` | 0 |

---
