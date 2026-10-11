import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/confirm.dart';
import '../../core/env.dart';
import '../../core/snack.dart';
import '../../data/db/database.dart';
import '../../providers.dart';
import '../auth/auth_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final _url = TextEditingController(text: ref.read(serverUrlProvider));

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider).value;
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
