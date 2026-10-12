import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import '../../core/person_avatar.dart';
import '../../core/snack.dart';
import '../../data/api/dto.dart';
import '../../providers.dart';

/// Settings → Blocked people (route `/settings/blocked`, docs/API.md 차단), online only: each with Unblock.
class BlockedScreen extends ConsumerStatefulWidget {
  const BlockedScreen({super.key});
  @override
  ConsumerState<BlockedScreen> createState() => _BlockedScreenState();
}

class _BlockedScreenState extends ConsumerState<BlockedScreen> {
  final _busy = <String>{};

  Future<void> _unblock(String userId, String name) async {
    setState(() => _busy.add(userId));
    try {
      await ref.read(apiProvider).unblock(userId);
      ref.invalidate(blocksProvider);
      if (mounted) showInfo(context, context.l.unblockedName(name));
    } catch (e) {
      if (mounted) showError(context, e is ApiException && e.code == 'NETWORK' ? context.l.blockNeedsConnection : e);
    } finally {
      if (mounted) setState(() => _busy.remove(userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(blocksProvider);
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l = context.l;
    Widget message(IconData icon, String title, {Widget? action}) => ListView(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 96, 32, 32),
            child: Column(children: [
              Icon(icon, size: 64, color: cs.primary),
              const SizedBox(height: 16),
              Text(keepAll(title, l.localeName), style: text.titleMedium, textAlign: TextAlign.center),
              if (action != null) ...[const SizedBox(height: 16), action],
            ]),
          ),
        ]);
    final Widget body = switch (async) {
      AsyncValue(hasError: true) => message(Icons.cloud_off_outlined, l.blockedNeedsConnection,
          action: OutlinedButton(onPressed: () => ref.invalidate(blocksProvider), child: Text(l.retry))),
      AsyncValue(:final valueOrNull?) when valueOrNull.isEmpty => message(Icons.check_circle_outline, l.blockedEmpty),
      AsyncValue(:final valueOrNull?) => ListView(padding: const EdgeInsets.only(bottom: 32), children: [
          for (final b in valueOrNull)
            ListTile(
              key: Key('blocked-${b.userId}'),
              leading: PersonAvatar(userId: b.userId, name: b.displayName),
              title: Text(b.displayName.isEmpty ? l.someone : b.displayName),
              trailing: _busy.contains(b.userId)
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : OutlinedButton(onPressed: () => _unblock(b.userId, b.displayName), child: Text(l.unblock)),
            ),
        ]),
      _ => const Center(child: CircularProgressIndicator()),
    };
    return Scaffold(
      appBar: AppBar(title: Text(l.blockedPeople)),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(keepAll(l.blockedHelp, l.localeName), style: text.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        ),
        Expanded(child: RefreshIndicator(onRefresh: () => ref.refresh(blocksProvider.future), child: body)),
      ]),
    );
  }
}
