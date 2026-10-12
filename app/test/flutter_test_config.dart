import 'dart:async';
import 'dart:io';

import 'package:evensies/core/strings.dart';

/// Runs before every test file: the shared text table (activity sentences, category names, money notation) as the
/// app loads it at startup.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  Strings.loadFromJson(File('../shared/strings.json').readAsStringSync());
  await testMain();
}
