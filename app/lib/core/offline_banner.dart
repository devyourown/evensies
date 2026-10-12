import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import 'l10n.dart';

/// Thin banner shown while SyncService reports offline. Renders nothing otherwise.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(offlineProvider)) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.tertiaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          Icon(Icons.cloud_off_outlined, size: 18, color: cs.onTertiaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(context.l.offlineBanner,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onTertiaryContainer)),
          ),
        ]),
      ),
    );
  }
}
