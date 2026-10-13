Google Play phone screenshots, Evensies 1.0 (captured 2026-10-13)

01-groups.png        Groups list with balances (and the settled-up section)
02-expenses.png      Lisbon trip > Expenses
03-balances.png      Lisbon trip > Balances
04-settle-up.png     Settle up, with PayPal / Wise pay buttons on Alex -> Maya
05-add-expense.png   New expense, Shares split (Leo 2 shares), Scan receipt / Add photo
06-friends.png       Friends tab
07-activity.png      Lisbon trip > Activity (comments, payment, expenses)
08-receipt-scan.png  Scan receipt > Items: the receipt photo read on the phone, first lines assigned

1080x1920 (9:16; Play allows a long side of at most 2x the short side), 24-bit PNG without alpha.
All people, handles and the receipt are made up. Same data as the iOS set: seed.py, backdate.sql and
receipt.swift here are the files the iOS capture used.

Feature graphic: ../play-feature-graphic.png (1024x500) from ../feature-graphic.html (commands in its header).

How to redo (macOS, from the repository root; nothing touches the official server)

1. Database and server (prebuilt jar, JDK 21, throwaway Postgres):
   docker run -d --name evensies-shots-android-pg -e POSTGRES_USER=evensies -e POSTGRES_PASSWORD=evensies \
     -e POSTGRES_DB=evensies -p 55452:5432 postgres:16-alpine
   export JAVA_HOME=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home
   EVENSIES_DB_URL=jdbc:postgresql://localhost:55452/evensies EVENSIES_DB_USER=evensies EVENSIES_DB_PASSWORD=evensies \
   EVENSIES_JWT_SECRET=$(openssl rand -hex 32) EVENSIES_AUTH_DEV_LOGIN=true EVENSIES_STORAGE_DIR=/tmp/evensies-shots \
   EVENSIES_SUPPORT_EMAIL=support@nariinfo.dev EVENSIES_FX_URL= SERVER_PORT=18202 \
     $JAVA_HOME/bin/java -jar server/build/libs/evensies-server-0.0.1-SNAPSHOT.jar

2. Seed through the HTTP API (dev login users Alex, Maya, Jonas, Priya, Leo), then make the feed times match
   the event times (the feed shows when the server received an event):
   python3 -I docs/store/android-phone/seed.py http://localhost:18202
   docker exec -i evensies-shots-android-pg psql -U evensies -d evensies < docs/store/android-phone/backdate.sql

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
   Sign in: tap "Dev name", `adb shell input text Alex`, back (hide keyboard), "Dev login".
   Open Activity (clock icon) once and go back, so the unread badge is gone.

5. Capture each screen (screencap PNG has alpha; a JPEG round trip removes it):
   $A exec-out screencap -p > raw.png
   sips -s format jpeg -s formatOptions 100 raw.png --out raw.jpg && sips -s format png raw.jpg --out 01-groups.png
   sips -g pixelWidth -g pixelHeight -g hasAlpha 01-groups.png
   Screens: 01 Groups tab. 02 Lisbon trip. 03 Balances tab. 04 Settle up. 07 Activity tab.
   05 + Expense: `adb shell input text 180.00`, Description `Sunset boat tour`, Shares, Leo's field -> 2, back,
      scroll until the Split heading is near the top. Back out without saving.
   08 + Expense, scan icon (top right) > Choose from library > the receipt; collapse Receipt, tick Alex + Maya on
      "Caldo verde x2" and Alex on "Polvo a lagareiro", expand Receipt again. Close and back out without saving.
   06 Friends tab.

6. Clean up: stop the app and server, `docker rm -f evensies-shots-android-pg`,
   $A shell $D exit; $A shell settings put global sysui_demo_allowed 0
   $A shell wm size reset; $A shell wm density 216   (this AVD's previous override; `wm density reset` if it had none)
   $A shell service call alarm 3 s16 Asia/Seoul       (the previous zone)
   $A emu kill
