import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/confirm.dart';
import '../../core/ids.dart';
import '../../core/invite_code.dart';
import '../../core/l10n.dart';
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
    if (context.mounted) showError(context, friendError(context.l, e));
  }
}

/// What "Share link" sends (the Add friend screen, and a friend page you no longer share a group with).
String friendLinkText(AppLocalizations l, FriendCode c) => l.friendLinkShare(c.link, formatInviteCode(c.friendCode));

/// My friend link through the share sheet; it needs the server for the code.
Future<void> shareFriendLink(BuildContext context, WidgetRef ref) async {
  try {
    final c = await ref.read(apiProvider).friendCode();
    if (context.mounted) await shareText(context, friendLinkText(context.l, c));
  } catch (e) {
    if (context.mounted) {
      showError(context, e is ApiException && e.code != 'NETWORK' ? e : context.l.friendLinkNeedsConnection);
    }
  }
}

String friendError(AppLocalizations l, ApiException e) => switch (e) {
      ApiException(code: 'SELF_FRIEND') => l.selfFriend,
      ApiException(status: 404) => l.noOneForCode,
      ApiException(status: 429) => l.errorRateLimited,
      ApiException(code: 'NETWORK') => l.addFriendNeedsConnection,
      _ => errorForCode(l, e.code),
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
    final l = context.l;
    final ok = await confirm(context,
        title: l.newFriendCodeTitle, message: l.newFriendCodeMessage, confirmLabel: l.newCode, destructive: false);
    if (!ok) return;
    setState(() => _rotating = true);
    try {
      final c = await ref.read(apiProvider).rotateFriendCode();
      if (mounted) setState(() => _mine = c);
    } catch (e) {
      if (mounted) showError(context, e is ApiException ? friendError(context.l, e) : e);
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
      if (mounted && _looked == code) setState(() => _codeError = friendError(context.l, e));
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
      if (mounted) showError(context, friendError(context.l, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l = context.l;
    final mine = _mine;
    final name = _name.text.trim();
    final nameOk = name.isNotEmpty && name.runes.length <= maxFriendName;
    Widget section(String s) => Padding(
          padding: const EdgeInsets.only(top: 28, bottom: 8),
          child: Text(s, style: text.titleSmall),
        );

    return Scaffold(
      appBar: AppBar(title: Text(l.addAFriend)),
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
                        Text(l.friendLinkOffline, style: TextStyle(color: cs.onSurfaceVariant)),
                        TextButton(onPressed: _loadMine, child: Text(l.retry)),
                      ] else
                        const Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()),
                    ])
                  : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Text(l.yourFriendCode, textAlign: TextAlign.center, style: text.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
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
                            semanticsLabel: l.friendQrLabel,
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
                      Text(l.friendCodeHelp,
                          textAlign: TextAlign.center, style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      const SizedBox(height: 12),
                      Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [
                        FilledButton.icon(
                          onPressed: () => shareText(context, friendLinkText(l, mine)),
                          icon: const Icon(Icons.share, size: 18),
                          label: Text(l.shareLink),
                        ),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: mine.friendCode));
                            if (context.mounted) showInfo(context, context.l.codeCopied);
                          },
                          icon: const Icon(Icons.copy, size: 18),
                          label: Text(l.copyCode),
                        ),
                        TextButton.icon(
                          onPressed: _rotating ? null : _rotate,
                          icon: _rotating
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.refresh, size: 18),
                          label: Text(l.newCode),
                        ),
                      ]),
                    ]),
            ),
          ),
          section(l.haveFriendCode),
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
                subtitle: Text(l.onEvensies, style: TextStyle(color: cs.onSecondaryContainer)),
                trailing: FilledButton(
                  key: const Key('friend-add'),
                  onPressed: _busy ? null : _addByCode,
                  child: Text(l.add),
                ),
              ),
            ),
          section(l.notOnEvensiesSection),
          Text(l.notOnEvensiesHelp,
              style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          const SizedBox(height: 8),
          TextField(
            key: const Key('friend-name'),
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l.nameLabel,
              border: const OutlineInputBorder(),
              errorText: name.runes.length > maxFriendName ? l.atMostChars(maxFriendName) : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          FilledButton.tonal(
            key: const Key('friend-add-name'),
            onPressed: _busy || !nameOk ? null : _addByName,
            child: _busy
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(nameOk ? l.addName(name) : l.add),
          ),
        ],
      ),
    );
  }
}
