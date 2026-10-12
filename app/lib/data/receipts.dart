import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show MethodChannel;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/ids.dart';
import '../domain/receipt_parser.dart';
import '../providers.dart';
import 'api/api_client.dart';
import 'images.dart';

/// Receipt photo files (docs/API.md 영수증): `{appSupport}/pending_attachments/{id}.jpg` (+ `_thumb`) until uploaded,
/// then `{appCache}/attachments/`. Both are this device's copies; the server keeps the photo for the group.
class ReceiptFiles {
  final ApiClient api;
  final Future<String> Function() _support, _cache;
  ReceiptFiles(this.api, {Future<String> Function()? supportDir, Future<String> Function()? cacheDir})
      : _support = supportDir ?? (() async => (await getApplicationSupportDirectory()).path),
        _cache = cacheDir ?? (() async => (await getApplicationCacheDirectory()).path);

  static String _name(String id, bool thumb) => '$id${thumb ? '_thumb' : ''}.jpg';
  Future<File> pending(String id, {bool thumb = false}) async =>
      File(p.join(await _support(), 'pending_attachments', _name(id, thumb)));
  Future<File> cached(String id, {bool thumb = false}) async =>
      File(p.join(await _cache(), 'attachments', _name(id, thumb)));

  /// [picked] (the original from the camera or library) → the pending photo (long edge 2048, quality 80, about
  /// 300–700 KB) and thumbnail (512, 70), EXIF dropped by [prepareJpeg]; the original temp file is deleted.
  Future<void> prepare(XFile picked, String id) async {
    for (final thumb in [false, true]) {
      final f = await prepareJpeg(picked, maxEdge: thumb ? 512 : 2048, quality: thumb ? 70 : 80);
      await _move(f, await pending(id, thumb: thumb));
    }
    try {
      await File(picked.path).delete();
    } catch (_) {} // the picker's own copy; the OS clears its temp folder anyway
  }

  /// The photo (or its thumbnail) to show: the cached file, else the pending one, else downloaded into the cache.
  /// Throws (ApiException NETWORK) when it isn't here and the server can't be reached.
  Future<File> file(String groupId, String id, {bool thumb = false}) async {
    final c = await cached(id, thumb: thumb);
    if (await c.exists()) return c;
    final pend = await pending(id, thumb: thumb);
    if (await pend.exists()) return pend;
    final bytes = await api.attachment(groupId, id, thumb: thumb);
    final tmp = File('${c.path}.${newId()}');
    await tmp.parent.create(recursive: true);
    await tmp.writeAsBytes(bytes, flush: true);
    return tmp.rename(c.path);
  }

  /// After the upload: both files move to the cache.
  Future<void> uploaded(String id) async {
    for (final thumb in [false, true]) {
      final f = await pending(id, thumb: thumb);
      if (await f.exists()) await _move(f, await cached(id, thumb: thumb));
    }
  }

  /// Copies of [from]'s photo and thumbnail ([file]: cached, pending or downloaded) in the cache as [to]'s (a receipt
  /// moved to another group under a new id). The copies are this device's own: a pending original may move to the
  /// cache meanwhile (its upload finished), and is then copied from there.
  Future<(File, File)> keepCopy(String groupId, String from, String to) async {
    final out = <File>[];
    for (final thumb in [false, true]) {
      final dest = await cached(to, thumb: thumb);
      await dest.parent.create(recursive: true);
      try {
        out.add(await (await file(groupId, from, thumb: thumb)).copy(dest.path));
      } on FileSystemException {
        out.add(await (await file(groupId, from, thumb: thumb)).copy(dest.path));
      }
    }
    return (out[0], out[1]);
  }

  /// Whether both pending files are still there (an upload needs them).
  Future<bool> hasPending(String id) async =>
      await (await pending(id)).exists() && await (await pending(id, thumb: true)).exists();

  /// Deletes this device's copies of [ids] (pending and cached).
  Future<void> delete(Iterable<String> ids) async {
    if (ids.isEmpty) return;
    for (final id in ids) {
      for (final thumb in [false, true]) {
        for (final f in [await pending(id, thumb: thumb), await cached(id, thumb: thumb)]) {
          try {
            await f.delete();
          } on FileSystemException catch (_) {} // not there
        }
      }
    }
  }

  /// Signed out: every receipt file on this device.
  Future<void> deleteAll() async {
    for (final d in [p.join(await _support(), 'pending_attachments'), p.join(await _cache(), 'attachments')]) {
      try {
        await Directory(d).delete(recursive: true);
      } on FileSystemException catch (_) {}
    }
  }

  static Future<void> _move(File f, File to) async {
    await to.parent.create(recursive: true);
    try {
      await f.rename(to.path);
    } on FileSystemException {
      await f.copy(to.path); // another volume
      await f.delete();
    }
  }
}

final receiptFilesProvider = Provider<ReceiptFiles>((ref) => ReceiptFiles(ref.watch(apiProvider)));

/// A receipt's file to show, or null when it isn't on this device and the server can't be reached ("Available when
/// online"); asked again when the screen comes back.
final receiptFileProvider = FutureProvider.autoDispose.family<File?, ({String groupId, String id, bool thumb})>(
  (ref, k) async {
    try {
      return await ref.watch(receiptFilesProvider).file(k.groupId, k.id, thumb: k.thumb);
    } catch (_) {
      return null;
    }
  },
);

/// Text lines in the photo at [imagePath], read on the phone: Apple Vision on iOS, ML Kit (Latin) on Android, both
/// behind `MethodChannel('evensies/ocr')` (AppDelegate.swift, MainActivity.kt). Neither the photo nor the text leaves
/// the device for this. ML Kit's iOS pods don't build for the arm64 simulator, hence Vision there (docs Phase 7).
Future<List<OcrLine>> recognizeLines(String imagePath) async {
  final lines = await const MethodChannel('evensies/ocr').invokeListMethod<Map>('recognize', {'path': imagePath});
  return [for (final l in lines ?? const <Map>[]) OcrLine.fromJson(l.cast<String, dynamic>())];
}

/// A photo taken or picked for an expense, prepared under [id]; [lines] when it was scanned (empty if nothing could be
/// read).
typedef ReceiptPhoto = ({String id, List<OcrLine>? lines});
typedef PickReceipt = Future<ReceiptPhoto?> Function(ImageSource source, {required bool scan});

/// Scan is hidden on the web (no on-device recognition there, docs Phase 9).
bool get canScanReceipts => !kIsWeb;

/// Camera or library → [ReceiptFiles.prepare] → (scan: text recognition on the prepared 2048 px photo, not the
/// original, which can be 50 MP and more: too big to decode at once on Android); null when cancelled. Tests override it.
final pickReceiptProvider = Provider<PickReceipt>((ref) => (source, {required scan}) async {
      final x = await ImagePicker().pickImage(source: source);
      if (x == null) return null;
      final id = newId();
      final files = ref.read(receiptFilesProvider);
      await files.prepare(x, id);
      List<OcrLine>? lines;
      if (scan) {
        try {
          lines = await recognizeLines((await files.pending(id)).path);
        } catch (_) {
          lines = const []; // unreadable: the items are typed by hand
        }
      }
      return (id: id, lines: lines);
    });
