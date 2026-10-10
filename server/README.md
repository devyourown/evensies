# Tally server

Spring Boot 4.1 / Kotlin 2.3 / PostgreSQL 16 / Flyway. The API and sync contract is `../docs/API.md`; this code follows it.

## Run tests

```sh
export JAVA_HOME=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home
./gradlew --no-daemon test                   # needs Docker (Testcontainers postgres:16-alpine)
./gradlew --no-daemon test -PincludeHyojun   # also runs the tests tagged "hyojun" (see below)
```

Tests load the fixtures shared with the app from `../shared/*.json`, so run Gradle from this directory.

## Run locally

```sh
docker run -d --name tally-pg -e POSTGRES_USER=tally -e POSTGRES_PASSWORD=tally -e POSTGRES_DB=tally -p 5432:5432 postgres:16-alpine
./gradlew --no-daemon bootRun --args='--spring.profiles.active=dev'
```

The `dev` profile (`application-dev.yml`) enables `POST /auth/dev`, uses a fixed JWT secret and routes push through the
temporary `pushNaive` (`tally.sync.naive=true`). Smoke test:

```sh
TOKEN=$(curl -s -X POST localhost:8080/auth/dev -H 'Content-Type: application/json' -d '{"name":"Anna"}' | python3 -c 'import sys,json;print(json.load(sys.stdin)["accessToken"])')
curl -s -X POST localhost:8080/groups -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"id":"<uuid>","name":"Rome trip","defaultCurrency":"EUR","memberId":"<uuid>","memberName":"Anna"}'
curl -s localhost:8080/groups/<groupId>/snapshot -H "Authorization: Bearer $TOKEN"
```

## Environment variables

| Variable | Default | Notes |
|---|---|---|
| `TALLY_DB_URL` | `jdbc:postgresql://localhost:5432/tally` | |
| `TALLY_DB_USER` / `TALLY_DB_PASSWORD` | `tally` / `tally` | |
| `TALLY_JWT_SECRET` | (required, >= 32 chars; the dev profile has one) | HS256 secret for access tokens |
| `TALLY_AUTH_DEV_LOGIN` | `false` | `true` enables `POST /auth/dev` |
| `TALLY_APPLE_CLIENT_ID` | | audience for Apple id tokens (`/auth/apple` answers `AUTH_NOT_CONFIGURED` when empty) |
| `TALLY_GOOGLE_CLIENT_IDS` | | comma separated audiences for Google id tokens |
| `TALLY_FCM_CREDENTIALS_FILE` | | Firebase service-account JSON; empty = push disabled (logged at startup) |
| `TALLY_PUBLIC_URL` | `http://localhost:8080` | used in the `/j/{code}` invite page |

Other knobs: `tally.sync.naive` (see below), `/actuator/health` is public.

## Layout

```
config/   AppProperties, JwtService, SecurityConfig (stateless bearer filter)
auth/     dev/apple/google/refresh login, /me, /devices, IdTokenVerifier (JWKS, RS256)
group/    groups, members, invites (/invites/{code}, /j/{code} HTML page)
sync/     events push/pull/snapshot, EventApplier (pure, mirrors the Dart one), EventValidator, GroupStateStore
money/    Money (currency decimals), Split, Settlement
export/   JSON/CSV export, Splitwise CSV import (goes through the normal push path)
push/     FcmNotifier (no-op without credentials)
common/   ApiException → {"code","message"}, RateLimiter (120 events/min/user)
```

Splitwise import: each name column is that person's net for the row; the largest net is the payer, everyone else
owes `-net`. Unknown names become placeholder members. Rows with multiple payers are rejected with `IMPORT_FAILED`.

## 효준님 몫

Four places are intentionally empty and throw `TODO("TODO(효준)")`. Each carries a comment with the exact rules.

| # | Where | What |
|---|---|---|
| 1 | `src/main/kotlin/dev/nariinfo/tally/money/Split.kt:26` (`Split.compute`) | equal/exact/percent split, remainder by memberId ascending |
| 2 | `src/main/kotlin/dev/nariinfo/tally/money/Settlement.kt:17` (`balances`) and `:30` (`simplify`) | balances and greedy debt simplification |
| 3 | `src/main/kotlin/dev/nariinfo/tally/sync/EventService.kt:78` (`EventService.push`) | the push transaction: `FOR UPDATE` lock, clientId dedupe, seq assignment, apply, `latest_seq` |
| 4 | `src/test/kotlin/dev/nariinfo/tally/SplitTest.kt:31,40` and `src/test/kotlin/dev/nariinfo/tally/SettlementTest.kt:32,40,47,53,59` | the assertions and property tests |

Workflow:

1. Implement 1, 2 and 4, then `./gradlew --no-daemon test -PincludeHyojun` until green.
2. Implement 3 (`push`). Set `tally.sync.naive: false` in `application-dev.yml` and in
   `src/test/kotlin/dev/nariinfo/tally/IntegrationTestBase.kt`, run the full suite with `-PincludeHyojun`
   (`EventSyncTest.duplicatePushReturnsSameSeq` is the one that needs the dedupe), then delete `EventService.pushNaive`
   and the `tally.sync.naive` property.
