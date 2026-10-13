# Releasing

How the maintainer ships a new version of the apps and the server. Contributors don't need any of this: pull requests are released from `main`.

Signing keys, certificates, Firebase files and `deploy/.env` never go into the repository. These are git-ignored and must stay that way: `app/ios/Runner/GoogleService-Info.plist`, `app/android/app/google-services.json`, `app/android/key.properties` and the upload keystore, `*.p8` App Store Connect API keys, `ExportOptions.plist`, `deploy/.env` and `deploy/secrets/`.

## Order of a release

1. **CI is green on `main`**, and the checks in [CONTRIBUTING.md](../CONTRIBUTING.md#running-the-tests) pass locally, including the server tests.
2. **Server first.** The compatibility notes in [docs/API.md](API.md) assume the server is updated before the apps that need it. Deploy the server, check it, then upload the apps.
3. **Apps**: bump the version, build iOS and Android, upload, test on real devices through TestFlight and an internal Play track, then submit for review.
4. **Store listing**: update the text and screenshots if the features changed.

## 1. Version

The version lives in one place, `app/pubspec.yaml`:

```yaml
version: 1.0.1+5   # <name shown to users>+<build number>
```

Both stores need a higher build number for every upload, even a rejected one; the name changes only when users should see a new version. iOS (the app and the widget extension) reads them through `FLUTTER_BUILD_NAME` / `FLUTTER_BUILD_NUMBER`, Android through `flutter.versionName` / `flutter.versionCode`.

## 2. Store builds use no build variables

Store builds pass **no** `--dart-define`. Without them a release build talks only to the official server, has no dev login and no Settings → Server field ([Official server](API.md#official-server-app-only), [build variables](API.md#build-variables-app---dart-define)). A fork that ships its own app sets `EVENSIES_SERVER_URL` and uses its own name, icon and bundle id ([TRADEMARKS.md](../TRADEMARKS.md)).

## 3. iOS

```sh
cd app
flutter clean          # always, before a release build
flutter pub get
flutter build ipa --release
```

**Why `flutter clean`:** every `flutter run` or `flutter build` writes its build mode and `--dart-define` values into `ios/Flutter/Generated.xcconfig`, and an archive made in Xcode uses whatever is there. An archive made right after a development run would ship `DEV_LOGIN=true` and a `localhost` server. After the release build, check that only Flutter's own values are left:

```sh
sed -n 's/^DART_DEFINES=//p' ios/Flutter/Generated.xcconfig | tr ',' '\n' | while read d; do echo "$d" | base64 --decode; echo; done
# FLUTTER_VERSION=…, FLUTTER_CHANNEL=…  and nothing starting with EVENSIES_ or DEV_LOGIN
```

`flutter build ipa` archives the app (`build/ios/archive/Runner.xcarchive`). To export and upload:

- **Xcode:** open the archive (Window → Organizer), then Distribute App → App Store Connect → Upload. Xcode signs the app and the widget extension with the distribution certificate and the App Store profiles.
- **Command line:** `flutter build ipa --release --export-options-plist=<path to ExportOptions.plist>` writes `build/ios/ipa/*.ipa`; upload it with Apple's Transporter app or `xcrun altool --upload-app` and an App Store Connect API key kept outside the repository.

The build appears in App Store Connect after processing. Test it through TestFlight before submitting it for review.

## 4. Android

```sh
cd app
flutter build appbundle --release      # build/app/outputs/bundle/release/app-release.aab
```

Release signing reads `android/key.properties` and the upload keystore it points to (both git-ignored, see `android/app/build.gradle.kts`). Without them the build silently falls back to the debug key, which Google Play refuses. Check the signer before uploading:

```sh
keytool -printcert -jarfile build/app/outputs/bundle/release/app-release.aab
```

Upload the bundle in the Play Console to the internal testing track, test it, then promote it. Copy the release notes from the store listing.

## 5. Server

The production server runs `deploy/docker-compose.yml` (server, Postgres, Caddy and a daily backup) from a clone of the repository; `deploy/bootstrap.sh` sets up a fresh Ubuntu host and writes `deploy/.env`.

**Back up before migrations.** Flyway applies new migrations (`server/src/main/resources/db/migration/V*.sql`) when the server starts, and there is no automatic way back. If the release adds one, take a fresh dump and copy the uploaded files first, on the server:

```sh
cd /opt/evensies/deploy
git -C .. fetch -q && git -C .. diff --stat HEAD origin/main -- server/src/main/resources/db/migration   # new migrations?
docker compose exec -T postgres sh -c 'pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB"' | gzip > backups/pre-release-$(date +%F-%H%M).sql.gz
tar -czf backups/data-$(date +%F-%H%M).tar.gz data      # profile photos, receipts, covers (EVENSIES_STORAGE_DIR)
```

Copy both files off the server as well; the daily `backup` container keeps 14 days of dumps in `deploy/backups/` on the same disk.

**Deploy:**

```sh
sudo /opt/evensies/deploy/update.sh
```

`update.sh` pulls `main` (fast-forward only), rebuilds the server image (which includes the Flutter web build, so the host needs a few GB of free disk), restarts the containers and prunes old images. Then check:

```sh
docker compose logs --tail=100 server              # Flyway "Successfully applied …", no errors
curl -s https://<your domain>/actuator/health      # {"status":"UP"}
curl -s https://<your domain>/info
```

Open the web app at `https://<your domain>/app/` and sign in once.

**Rolling back:** check out the previous commit on the server and run `docker compose up -d --build`. If a migration already ran and the old code can't read the new schema, restore the dump into an empty database before starting the old version.

## 6. Store listing

The listing text, keywords, privacy labels and review notes are in [store/listing.md](store/listing.md).

- Update the description, "What's New" and the screenshots when features change.
- Keep the App Store privacy label and the Play data safety form in line with [privacy.md](privacy.md), and update its date when it changes. The published privacy policy is this `docs/` folder on GitHub Pages ([index.md](index.md), [privacy.md](privacy.md)).
- The server must have `EVENSIES_SUPPORT_EMAIL` set, or the app hides Report…, which App Review expects for apps with user content.
- The server must have `EVENSIES_REVIEW_LOGIN_USERNAME` / `_PASSWORD` set (the password at least 20 characters, `GET /info` says `"reviewLogin": true`), with the same values in Play Console → App access and App Store Connect → App Review Information ([store/listing.md](store/listing.md#app-access)). Without it Google Play review can't sign in.

## First release only

One-time setup that later releases keep:

- **Apple:** an App ID with Sign in with Apple, Associated Domains and the App Group the widget shares with the app; the same for the widget extension. A Services ID for Sign in with Apple on the web (`EVENSIES_APPLE_SERVICES_ID`).
- **Google:** OAuth clients for iOS, Android and the web (`EVENSIES_GOOGLE_CLIENT_IDS`, `EVENSIES_GOOGLE_WEB_CLIENT_ID`).
- **Firebase** for push: the two app config files above, and a service-account JSON at `deploy/secrets/fcm.json` with `EVENSIES_FCM_CREDENTIALS_FILE=/secrets/fcm.json`.
- **Domain:** a DNS record for the server's domain; Caddy gets the TLS certificate itself.
- **Universal Links and App Links:** `deploy/well-known/apple-app-site-association` (team id and bundle id) and `assetlinks.json` (the SHA-256 fingerprints of the Play app signing key and the upload key). Update them when a key changes.
- **Email** (optional): an SMTP provider with SPF, DKIM and DMARC for the sending domain, its bounce webhook pointed at `/webhooks/email` with `EVENSIES_EMAIL_WEBHOOK_SECRET`, and the sender address registered with Apple's private email relay so Hide My Email users get mail ([Operations at launch](API.md#operations-at-launch-phase-10)).
- **Local networking:** `NSAllowsLocalNetworking` (iOS) and `usesCleartextTraffic` (Android) exist so development builds can reach `http://localhost`. Remove them if release builds should be HTTPS-only.

All server variables are listed in [docs/API.md](API.md#environment-variables-server).
