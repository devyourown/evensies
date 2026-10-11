import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/invite_code.dart';
import 'providers.dart';
import 'push.dart';
import 'router.dart';

class EvensiesApp extends ConsumerStatefulWidget {
  const EvensiesApp({super.key});
  @override
  ConsumerState<EvensiesApp> createState() => _EvensiesAppState();
}

class _EvensiesAppState extends ConsumerState<EvensiesApp> with WidgetsBindingObserver {
  StreamSubscription<String>? _rejections;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenDeepLinks();
    initPush(ref);
    // Before the first sync, so a change refused while the app was closed is still told.
    _rejections = ref.read(syncProvider).rejections.listen((msg) => scaffoldMessengerKey.currentState
        ?.showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 8))));
    // At launch with a session, and after every sign-in: a returning user's groups come from the server.
    ref.listenManual(sessionProvider.select((s) => s.value?.userId), (prev, userId) {
      if (userId != null && userId != prev) ref.read(syncProvider).syncAll();
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _rejections?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) ref.read(syncProvider).syncAll();
  }

  void _listenDeepLinks() {
    final links = AppLinks();
    void handle(Uri? uri) {
      if (uri == null) return;
      final code = extractInviteCode(uri.toString());
      if (code != null) ref.read(routerProvider).push('/join/$code');
    }

    links.getInitialLink().then(handle);
    links.uriLinkStream.listen(handle);
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Evensies',
        scaffoldMessengerKey: scaffoldMessengerKey,
        theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
        darkTheme: ThemeData(colorSchemeSeed: Colors.teal, brightness: Brightness.dark, useMaterial3: true),
        routerConfig: ref.watch(routerProvider),
      );
}
