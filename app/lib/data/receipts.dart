import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show MethodChannel;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/ids.dart';
import '../domain/receipt_parser.dart';
import '../providers.dart';
import 'api/api_client.dart';
import 'blob_store.dart';
import 'images.dart';

/// Receipt photos (docs/API.md, Receipts): `pending` (prepared, not uploaded yet) and `cache` (uploaded or downloaded),
/// as `{id}.jpg` and `{id}_thumb.jpg` in a [BlobStore] (files on phones, memory in the browser). Both are this device's
/// copies; the server keeps the photo for the group.
class ReceiptFiles {
  final ApiClient api;
  final BlobStore store;
  ReceiptFiles(this.api, {Future<String> Function()? supportDir, Future<String> Function()? cacheDir})
      : store = BlobStore(supportDir: supportDir, cacheDir: cacheDir);

  static String _name(String id, bool thumb) => '$id${thumb ? '_thumb' : ''}.jpg';

  /// The prepared photo waiting to upload, or null.
  Future<Uint8List?> pending(String id, {bool thumb = false}) => store.read(BlobArea.pending, _name(id, thumb));

  /// This device's copy of an uploaded or downloaded photo, or null.
  Future<Uint8List?> cached(String id, {bool thumb = false}) => store.read(BlobArea.cache, _name(id, thumb));

  /// The pending photo's file, for the phone's text recognition.
  Future<String> pendingPath(String id) => store.path(BlobArea.pending, _name(id, false));

  /// [picked] (the original from the camera or library) → the pending photo (long edge 2048, quality 80, about
  /// 300–700 KB) and thumbnail (512, 70), EXIF dropped by [prepareJpeg]; the picker's original is deleted (it can be
  /// tens of MB and carry GPS EXIF, and Android only clears an app's cache when storage runs low).
  Future<void> prepare(XFile picked, String id) async {
    for (final thumb in [false, true]) {
      final bytes = await prepareJpeg(picked, maxEdge: thumb ? 512 : 2048, quality: thumb ? 70 : 80);
      await store.write(BlobArea.pending, _name(id, thumb), bytes);
    }
    await deleteFile(picked.path);
  }

  /// Whether [id]'s missing pending photo is in another open tab's memory (the web; never on phones), which uploads it.
  Future<bool> inAnotherTab(String id) => store.claimed(_name(id, false));

  /// The photo (or its thumbnail) to show: the cached copy, else the pending one, else downloaded into the cache.
  /// Throws (ApiException NETWORK) when it isn't here and the server can't be reached.
  Future<Uint8List> file(String groupId, String id, {bool thumb = false}) async {
    final here = await cached(id, thumb: thumb) ?? await pending(id, thumb: thumb);
    if (here != null) return here;
    final bytes = await api.attachment(groupId, id, thumb: thumb);
    await store.write(BlobArea.cache, _name(id, thumb), bytes);
    return bytes;
  }

  /// After the upload: both move to the cache.
  Future<void> uploaded(String id) async {
    for (final thumb in [false, true]) {
      await store.move(_name(id, thumb), BlobArea.pending, BlobArea.cache);
    }
  }

  /// Copies of [from]'s photo and thumbnail ([file]: cached, pending or downloaded) in the cache as [to]'s (a receipt
  /// moved to another group under a new id). The copies are this device's own: a pending original may move to the
  /// cache meanwhile (its upload finished), and is then read from there.
  Future<(Uint8List, Uint8List)> keepCopy(String groupId, String from, String to) async {
    final out = <Uint8List>[];
    for (final thumb in [false, true]) {
      final bytes = await file(groupId, from, thumb: thumb);
      await store.write(BlobArea.cache, _name(to, thumb), bytes);
      out.add(bytes);
    }
    return (out[0], out[1]);
  }

  /// Whether both pending photos are still there (an upload needs them).
  Future<bool> hasPending(String id) async =>
      await store.exists(BlobArea.pending, _name(id, false)) && await store.exists(BlobArea.pending, _name(id, true));

  /// Deletes this device's copies of [ids] (pending and cached).
  Future<void> delete(Iterable<String> ids) async {
    for (final id in ids) {
      for (final thumb in [false, true]) {
        for (final a in BlobArea.values) {
          await store.delete(a, _name(id, thumb));
        }
      }
    }
  }

  /// Signed out: every receipt photo on this device.
  Future<void> deleteAll() => store.clear();
}

final receiptFilesProvider = Provider<ReceiptFiles>((ref) => ReceiptFiles(ref.watch(apiProvider)));

/// A receipt's photo to show, or null when it isn't on this device and the server can't be reached ("Available when
/// online"); asked again when the screen comes back.
final receiptFileProvider = FutureProvider.autoDispose.family<Uint8List?, ({String groupId, String id, bool thumb})>(
  (ref, k) async {
    try {
      return await ref.watch(receiptFilesProvider).file(k.groupId, k.id, thumb: k.thumb);
    } catch (_) {
      return null;
    }
  },
);

/// Text lines in the photo at [imagePath], read on the phone: Apple Vision on iOS, ML Kit on Android, both behind
/// `MethodChannel('evensies/ocr')` (AppDelegate.swift, MainActivity.kt). [script] ([ocrScript]) picks ML Kit's model
/// and Vision's first language. Neither the photo nor the text leaves the device for this. ML Kit's iOS pods don't
/// build for the arm64 simulator, hence Vision there (docs Phase 7).
Future<List<OcrLine>> recognizeLines(String imagePath, {String script = 'latin'}) async {
  final lines = await const MethodChannel('evensies/ocr')
      .invokeListMethod<Map>('recognize', {'path': imagePath, 'script': script});
  return [for (final l in lines ?? const <Map>[]) OcrLine.fromJson(l.cast<String, dynamic>())];
}

/// The script a receipt is likely in: from the expense's [currency] (KRW, JPY), else the app's [language] (ko, ja);
/// 'korean', 'japanese' or 'latin'. Both CJK models read Latin too.
String ocrScript(String currency, String language) => switch (currency) {
      'KRW' => 'korean',
      'JPY' => 'japanese',
      _ => switch (language) { 'ko' => 'korean', 'ja' => 'japanese', _ => 'latin' },
    };

/// A photo taken or picked for an expense, prepared under [id]; [lines] when it was scanned (empty if nothing could be
/// read).
typedef ReceiptPhoto = ({String id, List<OcrLine>? lines});
typedef PickReceipt = Future<ReceiptPhoto?> Function(ImageSource source, {required bool scan, String script});

/// Scan is hidden on the web (no on-device recognition there, docs Phase 9).
bool get canScanReceipts => !kIsWeb;

/// Camera or library → [ReceiptFiles.prepare] → (scan: text recognition on the prepared 2048 px photo, not the
/// original, which can be 50 MP and more: too big to decode at once on Android); null when cancelled. Tests override it.
final pickReceiptProvider = Provider<PickReceipt>((ref) => (source, {required scan, script = 'latin'}) async {
      // The browser resizes while picking (a canvas); phones keep the original for flutter_image_compress.
      final x = await ImagePicker().pickImage(
          source: source, maxWidth: kIsWeb ? 2048 : null, maxHeight: kIsWeb ? 2048 : null);
      if (x == null) return null;
      final id = newId();
      final files = ref.read(receiptFilesProvider);
      await files.prepare(x, id);
      List<OcrLine>? lines;
      if (scan) {
        try {
          lines = await recognizeLines(await files.pendingPath(id), script: script);
        } catch (_) {
          lines = const []; // unreadable: the items are typed by hand
        }
      }
      return (id: id, lines: lines);
    });
