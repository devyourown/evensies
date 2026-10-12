import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../core/ids.dart';
import 'blob_store.dart' show BlobArea;

/// `{appSupport}/pending_attachments/` and `{appCache}/attachments/`.
class BlobStore {
  final Future<String> Function() _support, _cache;
  BlobStore({Future<String> Function()? supportDir, Future<String> Function()? cacheDir})
      : _support = supportDir ?? (() async => (await getApplicationSupportDirectory()).path),
        _cache = cacheDir ?? (() async => (await getApplicationCacheDirectory()).path);

  Future<String> _dir(BlobArea a) async =>
      a == BlobArea.pending ? '${await _support()}/pending_attachments' : '${await _cache()}/attachments';

  /// The file's path, for the platform's text recognition.
  Future<String> path(BlobArea a, String name) async => '${await _dir(a)}/$name';

  Future<Uint8List?> read(BlobArea a, String name) async {
    try {
      return await File(await path(a, name)).readAsBytes();
    } on FileSystemException {
      return null;
    }
  }

  Future<bool> exists(BlobArea a, String name) async => File(await path(a, name)).exists();

  /// Written whole or not at all (a temp file renamed into place).
  Future<void> write(BlobArea a, String name, List<int> bytes) async {
    final f = File(await path(a, name));
    await f.parent.create(recursive: true);
    final tmp = File('${f.path}.${newId()}');
    await tmp.writeAsBytes(bytes, flush: true);
    await tmp.rename(f.path);
  }

  Future<void> delete(BlobArea a, String name) async {
    try {
      await File(await path(a, name)).delete();
    } on FileSystemException catch (_) {} // not there
  }

  /// [name] from [from] to [to]; nothing when it isn't there.
  Future<void> move(String name, BlobArea from, BlobArea to) async {
    final f = File(await path(from, name)), t = File(await path(to, name));
    if (!await f.exists()) return;
    await t.parent.create(recursive: true);
    try {
      await f.rename(t.path);
    } on FileSystemException {
      await f.copy(t.path); // another volume
      await f.delete();
    }
  }

  /// Both areas, every file.
  Future<void> clear() async {
    for (final a in BlobArea.values) {
      try {
        await Directory(await _dir(a)).delete(recursive: true);
      } on FileSystemException catch (_) {}
    }
  }

  /// One app process on a phone: a missing pending file is gone for good.
  Future<bool> claimed(String name) async => false;
}

/// The OS temp folder: a big export is streamed there for the share sheet (null in the browser).
Future<String?> tempDir() async => (await getTemporaryDirectory()).path;

/// Deletes the file at [path] if it is there (the picker's full-size original, which can carry GPS EXIF).
Future<void> deleteFile(String path) async {
  try {
    await File(path).delete();
  } on FileSystemException catch (_) {}
}
