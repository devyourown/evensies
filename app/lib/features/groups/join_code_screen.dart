import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/invite_code.dart';
import '../../data/api/dto.dart';
import '../../providers.dart';

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
      _error = null;
      _loading = code.length == 6 || code.length == 10;
    });
    if (!_loading) return;
    try {
      final p = await ref.read(apiProvider).invitePreview(code);
      if (mounted && _looked == code) setState(() => _preview = p);
    } on ApiException catch (e) {
      if (mounted && _looked == code) setState(() => _error = _message(e));
    } finally {
      if (mounted && _looked == code) setState(() => _loading = false);
    }
  }

  String _message(ApiException e) => switch (e) {
        ApiException(status: 404) => 'No group found for this code',
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
      appBar: AppBar(title: const Text('Join a group')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        children: [
          Text('Ask someone in the group for the 6-character code. They can find it in the group → Members.',
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
          if (p != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('${p.name} · ${p.memberCount} ${p.memberCount == 1 ? 'member' : 'members'}',
                      style: text.titleMedium, textAlign: TextAlign.center),
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
