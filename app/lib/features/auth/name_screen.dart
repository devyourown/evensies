import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n.dart';
import '../../core/snack.dart';
import '../../data/db/database.dart';
import '../../providers.dart';
import '../../router.dart' show safeNext;

const maxDisplayNameLength = 30;

/// True when the user has no usable name yet. Older sessions may still hold an email, which other
/// group members would see, so that counts as missing too.
bool needsDisplayName(SessionRow s) => s.displayName.trim().isEmpty || s.displayName.contains('@');

/// Asks for the name other members see. Shown once after the first sign-in, and from Settings.
class NameScreen extends ConsumerStatefulWidget {
  const NameScreen({super.key});
  @override
  ConsumerState<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends ConsumerState<NameScreen> {
  final _name = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final s = ref.read(sessionProvider).value;
    if (s != null && !needsDisplayName(s)) _name.text = s.displayName;
  }

  String get _value => _name.text.trim();
  bool get _valid => _value.isNotEmpty && _value.characters.length <= maxDisplayNameLength;

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final user = await ref.read(apiProvider).updateMe(displayName: _value);
      await ref.read(dbProvider).updateProfile(user.id, displayName: user.displayName);
      if (!mounted) return;
      context.canPop() ? context.pop() : context.go(safeNext(GoRouterState.of(context).uri.queryParameters['next']) ?? '/');
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final first = !context.canPop();
    final l = context.l;
    return Scaffold(
      appBar: AppBar(title: Text(first ? l.welcomeTitle : l.yourNameTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            first ? l.nameQuestion : l.nameExplain,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            l.nameHelp,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            autofocus: true,
            maxLength: maxDisplayNameLength,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(labelText: l.nameLabel, border: const OutlineInputBorder()),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _valid && !_busy ? _save() : null,
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _valid && !_busy ? _save : null,
            child: _busy
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l.save),
          ),
        ],
      ),
    );
  }
}
