import 'dart:typed_data';

/// Phones re-encode with flutter_image_compress (images.dart); only the browser uses this.
Future<Uint8List> resizeJpeg(Uint8List bytes, {required int maxEdge, required int quality}) =>
    throw UnsupportedError('browser only');
