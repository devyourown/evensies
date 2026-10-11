import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/currency_picker.dart';
import '../../core/ids.dart';
import '../../core/money.dart';
import '../../core/snack.dart';
import '../../data/local_writes.dart' show recordedStatus;
import '../../domain/models.dart';
import '../../providers.dart';
import '../expense_form/split_editor.dart' show minorToText;
import '../group_detail/balances.dart';

/// Record a payment, or edit [editing] (docs/API.md 송금 기록·편집): any two members, any amount, currency and date.
/// From a transfer card it opens prefilled with [from], [to], [amount] and [currency]. Returns the saved payment's id
/// (an edit's is new), or null when nothing was saved.
Future<String?> showPaymentSheet(
  BuildContext context, {
  required String groupId,
  Payment? editing,
  String? from,
  String? to,
  int? amount,
  String? currency,
}) =>
    showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => PaymentSheet(
          groupId: groupId, editing: editing, from: from, to: to, amount: amount, currency: currency),
    );

class PaymentSheet extends ConsumerStatefulWidget {
  final String groupId;
  final Payment? editing;
  final String? from, to, currency;
  final int? amount;
  const PaymentSheet({super.key, required this.groupId, this.editing, this.from, this.to, this.amount, this.currency});
  @override
  ConsumerState<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<PaymentSheet> {
  final _amount = TextEditingController();
  String? _from, _to, _currency;
  late String _date = widget.editing?.date ?? todayIso();
  bool _busy = false;
  bool _filled = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  /// Once the group and its members are loaded.
  void _fill(GroupState s, String? myMemberId) {
    if (_filled) return;
    _filled = true;
    final e = widget.editing;
    final active = s.members.where((m) => !m.removed).toList();
    _from = e?.fromMember ?? widget.from ?? myMemberId ?? active.firstOrNull?.id;
    _to = e?.toMember ?? widget.to ?? active.where((m) => m.id != _from).firstOrNull?.id;
    _currency = e?.currency ?? widget.currency ?? s.defaultCurrency;
    final a = e?.amount ?? widget.amount;
    if (a != null) _amount.text = minorToText(a, _currency!);
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_date) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _date = d.toIso8601String().substring(0, 10));
  }

  Future<void> _save(GroupState s, int amount) async {
    setState(() => _busy = true);
    final me = ref.read(sessionProvider).value?.userId;
    final p = Payment(
      id: newId(),
      fromMember: _from!,
      toMember: _to!,
      amount: amount,
      currency: _currency!,
      date: _date,
      status: recordedStatus(s.member(_from!), s.member(_to!), me),
    );
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final w = ref.read(localWritesProvider);
      final old = widget.editing;
      old == null ? await w.createPayment(widget.groupId, p) : await w.editPayment(widget.groupId, old.id, p);
      navigator.pop(p.id);
      final m = formatMoney(amount, p.currency);
      messenger.showSnackBar(SnackBar(
          content: Text(old != null
              ? 'Payment updated'
              : p.pending
                  ? 'Recorded $m. ${s.member(p.toMember)?.name ?? 'They'} will confirm.'
                  : 'Payment of $m recorded')));
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = ref.watch(groupProvider(widget.groupId)).value;
    final s = ref.watch(groupStateProvider(widget.groupId)).value;
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    if (group == null || s == null) {
      return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
    }
    _fill(s, group.myMemberId);
    final e = widget.editing;
    final people = [
      for (final m in s.members)
        if (!m.removed || m.id == e?.fromMember || m.id == e?.toMember || m.id == _from || m.id == _to) m,
    ];
    String label(Member m) => m.id == group.myMemberId ? '${m.name} (you)' : m.name;
    final currency = _currency ?? group.defaultCurrency;
    final amount = parseMoney(_amount.text, currency);
    final same = _from != null && _from == _to;
    final ok = !_busy && _from != null && _to != null && !same && amount != null && amount > 0;
    final hasComments = e != null && s.comments.any((c) => c.paymentId == e.id && !c.deleted);
    final date = DateTime.tryParse(_date);

    final large = MediaQuery.textScalerOf(context).scale(1) > 2;
    final amountField = TextField(
      key: const Key('payment-amount'),
      controller: _amount,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
      decoration: InputDecoration(labelText: 'Amount', hintText: minorToText(0, currency)),
      onChanged: (_) => setState(() {}),
    );
    final picker = CurrencyPicker(
      key: const Key('payment-currency'),
      value: currency,
      pinned: [group.defaultCurrency, ...s.expenses.map((x) => x.currency).toSet()],
      width: large ? null : 116,
      onChanged: (c) => setState(() => _currency = c),
    );

    // Keyed by its value: the field keeps its own state, and Swap changes both from outside.
    Widget person(String label0, String? value, ValueChanged<String?> onChanged, Key key) => KeyedSubtree(
          key: key,
          child: DropdownButtonFormField<String>(
            key: ValueKey(value),
            initialValue: value,
            isExpanded: true,
            decoration: InputDecoration(labelText: label0, border: const OutlineInputBorder()),
            items: [
              for (final m in people)
                DropdownMenuItem(value: m.id, child: Text(label(m), overflow: TextOverflow.ellipsis)),
            ],
            onChanged: _busy ? null : onChanged,
          ),
        );

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, 16 + MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(e == null ? 'Record a payment' : 'Edit payment', style: text.titleLarge),
            const SizedBox(height: 16),
            person('From', _from, (v) => setState(() => _from = v), const Key('payment-from')),
            Align(
              child: IconButton(
                tooltip: 'Swap',
                icon: const Icon(Icons.swap_vert),
                onPressed: () => setState(() {
                  final f = _from;
                  _from = _to;
                  _to = f;
                }),
              ),
            ),
            person('To', _to, (v) => setState(() => _to = v), const Key('payment-to')),
            if (same)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Pick two different people', style: text.bodySmall?.copyWith(color: cs.error)),
              ),
            const SizedBox(height: 16),
            // The largest text sizes: the currency under the amount, where its code fits (as in the expense form).
            if (large)
              ...[amountField, const SizedBox(height: 12), picker]
            else
              Row(children: [Expanded(child: amountField), const SizedBox(width: 12), picker]),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Text(date == null ? _date : DateFormat('EEE, d MMM yyyy').format(date)),
              ),
            ),
            if (hasComments)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(children: [
                  Icon(Icons.chat_bubble_outline, size: 16, color: cs.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('Comments stay with the old payment',
                        key: const Key('comments-stay'), style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  ),
                ]),
              ),
            const SizedBox(height: 24),
            FilledButton(
              key: const Key('payment-save'),
              onPressed: ok ? () => _save(s, amount) : null,
              child: _busy
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(e == null ? 'Record payment' : 'Save'),
            ),
          ]),
        ),
      ),
    );
  }
}
