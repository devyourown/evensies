import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract final class Env {
  static const _serverUrl = String.fromEnvironment('EVENSIES_SERVER_URL');

  /// The dart-define, else the web app's own origin (it is served by its server, `/app/`), else the official server.
  static String get defaultServerUrl =>
      _serverUrl.isNotEmpty ? _serverUrl : (kIsWeb ? Uri.base.origin : 'https://evensies.nariinfo.dev');
  // OAuth client ids are public (they ship inside every app binary), not secrets.
  static const googleServerClientId =
      String.fromEnvironment('EVENSIES_GOOGLE_SERVER_CLIENT_ID', defaultValue: '735984614718-p2ga7bem68i1tbs6se9tmfrcrepfnggt.apps.googleusercontent.com');
  static const devLogin = bool.fromEnvironment('DEV_LOGIN', defaultValue: false);
}

/// Overridden in main() with the real instance.
final sharedPreferencesProvider = Provider<SharedPreferences>((_) => throw UnimplementedError());

/// Server base URL: Settings override (persisted; not on the web, where the field is hidden) or the default.
class ServerUrl extends Notifier<String> {
  static const _key = 'serverUrl';
  @override
  String build() => (kIsWeb ? null : ref.read(sharedPreferencesProvider).getString(_key)) ?? Env.defaultServerUrl;

  Future<void> set(String url) async {
    final u = url.trim().replaceAll(RegExp(r'/+$'), '');
    state = u.isEmpty ? Env.defaultServerUrl : u;
    await ref.read(sharedPreferencesProvider).setString(_key, state);
  }
}

final serverUrlProvider = NotifierProvider<ServerUrl, String>(ServerUrl.new);
