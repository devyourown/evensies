/// Repeating expenses (docs/API.md, Recurring expenses): the schedule's dates and the series helpers the screens use.
/// shared/recurrence-cases.json checks the dates against the server's Schedule.kt.
library;

import '../core/money.dart';
import '../core/strings.dart';
import '../l10n/app_localizations.dart';
import 'models.dart';

/// The four schedules, in the order the Repeat menu shows them.
const frequencies = ['weekly', 'biweekly', 'monthly', 'yearly'];

/// "Every month" for the Repeat menu; null (no series) is "Never".
String repeatLabel(AppLocalizations l, String? frequency) => switch (frequency) {
      'weekly' => l.repeatWeekly,
      'biweekly' => l.repeatBiweekly,
      'monthly' => l.repeatMonthly,
      'yearly' => l.repeatYearly,
      _ => l.repeatNever,
    };

/// "every 2 weeks" in sentences ("repeats every 2 weeks", shared/strings.json `words.frequency`); an unknown value as
/// it is.
String frequencyWord(String? frequency, {String? lang}) =>
    Strings.lookup(lang ?? Money.lang, ['words', 'frequency', frequency ?? '']) as String? ?? frequency ?? '';

/// The date of occurrence [n] (0 = [startDate]), always counted from [startDate] so a clamped month end never sticks:
/// monthly from Jan 31 gives Feb 28, then Mar 31. A day the month doesn't have is its last day. UTC dates only: local
/// arithmetic loses a day across DST, and `DateTime(y, m + 1, 31)` overflows into the next month.
String occurrenceDate(String frequency, String startDate, int n) {
  final s = DateTime.parse('${startDate}T00:00:00Z');
  DateTime clamped(int year, int month) {
    final y = year + (month - 1) ~/ 12, m = (month - 1) % 12 + 1;
    final last = DateTime.utc(y, m + 1, 0).day;
    return DateTime.utc(y, m, s.day < last ? s.day : last);
  }

  final d = switch (frequency) {
    'weekly' => DateTime.utc(s.year, s.month, s.day + 7 * n),
    'biweekly' => DateTime.utc(s.year, s.month, s.day + 14 * n),
    'monthly' => clamped(s.year, s.month + n),
    'yearly' => clamped(s.year + n, s.month),
    _ => throw ArgumentError.value(frequency, 'frequency'),
  };
  return d.toIso8601String().substring(0, 10);
}

/// The first occurrence n ≥ [minN] on or after [onOrAfter] (YYYY-MM-DD). Never 0 (the series' own first expense).
/// ponytail: counts up from minN; a weekly series years old takes a few hundred steps.
({int n, String date}) firstOccurrenceOnOrAfter(String frequency, String startDate, String onOrAfter, {int minN = 1}) {
  for (var n = minN < 1 ? 1 : minN;; n++) {
    final d = occurrenceDate(frequency, startDate, n);
    if (d.compareTo(onOrAfter) >= 0) return (n: n, date: d);
  }
}

extension Series on GroupState {
  /// A series that exists here and isn't stopped.
  bool isActive(String? recurrenceId) => recurrenceId != null && recurrence(recurrenceId)?.deleted == false;

  /// The series' latest repeat: its live expense with the highest occurrence (the one whose edits can carry forward).
  Expense? latestRepeat(String recurrenceId) {
    Expense? best;
    for (final e in expenses) {
      if (e.deleted || e.recurrenceId != recurrenceId) continue;
      if (best == null || (e.occurrence ?? 0) > (best.occurrence ?? 0)) best = e;
    }
    return best;
  }

  /// The highest occurrence among the series' expenses, deleted ones included (0 when none is here).
  int lastPosted(String recurrenceId) => expenses
      .where((e) => e.recurrenceId == recurrenceId)
      .fold(0, (a, e) => (e.occurrence ?? 0) > a ? e.occurrence! : a);

  /// The active series whose template still has [memberId] paying or owing more than 0.
  List<Recurrence> seriesWith(String memberId) => [
        for (final r in recurrences)
          if (!r.deleted &&
              [...?r.template['payers'] as List?, ...?r.template['shares'] as List?]
                  .any((x) => x is Map && x['memberId'] == memberId && (x['amount'] as num? ?? 0) > 0))
            r,
      ];

  /// Why I can't leave yet (docs/API.md, Groups: leaving a group), next to `leaveBlocker`: a live series still charging or paying
  /// [me] would keep adding my share after I'm gone, a debt nobody can settle with me.
  String? seriesBlocker(AppLocalizations l, String? me) {
    final s = me == null ? const <Recurrence>[] : seriesWith(me);
    if (s.isEmpty) return null;
    return l.leaveSeries(s.length, seriesNames(l, s));
  }
}

/// "Rent, Netflix, Gym and 2 more": at most three names, in [series]' (creation) order.
String seriesNames(AppLocalizations l, List<Recurrence> series) {
  final names = [for (final r in series.take(3)) r.description ?? l.seriesUnnamed].join(l.listJoiner);
  return series.length > 3 ? l.seriesNamesMore(names, series.length - 3) : names;
}
