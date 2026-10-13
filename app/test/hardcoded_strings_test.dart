import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Every user-visible string goes through the ARB files or shared/strings.json (docs/API.md, Languages and web): no English
/// literal in a Text, a label or a snackbar, and no `toStringAsFixed` (it writes `.` in every language).
void main() {
  final patterns = [
    RegExp(r"Text\(\s*'[^'$]*[A-Za-z]"),
    RegExp(r'Text\(\s*"[^"$]*[A-Za-z]'),
    RegExp(r"""(labelText|hintText|helperText|tooltip|title|label|subtitle|message|confirmLabel|semanticLabel|semanticsLabel):\s*(const )?['"][^'"]*[A-Za-z]"""),
    RegExp(r"""show(Info|Error)\(context,\s*['"]"""),
    RegExp(r'toStringAsFixed\('),
  ];
  // Brand, the invite code's shape, the DEV login block (a developer-only build switch), and an ApiException's
  // message (never shown: the screens word the code).
  final allowed = [
    RegExp(r"'ABC-DEF'"),
    RegExp(r'ApiException\(code:'),
    RegExp(r"'Evensies'"),
    RegExp(r"'DEV'"),
    RegExp(r"'Dev name'"),
    RegExp(r"'Dev login'"),
  ];

  test('no hard-coded UI text in lib/features and lib/core', () {
    final hits = <String>[];
    for (final dir in ['lib/features', 'lib/core']) {
      for (final f in Directory(dir).listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
        final lines = f.readAsLinesSync();
        for (final (i, line) in lines.indexed) {
          if (line.trimLeft().startsWith('//')) continue;
          if (!patterns.any((p) => p.hasMatch(line)) || allowed.any((a) => a.hasMatch(line))) continue;
          hits.add('${f.path}:${i + 1}: ${line.trim()}');
        }
      }
    }
    expect(hits, isEmpty, reason: hits.join('\n'));
  });
}
