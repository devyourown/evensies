import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../../core/env.dart';
import '../../core/l10n.dart';
import '../auth/auth_service.dart';

/// App lock (docs/API.md, Appearance and app lock; phones only): Face ID, Touch ID or a fingerprint, the device passcode as fallback.

/// The device's own check; tests pass a fake.
abstract class Authenticator {
  Future<bool> isSupported();

  /// True only when the person passed; a cancel or an error is false.
  Future<bool> authenticate(String reason);
}

class _DeviceAuthenticator implements Authenticator {
  final _auth = LocalAuthentication();
  @override
  Future<bool> isSupported() async {
    if (kIsWeb) return false;
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(localizedReason: reason, biometricOnly: false);
    } catch (_) {
      return false;
    }
  }
}

final authenticatorProvider = Provider<Authenticator>((_) => _DeviceAuthenticator());

/// Whether Settings offers the switch: never on the web.
final lockSupportedProvider = FutureProvider<bool>((ref) => ref.watch(authenticatorProvider).isSupported());

/// The switch (prefs `appLock`, off by default).
class AppLockSetting extends Notifier<bool> {
  static const key = 'appLock';
  @override
  bool build() => !kIsWeb && ref.read(sharedPreferencesProvider).getBool(key) == true;

  /// On only after one successful check, so nobody locks themselves out.
  Future<bool> enable(String reason) async {
    if (!await ref.read(authenticatorProvider).authenticate(reason)) return false;
    state = true;
    await ref.read(sharedPreferencesProvider).setBool(key, true);
    return true;
  }

  Future<void> disable() async {
    state = false;
    await ref.read(sharedPreferencesProvider).remove(key);
  }
}

final appLockProvider = NotifierProvider<AppLockSetting, bool>(AppLockSetting.new);

/// Locked at a cold start; a cover while the app is in the background (the app switcher shows no balances); locked
/// again when it comes back after [timeout] or more.
class AppLockState extends ChangeNotifier {
  final bool Function() enabled;
  final DateTime Function() now;
  static const timeout = Duration(seconds: 60);
  AppLockState({required this.enabled, DateTime Function()? clock}) : now = clock ?? DateTime.now {
    locked = enabled();
  }

  late bool locked;
  bool covered = false;
  DateTime? _away;

  void lifecycle(AppLifecycleState s) {
    if (!enabled()) {
      _set(false, false);
      _away = null;
      return;
    }
    if (s == AppLifecycleState.resumed) {
      final away = _away;
      _away = null;
      _set(locked || (away != null && now().difference(away) >= timeout), false);
    } else if (s != AppLifecycleState.detached) {
      _away ??= now();
      _set(locked, true);
    }
  }

  /// After a successful check.
  void unlock() => _set(false, covered);

  /// The lock was turned off (Settings, or signing out from the lock screen).
  void release() {
    _away = null;
    _set(false, false);
  }

  void _set(bool l, bool c) {
    if (l == locked && c == covered) return;
    locked = l;
    covered = c;
    notifyListeners();
  }
}

final lockStateProvider = ChangeNotifierProvider<AppLockState>((ref) {
  final s = AppLockState(enabled: () => ref.read(appLockProvider));
  ref.listen(appLockProvider, (_, on) {
    if (!on) s.release();
  });
  return s;
});

/// Above the navigator (MaterialApp.builder): the app, with the lock screen or the cover on top when needed.
class LockGate extends ConsumerStatefulWidget {
  final Widget child;
  const LockGate({super.key, required this.child});
  @override
  ConsumerState<LockGate> createState() => _LockGateState();
}

class _LockGateState extends ConsumerState<LockGate> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => ref.read(lockStateProvider).lifecycle(state);

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(lockStateProvider);
    return Stack(children: [
      // Behind the lock or the cover: nothing for a screen reader; behind the lock, no keyboard focus either.
      ExcludeSemantics(
        excluding: s.locked || s.covered,
        child: ExcludeFocus(excluding: s.locked, child: widget.child),
      ),
      if (s.locked)
        const Positioned.fill(child: LockScreen())
      else if (s.covered)
        Positioned.fill(child: ColoredBox(color: Theme.of(context).colorScheme.surface, child: const _Brand())),
    ]);
  }
}

class _Brand extends StatelessWidget {
  const _Brand();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.savings_outlined, size: 64, color: cs.primary),
        const SizedBox(height: 12),
        Text('Evensies',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: cs.primary, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

/// **Unlock** (asks once by itself when it appears) and **Sign out**, the way out for a forgotten passcode: it signs
/// out, removes this device's data and turns the lock off.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});
  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  bool _asking = false, _confirmSignOut = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  Future<void> _unlock() async {
    if (_asking || !mounted) return;
    setState(() => _asking = true);
    final ok = await ref.read(authenticatorProvider).authenticate(context.l.lockReason);
    if (!mounted) return;
    setState(() => _asking = false);
    if (ok) ref.read(lockStateProvider).unlock();
  }

  Future<void> _signOut() async {
    await ref.read(authServiceProvider).logout();
    await ref.read(appLockProvider.notifier).disable();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    String k(String text) => keepAll(text, l.localeName);
    final cs = Theme.of(context).colorScheme;
    // Not a Scaffold: the app's ScaffoldMessenger would show snackbars and push banners (their text) on it.
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const Spacer(),
            Icon(Icons.lock_outline, size: 56, color: cs.primary),
            const SizedBox(height: 16),
            Text(k(l.lockTitle), style: Theme.of(context).textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(k(l.lockSubtitle), style: TextStyle(color: cs.onSurfaceVariant), textAlign: TextAlign.center),
            const Spacer(),
            if (_confirmSignOut) ...[
              Text(k(l.lockSignOutConfirm), textAlign: TextAlign.center),
              const SizedBox(height: 4),
              // As Settings → Sign out: offline changes not sent yet go with the device's data.
              Text(k(l.signOutMessage), textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                      onPressed: () => setState(() => _confirmSignOut = false), child: Text(l.cancel)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: cs.error, foregroundColor: cs.onError),
                    onPressed: _signOut,
                    child: Text(l.signOut),
                  ),
                ),
              ]),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const Key('lock-unlock'),
                  onPressed: _asking ? null : _unlock,
                  icon: const Icon(Icons.lock_open), // Face ID, Touch ID, a fingerprint or the passcode
                  label: Text(l.lockUnlock),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                key: const Key('lock-sign-out'),
                onPressed: () => setState(() => _confirmSignOut = true),
                child: Text(l.signOut),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}
