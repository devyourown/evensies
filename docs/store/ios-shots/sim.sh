#!/bin/bash
# Drives a running debug build through its Dart VM service (no simulator taps needed; see README.txt).
#   sim.sh <ws-file> go|push <route>       router navigation
#   sim.sh <ws-file> tap <x> <y>           a tap at logical points
#   sim.sh <ws-file> drag <x> <y1> <y2>    a slow vertical drag (scroll)
#   sim.sh <ws-file> scroll <px>           jumps the current screen's main list to that scroll offset
#   sim.sh <ws-file> type <text>           replaces the focused field's text, as if typed
#   sim.sh <ws-file> unfocus               hides the keyboard
#   sim.sh <ws-file> eval <dart expr>      anything else, evaluated in package:evensies/app.dart
#   sim.sh <udid> shot <out.png>           simctl screenshot
set -e
D=$(cd "$(dirname "$0")" && pwd)
W=$1; CMD=$2; shift 2
P=$(( RANDOM + 1 ))  # pointer id
ev() { node "$D/vm.js" "$(cat "$W")" package:evensies/app.dart "() { Future(() { $1; }); return 'ok'; }()" >/dev/null; }
C='ProviderScope.containerOf(scaffoldMessengerKey.currentContext!, listen: false)'
case $CMD in
  go|push) ev "$C.read(routerProvider).$CMD('$1')" ;;
  tap) ev "final b = WidgetsBinding.instance; b.handlePointerEvent(PointerDownEvent(pointer: $P, position: Offset($1, $2))); b.handlePointerEvent(PointerUpEvent(pointer: $P, position: Offset($1, $2)))" ;;
  drag) ev "final b = WidgetsBinding.instance; const n = 30; final x = $1.0, y1 = $2.0, y2 = $3.0; b.handlePointerEvent(PointerDownEvent(pointer: $P, position: Offset(x, y1), timeStamp: Duration.zero)); for (var i = 1; i <= n; i++) { b.handlePointerEvent(PointerMoveEvent(pointer: $P, position: Offset(x, y1 + (y2 - y1) * i / n), delta: Offset(0, (y2 - y1) / n), timeStamp: Duration(milliseconds: 50 * i))); } b.handlePointerEvent(PointerMoveEvent(pointer: $P, position: Offset(x, y2), timeStamp: Duration(milliseconds: 50 * n + 400))); b.handlePointerEvent(PointerUpEvent(pointer: $P, position: Offset(x, y2), timeStamp: Duration(milliseconds: 50 * n + 450)))" ;;
  scroll) ev "ScrollableState? m; void v(Element e) { if (e is StatefulElement && e.state is ScrollableState) { final s = e.state as ScrollableState; if ((ModalRoute.of(e)?.isCurrent ?? false) && s.position.axis == Axis.vertical && (m == null || s.position.viewportDimension > m!.position.viewportDimension)) m = s; } e.visitChildren(v); } WidgetsBinding.instance.rootElement!.visitChildren(v); m!.position.jumpTo($1.0)" ;;
  type) ev "FocusManager.instance.primaryFocus!.context!.findAncestorStateOfType<EditableTextState>()!.updateEditingValue(TextEditingValue(text: '$1', selection: TextSelection.collapsed(offset: '$1'.length)))" ;;
  unfocus) ev "FocusManager.instance.primaryFocus?.unfocus()" ;;
  eval) node "$D/vm.js" "$(cat "$W")" package:evensies/app.dart "$1" ;;
  shot) xcrun simctl io "$W" screenshot "$1" >/dev/null 2>&1 && echo "$1" ;;
  *) echo "unknown command $CMD" >&2; exit 2 ;;
esac
