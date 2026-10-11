import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../domain/categories.dart';
import '../../domain/insights.dart';
import '../../domain/models.dart';
import '../../providers.dart';
import '../categories/category_ui.dart';
import '../group_detail/balances.dart';
import '../group_detail/group_detail_screen.dart' show ExpenseTile;
import '../insights/insights_screen.dart' show monthLabel;

/// Every group on this device with its state: search runs over the local DB, so it works offline.
final searchIndexProvider = FutureProvider<List<({GroupRow group, GroupState state})>>((ref) async {
  final groups = await ref.watch(groupsProvider.future);
  return [for (final g in groups) (group: g, state: await ref.watch(groupStateProvider(g.id).future))];
});

/// Search expenses (route `/search?group=&category=&month=`, docs/API.md 검색): descriptions, notes, comments,
/// categories and amounts, across all groups or within one.
class SearchScreen extends ConsumerStatefulWidget {
  final String? groupId;

  /// A category key, or a parent key for the whole parent.
  final String? category;
  final String? month;
  const SearchScreen({super.key, this.groupId, this.category, this.month});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctl = TextEditingController();
  Timer? _debounce;
  String _query = '';
  late String? _group = widget.groupId;
  late String? _category = widget.category;
  late String? _month = widget.month;

  @override
  void dispose() {
    _debounce?.cancel();
    _ctl.dispose();
    super.dispose();
  }

  void _typed(String v) {
    setState(() {}); // the clear button
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _query = v);
    });
  }

  Future<void> _pickCategory() async {
    final key = await showCategoryPicker(context, current: _category, parents: true);
    if (key != null) setState(() => _category = key);
  }

  Future<void> _pickMonth(List<String> months) async {
    final m = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Month'),
        children: [
          for (final m in months)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, m),
              child: Text(monthLabel(m), style: TextStyle(fontWeight: m == _month ? FontWeight.w700 : null)),
            ),
        ],
      ),
    );
    if (m != null) setState(() => _month = m);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final indexAsync = ref.watch(searchIndexProvider);
    final index = indexAsync.valueOrNull;
    final groups = [for (final g in index ?? const <({GroupRow group, GroupState state})>[]) if (_group == null || g.group.id == _group) g];
    final docs = [for (final g in groups) ...SearchDoc.of(g.group.id, g.state)];
    final months = {for (final d in docs) ?monthOf(d.date)}.toList()
      ..sort((a, b) => b.compareTo(a));
    final ids = searchDocs(docs, _query, category: _category, month: _month);
    final byId = {for (final d in docs) d.id: d};
    final groupName = index?.where((g) => g.group.id == _group).firstOrNull?.group.name;

    Widget message(IconData icon, String title, String body) => ListView(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 72, 32, 32),
            child: Column(children: [
              Icon(icon, size: 56, color: cs.primary),
              const SizedBox(height: 16),
              Text(title, style: text.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(body, style: TextStyle(color: cs.onSurfaceVariant), textAlign: TextAlign.center),
            ]),
          ),
        ]);

    final Widget results;
    if (index == null && indexAsync.hasError) {
      results = message(Icons.error_outline, "Search isn't available", '${indexAsync.error}');
    } else if (index == null) {
      results = const Center(child: CircularProgressIndicator());
    } else if (searchTerms(_query).isEmpty && _category == null && _month == null) {
      results = message(Icons.search, 'Search expenses',
          'Descriptions, notes, comments, categories and amounts: "taxi", "airport", "12,50".');
    } else if (ids.isEmpty) {
      results = message(Icons.search_off, 'No matches', 'Try another word, or remove a filter.');
    } else {
      final all = {for (final g in groups) g.group.id: g};
      results = ListView.builder(
        padding: const EdgeInsets.only(bottom: 32),
        itemCount: ids.length + 1,
        itemBuilder: (_, n) {
          if (n == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text('${ids.length} expense${ids.length == 1 ? '' : 's'}',
                  style: text.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
            );
          }
          final doc = byId[ids[n - 1]]!;
          final g = all[doc.groupId]!;
          final extra = [
            if (_group == null) g.group.name,
            if (searchExcerpt(doc, _query) case final x?) '“$x”',
          ].join(' · ');
          return ExpenseTile(
            expense: g.state.expense(doc.id)!,
            group: g.group,
            names: {for (final m in g.state.members) m.id: m.name},
            extra: extra.isEmpty ? null : extra,
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          key: const Key('search-input'),
          controller: _ctl,
          autofocus: widget.category == null && widget.month == null,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: _group == null ? 'Search all groups' : 'Search ${groupName ?? 'this group'}',
            border: InputBorder.none,
          ),
          onChanged: _typed,
        ),
        actions: [
          if (_ctl.text.isNotEmpty)
            IconButton(
              tooltip: 'Clear',
              icon: const Icon(Icons.close),
              onPressed: () {
                _ctl.clear();
                _typed('');
              },
            ),
        ],
      ),
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Row(children: [
            if (_group != null) ...[
              InputChip(
                key: const Key('filter-group'),
                avatar: const Icon(Icons.group_outlined, size: 18),
                label: Text(groupName ?? 'This group'),
                onDeleted: () => setState(() => _group = null),
                deleteButtonTooltipMessage: 'Search all groups',
              ),
              const SizedBox(width: 8),
            ],
            InputChip(
              key: const Key('filter-category'),
              avatar: Icon(Icons.category_outlined, size: 18),
              label: Text(_category == null
                  ? 'Category'
                  : Categories.parent(_category!)?.label ?? Categories.labelOf(_category)),
              selected: _category != null,
              showCheckmark: false,
              onPressed: _pickCategory,
              onDeleted: _category == null ? null : () => setState(() => _category = null),
            ),
            const SizedBox(width: 8),
            InputChip(
              key: const Key('filter-month'),
              avatar: const Icon(Icons.calendar_month_outlined, size: 18),
              label: Text(_month == null ? 'Month' : monthLabel(_month!)),
              selected: _month != null,
              showCheckmark: false,
              onPressed: months.isEmpty ? null : () => _pickMonth(months),
              onDeleted: _month == null ? null : () => setState(() => _month = null),
            ),
          ]),
        ),
        const Divider(height: 1),
        Expanded(child: results),
      ]),
    );
  }
}
