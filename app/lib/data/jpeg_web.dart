import 'dart:js_interop';
import 'dart:typed_data';

@JS('Blob')
extension type _Blob._(JSObject _) implements JSObject {
  external factory _Blob(JSArray<JSAny> parts);
  external JSPromise<JSArrayBuffer> arrayBuffer();
}

extension type _Bitmap._(JSObject _) implements JSObject {
  external int get width;
  external int get height;
  external void close();
}

@JS('createImageBitmap')
external JSPromise<_Bitmap> _createImageBitmap(_Blob blob);

@JS('OffscreenCanvas')
extension type _Canvas._(JSObject _) implements JSObject {
  external factory _Canvas(int width, int height);
  external _Context getContext(String kind);
  external JSPromise<_Blob> convertToBlob(_BlobOptions options);
}

extension type _Context._(JSObject _) implements JSObject {
  external void drawImage(_Bitmap image, num x, num y, num width, num height);
}

extension type _BlobOptions._(JSObject _) implements JSObject {
  external factory _BlobOptions({String type, num quality});
}

/// [bytes] (any image the browser reads) as a JPEG with its long edge at most [maxEdge]: drawn on a canvas, which
/// applies the EXIF orientation and drops the metadata (docs/API.md 사진(웹)).
Future<Uint8List> resizeJpeg(Uint8List bytes, {required int maxEdge, required int quality}) async {
  final bitmap = await _createImageBitmap(_Blob([bytes.toJS].toJS)).toDart;
  final long = bitmap.width > bitmap.height ? bitmap.width : bitmap.height;
  final scale = long > maxEdge ? maxEdge / long : 1.0;
  final w = (bitmap.width * scale).round().clamp(1, maxEdge), h = (bitmap.height * scale).round().clamp(1, maxEdge);
  final canvas = _Canvas(w, h);
  canvas.getContext('2d').drawImage(bitmap, 0, 0, w, h);
  bitmap.close();
  final blob = await canvas.convertToBlob(_BlobOptions(type: 'image/jpeg', quality: quality / 100)).toDart;
  return (await blob.arrayBuffer().toDart).toDart.asUint8List();
}
