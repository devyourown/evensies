import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/invite_code.dart';
import 'features/auth/auth_service.dart';
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
  late final VoidCallback _stopRetry;
  bool _fxFetched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenDeepLinks();
    initPush(ref);
    ref.read(authServiceProvider).refreshMe(); // a saved session's name and home currency (no-op when signed out)
    // Before the first sync, so a change refused while the app was closed is still told.
    _rejections = ref.read(syncProvider).rejections.listen((msg) => scaffoldMessengerKey.currentState
        ?.showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 8))));
    _stopRetry = ref.read(syncProvider).retryWhileOffline();
    // At launch with a session, and after every sign-in: a returning user's groups come from the server.
    ref.listenManual(sessionProvider.select((s) => s.value?.userId), (prev, userId) {
      if (userId == prev) return;
      // Sign-out or another account; not at launch, where the icon keeps its count until the refresh below answers.
      if (prev != null) ref.read(unreadProvider.notifier).reset();
      if (userId == null) return;
      ref.read(syncProvider).syncAll();
      ref.read(unreadProvider.notifier).refresh();
      // The latest rate table once per app start, for the "≈" lines and offline expenses (docs/API.md 환율).
      if (!_fxFetched) {
        _fxFetched = true;
        ref.read(fxRatesProvider).lookup();
      }
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _rejections?.cancel();
    _stopRetry();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(syncProvider).syncAll();
      ref.read(authServiceProvider).refreshMe();
      ref.read(unreadProvider.notifier).refresh();
      // A friend's new (or removed) photo; the shown one stays while it reloads.
      ref.invalidate(avatarProvider);
    }
  }

  void _listenDeepLinks() {
    final links = AppLinks();
    void handle(Uri? uri) {
      if (uri == null) return;
      final link = uri.toString();
      final code = extractInviteCode(link);
      if (code != null) ref.read(routerProvider).push(isFriendLink(link) ? '/friends/add?code=$code' : '/join/$code');
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
