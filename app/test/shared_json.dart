import 'dart:convert';
import 'dart:io';

/// Loads `../shared/<name>` relative to the app/ dir where `flutter test` runs.
Map<String, dynamic> loadShared(String name) {
  final f = File('../shared/$name');
  if (!f.existsSync()) {
    throw StateError('Missing ${f.absolute.path}. Run `flutter test` from the app/ directory of the evensies repo.');
  }
  return jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
}

List<Map<String, dynamic>> sharedCases(String name) => (loadShared(name)['cases'] as List).cast<Map<String, dynamic>>();
