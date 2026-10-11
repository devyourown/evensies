import 'package:evensies/core/invite_code.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalize', () {
    expect(normalizeInviteCode(' k7p-4qx '), 'K7P4QX');
    expect(extractInviteCode(' k7p-4qx '), 'K7P4QX');
  });
  test('links', () {
    expect(extractInviteCode('Join: https://evensies.nariinfo.dev/j/k7p-4qx'), 'K7P4QX');
    expect(extractInviteCode('evensies://j/K7P4QX'), 'K7P4QX');
    expect(extractInviteCode('evensies://join/k7p4qx?x=1'), 'K7P4QX');
  });
  test('friend links (Phase 6)', () {
    expect(extractInviteCode('Add me: https://evensies.nariinfo.dev/f/k7p-4qx'), 'K7P4QX');
    expect(extractInviteCode('evensies://f/K7P4QX'), 'K7P4QX');
    expect(isFriendLink('evensies://f/K7P4QX'), isTrue);
    expect(isFriendLink('https://evensies.nariinfo.dev/f/K7P4QX'), isTrue);
    expect(isFriendLink('https://evensies.nariinfo.dev/j/K7P4QX'), isFalse);
    expect(isFriendLink('K7P4QX'), isFalse);
  });
  test('legacy 10-char code', () => expect(extractInviteCode('5c934x86ye'), '5C934X86YE'));
  test('junk', () {
    expect(extractInviteCode('see you at 7pm tonight'), isNull);
    expect(extractInviteCode(''), isNull);
    expect(extractInviteCode('abc'), isNull);
  });
  test('format', () {
    expect(formatInviteCode('K7P4QX'), 'K7P-4QX');
    expect(formatInviteCode('5C934X86YE'), '5C934X86YE');
  });

  test('ordinary clipboard text is not mistaken for a code', () {
    expect(extractInviteCode('hello world'), isNull); // has O
    expect(extractInviteCode('see you at seven tonight'), isNull); // too long
    expect(extractInviteCode('ABC100'), isNull); // 1 and 0 never appear in codes
  });
}
