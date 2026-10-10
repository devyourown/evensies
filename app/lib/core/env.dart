import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract final class Env {
  static const defaultServerUrl =
      String.fromEnvironment('EVENSIES_SERVER_URL', defaultValue: 'https://evensies.nariinfo.dev');
  static const devLogin = bool.fromEnvironment('DEV_LOGIN', defaultValue: false);
}

/// Overridden in main() with the real instance.
final sharedPreferencesProvider = Provider<SharedPreferences>((_) => throw UnimplementedError());

/// Server base URL: Settings override (persisted) or the dart-define default.
class ServerUrl extends Notifier<String> {
  static const _key = 'serverUrl';
  @override
  String build() => ref.read(sharedPreferencesProvider).getString(_key) ?? Env.defaultServerUrl;

  Future<void> set(String url) async {
    final u = url.trim().replaceAll(RegExp(r'/+$'), '');
    state = u.isEmpty ? Env.defaultServerUrl : u;
    await ref.read(sharedPreferencesProvider).setString(_key, state);
  }
}

final serverUrlProvider = NotifierProvider<ServerUrl, String>(ServerUrl.new);
