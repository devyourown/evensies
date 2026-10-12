import 'dart:typed_data';

// Browser-only helpers (browser_web.dart); phones share instead.
void printText(String title, String text) => throw UnsupportedError('browser only');
void downloadFile(Uint8List bytes, String fileName, String mime) => throw UnsupportedError('browser only');
