import 'dart:async';

import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, mapEquals;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/confirm.dart';
import '../../core/currency_picker.dart';
import '../../core/env.dart';
import '../../core/ids.dart';
import '../../core/l10n.dart';
import '../../core/money.dart';
import '../../core/snack.dart';
import '../../data/api/dto.dart';
import '../../data/db/database.dart';
import '../../data/fx_rates.dart';
import '../../data/images.dart';
import '../../data/receipts.dart';
import '../../data/sync/group_state_store.dart';
import '../../domain/balances.dart' show tryFx;
import '../../domain/categories.dart';
import '../../domain/fx.dart';
import '../../domain/itemized.dart';
import '../../domain/models.dart';
import '../../domain/receipt_parser.dart';
import '../../domain/recurrence.dart';
import '../../domain/split.dart';
import '../../providers.dart';
import '../auth/auth_service.dart' show infoProvider;
import '../../data/local_writes.dart' show MoveException;
import '../categories/category_ui.dart';
import '../expense_detail/expense_detail_screen.dart' show DeletedExpenseCard;
import '../friends/friend_screen.dart' show groupForExpenseWith;
import '../friends/home_data.dart';
import '../friends/with_picker.dart';
import '../group_detail/balances.dart' show groupStateProvider;
import '../itemize/itemize_screen.dart';
import '../receipts/receipt_widgets.dart';
import 'split_editor.dart';

class ExpenseFormScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String? expenseId;
  const ExpenseFormScreen({super.key, required this.groupId, this.expenseId});
  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _amount = TextEditingController();
  final _description = TextEditingController();
  final _fx = TextEditingController();
  /// The stored or picked category (a key, legacy text, or null); [_catAuto] while it is a guess.
  String? _cat;
  bool _catAuto = false;

  /// Guessing stops for good once the user picks (General included).
  bool _catTouched = false;

  /// Only a new expense or one stored without a category is guessed (docs/API.md, Categories).
  bool _guessable = true;
  Timer? _guessTimer;

  /// The group's other non-deleted expenses, oldest first, for guessCategory.
  List<({String description, String? category})> _history = const [];
  final _notes = TextEditingController();
  static const _maxNotes = 500; // UTF-16 units, like the server
  static const _maxDescription = 200; // the server checks it only when sent, so an unchanged long one may stay
  final _split = SplitEditorController();
  final _payerFields = <String, TextEditingController>{};
  bool _several = false; // "Several people" paid
  String? _currency;
  String? _paidBy;
  bool _refund = false;
  String _date = todayIso();
  Expense? _editing;
  /// The stored split when the editor couldn't rebuild it and opened as exact: kept if the shares stay the same.
  SplitSpec? _keptSplit;
  /// Set when the group's default split no longer computes for today's members and the form starts as equal.
  String? _defaultNote;
  bool _loaded = false;
  bool _busy = false;

  /// Editing only: the friend or group picked under *With* (docs/API.md, Moving expenses); Save then moves the expense.
  WithChoice? _moveTo;

  /// The moved expense's id, its push's clientId and its receipts' new ids and clientIds, made once per [_moveTo]
  /// (docs/API.md, Moving expenses).
  ({String expenseId, String clientId, Map<String, ({String id, String clientId})> receipts})? _moveIds;

  /// A new expense's id, made when the form opens (its receipts are prepared under it).
  late final String _newId = newId();

  /// Photos added in this form (prepared files, attached on Save; deleted if the form is left without saving).
  final _newReceipts = <String>[];
  bool _saved = false;
  bool _scanning = false;

  /// The scanned photo and what it says the bill comes to (a mismatch is only a warning on the Itemize screen).
  String? _scanId;
  int? _printedTotal;

  /// The last scan's items: Items opens with them while the form has no bill yet (after a Cancel on the scan).
  ItemizedBill? _scanBill;
  late final ReceiptFiles _files;

  /// Repeat (docs/API.md, Recurring expenses): the picked schedule, null = Never.
  String? _repeat;

  /// Editing an expense of a live series: that series, its latest repeat (only that one's edits carry forward) and
  /// the highest occurrence added so far (for the "Next:" line).
  Recurrence? _series;
  Expense? _latest;
  int _lastPosted = 0;

  /// "Also change future repeats" on the latest repeat.
  bool _future = true;

  /// Email a reminder this many days before each repeat (Phase 10, rule 18); null = Never.
  int? _remind;

  /// The rate field was typed in this session (or holds a stored rate): kept when the date changes.
  bool _fxTyped = false;

  /// The rate table for [_date] (server or cache) while the currency is foreign; null = no automatic rate.
  FxTable? _fxTable;
  bool _fxLoading = false;
  int _fxAsk = 0; // a newer lookup drops the answer of an older one

  static String lastCurrencyKey(String groupId) => 'lastCurrency.$groupId';

  @override
  void initState() {
    super.initState();
    _files = ref.read(receiptFilesProvider);
    _split.addListener(_changed);
  }

  void _changed() => setState(() {});

  @override
  void dispose() {
    // Cancel deletes the photos prepared here (an attached one belongs to the expense now).
    if (!_saved && _newReceipts.isNotEmpty) _files.delete([..._newReceipts]);
    _split.dispose();
    _guessTimer?.cancel();
    for (final c in [_amount, _description, _fx, _notes, ..._payerFields.values]) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _payer(String memberId) => _payerFields.putIfAbsent(memberId, TextEditingController.new);

  Future<void> _loadExisting() async {
    _loaded = true;
    final db = ref.read(dbProvider);
    final id = widget.expenseId;
    final state = await GroupStateStore(db).load(widget.groupId);
    _history = [
      for (final x in state.expenses)
        if (!x.deleted && x.id != id) (description: x.description, category: x.category),
    ];
    if (id == null) {
      // A new expense starts in the last currency used in this group.
      final last = ref.read(sharedPreferencesProvider).getString(lastCurrencyKey(widget.groupId));
      final d = (await db.getGroup(widget.groupId))?.defaultCurrency;
      if (last != null && Money.decimals.containsKey(last) && last != d && mounted) {
        setState(() => _currency = last);
        _lookupRate(apply: true);
      }
      return _startFromDefault(db);
    }
    final e = state.expense(id);
    if (e == null || !mounted) return;
    final rated = (e.fxRateToDefault ?? 0) > 0; // 0 = not converted, like null
    final series = state.isActive(e.recurrenceId) ? state.recurrence(e.recurrenceId!) : null;
    setState(() {
      _editing = e;
      _series = series;
      _latest = series == null ? null : state.latestRepeat(series.id);
      _lastPosted = series == null ? 0 : state.lastPosted(series.id);
      _repeat = series?.frequency; // a stopped series starts at Never: picking one starts a new series
      _remind = series?.remindDaysBefore;
      _future = true;
      _amount.text = inputAmount(e.amount, e.currency);
      _description.text = e.description;
      _fx.text = rated ? numberText(e.fxRateToDefault!, decimals: 10) : '';
      _fxTyped = rated;
      _cat = e.category;
      _catAuto = false;
      _guessable = e.category == null;
      _notes.text = e.notes ?? '';
      _currency = e.currency;
      _date = e.date;
      _refund = e.refund;
      _several = e.payers.length > 1;
      _paidBy = e.paidBy;
      for (final p in e.payers) {
        _payer(p.memberId).text = inputAmount(p.amount, e.currency);
      }
      _openSplit(e, [for (final m in state.members) m.id]);
    });
    // Opening changes nothing: the automatic rate is offered ("Use automatic rate"); a date change fills it in
    // unless a rate is stored.
    if (e.currency != state.defaultCurrency) _lookupRate(apply: false);
  }

  /// Looks up the automatic rate for the form's currency on [_date] (docs/API.md, Exchange rates: server, else this device's
  /// cache). With [apply] it goes into the rate field unless the user typed one.
  Future<void> _lookupRate({required bool apply}) async {
    final ask = ++_fxAsk;
    setState(() => _fxLoading = true);
    final table = await ref.read(fxRatesProvider).lookup(_date);
    final d = (await ref.read(dbProvider).getGroup(widget.groupId))?.defaultCurrency;
    if (!mounted || ask != _fxAsk) return;
    setState(() {
      _fxLoading = false;
      _fxTable = table;
      final auto = d == null || _currency == null ? null : _autoRate(_currency!, d);
      if (apply && !_fxTyped) _fx.text = auto == null ? '' : numberText(auto, decimals: 10);
    });
  }

  double? _autoRate(String currency, String d) => _fxTable == null ? null : crossRate(_fxTable!.rates, currency, d);

  /// ponytail: Items keep their minor units when the currency changes (EUR 12.50 → JPY ¥1,250); convert the bill if
  /// people scan in one currency and then switch to one with other decimals.
  void _setCurrency(String c, String d) {
    _fxAsk++; // an answer for the old currency is stale
    setState(() {
      _currency = c;
      _fxTyped = false; // a rate typed for another currency means nothing for this one
      _fxTable = null;
      _fxLoading = false;
      _fx.clear();
      if (_split.items && _split.bill != null) _amount.text = inputAmount(itemizedTotal(_split.bill!), c);
    });
    if (c != d) _lookupRate(apply: true);
  }

  /// The stored mode with the typed numbers (or the items) when they still give the stored shares (zeros aside);
  /// otherwise the amounts as exact (docs/API.md SplitSpec). No split (exact, or saved before Phase 3) whose shares are
  /// an equal split of the people in it opens as equal.
  void _openSplit(Expense e, List<String> shown) {
    final ids = [for (final s in e.shares) s.memberId];
    Map<String, int> nonZero(Map<String, int> m) => {
          for (final x in m.entries)
            if (x.value != 0) x.key: x.value
        };
    final stored = nonZero({for (final s in e.shares) s.memberId: s.amount});
    final spec = e.split;
    Map<String, int>? again;
    _keptSplit = null;
    if (spec != null && ids.isNotEmpty) {
      try {
        again = switch (spec.bill) {
          final b? => itemizedTotal(b) == e.amount ? computeItemizedSplit(b) : null,
          null => computeSplit(amount: e.amount, mode: spec.mode!, members: ids, input: spec.input),
        };
      } on SplitException {
        again = null;
      }
    }
    if (ids.isEmpty) {
      _split.loadEqual(shown, shown); // no shares stored (not written by this app): start like a new expense
    } else if (spec == null &&
        stored.isNotEmpty &&
        mapEquals(computeSplit(amount: e.amount, mode: SplitMode.equal, members: stored.keys.toList()), stored)) {
      _split.loadEqual(stored.keys, {...shown, ...ids});
    } else if (spec == null || again == null || !mapEquals(nonZero(again), stored)) {
      _split.loadExact(e.shares, e.currency);
      _keptSplit = spec;
    } else if (spec.mode == SplitMode.equal) {
      _split.loadEqual(ids, {...shown, ...ids});
    } else {
      _split.load(spec, e.currency);
    }
  }

  /// New expense: the group's default split (percent or shares) if it can be computed for today's members,
  /// otherwise equal with everyone ticked.
  Future<void> _startFromDefault(AppDatabase db) async {
    final spec = splitFromJson((await db.getGroup(widget.groupId))?.defaultSplitJson);
    final mode = spec?.mode;
    if (spec == null || mode == null || mode == SplitMode.equal) return;
    final ids = [
      for (final m in await (db.select(db.members)..where((m) => m.groupId.equals(widget.groupId))).get())
        if (!m.removed) m.id
    ];
    if (!mounted) return;
    if (!splitFits(spec, ids)) {
      return setState(() => _defaultNote = context.l.defaultSplitStartsEqual);
    }
    _split.load(SplitSpec(mode, {for (final id in ids) id: spec.input?[id] ?? 0.0}), ''); // joined later: 0
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) _loadExisting();
  }

  /// Several payers: per person amounts (empty or zero dropped) that must add up to [amount].
  ({List<Share>? payers, String status, bool ok}) _payers(
      AppLocalizations l, int? amount, List<MemberRow> members, String currency, String? single) {
    if (!_several) {
      return single == null || amount == null
          ? (payers: null, status: '', ok: false)
          : (payers: [Share(memberId: single, amount: amount)], status: '', ok: true);
    }
    final list = <Share>[];
    for (final m in members) {
      final t = _payer(m.id).text.trim();
      if (t.isEmpty) continue;
      final v = parseMoney(t, currency);
      if (v == null || v < 0) return (payers: null, status: l.checkAmounts, ok: false);
      if (v > 0) list.add(Share(memberId: m.id, amount: v));
    }
    if (amount == null) return (payers: null, status: l.enterTotalFirst, ok: false);
    final left = amount - list.fold<int>(0, (a, p) => a + p.amount);
    if (left > 0) return (payers: null, status: l.leftToAssign(formatMoney(left, currency)), ok: false);
    if (left < 0) return (payers: null, status: l.overBy(formatMoney(-left, currency)), ok: false);
    // A zero total still needs a payer.
    if (list.isEmpty && single != null) list.add(Share(memberId: single, amount: 0));
    return (payers: list, status: l.addsUp, ok: list.isNotEmpty);
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_date) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d == null) return;
    setState(() => _date = d.toIso8601String().substring(0, 10));
    final group = ref.read(groupProvider(widget.groupId)).value;
    if (group != null && (_currency ?? group.defaultCurrency) != group.defaultCurrency) _lookupRate(apply: true);
  }

  /// "Ben owes the full amount" / "I owe Ben the full amount": one payer, equal with only [owes] ticked.
  void _setFull(String payer, String owes, List<String> shown) => setState(() {
        _several = false;
        _paidBy = payer;
        _split.loadEqual([owes], shown);
      });

  bool _isFull(String? paidBy, String payer, String owes, List<String> shown) =>
      !_several &&
      paidBy == payer &&
      !_split.items &&
      _split.mode == SplitMode.equal &&
      shown.where((id) => !_split.unticked.contains(id)).toList().join() == owes;

  @override
  Widget build(BuildContext context) {
    final group = ref.watch(groupProvider(widget.groupId)).value;
    final all = ref.watch(membersProvider(widget.groupId)).value ?? const <MemberRow>[];
    final e0 = _editing;
    bool involved(String id) =>
        e0 != null && (e0.payers.any((p) => p.memberId == id) || e0.shares.any((s) => s.memberId == id));
    final members = all.where((m) => !m.removed || involved(m.id)).toList();
    if (group == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l = context.l;
    final large = MediaQuery.textScalerOf(context).scale(1) > 2;
    final ids = [for (final m in members) m.id];
    final currency = _currency ?? group.defaultCurrency;
    final d = group.defaultCurrency;
    final foreign = currency != d;
    final fxText = _fx.text.trim();
    final fxValue = fxText.isEmpty ? null : parseDecimal(fxText);
    // Empty is fine (the expense stays under Not converted); 0 is refused: it would mean the same, but silently.
    final fxBad = foreign && fxText.isNotEmpty && (fxValue == null || !fxValue.isFinite || fxValue <= 0);
    final autoRate = foreign ? _autoRate(currency, d) : null;
    final paidBy = _paidBy ?? group.myMemberId ?? members.firstOrNull?.id;
    final items = _split.items ? _split.bill : null;
    // Items: the amount is the bill's total (read-only).
    final amount = items != null ? itemizedTotal(items) : parseMoney(_amount.text, currency);
    final deleted = _editing?.deleted ?? false;
    final notesLength = _notes.text.trim().length;
    final descriptionLength = _description.text.trim().length;
    final descriptionTooLong = descriptionLength > _maxDescription && _description.text.trim() != _editing?.description;
    final split = _split.evaluate(amount: amount, ids: ids, currency: currency, l: l);
    final payers = _payers(l, amount, members, currency, paidBy);
    final canSave = !_busy &&
        !deleted &&
        notesLength <= _maxNotes &&
        !descriptionTooLong &&
        !fxBad &&
        amount != null &&
        amount > 0 &&
        _description.text.trim().isNotEmpty &&
        members.isNotEmpty &&
        payers.ok &&
        split.ok &&
        split.shares != null;
    final dateLabel = DateFormat.yMMMEd().format(DateTime.tryParse(_date) ?? DateTime.now());
    final active = all.where((m) => !m.removed).toList();
    final me = group.myMemberId;
    final other = active.length == 2 && active.any((m) => m.id == me) ? active.firstWhere((m) => m.id != me) : null;

    final amountField = TextField(
      key: const Key('amount'),
      controller: _amount,
      autofocus: widget.expenseId == null,
      readOnly: items != null,
      style: text.displaySmall?.copyWith(fontWeight: FontWeight.w600),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        hintText: inputAmount(0, currency),
        border: InputBorder.none,
        isDense: true,
        helperText: items != null ? l.itemsTotal : null,
      ),
      onTap: items != null ? _openItems : null,
      onChanged: (_) => setState(() {}),
    );
    final picker = CurrencyPicker(
      key: const Key('currency'),
      value: currency,
      pinned: [
        d,
        ref.watch(homeCurrencyProvider),
        ?ref.read(sharedPreferencesProvider).getString(lastCurrencyKey(widget.groupId)),
      ],
      width: large ? null : 116,
      bare: true,
      textStyle: text.titleMedium?.copyWith(color: cs.onSurface),
      onChanged: (c) => _setCurrency(c, d),
    );

    Widget sectionLabel(String s) => Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: Text(s, style: text.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
        );

    Widget statusLine(String s, bool ok, {Key? key}) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(children: [
            Icon(ok ? Icons.check_circle_outline : Icons.info_outline, size: 16, color: ok ? cs.primary : cs.error),
            const SizedBox(width: 6),
            Expanded(child: Text(s, key: key, style: text.bodySmall?.copyWith(color: ok ? cs.primary : cs.error))),
          ]),
        );

    final stored = _editing == null
        ? const <String>[]
        : [
            for (final a in ref.watch(groupStateProvider(widget.groupId)).value?.receiptsOf(_editing!.id) ??
                const <Attachment>[])
              a.id
          ];
    final receiptRoom = stored.length + _newReceipts.length < maxReceipts;
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing == null ? l.newExpense : (deleted ? l.deletedExpense : l.editExpense)),
        actions: [
          if (canScanReceipts && !deleted && receiptRoom)
            IconButton(
              key: const Key('scan-receipt'),
              tooltip: l.scanReceipt,
              onPressed: _scanning ? null : _scan,
              icon: _scanning
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.document_scanner_outlined),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (deleted)
            DeletedExpenseCard(groupId: widget.groupId, expenseId: _editing!.id, onRestore: _busy ? null : _restore),
          // A deleted expense is read-only until restored, so no stale edit survives the restore.
          IgnorePointer(
            ignoring: deleted,
            child: Opacity(
              opacity: deleted ? 0.6 : 1,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                _withTile(group.name, cs, text),
                // The largest text sizes: the currency under the amount, where its code fits.
                if (large)
                  ...[amountField, picker]
                else
                  Row(children: [Expanded(child: amountField), const SizedBox(width: 12), picker]),
                const Divider(height: 1),
                if (foreign) ...[
                  if (_approx(amount, currency, d, fxBad ? null : fxValue) case final approx?)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(l.approx(formatMoney(approx, d)),
                          key: const Key('fx-approx'), style: text.titleSmall?.copyWith(color: cs.onSurfaceVariant)),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: TextField(
                      key: const Key('fx'),
                      controller: _fx,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: l.rateLabel(currency, d),
                        prefixIcon: const Icon(Icons.currency_exchange),
                        helperText: _fxLoading ? l.lookingUpRate : _fxSource(l, currency, d, fxValue, autoRate),
                        helperMaxLines: 3,
                        errorText: fxBad ? l.rateAboveZeroOrEmpty : null,
                        suffixIcon: _fxLoading
                            ? const Padding(
                                padding: EdgeInsets.all(14),
                                child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                              )
                            : null,
                      ),
                      onChanged: (_) => setState(() => _fxTyped = true),
                    ),
                  ),
                  if (!_fxLoading && autoRate != null && fxValue != autoRate)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        key: const Key('fx-auto'),
                        onPressed: () => setState(() {
                          _fx.text = numberText(autoRate, decimals: 10);
                          _fxTyped = false;
                        }),
                        icon: const Icon(Icons.restart_alt, size: 18),
                        label: Text(l.useAutoRate(numberText(autoRate, decimals: 10), _fxDay(l))),
                      ),
                    ),
                ],
                const SizedBox(height: 16),
                TextField(
                  key: const Key('description'),
                  controller: _description,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l.description,
                    prefixIcon: const Icon(Icons.notes),
                    counterText: descriptionLength > _maxDescription - 20 ? '$descriptionLength/$_maxDescription' : null,
                    errorText: descriptionTooLong ? l.tooLong : null,
                  ),
                  onChanged: (_) {
                    setState(() {});
                    _scheduleGuess();
                  },
                ),
                sectionLabel(_refund ? l.receivedBy : l.paidBy),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (final m in members)
                      ChoiceChip(
                        label: Text(m.name),
                        selected: !_several && m.id == paidBy,
                        onSelected: (_) => setState(() {
                          _several = false;
                          _paidBy = m.id;
                        }),
                      ),
                    ChoiceChip(
                      key: const Key('several-payers'),
                      avatar: const Icon(Icons.group_outlined, size: 18),
                      label: Text(l.severalPeople),
                      selected: _several,
                      onSelected: (_) => setState(() {
                        // Start from what the single payer paid.
                        if (!_several && paidBy != null && _payerFields.values.every((c) => c.text.trim().isEmpty)) {
                          _payer(paidBy).text = _amount.text.trim();
                        }
                        _several = true;
                      }),
                    ),
                  ],
                ),
                if (_several) ...[
                  for (final m in members)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextField(
                        key: Key('payer-${m.id}'),
                        controller: _payer(m.id),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                            labelText: m.name, isDense: true, suffixText: currency, hintText: inputAmount(0, currency)),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  statusLine(payers.status, payers.ok, key: const Key('payers-status')),
                ],
                sectionLabel(l.when),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: Text(dateLabel),
                  ),
                  _repeatButton(),
                ]),
                ..._repeatNotes(cs, text),
                const SizedBox(height: 8),
                // Wraps Refund to its own line at the largest text sizes, so the category keeps its label.
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _categoryButton(cs, text),
                    FilterChip(
                      key: const Key('refund'),
                      avatar: Icon(Icons.undo, size: 18, color: _refund ? cs.onSecondaryContainer : cs.onSurfaceVariant),
                      showCheckmark: false,
                      label: Text(l.refund),
                      tooltip: l.refundTooltip,
                      selected: _refund,
                      onSelected: (v) => setState(() => _refund = v),
                    ),
                  ],
                ),
                sectionLabel(_refund ? l.splitBackTo : l.split),
                // A refund reverses who owes whom, so the labels would be backwards (Splitwise hides them too).
                if (other != null && me != null && !_refund) ...[
                  Wrap(spacing: 8, runSpacing: 4, children: [
                    ChoiceChip(
                      key: const Key('full-they-owe'),
                      label: Text(l.theyOweFull(other.name)),
                      selected: _isFull(paidBy, me, other.id, ids),
                      onSelected: (_) => _setFull(me, other.id, ids),
                    ),
                    ChoiceChip(
                      key: const Key('full-i-owe'),
                      label: Text(l.iOweFull(other.name)),
                      selected: _isFull(paidBy, other.id, me, ids),
                      onSelected: (_) => _setFull(other.id, me, ids),
                    ),
                  ]),
                  const SizedBox(height: 12),
                ],
                if (_defaultNote != null && !_split.items && _split.mode == SplitMode.equal)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(_defaultNote!, key: const Key('default-note'), style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  ),
                SplitEditor(
                    controller: _split, members: members, amount: amount, currency: currency, onItems: _openItems),
                sectionLabel(l.receipts),
                _receiptsSection(group.id, stored, receiptRoom),
                const SizedBox(height: 16),
                TextField(
                  key: const Key('notes'),
                  controller: _notes,
                  minLines: 1,
                  maxLines: 5,
                  // No maxLength: Flutter counts characters as seen (an emoji is 1), the limit counts UTF-16 units.
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: l.notes,
                    prefixIcon: const Icon(Icons.sticky_note_2_outlined),
                    counterText: notesLength > _maxNotes - 50 ? '$notesLength/$_maxNotes' : null,
                    errorText: notesLength > _maxNotes ? l.tooLong : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: canSave ? () => _save(group, ids, currency, amount, payers.payers!, split.shares!) : null,
            child: _busy
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l.save),
          ),
        ],
      ),
    );
  }

  /// Whether this is the latest repeat of a live series: Repeat and "Also change future repeats" act on the series.
  bool get _isLatest => _series != null && _latest?.id == _editing?.id;

  /// Saving starts a schedule from this expense: a new series (new expense, or none live), or on the latest repeat a
  /// new frequency, or a new date carried forward.
  bool get _restarts =>
      _repeat != null &&
      (_series == null ||
          (_isLatest && (_repeat != _series!.frequency || (_future && _date != _editing!.date))));

  /// Repeat next to the date: Never / Every week / … An older repeat of a live series can't change it (the latest
  /// can), and neither can an expense about to move.
  Widget _repeatButton() {
    final locked = (_series != null && !_isLatest) || _moveTo != null;
    return MenuAnchor(
      menuChildren: [
        for (final f in [null, ...frequencies])
          MenuItemButton(
            key: Key('repeat-${f ?? 'never'}'),
            leadingIcon: f == _repeat ? const Icon(Icons.check, size: 18) : const SizedBox(width: 18),
            onPressed: () => setState(() => _repeat = f),
            child: Text(repeatLabel(context.l, f)),
          ),
      ],
      builder: (context, menu, _) => Tooltip(
        message: context.l.repeat,
        child: OutlinedButton.icon(
          key: const Key('repeat'),
          onPressed: locked ? null : () => menu.isOpen ? menu.close() : menu.open(),
          icon: const Icon(Icons.repeat, size: 18),
          label: Text(repeatLabel(context.l, _repeat)),
        ),
      ),
    );
  }

  /// Under Date and Repeat: when the next repeat comes, why an older repeat can't change the schedule, what Never
  /// does to a series, and on the latest repeat whether the edit carries forward.
  List<Widget> _repeatNotes(ColorScheme cs, TextTheme text) {
    final series = _series;
    final l = context.l;
    Widget note(Key key, IconData icon, String s) => Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(children: [
            Icon(icon, size: 16, color: cs.onSurfaceVariant),
            const SizedBox(width: 6),
            Expanded(child: Text(s, key: key, style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant))),
          ]),
        );
    if (series != null && !_isLatest) {
      final d = DateTime.tryParse(_latest?.date ?? '');
      return [
        note(const Key('repeat-hint'), Icons.info_outline,
            l.editLatestRepeat(d == null ? _latest?.date ?? '' : DateFormat.MMMd().format(d))),
      ];
    }
    final f = _repeat;
    if (f == null) {
      return [
        if (series != null)
          note(const Key('repeat-stop'), Icons.info_outline, l.stopsRepeating),
      ];
    }
    // No past dates are filled in: the first repeat is on or after today (docs/API.md, Recurring expenses).
    final next = _restarts
        ? firstOccurrenceOnOrAfter(f, _date, todayIso())
        : firstOccurrenceOnOrAfter(series!.frequency, series.startDate, todayIso(), minN: _lastPosted + 1);
    final nextDay = DateTime.tryParse(next.date);
    return [
      note(const Key('repeat-next'), Icons.event_repeat,
          l.nextRepeat(nextDay == null ? next.date : DateFormat.yMMMEd().format(nextDay))),
      // Email a reminder (Phase 10): only when this server sends email.
      if (ref.watch(infoProvider).emailLogin) _reminderButton(cs, text),
      if (series != null && f == series.frequency)
        CheckboxListTile(
          key: const Key('repeat-future'),
          contentPadding: EdgeInsets.zero,
          dense: true,
          controlAffinity: ListTileControlAffinity.leading,
          value: _future,
          onChanged: (v) => setState(() => _future = v ?? true),
          title: Text(l.alsoChangeFuture),
          subtitle: Text(_future ? l.futureFields : l.onlyThisOne),
        ),
    ];
  }

  /// "Email a reminder: Never / 1 day before / 3 days before / 7 days before"; everyone on the expense who has an
  /// email gets it (docs/API.md rule 18).
  Widget _reminderButton(ColorScheme cs, TextTheme text) {
    final l = context.l;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: MenuAnchor(
        menuChildren: [
          for (final d in const [null, 1, 3, 7])
            MenuItemButton(
              key: Key('remind-${d ?? 'never'}'),
              leadingIcon: d == _remind ? const Icon(Icons.check, size: 18) : const SizedBox(width: 18),
              onPressed: () => setState(() => _remind = d),
              child: Text(d == null ? l.remindNever : l.remindDaysBefore(d)),
            ),
        ],
        builder: (context, menu, _) => TextButton.icon(
          key: const Key('remind'),
          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 4)),
          onPressed: () => menu.isOpen ? menu.close() : menu.open(),
          icon: Icon(_remind == null ? Icons.notifications_none : Icons.notifications_active_outlined, size: 18),
          label: Text(l.emailReminder(_remind == null ? l.remindNever : l.remindDaysBefore(_remind!))),
        ),
      ),
    );
  }

  /// The receipts already on the expense (tap: full screen, remove) and the ones added here (attached on Save; the
  /// cross takes one back), with Scan and Add while there is room.
  Widget _receiptsSection(String groupId, List<String> stored, bool room) {
    final cs = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (stored.isNotEmpty || _newReceipts.isNotEmpty)
        SizedBox(
          height: 80,
          child: ListView(scrollDirection: Axis.horizontal, children: [
            for (final (i, id) in stored.indexed)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: ReceiptThumb(
                  key: Key('receipt-$id'),
                  groupId: groupId,
                  attachmentId: id,
                  onTap: () => openReceiptViewer(context, groupId: groupId, ids: stored, initial: i),
                ),
              ),
            for (final id in _newReceipts)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: Stack(clipBehavior: Clip.none, children: [
                  ReceiptThumb(key: Key('new-receipt-$id'), groupId: groupId, attachmentId: id),
                  PositionedDirectional(
                    top: -6,
                    end: -6,
                    child: IconButton.filledTonal(
                      key: Key('new-receipt-remove-$id'),
                      tooltip: context.l.photoRemove,
                      visualDensity: VisualDensity.compact,
                      iconSize: 16,
                      onPressed: () {
                        setState(() => _newReceipts.remove(id));
                        _files.delete([id]);
                      },
                      icon: const Icon(Icons.close),
                    ),
                  ),
                ]),
              ),
          ]),
        ),
      if (room)
        Wrap(spacing: 8, runSpacing: 4, children: [
          if (canScanReceipts)
            OutlinedButton.icon(
              key: const Key('scan-receipt-button'),
              onPressed: _scanning ? null : _scan,
              icon: const Icon(Icons.document_scanner_outlined),
              label: Text(context.l.scanReceipt),
            ),
          OutlinedButton.icon(
            key: const Key('add-receipt'),
            onPressed: _scanning ? null : _addPhoto,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: Text(context.l.addPhoto),
          ),
        ])
      else
        Text(context.l.maxReceiptsNote(maxReceipts),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
    ]);
  }

  Future<void> _addPhoto() async {
    final source = await pickImageSource(context);
    if (source == null || !mounted) return;
    setState(() => _scanning = true);
    try {
      final photo = await ref.read(pickReceiptProvider)(source, scan: false);
      if (photo != null && mounted) setState(() => _newReceipts.add(photo.id));
    } catch (e) {
      if (mounted) showError(context, photoErrorText(context.l, e, source));
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
  }

  /// Scan: the photo's text (on the phone) → the Itemize screen with its lines, tax, tip and discount; the shop's name
  /// fills an empty description, and on a Cancel the printed total an empty amount. Nothing read, and the receipt names
  /// another currency: offers to switch to it. The photo is attached on Save either way.
  Future<void> _scan() async {
    final source = await pickImageSource(context, title: context.l.scanAReceipt);
    if (source == null || !mounted) return;
    final d = ref.read(groupProvider(widget.groupId)).value?.defaultCurrency ?? '';
    var currency = _currency ?? d;
    final script = ocrScript(currency, Localizations.localeOf(context).languageCode);
    setState(() => _scanning = true);
    ReceiptPhoto? photo;
    try {
      photo = await ref.read(pickReceiptProvider)(source, scan: true, script: script);
    } catch (e) {
      if (mounted) showError(context, photoErrorText(context.l, e, source));
    } finally {
      if (mounted) setState(() => _scanning = false);
    }
    if (photo == null || !mounted) return;
    final scanned = photo;
    setState(() {
      _newReceipts.add(scanned.id);
      _scanId = scanned.id;
    });
    var lines = scanned.lines ?? const <OcrLine>[];
    var draft = parseReceipt(lines, decimals: Money.digits(currency));
    if (draft.lines.isEmpty && script == 'latin' && defaultTargetPlatform == TargetPlatform.android) {
      setState(() => _scanning = true);
      final cjk = await recognizeCjk(ref.read(receiptFilesProvider), scanned.id);
      if (!mounted) return;
      setState(() => _scanning = false);
      if (cjk != null) {
        lines = cjk;
        draft = parseReceipt(lines, decimals: Money.digits(currency));
      }
    }
    final other = draft.lines.isEmpty ? receiptCurrency(lines, known: Money.decimals.keys.toSet()) : null;
    if (other != null && other != currency) {
      final again = parseReceipt(lines, decimals: Money.digits(other));
      if (again.lines.isNotEmpty &&
          await confirm(context,
              title: context.l.receiptLooksLike(other),
              message: context.l.switchToCurrencyQuestion(other),
              confirmLabel: context.l.switchTo(other),
              destructive: false) &&
          mounted) {
        _setCurrency(other, d);
        currency = other;
        draft = again;
      }
    }
    if (!mounted) return;
    if (draft.lines.isEmpty) showInfo(context, context.l.couldntReadItems);
    final bill = ItemizedBill(
      lines: [for (final l in draft.lines) ItemLine(name: l.name, amount: l.amount, memberIds: const [])],
      tax: draft.tax,
      tip: draft.tip,
      discount: draft.discount,
    );
    setState(() {
      _printedTotal = draft.total;
      _scanBill = bill;
    });
    final done = await _openItems(start: bill);
    if (!mounted) return;
    // Nothing read: the "merchant" is likely OCR noise (a Korean header under the Latin model).
    if (draft.merchant case final merchant? when draft.lines.isNotEmpty && _description.text.trim().isEmpty) {
      setState(() => _description.text = merchant);
      _scheduleGuess();
    }
    if (draft.total case final total? when !done && !_split.items && (parseMoney(_amount.text, currency) ?? 0) == 0) {
      setState(() => _amount.text = inputAmount(total, currency));
    }
  }

  /// The Itemize screen for the items (or [start], a scanned draft), with the scanned photo on top while it is still
  /// here; Done switches the split to Items and the amount to the bill's total. False when the user went back.
  Future<bool> _openItems({ItemizedBill? start}) async {
    final group = ref.read(groupProvider(widget.groupId)).value;
    final currency = _currency ?? group?.defaultCurrency ?? '';
    final all = ref.read(membersProvider(widget.groupId)).value ?? const <MemberRow>[];
    final scan = _scanId != null && _newReceipts.contains(_scanId) ? _scanId : null;
    final image = scan == null ? null : _files.pending(scan);
    final bill = await showItemize(context,
        members: all,
        currency: currency,
        bill: start ?? _split.bill ?? _scanBill,
        me: group?.myMemberId,
        image: image,
        printedTotal: scan == null ? null : _printedTotal,
        printedTip: (_scanBill?.tip ?? 0) != 0);
    if (bill == null || !mounted) return false;
    setState(() {
      _split.setItems(bill);
      _amount.text = inputAmount(itemizedTotal(bill), currency);
    });
    return true;
  }

  /// *With*: the friend or group of this expense. While editing, picking another one moves the expense on Save.
  Widget _withTile(String groupName, ColorScheme cs, TextTheme text) {
    final home = ref.watch(homeDataProvider).value;
    final l = context.l;
    final current = home?.label(widget.groupId, l) ?? groupName;
    final m = _moveTo;
    final target = m == null ? null : (m.person != null ? l.nonGroupWith(m.person!.name) : home?.label(m.groupId!, l) ?? '');
    final canMove = _editing != null && !(_editing?.deleted ?? false);
    return ListTile(
      key: const Key('with'),
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(target == null ? Icons.group_outlined : Icons.drive_file_move_outline,
          color: target == null ? cs.onSurfaceVariant : cs.primary),
      title: Text(target == null ? l.withName(current) : l.movesTo(target),
          style: text.bodyLarge?.copyWith(color: target == null ? null : cs.primary)),
      subtitle: target == null ? null : Text(l.fromName(current)),
      trailing: !canMove
          ? null
          : target == null
              ? const Icon(Icons.chevron_right)
              : IconButton(
                  tooltip: l.dontMove,
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() {
                    _moveTo = null;
                    _moveIds = null;
                  }),
                ),
      onTap: canMove ? _pickWith : null,
    );
  }

  Future<void> _pickWith() async {
    final picked = await showModalBottomSheet<WithChoice>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) => SizedBox(
        height: MediaQuery.sizeOf(ctx).height * 0.75,
        child: WithPicker(except: widget.groupId, onPick: (c) => Navigator.pop(ctx, c)),
      ),
    );
    if (picked == null || !mounted) return;
    final same = picked.groupId == widget.groupId || (picked.person?.friendGroups.contains(widget.groupId) ?? false);
    setState(() {
      _moveTo = same ? null : picked;
      _moveIds = null;
    });
  }

  /// Online only: the target friend group is created first if needed, then [e] goes there and leaves this group.
  Future<void> _move(GroupRow group, Expense old, Expense e) async {
    final m = _moveTo!;
    final db = ref.read(dbProvider);
    final l = context.l;
    try {
      final target = m.person != null ? await groupForExpenseWith(ref, m.person!) : m.groupId!;
      final store = GroupStateStore(db);
      final source = await store.load(widget.groupId), dest = await store.load(target);
      // One id pair per picked target: a retry after a lost answer is the same event, deduped by the server, plus an
      // update with today's values (moveExpense).
      final retry = _moveIds != null;
      final ids = _moveIds ??= (
        expenseId: newId(),
        clientId: newId(),
        receipts: {for (final a in source.receiptsOf(old.id)) a.id: (id: newId(), clientId: newId())},
      );
      var moved = remapForMove(e, source.members, dest.members,
          id: ids.expenseId, sameCurrency: source.defaultCurrency == dest.defaultCurrency);
      if (moved == null) throw MoveException(l.onlyLinkedMove);
      // Another default currency there: the day's automatic rate, as a new expense in that currency gets it.
      final to = dest.defaultCurrency;
      if (to != null && moved.currency != to && moved.fxRateToDefault == null) {
        final table = await ref.read(fxRatesProvider).lookup(moved.date);
        final rate = table == null ? null : crossRate(table.rates, moved.currency, to);
        if (rate != null) moved = moved.copyWith(fxRateToDefault: rate);
      }
      await ref
          .read(localWritesProvider)
          .moveExpense(widget.groupId, old, target, moved, clientId: ids.clientId, retry: retry, receipts: ids.receipts);
      if (mounted) context.go('/groups/$target');
    } on ApiException catch (x) {
      if (mounted) {
        showError(context, x.code == 'NETWORK' ? context.l.moveOffline : context.l.moveFailed(errorForCode(context.l, x.code)));
      }
    }
  }

  /// 300 ms after the description changes, guess the category until the user picks one; a blank description clears
  /// the guess (docs/API.md, Categories).
  void _scheduleGuess() {
    if (!_guessable || _catTouched) return;
    _guessTimer?.cancel();
    if (_description.text.trim().isEmpty) {
      setState(() {
        _cat = null;
        _catAuto = false;
      });
      return;
    }
    _guessTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted || _catTouched) return;
      final g = guessCategory(_description.text, history: _history);
      setState(() {
        _cat = g;
        _catAuto = g != null;
      });
    });
  }

  Future<void> _pickCategory() async {
    final key = await showCategoryPicker(context, current: _cat == null ? null : resolveCategory(_cat));
    if (key == null || !mounted) return;
    setState(() {
      _guessTimer?.cancel();
      _cat = key;
      _catAuto = false;
      _catTouched = true;
    });
  }

  /// The category as a tappable tile + label ("auto" while guessed); a legacy value shows as General.
  Widget _categoryButton(ColorScheme cs, TextTheme text) => InkWell(
        key: const Key('category'),
        borderRadius: BorderRadius.circular(12),
        onTap: _pickCategory,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            CategoryAvatar(_cat, size: 36),
            const SizedBox(width: 10),
            Flexible(
              child: Text(_cat == null ? context.l.category : Categories.labelOf(_cat),
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: text.bodyLarge),
            ),
            if (_catAuto) ...[
              const SizedBox(width: 6),
              Container(
                key: const Key('category-auto'),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: cs.secondaryContainer, borderRadius: BorderRadius.circular(4)),
                child: Text(context.l.auto, style: text.labelSmall?.copyWith(color: cs.onSecondaryContainer)),
              ),
            ],
            Icon(Icons.arrow_drop_down, color: cs.onSurfaceVariant),
          ]),
        ),
      );

  /// "≈ €69.55" under the amount; null without a usable rate.
  int? _approx(int? amount, String currency, String d, double? rate) => amount == null || rate == null
      ? null
      : tryFx(() => convertAmount(
          amount: amount, fromDecimals: Money.digits(currency), toDecimals: Money.digits(d), rate: rate));

  /// The line under the rate field (docs Phase 4): where the rate comes from.
  String _fxSource(AppLocalizations l, String currency, String d, double? value, double? auto) {
    if (value == null || value <= 0 || !value.isFinite) return auto == null ? l.noAutoRateForm : l.emptyNotConverted;
    final inverse = numberText(double.parse((1 / value).toStringAsPrecision(6)), decimals: 10);
    return l.rateExplain(currency, numberText(value, decimals: 10), d, inverse, value == auto ? _fxDay(l) : l.yourRate);
  }

  String _fxDay(AppLocalizations l) {
    final t = _fxTable;
    if (t == null) return '';
    final x = DateTime.tryParse(t.date);
    final day = x == null ? t.date : DateFormat.MMMd().format(x);
    return t.offline ? l.rateOfOffline(day) : l.rateOf(day);
  }

  Future<void> _save(
      GroupRow group, List<String> ids, String currency, int amount, List<Share> payers, Map<String, int> split) async {
    final old = _editing;
    final d = group.defaultCurrency;
    // A stray rate on an expense in the group currency stays as it was (it's ignored, docs/API.md, Currency conversion).
    double? fx = currency != d
        ? parseDecimal(_fx.text)
        : (old?.currency == d ? old?.fxRateToDefault : null);
    // Same currency, and 0 vs null (both "not converted"): unchanged.
    if (old != null && currency == old.currency && (fx ?? 0) == (old.fxRateToDefault ?? 0)) fx = old.fxRateToDefault;
    final cat = _cat; // a legacy value stays as it was unless the picker changed it
    final notes = _notes.text.trim().isEmpty ? null : _notes.text.trim();
    var e = Expense(
      id: old?.id ?? _newId,
      description: _description.text.trim(),
      amount: amount,
      currency: currency,
      fxRateToDefault: fx,
      payers: payers,
      date: _date,
      category: cat,
      notes: notes,
      refund: _refund,
      split: _split.spec(ids, currency),
      // Equal: only the ticked people; items: everyone on a line; the other modes: everyone shown, zeros included
      // (docs/API.md SplitSpec).
      shares: _split.items
          ? [for (final MapEntry(:key, :value) in split.entries) Share(memberId: key, amount: value)]
          : [
              for (final id in ids)
                if (_split.mode != SplitMode.equal || split.containsKey(id)) Share(memberId: id, amount: split[id] ?? 0)
            ],
      recurrenceId: old?.recurrenceId,
      occurrence: old?.occurrence,
    );
    // Opened as exact only because the stored split couldn't be rebuilt, and the shares are what they were: the
    // split didn't change, so keep it (no `split: null`, no money fields for a description edit).
    if (old != null && _keptSplit != null && !_split.items && _split.mode == SplitMode.exact && _same(e.shares, old.shares)) {
      e = e.copyWith(split: _keptSplit, shares: old.shares);
    }
    // No stored split that opened as equal (see _openSplit), same shares: still no split, so no money fields.
    if (old != null && old.split == null && !_split.items && _split.mode == SplitMode.equal && _same(e.shares, old.shares)) {
      e = e.copyWith(clearSplit: true, shares: old.shares);
    }
    setState(() => _busy = true);
    try {
      final w = ref.read(localWritesProvider);
      await ref.read(sharedPreferencesProvider).setString(lastCurrencyKey(group.id), currency);
      if (old != null && _moveTo != null) {
        await _attachNew(old.id); // they move with the rest
        await _move(group, old, e);
        return;
      } else if (old == null) {
        await w.createExpense(group.id, e, repeat: _repeat, remindDaysBefore: _repeat == null ? null : _remind);
      } else {
        final money = e.amount != old.amount ||
            e.paidBy != old.paidBy ||
            !_same(e.payers, old.payers) ||
            !_same(e.shares, old.shares) ||
            e.split != old.split ||
            e.refund != old.refund;
        final fields = <String, dynamic>{
          if (e.description != old.description) 'description': e.description,
          // Both or neither: `currency` alone would keep the old currency's rate (rule 9, docs/API.md, Currency conversion).
          if (e.currency != old.currency || e.fxRateToDefault != old.fxRateToDefault) ...{
            'currency': e.currency,
            'fxRateToDefault': e.fxRateToDefault,
          },
          if (e.date != old.date) 'date': e.date,
          if (e.category != old.category) 'category': e.category,
          if (e.notes != old.notes) 'notes': e.notes,
          // Any money field changed: all six together, so the server can check them as one (docs/API.md).
          if (money) ...{
            'amount': e.amount,
            'paidBy': e.paidBy,
            'payers': e.payers,
            'shares': e.shares,
            'split': e.split,
            'refund': e.refund,
          },
        };
        await _saveSeries(group.id, e, fields);
      }
      await _attachNew(e.id);
      if (mounted) context.pop();
    } catch (err) {
      if (mounted) showError(context, err);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// An edit with Repeat (docs/API.md, Recurring expenses: app): on the latest repeat Never stops the series, a new frequency (or
  /// a new date carried forward) restarts it from here, and a ticked "Also change future repeats" sends the changed
  /// fields but the date to the series too. Repeat on an expense in no live series starts one from it.
  Future<void> _saveSeries(String groupId, Expense e, Map<String, dynamic> fields) async {
    final w = ref.read(localWritesProvider);
    final series = _series, f = _repeat;
    // The reminder belongs to the series: a changed one goes with recurrence.updated (rule 18).
    final remind = series != null && _isLatest && _remind != series.remindDaysBefore ? (_remind,) : null;
    if (series != null && _isLatest && f == null) {
      await w.stopRecurrence(groupId, series.id);
      await w.updateExpense(groupId, e, fields);
    } else if (f != null && _restarts) {
      await w.repeatFrom(groupId, e, f, stop: series?.id, fields: fields, remindDaysBefore: _remind);
    } else if (series != null && _isLatest && _future) {
      await w.updateExpense(groupId, e, fields);
      await w.updateRecurrence(groupId, series.id, {...fields}..remove('date'), remind: remind);
    } else {
      await w.updateExpense(groupId, e, fields);
      if (remind != null) await w.updateRecurrence(groupId, series!.id, const {}, remind: remind);
    }
  }

  /// The photos added here, after the expense's own event (docs/API.md, Receipts: local writes).
  Future<void> _attachNew(String expenseId) async {
    final w = ref.read(localWritesProvider);
    for (final id in [..._newReceipts]) {
      await w.attachReceipt(widget.groupId, expenseId, id);
      _newReceipts.remove(id);
    }
    _saved = true;
  }

  /// Zero entries aside: they don't change any balance.
  bool _same(List<Share> a, List<Share> b) => mapEquals(
        {for (final s in a) if (s.amount != 0) s.memberId: s.amount},
        {for (final s in b) if (s.amount != 0) s.memberId: s.amount},
      );

  Future<void> _restore() async {
    setState(() => _busy = true);
    try {
      await ref.read(localWritesProvider).restoreExpense(widget.groupId, _editing!.id);
      if (mounted) await _loadExisting(); // the restored values, not what the fields showed
    } catch (err) {
      if (mounted) showError(context, err);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
