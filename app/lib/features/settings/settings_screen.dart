import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/confirm.dart';
import '../../core/currency_picker.dart';
import '../../core/env.dart';
import '../../core/snack.dart';
import '../../data/api/dto.dart';
import '../../data/db/database.dart';
import '../../domain/fx.dart';
import '../../providers.dart';
import '../auth/auth_service.dart';

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
  int _homeTry = 0; // a refused change rebuilds the picker with the saved value
  static const _prefLabels = [
    ('expenses', 'Expenses and payments', Icons.receipt_long_outlined),
    ('comments', 'Comments', Icons.chat_bubble_outline),
    ('members', 'Members and group changes', Icons.group_outlined),
  ];

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
            leading: const CircleAvatar(child: Icon(Icons.person)),
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
            // The "≈" lines need convertAmount (TODO(효준)); no promise before they show.
            subtitle: Text(session?.homeCurrency == null
                ? 'From your region · ${fxReady ? 'balances also show ≈ in it' : 'totals in it are coming soon'}'
                : fxReady
                    ? 'Balances also show ≈ in it'
                    : 'Totals in it are coming soon'),
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
              title: Text(g.name),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz),
                onSelected: (v) => v == 'import' ? _import(g) : _export(g, v),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'json', child: Text('Export JSON')),
                  PopupMenuItem(value: 'csv', child: Text('Export CSV')),
                  PopupMenuItem(value: 'import', child: Text('Import Splitwise CSV')),
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

  Future<void> _export(GroupRow g, String format) async {
    try {
      final data = await ref.read(apiProvider).export(g.id, format);
      final dir = await getTemporaryDirectory();
      final file = File(p.join(dir.path, '${g.name}.$format'));
      await file.writeAsString(data);
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    } catch (e) {
      if (mounted) showError(context, e);
    }
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
