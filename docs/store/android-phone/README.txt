Google Play phone screenshots, Evensies 1.0 (captured 2026-10-13)

01-groups.png        Groups list with balances (and the settled-up section)
02-expenses.png      Lisbon trip > Expenses
03-balances.png      Lisbon trip > Balances
04-settle-up.png     Settle up, with PayPal / Wise pay buttons on Alex -> Maya
05-add-expense.png   New expense "Fado dinner in Alfama", 180.00, Dining out (auto), Shares split (Leo 2 shares)
06-friends.png       Friends tab
07-activity.png      Activity across all groups (clock icon on Groups)
08-receipt-scan.png  Scan receipt > Items: the receipt photo read on the phone, every line assigned (Done enabled)

1080x1920 (9:16; Play allows a long side of at most 2x the short side), 24-bit PNG without alpha.
All people, handles and the receipt are made up. Same data as the iOS set: the seed, backdate.sql and the
VM-service driver are in ../ios-shots/ (see ../ios-6.9/README.txt); receipt.swift here draws the receipt photo.

Feature graphic: ../play-feature-graphic.png (1024x500) from ../feature-graphic.html (commands in its header).

How to redo (macOS, from the repository root; nothing touches the official server)
REPO=$(pwd); WORK=$(mktemp -d)    # WORK holds ids.json and ws-android

1. Database and server (JDK 21, throwaway Postgres):
   docker run -d --name evensies-shots-android-pg -e POSTGRES_USER=evensies -e POSTGRES_PASSWORD=evensies \
     -e POSTGRES_DB=evensies -p 55452:5432 postgres:16-alpine
   export JAVA_HOME=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home
   (cd server && ./gradlew --no-daemon bootJar)
   EVENSIES_DB_URL=jdbc:postgresql://localhost:55452/evensies EVENSIES_DB_USER=evensies EVENSIES_DB_PASSWORD=evensies \
   EVENSIES_JWT_SECRET=$(openssl rand -hex 32) EVENSIES_AUTH_DEV_LOGIN=true EVENSIES_STORAGE_DIR=/tmp/evensies-shots \
   EVENSIES_SUPPORT_EMAIL=support@nariinfo.dev EVENSIES_FX_URL= SERVER_PORT=18202 \
     $JAVA_HOME/bin/java -jar server/build/libs/evensies-server-0.0.1-SNAPSHOT.jar

2. Seed through the HTTP API (dev login users Alex, Maya, Jonas, Priya, Leo), then make the feed times match the
   event times. seed.py uses random ids and the last cent of an uneven split goes by id order, so run it with
   seeded ids to get the iPhone set's cents (Alex owes 54.70 in Lisbon, is owed 531.15 in Flat 3B):
   cd $WORK && python3 -I -c "
   import random, runpy, sys, uuid
   r = random.Random(2)
   uuid.uuid4 = lambda: uuid.UUID(int=r.getrandbits(128), version=4)
   sys.argv = sys.argv[1:]; runpy.run_path(sys.argv[0], run_name='__main__')" $REPO/docs/store/ios-shots/seed.py http://localhost:18202
   docker exec -i evensies-shots-android-pg psql -U evensies -d evensies < $REPO/docs/store/ios-shots/backdate.sql
   ($WORK now holds ids.json; LIS below is its "Lisbon trip" id.)

3. Emulator (Pixel_8 AVD, API 34), 9:16, Lisbon time, clean status bar, receipt photo in the library:
   ~/Library/Android/sdk/emulator/emulator -avd Pixel_8 -no-snapshot-save -no-audio -no-boot-anim -port 5584 &
   A="adb -s emulator-5584"
   $A shell wm size 1080x1920 && $A shell wm density 380      # 420 cuts the "Lisbon trip" title
   $A shell service call alarm 3 s16 Europe/Lisbon             # times in the feed are local to the trip
   $A shell settings put global sysui_demo_allowed 1
   D="am broadcast -a com.android.systemui.demo -e command"
   $A shell $D enter; $A shell $D clock -e hhmm 0941
   $A shell $D battery -e level 100 -e plugged false
   $A shell $D network -e wifi show -e level 4 -e fully true; $A shell $D network -e mobile hide
   $A shell $D notifications -e visible false
   (density changes restart SystemUI: set the density first, then demo mode)
   swift docs/store/android-phone/receipt.swift /tmp/receipt.jpg
   $A push /tmp/receipt.jpg /sdcard/Pictures/evensies-demo-receipt.jpg
   $A shell am broadcast -a android.intent.action.MEDIA_SCANNER_SCAN_FILE -d file:///sdcard/Pictures/evensies-demo-receipt.jpg

4. App (debug build, no debug banner; the dev login and the Settings > Server field never appear in the frames):
   cd app && flutter run -d emulator-5584 --dart-define=DEV_LOGIN=true --dart-define=EVENSIES_SERVER_URL=http://10.0.2.2:18202
   Put the VM service URI it prints, as ws://127.0.0.1:<port>/<token>=/ws, into $WORK/ws-android.
   S="$REPO/docs/store/ios-shots/sim.sh ws-android"   (run from $WORK; taps are logical points, 454x808 here)
   $S eval "ProviderScope.containerOf(scaffoldMessengerKey.currentContext!, listen: false).read(authServiceProvider).dev('Alex')"
   $S push /activity; $S go /      # once, so the unread badge on the clock icon is gone

5. Capture each screen (screencap PNG has alpha; a JPEG round trip removes it):
   $A exec-out screencap -p > raw.png
   sips -s format jpeg -s formatOptions 100 raw.png --out raw.jpg && sips -s format png raw.jpg --out 01-groups.png
   01 $S go /
   02 $S push /groups/$LIS; then $S drag 220 600 501 and $S drag 220 600 572: "Mon, Oct 5" at the top and the
      + Expense button over the gap at "Fri, Oct 2", not over a row.
   03 $S tap 225 147 (Balances tab).   04 $S push /groups/$LIS/settle
   05 $S go /; $S push /groups/$LIS/expenses/new; $S type 180.00; $S tap 160 257; $S type "Fado dinner in Alfama";
      $S unfocus; $S tap 284 658 (Shares); $S drag 220 650 350; $S tap 300 548 (Leo); $S type 2; $S unfocus;
      $S drag 220 200 750 (back to the top: amount, description and the start of the split, nothing cut).
   06 $S go "/?tab=friends"   07 $S go /; $S push /activity; $S drag 220 600 574 (the last row ends on screen)
   08 $S go /; $S push /groups/$LIS/expenses/new; $S unfocus; $S tap 430 73 (scan) > Choose from library, then
      $A shell input tap 130 1300 (the receipt in the system picker). Collapse Receipt ($S tap 402 136) and assign
      every line so Done turns on: Caldo verde Alex + Maya, Polvo Alex, Bitoque Jonas, Arroz Leo + Priya,
      Salada Maya, Agua and Vinho All, Pastel de nata Jonas + Leo + Priya. Scroll to the top, expand Receipt.
      Leave with $S go / (nothing is saved).
   sips -g pixelWidth -g pixelHeight -g hasAlpha docs/store/android-phone/0*.png

6. Clean up: stop the app and server, `docker rm -f evensies-shots-android-pg`,
   $A shell $D exit; $A shell settings put global sysui_demo_allowed 0
   $A shell wm size reset; $A shell wm density 216   (this AVD's previous override; `wm density reset` if it had none)
   $A shell service call alarm 3 s16 Asia/Seoul       (the previous zone)
   $A emu kill
