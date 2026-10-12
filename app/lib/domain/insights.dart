/// Insights and search over the local group state (docs/API.md 인사이트, 검색). Pure Dart.
library;

import '../core/money.dart';
import '../l10n/app_localizations.dart';
import 'balances.dart' show convertToDefault;
import 'categories.dart';
import 'models.dart';

typedef MemberTotals = ({int paid, int share});

/// Totals of one period in one currency bucket.
class PeriodTotals {
  final int spent, youPaid, yourShare, paymentsMade, paymentsReceived;

  /// resolveCategory key → amount; no zero entries.
  final Map<String, int> byCategory;

  /// memberId → what they paid and their share; no member with both at zero.
  final Map<String, MemberTotals> byMember;
  const PeriodTotals({
    this.spent = 0,
    this.youPaid = 0,
    this.yourShare = 0,
    this.paymentsMade = 0,
    this.paymentsReceived = 0,
    this.byCategory = const {},
    this.byMember = const {},
  });

  static const zero = PeriodTotals();

  /// Change in my balance over the period.
  int get netChange => youPaid - yourShare + paymentsMade - paymentsReceived;

  bool get isEmpty =>
      spent == 0 && youPaid == 0 && yourShare == 0 && paymentsMade == 0 && paymentsReceived == 0 && byMember.isEmpty;

  PeriodTotals operator +(PeriodTotals o) {
    final cat = {...byCategory};
    for (final e in o.byCategory.entries) {
      cat[e.key] = (cat[e.key] ?? 0) + e.value;
    }
    final mem = {...byMember};
    for (final e in o.byMember.entries) {
      final a = mem[e.key] ?? (paid: 0, share: 0);
      mem[e.key] = (paid: a.paid + e.value.paid, share: a.share + e.value.share);
    }
    return PeriodTotals(
      spent: spent + o.spent,
      youPaid: youPaid + o.youPaid,
      yourShare: yourShare + o.yourShare,
      paymentsMade: paymentsMade + o.paymentsMade,
      paymentsReceived: paymentsReceived + o.paymentsReceived,
      byCategory: {for (final e in cat.entries) if (e.value != 0) e.key: e.value},
      byMember: {for (final e in mem.entries) if (e.value.paid != 0 || e.value.share != 0) e.key: e.value},
    );
  }
}

/// memberId → what they paid (for a refund: received), from the stored payers.
Map<String, int> paidAmounts(Expense e) {
  final m = <String, int>{};
  for (final p in e.payers) {
    m[p.memberId] = (m[p.memberId] ?? 0) + p.amount;
  }
  return m;
}

final _monthKey = RegExp(r'^\d{4}-\d{2}');

/// The `YYYY-MM` of [date], or null when it doesn't start like one (the server's date check lets `+10000-01-01`
/// through).
String? monthOf(String date) => _monthKey.firstMatch(date)?[0];

/// Totals per month (`YYYY-MM`) and for all time, for expenses and payments already in one currency (one bucket of
/// [insightBuckets]). A refund counts with sign −1. Payments count only in made/received for [me]. A date without a
/// month ([monthOf]) counts in all time only.
({Map<String, PeriodTotals> months, PeriodTotals allTime}) computeTotals(List<Expense> expenses, List<Payment> payments,
    {required String? me}) {
  final months = <String, PeriodTotals>{};
  var allTime = PeriodTotals.zero;
  void add(String date, PeriodTotals t) {
    allTime += t;
    final m = monthOf(date);
    if (m != null) months[m] = (months[m] ?? PeriodTotals.zero) + t;
  }

  for (final e in expenses.where((e) => !e.deleted)) {
    final sign = e.refund ? -1 : 1;
    final paid = paidAmounts(e);
    final share = <String, int>{};
    for (final s in e.shares) {
      share[s.memberId] = (share[s.memberId] ?? 0) + s.amount;
    }
    add(
      e.date,
      PeriodTotals(
        spent: sign * e.amount,
        youPaid: sign * (paid[me] ?? 0),
        yourShare: sign * (share[me] ?? 0),
        byCategory: {resolveCategory(e.category): sign * e.amount},
        byMember: {
          for (final m in {...paid.keys, ...share.keys}) m: (paid: sign * (paid[m] ?? 0), share: sign * (share[m] ?? 0)),
        },
      ),
    );
  }
  for (final p in payments.where((p) => !p.deleted && (p.status == 'sent' || p.status == 'confirmed'))) {
    add(
      p.date,
      PeriodTotals(
        paymentsMade: p.fromMember == me ? p.amount : 0,
        paymentsReceived: p.toMember == me ? p.amount : 0,
      ),
    );
  }
  return (months: months, allTime: allTime);
}

typedef Bucket = ({List<Expense> expenses, List<Payment> payments});

/// Insights per currency bucket, like Balances (docs/API.md 인사이트): the group currency D first with the converted
/// expenses and D payments, then every other currency X with its unconverted X expenses and X payments. Nothing is
/// dropped: a foreign expense convertExpense can't convert stays in its own bucket.
Map<String, Bucket> insightBuckets(GroupState s) {
  final d = s.defaultCurrency ?? '';
  final (:converted, :unconverted) = convertToDefault(s);
  final pays = <String, List<Payment>>{};
  for (final p in s.payments.where((p) => !p.deleted)) {
    pays.putIfAbsent(p.currency, () => []).add(p);
  }
  final others = ({...unconverted.keys, ...pays.keys}..remove(d)).toList()..sort();
  return {
    d: (expenses: converted, payments: pays[d] ?? const []),
    for (final x in others) x: (expenses: unconverted[x] ?? const [], payments: pays[x] ?? const []),
  };
}

/// One expense as search sees it (docs/API.md 검색): [comments] = texts of non-deleted comments, [category] = the
/// stored value, [amount] in the expense's own currency.
class SearchDoc {
  final String id;
  final String? groupId;
  final String date;
  final String description;
  final String? notes;
  final List<String> comments;
  final String? category;
  final int amount;
  final String currency;
  const SearchDoc({
    required this.id,
    this.groupId,
    required this.date,
    required this.description,
    this.notes,
    this.comments = const [],
    this.category,
    required this.amount,
    required this.currency,
  });

  factory SearchDoc.fromJson(Map<String, dynamic> j) => SearchDoc(
        id: j['id'] as String,
        groupId: j['groupId'] as String?,
        date: j['date'] as String,
        description: j['description'] as String,
        notes: j['notes'] as String?,
        comments: ((j['comments'] as List?) ?? const []).cast<String>(),
        category: j['category'] as String?,
        amount: (j['amount'] as num).toInt(),
        currency: j['currency'] as String,
      );

  /// Every non-deleted expense of [s].
  static List<SearchDoc> of(String groupId, GroupState s) {
    final comments = <String, List<String>>{};
    for (final c in s.comments.where((c) => !c.deleted && c.expenseId != null)) {
      comments.putIfAbsent(c.expenseId!, () => []).add(c.text);
    }
    return [
      for (final e in s.expenses.where((e) => !e.deleted))
        SearchDoc(
          id: e.id,
          groupId: groupId,
          date: e.date,
          description: e.description,
          notes: e.notes,
          comments: comments[e.id] ?? const [],
          category: e.category,
          amount: e.amount,
          currency: e.currency,
        ),
    ];
  }
}

final _amountTerm = RegExp(r'^\d+([.,]\d{1,3})?$');

/// Query terms (split on whitespace) of [query]; empty for a blank query.
List<String> searchTerms(String query) => query.trim().split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

/// Whether [term] matches [d]'s amount: `12` = 12.00–12.99, `12,5` = 12.50–12.59, `12,50` = 12.50.
bool _amountMatches(String term, SearchDoc d) {
  if (!_amountTerm.hasMatch(term)) return false;
  final parts = term.split(RegExp('[.,]'));
  final k = parts.length > 1 ? parts[1].length : 0;
  final digits = Money.digits(d.currency);
  final n = int.tryParse(parts.join());
  if (n == null || k > digits) return false;
  var div = 1;
  for (var i = 0; i < digits - k; i++) {
    div *= 10;
  }
  return d.amount ~/ div == n;
}

/// The folded text fields [term] may match in, in this order: description, notes, comments, raw category, label,
/// parent label.
List<String> _fields(SearchDoc d) {
  final c = Categories.byKey(resolveCategory(d.category));
  return [
    d.description,
    ?d.notes,
    ...d.comments,
    ?d.category,
    // The names as the UI shows them (docs/API.md 카테고리: search reads the UI language's).
    ?(c == null ? null : Categories.nameOf(c.key)),
    ?(c == null ? null : Categories.nameOf(c.parent)),
  ].map(fold).toList();
}

/// Whether [d] passes the [category] (a key, or a parent key) and [month] (`YYYY-MM`) filters.
bool _filtered(SearchDoc d, String? category, String? month) {
  if (month != null && monthOf(d.date) != month) return false;
  if (category == null) return true;
  final r = resolveCategory(d.category);
  return category.contains('.') ? r == category : r.startsWith('$category.');
}

/// Ids of the docs where every term of [query] matches and the filters pass, date descending then id ascending.
/// A blank query without a filter finds nothing. ponytail: a linear scan behind a 150 ms debounce; move to SQLite FTS5
/// past about 20k expenses.
List<String> searchDocs(List<SearchDoc> docs, String query, {String? category, String? month}) {
  final terms = searchTerms(query);
  if (terms.isEmpty && category == null && month == null) return const [];
  final folded = terms.map(fold).toList();
  bool matches(SearchDoc d) {
    final f = _fields(d);
    for (var i = 0; i < terms.length; i++) {
      if (!f.any((x) => x.contains(folded[i])) && !_amountMatches(terms[i], d)) return false;
    }
    return true;
  }

  final hits = [
    for (final d in docs)
      if (_filtered(d, category, month) && matches(d)) d,
  ]..sort((a, b) => a.date != b.date ? b.date.compareTo(a.date) : a.id.compareTo(b.id));
  return [for (final d in hits) d.id];
}

/// The note or comment that holds a query term, for the result row; null when the match is elsewhere.
String? searchExcerpt(SearchDoc d, String query) {
  final terms = searchTerms(query).map(fold).toList();
  if (terms.isEmpty) return null;
  for (final t in [?d.notes, ...d.comments]) {
    if (terms.any(fold(t).contains)) return t;
  }
  return null;
}

/// The share-sheet summary of one period (docs Phase 5 "Share summary"): totals per currency bucket, the top
/// categories of the group currency, and today's balances. [balances] = memberId → balance in [currency].
String insightsSummary(
  AppLocalizations l, {
  required String group,
  required String period,
  required String currency,
  required Map<String, PeriodTotals> totals,
  required Map<String, String> names,
  Map<String, int> balances = const {},
}) {
  final b = StringBuffer('$group · $period\n');
  for (final MapEntry(key: cur, value: t) in totals.entries) {
    if (cur != currency && t.isEmpty) continue;
    String m(int v) => formatMoney(v, cur);
    b.writeln();
    if (cur != currency) b.writeln(l.summaryNotConverted(cur));
    b.writeln(l.summaryTotalSpent(m(t.spent)));
    b.writeln(l.summaryPaidShare(m(t.youPaid), m(t.yourShare)));
    if (t.paymentsMade != 0 || t.paymentsReceived != 0) {
      b.writeln(l.summaryPayments(m(t.paymentsMade), m(t.paymentsReceived)));
    }
    if (cur == currency && t.byCategory.isNotEmpty) {
      final top = (t.byCategory.entries.toList()..sort((x, y) => y.value.compareTo(x.value))).take(3);
      b.writeln(l.summaryTopCategories(top.map((e) => '${Categories.labelOf(e.key)} ${m(e.value)}').join(l.listJoiner)));
    }
  }
  final owing = balances.entries.where((e) => e.value != 0).toList()..sort((x, y) => y.value.compareTo(x.value));
  if (owing.isNotEmpty) {
    b.writeln();
    b.writeln(l.summaryBalancesToday); // not the period's: a month summary would read them as that month's
    for (final e in owing) {
      final name = names[e.key] ?? '?', amount = formatMoney(e.value.abs(), currency);
      b.writeln(e.value > 0 ? l.summaryGetsBack(name, amount) : l.summaryOwes(name, amount));
    }
  }
  b.write('\n${l.summaryFooter}');
  return b.toString();
}
