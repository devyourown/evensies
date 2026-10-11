import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/confirm.dart';
import '../../core/snack.dart';
import '../../data/api/dto.dart';
import '../../domain/payment_methods.dart';
import '../../providers.dart';

IconData methodIcon(String type) => switch (type) {
      PaymentTypes.iban || PaymentTypes.krBank => Icons.account_balance_outlined,
      PaymentTypes.wise => Icons.public,
      _ => Icons.account_balance_wallet_outlined,
    };

/// Settings → Ways to get paid. Online only: the list lives on the server (PUT replaces it whole).
class PaymentMethodsScreen extends ConsumerStatefulWidget {
  const PaymentMethodsScreen({super.key});
  @override
  ConsumerState<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends ConsumerState<PaymentMethodsScreen> {
  List<PaymentMethod>? _methods;
  Object? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final ms = await ref.read(apiProvider).getMyPaymentMethods();
      if (mounted) setState(() => _methods = ms);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<bool> _save(List<PaymentMethod> next) async {
    setState(() => _saving = true);
    try {
      final ms = await ref.read(apiProvider).putMyPaymentMethods(next);
      if (mounted) setState(() => _methods = ms);
      return true;
    } catch (e) {
      if (mounted) showError(context, e is ApiException && e.code == 'NETWORK' ? 'You are offline. Try again later.' : e);
      return false;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _add() async {
    final ms = _methods!;
    final type = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: ListView(shrinkWrap: true, children: [
          for (final t in PaymentTypes.all)
            ListTile(
              leading: Icon(methodIcon(t)),
              title: Text(methodLabel(t)),
              subtitle: Text(_typeBlurb(t)),
              enabled: ms.length < maxMethods && ms.where((m) => m.type == t).length < maxPerType(t),
              onTap: () => Navigator.pop(ctx, t),
            ),
        ]),
      ),
    );
    if (type == null || !mounted) return;
    final m = await _openForm(type, null);
    if (m != null) await _save([...ms, m]);
  }

  Future<PaymentMethod?> _openForm(String type, PaymentMethod? initial) => Navigator.of(context).push(
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => PaymentMethodForm(type: type, initial: initial)));

  Future<void> _edit(int i) async {
    final ms = _methods!;
    final m = await _openForm(ms[i].type, ms[i]);
    if (m != null) await _save([...ms]..[i] = m);
  }

  Future<void> _delete(int i) async {
    final ms = _methods!;
    final ok = await confirm(context, title: 'Remove ${methodLabel(ms[i].type)}?', message: methodSummary(ms[i]), confirmLabel: 'Remove');
    if (ok) await _save([...ms]..removeAt(i));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ms = _methods;
    Widget body;
    if (ms == null && _error != null) {
      final offline = _error is ApiException && (_error as ApiException).code == 'NETWORK';
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(offline ? Icons.cloud_off_outlined : Icons.error_outline, size: 48, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(offline ? 'Connect to the internet to edit your ways to get paid.' : _error.toString(),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text('Retry')),
          ]),
        ),
      );
    } else if (ms == null) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = ListView(padding: const EdgeInsets.only(bottom: 88), children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(
            'Group members see these when they owe you money, so they can pay you in one tap. '
            'Evensies never moves money itself.',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
        ),
        if (ms.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text('No ways to get paid yet.', textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant)),
          ),
        for (var i = 0; i < ms.length; i++)
          ListTile(
            leading: Icon(methodIcon(ms[i].type)),
            title: Text(methodLabel(ms[i].type)),
            subtitle: Text(methodSummary(ms[i]), maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: _saving ? null : () => _edit(i),
            trailing: IconButton(
              tooltip: 'Remove',
              icon: const Icon(Icons.delete_outline),
              onPressed: _saving ? null : () => _delete(i),
            ),
          ),
      ]);
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ways to get paid'),
        bottom: _saving ? const PreferredSize(preferredSize: Size.fromHeight(2), child: LinearProgressIndicator()) : null,
      ),
      body: body,
      floatingActionButton: ms == null || ms.length >= maxMethods || _saving
          ? null
          : FloatingActionButton.extended(onPressed: _add, icon: const Icon(Icons.add), label: const Text('Add')),
    );
  }
}

String _typeBlurb(String t) => switch (t) {
      PaymentTypes.paypal => 'PayPal.me link, amount filled in',
      PaymentTypes.wise => 'Wise Quick Pay link, amount filled in',
      PaymentTypes.venmo => 'Venmo username (US)',
      PaymentTypes.revolut => 'Revolut.me username',
      PaymentTypes.kakaopay => 'KakaoPay 송금코드 link',
      PaymentTypes.iban => 'Bank transfer (SEPA QR for EUR)',
      PaymentTypes.krBank => 'Korean bank account (Toss, bank apps)',
      _ => '',
    };

class _Field {
  final String key, label;
  final String? hint, prefix;
  final TextInputType keyboard;
  final bool optional;
  const _Field(this.key, this.label, {this.hint, this.prefix, this.keyboard = TextInputType.text, this.optional = false});
}

List<_Field> _fieldsFor(String t) => switch (t) {
      PaymentTypes.paypal => const [
          _Field('value', 'PayPal.me username', hint: 'Your PayPal.me username, e.g. anna', prefix: 'paypal.me/', keyboard: TextInputType.url),
        ],
      PaymentTypes.revolut => const [
          _Field('value', 'Revolut.me username', hint: 'Your Revolut.me username, e.g. anna', prefix: 'revolut.me/', keyboard: TextInputType.url),
        ],
      PaymentTypes.venmo => const [
          _Field('value', 'Venmo username', hint: 'Without the @, e.g. anna-rossi', prefix: '@', keyboard: TextInputType.url),
        ],
      PaymentTypes.wise => const [
          _Field('value', 'Wise Quick Pay link',
              hint: 'In Wise: Payments → Quick Pay → copy link (https://wise.com/pay/…)', keyboard: TextInputType.url),
        ],
      PaymentTypes.kakaopay => const [
          _Field('value', 'KakaoPay 송금코드 link',
              hint: 'In KakaoPay: 송금 → 송금코드 → copy link (https://qr.kakaopay.com/…)', keyboard: TextInputType.url),
        ],
      PaymentTypes.iban => const [
          _Field('holder', 'Account holder', hint: 'Name exactly as on the account'),
          _Field('value', 'IBAN', hint: 'e.g. DE89 3704 0044 0532 0130 00', keyboard: TextInputType.url),
          _Field('bic', 'BIC (optional)', hint: '8 or 11 characters', keyboard: TextInputType.url, optional: true),
        ],
      PaymentTypes.krBank => const [
          _Field('bank', 'Bank', hint: 'e.g. 신한은행, Toss Bank'),
          _Field('value', 'Account number', hint: 'Digits, hyphens optional', keyboard: TextInputType.number),
          _Field('holder', 'Account holder'),
        ],
      _ => const [],
    };

class PaymentMethodForm extends StatefulWidget {
  final String type;
  final PaymentMethod? initial;
  const PaymentMethodForm({super.key, required this.type, this.initial});
  @override
  State<PaymentMethodForm> createState() => _PaymentMethodFormState();
}

class _PaymentMethodFormState extends State<PaymentMethodForm> {
  final _form = GlobalKey<FormState>();
  late final _fields = _fieldsFor(widget.type);
  late final _ctl = {
    for (final f in _fields)
      f.key: TextEditingController(
        text: switch (f.key) {
          'holder' => widget.initial?.holder,
          'bank' => widget.initial?.bank,
          'bic' => widget.initial?.bic,
          _ => widget.initial?.value,
        },
      ),
  };

  @override
  void dispose() {
    for (final c in _ctl.values) {
      c.dispose();
    }
    super.dispose();
  }

  String? _get(String k) {
    final v = _ctl[k]?.text.trim();
    return v == null || v.isEmpty ? null : v;
  }

  void _done() {
    if (!_form.currentState!.validate()) return;
    final iban = widget.type == PaymentTypes.iban;
    Navigator.pop(
      context,
      PaymentMethod(
        type: widget.type,
        value: iban ? normalizeIban(_get('value')!) : _get('value')!,
        holder: _get('holder'),
        bank: _get('bank'),
        bic: _get('bic')?.toUpperCase(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(methodLabel(widget.type)),
        actions: [TextButton(onPressed: _done, child: const Text('Done'))],
      ),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          for (final f in _fields)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: TextFormField(
                key: Key('pm-${f.key}'),
                controller: _ctl[f.key],
                keyboardType: f.keyboard,
                autocorrect: false,
                textCapitalization: f.key == 'value' && widget.type == PaymentTypes.iban
                    ? TextCapitalization.characters
                    : TextCapitalization.none,
                decoration: InputDecoration(labelText: f.label, helperText: f.hint, helperMaxLines: 2, prefixText: f.prefix),
                validator: (v) => methodFieldError(widget.type, f.key, v),
              ),
            ),
        ]),
      ),
    );
  }
}
