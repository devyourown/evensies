/// "Ways to get paid" (docs/API.md, Payment methods). Validation returns codes; the screens word them ([methodErrorText]).
library;

import '../core/money.dart';
import '../l10n/app_localizations.dart';

abstract final class PaymentTypes {
  static const paypal = 'paypal';
  static const wise = 'wise';
  static const venmo = 'venmo';
  static const revolut = 'revolut';
  static const kakaopay = 'kakaopay';
  static const iban = 'iban';
  static const krBank = 'kr_bank';

  /// India's UPI (Paytm, PhonePe, Google Pay, BHIM…): a UPI ID (VPA) and an optional name (Phase 10).
  static const upi = 'upi';
  static const all = [paypal, wise, venmo, revolut, kakaopay, upi, iban, krBank];
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

String methodLabel(String type, AppLocalizations l) => switch (type) {
      PaymentTypes.paypal => 'PayPal',
      PaymentTypes.wise => 'Wise',
      PaymentTypes.venmo => 'Venmo',
      PaymentTypes.revolut => 'Revolut',
      PaymentTypes.kakaopay => 'KakaoPay',
      PaymentTypes.iban => 'IBAN',
      PaymentTypes.upi => 'UPI',
      PaymentTypes.krBank => l.koreanBank,
      _ => type,
    };

/// How many of [type] a user may have.
int maxPerType(String type) => type == PaymentTypes.iban || type == PaymentTypes.krBank ? 3 : 1;
const maxMethods = 8;

/// IBAN as stored: no spaces, upper case.
String normalizeIban(String s) => s.replaceAll(RegExp(r'\s'), '').toUpperCase();

final _username = RegExp(r'^[A-Za-z0-9._-]{1,40}$');
final _vpa = RegExp(r'^[A-Za-z0-9._-]{2,256}@[A-Za-z][A-Za-z0-9]{1,63}$');

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

/// Error code for one field (`value`, `holder`, `bank`, `bic`) of a method of [type], or null if valid: `USERNAME`,
/// `LINK_PREFIX`, `TOO_LONG`, `IBAN`, `HOLDER`, `BIC`, `KR_ACCOUNT`, `BANK`, `UPI`. Mirrors the validation table in
/// docs/API.md; the server is the authority.
String? methodFieldError(String type, String field, String? input) {
  final v = input?.trim() ?? '';
  switch ((type, field)) {
    case (PaymentTypes.paypal || PaymentTypes.revolut || PaymentTypes.venmo, 'value'):
      return _username.hasMatch(v) ? null : 'USERNAME';
    case (PaymentTypes.wise, 'value'):
      return _link(v, 'https://wise.com/');
    case (PaymentTypes.kakaopay, 'value'):
      return _link(v, 'https://qr.kakaopay.com/');
    case (PaymentTypes.iban, 'value'):
      return ibanValid(normalizeIban(v)) ? null : 'IBAN';
    case (PaymentTypes.iban || PaymentTypes.krBank, 'holder'):
      return v.isEmpty || v.length > 70 ? 'HOLDER' : null;
    case (PaymentTypes.upi, 'value'):
      return _vpa.hasMatch(v) ? null : 'UPI';
    case (PaymentTypes.upi, 'holder'):
      return v.length > 70 ? 'HOLDER' : null; // optional
    case (PaymentTypes.iban, 'bic'):
      if (v.isEmpty) return null;
      return v.length == 8 || v.length == 11 ? null : 'BIC';
    case (PaymentTypes.krBank, 'value'):
      final digits = v.replaceAll('-', '');
      return RegExp(r'^[\d-]+$').hasMatch(v) && digits.length >= 8 && digits.length <= 20
          ? null
          : 'KR_ACCOUNT';
    case (PaymentTypes.krBank, 'bank'):
      return v.isEmpty || v.length > 30 ? 'BANK' : null;
    default:
      return null;
  }
}

String? _link(String v, String prefix) {
  if (!v.startsWith(prefix)) return 'LINK_PREFIX';
  return v.length > 200 ? 'TOO_LONG' : null;
}

/// A validation code of [type]'s fields as the form shows it.
String methodErrorText(AppLocalizations l, String type, String code) => switch (code) {
      'USERNAME' => l.methodErrorUsername,
      'LINK_PREFIX' => l.methodErrorLinkPrefix(type == PaymentTypes.wise ? 'https://wise.com/' : 'https://qr.kakaopay.com/'),
      'TOO_LONG' => l.methodErrorTooLong,
      'IBAN' => l.methodErrorIban,
      'HOLDER' => l.methodErrorHolder,
      'BIC' => l.methodErrorBic,
      'KR_ACCOUNT' => l.methodErrorKrAccount,
      'BANK' => l.methodErrorBank,
      'UPI' => l.methodErrorUpi,
      'UNKNOWN_TYPE' => l.methodErrorUnknownType,
      'TOO_MANY' => l.methodErrorTooMany,
      _ => l.errorGeneric(code),
    };

/// First error code in [m], or null.
String? methodError(PaymentMethod m) {
  if (!PaymentTypes.all.contains(m.type)) return 'UNKNOWN_TYPE';
  for (final (f, v) in [('value', m.value), ('holder', m.holder), ('bank', m.bank), ('bic', m.bic)]) {
    final e = methodFieldError(m.type, f, v);
    if (e != null) return e;
  }
  return null;
}

/// Error code for the whole list (`TOO_MANY` past the limits, else the first method's), or null.
String? methodsError(List<PaymentMethod> ms) {
  if (ms.length > maxMethods) return 'TOO_MANY';
  for (final t in PaymentTypes.all) {
    if (ms.where((m) => m.type == t).length > maxPerType(t)) return 'TOO_MANY';
  }
  for (final m in ms) {
    final e = methodError(m);
    if (e != null) return e;
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

/// Whether [type]'s link carries the amount: a UPI link only in INR (it has no currency choice).
bool prefillsAmount(String type, String currency) =>
    type == PaymentTypes.paypal ||
    type == PaymentTypes.wise ||
    type == PaymentTypes.venmo ||
    (type == PaymentTypes.upi && currency == 'INR');

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
    case PaymentTypes.upi:
      // NPCI's deep link: payee address, name, note (≤ 50 characters); the amount only in INR.
      final tn = note == null ? null : (note.length > 50 ? note.substring(0, 50) : note);
      return Uri.parse('upi://pay?${[
        'pa=${m.value}', // the validated ID needs no encoding; apps expect a plain @

        if (m.holder != null) q('pn', m.holder!),
        if (tn != null) q('tn', tn),
        if (currency == 'INR') ...[q('am', a), q('cu', 'INR')],
      ].join('&')}');
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
String requestText(
  AppLocalizations l, {
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
        // A upi:// link isn't clickable in a message: the ID is what people type.
        PaymentTypes.upi => 'UPI ${m.value}',
        _ => '${methodLabel(m.type, l)} ${payLink(m, amountMinor: amountMinor, currency: currency, note: 'Evensies: $group')}',
      },
  ];
  return ways.isEmpty
      ? l.requestText(formattedAmount, group)
      : l.requestTextWays(formattedAmount, group, ways.join(' · '));
}
