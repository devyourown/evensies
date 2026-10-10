import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../data/api/dto.dart';
import '../../data/db/database.dart';
import '../../providers.dart';

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
    await _store(await ref.read(apiProvider).authApple(token));
  }

  Future<void> google() async {
    final g = GoogleSignIn.instance;
    await g.initialize();
    final account = await g.authenticate();
    final token = account.authentication.idToken;
    if (token == null) throw const ApiException(code: 'GOOGLE', message: 'No id token from Google');
    await _store(await ref.read(apiProvider).authGoogle(token));
  }

  Future<void> logout() => ref.read(dbProvider).wipeAll();

  Future<void> deleteAccount() async {
    await ref.read(apiProvider).deleteMe();
    await logout();
  }

  static bool get appleAvailable => Platform.isIOS || Platform.isMacOS;
}

final authServiceProvider = Provider((ref) => AuthService(ref));
