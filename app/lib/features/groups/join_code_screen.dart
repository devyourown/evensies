import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/invite_code.dart';
import '../../data/api/dto.dart';
import '../../providers.dart';
import '../friends/add_friend_screen.dart' show addFriendByCode;

/// Keeps the field as a formatted code (`ABC-DEF`); a pasted link collapses to its code.
class _CodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final t = newValue.text;
    var code = (t.contains('/') || t.contains(':')) ? extractInviteCode(t) ?? '' : normalizeInviteCode(t);
    if (code.length > 10) code = code.substring(0, 10); // legacy codes are 10
    final f = formatInviteCode(code);
    return TextEditingValue(text: f, selection: TextSelection.collapsed(offset: f.length));
  }
}

class JoinCodeScreen extends ConsumerStatefulWidget {
  const JoinCodeScreen({super.key});
  @override
  ConsumerState<JoinCodeScreen> createState() => _JoinCodeScreenState();
}

class _JoinCodeScreenState extends ConsumerState<JoinCodeScreen> {
  final _ctl = TextEditingController();
  bool _fromClipboard = false;
  String _looked = ''; // code of the latest preview request
  bool _loading = false;
  InvitePreview? _preview;
  /// A friend code (Phase 6, one namespace with group codes): the person's display name.
  String? _friend;
  bool _adding = false;
  String? _error;

  String get _code => normalizeInviteCode(_ctl.text);

  @override
  void initState() {
    super.initState();
    _readClipboard();
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _readClipboard() async {
    final clip = (await Clipboard.getData(Clipboard.kTextPlain))?.text;
    final code = clip == null ? null : extractInviteCode(clip);
    if (!mounted || code == null || _ctl.text.isNotEmpty) return;
    _ctl.text = formatInviteCode(code);
    setState(() => _fromClipboard = true);
    _onChanged();
  }

  Future<void> _onChanged() async {
    final code = _code;
    if (code == _looked) return;
    _looked = code;
    setState(() {
      _preview = null;
      _friend = null;
      _error = null;
      _loading = code.length == 6 || code.length == 10;
    });
    if (!_loading) return;
    final api = ref.read(apiProvider);
    try {
      final p = await api.invitePreview(code);
      if (mounted && _looked == code) setState(() => _preview = p);
    } on ApiException catch (e) {
      // Not a group: maybe a friend code (docs/API.md: invites first, then friend-invites).
      if (e.status == 404 && code.length == 6) {
        try {
          final name = await api.friendInvite(code);
          if (mounted && _looked == code) setState(() => _friend = name);
          return;
        } on ApiException catch (f) {
          if (mounted && _looked == code) setState(() => _error = _message(f));
          return;
        }
      }
      if (mounted && _looked == code) setState(() => _error = _message(e));
    } finally {
      if (mounted && _looked == code) setState(() => _loading = false);
    }
  }

  String _message(ApiException e) => switch (e) {
        ApiException(status: 404) => 'No group or friend found for this code',
        ApiException(status: 429) => 'Too many tries. Wait a minute and try again.',
        ApiException(code: 'NETWORK') => 'Joining a group needs a connection.',
        _ => e.message,
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final p = _preview;
    return Scaffold(
      appBar: AppBar(title: const Text('Enter a code')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          Text(
              'A group code is in the group → Members. A friend code is on their Friends tab → Add a friend.',
              textAlign: TextAlign.center, style: text.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 24),
          TextField(
            controller: _ctl,
            autofocus: true,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.visiblePassword, // no autocorrect bar on Android
            inputFormatters: [_CodeFormatter()],
            onChanged: (_) {
              if (_fromClipboard) setState(() => _fromClipboard = false);
              _onChanged();
            },
            style: text.headlineMedium?.copyWith(fontFamily: 'monospace', letterSpacing: 6, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(hintText: 'ABC-DEF', border: OutlineInputBorder(), counterText: ''),
          ),
          if (_fromClipboard) ...[
            const SizedBox(height: 8),
            Text('Pasted from clipboard', textAlign: TextAlign.center, style: text.bodySmall?.copyWith(color: cs.primary)),
          ],
          const SizedBox(height: 24),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_error != null) Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: cs.error)),
          if (_friend != null)
            Card(
              key: const Key('friend-code-preview'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('$_friend · on Evensies', style: text.titleMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _adding
                        ? null
                        : () async {
                            setState(() => _adding = true);
                            await addFriendByCode(context, ref, _code);
                            if (mounted) setState(() => _adding = false);
                          },
                    child: Text('Add $_friend as a friend'),
                  ),
                ]),
              ),
            ),
          if (p != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  // A placeholder friend's code: the friend group's name is internal (docs/API.md 친구), say who added me.
                  Text(
                      p.kind == 'friend'
                          ? '${p.members.where((m) => m.linked).firstOrNull?.name ?? 'Someone'} added you as a friend'
                          : '${p.name} · ${p.memberCount} ${p.memberCount == 1 ? 'member' : 'members'}',
                      key: const Key('group-code-preview'),
                      style: text.titleMedium,
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: () => context.push('/join/$_code'), child: const Text('Continue')),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}
