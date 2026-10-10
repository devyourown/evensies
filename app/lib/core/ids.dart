import 'package:uuid/uuid.dart';

const _uuid = Uuid();
String newId() => _uuid.v4();

String todayIso() => DateTime.now().toIso8601String().substring(0, 10);
String nowIsoUtc() => DateTime.now().toUtc().toIso8601String();
