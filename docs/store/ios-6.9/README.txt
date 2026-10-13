App Store screenshots: iPhone 17 Pro Max simulator, 1320x2868. Release 1.0 is iPhone-only (no iPad set; iPad
screenshots come back with a tablet layout). Captured 2026-10-13 from a debug build of main (05c61be) against a local
server with made-up demo data. Light mode, en_US, status bar 9:41, full battery (not charging). Scripts: ../ios-shots/.
seed.py there is the one seed for both stores (the Android set uses it too). Never point any of this at the official server.

Why scripts and not taps: the simulator's HID keyboard is unreliable, so ios-shots/sim.sh drives the running debug app
through its Dart VM service instead (router go/push, pointer taps and drags, scroll offsets, text edits). The tap
coordinates in capture.sh are logical points for this device; if a layout changes, check with `sim.sh <udid> shot x.png`.

REPO=<path to the evensies checkout>; WORK=$(mktemp -d)    # WORK holds ids.json and ws-iphone
U=E0A764AA-73AB-4165-9A8D-FB18184245A3                     # this Mac's iPhone 17 Pro Max simulator

1. Database and server (dev login on, no SMTP, no exchange-rate fetches)
   docker run -d --name evensies-shots-ios-pg -e POSTGRES_USER=evensies -e POSTGRES_PASSWORD=evensies \
     -e POSTGRES_DB=evensies -p 55451:5432 postgres:16-alpine
   export JAVA_HOME=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home
   (cd $REPO/server && ./gradlew --no-daemon bootJar)
   EVENSIES_DB_URL=jdbc:postgresql://localhost:55451/evensies EVENSIES_DB_USER=evensies EVENSIES_DB_PASSWORD=evensies \
   EVENSIES_JWT_SECRET=$(openssl rand -hex 32) EVENSIES_AUTH_DEV_LOGIN=true EVENSIES_STORAGE_DIR=$WORK/data \
   EVENSIES_SUPPORT_EMAIL=support@nariinfo.dev EVENSIES_FX_URL= \
   $JAVA_HOME/bin/java -jar $REPO/server/build/libs/evensies-server-0.0.1-SNAPSHOT.jar --server.port=18201

2. Seed through the HTTP API (Alex, Maya, Jonas, Priya, Leo; Lisbon trip, Flat 3B with monthly rent, Berlin
   weekend, Climbing crew, Alex & Priya non-group; PayPal and Wise on Maya). Run once on an empty database.
   Member ids are random, so a cent of equal-split rounding can land on another person from one run to the next.
   cd $WORK && python3 $REPO/docs/store/ios-shots/seed.py http://localhost:18201
   docker exec -i evensies-shots-ios-pg psql -U evensies -d evensies < $REPO/docs/store/ios-shots/backdate.sql
   (backdate.sql makes the activity feed show each event's own date instead of "just now".)

3. Simulator: English, light, clean status bar.
   xcrun simctl boot $U
   xcrun simctl spawn $U defaults write -g AppleLocale en_US
   xcrun simctl spawn $U defaults write -g AppleLanguages -array en-US
   xcrun simctl shutdown $U; xcrun simctl boot $U; xcrun simctl ui $U appearance light
   xcrun simctl status_bar $U override --time 9:41 --batteryState discharging --batteryLevel 100 --cellularBars 4 --wifiBars 3

4. The app (TZ makes the activity times read as Lisbon time):
   cd $REPO/app && SIMCTL_CHILD_TZ=Europe/Lisbon flutter run -d $U \
     --dart-define=DEV_LOGIN=true --dart-define=EVENSIES_SERVER_URL=http://localhost:18201
   Put the "ws://127.0.0.1:.../ws" URI it prints into $WORK/ws-iphone.

5. Sign in as Alex (no typing), capture, check the sizes:
   cd $WORK
   $REPO/docs/store/ios-shots/sim.sh ws-iphone eval \
     "ProviderScope.containerOf(scaffoldMessengerKey.currentContext!, listen: false).read(authServiceProvider).dev('Alex')"
   $REPO/docs/store/ios-shots/capture.sh $REPO/docs/store/ios-6.9
   sips -g pixelWidth -g pixelHeight -g hasAlpha $REPO/docs/store/ios-6.9/0*.png
   (capture.sh ends with flatten.swift, which drops the alpha channel App Store Connect refuses.)
   To seed again, sign out first (same eval with .logout()), since the app keeps the old server's rows.

6. Clean up: quit flutter run, stop the server, `docker rm -f evensies-shots-ios-pg`, then
   `xcrun simctl status_bar $U clear`, restore the simulator's language, `xcrun simctl shutdown $U`.
