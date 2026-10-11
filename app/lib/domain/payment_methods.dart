/// "Ways to get paid" (docs/API.md 결제 수단). Pure: no Flutter imports.
library;

import '../core/money.dart';

abstract final class PaymentTypes {
  static const paypal = 'paypal';
  static const wise = 'wise';
  static const venmo = 'venmo';
  static const revolut = 'revolut';
  static const kakaopay = 'kakaopay';
  static const iban = 'iban';
  static const krBank = 'kr_bank';
  static const all = [paypal, wise, venmo, revolut, kakaopay, iban, krBank];
}

class PaymentMethod {
  final String type;
  final String value;
  final String? holder;
  final String? bank;
  final String? bic;
  const PaymentMethod({required this.type, required this.value, this.holder, this.bank, this.bic});

  factory PaymentMethod.fromJson(Map<String, dynamic> j) => PaymentMethod(
        type: j['type'] as String,
        value: j['value'] as String,
        holder: j['holder'] as String?,
        bank: j['bank'] as String?,
        bic: j['bic'] as String?,
      );
  Map<String, dynamic> toJson() =>
      {'type': type, 'value': value, 'holder': ?holder, 'bank': ?bank, 'bic': ?bic};
}

String methodLabel(String type) => switch (type) {
      PaymentTypes.paypal => 'PayPal',
      PaymentTypes.wise => 'Wise',
      PaymentTypes.venmo => 'Venmo',
      PaymentTypes.revolut => 'Revolut',
      PaymentTypes.kakaopay => 'KakaoPay',
      PaymentTypes.iban => 'IBAN',
      PaymentTypes.krBank => 'Korean bank',
      _ => type,
    };

/// How many of [type] a user may have.
int maxPerType(String type) => type == PaymentTypes.iban || type == PaymentTypes.krBank ? 3 : 1;
const maxMethods = 8;

/// IBAN as stored: no spaces, upper case.
String normalizeIban(String s) => s.replaceAll(RegExp(r'\s'), '').toUpperCase();

final _username = RegExp(r'^[A-Za-z0-9._-]{1,40}$');

bool ibanValid(String iban) {
  if (!RegExp(r'^[A-Z]{2}\d{2}[A-Z0-9]{11,30}$').hasMatch(iban)) return false;
  final r = iban.substring(4) + iban.substring(0, 4);
  var mod = 0;
  for (final c in r.codeUnits) {
    final v = c >= 65 ? c - 55 : c - 48; // A=10 … Z=35
    mod = (v >= 10 ? mod * 100 + v : mod * 10 + v) % 97;
  }
  return mod == 1;
}

/// Error for one field (`value`, `holder`, `bank`, `bic`) of a method of [type], or null if valid.
/// Mirrors the validation table in docs/API.md; the server is the authority.
String? methodFieldError(String type, String field, String? input) {
  final v = input?.trim() ?? '';
  switch ((type, field)) {
    case (PaymentTypes.paypal || PaymentTypes.revolut || PaymentTypes.venmo, 'value'):
      return _username.hasMatch(v) ? null : 'Letters, digits, . _ - only (max 40)';
    case (PaymentTypes.wise, 'value'):
      return _link(v, 'https://wise.com/');
    case (PaymentTypes.kakaopay, 'value'):
      return _link(v, 'https://qr.kakaopay.com/');
    case (PaymentTypes.iban, 'value'):
      return ibanValid(normalizeIban(v)) ? null : 'Not a valid IBAN';
    case (PaymentTypes.iban || PaymentTypes.krBank, 'holder'):
      return v.isEmpty || v.length > 70 ? 'Account holder name (1–70 characters)' : null;
    case (PaymentTypes.iban, 'bic'):
      if (v.isEmpty) return null;
      return v.length == 8 || v.length == 11 ? null : 'BIC has 8 or 11 characters';
    case (PaymentTypes.krBank, 'value'):
      final digits = v.replaceAll('-', '');
      return RegExp(r'^[\d-]+$').hasMatch(v) && digits.length >= 8 && digits.length <= 20
          ? null
          : 'Digits and hyphens, 8–20 digits';
    case (PaymentTypes.krBank, 'bank'):
      return v.isEmpty || v.length > 30 ? 'Bank name (1–30 characters)' : null;
    default:
      return null;
  }
}

String? _link(String v, String prefix) {
  if (!v.startsWith(prefix)) return 'Must start with $prefix';
  return v.length > 200 ? 'Max 200 characters' : null;
}

/// First error in [m], or null.
String? methodError(PaymentMethod m) {
  if (!PaymentTypes.all.contains(m.type)) return 'Unknown type';
  for (final (f, v) in [('value', m.value), ('holder', m.holder), ('bank', m.bank), ('bic', m.bic)]) {
    final e = methodFieldError(m.type, f, v);
    if (e != null) return e;
  }
  return null;
}

/// Error for the whole list (per-method errors and limits), or null.
String? methodsError(List<PaymentMethod> ms) {
  if (ms.length > maxMethods) return 'At most $maxMethods ways to get paid';
  for (final t in PaymentTypes.all) {
    final n = ms.where((m) => m.type == t).length;
    if (n > maxPerType(t)) return 'At most ${maxPerType(t)} ${methodLabel(t)}';
  }
  for (final m in ms) {
    final e = methodError(m);
    if (e != null) return '${methodLabel(m.type)}: $e';
  }
  return null;
}

/// "15.00" for 1500 EUR, "15000" for 15000 KRW: currency decimals, dot, no grouping.
String plainAmount(int minor, String currency) {
  final d = Money.digits(currency);
  if (d == 0) return '$minor';
  final s = minor.abs().toString().padLeft(d + 1, '0');
  return '${minor < 0 ? '-' : ''}${s.substring(0, s.length - d)}.${s.substring(s.length - d)}';
}

bool prefillsAmount(String type) =>
    type == PaymentTypes.paypal || type == PaymentTypes.wise || type == PaymentTypes.venmo;

/// Link that opens the payment app, or null for bank types (shown in a sheet instead).
Uri? payLink(PaymentMethod m, {required int amountMinor, required String currency, String? note}) {
  final a = plainAmount(amountMinor, currency);
  String q(String k, String v) => '$k=${Uri.encodeComponent(v)}';
  switch (m.type) {
    case PaymentTypes.paypal:
      return Uri.parse('https://paypal.me/${m.value}/$a$currency');
    case PaymentTypes.wise:
      final u = Uri.parse(m.value);
      return u.replace(query: [
        if (u.query.isNotEmpty) u.query,
        q('amount', a),
        q('currency', currency),
        if (note != null) q('description', note),
      ].join('&'));
    case PaymentTypes.venmo:
      return Uri.parse('https://venmo.com/${m.value}?${[
        'txn=pay',
        q('amount', a),
        if (note != null) q('note', note),
      ].join('&')}');
    case PaymentTypes.revolut:
      return Uri.parse('https://revolut.me/${m.value}');
    case PaymentTypes.kakaopay:
      return Uri.parse(m.value);
    default:
      return null;
  }
}

/// EPC069-12 v002 "SEPA credit transfer" QR payload (the "GiroCode" EU banking apps scan).
String epcPayload({
  required String name,
  required String iban,
  String? bic,
  required int amountCents,
  String remittance = '',
}) {
  String cut(String s, int n) => s.length > n ? s.substring(0, n) : s;
  final lines = [
    'BCD', '002', '1', 'SCT',
    bic ?? '',
    cut(name, 70),
    normalizeIban(iban),
    'EUR${plainAmount(amountCents, 'EUR')}',
    '', // purpose
    '', // structured remittance reference
    cut(remittance, 140),
  ];
  while (lines.last.isEmpty) {
    lines.removeLast();
  }
  return lines.join('\n');
}

/// "•••• 1234".
String mask(String accountOrIban) {
  final s = accountOrIban.replaceAll(RegExp(r'[\s-]'), '');
  return '•••• ${s.length <= 4 ? s : s.substring(s.length - 4)}';
}

/// Short line for lists: username/link for apps, masked number for banks.
String methodSummary(PaymentMethod m) => switch (m.type) {
      PaymentTypes.iban => '${m.holder} · ${mask(m.value)}',
      PaymentTypes.krBank => '${m.bank} · ${mask(m.value)}',
      _ => m.value,
    };

/// Share text for "Request": "You owe me €15.00 for Trip on Evensies. Pay with: PayPal https://… · IBAN •••• 1234".
String requestText({
  required String formattedAmount,
  required String group,
  required List<PaymentMethod> methods,
  required int amountMinor,
  required String currency,
}) {
  final ways = [
    for (final m in methods)
      switch (m.type) {
        PaymentTypes.iban => 'IBAN ${mask(m.value)}',
        PaymentTypes.krBank => '${m.bank} ${mask(m.value)}',
        _ => '${methodLabel(m.type)} ${payLink(m, amountMinor: amountMinor, currency: currency, note: 'Evensies: $group')}',
      },
  ];
  final base = 'You owe me $formattedAmount for $group on Evensies.';
  return ways.isEmpty ? base : '$base Pay with: ${ways.join(' · ')}';
}
