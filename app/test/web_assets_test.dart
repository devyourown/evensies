import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The web build loads drift's worker and sqlite3's wasm from web/: their names carry the versions they were built
/// for, so a `flutter pub upgrade` that moves drift or sqlite3 fails here until the files are replaced too.
void main() {
  String locked(String package) {
    final lock = File('pubspec.lock').readAsStringSync();
    return RegExp('\\n  $package:\\n(?:    .*\\n)*?    version: "([^"]+)"').firstMatch(lock)![1]!;
  }

  test('web/ has the worker and wasm for the locked drift and sqlite3, and the database asks for them', () {
    final worker = 'drift_worker-${locked('drift')}.js';
    final wasm = 'sqlite3-${locked('sqlite3')}.wasm';
    expect(File('web/$worker').existsSync(), isTrue, reason: worker);
    expect(File('web/$wasm').existsSync(), isTrue, reason: wasm);
    final db = File('lib/data/db/database.dart').readAsStringSync();
    expect(db, contains("Uri.parse('$worker')"));
    expect(db, contains("Uri.parse('$wasm')"));
    expect(File('web/$wasm').readAsBytesSync().take(4), [0, 0x61, 0x73, 0x6d]); // "\0asm"
  });

  test("Google's sign-in script is held back before the app starts (web/gsi_lazy.js)", () {
    final index = File('web/index.html').readAsStringSync();
    expect(File('web/gsi_lazy.js').existsSync(), isTrue);
    final holder = index.indexOf('<script src="gsi_lazy.js"></script>');
    expect(holder, allOf(isNot(-1), lessThan(index.indexOf('flutter_bootstrap.js'))));
  });

  test('no stale copies', () {
    final names = Directory('web').listSync().map((e) => e.uri.pathSegments.last);
    expect(names.where((n) => n.startsWith('drift_worker')), hasLength(1));
    expect(names.where((n) => n.startsWith('sqlite3')), hasLength(1));
  });
}
