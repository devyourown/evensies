import 'dart:typed_data';

import 'package:drift/drift.dart' show QueryExecutor;

// Browser-only helpers (browser_web.dart); phones share instead.
void printText(String title, String text) => throw UnsupportedError('browser only');
void downloadFile(Uint8List bytes, String fileName, String mime) => throw UnsupportedError('browser only');
QueryExecutor tabDatabase(String name, Uri sqlite3, Uri worker) => throw UnsupportedError('browser only');
Future<bool> holdTabLock(String name) => throw UnsupportedError('browser only');
bool get hasSharedWorkers => throw UnsupportedError('browser only');
