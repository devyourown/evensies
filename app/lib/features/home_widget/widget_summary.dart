import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import '../../core/money.dart';
import '../../data/fx_rates.dart' show approxIn;
import '../../domain/overview.dart';
import '../../l10n/app_localizations.dart';

/// The home-screen widget (docs/API.md 홈 화면 위젯): Dart writes one pre-formatted, pre-translated JSON under `summary`;
/// the native widgets (iOS `EvensiesWidget`, Android `BalanceWidgetProvider`) only draw it.
const widgetAppGroup = 'group.dev.nariinfo.evensies';
const widgetKey = 'summary';

/// The payload: [overview] per currency in `lines` (net = owed to me − I owe, zeros dropped, the largest first as on the
/// Friends tab, at most 4), plus one `≈` line in [home] as `total` when there are several currencies and every one
/// converts (small widgets show the total, medium ones the total and the lines); [signedIn] false and all-zero have no
/// lines but a sentence, and signed out has no "Updated" time either.
Map<String, Object?> widgetSummary(
  AppLocalizations l, {
  required bool signedIn,
  required Overview overview,
  required String home,
  Map<String, double>? perEur,
  required DateTime now,
  String? locale,
}) {
  if (!signedIn) return {'v': 1, 'total': null, 'lines': const [], 'empty': l.widgetSignedOut, 'updated': null};
  final updated = l.widgetUpdated(DateFormat.MMMd(locale).add_jm().format(now));
  final net = <String, int>{
    for (final c in {...overview.owedToMe.keys, ...overview.iOwe.keys})
      if ((overview.owedToMe[c] ?? 0) - (overview.iOwe[c] ?? 0) case final v when v != 0) c: v,
  };
  if (net.isEmpty) return {'v': 1, 'total': null, 'lines': const [], 'empty': l.widgetSettled, 'updated': updated};
  Map<String, String> line(int v, String amount) =>
      {'text': v > 0 ? l.widgetOwed : l.widgetOwe, 'amount': amount, 'tone': v > 0 ? 'owed' : 'owe'};
  final total = net.length > 1 ? approxIn(home, net, perEur) : null;
  final order = <String>[];
  final left = {...net};
  while (left.isNotEmpty && order.length < 4) {
    final c = largestCurrency(left, perEur);
    order.add(c);
    left.remove(c);
  }
  return {
    'v': 1,
    'total': total == null || total == 0 ? null : line(total, '≈ ${formatMoney(total.abs(), home)}'),
    'lines': [for (final c in order) line(net[c]!, formatMoney(net[c]!.abs(), c))],
    'empty': null,
    'updated': updated,
  };
}

/// Writes [widgetSummary] payloads: only when the content changed, then asks the widgets to redraw. Nothing on the web.
class WidgetWriter {
  final Future<void> Function(String json) _save;
  final bool _web;
  WidgetWriter({Future<void> Function(String json)? save, @visibleForTesting bool web = kIsWeb})
      : _save = save ?? _homeWidget,
        _web = web;

  String? _last;

  /// Only the parts people see, without `updated` (which changes every minute): a new time alone is no new content.
  Future<void> write(Map<String, Object?> payload) async {
    if (_web) return;
    final content = jsonEncode({...payload}..remove('updated'));
    if (content == _last) return;
    _last = content;
    try {
      await _save(jsonEncode(payload));
    } catch (_) {
      _last = null; // no widget support here (tests, an old launcher): try again next time
    }
  }

  static Future<void> _homeWidget(String json) async {
    await HomeWidget.setAppGroupId(widgetAppGroup);
    await HomeWidget.saveWidgetData<String>(widgetKey, json);
    await HomeWidget.updateWidget(iOSName: 'EvensiesWidget', androidName: 'BalanceWidgetProvider');
  }
}

/// Runs [action] once things are quiet for [delay] (1 s for the widget: many rows change during a sync).
class Debouncer {
  final Duration delay;
  Timer? _t;
  Debouncer(this.delay);
  void call(void Function() action) {
    _t?.cancel();
    _t = Timer(delay, action);
  }

  void cancel() => _t?.cancel();
}
