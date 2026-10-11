import '../core/core_guard.dart';
import '../core/money.dart';
import 'fx.dart';
import 'models.dart';
import 'settlement.dart';

typedef BalanceFn = Map<String, int> Function(List<String> members, List<ExpenseLine> lines, List<PaymentLine> payments);
typedef ConvertFn = ConvertedExpense Function({
  required int amount,
  required Map<String, int> parts,
  required int fromDecimals,
  required int toDecimals,
  required double rate,
});

/// Runs a conversion; null while Hyojun's function is a stub (UnimplementedError) or when it refuses (FxException).
T? tryFx<T>(T Function() f) {
  try {
    return tryCore(f);
  } on FxException {
    return null;
  }
}

/// Balances per currency (docs/API.md 통화별 잔액). D = [currency], the group's default currency.
class BalanceResult {
  final String currency;

  /// currency → memberId → balance (positive = gets back). D always present; another currency only while someone's
  /// balance in it isn't zero. Every bucket sums to 0.
  final Map<String, Map<String, int>> byCurrency;

  /// What each bucket was computed from (Settle up reuses them for pairwise debts).
  final Map<String, List<ExpenseLine>> lines;
  final Map<String, List<PaymentLine>> payments;

  /// currency → number of expenses left in their own currency (no rate, or the conversion couldn't run).
  final Map<String, int> unconverted;

  /// currency → how many of those have no rate (null or 0): what Convert fills in. The rest have a rate that can't be
  /// used yet (convertExpense is a TODO(효준) stub, or it refused).
  final Map<String, int> unrated;

  /// Expenses with several payers or a refund that computeBalances refused as unimplemented; left out (0 since it
  /// counts them).
  final int unsupported;
  final List<String> members;
  const BalanceResult({
    required this.currency,
    required this.byCurrency,
    this.lines = const {},
    this.payments = const {},
    this.unconverted = const {},
    this.unrated = const {},
    this.unsupported = 0,
    this.members = const [],
  });

  /// The bucket in D.
  Map<String, int> get balances => byCurrency[currency] ?? const {};

  /// Currencies other than D that have a bucket or an unconverted expense, sorted.
  List<String> get others => ({...byCurrency.keys, ...unconverted.keys}..remove(currency)).toList()..sort();

  /// My balance per bucket, zeros left out (D first).
  Map<String, int> mine(String? me) => {
        for (final e in byCurrency.entries)
          if ((e.value[me] ?? 0) != 0) e.key: e.value[me]!,
      };

  /// What Settle up shows, per bucket: fewest payments, or debts as recorded when the group turned simplifying off.
  /// A bucket whose transfers can't be computed (a stub that throws UnimplementedError) is left out.
  Map<String, List<Transfer>> transfers({required bool simplify}) => {
        for (final MapEntry(key: cur, value: b) in byCurrency.entries)
          cur: ?tryCore(() =>
              simplify ? simplifyDebts(b) : pairwiseDebts(members, lines[cur] ?? const [], payments[cur] ?? const [])),
      };
}

/// Expenses converted into D (amount, shares and payers via convertExpense; currency = D, fxRateToDefault = null),
/// and the non-deleted expenses left in their own currency. Insights (Phase 5) and balancesOf both use it.
({List<Expense> converted, Map<String, List<Expense>> unconverted}) convertToDefault(GroupState s,
    {ConvertFn convert = convertExpense}) {
  final d = s.defaultCurrency ?? '';
  final converted = <Expense>[];
  final unconverted = <String, List<Expense>>{};
  for (final e in s.expenses.where((e) => !e.deleted)) {
    // Rule 1: in D as it is, a stray rate ignored. Rules 2–3: a foreign expense converts only with a rate > 0.
    final c = e.currency == d ? e.copyWith(clearFx: true) : _convert(e, d, convert);
    if (c != null) {
      converted.add(c);
    } else {
      unconverted.putIfAbsent(e.currency, () => []).add(e);
    }
  }
  return (converted: converted, unconverted: unconverted);
}

/// Shares and payers each through [convert] (their totals are the same); null if either can't be converted.
Expense? _convert(Expense e, String d, ConvertFn convert) {
  final rate = e.fxRateToDefault;
  if (rate == null || !(rate > 0)) return null;
  ConvertedExpense? run(List<Share> list) => tryFx(() => convert(
        amount: e.amount,
        parts: {for (final x in list) x.memberId: x.amount},
        fromDecimals: Money.digits(e.currency),
        toDecimals: Money.digits(d),
        rate: rate,
      ));
  List<Share> back(List<Share> list, ConvertedExpense c) =>
      [for (final x in list) Share(memberId: x.memberId, amount: c.parts[x.memberId] ?? 0)];

  final shares = run(e.shares);
  final payers = run(e.payers);
  if (shares == null || payers == null) return null;
  return e.copyWith(
    amount: shares.amount,
    currency: d,
    clearFx: true,
    shares: back(e.shares, shares),
    payers: back(e.payers, payers),
  );
}

/// computeBalances per bucket (rules in docs/API.md 통화별 잔액). Payments go to the bucket of their own currency
/// (Settle up always records them in D). While [compute] can't handle several payers or refunds, those lines are left
/// out and counted as unsupported. Null only if [compute] throws UnimplementedError even for single-payer lines.
BalanceResult? balancesOf(GroupState s, {BalanceFn compute = computeBalances, ConvertFn convert = convertExpense}) {
  final d = s.defaultCurrency ?? '';
  final (:converted, :unconverted) = convertToDefault(s, convert: convert);
  final expensesBy = <String, List<Expense>>{d: converted, ...unconverted};
  final paymentsBy = <String, List<PaymentLine>>{};
  for (final p in s.payments.where((p) => !p.deleted)) {
    paymentsBy.putIfAbsent(p.currency, () => []).add(PaymentLine(from: p.fromMember, to: p.toMember, amount: p.amount));
  }
  final ids = s.members.map((m) => m.id).toList();
  final byCurrency = <String, Map<String, int>>{};
  final lines = <String, List<ExpenseLine>>{};
  final payments = <String, List<PaymentLine>>{};
  var unsupported = 0;
  for (final cur in {d, ...expensesBy.keys, ...paymentsBy.keys}) {
    final all = [
      for (final e in expensesBy[cur] ?? const <Expense>[])
        ExpenseLine(
          payers: {for (final p in e.payers) p.memberId: p.amount},
          amount: e.amount,
          shares: {for (final sh in e.shares) sh.memberId: sh.amount},
          refund: e.refund,
        ),
    ];
    final pays = paymentsBy[cur] ?? const <PaymentLine>[];
    var used = all;
    var b = tryCore(() => compute(ids, all, pays));
    if (b == null) {
      used = [for (final l in all) if (l.payers.length == 1 && !l.refund) l];
      b = tryCore(() => compute(ids, used, pays));
      if (b == null) return null;
      unsupported += all.length - used.length;
    }
    if (cur != d && b.values.every((v) => v == 0)) continue; // rule 5
    byCurrency[cur] = b;
    lines[cur] = used;
    payments[cur] = pays;
  }
  return BalanceResult(
    currency: d,
    byCurrency: byCurrency,
    lines: lines,
    payments: payments,
    unconverted: {for (final e in unconverted.entries) e.key: e.value.length},
    unrated: {
      for (final e in unconverted.entries)
        if (e.value.where((x) => !((x.fxRateToDefault ?? 0) > 0)).length case final n when n > 0) e.key: n,
    },
    unsupported: unsupported,
    members: ids,
  );
}

/// What Settle up shows, per currency: simplifyDebts(bucket) or, with simplify off, pairwiseDebts(bucket lines,
/// payments). Settle up, the Phase 6 overview and the Phase 9 widget all read this one function.
Map<String, List<Transfer>> groupTransfers(GroupState s) =>
    balancesOf(s)?.transfers(simplify: s.simplifyDebts) ?? const {};

/// Why [me] can't leave yet, or null when my balance is zero in every bucket and every expense is counted. Only the
/// app checks it (docs/API.md 그룹 나가기): the settings screen before the tap, LocalWrites.leaveGroup after its sync.
/// Unconverted expenses alone don't block leaving.
String? leaveBlocker(BalanceResult? res, String? me) {
  if (res == null) return "Balances can't be computed yet";
  if (res.unsupported > 0) return "Some expenses aren't counted in balances yet";
  for (final MapEntry(key: cur, value: mine) in res.mine(me).entries) {
    final m = formatMoney(mine.abs(), cur);
    final tail = cur == res.currency
        ? 'settle up first'
        : fxReady
            ? 'convert it and settle up first'
            : 'it can be settled once converting to ${res.currency} is ready';
    return mine < 0 ? 'You owe $m · $tail' : 'You are owed $m · $tail';
  }
  return null;
}

/// Who should pay next (docs/API.md 인사이트): the active member with the most negative balance in [defaultBucket],
/// the lowest memberId on a tie; null when nobody owes.
String? whoPaysNext(Map<String, int> defaultBucket, Set<String> activeMemberIds) {
  String? who;
  for (final MapEntry(key: m, value: v) in defaultBucket.entries) {
    if (v >= 0 || !activeMemberIds.contains(m)) continue;
    final w = defaultBucket[who] ?? 0;
    if (who == null || v < w || (v == w && m.compareTo(who) < 0)) who = m;
  }
  return who;
}
