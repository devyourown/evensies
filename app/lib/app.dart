import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'core/appearance.dart';
import 'core/env.dart';
import 'core/invite_code.dart';
import 'domain/overview.dart' show Overview;
import 'core/l10n.dart';
import 'features/auth/auth_service.dart';
import 'features/friends/home_data.dart';
import 'features/groups/wide_layout.dart';
import 'features/home_widget/widget_summary.dart';
import 'features/lock/app_lock.dart';
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
  Timer? _poll;
  final _widget = WidgetWriter();
  final _widgetLater = Debouncer(const Duration(seconds: 1));

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // The UI language drives amounts, dates, rejected-change messages and what the server writes to me.
    ref.listenManual(languageProvider, (_, lang) {
      applyLanguage(lang, ref.read(deviceLocalesProvider));
      ref.read(syncProvider).l10n = lookupAppLocalizations(Locale(lang));
      ref.read(authServiceProvider).syncLanguage(lang);
      _updateWidget();
    }, fireImmediately: true);
    if (!kIsWeb) {
      _listenDeepLinks();
      initPush(ref);
    }
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
      _updateWidget();
      if (userId == null) {
        // Whoever signs in next tells the server their language again.
        ref.read(sharedPreferencesProvider).remove(AuthService.sentLanguageKey);
        return;
      }
      ref.read(syncProvider).syncAll();
      ref.read(unreadProvider.notifier).refresh();
      ref.read(authServiceProvider).syncLanguage(ref.read(languageProvider));
      // The latest rate table once per app start, for the "≈" lines and offline expenses (docs/API.md 환율).
      if (!_fxFetched) {
        _fxFetched = true;
        ref.read(fxRatesProvider).lookup();
      }
    }, fireImmediately: true);
    if (!kIsWeb) {
      ref.listenManual(homeDataProvider, (_, _) => _updateWidget());
      ref.listenManual(latestFxProvider, (_, _) => _updateWidget());
    }
    // No web push: the tab syncs when it comes to the front and every 60 s while it is visible (docs/API.md 새로 고침).
    // A visible tab without focus (DevTools, another window, the Google sign-in frame) is `inactive` and still polls.
    if (kIsWeb) {
      _poll = Timer.periodic(const Duration(seconds: 60), (_) {
        final s = WidgetsBinding.instance.lifecycleState;
        if (s != AppLifecycleState.hidden && s != AppLifecycleState.paused) _refresh();
      });
    }
  }

  /// The home-screen widget's payload, 1 s after things settle (docs/API.md 홈 화면 위젯).
  void _updateWidget() {
    if (kIsWeb) return;
    _widgetLater(() {
      if (!mounted) return;
      final lang = ref.read(languageProvider);
      final home = ref.read(homeDataProvider).value;
      final signedIn = ref.read(sessionProvider).value != null;
      if (signedIn && home == null) return; // still loading: the next change writes it
      _widget.write(widgetSummary(
        lookupAppLocalizations(Locale(lang)),
        signedIn: signedIn,
        overview: home?.overview ?? const Overview(),
        home: ref.read(homeCurrencyProvider),
        perEur: ref.read(latestFxProvider).value?.rates,
        now: DateTime.now(),
        locale: Intl.defaultLocale,
      ));
    });
  }

  @override
  void dispose() {
    _rejections?.cancel();
    _stopRetry();
    _poll?.cancel();
    _widgetLater.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeLocales(List<Locale>? locales) => ref.invalidate(deviceLocalesProvider);

  /// Hidden (or paused) since the last resume.
  bool _wasHidden = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.hidden || state == AppLifecycleState.paused) _wasHidden = true;
    if (state != AppLifecycleState.resumed) return;
    // The web is `inactive` whenever the window loses focus: only a tab coming back from hidden reloads the photos.
    _refresh(avatars: !kIsWeb || _wasHidden);
    _wasHidden = false;
  }

  void _refresh({bool avatars = false}) {
    // Signed out (the sign-in page): nothing of mine to fetch, and no 401s in the console.
    if (ref.read(sessionProvider).value != null) {
      ref.read(syncProvider).syncAll();
      ref.read(authServiceProvider).refreshMe();
      ref.read(unreadProvider.notifier).refresh();
      ref.read(authServiceProvider).syncLanguage(ref.read(languageProvider));
    }
    // A friend's new (or removed) photo; the shown one stays while it reloads. And what the server offers (email).
    if (avatars) {
      ref.invalidate(avatarProvider);
      ref.invalidate(serverInfoProvider);
    }
  }

  void _listenDeepLinks() {
    final links = AppLinks();
    void handle(Uri? uri) {
      if (uri == null) return;
      final link = uri.toString();
      final code = extractInviteCode(link);
      if (code != null) {
        ref.read(routerProvider).push(isFriendLink(link) ? '/friends/add?code=$code' : joinRoute(code, link));
      }
    }

    links.getInitialLink().then(handle);
    links.uriLinkStream.listen(handle);
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    // Until the saved session is loaded, nothing rather than a flash of the sign-in page (router redirect).
    final session = ref.watch(sessionProvider);
    final loading = session.isLoading && !session.hasValue;
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (_) => 'Evensies',
      locale: Locale(lang),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      scaffoldMessengerKey: scaffoldMessengerKey,
      themeMode: ref.watch(themeModeProvider),
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      darkTheme: ThemeData(colorSchemeSeed: Colors.teal, brightness: Brightness.dark, useMaterial3: true),
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        final app = loading ? ColoredBox(color: Theme.of(context).colorScheme.surface) : child ?? const SizedBox.shrink();
        // The web: one 640 px column in the middle of the window, or the three columns of a wide window (docs/API.md
        // 화면 배치); phones: the lock on top.
        if (!kIsWeb) return LockGate(child: app);
        return WebColumn(wide: isWide(context), child: app);
      },
    );
  }
}
