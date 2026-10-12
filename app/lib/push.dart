import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/env.dart';
import 'core/ids.dart';
import 'core/l10n.dart';
import 'providers.dart';
import 'router.dart';

/// SharedPreferences key of this install's device id (POST/DELETE /devices).
const deviceIdKey = 'deviceId';

/// SharedPreferences flag: a sign-out could not delete this install's FCM token yet (offline).
@visibleForTesting
const tokenToDeleteKey = 'pushTokenToDelete';

/// App-wide messenger: the in-app push banner and SnackBars that outlive a screen (Undo after delete).
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// FCM (docs/API.md 푸시): group messages carry data {"type":"sync","groupId","seq"} → sync(groupId), or syncAll() for a
/// group not on this device yet (a new friend group); reminders carry {"type":"remind","fromUserId"} (Phase 6).
/// Visible ones (notification title/body) show an in-app banner in the foreground; tapping one opens the
/// group's Activity tab (a friend group: the friend's page) or, for a reminder, the sender's friend page. Every
/// message refreshes the unread count. No-op when Firebase is not configured (no GoogleService-Info.plist / google-services.json).
/// The token is registered whenever someone is signed in (at launch, after a sign-in, on refresh). The permission
/// prompt waits until there is a group (created, joined, or adopted on a new device), not at launch.
/// Losing the session in any way deletes the token at FCM (see [wirePush]).
Future<void> initPush(WidgetRef ref) async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase not configured, push disabled: $e');
    return;
  }
  final fm = FirebaseMessaging.instance;
  await wirePush(
    ref,
    getToken: fm.getToken,
    deleteToken: fm.deleteToken,
    requestPermission: fm.requestPermission,
    onTokenRefresh: fm.onTokenRefresh,
    onMessage: FirebaseMessaging.onMessage,
    onMessageOpenedApp: FirebaseMessaging.onMessageOpenedApp,
    getInitialMessage: fm.getInitialMessage,
  );
}

/// [initPush] without Firebase: tests pass fakes for the FCM calls and streams.
@visibleForTesting
Future<void> wirePush(
  WidgetRef ref, {
  required Future<String?> Function() getToken,
  required Future<void> Function() deleteToken,
  required Future<Object?> Function() requestPermission,
  required Stream<String> onTokenRefresh,
  required Stream<RemoteMessage> onMessage,
  required Stream<RemoteMessage> onMessageOpenedApp,
  required Future<RemoteMessage?> Function() getInitialMessage,
}) async {
  /// Sends this device's FCM token (or [token]) to the server for the signed-in user; errors are only logged.
  Future<void> register([String? token]) async {
    try {
      if (await ref.read(dbProvider).getSession() == null) return;
      token ??= await getToken();
      if (token == null) return;
      final prefs = ref.read(sharedPreferencesProvider);
      final deviceId = prefs.getString(deviceIdKey) ?? newId();
      await prefs.setString(deviceIdKey, deviceId);
      await ref.read(apiProvider).registerDevice(deviceId, token);
    } catch (e) {
      debugPrint('Push token registration failed: $e');
    }
  }

  /// Signed out (sign-out, account deletion, or the session cleared after a failed refresh): FCM invalidates this
  /// phone's token, so the server's next send gets UNREGISTERED and drops the device row even when DELETE /devices
  /// never reached it. Until then the flag stays set and [retryForget] tries again.
  Future<void> forgetToken() async {
    try {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setBool(tokenToDeleteKey, true);
      await deleteToken();
      await prefs.remove(tokenToDeleteKey);
    } catch (e) {
      debugPrint('Push token deletion failed: $e');
    }
  }

  /// A deletion that failed earlier, retried while still signed out (a later sign-in moves the token instead).
  Future<void> retryForget() async {
    try {
      if (ref.read(sharedPreferencesProvider).getBool(tokenToDeleteKey) != true) return;
      if (await ref.read(dbProvider).getSession() == null) await forgetToken();
    } catch (e) {
      debugPrint('Push token deletion retry failed: $e');
    }
  }

  // Before anything that can throw, so a failed launch step never leaves these unset.
  onTokenRefresh.listen(register);
  ref.listenManual(sessionProvider.select((s) => s.value?.userId), (prev, userId) {
    if (userId != null && userId != prev) register();
    if (userId == null && prev != null) forgetToken();
  }, fireImmediately: true);
  // ponytail: retried only at launch and on resume; a phone that stays in the background keeps showing the
  // signed-out user's pushes until then. A server-side session link on devices if that ever matters.
  AppLifecycleListener(onResume: retryForget);
  unawaited(retryForget());
  // From no groups to some (null while loading, so a launch with groups never prompts). The OS prompts only once;
  // register again after it, since some platforms hand out a usable token only once notifications are allowed.
  ref.listenManual(groupsProvider.select((g) => g.value?.isNotEmpty), (prev, any) async {
    if (prev != false || any != true) return;
    try {
      await requestPermission();
    } catch (e) {
      debugPrint('Push permission request failed: $e');
    }
    await register();
  });
  try {
    /// Where tapping [m] goes; null when it has nowhere to go.
    String? target(RemoteMessage? m) {
      final d = m?.data ?? const <String, dynamic>{};
      if (d['type'] == 'remind' && d['fromUserId'] is String) return '/friends/${d['fromUserId']}';
      final groupId = d['groupId'];
      return groupId is String ? '/groups/$groupId?tab=activity' : null;
    }

    Future<void> open(RemoteMessage? m) async {
      final to = target(m);
      if (to == null) return;
      await ref.read(sessionProvider.future); // let the router's sign-in redirect settle first
      ref.read(routerProvider).go(to);
    }

    onMessage.listen((m) async {
      final groupId = m.data['groupId'];
      if (m.data['type'] == 'sync' && groupId is String) {
        final sync = ref.read(syncProvider);
        // A group this device doesn't have yet (someone added me as a friend): adopt it with the rest.
        (await ref.read(dbProvider).getGroup(groupId)) == null ? sync.syncAll() : sync.syncLater(groupId);
      }
      ref.read(unreadProvider.notifier).refresh();
      final n = m.notification;
      if (n != null) _showBanner(n.title ?? 'Evensies', n.body ?? '', target(m) == null ? null : () => open(m));
    });
    onMessageOpenedApp.listen(open);
    await open(await getInitialMessage());
  } catch (e) {
    debugPrint('FCM setup failed: $e');
  }
}

ScaffoldFeatureController<MaterialBanner, MaterialBannerClosedReason>? _banner;

/// Top banner with the notification's title/body, hidden after a few seconds.
void _showBanner(String title, String body, VoidCallback? onOpen) {
  final messenger = scaffoldMessengerKey.currentState;
  if (messenger == null) return;
  messenger.removeCurrentMaterialBanner();
  final c = messenger.showMaterialBanner(MaterialBanner(
    leading: const Icon(Icons.notifications_outlined),
    content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      if (body.isNotEmpty) Text(body, maxLines: 3, overflow: TextOverflow.ellipsis),
    ]),
    actions: [
      TextButton(onPressed: messenger.hideCurrentMaterialBanner, child: Text(messenger.context.l.bannerDismiss)),
      if (onOpen != null)
        TextButton(
          onPressed: () {
            messenger.hideCurrentMaterialBanner();
            onOpen();
          },
          child: Text(messenger.context.l.bannerView),
        ),
    ],
  ));
  _banner = c;
  c.closed.then((_) {
    if (identical(_banner, c)) _banner = null;
  });
  Timer(const Duration(seconds: 5), () {
    if (identical(_banner, c)) messenger.hideCurrentMaterialBanner();
  });
}
