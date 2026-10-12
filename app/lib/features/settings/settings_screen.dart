import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart' show ImageSource;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/confirm.dart';
import '../../core/currency_picker.dart';
import '../../core/env.dart';
import '../../core/person_avatar.dart';
import '../../core/snack.dart';
import '../../data/api/dto.dart';
import '../../data/db/database.dart';
import '../../data/images.dart';
import '../../providers.dart';
import '../auth/auth_service.dart';
import '../friends/home_data.dart';

/// Exports a group (a friend group: its non-group expenses) through the share sheet as `[name].[format]`; `zip` is
/// the JSON plus every receipt photo (Phase 7).
Future<void> exportGroup(BuildContext context, WidgetRef ref, String groupId, String name, String format) async {
  try {
    final api = ref.read(apiProvider);
    final dir = await getTemporaryDirectory();
    // A file name can't hold a slash.
    final file = File(p.join(dir.path, '${name.replaceAll('/', '-')}.$format'));
    if (format == 'zip') {
      await api.exportZip(groupId, file.path);
    } else {
      await file.writeAsString(await api.export(groupId, format));
    }
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  } catch (e) {
    if (context.mounted) showError(context, e);
  }
}

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final _url = TextEditingController(text: ref.read(serverUrlProvider));

  /// GET/PUT /me/notifications; null while loading or when it failed ([_prefsFailed]).
  Map<String, bool>? _prefs;
  bool _prefsFailed = false;
  bool _savingHome = false;
  bool _savingPhoto = false;
  int _homeTry = 0; // a refused change rebuilds the picker with the saved value
  static const _prefLabels = [
    ('expenses', 'Expenses and payments', Icons.receipt_long_outlined),
    ('comments', 'Comments', Icons.chat_bubble_outline),
    ('members', 'Members and group changes', Icons.group_outlined),
    // Only shown when the server has it (Phase 6): an older server would refuse the key.
    ('reminders', 'Reminders from friends', Icons.notifications_active_outlined),
  ];

  /// Take photo / Choose from library / Remove (docs/API.md 프로필 사진), online only.
  Future<void> _photo(String userId) async {
    final hasPhoto = ref.read(avatarProvider(userId)).value != null;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Take photo'),
            onTap: () => Navigator.pop(ctx, 'camera'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from library'),
            onTap: () => Navigator.pop(ctx, 'gallery'),
          ),
          if (hasPhoto)
            ListTile(
              leading: Icon(Icons.delete_outline, color: Theme.of(ctx).colorScheme.error),
              title: Text('Remove photo', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
              onTap: () => Navigator.pop(ctx, 'remove'),
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (choice == null || !mounted) return;
    final api = ref.read(apiProvider);
    final source = choice == 'camera' ? ImageSource.camera : ImageSource.gallery;
    try {
      if (choice == 'remove') {
        setState(() => _savingPhoto = true);
        await api.deleteAvatar();
      } else {
        final file = await ref
            .read(pickPhotoProvider)(source, maxEdge: 512, quality: 85);
        if (file == null) return;
        if (mounted) setState(() => _savingPhoto = true);
        await api.putAvatar(file);
      }
      ref.invalidate(avatarProvider(userId));
    } on ApiException catch (e) {
      if (mounted) {
        showError(
          context,
          switch (e) {
            ApiException(code: 'NETWORK') => 'Changing your photo needs a connection.',
            ApiException(status: 429) => 'Too many photo changes. Try again in an hour.',
            _ => "That photo couldn't be used. Try another one.",
          },
        );
      }
    } catch (e) {
      if (mounted) showError(context, photoErrorText(e, source));
    } finally {
      if (mounted) setState(() => _savingPhoto = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    if (_prefsFailed) setState(() => _prefsFailed = false);
    try {
      final p = await ref.read(apiProvider).getNotificationPrefs();
      if (mounted) setState(() => _prefs = p);
    } catch (_) {
      if (mounted) setState(() => _prefsFailed = true);
    }
  }

  /// Optimistic; reverts when the server refuses or is unreachable.
  Future<void> _setPref(String key, bool on) async {
    final old = _prefs!;
    setState(() => _prefs = {...old, key: on});
    try {
      final saved = await ref.read(apiProvider).putNotificationPrefs({...old, key: on});
      if (mounted) setState(() => _prefs = saved);
    } catch (e) {
      if (!mounted) return;
      setState(() => _prefs = old);
      showError(context, 'Could not save notification settings. Check your connection.');
    }
  }

  /// PATCH /me, online only (docs/API.md): the session keeps what the server saved.
  Future<void> _setHome(String code) async {
    setState(() => _savingHome = true);
    try {
      final user = await ref.read(apiProvider).updateMe(homeCurrency: code);
      await ref.read(dbProvider).updateProfile(user.id, homeCurrency: user.homeCurrency ?? code);
    } catch (e) {
      if (!mounted) return;
      setState(() => _homeTry++);
      showError(context,
          e is ApiException && e.code == 'NETWORK' ? 'Changing your home currency needs a connection.' : e);
    } finally {
      if (mounted) setState(() => _savingHome = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider).value;
    final home = ref.watch(homeCurrencyProvider);
    final groups = ref.watch(groupsProvider).value ?? const <GroupRow>[];
    final homeData = ref.watch(homeDataProvider).value;
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    Widget header(String s) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: Text(s, style: text.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
        );
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          ListTile(
            leading: Semantics(
              button: true,
              label: 'Change profile photo',
              child: InkWell(
                key: const Key('my-photo'),
                customBorder: const CircleBorder(),
                onTap: session == null || _savingPhoto ? null : () => _photo(session.userId),
                child: Stack(clipBehavior: Clip.none, children: [
                  PersonAvatar(userId: session?.userId, name: session?.displayName ?? '', radius: 24),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: CircleAvatar(
                      radius: 11,
                      backgroundColor: cs.surface,
                      child: _savingPhoto
                          ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(Icons.photo_camera, size: 14, color: cs.primary),
                    ),
                  ),
                ]),
              ),
            ),
            title: Text(session?.displayName ?? '-'),
            subtitle: const Text('Your name · tap to change'),
            trailing: const Icon(Icons.edit_outlined),
            onTap: () => context.push('/name'),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('Ways to get paid'),
            subtitle: const Text('PayPal, Wise, IBAN, bank account…'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/payment-methods'),
          ),
          ListTile(
            key: const Key('home-currency'),
            leading: const Icon(Icons.public),
            title: const Text('Home currency'),
            subtitle: Text(session?.homeCurrency == null
                ? 'From your region · balances also show ≈ in it'
                : 'Balances also show ≈ in it'),
            trailing: _savingHome
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : CurrencyPicker(
                    key: ValueKey('home-$_homeTry'),
                    value: home,
                    width: 124,
                    bare: true,
                    textStyle: text.titleMedium?.copyWith(color: cs.onSurface),
                    onChanged: _setHome,
                  ),
          ),
          header('Notifications'),
          for (final (key, label, icon) in _prefLabels)
            if (key != 'reminders' || (_prefs?.containsKey(key) ?? false))
              SwitchListTile(
                secondary: Icon(icon),
                title: Text(label),
                value: _prefs?[key] ?? true,
                onChanged: _prefs == null ? null : (v) => _setPref(key, v),
              ),
          if (_prefsFailed)
            ListTile(
              leading: Icon(Icons.cloud_off_outlined, color: cs.onSurfaceVariant),
              title: Text('Notification settings need a connection', style: TextStyle(color: cs.onSurfaceVariant)),
              trailing: TextButton(onPressed: _loadPrefs, child: const Text('Retry')),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Only changes made by other people notify you.',
                  style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            ),
          header('Export & import'),
          if (groups.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('No groups to export.', style: TextStyle(color: cs.onSurfaceVariant)),
            ),
          for (final g in groups)
            ListTile(
              title: Text(g.kind == 'friend' ? homeData?.label(g.id) ?? 'Non-group' : g.name),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz),
                onSelected: (v) => v == 'import'
                    ? _import(g)
                    : exportGroup(context, ref, g.id, g.kind == 'friend' ? homeData?.label(g.id) ?? g.name : g.name, v),
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'json', child: Text('Export JSON')),
                  const PopupMenuItem(value: 'csv', child: Text('Export CSV')),
                  const PopupMenuItem(value: 'zip', child: Text('ZIP with receipts')),
                  // A friend group has exactly two members, so new names from a file can't be added (409).
                  if (g.kind != 'friend') const PopupMenuItem(value: 'import', child: Text('Import Splitwise CSV')),
                ],
              ),
            ),
          header('Server'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _url,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: 'Server URL',
                helperText: 'Default: ${Env.defaultServerUrl}',
                suffixIcon: IconButton(
                  tooltip: 'Save',
                  icon: const Icon(Icons.save_outlined),
                  onPressed: () async {
                    await ref.read(serverUrlProvider.notifier).set(_url.text);
                    if (context.mounted) showInfo(context, 'Server URL saved');
                  },
                ),
              ),
            ),
          ),
          header('Account'),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Licenses'),
            onTap: () => showLicensePage(context: context, applicationName: 'Evensies'),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: _signOut,
          ),
          ListTile(
            leading: Icon(Icons.delete_forever_outlined, color: cs.error),
            title: Text('Delete account', style: TextStyle(color: cs.error)),
            onTap: _deleteAccount,
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    final ok = await confirm(context,
        title: 'Sign out?',
        message: 'Local data on this device is removed. Changes that have not synced yet will be lost.',
        confirmLabel: 'Sign out',
        destructive: false);
    if (!ok) return;
    await ref.read(authServiceProvider).logout();
    if (mounted) context.go('/login');
  }

  Future<void> _import(GroupRow g) async {
    try {
      final picked = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['csv']);
      final path = picked.firstOrNull?.path;
      if (path == null) return;
      final r = await ref.read(apiProvider).importSplitwise(g.id, File(path));
      ref.read(syncProvider).syncLater(g.id);
      if (mounted) showInfo(context, 'Imported ${r.imported} expenses');
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }

  Future<void> _deleteAccount() async {
    final ok = await confirm(context,
        title: 'Delete account?',
        message: 'Your memberships become placeholders. Group data stays with the other members. This cannot be undone.');
    if (!ok) return;
    try {
      await ref.read(authServiceProvider).deleteAccount();
      if (mounted) context.go('/login');
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }
}
