import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/app_localizations.dart';
import 'jpeg_stub.dart' if (dart.library.js_interop) 'jpeg_web.dart' as web;

/// The one image pipeline (profile photos, receipts; group covers in Phase 10). The server never decodes pixels it
/// gets: the app re-encodes every image, and the server only strips metadata segments (docs/API.md, Profile photos).

/// The edge flutter_image_compress scales to: it keeps both edges at least `minWidth`/`minHeight`, so the same value
/// for both bounds the short edge. For a long edge of [maxEdge], the short edge goes to short × maxEdge / long. An image
/// already within [maxEdge] keeps its size (it never scales up).
int compressMinEdge(int width, int height, int maxEdge) {
  final long = max(width, height), short = min(width, height);
  if (long <= maxEdge) return max(short, 1);
  return max((short * maxEdge / long).floor(), 1);
}

/// The picked image couldn't be turned into a JPEG.
class UnusablePhoto implements Exception {
  const UnusablePhoto();
}

/// [picked] as JPEG bytes: the EXIF orientation applied to the pixels, EXIF (GPS included) dropped, HEIC converted,
/// the long edge at most [maxEdge]. Avatars use maxEdge 512, quality 85 (about 50 KB). In the browser a canvas
/// re-encodes it (any format it reads).
Future<Uint8List> prepareJpeg(XFile picked, {required int maxEdge, required int quality}) async {
  final bytes = await picked.readAsBytes();
  if (kIsWeb) return web.resizeJpeg(bytes, maxEdge: maxEdge, quality: quality);
  var minEdge = maxEdge;
  try {
    // Reads the size from the header without decoding the pixels.
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final desc = await ui.ImageDescriptor.encoded(buffer);
    minEdge = compressMinEdge(desc.width, desc.height, maxEdge);
    desc.dispose();
    buffer.dispose();
  } catch (_) {
    // A format the engine can't read (some HEIC): the picker already bounded both edges by maxEdge.
  }
  final r = await FlutterImageCompress.compressWithFile(
    picked.path,
    minWidth: minEdge,
    minHeight: minEdge,
    quality: quality,
    format: CompressFormat.jpeg,
    keepExif: false,
    autoCorrectionAngle: true,
  );
  if (r == null || r.isEmpty) throw const UnusablePhoto();
  return r;
}

typedef PickPhoto = Future<Uint8List?> Function(ImageSource source, {required int maxEdge, required int quality});

/// Camera or library → [prepareJpeg]; null when the user cancels. Tests override [pickPhotoProvider].
Future<Uint8List?> pickPhoto(ImageSource source, {required int maxEdge, required int quality}) async {
  final x = await ImagePicker().pickImage(
    source: source,
    maxWidth: maxEdge.toDouble(),
    maxHeight: maxEdge.toDouble(),
    imageQuality: quality,
    preferredCameraDevice: CameraDevice.front,
  );
  return x == null ? null : prepareJpeg(x, maxEdge: maxEdge, quality: quality);
}

final pickPhotoProvider = Provider<PickPhoto>((_) => pickPhoto);

/// What to tell the user when taking or picking a photo from [source] failed with [e] (never the raw error).
String photoErrorText(AppLocalizations l, Object e, ImageSource source) => switch (e) {
      PlatformException(:final code) when code.contains('access_denied') => l.photoNoAccess,
      PlatformException() => source == ImageSource.camera ? l.photoNoCamera : l.photoNoLibrary,
      _ => l.photoUnusable,
    };
