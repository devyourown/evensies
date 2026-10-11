import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/env.dart';
import '../../data/api/dto.dart';
import '../../data/db/database.dart';
import '../../providers.dart';
import '../../push.dart' show deviceIdKey;

class AuthService {
  final Ref ref;
  AuthService(this.ref);

  Future<void> _store(AuthResponse r) => ref.read(dbProvider).saveSession(SessionRow(
        id: 1,
        accessToken: r.accessToken,
        refreshToken: r.refreshToken,
        userId: r.user.id,
        displayName: r.user.displayName,
      ));

  Future<void> dev(String name) async => _store(await ref.read(apiProvider).authDev(name));

  Future<void> apple() async {
    final c = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName]);
    final token = c.identityToken;
    if (token == null) throw const ApiException(code: 'APPLE', message: 'No identity token from Apple');
    // Apple shares the name only on the very first sign-in and never inside the id token.
    final name = [c.givenName, c.familyName].whereType<String>().where((p) => p.trim().isNotEmpty).join(' ');
    await _store(await ref.read(apiProvider).authApple(token, displayName: name.isEmpty ? null : name));
  }

  Future<void> google() async {
    final g = GoogleSignIn.instance;
    // Web client id: Android needs it to return an id token; the server accepts it plus the iOS client id.
    await g.initialize(serverClientId: Env.googleServerClientId);
    final account = await g.authenticate();
    final token = account.authentication.idToken;
    if (token == null) throw const ApiException(code: 'GOOGLE', message: 'No id token from Google');
    await _store(await ref.read(apiProvider).authGoogle(token, displayName: account.displayName));
  }

  /// Unregisters this phone first (docs/API.md DELETE /devices), or the signed-out user's pushes keep arriving.
  /// Best effort: offline the row stays, but the session going away also deletes the FCM token (push.dart), so the
  /// server drops the row at its next send.
  Future<void> logout() async {
    final deviceId = ref.read(sharedPreferencesProvider).getString(deviceIdKey);
    if (deviceId != null && await ref.read(dbProvider).getSession() != null) {
      try {
        await ref.read(apiProvider).unregisterDevice(deviceId).timeout(const Duration(seconds: 5));
      } catch (_) {}
    }
    await ref.read(dbProvider).wipeAll();
  }

  /// The server already dropped every device of the account.
  Future<void> deleteAccount() async {
    await ref.read(apiProvider).deleteMe();
    await ref.read(dbProvider).wipeAll();
  }

  static bool get appleAvailable => Platform.isIOS || Platform.isMacOS;
}

final authServiceProvider = Provider((ref) => AuthService(ref));
