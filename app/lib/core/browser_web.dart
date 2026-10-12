import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:drift/drift.dart' show DatabaseConnection, QueryExecutor;
import 'package:drift/wasm.dart';

@JS('open')
external _Window? _open(String url, String target);

@JS('document')
external _Document get _document;

@JS('URL.createObjectURL')
external String _createObjectUrl(_Blob blob);

@JS('URL.revokeObjectURL')
external void _revokeObjectUrl(String url);

@JS('navigator.locks')
external _LockManager? get _locks;

@JS('SharedWorker')
external JSAny? get _sharedWorker;

/// False in a browser without shared workers at all: drift then keeps the database on each tab itself
/// (`unsafeIndexedDb`, AppDatabase.openChecked).
bool get hasSharedWorkers => _sharedWorker != null;

extension type _LockManager._(JSObject _) implements JSObject {
  external JSPromise<JSAny?> request(String name, _LockOptions options, JSFunction callback);
}

extension type _LockOptions._(JSObject _) implements JSObject {
  external factory _LockOptions({bool ifAvailable});
}

@JS('Blob')
extension type _Blob._(JSObject _) implements JSObject {
  external factory _Blob(JSArray<JSAny> parts, _BlobOptions options);
}

extension type _BlobOptions._(JSObject _) implements JSObject {
  external factory _BlobOptions({String type});
}

extension type _Window._(JSObject _) implements JSObject {
  external _Document get document;
  external void print();
}

extension type _Document._(JSObject _) implements JSObject {
  external set title(String value);
  external _Element get body;
  external _Element createElement(String tag);
}

extension type _Element._(JSObject _) implements JSObject {
  external set textContent(String value);
  external void setAttribute(String name, String value);
  external void append(_Element child);
  external void click();
  external void remove();
}

/// [text] alone on a new tab, then the browser's print dialog for it (Phase 5 summary, parity row 38). Set as
/// textContent, never as HTML: the summary holds names people typed.
void printText(String title, String text) {
  final w = _open('', '_blank');
  if (w == null) return; // popup blocked: nothing to print into
  final d = w.document..title = title;
  final pre = d.createElement('pre')
    ..setAttribute('style', 'white-space: pre-wrap; font: 14px/1.5 system-ui, sans-serif; margin: 24px')
    ..textContent = text;
  d.body.append(pre);
  w.print();
}

/// Saves [bytes] as [fileName] through the browser's downloads. share_plus would call `navigator.share`, which on
/// desktop Chrome and Safari opens the system share sheet instead, with no way to save the file.
void downloadFile(Uint8List bytes, String fileName, String mime) {
  final url = _createObjectUrl(_Blob(<JSAny>[bytes.toJS].toJS, _BlobOptions(type: mime)));
  final a = _document.createElement('a')
    ..setAttribute('href', url)
    ..setAttribute('download', fileName);
  _document.body.append(a);
  a.click();
  a.remove();
  // Not at once: some browsers start reading the blob only after click() returns.
  Future<void>.delayed(const Duration(minutes: 1), () => _revokeObjectUrl(url));
}

/// The app database in IndexedDB on this tab, without drift's shared worker (`unsafeIndexedDb`): for a browser where
/// that worker can't start (AppDatabase.openChecked).
QueryExecutor tabDatabase(String name, Uri sqlite3, Uri worker) => DatabaseConnection.delayed(Future(() async {
      final probe = await WasmDatabase.probe(sqlite3Uri: sqlite3, driftWorkerUri: worker, databaseName: name);
      return probe.open(WasmStorageImplementation.unsafeIndexedDb, name);
    }));

/// Takes the Web Lock [name] for as long as this tab lives; false when another tab of this browser has it. A browser
/// without Web Locks: true (nothing to share it with).
Future<bool> holdTabLock(String name) {
  final locks = _locks;
  if (locks == null) return Future.value(true);
  final got = Completer<bool>();
  JSAny? held(JSAny? lock) {
    got.complete(lock != null);
    return lock == null ? null : Completer<void>().future.toJS; // never settles: kept until the tab closes
  }

  locks.request(name, _LockOptions(ifAvailable: true), held.toJS).toDart.ignore();
  return got.future;
}
