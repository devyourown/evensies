import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/money.dart';
import '../../core/snack.dart';
import '../../domain/payment_methods.dart';
import '../settings/payment_methods_screen.dart' show methodIcon;

/// Ways to pay (docs Phase 1), shared by a group's Settle up and settling with a friend.

Future<void> _copy(BuildContext context, String value, String message) async {
  await Clipboard.setData(ClipboardData(text: value));
  if (context.mounted) showInfo(context, message);
}

/// Opens [m]'s app with [amount] in [currency] (copying the amount where the link can't carry it), or the bank sheet
/// for IBAN and Korean bank accounts. [note] is the payment reference ("Evensies: Rome").
Future<void> payWith(BuildContext context, PaymentMethod m,
    {required String toName, required int amount, required String currency, required String note}) async {
  final uri = payLink(m, amountMinor: amount, currency: currency, note: note);
  if (uri == null) return _bankSheet(context, m, toName: toName, amount: amount, currency: currency, note: note);
  if (!prefillsAmount(m.type)) {
    await _copy(context, plainAmount(amount, currency), 'Amount copied: ${formatMoney(amount, currency)}');
  }
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication).catchError((_) => false);
  if (!ok && context.mounted) showInfo(context, 'Could not open $uri');
}

/// One chip per way to pay; nothing while loading, a muted line when offline or there is none.
class PayChips extends StatelessWidget {
  /// Null while loading.
  final List<PaymentMethod>? methods;
  final bool failed;
  final String toName;
  final void Function(PaymentMethod m) onPay;
  const PayChips({super.key, required this.methods, required this.failed, required this.toName, required this.onPay});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    final ms = methods;
    if (failed) return Text('Offline: ways to pay are not available', style: muted);
    if (ms == null) return Text('Loading ways to pay…', style: muted);
    if (ms.isEmpty) return Text('Ask $toName to add a way to get paid', style: muted);
    return Wrap(spacing: 8, runSpacing: 4, children: [
      for (final m in ms)
        ActionChip(
          avatar: Icon(methodIcon(m.type), size: 18),
          label: Text(m.type == PaymentTypes.krBank ? m.bank ?? methodLabel(m.type) : methodLabel(m.type)),
          onPressed: () => onPay(m),
        ),
    ]);
  }
}

Future<void> _bankSheet(BuildContext context, PaymentMethod m,
    {required String toName, required int amount, required String currency, required String note}) {
  final formatted = formatMoney(amount, currency);
  final iban = m.type == PaymentTypes.iban;
  final qr = iban && currency == 'EUR';
  final account = iban ? m.value.replaceAllMapped(RegExp(r'.{4}'), (x) => '${x[0]} ').trim() : m.value;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      final text = Theme.of(ctx).textTheme;
      Widget line(String label, String value) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 96, child: Text(label, style: TextStyle(color: cs.onSurfaceVariant))),
              Expanded(child: SelectableText(value, style: text.bodyLarge)),
            ]),
          );
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Pay $toName $formatted', style: text.titleLarge),
            const SizedBox(height: 12),
            if (qr) ...[
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  // A QR code needs a light quiet zone in dark mode too.
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: QrImageView(
                    key: const Key('epc-qr'),
                    data: epcPayload(name: m.holder ?? '', iban: m.value, bic: m.bic, amountCents: amount, remittance: note),
                    size: 200,
                    backgroundColor: Colors.white,
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text('Scan with your banking app (SEPA QR)',
                  textAlign: TextAlign.center, style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 12),
            ] else if (iban) ...[
              Text('QR code is only available for EUR transfers.', style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 8),
            ],
            if (!iban) line('Bank', m.bank ?? ''),
            line(iban ? 'IBAN' : 'Account', account),
            if (iban && m.bic != null) line('BIC', m.bic!),
            line('Holder', m.holder ?? ''),
            line('Amount', formatted),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.copy, size: 18),
                  label: Text(iban ? 'Copy IBAN' : 'Copy account'),
                  onPressed: () =>
                      _copy(ctx, iban ? m.value : '${m.bank} ${m.value}', iban ? 'IBAN copied' : 'Account copied'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy amount'),
                  onPressed: () => _copy(ctx, plainAmount(amount, currency), 'Amount copied: $formatted'),
                ),
              ),
            ]),
          ]),
        ),
      );
    },
  );
}
