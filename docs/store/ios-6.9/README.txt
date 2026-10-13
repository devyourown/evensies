App Store screenshots: ios-6.9/ (iPhone 17 Pro Max simulator, 1320x2868) and ../ipad-13/ (iPad Pro 13-inch (M5)
simulator, 2064x2752). Captured 2026-10-13 from a debug build of main (05c61be) against a local server with made-up
demo data. Light mode, en_US, status bar 9:41. Scripts: ../ios-shots/. Never point any of this at the official server.

Why scripts and not taps: the simulator's HID keyboard is unreliable, so ios-shots/sim.sh drives the running debug app
through its Dart VM service instead (router go/push, pointer taps and drags, text edits). The tap coordinates in
capture.sh are logical points for these two devices; if a layout changes, check with `sim.sh <udid> shot x.png`.

REPO=<path to the evensies checkout>; WORK=$(mktemp -d)    # WORK holds ids.json and the ws-* files
IPHONE=E0A764AA-73AB-4165-9A8D-FB18184245A3; IPAD=31791BF2-6CCD-4D9C-BC64-03B99AFBA4F8   # this Mac's simulator ids

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
   cd $WORK && python3 $REPO/docs/store/ios-shots/seed.py http://localhost:18201
   docker exec -i evensies-shots-ios-pg psql -U evensies -d evensies < $REPO/docs/store/ios-shots/backdate.sql
   (backdate.sql makes the activity feed show each event's own date instead of "just now".)

3. Simulators: English, light, clean status bar. On the iPad, iPadOS 26 "Windowed Apps" draws a resize handle in the
   bottom-right corner; the two springboard keys switch to full-screen apps.
   for U in $IPHONE $IPAD; do xcrun simctl boot $U
     xcrun simctl spawn $U defaults write -g AppleLocale en_US
     xcrun simctl spawn $U defaults write -g AppleLanguages -array en-US; done
   xcrun simctl spawn $IPAD defaults write com.apple.springboard SBFlexibleWindowingUI -bool false
   xcrun simctl spawn $IPAD defaults write com.apple.springboard SBChamoisWindowingUI -bool false
   for U in $IPHONE $IPAD; do xcrun simctl shutdown $U; xcrun simctl boot $U; xcrun simctl ui $U appearance light
     xcrun simctl status_bar $U override --time 9:41 --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3
   done

4. The app, one terminal per device (TZ makes the activity times read as Lisbon time):
   cd $REPO/app && SIMCTL_CHILD_TZ=Europe/Lisbon flutter run -d $IPHONE \
     --dart-define=DEV_LOGIN=true --dart-define=EVENSIES_SERVER_URL=http://localhost:18201
   Put the "ws://127.0.0.1:.../ws" URI it prints into $WORK/ws-iphone (the iPad's into $WORK/ws-ipad).

5. Sign in as Alex (no typing), capture, check the sizes:
   cd $WORK
   $REPO/docs/store/ios-shots/sim.sh ws-iphone eval \
     "ProviderScope.containerOf(scaffoldMessengerKey.currentContext!, listen: false).read(authServiceProvider).dev('Alex')"
   (same with ws-ipad), then
   $REPO/docs/store/ios-shots/capture.sh iphone $REPO/docs/store/ios-6.9
   $REPO/docs/store/ios-shots/capture.sh ipad $REPO/docs/store/ipad-13
   sips -g pixelWidth -g pixelHeight -g hasAlpha $REPO/docs/store/ios-6.9/0*.png $REPO/docs/store/ipad-13/0*.png
   (capture.sh ends with flatten.swift, which drops the alpha channel App Store Connect refuses.)

6. Clean up: quit both flutter runs, stop the server, `docker rm -f evensies-shots-ios-pg`, and per simulator
   `xcrun simctl status_bar $U clear`, restore its language, `defaults delete com.apple.springboard SBFlexibleWindowingUI`
   (and SBChamoisWindowingUI) on the iPad, then `xcrun simctl shutdown $U`.
