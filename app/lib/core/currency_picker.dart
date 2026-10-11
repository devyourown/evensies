import 'package:flutter/material.dart';

import 'money.dart';

/// Searchable currency picker (docs Phase 4): type to filter by code (and by English name when currencies.json has
/// `names`); [pinned] codes (group, home, last used) come first, then every code in shared/currencies.json. Null
/// [onChanged] disables it.
///
/// The field empties when it gets focus (typing searches instead of appending to the code), and when it loses focus
/// it never keeps text that isn't the picked currency: an exact code typed is picked, anything else goes back.
class CurrencyPicker extends StatefulWidget {
  final String value;
  final ValueChanged<String>? onChanged;
  final List<String> pinned;
  final String? label;

  /// Null fills the width it gets.
  final double? width;

  /// Borderless, in the style of the text next to it (the amount row of the expense form).
  final bool bare;
  final TextStyle? textStyle;
  const CurrencyPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.pinned = const [],
    this.label,
    this.width,
    this.bare = false,
    this.textStyle,
  });

  @override
  State<CurrencyPicker> createState() => _CurrencyPickerState();
}

class _CurrencyPickerState extends State<CurrencyPicker> {
  late final _text = TextEditingController(text: widget.value);
  final _focus = FocusNode();

  /// The value last given or sent, so a pick isn't sent twice before the parent rebuilds.
  late String _current = widget.value;

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(CurrencyPicker old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _current = widget.value;
  }

  @override
  void dispose() {
    _focus.dispose();
    _text.dispose();
    super.dispose();
  }

  void _pick(String code) {
    if (code == _current) return;
    _current = code;
    widget.onChanged?.call(code);
  }

  void _onFocus() {
    if (_focus.hasFocus) return _text.clear();
    final typed = _text.text.trim().toUpperCase();
    if (Money.decimals.containsKey(typed)) _pick(typed);
    _text.text = _current;
  }

  /// An empty query matches everything, the "All currencies" line ('') included; a query never matches that line.
  static bool _matches(String code, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return code.toLowerCase().contains(q) || (Money.names?[code]?.toLowerCase().contains(q) ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final muted = TextStyle(color: cs.onSurfaceVariant);
    final top = {...widget.pinned.where(Money.decimals.containsKey), widget.value};
    DropdownMenuEntry<String> entry(String c) {
      final name = widget.width == null ? (Money.names?[c]) : null; // a narrow menu has no room for names
      return DropdownMenuEntry(
        value: c,
        label: c,
        labelWidget: name == null
            ? null
            : Row(mainAxisSize: MainAxisSize.min, children: [
                Text(c),
                const SizedBox(width: 8),
                Flexible(child: Text(name, style: muted, overflow: TextOverflow.ellipsis)),
              ]),
        trailingIcon:
            Money.symbols?[c] == null || Money.symbols![c] == c ? null : Text(Money.symbols![c]!, style: muted),
      );
    }

    return DropdownMenu<String>(
      controller: _text,
      focusNode: _focus,
      initialSelection: widget.value,
      hintText: widget.value,
      enabled: widget.onChanged != null,
      enableFilter: true,
      requestFocusOnTap: true, // typing filters; the default on phones is a plain button
      // The menu opens at the top, where the pinned codes are; while typing, Done takes the first match.
      filterCallback: (entries, q) => [for (final e in entries) if (_matches(e.value, q)) e],
      searchCallback: (entries, q) {
        final i = q.trim().isEmpty ? -1 : entries.indexWhere((e) => _matches(e.value, q));
        return i < 0 ? null : i;
      },
      width: widget.width,
      expandedInsets: widget.width == null ? EdgeInsets.zero : null,
      menuHeight: 320,
      label: widget.label == null ? null : Text(widget.label!),
      textStyle: widget.textStyle,
      textInputAction: TextInputAction.done,
      inputDecorationTheme: widget.bare
          ? const InputDecorationThemeData(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero)
          : null,
      onSelected: (v) {
        if (v == null || v.isEmpty) return;
        _pick(v);
        _focus.unfocus(); // picked: the next tap searches afresh
      },
      dropdownMenuEntries: [
        for (final c in top) entry(c),
        // Not selectable: marks where the pinned codes end.
        DropdownMenuEntry(
          value: '',
          label: '',
          enabled: false,
          labelWidget: Text('All currencies', style: Theme.of(context).textTheme.labelSmall?.merge(muted)),
        ),
        for (final c in Money.currencies)
          if (!top.contains(c)) entry(c),
      ],
    );
  }
}
