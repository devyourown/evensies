import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/confirm.dart';
import '../../core/ids.dart';
import '../../core/invite_code.dart';
import '../../core/snack.dart';
import '../../data/api/dto.dart';
import '../../providers.dart';

/// Max friend name, in code points after trim (docs/API.md `POST /friends {name}`).
const maxFriendName = 30;

/// Adds a friend by code (or a `/f/` link) and opens their page; [onError] gets the message to show.
Future<void> addFriendByCode(BuildContext context, WidgetRef ref, String code) async {
  try {
    final dto = await ref
        .read(apiProvider)
        .addFriend(id: newId(), defaultCurrency: ref.read(homeCurrencyProvider), code: normalizeInviteCode(code));
    await ref.read(syncProvider).adoptFromSnapshot(dto.id);
    if (context.mounted) context.go('/groups/${dto.id}'); // a friend group shows the friend's page
  } on ApiException catch (e) {
    if (context.mounted) showError(context, friendError(e));
  }
}

String friendError(ApiException e) => switch (e) {
      ApiException(code: 'SELF_FRIEND') => "That's your own code",
      ApiException(status: 404) => 'No one found for this code',
      ApiException(status: 429) => 'Too many tries. Wait a minute and try again.',
      ApiException(code: 'NETWORK') => 'Adding a friend needs a connection.',
      _ => e.message,
    };

/// Add a friend (route `/friends/add`, docs/API.md 친구): my QR code, link and code to share (and rotate), a friend's
/// code with a preview, or someone not on Evensies yet by name. [code] prefills the code field (a `/f/` link).
class AddFriendScreen extends ConsumerStatefulWidget {
  final String? code;
  const AddFriendScreen({super.key, this.code});
  @override
  ConsumerState<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends ConsumerState<AddFriendScreen> {
  FriendCode? _mine;
  bool _mineFailed = false;
  bool _rotating = false;
  final _code = TextEditingController();
  final _name = TextEditingController();
  String _looked = '';
  String? _preview; // display name behind the typed code
  String? _codeError;
  bool _looking = false;
  bool _busy = false;

  /// One id per name typed (docs/API.md `POST /friends` id): a retry after a lost answer gets the same friend group.
  final _nameIds = <String, String>{};

  @override
  void initState() {
    super.initState();
    _loadMine();
    if (widget.code case final c?) {
      _code.text = formatInviteCode(normalizeInviteCode(c));
      _lookup();
    }
  }

  @override
  void dispose() {
    _code.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _loadMine() async {
    setState(() => _mineFailed = false);
    try {
      final c = await ref.read(apiProvider).friendCode();
      if (mounted) setState(() => _mine = c);
    } catch (_) {
      if (mounted) setState(() => _mineFailed = true);
    }
  }

  Future<void> _rotate() async {
    final ok = await confirm(context,
        title: 'Get a new friend code?',
        message: 'Your current link and code stop working. Friends you already have stay.',
        confirmLabel: 'New code',
        destructive: false);
    if (!ok) return;
    setState(() => _rotating = true);
    try {
      final c = await ref.read(apiProvider).rotateFriendCode();
      if (mounted) setState(() => _mine = c);
    } catch (e) {
      if (mounted) showError(context, e is ApiException ? friendError(e) : e);
    } finally {
      if (mounted) setState(() => _rotating = false);
    }
  }

  Future<void> _lookup() async {
    final code = normalizeInviteCode(_code.text);
    if (code == _looked) return;
    _looked = code;
    setState(() {
      _preview = null;
      _codeError = null;
      _looking = code.length == 6;
    });
    if (!_looking) return;
    try {
      final name = await ref.read(apiProvider).friendInvite(code);
      if (mounted && _looked == code) setState(() => _preview = name);
    } on ApiException catch (e) {
      if (mounted && _looked == code) setState(() => _codeError = friendError(e));
    } finally {
      if (mounted && _looked == code) setState(() => _looking = false);
    }
  }

  Future<void> _addByCode() async {
    setState(() => _busy = true);
    await addFriendByCode(context, ref, _looked);
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _addByName() async {
    setState(() => _busy = true);
    try {
      final dto = await ref
          .read(apiProvider)
          .addFriend(
              id: _nameIds.putIfAbsent(_name.text.trim(), newId),
              defaultCurrency: ref.read(homeCurrencyProvider),
              name: _name.text.trim());
      await ref.read(syncProvider).adoptFromSnapshot(dto.id);
      if (mounted) context.go('/friends/g:${dto.id}');
    } on ApiException catch (e) {
      if (mounted) showError(context, friendError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final mine = _mine;
    final name = _name.text.trim();
    final nameOk = name.isNotEmpty && name.runes.length <= maxFriendName;
    Widget section(String s) => Padding(
          padding: const EdgeInsets.only(top: 28, bottom: 8),
          child: Text(s, style: text.titleSmall),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Add a friend')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: mine == null
                  ? Column(children: [
                      if (_mineFailed) ...[
                        Icon(Icons.cloud_off_outlined, color: cs.onSurfaceVariant),
                        const SizedBox(height: 8),
                        Text('Your friend link needs a connection', style: TextStyle(color: cs.onSurfaceVariant)),
                        TextButton(onPressed: _loadMine, child: const Text('Retry')),
                      ] else
                        const Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()),
                    ])
                  : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text('Your friend code', textAlign: TextAlign.center, style: text.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
                      const SizedBox(height: 12),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          // A QR code needs a light quiet zone, in dark mode too.
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                          child: QrImageView(
                            key: const Key('friend-qr'),
                            data: mine.link,
                            size: 180,
                            backgroundColor: Colors.white,
                            semanticsLabel: 'QR code of your friend link',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SelectableText(formatInviteCode(mine.friendCode),
                          key: const Key('my-friend-code'),
                          textAlign: TextAlign.center,
                          style: text.headlineMedium
                              ?.copyWith(fontFamily: 'monospace', letterSpacing: 4, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('Friends scan this, open the link, or type the code.',
                          textAlign: TextAlign.center, style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      const SizedBox(height: 12),
                      Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
                        FilledButton.icon(
                          onPressed: () => SharePlus.instance.share(ShareParams(
                              text: 'Add me on Evensies to split expenses: ${mine.link}\n'
                                  'Or enter my code ${formatInviteCode(mine.friendCode)}')),
                          icon: const Icon(Icons.share, size: 18),
                          label: const Text('Share link'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: mine.friendCode));
                            if (context.mounted) showInfo(context, 'Code copied');
                          },
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('Copy code'),
                        ),
                        TextButton.icon(
                          onPressed: _rotating ? null : _rotate,
                          icon: _rotating
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.refresh, size: 18),
                          label: const Text('New code'),
                        ),
                      ]),
                    ]),
            ),
          ),
          section("Have a friend's code?"),
          TextField(
            key: const Key('friend-code'),
            controller: _code,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.visiblePassword,
            style: text.headlineSmall?.copyWith(fontFamily: 'monospace', letterSpacing: 4),
            decoration: const InputDecoration(hintText: 'ABC-DEF', border: OutlineInputBorder()),
            onChanged: (v) {
              final c = (v.contains('/') || v.contains(':')) ? extractInviteCode(v) ?? '' : normalizeInviteCode(v);
              final f = formatInviteCode(c.length > 6 ? c.substring(0, 6) : c);
              if (f != v) _code.value = TextEditingValue(text: f, selection: TextSelection.collapsed(offset: f.length));
              _lookup();
            },
          ),
          const SizedBox(height: 12),
          if (_looking) const Center(child: CircularProgressIndicator()),
          if (_codeError != null) Text(_codeError!, textAlign: TextAlign.center, style: TextStyle(color: cs.error)),
          if (_preview != null)
            Card(
              key: const Key('friend-preview'),
              color: cs.secondaryContainer,
              child: ListTile(
                leading: CircleAvatar(child: Text(_preview!.isEmpty ? '?' : _preview!.characters.first.toUpperCase())),
                title: Text(_preview!, style: TextStyle(color: cs.onSecondaryContainer, fontWeight: FontWeight.w600)),
                subtitle: Text('on Evensies', style: TextStyle(color: cs.onSecondaryContainer)),
                trailing: FilledButton(
                  key: const Key('friend-add'),
                  onPressed: _busy ? null : _addByCode,
                  child: const Text('Add'),
                ),
              ),
            ),
          section('Someone not on Evensies yet'),
          Text('Add expenses with them right away, and invite them later.',
              style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          TextField(
            key: const Key('friend-name'),
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Name',
              border: const OutlineInputBorder(),
              errorText: name.runes.length > maxFriendName ? 'At most $maxFriendName characters' : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            key: const Key('friend-add-name'),
            onPressed: _busy || !nameOk ? null : _addByName,
            child: _busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(nameOk ? 'Add $name' : 'Add'),
          ),
        ],
      ),
    );
  }
}
