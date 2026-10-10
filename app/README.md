# Tally app (Flutter)

Offline-first expense splitting client for the Tally server. Contract: `../docs/API.md`.

## Run (iOS simulator, local server, dev login)

```sh
/Users/hyojun/flutter/bin/flutter run -d <simulator-id> \
  --dart-define=DEV_LOGIN=true \
  --dart-define=NAIVE_APPLY=true \
  --dart-define=TALLY_SERVER_URL=http://localhost:8080
```

| dart-define | default | effect |
|---|---|---|
| `TALLY_SERVER_URL` | `http://localhost:8080` | server base URL (overridable at runtime in Settings; Android emulator: `http://10.0.2.2:8080`) |
| `DEV_LOGIN` | `false` | shows a "Dev login" button that calls `POST /auth/dev {name}` |
| `NAIVE_APPLY` | `false` | uses `lib/data/sync/apply_event_naive.dart` (and `naiveSplit`) instead of the TODO(효준) functions so the app works end-to-end before they are written. Dev only. |

## Tests

```sh
flutter test --exclude-tags hyojun   # what CI runs: must be green
flutter test test/hyojun             # the three TODO(효준) suites; red until the assertions are written
dart run build_runner build --delete-conflicting-outputs   # after changing lib/data/db/database.dart
```

Tests read `../shared/*.json` relative to this `app/` directory, so run them from here.

## TODO(효준) — the only places you write

| # | file:line | what |
|---|---|---|
| 1 | `lib/domain/split.dart:28` | `computeSplit` body (equal / exact / percent, remainder by memberId ascending) |
| 2 | `lib/domain/settlement.dart:40` and `:52` | `computeBalances`, `simplifyDebts` bodies |
| 3 | `lib/data/sync/apply_event.dart:25` | `applyEvent` body (API.md apply rules 1–5) |
| 4 | `test/hyojun/split_test.dart`, `test/hyojun/settlement_test.dart`, `test/hyojun/apply_event_test.dart` | replace every `fail('TODO(효준)')` with the `expect` in the comment above it |

When `apply_event_test.dart` passes, delete `lib/data/sync/apply_event_naive.dart`, `test/apply_event_naive_test.dart`, and the `Env.naiveApply` branches in `sync_service.dart` / `expense_form_screen.dart`.

Until then the UI shows a "정산 로직 미구현 / not implemented" chip wherever one of those functions is needed (`lib/core/core_guard.dart`).

## Layout

```
lib/core/        env.dart money.dart ids.dart core_guard.dart snack.dart
lib/data/db/     database.dart (+ .g.dart)      drift tables
lib/data/api/    api_client.dart dto.dart        every endpoint in API.md, 401 → refresh once → retry
lib/data/sync/   sync_service.dart               push outbox → pull after lastSeq → applyEvent → save
                 group_state_store.dart          GroupState ⇄ drift
                 apply_event.dart                TODO(효준)   apply_event_naive.dart  dev stand-in
lib/data/local_writes.dart                       every local change = drift rows + outbox event
lib/domain/      models.dart split.dart settlement.dart
lib/features/    auth groups group_detail expense_form settle members settings
```

## Platform setup still needed (before TestFlight / Play)

- **Bundle id / application id**: currently `dev.nariinfo.tally` (ios `PRODUCT_BUNDLE_IDENTIFIER`, android `applicationId`).
- **Sign in with Apple**: enable the capability on the App ID and in Xcode (Runner → Signing & Capabilities). Server env `TALLY_APPLE_CLIENT_ID` = bundle id.
- **Google Sign-In**: create iOS + Android OAuth clients; add the iOS client's reversed id as a URL scheme in `Info.plist` (`GIDClientID` key too); server env `TALLY_GOOGLE_CLIENT_IDS`.
- **Firebase (push)**: add `ios/Runner/GoogleService-Info.plist` and `android/app/google-services.json` (+ the google-services Gradle plugin). Without them the app runs and just logs "Firebase not configured, push disabled".
- **Deep links**: iOS Associated Domains `applinks:<host>` + `/.well-known/apple-app-site-association` on the server; Android replace `YOUR_HOST` in `AndroidManifest.xml` + `/.well-known/assetlinks.json`. The custom scheme `tally://j/<code>` already works on both.
- **Release networking**: `NSAllowsLocalNetworking` (iOS) and `usesCleartextTraffic` (Android) are for `http://localhost`; drop them if the production server is HTTPS-only.
