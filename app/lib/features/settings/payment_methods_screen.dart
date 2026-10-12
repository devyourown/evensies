import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/confirm.dart';
import '../../core/l10n.dart';
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
      if (mounted) showError(context, e);
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
              title: Text(methodLabel(t, ctx.l)),
              subtitle: Text(_typeBlurb(ctx.l, t)),
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
    final l = context.l;
    final ok = await confirm(context,
        title: l.methodRemoveTitle(methodLabel(ms[i].type, l)), message: methodSummary(ms[i]), confirmLabel: l.remove);
    if (ok) await _save([...ms]..removeAt(i));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = context.l;
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
            Text(offline ? l.methodsOffline : l.methodsLoadFailed, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: Text(l.retry)),
          ]),
        ),
      );
    } else if (ms == null) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = ListView(padding: const EdgeInsets.only(bottom: 88), children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text(l.methodsIntro, style: TextStyle(color: cs.onSurfaceVariant)),
        ),
        if (ms.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(l.methodsEmpty, textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant)),
          ),
        for (var i = 0; i < ms.length; i++)
          ListTile(
            leading: Icon(methodIcon(ms[i].type)),
            title: Text(methodLabel(ms[i].type, l)),
            subtitle: Text(methodSummary(ms[i]), maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: _saving ? null : () => _edit(i),
            trailing: IconButton(
              tooltip: l.remove,
              icon: const Icon(Icons.delete_outline),
              onPressed: _saving ? null : () => _delete(i),
            ),
          ),
      ]);
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(l.waysToGetPaid),
        bottom: _saving ? const PreferredSize(preferredSize: Size.fromHeight(2), child: LinearProgressIndicator()) : null,
      ),
      body: body,
      floatingActionButton: ms == null || ms.length >= maxMethods || _saving
          ? null
          : FloatingActionButton.extended(onPressed: _add, icon: const Icon(Icons.add), label: Text(l.add)),
    );
  }
}

String _typeBlurb(AppLocalizations l, String t) => switch (t) {
      PaymentTypes.paypal => l.blurbPaypal,
      PaymentTypes.wise => l.blurbWise,
      PaymentTypes.venmo => l.blurbVenmo,
      PaymentTypes.revolut => l.blurbRevolut,
      PaymentTypes.kakaopay => l.blurbKakaopay,
      PaymentTypes.iban => l.blurbIban,
      PaymentTypes.krBank => l.blurbKrBank,
      _ => '',
    };

class _Field {
  final String key, label;
  final String? hint, prefix;
  final TextInputType keyboard;
  final bool optional;
  const _Field(this.key, this.label, {this.hint, this.prefix, this.keyboard = TextInputType.text, this.optional = false});
}

List<_Field> _fieldsFor(AppLocalizations l, String t) => switch (t) {
      PaymentTypes.paypal => [
          _Field('value', l.fieldPaypal, hint: l.fieldPaypalHint, prefix: 'paypal.me/', keyboard: TextInputType.url),
        ],
      PaymentTypes.revolut => [
          _Field('value', l.fieldRevolut, hint: l.fieldRevolutHint, prefix: 'revolut.me/', keyboard: TextInputType.url),
        ],
      PaymentTypes.venmo => [
          _Field('value', l.fieldVenmo, hint: l.fieldVenmoHint, prefix: '@', keyboard: TextInputType.url),
        ],
      PaymentTypes.wise => [
          _Field('value', l.fieldWise, hint: l.fieldWiseHint, keyboard: TextInputType.url),
        ],
      PaymentTypes.kakaopay => [
          _Field('value', l.fieldKakaopay, hint: l.fieldKakaopayHint, keyboard: TextInputType.url),
        ],
      PaymentTypes.iban => [
          _Field('holder', l.fieldHolder, hint: l.fieldHolderHint),
          _Field('value', l.fieldIban, hint: l.fieldIbanHint, keyboard: TextInputType.url),
          _Field('bic', l.fieldBic, hint: l.fieldBicHint, keyboard: TextInputType.url, optional: true),
        ],
      PaymentTypes.krBank => [
          _Field('bank', l.fieldBank, hint: l.fieldBankHint),
          _Field('value', l.fieldAccountNumber, hint: l.fieldAccountNumberHint, keyboard: TextInputType.number),
          _Field('holder', l.fieldHolder),
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
  static const _keys = {'value', 'holder', 'bank', 'bic'};
  late final _ctl = {
    for (final f in _keys)
      f: TextEditingController(
        text: switch (f) {
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
    final l = context.l;
    return Scaffold(
      appBar: AppBar(
        title: Text(methodLabel(widget.type, l)),
        actions: [TextButton(onPressed: _done, child: Text(l.done))],
      ),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          for (final f in _fieldsFor(l, widget.type))
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
                validator: (v) => switch (methodFieldError(widget.type, f.key, v)) {
                  final code? => methodErrorText(l, widget.type, code),
                  null => null,
                },
              ),
            ),
        ]),
      ),
    );
  }
}
