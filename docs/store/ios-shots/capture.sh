#!/bin/bash
# Captures the 8 store frames on one simulator. Run from the directory that holds ids.json (from seed.py) and
# ws-iphone / ws-ipad (the app's VM service URI, from the flutter run output). See README.txt.
#   capture.sh iphone <out-dir>    iPhone 17 Pro Max, 440x956 points
#   capture.sh ipad <out-dir>      iPad Pro 13-inch (M5), 1032x1376 points
set -e
S="$(cd "$(dirname "$0")" && pwd)/sim.sh"
DEV=$1; O=$2; mkdir -p "$O"
LIS=$(python3 -c "import json;print(json.load(open('ids.json'))['Lisbon trip']['id'])")
SEA=$(python3 -c "import json;print(json.load(open('ids.json'))['Lisbon trip']['expenses']['Seafood dinner in Cais do Sodré'])")
if [ "$DEV" = iphone ]; then
  U=E0A764AA-73AB-4165-9A8D-FB18184245A3; W=ws-iphone
  BAL="220 166"; DESC="160 275"; SHARES="291 674"; LEO="287 855"; EDIT_ITEMS="367 646"
else
  U=31791BF2-6CCD-4D9C-BC64-03B99AFBA4F8; W=ws-ipad
  BAL="515 135"; DESC="115 245"; SHARES="292 593"; LEO="879 720"; EDIT_ITEMS="959 680"
fi
s() { "$S" $W "$@"; }

s go /; sleep 2;                        "$S" $U shot "$O/01-groups.png"
s push /groups/$LIS; sleep 2;           "$S" $U shot "$O/02-expenses.png"
s tap $BAL; sleep 1.5;                  "$S" $U shot "$O/03-balances.png"
s push /groups/$LIS/settle; sleep 2;    "$S" $U shot "$O/04-settle-up.png"
s go /; sleep 1; s push /groups/$LIS/expenses/new; sleep 2
s type 180.00                           # the amount field has focus
s tap $DESC; sleep 0.7; s type "Fado dinner in Alfama"; sleep 0.5; s unfocus; sleep 1
s tap $SHARES; sleep 1.2
s tap $LEO; sleep 0.7; s type 2; sleep 0.4; s unfocus; sleep 1    # Leo: 2 shares
if [ "$DEV" = iphone ]; then            # back to the top (the focused field scrolled the form), then a little down
  s drag 220 300 900; sleep 1.5; s drag 220 700 640
fi
sleep 1.5;                              "$S" $U shot "$O/05-add-expense.png"
s go "/?tab=friends"; sleep 2;          "$S" $U shot "$O/06-friends.png"
s go /; sleep 1; s push /activity; sleep 3; "$S" $U shot "$O/07-activity.png"
s go /; sleep 1; s push /groups/$LIS/expenses/$SEA/edit; sleep 2; s unfocus; sleep 1
[ "$DEV" = iphone ] && { s drag 220 800 400; sleep 1.5; }
s tap $EDIT_ITEMS; sleep 2              # Items → Edit
[ "$DEV" = iphone ] && { s drag 220 850 150; sleep 1.5; }   # down to the totals
"$S" $U shot "$O/08-items.png"
s go /
swift "$(dirname "$S")/flatten.swift" "$O"/0*.png      # App Store Connect refuses PNGs with an alpha channel
