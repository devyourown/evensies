import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/snack.dart';
import '../../data/db/database.dart';
import '../../providers.dart';

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
      final db = ref.read(dbProvider);
      final s = await db.getSession();
      if (s != null) await db.saveSession(s.copyWith(displayName: user.displayName));
      if (!mounted) return;
      context.canPop() ? context.pop() : context.go('/');
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final first = !context.canPop();
    return Scaffold(
      appBar: AppBar(title: Text(first ? 'Welcome' : 'Your name')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            first ? 'What should your friends call you?' : 'This is the name other members see.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'It is shown to people in your groups. You can change it later in Settings.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            autofocus: true,
            maxLength: maxDisplayNameLength,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(labelText: 'Name', border: OutlineInputBorder()),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _valid && !_busy ? _save() : null,
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _valid && !_busy ? _save : null,
            child: _busy
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}
