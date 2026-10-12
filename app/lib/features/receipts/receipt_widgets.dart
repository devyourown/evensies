import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart' show ImageSource;
import 'package:share_plus/share_plus.dart';

import '../../core/confirm.dart';
import '../../core/l10n.dart';
import '../../core/snack.dart';
import '../../data/images.dart';
import '../../data/receipts.dart';
import '../../providers.dart';

/// At most this many receipts on one expense (docs/API.md 영수증, an abuse cap on the server).
const maxReceipts = 10;

/// Camera or library; null when dismissed. The browser has one choice, a file (a phone's browser offers its camera
/// there too), so it skips the sheet.
Future<ImageSource?> pickImageSource(BuildContext context, {String? title}) async => kIsWeb
    ? ImageSource.gallery
    : showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(title ?? ctx.l.receiptAdd, style: Theme.of(ctx).textTheme.titleMedium)),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(ctx.l.photoTake),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(ctx.l.photoChoose),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

/// A receipt thumbnail: this device's copy or a download; "Available when online" when neither works.
class ReceiptThumb extends ConsumerWidget {
  final String groupId;
  final String attachmentId;
  final double size;
  final VoidCallback? onTap;
  const ReceiptThumb({super.key, required this.groupId, required this.attachmentId, this.size = 72, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final key = (groupId: groupId, id: attachmentId, thumb: true);
    final f = ref.watch(receiptFileProvider(key));
    final Widget child = switch (f) {
      AsyncData(value: final bytes?) => Image.memory(
        bytes,
        fit: BoxFit.cover,
        width: size,
        height: size,
        gaplessPlayback: true,
        errorBuilder: (_, _, _) => Icon(Icons.broken_image_outlined, color: cs.onSurfaceVariant),
      ),
      // Scaled down to the tile at any text size.
      AsyncData() => Padding(
        padding: const EdgeInsets.all(6),
        child: FittedBox(
          child: SizedBox(
            width: 64,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_outlined, size: 20, color: cs.onSurfaceVariant),
                Text(
                  context.l.availableWhenOnline,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
      _ => const Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
    };
    return Semantics(
      label: context.l.receiptPhoto,
      button: onTap != null,
      child: Material(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(width: size, height: size, child: child),
        ),
      ),
    );
  }
}

/// The expense's receipts as a row of thumbnails, plus Add (attached right away) while there is room; a tap opens the
/// photo full screen.
class ReceiptStrip extends ConsumerStatefulWidget {
  final String groupId;
  final String expenseId;

  /// The live receipts' ids, in attach order.
  final List<String> ids;

  /// False on a deleted expense: look, don't touch.
  final bool editable;
  const ReceiptStrip({
    super.key,
    required this.groupId,
    required this.expenseId,
    required this.ids,
    this.editable = true,
  });
  @override
  ConsumerState<ReceiptStrip> createState() => _ReceiptStripState();
}

class _ReceiptStripState extends ConsumerState<ReceiptStrip> {
  bool _adding = false;

  Future<void> _add() async {
    final source = await pickImageSource(context);
    if (source == null || !mounted) return;
    setState(() => _adding = true);
    try {
      final photo = await ref.read(pickReceiptProvider)(source, scan: false);
      if (photo == null) return;
      await ref.read(localWritesProvider).attachReceipt(widget.groupId, widget.expenseId, photo.id);
    } catch (e) {
      if (mounted) showError(context, photoErrorText(context.l, e, source));
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ids = widget.ids;
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (final (i, id) in ids.indexed)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ReceiptThumb(
                key: Key('receipt-$id'),
                groupId: widget.groupId,
                attachmentId: id,
                onTap: () => openReceiptViewer(
                  context,
                  groupId: widget.groupId,
                  ids: ids,
                  initial: i,
                  editable: widget.editable,
                ),
              ),
            ),
          if (widget.editable && ids.length < maxReceipts)
            SizedBox(
              width: 72,
              height: 72,
              child: OutlinedButton(
                key: const Key('receipt-add'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _adding ? null : _add,
                child: _adding
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_a_photo_outlined, color: cs.primary),
                          const SizedBox(height: 2),
                          Text(context.l.add, style: Theme.of(context).textTheme.labelSmall),
                        ],
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

Future<void> openReceiptViewer(
  BuildContext context, {
  required String groupId,
  required List<String> ids,
  int initial = 0,
  bool editable = true,
}) => Navigator.of(context).push(
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (_) => ReceiptViewer(groupId: groupId, ids: ids, initial: initial, editable: editable),
  ),
);

/// Receipt photos full screen: swipe between them, pinch to zoom, share or save (the share sheet), remove for everyone.
class ReceiptViewer extends ConsumerStatefulWidget {
  final String groupId;
  final List<String> ids;
  final int initial;
  final bool editable;
  const ReceiptViewer({super.key, required this.groupId, required this.ids, this.initial = 0, this.editable = true});
  @override
  ConsumerState<ReceiptViewer> createState() => _ReceiptViewerState();
}

class _ReceiptViewerState extends ConsumerState<ReceiptViewer> {
  late final _pages = PageController(initialPage: widget.initial);
  late int _index = widget.initial;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  String get _id => widget.ids[_index];

  Future<void> _share() async {
    try {
      final bytes = await ref.read(receiptFilesProvider).file(widget.groupId, _id);
      await SharePlus.instance.share(ShareParams(
          files: [XFile.fromData(bytes, mimeType: 'image/jpeg', name: 'receipt-$_id.jpg')],
          fileNameOverrides: ['receipt-$_id.jpg']));
    } catch (_) {
      if (mounted) showError(context, context.l.receiptAvailableOnline);
    }
  }

  Future<void> _remove() async {
    final ok = await confirm(
      context,
      title: context.l.receiptRemoveTitle,
      message: context.l.receiptRemoveMessage,
      confirmLabel: context.l.remove,
    );
    if (!ok || !mounted) return;
    await ref.read(localWritesProvider).removeReceipt(widget.groupId, _id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final n = widget.ids.length;
    final l = context.l;
    return Scaffold(
      appBar: AppBar(
        title: Text(n == 1 ? l.receiptTitle : l.receiptTitleOf(_index + 1, n)),
        actions: [
          IconButton(tooltip: l.shareOrSave, icon: const Icon(Icons.ios_share), onPressed: _share),
          if (widget.editable)
            IconButton(
              key: const Key('receipt-remove'),
              tooltip: l.remove,
              icon: const Icon(Icons.delete_outline),
              onPressed: _remove,
            ),
        ],
      ),
      body: PageView.builder(
        controller: _pages,
        itemCount: n,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (_, i) {
          final key = (groupId: widget.groupId, id: widget.ids[i], thumb: false);
          final f = ref.watch(receiptFileProvider(key));
          return switch (f) {
            AsyncData(value: final bytes?) => InteractiveViewer(
              maxScale: 6,
              child: Center(
                child: Image.memory(
                  bytes,
                  fit: BoxFit.contain,
                  semanticLabel: l.receiptPhoto,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => Icon(Icons.broken_image_outlined, size: 48, color: cs.onSurfaceVariant),
                ),
              ),
            ),
            AsyncData() => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off_outlined, size: 48, color: cs.onSurfaceVariant),
                  const SizedBox(height: 8),
                  Text(l.availableWhenOnline, style: TextStyle(color: cs.onSurfaceVariant)),
                ],
              ),
            ),
            _ => const Center(child: CircularProgressIndicator()),
          };
        },
      ),
    );
  }
}
