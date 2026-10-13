import 'package:uuid/uuid.dart';

const _uuid = Uuid();
String newId() => _uuid.v4();

String todayIso() => DateTime.now().toIso8601String().substring(0, 10);
/// Always six fraction digits, so the text sorts like the time (the outbox is ordered by it): toIso8601String drops the
/// microseconds when they are 0, and "…05.123Z" would sort after "…05.123045Z".
String nowIsoUtc([DateTime? now]) {
  final s = (now ?? DateTime.now()).toUtc().toIso8601String();
  return s.length == 24 ? '${s.substring(0, 23)}000Z' : s;
}

/// This device's UTC offset now as `±HH:MM` (`+00:00` for UTC), the time zone of a new repeating series (docs/API.md,
/// Recurring expenses). No IANA name without a plugin: across a DST change only the posting hour moves, never the date.
String deviceTimeZone([Duration? offset]) {
  final o = offset ?? DateTime.now().timeZoneOffset;
  final m = o.inMinutes.abs();
  return '${o.isNegative ? '-' : '+'}${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
}
