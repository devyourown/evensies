/// Reading a receipt photo's text into a draft bill (docs Phase 7 "Receipt parser"): best effort, the user always reviews
/// it on the Itemize screen. Pure Dart; the text comes from on-device recognition (data/receipts.dart).
library;

import 'categories.dart' show fold;

/// One recognized line of text and its box in the photo.
class OcrLine {
  final String text;
  final double left, top, right, bottom;
  const OcrLine({required this.text, required this.left, required this.top, required this.right, required this.bottom});
  factory OcrLine.fromJson(Map<String, dynamic> j) => OcrLine(
        text: j['text'] as String,
        left: (j['left'] as num).toDouble(),
        top: (j['top'] as num).toDouble(),
        right: (j['right'] as num).toDouble(),
        bottom: (j['bottom'] as num).toDouble(),
      );
  double get centre => (top + bottom) / 2;
}

/// What a receipt says: its item lines, tax, tip, discount (minor units), the printed total and the shop's name.
class ReceiptDraft {
  final List<({String name, int amount})> lines;
  final int tax, tip, discount;
  final int? total;
  final String? merchant;
  const ReceiptDraft({required this.lines, this.tax = 0, this.tip = 0, this.discount = 0, this.total, this.merchant});
  Map<String, dynamic> toJson() => {
        'lines': [for (final l in lines) {'name': l.name, 'amount': l.amount}],
        'tax': tax,
        'tip': tip,
        'discount': discount,
        'total': total,
        'merchant': merchant,
      };
}

/// Words on receipts in EN, IT, DE, FR, ES, NL, PT, SV, PL and ID, folded (lowercase, no accents). Matched as whole
/// words of the folded row.
const _keywords = <String, List<String>>{
  'subtotal': [
    'subtotal', 'sub total', 'sub-total', 'subtotale', 'zwischensumme', 'sous-total', 'sous total', 'subtotaal',
    'delsumma', 'suma czesciowa', 'sub jumlah',
  ],
  'total': [
    'total', 'totale', 'grand total', 'amount due', 'balance due', 'gesamt', 'summe', 'zu zahlen', 'gesamtbetrag',
    'total ttc', 'a payer', 'net a payer', 'importe', 'a pagar', 'totaal', 'te betalen', 'totalt', 'att betala',
    'summa', 'suma', 'razem', 'do zaplaty', 'jumlah', 'total bayar',
  ],
  'tax': [
    'tax', 'sales tax', 'vat', 'iva', 'imposta', 'mwst', 'ust', 'steuer', 'tva', 'impuesto', 'imposto', 'btw', 'moms',
    'ptu', 'ppn', 'pajak',
  ],
  'tip': [
    'tip', 'tips', 'gratuity', 'service', 'service charge', 'servizio', 'mancia', 'trinkgeld', 'bedienung',
    'pourboire', 'propina', 'servicio', 'gorjeta', 'servico', 'taxa de servico', 'fooi', 'bediening', 'dricks',
    'napiwek', 'serwis', 'layanan', 'biaya layanan',
  ],
  'discount': [
    'discount', 'coupon', 'voucher', 'promo', 'sconto', 'rabatt', 'nachlass', 'remise', 'reduction', 'descuento',
    'desconto', 'korting', 'rabat', 'znizka', 'diskon', 'potongan',
  ],
  // Payment lines and the card slip: never items.
  'payment': [
    'cash', 'card', 'change', 'visa', 'mastercard', 'amex', 'credit', 'debit', 'tendered', 'contanti', 'carta',
    'bancomat', 'resto', 'karte', 'wechselgeld', 'ruckgeld', 'gegeben', 'especes', 'carte', 'rendu', 'monnaie',
    'efectivo', 'tarjeta', 'cambio', 'dinheiro', 'cartao', 'troco', 'contant', 'wisselgeld', 'pinnen', 'kontant',
    'kontokort', 'vaxel', 'gotowka', 'karta', 'reszta', 'tunai', 'kartu', 'kembali', 'kembalian',
  ],
};

bool _has(String folded, String kind) => _keywords[kind]!.any((k) => folded.contains(' $k '));

/// The row as " word word " (folded, every non-letter a space) for whole-word keyword checks.
String _words(String s) => ' ${fold(s).replaceAll(RegExp(r'[^\p{L}]+', unicode: true), ' ').trim()} ';

/// The price at the end of a row (docs Phase 7): an optional currency sign or code, digits grouped by `.` `,` `'` (or a
/// space, only with a fraction: "1 234,50"; without one "2 450" is a quantity and a price), a fraction of exactly
/// [decimals] digits (required when there are decimals, never present otherwise; the separator before it is the
/// decimal mark), an optional `-` (negative), then an optional VAT letter, `*` or currency.
RegExp _priceRe(int decimals) {
  const cur = r"(?:(?<![A-Za-z])(?:[A-Z]{3}|Rp|kr|zł)|[€$£¥₩₹₺¢])";
  final group = decimals > 0 ? "[.,' ]" : "[.,']";
  final frac = decimals > 0 ? '[.,](\\d{$decimals})' : '';
  // Not inside a word or another number ("03-1234-5678", "14:32", "2026/10/11").
  return RegExp(
    '(?<![\\w.,\'/:-])(?:(-)\\s?)?(?:$cur\\s?)?(\\d{1,3}(?:$group\\d{3})+|\\d+)$frac(-)?'
    r"(?:\s?(?:[A-Z]{3}|[€$£¥₩円*]|[A-Z]))?\s*$",
    unicode: true,
  );
}

/// Signs that name one currency ($ and kr are several; ¥ is read as JPY, the one travellers meet most).
const _signs = {'€': 'EUR', '£': 'GBP', '¥': 'JPY', '円': 'JPY', '₩': 'KRW', '₹': 'INR', '₺': 'TRY', 'zł': 'PLN', 'Rp': 'IDR'};

/// The currency the receipt's text names most often: a sign from [_signs], or a code in [known] next to a number
/// ("JPY 1,200", "12.50 EUR"); null when it names none. Used to offer a switch when nothing could be read in the
/// form's currency (a ¥ receipt in a EUR group: other decimals).
String? receiptCurrency(List<OcrLine> lines, {required Set<String> known}) {
  final counts = <String, int>{};
  final code = RegExp(r'(?<![A-Za-z])([A-Z]{3})\s?\d|\d\s?([A-Z]{3})(?![A-Za-z])');
  for (final l in lines) {
    for (final MapEntry(key: sign, value: c) in _signs.entries) {
      if (l.text.contains(sign)) counts[c] = (counts[c] ?? 0) + 1;
    }
    for (final m in code.allMatches(l.text)) {
      final c = m.group(1) ?? m.group(2)!;
      if (known.contains(c)) counts[c] = (counts[c] ?? 0) + 1;
    }
  }
  return counts.entries.fold<MapEntry<String, int>?>(null, (a, e) => a == null || e.value > a.value ? e : a)?.key;
}

class _Row {
  final List<OcrLine> parts;
  _Row(OcrLine first) : parts = [first];
  double get centre => parts.fold(0.0, (a, l) => a + l.centre) / parts.length;
  String get text => (([...parts]..sort((a, b) => a.left.compareTo(b.left))).map((l) => l.text.trim())).join(' ');
}

/// [lines] → a draft; amounts in minor units of a currency with [decimals] digits (shared/currencies.json).
/// 1. Rows: lines sorted by vertical centre; a line joins the row when its centre is within half the median line
///    height of the row's. Text joins left to right. A text-only row followed by a price-only row is one row.
/// 2. The price is at the end of a row ([_priceRe]).
/// 3. Total: the largest price on a row with a total word (not a subtotal one), else the largest price; the first
///    such row. Rows below it are ignored.
/// 4. Rows above it, first match wins: subtotal → ignored; tax → tax; tip/service → tip; a discount word or a negative
///    price → discount (its size); another total word → ignored; payment words → ignored; any other priced row → an
///    item ("2x" stays in its name).
/// 5. VAT already included: items + tip − discount == total → tax 0.
/// 6. Merchant: the first row without a price, if 40 characters or fewer.
ReceiptDraft parseReceipt(List<OcrLine> lines, {required int decimals}) {
  if (lines.isEmpty) return const ReceiptDraft(lines: []);
  final heights = [for (final l in lines) l.bottom - l.top]..sort();
  final half = heights[heights.length ~/ 2] / 2;
  final rows = <_Row>[];
  for (final l in [...lines]..sort((a, b) => a.centre.compareTo(b.centre))) {
    if (rows.isNotEmpty && (l.centre - rows.last.centre).abs() <= half) {
      rows.last.parts.add(l);
    } else {
      rows.add(_Row(l));
    }
  }
  final re = _priceRe(decimals);
  ({String name, int amount})? price(String text) {
    final m = re.firstMatch(text);
    if (m == null) return null;
    final digits = m.group(2)!.replaceAll(RegExp(r"[.,' ]"), '') + (decimals > 0 ? m.group(3)! : '');
    final v = int.tryParse(digits);
    if (v == null) return null;
    final name = text.substring(0, m.start).trim().replaceAll(RegExp(r'[\s.:·_=-]+$'), '');
    return (name: name, amount: (m.group(1) != null || m.group(decimals > 0 ? 4 : 3) != null) ? -v : v);
  }

  // Text rows and their prices, a lone price joined to the text-only row above it.
  final texts = <String>[];
  for (final r in rows) {
    final t = r.text;
    final p = price(t);
    if (p != null && p.name.isEmpty && texts.isNotEmpty && price(texts.last) == null) {
      texts.last = '${texts.last} $t';
    } else {
      texts.add(t);
    }
  }
  final priced = [for (final t in texts) (text: t, words: _words(t), price: price(t))];

  int? totalAt;
  for (final pass in [true, false]) {
    for (final (i, r) in priced.indexed) {
      final p = r.price;
      if (p == null || (pass && (!_has(r.words, 'total') || _has(r.words, 'subtotal')))) continue;
      if (totalAt == null || p.amount > priced[totalAt].price!.amount) totalAt = i;
    }
    if (totalAt != null) break;
  }
  final items = <({String name, int amount})>[];
  var tax = 0, tip = 0, discount = 0;
  for (final r in priced.take(totalAt ?? priced.length)) {
    final p = r.price;
    // A quantity detail under an item ("2 x 0,99") is not an item of its own.
    if (p == null || RegExp(r'^\d+\s*[x×*]$').hasMatch(p.name)) continue;
    final w = r.words;
    if (_has(w, 'subtotal')) continue;
    if (_has(w, 'tax')) {
      tax += p.amount.abs();
    } else if (_has(w, 'tip')) {
      tip += p.amount.abs();
    } else if (_has(w, 'discount') || p.amount < 0) {
      discount += p.amount.abs();
    } else if (_has(w, 'total') || _has(w, 'payment')) {
      continue;
    } else {
      items.add((name: p.name.isEmpty ? 'Item' : p.name, amount: p.amount));
    }
  }
  final total = totalAt == null ? null : priced[totalAt].price!.amount;
  final sum = items.fold(0, (a, l) => a + l.amount);
  if (total != null && sum + tip - discount == total) tax = 0;
  final merchant = priced.where((r) => r.price == null).firstOrNull?.text.trim();
  return ReceiptDraft(
    lines: items,
    tax: tax,
    tip: tip,
    discount: discount,
    total: total,
    merchant: merchant != null && merchant.isNotEmpty && merchant.length <= 40 ? merchant : null,
  );
}
