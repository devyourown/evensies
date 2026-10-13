#!/bin/bash
# Captures the 8 store frames on the iPhone 17 Pro Max simulator (440x956 points). Run from the directory that holds
# ids.json (from seed.py) and ws-iphone (the app's VM service URI, from the flutter run output). See README.txt.
#   capture.sh <out-dir>
set -e
S="$(cd "$(dirname "$0")" && pwd)/sim.sh"
O=$1; mkdir -p "$O"
LIS=$(python3 -c "import json;print(json.load(open('ids.json'))['Lisbon trip']['id'])")
SEA=$(python3 -c "import json;print(json.load(open('ids.json'))['Lisbon trip']['expenses']['Seafood dinner in Cais do Sodré'])")
U=E0A764AA-73AB-4165-9A8D-FB18184245A3
s() { "$S" ws-iphone "$@"; }
shot() { "$S" $U shot "$O/$1.png"; }

s go /; sleep 2;                        shot 01-groups
s push /groups/$LIS; sleep 2;           shot 02-expenses
s tap 220 166; sleep 1.5;               shot 03-balances
s push /groups/$LIS/settle; sleep 2;    shot 04-settle-up
s go /; sleep 1; s push /groups/$LIS/expenses/new; sleep 2
s type 180.00                           # the amount field has focus
s tap 160 275; sleep 0.7; s type "Fado dinner in Alfama"; sleep 0.5; s unfocus; sleep 1
s tap 291 674; sleep 1.2                # Split: Shares
s tap 287 855; sleep 0.7; s type 2; sleep 0.4; s unfocus; sleep 1    # Leo: 2 shares
s scroll 0; sleep 1.5                   # the focused fields scrolled the form; its top ends on Priya's whole row
shot 05-add-expense
s go "/?tab=friends"; sleep 2;          shot 06-friends
s go /; sleep 1; s push /activity; sleep 3; shot 07-activity
s go /; sleep 1; s push /groups/$LIS/expenses/$SEA/edit; sleep 2; s unfocus; sleep 1
s drag 220 800 400; sleep 1.5           # down to the Items row
s tap 367 646; sleep 2                  # Items → Edit, at the top: five whole line cards, four of them per person
shot 08-items
s go /
swift "$(dirname "$S")/flatten.swift" "$O"/0*.png      # App Store Connect refuses PNGs with an alpha channel
