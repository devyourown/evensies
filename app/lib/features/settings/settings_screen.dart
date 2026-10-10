import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(title: const Text('Signed in as'), subtitle: Text(session?.displayName ?? '-')),
          const Divider(),
          const ListTile(title: Text('Export'), subtitle: Text('Per group, via the server')),
          for (final g in groups)
            ListTile(
              title: Text(g.name),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                TextButton(onPressed: () => _export(g, 'json'), child: const Text('JSON')),
                TextButton(onPressed: () => _export(g, 'csv'), child: const Text('CSV')),
                TextButton(onPressed: () => _import(g), child: const Text('Import Splitwise')),
              ]),
            ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _url,
              decoration: InputDecoration(
                labelText: 'Server URL',
                helperText: 'Default: ${Env.defaultServerUrl}',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: () async {
                    await ref.read(serverUrlProvider.notifier).set(_url.text);
                    if (context.mounted) showInfo(context, 'Server URL saved');
                  },
                ),
              ),
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Licenses'),
            onTap: () => showLicensePage(context: context, applicationName: 'Tally'),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () async {
              await ref.read(authServiceProvider).logout();
              if (context.mounted) context.go('/login');
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Delete account', style: TextStyle(color: Colors.red)),
            onTap: _deleteAccount,
          ),
        ],
      ),
    );
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
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text('Your memberships become placeholders. Group data stays with the other members. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(authServiceProvider).deleteAccount();
      if (mounted) context.go('/login');
    } catch (e) {
      if (mounted) showError(context, e);
    }
  }
}
