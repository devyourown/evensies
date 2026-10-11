import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/money.dart';
import '../../domain/categories.dart';
import '../../domain/insights.dart';
import '../../providers.dart';
import '../categories/category_ui.dart';
import '../group_detail/balances.dart';

typedef Totals = ({Map<String, PeriodTotals> months, PeriodTotals allTime});

/// Totals per currency bucket of one group (docs/API.md 인사이트), the group currency first.
final insightsProvider = FutureProvider.family<Map<String, Totals>, String>((ref, id) async {
  final s = await ref.watch(groupStateProvider(id).future);
  final me = (await ref.watch(groupProvider(id).future))?.myMemberId;
  return {
    for (final MapEntry(key: cur, value: b) in insightBuckets(s).entries)
      cur: computeTotals(b.expenses, b.payments, me: me),
  };
});

DateTime? _monthStart(String m) =>
    monthOf(m) == m ? DateTime(int.parse(m.substring(0, 4)), int.parse(m.substring(5))) : null;

/// Every month from the first to the last with data (`YYYY-MM`), so the bars show the gaps too; other keys are skipped.
List<String> monthRange(Iterable<String> keys) {
  final sorted = keys.where((m) => _monthStart(m) != null).toList()..sort();
  if (sorted.isEmpty) return const [];
  final last = _monthStart(sorted.last)!;
  return [
    for (var d = _monthStart(sorted.first)!; !d.isAfter(last); d = DateTime(d.year, d.month + 1))
      '${d.year}-${d.month.toString().padLeft(2, '0')}',
  ];
}

/// "October 2026" for `2026-10`; anything else (a `?month=` link) as it is.
String monthLabel(String m, {String pattern = 'MMMM yyyy'}) {
  final d = _monthStart(m);
  return d == null ? m : DateFormat(pattern).format(d);
}

/// Group totals and charts (route `/groups/{id}/insights`): a period bar, totals, by month, by category, by person,
/// and one "Not converted" section per other currency.
class InsightsScreen extends ConsumerStatefulWidget {
  final String groupId;
  const InsightsScreen({super.key, required this.groupId});
  @override
  ConsumerState<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends ConsumerState<InsightsScreen> {
  String? _month; // null = all time
  bool _mine = false; // month bars: my share instead of the group's spending

  @override
  Widget build(BuildContext context) {
    final gid = widget.groupId;
    final group = ref.watch(groupProvider(gid)).valueOrNull;
    final async = ref.watch(insightsProvider(gid));
    final state = ref.watch(groupStateProvider(gid)).valueOrNull;
    final res = ref.watch(balancesProvider(gid)).valueOrNull; // Balances failing never hides Insights
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final buckets = async.valueOrNull;
    if (group == null || buckets == null || state == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Insights')),
        body: Center(
            child: async.hasError ? Text("Insights can't be shown: ${async.error}") : const CircularProgressIndicator()),
      );
    }
    final d = group.defaultCurrency;
    final main = buckets[d] ?? (months: const <String, PeriodTotals>{}, allTime: PeriodTotals.zero);
    final months = monthRange({for (final b in buckets.values) ...b.months.keys});
    final names = {for (final m in state.members) m.id: m.name};
    final month = months.contains(_month) ? _month : null;
    PeriodTotals pick(Totals t) => month == null ? t.allTime : t.months[month] ?? PeriodTotals.zero;
    final t = pick(main);

    if (months.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Insights')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.insights, size: 64, color: cs.primary),
              const SizedBox(height: 16),
              Text('Nothing to show yet', style: text.titleMedium),
              const SizedBox(height: 4),
              Text('Totals and charts appear once the group has expenses.',
                  textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant)),
            ]),
          ),
        ),
      );
    }

    final shown = month ?? months.last;
    final i = months.indexOf(shown);
    void go(String m) => setState(() => _month = m);
    final period = month == null ? 'All time' : monthLabel(month);

    Widget header(String s, {Widget? trailing}) => Padding(
          padding: const EdgeInsets.only(top: 28, bottom: 8),
          child: trailing == null
              ? Text(s, style: text.titleMedium)
              : _spread(Text(s, style: text.titleMedium), trailing),
        );

    final unsupported = res?.unsupported ?? 0;
    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Insights'),
          Text(group.name, style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
        ]),
        actions: [
          IconButton(
            tooltip: 'Share summary',
            icon: const Icon(Icons.ios_share),
            onPressed: () => SharePlus.instance.share(ShareParams(
              text: insightsSummary(
                group: group.name,
                period: period,
                currency: d,
                totals: {for (final MapEntry(key: cur, value: b) in buckets.entries) cur: pick(b)},
                names: names,
                balances: res?.balances ?? const {},
              ),
            )),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _spread(
            ChoiceChip(
              key: const Key('period-all'),
              label: const Text('All time'),
              selected: month == null,
              onSelected: (_) => setState(() => _month = null),
            ),
            Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(
                tooltip: 'Previous month',
                onPressed: i > 0 ? () => go(months[i - 1]) : null,
                icon: const Icon(Icons.chevron_left),
              ),
              Flexible(
                child: ChoiceChip(
                  key: const Key('period-month'),
                  label: Text(monthLabel(shown, pattern: 'MMM yyyy')),
                  selected: month != null,
                  onSelected: (_) => go(shown),
                ),
              ),
              IconButton(
                tooltip: 'Next month',
                onPressed: i < months.length - 1 ? () => go(months[i + 1]) : null,
                icon: const Icon(Icons.chevron_right),
              ),
            ]),
          ),
          if (unsupported > 0)
            Card(
              color: cs.tertiaryContainer,
              child: ListTile(
                leading: Icon(Icons.construction, color: cs.onTertiaryContainer),
                title: Text(
                    '$unsupported expense${unsupported == 1 ? '' : 's'} with several payers or refunds '
                    "${unsupported == 1 ? "isn't" : "aren't"} counted in Balances yet",
                    style: TextStyle(color: cs.onTertiaryContainer)),
                subtitle: Text('They are in these totals, so the change in your balance can differ from Balances.',
                    style: TextStyle(color: cs.onTertiaryContainer)),
              ),
            ),
          const SizedBox(height: 8),
          _TotalsCard(totals: t, currency: d),
          header('By month',
              trailing: SegmentedButton<bool>(
                showSelectedIcon: false,
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
                segments: const [
                  ButtonSegment(value: false, label: Text('Group')),
                  ButtonSegment(value: true, label: Text('Mine')),
                ],
                selected: {_mine},
                onSelectionChanged: (v) => setState(() => _mine = v.first),
              )),
          _MonthBars(
            // At most the latest 24; the row scrolls sideways and starts at the newest.
            months: months.length > 24 ? months.sublist(months.length - 24) : months,
            values: {for (final m in months) m: _mine ? main.months[m]?.yourShare ?? 0 : main.months[m]?.spent ?? 0},
            currency: d,
            selected: month,
            onTap: go,
          ),
          header('By category'),
          if (t.byCategory.isEmpty)
            Text('No expenses in this period.', style: TextStyle(color: cs.onSurfaceVariant))
          else
            _Categories(
              byCategory: t.byCategory,
              currency: d,
              onTap: (key) => context.push(
                  Uri(path: '/search', queryParameters: {'group': gid, 'category': key, 'month': ?month}).toString()),
            ),
          header('By person'),
          if (t.byMember.isEmpty)
            Text('Nobody paid or owed anything in this period.', style: TextStyle(color: cs.onSurfaceVariant))
          else
            _People(byMember: t.byMember, names: names, me: group.myMemberId, currency: d),
          for (final MapEntry(key: cur, value: b) in buckets.entries)
            if (cur != d && !pick(b).isEmpty) ...[
              header('Not converted · $cur'),
              Text('Kept in $cur until it is converted to $d.',
                  style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 8),
              _TotalsCard(key: Key('totals-$cur'), totals: pick(b), currency: cur),
            ],
        ],
      ),
    );
  }
}

/// [label] at the start and [value] at the end of one line, or [value] on the next line when both don't fit
/// (the largest text sizes).
Widget _spread(Widget label, Widget value) => SizedBox(
      width: double.infinity,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        children: [label, value],
      ),
    );

class _TotalsCard extends StatelessWidget {
  final PeriodTotals totals;
  final String currency;
  const _TotalsCard({super.key, required this.totals, required this.currency});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final t = totals;
    Widget row(String label, int v, {bool big = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: _spread(
            Text(label, style: big ? text.titleMedium : text.bodyMedium),
            Text(formatMoney(v, currency),
                style: (big ? text.titleLarge : text.bodyLarge)?.copyWith(fontWeight: big ? FontWeight.w600 : null)),
          ),
        );
    final net = t.netChange;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(children: [
          row('Total spent', t.spent, big: true),
          const Divider(),
          row('You paid', t.youPaid),
          row('Your share', t.yourShare),
          row('Payments made', t.paymentsMade),
          row('Payments received', t.paymentsReceived),
          const Divider(),
          _spread(
            Text('Change in your balance', style: text.bodyMedium),
            Text(
              '${net > 0 ? '+' : net < 0 ? '−' : ''}${formatMoney(net.abs(), currency)}',
              key: Key('net-$currency'),
              style: text.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600, color: net > 0 ? cs.primary : net < 0 ? cs.error : cs.onSurfaceVariant),
            ),
          ),
        ]),
      ),
    );
  }
}

/// Vertical bars from existing widgets (no chart package), each with its amount as text; negative months (refunds)
/// draw no bar but keep their amount.
class _MonthBars extends StatelessWidget {
  final List<String> months;
  final Map<String, int> values;
  final String currency;
  final String? selected;
  final ValueChanged<String> onTap;
  const _MonthBars(
      {required this.months, required this.values, required this.currency, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final top = months.fold(0, (a, m) => math.max(a, values[m] ?? 0));
    return SizedBox(
      height: 116 + MediaQuery.textScalerOf(context).scale(56), // room for the labels at large text sizes
      child: ListView(
        scrollDirection: Axis.horizontal,
        reverse: true, // newest at the right edge, in view
        children: [
          for (final m in months.reversed)
            InkWell(
              key: Key('bar-$m'),
              borderRadius: BorderRadius.circular(8),
              onTap: () => onTap(m),
              child: SizedBox(
                width: 60,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Column(children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(formatMoney(values[m] ?? 0, currency),
                          style: text.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: top == 0 ? 0 : math.max(0, values[m] ?? 0) / top,
                          child: Container(
                            width: 28,
                            decoration: BoxDecoration(
                              color: m == selected ? cs.primary : cs.primaryContainer,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(monthLabel(m, pattern: 'MMM'),
                        style: text.labelMedium?.copyWith(fontWeight: m == selected ? FontWeight.w700 : null)),
                    Text(monthLabel(m, pattern: 'yy'), style: text.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                  ]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Widget _bar(BuildContext context, int v, int top, Color color) => ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: LinearProgressIndicator(
        value: top <= 0 ? 0 : math.max(0, v) / top,
        minHeight: 6,
        color: color,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    );

/// Parent rows, largest first, that expand into their subcategories; a subcategory opens Search filtered to it.
class _Categories extends StatelessWidget {
  final Map<String, int> byCategory;
  final String currency;
  final ValueChanged<String> onTap;
  const _Categories({required this.byCategory, required this.currency, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final byParent = <String, Map<String, int>>{};
    for (final e in byCategory.entries) {
      byParent.putIfAbsent(e.key.split('.').first, () => {})[e.key] = e.value;
    }
    int sum(Map<String, int> m) => m.values.fold(0, (a, b) => a + b);
    final parents = byParent.entries.toList()..sort((a, b) => sum(b.value).compareTo(sum(a.value)));
    final top = parents.fold(0, (a, p) => math.max(a, sum(p.value)));
    return Column(children: [
      for (final p in parents)
        ExpansionTile(
          key: PageStorageKey('cat-${p.key}'),
          tilePadding: EdgeInsets.zero,
          shape: const Border(),
          leading: CategoryAvatar.parent(p.key),
          // The amount in the title, not trailing, so it wraps under the label at the largest text sizes.
          title: _spread(Text(Categories.parent(p.key)?.label ?? Categories.labelOf(p.key)),
              Text(formatMoney(sum(p.value), currency), style: Theme.of(context).textTheme.titleSmall)),
          subtitle: Padding(padding: const EdgeInsets.only(top: 6), child: _bar(context, sum(p.value), top, cs.primary)),
          children: [
            for (final c in p.value.entries.toList()..sort((a, b) => b.value.compareTo(a.value)))
              ListTile(
                key: Key('cat-row-${c.key}'),
                contentPadding: const EdgeInsets.only(left: 16),
                leading: CategoryAvatar(c.key, size: 32),
                title: _spread(Text(Categories.labelOf(c.key)), Text(formatMoney(c.value, currency))),
                subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6), child: _bar(context, c.value, top, cs.secondary)),
                trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                onTap: () => onTap(c.key),
              ),
          ],
        ),
    ]);
  }
}

/// What each member paid next to their share.
class _People extends StatelessWidget {
  final Map<String, MemberTotals> byMember;
  final Map<String, String> names;
  final String? me;
  final String currency;
  const _People({required this.byMember, required this.names, required this.me, required this.currency});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final rows = byMember.entries.toList()..sort((a, b) => b.value.paid.compareTo(a.value.paid));
    final top = rows.fold(0, (a, r) => math.max(a, math.max(r.value.paid, r.value.share)));
    Widget dot(Color c, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label, style: text.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(width: 12),
        ]);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [dot(cs.primary, 'Paid'), dot(cs.tertiary, 'Share')]),
      for (final r in rows)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _spread(
              Text(r.key == me ? 'You' : names[r.key] ?? 'Someone', maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('paid ${formatMoney(r.value.paid, currency)} · share ${formatMoney(r.value.share, currency)}',
                  style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            ),
            const SizedBox(height: 6),
            _bar(context, r.value.paid, top, cs.primary),
            const SizedBox(height: 3),
            _bar(context, r.value.share, top, cs.tertiary),
          ]),
        ),
    ]);
  }
}
