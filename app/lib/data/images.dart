import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show PlatformException;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/ids.dart';

/// The one image pipeline (profile photos now; receipts in Phase 7, group covers in Phase 10). The server never decodes
/// pixels it gets: the app re-encodes every image, and the server only strips metadata segments (docs/API.md 프로필 사진).

/// The edge flutter_image_compress scales to: it keeps both edges at least `minWidth`/`minHeight`, so the same value
/// for both bounds the short edge. For a long edge of [maxEdge], the short edge goes to short × maxEdge / long. An image
/// already within [maxEdge] keeps its size (it never scales up).
int compressMinEdge(int width, int height, int maxEdge) {
  final long = max(width, height), short = min(width, height);
  if (long <= maxEdge) return max(short, 1);
  return max((short * maxEdge / long).floor(), 1);
}

/// [picked] as a JPEG file: the EXIF orientation applied to the pixels, EXIF (GPS included) dropped, HEIC converted,
/// the long edge at most [maxEdge]. Avatars use maxEdge 512, quality 85 (about 50 KB).
Future<File> prepareJpeg(XFile picked, {required int maxEdge, required int quality}) async {
  var minEdge = maxEdge;
  try {
    // Reads the size from the header without decoding the pixels.
    final buffer = await ui.ImmutableBuffer.fromUint8List(await picked.readAsBytes());
    final desc = await ui.ImageDescriptor.encoded(buffer);
    minEdge = compressMinEdge(desc.width, desc.height, maxEdge);
    desc.dispose();
    buffer.dispose();
  } catch (_) {
    // A format the engine can't read (some HEIC): the picker already bounded both edges by maxEdge.
  }
  final out = p.join((await getTemporaryDirectory()).path, '${newId()}.jpg');
  final r = await FlutterImageCompress.compressAndGetFile(
    picked.path,
    out,
    minWidth: minEdge,
    minHeight: minEdge,
    quality: quality,
    format: CompressFormat.jpeg,
    keepExif: false,
    autoCorrectionAngle: true,
  );
  if (r == null) throw const FileSystemException("Couldn't read that image");
  return File(r.path);
}

typedef PickPhoto = Future<File?> Function(ImageSource source, {required int maxEdge, required int quality});

/// Camera or library → [prepareJpeg]; null when the user cancels. Tests override [pickPhotoProvider].
Future<File?> pickPhoto(ImageSource source, {required int maxEdge, required int quality}) async {
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
String photoErrorText(Object e, ImageSource source) => switch (e) {
      PlatformException(:final code) when code.contains('access_denied') =>
        'Evensies has no access. Allow it in the Settings app.',
      PlatformException() => "Couldn't open the ${source == ImageSource.camera ? 'camera' : 'photo library'}.",
      _ => "That photo couldn't be used. Try another one.",
    };
