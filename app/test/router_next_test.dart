import 'package:evensies/data/db/database.dart';
import 'package:evensies/router.dart';
import 'package:flutter_test/flutter_test.dart';

SessionRow _session(String name) =>
    SessionRow(id: 1, accessToken: 'a', refreshToken: 'r', userId: 'u', displayName: name);

/// docs/API.md, Web app, back after sign-in: a signed-out link goes through /login (and /name) and lands where it pointed.
void main() {
  String? go(SessionRow? s, String location) {
    final uri = Uri.parse(location);
    return authRedirect(s, uri.path, uri);
  }

  test('next stays in the app', () {
    expect(safeNext('/join/K7P4QX'), '/join/K7P4QX');
    expect(safeNext('//evil.example'), isNull);
    expect(safeNext('https://evil.example'), isNull);
    expect(safeNext('join'), isNull);
    expect(safeNext(null), isNull);
  });

  test('signed out: every page goes to /login with next; the home page without it', () {
    expect(go(null, '/join/K7P4QX'), '/login?next=%2Fjoin%2FK7P4QX');
    expect(go(null, '/friends/add?code=ABC'), '/login?next=%2Ffriends%2Fadd%3Fcode%3DABC');
    expect(go(null, '/'), '/login');
    expect(go(null, '/login?next=/join/K7P4QX'), isNull);
  });

  test('after sign-in: next, else home; a foreign next is dropped', () {
    final anna = _session('Anna');
    expect(go(anna, '/login?next=%2Fjoin%2FK7P4QX'), '/join/K7P4QX');
    expect(go(anna, '/login'), '/');
    expect(go(anna, '/login?next=%2F%2Fevil.example'), '/');
    expect(go(anna, '/groups/g1'), isNull);
  });

  test('a new account names itself first and keeps next', () {
    final nameless = _session('');
    expect(go(nameless, '/login?next=%2Fjoin%2FK7P4QX'), '/name?next=%2Fjoin%2FK7P4QX');
    expect(go(nameless, '/name?next=%2Fjoin%2FK7P4QX'), isNull);
    expect(go(nameless, '/'), '/name');
  });

  test('email sign-in (Phase 10): the code page stays while signed out and keeps next; then next', () {
    expect(go(null, '/login/email?next=%2Fjoin%2FK7P4QX%3Fm%3Dx'), isNull);
    expect(go(_session('Anna'), '/login/email?next=%2Fjoin%2FK7P4QX%3Fm%3Dx'), '/join/K7P4QX?m=x');
    expect(go(_session(''), '/login/email?next=%2Fjoin%2FK7P4QX'), '/name?next=%2Fjoin%2FK7P4QX');
  });
}
