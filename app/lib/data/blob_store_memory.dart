import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'blob_store.dart' show BlobArea;

/// The browser's copy: memory only, so an unsent photo goes with the tab and a viewed one is downloaded again after a
/// reload. The tabs share one database but not this memory: a pending photo is claimed with a Web Lock, which the
/// browser releases when its tab closes or reloads, so another tab's sync leaves that receipt alone until then
/// ([claimed]) and only a closed tab's receipt is dropped by the "local file missing" rule.
class BlobStore {
  BlobStore({Future<String> Function()? supportDir, Future<String> Function()? cacheDir});

  final _blobs = <(BlobArea, String), Uint8List>{};

  Future<String> path(BlobArea a, String name) async => throw UnsupportedError('no files in the browser');
  Future<Uint8List?> read(BlobArea a, String name) async => _blobs[(a, name)];
  Future<bool> exists(BlobArea a, String name) async => _blobs.containsKey((a, name));
  Future<void> write(BlobArea a, String name, List<int> bytes) async {
    _blobs[(a, name)] = Uint8List.fromList(bytes);
    // Held until the tab goes (a promise that never settles); an uploaded photo's lock is simply never asked about.
    if (a == BlobArea.pending) _locks?.request('$_lockPrefix$name', ((JSAny? _) => Completer<void>().future.toJS).toJS);
  }

  Future<void> delete(BlobArea a, String name) async => _blobs.remove((a, name));

  Future<void> move(String name, BlobArea from, BlobArea to) async {
    final b = _blobs.remove((from, name));
    if (b != null) _blobs[(to, name)] = b;
  }

  Future<void> clear() async => _blobs.clear();

  /// Whether an open tab (this one or another) still holds the pending photo [name] in its memory.
  /// ponytail: without Web Locks (Safari before 15.4, a page not served over https or localhost) it counts as gone.
  Future<bool> claimed(String name) async {
    final locks = _locks;
    if (locks == null) return false;
    final held = (await locks.query().toDart).held?.toDart ?? const [];
    return held.any((l) => l.name == '$_lockPrefix$name');
  }
}

/// No files in the browser: a big export is held in memory instead.
Future<String?> tempDir() async => null;

/// Nothing to delete in the browser (the picker's copy is a blob URL).
Future<void> deleteFile(String path) async {}

const _lockPrefix = 'evensies-pending-';

@JS('navigator.locks')
external _LockManager? get _locks;

extension type _LockManager._(JSObject _) implements JSObject {
  external JSPromise<JSAny?> request(String name, JSFunction callback);
  external JSPromise<_LockSnapshot> query();
}

extension type _LockSnapshot._(JSObject _) implements JSObject {
  external JSArray<_LockInfo>? get held;
}

extension type _LockInfo._(JSObject _) implements JSObject {
  external String? get name;
}
