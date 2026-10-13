# Contributing to Evensies

Thanks for helping. Evensies is a Flutter app (`app/`) and a Spring Boot server in Kotlin (`server/`) that implement the same money and sync rules, checked by shared JSON test cases (`shared/`). This guide covers the setup, the tests and the few rules that keep the two sides in agreement.

- [Ways to help](#ways-to-help)
- [Development setup](#development-setup)
- [Running the tests](#running-the-tests)
- [Keeping the app and the server in sync](#keeping-the-app-and-the-server-in-sync)
- [Translations](#translations)
- [Code style](#code-style)
- [Commit messages](#commit-messages)
- [Pull requests](#pull-requests)
- [Licensing of contributions](#licensing-of-contributions)

## Ways to help

- **Report a bug.** Open an issue with the [bug report form](https://github.com/devyourown/evensies/issues/new?template=bug_report.yml): what you did, what you expected, what happened, and the platform and version.
- **Review a translation.** This is the easiest place to start. All 12 languages other than English were machine-translated and nobody has reviewed them yet. See [Translations](#translations).
- **Write code.** Issues labelled [good first issue](https://github.com/devyourown/evensies/labels/good%20first%20issue) (when there are some) are small and self-contained; [help wanted](https://github.com/devyourown/evensies/labels/help%20wanted) ones are bigger. For anything that changes behaviour, open an issue first so we can agree on the approach before you write it.
- **Ask a question** in a [blank issue](https://github.com/devyourown/evensies/issues/new).

Security problems: please don't open a public issue, see [SECURITY.md](SECURITY.md).

## Development setup

### Prerequisites

| Tool | Version | Needed for |
|---|---|---|
| Flutter | 3.41.4 stable (Dart 3.11.1), the version CI pins | the app |
| JDK | 21 | the server (the build needs a JDK 21 toolchain; Gradle itself runs on 17+ and downloads JDK 21 if it finds none) |
| Docker with Compose v2 | any recent | Postgres and Mailpit for development, Testcontainers for the server tests |
| Xcode and CocoaPods | Xcode 26.3 with an iOS 18.1 simulator, CocoaPods 1.16.2 | iOS only (macOS) |
| Android SDK | through Android Studio | Android emulator and APK builds only |
| Chrome | any recent | the web app only (optional) |

These versions were checked on macOS 26 on Apple Silicon. On Linux everything except iOS works; CI runs the app and server tests on Ubuntu.

No Firebase files are needed: without `GoogleService-Info.plist` and `google-services.json` the app runs and push notifications are simply off. Sign-in during development uses the dev login, so you don't need Apple or Google credentials either.

Point `JAVA_HOME` at JDK 21 in every terminal that runs Gradle:

```sh
export JAVA_HOME=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home   # macOS, Homebrew openjdk@21
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64                              # Debian/Ubuntu, openjdk-21-jdk
```

### 1. Database and mail

```sh
git clone https://github.com/devyourown/evensies.git && cd evensies
docker compose -f deploy/docker-compose.dev.yml up -d
```

This starts Postgres 16 on `localhost:5432` (user, password and database `evensies`) and Mailpit, a fake mail server (SMTP on `localhost:1025`, inbox at http://localhost:8025, where email sign-in codes arrive).

If port 5432 is taken (a Homebrew Postgres, say), change the mapping in `deploy/docker-compose.dev.yml` to `"5433:5432"` and start the server below with `EVENSIES_DB_URL=jdbc:postgresql://localhost:5433/evensies`.

### 2. Server

```sh
cd server
./gradlew --no-daemon bootRun --args='--spring.profiles.active=dev'
```

The `dev` profile (`server/src/main/resources/application-dev.yml`) turns on `POST /auth/dev` (sign in with just a name), uses a fixed JWT secret, allows CORS from `http://localhost:7357` for the web app and sends email to Mailpit. Never use it in production. `SPRING_PROFILES_ACTIVE=dev` works too, and `EVENSIES_DB_URL=jdbc:postgresql://localhost:5432/<db>` points the server at another database.

Check it from another terminal:

```sh
curl -s localhost:8080/info      # ... "devLogin":true ...
```

### 3. App on a simulator or emulator

In a new terminal:

```sh
cd app
flutter pub get
flutter devices                  # find the simulator or emulator id (on macOS, `open -a Simulator` boots one)
flutter run -d <device-id> --dart-define=DEV_LOGIN=true --dart-define=EVENSIES_SERVER_URL=http://localhost:8080
```

On the login screen, type a name under "Dev name" and tap "Dev login". Then try Create group, + Expense, an amount and a description, and Save. To see sync between two people, sign in with a second name in another simulator or in the web app: open the group's Members & invite screen on the first one and copy the code, then use Join with a code as the second person (in the new-group menu, or the + next to Groups in the wide web layout).

The Android emulator reaches your computer at `10.0.2.2`, so use `--dart-define=EVENSIES_SERVER_URL=http://10.0.2.2:8080` there. Debug builds on phones also have a Settings → Server field.

### 4. Web app

```sh
cd app
flutter run -d chrome --web-port 7357 --dart-define=DEV_LOGIN=true --dart-define=EVENSIES_SERVER_URL=http://localhost:8080
```

The port must be 7357, the only origin the dev profile allows. Without Chrome, use `-d web-server --web-port 7357` and open http://localhost:7357.

### Build variables

| `--dart-define` | Default | Effect |
|---|---|---|
| `EVENSIES_SERVER_URL` | the official server (web: the origin it was served from) | the server the app talks to |
| `DEV_LOGIN` | `false` | shows the dev login (the server needs the dev profile too) |
| `EVENSIES_ALLOW_CUSTOM_SERVER` | `false` | keeps the Settings → Server field in release builds |
| `EVENSIES_GOOGLE_SERVER_CLIENT_ID` | the official server's Google web client id | for Google sign-in against another server |

Details: [docs/API.md](docs/API.md#build-variables-app---dart-define) and [app/README.md](app/README.md).

## Running the tests

These are the checks CI runs ([`.github/workflows/ci.yml`](.github/workflows/ci.yml)); run the ones for the side you changed before opening a pull request.

**App** (from `app/`; the tests read `../shared/*.json`, so run them from there):

```sh
dart run build_runner build                                # regenerates lib/data/db/database.g.dart (committed)
flutter analyze
flutter test                                               # or one file: flutter test test/l10n_test.dart
flutter build web --release --base-href /app/ --no-web-resources-cdn --csp
```

`flutter build apk --debug` and `flutter build ios --simulator --debug` also work without Firebase files.

**Server** (from `server/`, with Docker running):

```sh
./gradlew --no-daemon test                         # Testcontainers starts postgres:16-alpine and axllent/mailpit
./gradlew --no-daemon test --tests '*SplitTest'    # one class
```

The first run pulls the Postgres image (about 270 MB) and Mailpit (about 35 MB).

**Shared JSON** (from the repository root):

```sh
(for f in shared/*.json; do python3 -m json.tool "$f" > /dev/null || { echo "invalid $f"; exit 1; }; echo "ok $f"; done)
```

CI also runs a [gitleaks](https://github.com/gitleaks/gitleaks) scan over the whole history. Never commit secrets: `deploy/.env`, Firebase files, signing keys and keystores are git-ignored, so keep them that way.

## Keeping the app and the server in sync

The app (Dart) and the server (Kotlin) each implement splitting, balances, currency conversion, the event applier and the activity sentences. They must agree to the last minor unit, so:

1. **The contract comes first.** [docs/API.md](docs/API.md) describes every endpoint, event, applier rule and money rule. To change behaviour, change API.md first, in the same pull request.
2. **Then the shared test cases.** Add or update cases in `shared/*.json`: for example `split-cases.json`, `settlement-cases.json`, `fx-cases.json`, `sync-cases.json` and `activity-cases.json`. Both test suites load these files, so a case you add is checked on both sides.
3. **Then the code**, in Dart (`app/lib/domain/`, `app/lib/data/sync/apply_event.dart`) and in Kotlin (`server/src/main/kotlin/dev/nariinfo/evensies/money/`, `sync/EventApplier.kt`), until both suites pass.

The rules that make agreement possible:

- **Money is an integer** in the currency's minor unit (cents for EUR, whole won for KRW), always paired with a currency code. The number of decimals comes from `shared/currencies.json`. No floating-point money: a double appears only where a person types a ratio (a percentage, a share count, an exchange rate), and the code switches to integer arithmetic before it computes any amount. The one exception is the itemize screen's % helper (`percentOf`), which rounds one double product to a whole minor unit before it is stored.
- **Results are deterministic.** The same input gives the same output on every device and on the server: leftover minor units go to members in memberId order, ties are broken by memberId, and nothing depends on map order, the clock or the locale.
- **Store final amounts, not rules.** An expense stores the final share of each member. The server checks the sums and never recomputes a split.
- **The applier is pure.** `applyEvent(state, event)` changes nothing else, and applying an event twice gives the same state as applying it once.
- **Shared tables are copied byte for byte.** `shared/currencies.json`, `categories.json` and `strings.json` have copies in `app/assets/` and `server/src/main/resources/`. After editing one, copy it to both places (`cp shared/strings.json app/assets/ && cp shared/strings.json server/src/main/resources/`); the tests compare the copies (all but the app's `currencies.json`, for now).
- **Schema changes are new files.** A server change is a new Flyway migration `server/src/main/resources/db/migration/V<next>__<name>.sql`; never edit one that exists, not even a comment: Flyway checksums the whole file, so the Korean section names in some older migrations' comments stay as they are. An app change bumps `schemaVersion` in `app/lib/data/db/database.dart`, adds an `onUpgrade` step and regenerates `database.g.dart`.
- **Old clients keep working.** New payload keys are optional and have a default that matches older events; API.md records the compatibility notes for each change.

[ARCHITECTURE.md](ARCHITECTURE.md) explains why these rules exist.

## Translations

English is the source and the fallback. The other 12 languages were machine-translated and need native speakers:

| Language | Code | Status |
|---|---|---|
| English | `en` | source |
| Dutch | `nl` | machine-translated, reviews welcome |
| French | `fr` | machine-translated, reviews welcome |
| German | `de` | machine-translated, reviews welcome |
| Indonesian | `id` | machine-translated, reviews welcome |
| Italian | `it` | machine-translated, reviews welcome |
| Japanese | `ja` | machine-translated, reviews welcome |
| Korean | `ko` | machine-translated, maintainer review pending |
| Polish | `pl` | machine-translated, reviews welcome |
| Portuguese (Brazil) | `pt` | machine-translated, reviews welcome |
| Spanish | `es` | machine-translated, reviews welcome |
| Swedish | `sv` | machine-translated, reviews welcome |
| Thai | `th` | machine-translated, reviews welcome |

To review or fix a language, open a [translation issue](https://github.com/devyourown/evensies/issues/new?template=translation.yml) or send a pull request. You don't need to build the app to fix wording.

Text lives in two places:

- **App screens:** `app/lib/l10n/app_<code>.arb`. `app_en.arb` is the source, and each key's `@description` says where the text appears. After editing, run `flutter gen-l10n` in `app/` and commit the generated `app_localizations*.dart` files. (It prints a note about `l10n.yaml`; that is expected, keep the file.)
- **Sentences the server writes too** (activity feed, push notifications, reminders, emails, invite pages, category names, repeat wording, the money format): the `<code>` block of `shared/strings.json`. Copy the file byte for byte to `app/assets/strings.json` and `server/src/main/resources/strings.json`. Its `_doc` key explains the format.

Rules:

- Translate whole sentences and keep every `{placeholder}`.
- Plurals only in ARB, with ICU `one`/`other` (plus `few`/`many` for Polish). `shared/strings.json` has no plurals, so its `{n}` sentences must read correctly for every n of 2 or more.
- Placeholders such as `{A}`, `{member}`, `{from}` and `{to}` can hold a name, "you" or "someone", so word the sentence around them without gender and without endings that only fit names.
- Register: informal for de, es, it, nl, pl, pt and sv; formal for fr (vous), ja (です/ます) and ko (haeyo-che, the polite -yo style).
- Keep as they are: names, descriptions, brand and payment-service names, currency codes and currency names.
- Use the language's own quotation marks („…“, 「…」, « … »).
- Some German, Italian, Japanese and Korean sentences are pinned in the `localized` cases of `shared/activity-cases.json`. If you change one of them, update the expected text there too.

Check your change:

```sh
(cd app && flutter gen-l10n && flutter test test/l10n_test.dart test/activity_text_test.dart test/hardcoded_strings_test.dart)
(cd server && ./gradlew --no-daemon test --tests '*StringsTest' --tests '*ActivityCasesTest')
```

These check that every language has every key, variant and placeholder, that the copies are byte-equal, and that no English text is hard-coded in widgets. Adding a new language touches more files (the endonym table in `app/lib/core/l10n.dart`, `CFBundleLocalizations` in `app/ios/Runner/Info.plist`, both test suites); please open an issue first.

## Code style

CI checks the app with `flutter analyze` (the `flutter_lints` rules in `app/analysis_options.yaml`) and fails on any issue. The server has no linter; the Kotlin compiler with `-Xjsr305=strict` is the check. There is no formatter run in CI, and the existing code is not formatted with `dart format`, so:

- Don't reformat lines you didn't change; a pull request should show only your change.
- Follow the file you are in: two-space indentation in Dart, four spaces in Kotlin, and lines of a similar length to their neighbours (most are under 120 characters).
- Write comments and doc comments in English. Explain why, and point to the API.md section a rule comes from.
- A deliberate shortcut with a known limit gets a `ponytail:` comment that names the limit and the way out, like the ones already in the code.
- UI text goes through the ARB files (`context.l`), never a string literal in a widget; `test/hardcoded_strings_test.dart` catches literals.
- Money stays in integers end to end; format with `formatMoney` and parse with `parseMoney` (`app/lib/core/money.dart`).

## Commit messages

English, in the imperative mood, with a short summary line (about 72 characters) and, when it helps, a body that explains why. Most of the history uses a type prefix (`feat:`, `fix:`, `docs:`, `test:`, `chore:`), which is welcome but not required:

```
fix: keep the payer when an expense's amount changes
```

## Pull requests

- Keep them small and focused: one fix or one feature. Large changes are easier to land as a series.
- CI must be green: the app job (build_runner, analyze, tests, web build), the server tests, the shared JSON check and the secrets scan.
- When behaviour changes, update docs/API.md and the shared test cases in the same pull request.
- Add screenshots for UI changes, ideally in light and dark mode.
- Fill in the pull request template. The maintainer (@devyourown, through [CODEOWNERS](.github/CODEOWNERS)) reviews every pull request.

## Licensing of contributions

Evensies is licensed under the [Apache License 2.0](LICENSE). As section 5 of the license says, any contribution you submit for inclusion is licensed under the same terms, unless you say otherwise. There is no contributor license agreement to sign. Please contribute only work you have the right to license this way.

The name and icon are covered by [TRADEMARKS.md](TRADEMARKS.md), not by the license.

## Code of Conduct

Everyone taking part is expected to follow the [Code of Conduct](CODE_OF_CONDUCT.md).
