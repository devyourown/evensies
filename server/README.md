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
| `EVENSIES_GOOGLE_CLIENT_IDS` | | comma separated audiences for Google id tokens |
| `EVENSIES_FCM_CREDENTIALS_FILE` | | Firebase service-account JSON; empty = push disabled (logged at startup) |
| `EVENSIES_PUBLIC_URL` | `http://localhost:8080` | used in the `/j/{code}` invite page |

`/actuator/health` is public.

## Layout

```
config/   AppProperties, JwtService, SecurityConfig (stateless bearer filter)
auth/     dev/apple/google/refresh login, /me, /devices, IdTokenVerifier (JWKS, RS256)
group/    groups, members, invites (/invites/{code}, /j/{code} HTML page)
sync/     events push/pull/snapshot, EventApplier (pure, mirrors the Dart one), EventValidator, GroupStateStore
money/    Money (currency decimals), Split, Settlement
payment/  "ways to get paid": GET/PUT /me/payment-methods, GET /groups/{id}/payment-methods (validation incl. IBAN mod-97)
export/   JSON/CSV export, Splitwise CSV import (goes through the normal push path)
push/     FcmNotifier (no-op without credentials)
common/   ApiException → {"code","message"}, RateLimiter (120 events/min/user)
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
