import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/env.dart';
import 'core/ids.dart';
import 'providers.dart';

/// FCM data message {"type":"sync","groupId"} → sync(groupId). No-op when Firebase is not configured
/// (no GoogleService-Info.plist / google-services.json).
Future<void> initPush(WidgetRef ref) async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase not configured, push disabled: $e');
    return;
  }
  try {
    final fm = FirebaseMessaging.instance;
    await fm.requestPermission();
    final prefs = ref.read(sharedPreferencesProvider);
    final deviceId = prefs.getString('deviceId') ?? newId();
    await prefs.setString('deviceId', deviceId);
    Future<void> register(String? token) async {
      if (token == null || await ref.read(dbProvider).getSession() == null) return;
      await ref.read(apiProvider).registerDevice(deviceId, token);
    }

    await register(await fm.getToken());
    fm.onTokenRefresh.listen(register);
    FirebaseMessaging.onMessage.listen((m) {
      final groupId = m.data['groupId'];
      if (m.data['type'] == 'sync' && groupId is String) ref.read(syncProvider).syncLater(groupId);
    });
  } catch (e) {
    debugPrint('FCM setup failed: $e');
  }
}

