import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/blob_store.dart';
import 'l10n.dart';
import 'strings.dart';
import '../data/receipts.dart' show receiptFilesProvider;
import '../providers.dart';

/// Group cover photos (docs/API.md, Group types, covers and deletion): `cover_{coverId}.jpg` in this device's image cache (files on phones,
/// memory in the browser). A cover id never changes its bytes, so a cached file is always right; SyncService deletes
/// the old file when a group's cover changes or the group leaves this device.
String coverFileName(String coverId) => 'cover_$coverId.jpg';

Future<void> dropCover(BlobStore store, String? coverId) async {
  if (coverId == null) return;
  try {
    await store.delete(BlobArea.cache, coverFileName(coverId));
  } catch (_) {} // no file system here (tests): nothing to delete
}

/// The cover to show, or null when there is none here and the server can't be reached (the type band shows then).
final coverProvider = FutureProvider.family<Uint8List?, ({String groupId, String coverId})>((ref, k) async {
  final store = ref.watch(receiptFilesProvider).store;
  final name = coverFileName(k.coverId);
  try {
    final here = await store.read(BlobArea.cache, name);
    if (here != null) return here;
    final bytes = await ref.read(apiProvider).cover(k.groupId, k.coverId);
    await store.write(BlobArea.cache, name, bytes);
    return bytes;
  } catch (_) {
    return null; // offline, or no such cover any more: the band shows
  }
});

/// The group types (docs/API.md rule 17), in the order the chips show them; an unknown stored type shows as Other.
const groupTypes = ['trip', 'home', 'couple', 'other'];

String shownGroupType(String? type) => groupTypes.contains(type) ? type! : 'other';

IconData groupTypeIcon(String? type) => switch (shownGroupType(type)) {
      'trip' => Icons.flight_takeoff,
      'home' => Icons.home_outlined,
      'couple' => Icons.favorite_border,
      _ => Icons.groups_outlined,
    };

/// The type's colours from the theme (light and dark): a container and the colour on it.
(Color, Color) groupTypeColors(ColorScheme cs, String? type) => switch (shownGroupType(type)) {
      'trip' => (cs.primaryContainer, cs.onPrimaryContainer),
      'home' => (cs.tertiaryContainer, cs.onTertiaryContainer),
      'couple' => (cs.errorContainer, cs.onErrorContainer),
      _ => (cs.secondaryContainer, cs.onSecondaryContainer),
    };

/// A group's cover: the photo, or the type's colour band (with its icon as a thumbnail). [size] null fills the parent
/// (the group header); a size draws a rounded square (the list thumbnail).
class GroupCover extends ConsumerWidget {
  final String groupId;
  final String? type;
  final String? coverImageId;
  final double? size;
  const GroupCover({super.key, required this.groupId, required this.type, this.coverImageId, this.size});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final (bg, fg) = groupTypeColors(cs, type);
    final id = coverImageId;
    final bytes = id == null ? null : ref.watch(coverProvider((groupId: groupId, coverId: id))).valueOrNull;
    final s = size;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final Widget child = bytes != null
        ? Image.memory(
            bytes,
            key: const Key('cover-image'),
            fit: BoxFit.cover,
            width: s,
            height: s,
            // A thumbnail decodes small.
            cacheWidth: s == null ? null : (s * dpr).round(),
            gaplessPlayback: true,
            excludeFromSemantics: true,
          )
        : DecoratedBox(
            key: const Key('cover-band'),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [bg, Color.alphaBlend(fg.withValues(alpha: 0.18), bg)],
              ),
            ),
            // The header's band has no icon of its own: the AppBar shows it by the title, clear of the buttons.
            child: s == null ? null : Center(child: Icon(groupTypeIcon(type), size: s * 0.5, color: fg)),
          );
    if (s == null) return SizedBox.expand(child: child);
    return ClipRRect(
      borderRadius: BorderRadius.circular(s / 4),
      child: SizedBox(width: s, height: s, child: child),
    );
  }
}

/// "Trip" / "Home" / "Couple" / "Other" from shared/strings.json `words.groupType` (an unknown stored type: Other),
/// the same words the activity feed uses.
String groupTypeLabel(AppLocalizations l, String? type) =>
    Strings.text(l.localeName, ['words', 'groupType', shownGroupType(type)]);

/// Trip · Home · Couple · Other, one picked (the new-group dialog and group settings).
class GroupTypeChips extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const GroupTypeChips({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => Wrap(spacing: 8, runSpacing: 8, children: [
        for (final t in groupTypes)
          ChoiceChip(
            key: Key('type-$t'),
            avatar: Icon(groupTypeIcon(t), size: 18),
            showCheckmark: false,
            label: Text(groupTypeLabel(context.l, t)),
            selected: shownGroupType(value) == t,
            onSelected: (_) => onChanged(t),
          ),
      ]);
}
