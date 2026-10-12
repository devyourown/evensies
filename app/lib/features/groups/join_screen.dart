import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/ids.dart';
import '../../core/l10n.dart';
import '../../core/snack.dart';
import '../../core/text_limits.dart';
import '../../data/api/dto.dart';
import '../../providers.dart';
import '../friends/add_friend_screen.dart' show addFriendByCode;

class JoinScreen extends ConsumerStatefulWidget {
  final String code;
  const JoinScreen({super.key, required this.code});
  @override
  ConsumerState<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends ConsumerState<JoinScreen> {
  /// The group behind the code, or (a 404 there) the person behind a friend code: one namespace (docs/API.md).
  late final Future<({InvitePreview? group, String? friend})> _preview = () async {
    final api = ref.read(apiProvider);
    try {
      return (group: await api.invitePreview(widget.code), friend: null);
    } on ApiException catch (e) {
      if (e.status != 404) rethrow;
      return (group: null, friend: await api.friendInvite(widget.code));
    }
  }();
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

  Widget _friendInvite(String name) => ListView(padding: const EdgeInsets.all(16), children: [
        Text(context.l.wantsToSplit(name), style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _busy
              ? null
              : () async {
                  setState(() => _busy = true);
                  await addFriendByCode(context, ref, widget.code);
                  if (mounted) setState(() => _busy = false);
                },
          child: Text(context.l.addAsFriend(name)),
        ),
      ]);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(context.l.joinGroup)),
        body: FutureBuilder(
          future: _preview,
          builder: (context, snap) {
            if (snap.hasError) {
              final e = snap.error;
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                      e is ApiException && e.status == 404
                          ? context.l.inviteInvalid
                          : context.l.inviteFailed(errorText(context.l, e ?? '')),
                      textAlign: TextAlign.center),
                ),
              );
            }
            final found = snap.data;
            if (found == null) return const Center(child: CircularProgressIndicator());
            if (found.friend case final name?) return _friendInvite(name);
            final p = found.group!;
            final placeholders = p.members.where((m) => !m.linked).toList();
            // A placeholder friend's link: only the placeholder can be claimed (a third member gets 409).
            if (p.kind == 'friend') {
              if (placeholders.isEmpty) {
                return Center(child: Text(context.l.friendInviteUsed));
              }
              if (_memberId == _newMember) _memberId = placeholders.first.id;
              final by = p.members.where((m) => m.linked).firstOrNull?.name;
              return ListView(padding: const EdgeInsets.all(16), children: [
                Text(by == null ? context.l.someoneAddedYouAsFriend : context.l.addedYouAsFriend(by),
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(context.l.joinToSeeShared),
                const SizedBox(height: 24),
                RadioGroup<String>(
                  groupValue: _memberId,
                  onChanged: (v) => setState(() => _memberId = v ?? _memberId),
                  child: Column(children: [
                    for (final m in placeholders) RadioListTile<String>(value: m.id, title: Text(context.l.imName(m.name))),
                  ]),
                ),
                const SizedBox(height: 24),
                FilledButton(onPressed: _busy ? null : _join, child: Text(context.l.join)),
              ]);
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(p.name, style: Theme.of(context).textTheme.headlineSmall),
                Text(context.l.memberCount(p.memberCount)),
                const SizedBox(height: 24),
                Text(context.l.whoAreYou),
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
                        decoration: limitedDecoration(context, InputDecoration(labelText: context.l.newMemberName),
                            _name.text, maxMemberName),
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
                  child: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Text(context.l.join),
                ),
              ],
            );
          },
        ),
      );
}
