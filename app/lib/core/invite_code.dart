/// Invite codes: 6 chars from `23456789ABCDEFGHJKMNPQRSTUVWXYZ` (legacy: 10 chars).
String normalizeInviteCode(String input) => input.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

final _link = RegExp(r'/(?:j|join|f)/([A-Za-z0-9-]+)');

/// Whether [text] is a friend link (`…/f/CODE`, `evensies://f/CODE`), not a group invite.
bool isFriendLink(String text) => RegExp(r'/f/[A-Za-z0-9-]+').hasMatch(text);

/// Code from an invite link (`…/j/CODE`, `evensies://j/CODE`, `evensies://join/CODE`), a friend link (`…/f/CODE`,
/// `evensies://f/CODE`; group and friend codes share one namespace) or a bare 6/10-char code.
String? extractInviteCode(String text) {
  final m = _link.firstMatch(text);
  if (m != null) {
    final c = normalizeInviteCode(m.group(1)!);
    return c.isEmpty ? null : c;
  }
  // Bare text only counts if it is short and uses code characters, so arbitrary clipboard text is ignored.
  if (text.trim().length > 13) return null;
  final c = normalizeInviteCode(text);
  if (c.length != 6 && c.length != 10) return null;
  return c.split('').every(_codeChars.contains) ? c : null;
}

/// Current alphabet plus `L`, which the legacy 10-char codes could contain. No 0/O, 1/I.
const _codeChars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';

/// `ABCDEF` → `ABC-DEF`; other lengths unchanged.
String formatInviteCode(String code) => code.length == 6 ? '${code.substring(0, 3)}-${code.substring(3)}' : code;

final _uuid = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

/// The app route for a group invite link: `/join/CODE`, plus `?m=` when an email invite named the placeholder
/// (`…/j/CODE?m=<uuid>`, Phase 10); anything not UUID-shaped is dropped.
String joinRoute(String code, String link) {
  final m = Uri.tryParse(link)?.queryParameters['m'];
  return m != null && _uuid.hasMatch(m) ? '/join/$code?m=$m' : '/join/$code';
}
