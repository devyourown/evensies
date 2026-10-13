# Evensies app (Flutter)

Offline-first expense splitting client for the Evensies server, for iOS, Android and the web. Contract: `../docs/API.md`; how it fits together: `../ARCHITECTURE.md`; setup from scratch: `../CONTRIBUTING.md`.

## Run (simulator or emulator, local server, dev login)

```sh
flutter run -d <device-id> \
  --dart-define=DEV_LOGIN=true \
  --dart-define=EVENSIES_SERVER_URL=http://localhost:8080
```

| dart-define | default | effect |
|---|---|---|
| `EVENSIES_SERVER_URL` | `https://evensies.nariinfo.dev` (web: its own origin) | server base URL (Android emulator: `http://10.0.2.2:8080`); applies in every build mode |
| `EVENSIES_ALLOW_CUSTOM_SERVER` | `false` | `true` keeps the Settings → Server field and the stored URL in a release build; debug builds always have them, the web never |
| `DEV_LOGIN` | `false` | shows a "Dev login" button that calls `POST /auth/dev {name}` |
| `EVENSIES_GOOGLE_SERVER_CLIENT_ID` | the official server's Google web client id | `google_sign_in`'s `serverClientId`; must be in the server's `EVENSIES_GOOGLE_CLIENT_IDS` |

Store builds pass none of these. A release build without them always talks to the official server (`Env.allowCustomServer`).
To build an app for another server, give it its own name, icon and bundle id (`../TRADEMARKS.md`) and follow the
[build variables](../docs/API.md#build-variables-app---dart-define) section of `../docs/API.md`.

Without `ios/Runner/GoogleService-Info.plist` and `android/app/google-services.json` (git-ignored) the app runs and
logs "Firebase not configured, push disabled".

## Web (`/app/` on the server, same origin)

```sh
flutter run -d chrome --web-port 7357 --dart-define=EVENSIES_SERVER_URL=http://localhost:8080   # against bootRun (dev profile)
flutter build web --release --base-href /app/ --no-web-resources-cdn --csp                       # what CI and the image build
```

Without `EVENSIES_SERVER_URL` the web app talks to the origin it was served from; the login screen asks `GET /info`
which buttons to show. `web/` carries drift's worker and sqlite3's wasm named by version
(`drift_worker-<drift>.js`, `sqlite3-<sqlite3>.wasm`): after a `pub upgrade` that moves either, replace both files and
the names in `lib/data/db/database.dart` (`test/web_assets_test.dart` fails until then).

## Languages

UI text lives in `lib/l10n/app_<lang>.arb` (English `app_en.arb` is the source, with a `@description` per key); run
`flutter gen-l10n` after editing and commit the generated `app_localizations*.dart`. Activity sentences, category
names, frequency words and the money notation come from `assets/strings.json`, a byte-equal copy of
`../shared/strings.json`. `test/l10n_test.dart` checks keys and placeholders, `test/hardcoded_strings_test.dart`
fails on new English literals in widgets. The translation rules are in `../CONTRIBUTING.md`.

## Tests

```sh
flutter analyze
flutter test                                               # all suites, including test/domain (split, settlement, fx, event applier)
dart run build_runner build                                # after changing lib/data/db/database.dart
```

Tests read `../shared/*.json` relative to this `app/` directory, so run them from here.

## Core logic

The domain logic lives in small, pure files, each checked against the JSON cases shared with the server:

| file | what | cases |
|---|---|---|
| `lib/domain/split.dart` | equal / exact / percent / shares / adjustment split, remainder by memberId ascending | `shared/split-cases.json` |
| `lib/domain/settlement.dart` | balances (several payers, refunds, payments), greedy debt simplification, pairwise debts | `shared/settlement-cases.json` |
| `lib/domain/fx.dart` | exact currency conversion of amounts and expenses (largest remainder) | `shared/fx-cases.json` |
| `lib/domain/balances.dart` | balances per currency bucket, conversion into the group currency | `shared/settlement-cases.json`, `shared/overview-cases.json` |
| `lib/domain/itemized.dart` | itemized split from receipt lines (app only) | `test/fixtures/itemized-cases.json` |
| `lib/data/sync/apply_event.dart` | event applier (API.md applier rules) | `shared/sync-cases.json` |

## Layout

```
lib/core/        env.dart money.dart ids.dart snack.dart l10n.dart strings.dart appearance.dart …
lib/l10n/        app_<lang>.arb (+ generated app_localizations*.dart)
lib/data/db/     database.dart (+ .g.dart)      drift tables
lib/data/api/    api_client.dart dto.dart        every endpoint in API.md, 401 → refresh once → retry
lib/data/sync/   sync_service.dart               push outbox → pull after lastSeq → applyEvent → save
                 group_state_store.dart          GroupState ⇄ drift
lib/data/local_writes.dart                       every local change = drift rows + outbox event
lib/domain/      models.dart split.dart settlement.dart fx.dart balances.dart overview.dart activity.dart …
lib/features/    auth groups group_detail expense_form settle members settings lock home_widget …
```

## Release builds

Version bump, `flutter clean`, the iOS archive and upload, the Android app bundle and the first-release platform
setup (Apple capabilities, Google sign-in, Firebase, Universal Links and App Links) are in `../docs/RELEASING.md`.
The custom scheme `evensies://j/<code>` and `evensies://f/<code>` works on both platforms without any setup.
