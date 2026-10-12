# Evensies server

Spring Boot 4.1 / Kotlin 2.3 / PostgreSQL 16 / Flyway. The API and sync contract is `../docs/API.md`; this code follows it.

## Run tests

```sh
export JAVA_HOME=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home
./gradlew --no-daemon test                   # needs Docker (Testcontainers postgres:16-alpine)
```

Tests load the fixtures shared with the app from `../shared/*.json`, so run Gradle from this directory.

## Run locally

```sh
docker run -d --name evensies-pg -e POSTGRES_USER=evensies -e POSTGRES_PASSWORD=evensies -e POSTGRES_DB=evensies -p 5432:5432 postgres:16-alpine
./gradlew --no-daemon bootRun --args='--spring.profiles.active=dev'
```

The `dev` profile (`application-dev.yml`) enables `POST /auth/dev` and uses a fixed JWT secret. Smoke test:

```sh
TOKEN=$(curl -s -X POST localhost:8080/auth/dev -H 'Content-Type: application/json' -d '{"name":"Anna"}' | python3 -c 'import sys,json;print(json.load(sys.stdin)["accessToken"])')
curl -s -X POST localhost:8080/groups -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"id":"<uuid>","name":"Rome trip","defaultCurrency":"EUR","memberId":"<uuid>","memberName":"Anna"}'
curl -s localhost:8080/groups/<groupId>/snapshot -H "Authorization: Bearer $TOKEN"
```

## Environment variables

| Variable | Default | Notes |
|---|---|---|
| `EVENSIES_DB_URL` | `jdbc:postgresql://localhost:5432/evensies` | |
| `EVENSIES_DB_USER` / `EVENSIES_DB_PASSWORD` | `evensies` / `evensies` | |
| `EVENSIES_JWT_SECRET` | (required, >= 32 chars; the dev profile has one) | HS256 secret for access tokens |
| `EVENSIES_AUTH_DEV_LOGIN` | `false` | `true` enables `POST /auth/dev` |
| `EVENSIES_APPLE_CLIENT_ID` | | audience for Apple id tokens (`/auth/apple` answers `AUTH_NOT_CONFIGURED` when empty) |
| `EVENSIES_APPLE_SERVICES_ID` | | web sign-in Services ID: also an accepted Apple audience, shown by `GET /info` |
| `EVENSIES_GOOGLE_CLIENT_IDS` | | comma separated audiences for Google id tokens |
| `EVENSIES_GOOGLE_WEB_CLIENT_ID` | | Google web client id: also an accepted audience, shown by `GET /info` |
| `EVENSIES_CORS_ORIGINS` | (empty; `dev` profile `http://localhost:7357`) | development only: exact origins for `flutter run -d chrome` |
| `EVENSIES_FCM_CREDENTIALS_FILE` | | Firebase service-account JSON; empty = push disabled (logged at startup) |
| `EVENSIES_PUBLIC_URL` | `http://localhost:8080` | used in the `/j/{code}` invite page |
| `EVENSIES_FX_URL` | `https://api.frankfurter.dev/v2` | exchange-rate source for `GET /fx` (Frankfurter v2 shape, no key); empty = automatic rates off |

`/actuator/health`, `GET /info` and the web app are public.

## Web app

`deploy/Dockerfile` builds the Flutter web app and puts it in `src/main/resources/static/app/` (gitignored), so the
image serves it at `/app/` (`/` and `/app` redirect there). Locally, `bootRun` with the dev profile plus
`flutter run -d chrome --web-port 7357 --dart-define=EVENSIES_SERVER_URL=http://localhost:8080` in `app/` works through
CORS. Every response carries the CSP in `SecurityConfig.CSP`.

## Layout

```
config/   AppProperties, JwtService, SecurityConfig (stateless bearer filter, CSP, dev CORS), WebConfig (/app/)
auth/     dev/apple/google/refresh login, /me, /devices, IdTokenVerifier (JWKS, RS256)
group/    groups, members, invites (/invites/{code}, /j/{code} HTML page in the Accept-Language language)
sync/     events push/pull/snapshot, EventApplier (pure, mirrors the Dart one), EventValidator, GroupStateStore
money/    Money (currency decimals), Split, Settlement, Fx (conversion, Hyojun's port pending)
fx/       GET /fx: daily EUR rates from EVENSIES_FX_URL, cached per day in fx_days
payment/  "ways to get paid": GET/PUT /me/payment-methods, GET /groups/{id}/payment-methods (validation incl. IBAN mod-97)
export/   JSON/CSV export, Splitwise CSV import (goes through the normal push path)
push/     FcmNotifier (no-op without credentials)
common/   ApiException → {"code","message"}, RateLimiter (120 events/min/user), Strings (resources/strings.json: per-language
          text for push, reminders and landing pages; a copy of shared/strings.json)
```

Splitwise import: each name column is that person's net for the row; the largest net is the payer, everyone else
owes `-net`. Unknown names become placeholder members. Rows with multiple payers are rejected with `IMPORT_FAILED`.

## Core logic

| Where | What |
|---|---|
| `money/Split.kt` | equal/exact/percent split, remainder by memberId ascending (`shared/split-cases.json`) |
| `money/Settlement.kt` | balances and greedy debt simplification (`shared/settlement-cases.json`) |
| `sync/EventApplier.kt` | applies events to the in-memory state (`shared/sync-cases.json`) |
| `sync/EventValidator.kt` | batch validation; `payment.created` `sent` → `confirmed` when the receiver is a placeholder or the sender; who may confirm/delete payments |
| `sync/EventService.push` | the sync transaction: `FOR UPDATE` lock, clientId dedupe, gap-free seq, apply, `latest_seq` |
