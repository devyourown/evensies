# Evensies

Expense splitting for friends, roommates and trips. A Splitwise alternative with **no daily limits, no ads, and no data lock-in**. iOS, Android and web app (Flutter) + a small server (Spring Boot, Kotlin, PostgreSQL). The source is public under the [Functional Source License](LICENSE).

> Status: pre-release. The product name is Evensies.

## Why
Splitwise caps free users at a few expenses per day — exactly on the first day of a trip. Most alternatives are web apps. Evensies is a native app with offline-first sync, and the same app runs in the browser.

## Promises (sustainability rules)
These are commitments, written down so they can't quietly change later:
1. **No input limits, ever.** Not per day, not per group.
2. **No ads and no tracking.**
3. **Export is always available** (JSON and CSV). Your data leaves whenever you do.
4. **No paywall.** Every feature is free.
5. **The source stays public**, and each version becomes Apache-2.0 two years after its release.

## Features
- Groups (trip, home, couple, other) with invite links, codes and QR; placeholder members claimed later; cover photos; delete and restore a group
- Friends: 1:1 expenses outside groups, balances across everything, reminders, block and report
- Six ways to split (equal with tick boxes, exact, percent, shares, adjustment, items from a receipt), several payers, refunds, a default split per group
- 155 currencies with automatic daily exchange rates and a home currency
- Categories, search, charts, edit history, comments, activity feed and push notifications
- Settle up with the fewest transfers and pay links (PayPal, Wise, Venmo, Revolut, KakaoPay, UPI, EPC QR / IBAN, Korean bank account); sent → confirmed payments
- Receipt photos with on-device scanning, repeating expenses, email sign-in codes and a summary email
- Offline-first sync, 13 languages, web app, home-screen widget, app lock
- Export a group (JSON, CSV, ZIP with receipts) or everything (JSON); import a Splitwise CSV

## Repository layout
```
app/      Flutter app (iOS, Android, web)
server/   Spring Boot (Kotlin) API + sync server
shared/   JSON test cases both implementations must pass (split, settlement, sync), shared strings
deploy/   Docker Compose, Caddy, .env.example
docs/     API contract (docs/API.md), design spec, plans
```

## Running the server yourself
The license allows running Evensies for your own internal use, education and research, but not offering it to others as a competing product or service. The App Store and Play Store app connects only to the official server; a build that talks to another server must use its own name and icon (see [TRADEMARKS.md](TRADEMARKS.md)); the build variables and the steps are in [docs/API.md](docs/API.md#빌드-변수-앱---dart-define) (빌드 변수).
```bash
git clone https://github.com/devyourown/evensies && cd evensies/deploy
cp .env.example .env     # set EVENSIES_DOMAIN, EVENSIES_JWT_SECRET, DB password, Apple/Google client ids
docker compose up -d
```
Caddy obtains TLS automatically for `EVENSIES_DOMAIN`. The server image also serves the web app at `https://EVENSIES_DOMAIN/app/`; set `EVENSIES_GOOGLE_WEB_CLIENT_ID` and `EVENSIES_APPLE_SERVICES_ID` to show Google and Apple sign-in there. See [server/README.md](server/README.md) and [docs/API.md](docs/API.md) for environment variables.

## Languages
The app, the activity feed, notifications and invite pages follow each person's language. English is the source and the fallback.

| Language | Code | Status |
|---|---|---|
| English | `en` | source |
| Korean | `ko` | machine-translated, maintainer review pending |
| Dutch | `nl` | machine-translated — reviews welcome |
| French | `fr` | machine-translated — reviews welcome |
| German | `de` | machine-translated — reviews welcome |
| Indonesian | `id` | machine-translated — reviews welcome |
| Italian | `it` | machine-translated — reviews welcome |
| Japanese | `ja` | machine-translated — reviews welcome |
| Polish | `pl` | machine-translated — reviews welcome |
| Portuguese (Brazil) | `pt` | machine-translated — reviews welcome |
| Spanish | `es` | machine-translated — reviews welcome |
| Swedish | `sv` | machine-translated — reviews welcome |
| Thai | `th` | machine-translated — reviews welcome |

## Translating
Corrections are welcome as pull requests. Text lives in two places:
- **App screens:** `app/lib/l10n/app_<code>.arb`. `app_en.arb` is the source; each key's `@description` says where it appears. Run `flutter gen-l10n` in `app/` and commit the generated `app_localizations*.dart`.
- **Sentences the server also writes** (activity feed, push notifications, reminders, invite and friend pages, category names, repeat wording, money format): `shared/strings.json`, keyed by language. Copy it byte for byte to `app/assets/strings.json` and `server/src/main/resources/strings.json`.

Rules: whole sentences with every `{placeholder}` kept; plurals only in ARB (ICU `one`/`other`, plus `few`/`many` for Polish); gender-neutral wording around names; informal register for de, es, it, nl, pl, pt, sv and formal for fr (vous), ja (です/ます) and ko (해요체). Names, descriptions, brand names and currency codes and names stay as they are. `cd app && flutter test test/l10n_test.dart` and `cd server && ./gradlew test --tests '*StringsTest'` check that every language has every key and placeholder.

## Develop
```bash
# database
docker compose -f deploy/docker-compose.dev.yml up -d
# server (dev profile enables /auth/dev)
cd server && ./gradlew bootRun --args='--spring.profiles.active=dev'
# app (iOS simulator)
cd app && flutter run --dart-define=DEV_LOGIN=true --dart-define=EVENSIES_SERVER_URL=http://localhost:8080
# web app (Chrome) against the same server
cd app && flutter run -d chrome --web-port 7357 --dart-define=EVENSIES_SERVER_URL=http://localhost:8080
```
Phone debug builds (`flutter run`) have a Settings → Server field; phone release builds always use `EVENSIES_SERVER_URL` (default: the official server) unless built with `--dart-define=EVENSIES_ALLOW_CUSTOM_SERVER=true` ([app/README.md](app/README.md)).

Tests: `cd server && ./gradlew test` · `cd app && flutter test`.

## Design
- Money is stored as integers in the currency's minor unit; splits are stored as final per-member amounts.
- Sync is an append-only event log per group with a server-assigned sequence; pushes are idempotent via `(group_id, client_id)`.
- The app keeps a full local copy (SQLite) and computes balances locally, so it works offline.
- Contract: [docs/API.md](docs/API.md). Spec: [docs/superpowers/specs](docs/superpowers/specs).

## License
[Functional Source License 1.1, Apache-2.0 future license](LICENSE) (FSL-1.1-ALv2). You may read, use, modify and redistribute the code for any purpose except a competing product or service; two years after each version is published, that version is also available under Apache-2.0. The name and icon are covered by the [trademark policy](TRADEMARKS.md).

Versions published up to commit `d3ac783` (2026-10-11) were released under AGPL-3.0 and remain available under it.
