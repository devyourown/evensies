import 'dart:js_interop';
import 'dart:typed_data';

@JS('open')
external _Window? _open(String url, String target);

@JS('document')
external _Document get _document;

@JS('URL.createObjectURL')
external String _createObjectUrl(_Blob blob);

@JS('URL.revokeObjectURL')
external void _revokeObjectUrl(String url);

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
