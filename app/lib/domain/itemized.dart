/// Itemized split (docs/API.md 항목별 분할, SplitSpec mode `itemized`): receipt lines, each split equally between its
/// people, with tax, tip and a discount spread by each person's subtotal. App only: the server never recomputes shares,
/// so there is no Kotlin twin (app/test/fixtures/itemized-cases.json).
library;

import 'dart:convert';

import 'split.dart';

class ItemLine {
  final String name;
  final int amount;
  final List<String> memberIds;
  const ItemLine({required this.name, required this.amount, required this.memberIds});

  /// Null when the shape is wrong (the app reads such a split as none).
  static ItemLine? fromJson(Object? j) {
    if (j is! Map || j['name'] is! String || j['amount'] is! num || j['memberIds'] is! List) return null;
    final ids = j['memberIds'] as List;
    if (ids.any((x) => x is! String)) return null;
    return ItemLine(name: j['name'] as String, amount: (j['amount'] as num).toInt(), memberIds: ids.cast<String>());
  }

  Map<String, dynamic> toJson() => {'name': name, 'amount': amount, 'memberIds': memberIds};
}

class ItemizedBill {
  final List<ItemLine> lines;
  final int tax, tip, discount;
  const ItemizedBill({required this.lines, this.tax = 0, this.tip = 0, this.discount = 0});

  /// Missing or null tax / tip / discount = 0; null when the shape is wrong.
  static ItemizedBill? fromJson(Object? j) {
    if (j is! Map || j['lines'] is! List) return null;
    final lines = [for (final l in j['lines'] as List) ItemLine.fromJson(l)];
    if (lines.contains(null)) return null;
    int? n(Object? v) => v == null ? 0 : (v is num ? v.toInt() : null);
    final tax = n(j['tax']), tip = n(j['tip']), discount = n(j['discount']);
    if (tax == null || tip == null || discount == null) return null;
    return ItemizedBill(lines: lines.cast<ItemLine>(), tax: tax, tip: tip, discount: discount);
  }

  /// Always writes tax, tip and discount (0 included): the server compares the raw JSON.
  Map<String, dynamic> toJson() =>
      {'lines': [for (final l in lines) l.toJson()], 'tax': tax, 'tip': tip, 'discount': discount};

  int get subtotal => lines.fold(0, (a, l) => a + l.amount);

  @override
  bool operator ==(Object other) => other is ItemizedBill && jsonEncode(other.toJson()) == jsonEncode(toJson());
  @override
  int get hashCode => jsonEncode(toJson()).hashCode;
}

/// Σ lines.amount + tax + tip − discount.
int itemizedTotal(ItemizedBill b) => b.subtotal + b.tax + b.tip - b.discount;

/// memberId → share for every member on any line (0 allowed); sums to [itemizedTotal]. Throws SplitException:
/// 1. any line amount, tax, tip or discount < 0 → NEGATIVE_AMOUNT (first); a line with no memberIds → UNASSIGNED_ITEM.
/// 2. Lines with the same set of people are added up first, then each such sum is computeSplit(equal) between its
///    people (remainder +1 to memberId ascending), so three 1.00 lines shared by a, b and c give 1.00 each, not
///    a 1.02. subtotal[m] = Σ m's parts, S = Σ subtotal.
/// 3. net = tax + tip − discount. S + net < 0 → NEGATIVE_TOTAL; S == 0 and net != 0 → ZERO_SUBTOTAL.
/// 4. extra[m] = floor(|net| × subtotal[m] / S) (BigInt product, exact on the web); the r = |net| − Σ extra left over
///    go +1 each to the first r members with a subtotal > 0 in memberId ascending order.
/// 5. share[m] = subtotal[m] + extra[m] when net ≥ 0, else subtotal[m] − extra[m] (never below zero).
Map<String, int> computeItemizedSplit(ItemizedBill b) {
  if ([b.tax, b.tip, b.discount, for (final l in b.lines) l.amount].any((v) => v < 0)) {
    throw SplitException('NEGATIVE_AMOUNT');
  }
  if (b.lines.any((l) => l.memberIds.isEmpty)) throw SplitException('UNASSIGNED_ITEM');
  // The same people (in any order; the server refuses duplicates, a set keeps one person from counting twice anyway)
  // → one sum, so a remainder isn't paid once per line by the same person.
  final sums = <String, (List<String>, int)>{};
  for (final l in b.lines) {
    final people = l.memberIds.toSet().toList()..sort();
    final key = people.join('\u0000');
    sums[key] = (people, (sums[key]?.$2 ?? 0) + l.amount);
  }
  final subtotal = <String, int>{};
  for (final (people, amount) in sums.values) {
    final parts = computeSplit(amount: amount, mode: SplitMode.equal, members: people);
    for (final MapEntry(:key, :value) in parts.entries) {
      subtotal[key] = (subtotal[key] ?? 0) + value;
    }
  }
  final s = b.subtotal;
  final net = b.tax + b.tip - b.discount;
  if (s + net < 0) throw SplitException('NEGATIVE_TOTAL');
  if (s == 0 && net != 0) throw SplitException('ZERO_SUBTOTAL');
  final ids = subtotal.keys.toList()..sort();
  final abs = net.abs();
  final extra = {
    for (final m in ids) m: s == 0 ? 0 : (BigInt.from(abs) * BigInt.from(subtotal[m]!) ~/ BigInt.from(s)).toInt(),
  };
  var left = abs - extra.values.fold(0, (a, v) => a + v);
  for (final m in ids) {
    if (left == 0) break;
    if (subtotal[m]! > 0) {
      extra[m] = extra[m]! + 1;
      left--;
    }
  }
  return {for (final m in ids) m: net >= 0 ? subtotal[m]! + extra[m]! : subtotal[m]! - extra[m]!};
}

/// UI only: [pct] % of [subtotal] in minor units, halves rounded up (a tip typed as 10 % is stored as its amount).
int percentOf(int subtotal, num pct) => (subtotal * pct / 100).round();
