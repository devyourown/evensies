import 'dart:io';

import 'package:evensies/core/money.dart';
import 'package:evensies/domain/payment_methods.dart';
import 'package:evensies/features/settle/pay_sheet.dart';
import 'package:evensies/l10n/app_localizations_en.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() => Money.loadFromJson(File('../shared/currencies.json').readAsStringSync()));

  PaymentMethod m(String type, String value, {String? holder, String? bank, String? bic}) =>
      PaymentMethod(type: type, value: value, holder: holder, bank: bank, bic: bic);
  String link(PaymentMethod x, int amount, String cur, {String? note}) =>
      payLink(x, amountMinor: amount, currency: cur, note: note).toString();

  group('payLink', () {
    test('PayPal uses currency decimals, dot, no grouping', () {
      expect(link(m('paypal', 'anna'), 1500, 'EUR'), 'https://paypal.me/anna/15.00EUR');
      expect(link(m('paypal', 'anna'), 123456, 'USD'), 'https://paypal.me/anna/1234.56USD');
      expect(link(m('paypal', 'anna'), 15000, 'KRW'), 'https://paypal.me/anna/15000KRW');
      expect(link(m('paypal', 'anna'), 5, 'EUR'), 'https://paypal.me/anna/0.05EUR');
    });
    test('Wise adds amount/currency/description, keeps existing query, encodes note', () {
      expect(link(m('wise', 'https://wise.com/pay/me/annar'), 1500, 'EUR', note: 'Evensies: Trip & co'),
          'https://wise.com/pay/me/annar?amount=15.00&currency=EUR&description=Evensies%3A%20Trip%20%26%20co');
      expect(link(m('wise', 'https://wise.com/pay/r/abc?x=1'), 1500, 'EUR'),
          'https://wise.com/pay/r/abc?x=1&amount=15.00&currency=EUR');
    });
    test('Venmo', () {
      expect(link(m('venmo', 'ben-k'), 2050, 'USD', note: 'Rome trip'),
          'https://venmo.com/ben-k?txn=pay&amount=20.50&note=Rome%20trip');
    });
    test('Revolut and KakaoPay open as-is, banks have no link', () {
      expect(link(m('revolut', 'anna'), 1500, 'EUR'), 'https://revolut.me/anna');
      expect(link(m('kakaopay', 'https://qr.kakaopay.com/Ej8abc'), 1500, 'KRW'), 'https://qr.kakaopay.com/Ej8abc');
      expect(payLink(m('iban', 'DE89370400440532013000', holder: 'A'), amountMinor: 1, currency: 'EUR'), isNull);
      expect(payLink(m('kr_bank', '110-123-456789', bank: 'Shinhan', holder: 'A'), amountMinor: 1, currency: 'KRW'),
          isNull);
    });
    test('prefillsAmount', () {
      expect([for (final t in PaymentTypes.all) if (prefillsAmount(t, 'EUR')) t], ['paypal', 'wise', 'venmo']);
      expect([for (final t in PaymentTypes.all) if (prefillsAmount(t, 'INR')) t], ['paypal', 'wise', 'venmo', 'upi']);
    });
    test('UPI: the INR amount with currency, no amount in other currencies, name and note encoded (Phase 10)', () {
      final upi = m('upi', 'anna.r@okicici', holder: 'Anna Rossi & Co');
      expect(link(upi, 150050, 'INR', note: 'Evensies: Goa trip'),
          'upi://pay?pa=anna.r@okicici&pn=Anna%20Rossi%20%26%20Co&tn=Evensies%3A%20Goa%20trip&am=1500.50&cu=INR');
      expect(link(upi, 1500, 'EUR', note: 'Evensies: Goa'), 'upi://pay?pa=anna.r@okicici&pn=Anna%20Rossi%20%26%20Co&tn=Evensies%3A%20Goa');
      // No name; a note cut at 50 characters.
      final long = link(m('upi', 'ben@ybl'), 100, 'INR', note: 'n' * 80);
      expect(long, 'upi://pay?pa=ben@ybl&tn=${'n' * 50}&am=1.00&cu=INR');
    });
    test('UPI ID check and one per user', () {
      expect(methodError(m('upi', 'anna.r@okicici')), isNull);
      expect(methodError(m('upi', 'anna.r@okicici', holder: 'Anna')), isNull);
      expect(methodError(m('upi', 'a@okicici')), 'UPI'); // 2+ before @
      expect(methodError(m('upi', 'anna@1bank')), 'UPI'); // the handle starts with a letter
      expect(methodError(m('upi', 'anna rossi@ok')), 'UPI');
      expect(methodError(m('upi', 'anna@ok', holder: 'x' * 71)), 'HOLDER');
      expect(methodsError([m('upi', 'anna@ok'), m('upi', 'ben@ok')]), 'TOO_MANY');
      expect(requestText(AppLocalizationsEn(),
              formattedAmount: '₹15.00', group: 'Goa', methods: [m('upi', 'anna@ok')], amountMinor: 1500, currency: 'INR'),
          contains('UPI anna@ok'));
    });
  });

  testWidgets('UPI is offered on an INR card only (a UPI payment has no other currency)', (t) async {
    Future<List<String>> chips(String currency) async {
      await t.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PayChips(
            methods: [m('paypal', 'anna'), m('upi', 'anna@okicici')],
            failed: false,
            toName: 'Anna',
            currency: currency,
            onPay: (_) {},
          ),
        ),
      ));
      return [for (final c in t.widgetList<ActionChip>(find.byType(ActionChip))) (c.label as Text).data!];
    }

    expect(await chips('EUR'), ['PayPal']);
    expect(await chips('INR'), ['PayPal', 'UPI']);
  });

  test('EPC payload exact text', () {
    expect(
      epcPayload(
          name: 'Anna Rossi',
          iban: 'DE89 3704 0044 0532 0130 00',
          bic: 'COBADEFFXXX',
          amountCents: 1500,
          remittance: 'Evensies: Rome'),
      'BCD\n002\n1\nSCT\nCOBADEFFXXX\nAnna Rossi\nDE89370400440532013000\nEUR15.00\n\n\nEvensies: Rome',
    );
    // No BIC, no remittance: trailing empty fields are dropped, BIC line stays empty.
    expect(epcPayload(name: 'A', iban: 'DE89370400440532013000', amountCents: 5),
        'BCD\n002\n1\nSCT\n\nA\nDE89370400440532013000\nEUR0.05');
    final long = epcPayload(name: 'n' * 80, iban: 'DE89370400440532013000', amountCents: 1, remittance: 'r' * 200);
    expect(long.split('\n')[5].length, 70);
    expect(long.split('\n').last.length, 140);
  });

  group('validation', () {
    test('IBAN mod-97', () {
      expect(ibanValid('DE89370400440532013000'), isTrue);
      expect(ibanValid('GB82WEST12345698765432'), isTrue);
      expect(ibanValid(normalizeIban('it60 x054 2811 1010 0000 0123 456')), isTrue);
      expect(ibanValid('DE89370400440532013001'), isFalse);
      expect(ibanValid('DE89'), isFalse);
    });
    test('per type', () {
      expect(methodError(m('paypal', 'anna.r_1-x')), isNull);
      expect(methodError(m('paypal', 'anna rossi')), isNotNull);
      expect(methodError(m('venmo', 'a' * 41)), isNotNull);
      expect(methodError(m('wise', 'https://wise.com/pay/me/a')), isNull);
      expect(methodError(m('wise', 'https://evil.com/wise.com/')), isNotNull);
      expect(methodError(m('wise', 'https://wise.com/${'a' * 200}')), isNotNull);
      expect(methodError(m('kakaopay', 'https://qr.kakaopay.com/abc')), isNull);
      expect(methodError(m('kakaopay', 'http://qr.kakaopay.com/abc')), isNotNull);
      expect(methodError(m('iban', 'DE89370400440532013000', holder: 'Anna')), isNull);
      expect(methodError(m('iban', 'DE89370400440532013000')), isNotNull, reason: 'holder required');
      expect(methodError(m('iban', 'DE89370400440532013000', holder: 'A', bic: 'COBADEFF')), isNull);
      expect(methodError(m('iban', 'DE89370400440532013000', holder: 'A', bic: 'COBADEF')), isNotNull);
      expect(methodError(m('kr_bank', '110-123-456789', bank: 'Shinhan', holder: 'Kim')), isNull);
      expect(methodError(m('kr_bank', '1234567', bank: 'Shinhan', holder: 'Kim')), isNotNull);
      expect(methodError(m('kr_bank', '12345678', holder: 'Kim')), isNotNull, reason: 'bank required');
      expect(methodError(m('kr_bank', '1234-5678a', bank: 'B', holder: 'K')), isNotNull);
    });
    test('limits', () {
      final iban = m('iban', 'DE89370400440532013000', holder: 'A');
      expect(methodsError([iban, iban, iban]), isNull);
      expect(methodsError([iban, iban, iban, iban]), isNotNull);
      expect(methodsError([m('paypal', 'a'), m('paypal', 'b')]), isNotNull);
      final nine = [
        m('paypal', 'a'), m('wise', 'https://wise.com/a'), m('venmo', 'a'), m('revolut', 'a'),
        m('kakaopay', 'https://qr.kakaopay.com/a'), iban, iban, iban, m('kr_bank', '12345678', bank: 'B', holder: 'K'),
      ];
      expect(methodsError(nine.take(8).toList()), isNull);
      expect(methodsError(nine), isNotNull);
    });
  });

  test('mask', () {
    expect(mask('DE89370400440532013000'), '•••• 3000');
    expect(mask('110-123-456789'), '•••• 6789');
  });

  test('JSON round trip omits null fields', () {
    final j = m('paypal', 'anna').toJson();
    expect(j, {'type': 'paypal', 'value': 'anna'});
    expect(PaymentMethod.fromJson(m('iban', 'X', holder: 'H', bic: 'B').toJson()).holder, 'H');
  });

  test('request text', () {
    expect(
      requestText(
        AppLocalizationsEn(),
        formattedAmount: '€15.00',
        group: 'Rome',
        amountMinor: 1500,
        currency: 'EUR',
        methods: [m('paypal', 'anna'), m('iban', 'DE89370400440532013000', holder: 'Anna')],
      ),
      'You owe me €15.00 for Rome on Evensies. Pay with: PayPal https://paypal.me/anna/15.00EUR · IBAN •••• 3000',
    );
  });
}
