import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/ids.dart';
import '../../core/snack.dart';
import '../../core/text_limits.dart';
import '../../data/api/dto.dart';
import '../../providers.dart';

class JoinScreen extends ConsumerStatefulWidget {
  final String code;
  const JoinScreen({super.key, required this.code});
  @override
  ConsumerState<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends ConsumerState<JoinScreen> {
  late final Future<InvitePreview> _preview = ref.read(apiProvider).invitePreview(widget.code);
  static const _newMember = '__new__';
  String _memberId = _newMember; // existing placeholder id, or _newMember
  // New members default to the profile name, like when creating a group.
  late final _name = TextEditingController(text: ref.read(sessionProvider).value?.displayName ?? '');
  bool _busy = false;

  Future<void> _join() async {
    setState(() => _busy = true);
    try {
      final api = ref.read(apiProvider);
      final dto = _memberId != _newMember
          ? await api.joinExisting(widget.code, _memberId)
          : await api.joinNew(widget.code, newMemberId: newId(), name: _name.text.trim());
      await ref.read(syncProvider).adoptFromSnapshot(dto.id);
      if (!mounted) return;
      context.go('/groups/${dto.id}');
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Join group')),
        body: FutureBuilder(
          future: _preview,
          builder: (context, snap) {
            if (snap.hasError) return Center(child: Text('Invalid invite: ${snap.error}'));
            final p = snap.data;
            if (p == null) return const Center(child: CircularProgressIndicator());
            final placeholders = p.members.where((m) => !m.linked).toList();
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(p.name, style: Theme.of(context).textTheme.headlineSmall),
                Text('${p.memberCount} ${p.memberCount == 1 ? 'member' : 'members'}'),
                const SizedBox(height: 24),
                const Text('Who are you?'),
                RadioGroup<String>(
                  groupValue: _memberId,
                  onChanged: (v) => setState(() => _memberId = v ?? _newMember),
                  child: Column(children: [
                    for (final m in placeholders) RadioListTile<String>(value: m.id, title: Text(m.name)),
                    RadioListTile<String>(
                      value: _newMember,
                      title: TextField(
                        controller: _name,
                        onChanged: (_) => setState(() => _memberId = _newMember),
                        decoration: limitedDecoration(
                            const InputDecoration(labelText: 'New member name'), _name.text, maxMemberName),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ||
                          (_memberId == _newMember &&
                              (_name.text.trim().isEmpty || !fitsLimit(_name.text, maxMemberName)))
                      ? null
                      : _join,
                  child: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Join'),
                ),
              ],
            );
          },
        ),
      );
}
