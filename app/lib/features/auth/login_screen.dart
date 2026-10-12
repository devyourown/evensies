import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

import '../../core/env.dart';
import '../../core/l10n.dart';
import '../../core/snack.dart';
import 'auth_service.dart';
import 'sign_in_web_stub.dart' if (dart.library.js_interop) 'sign_in_web.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _busy = false;
  final _devName = TextEditingController();

  Future<void> _run(Future<void> Function() f) async {
    setState(() => _busy = true);
    try {
      await f();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.read(authServiceProvider);
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l = context.l;
    // The server says which sign-ins it has (GET /info); offline, phones show the ones built in.
    final info = ref.watch(serverInfoProvider);
    final web = info.valueOrNull;
    final server = ref.watch(infoProvider);
    if (kIsWeb && web?.googleWebClientId != null) {
      loadGoogleSignIn();
      auth.initGoogleWeb(web!.googleWebClientId!, (e) {
        if (mounted) showError(context, e);
      });
    }
    final apple = AuthService.appleAvailable && server.appleLogin && (!kIsWeb || web?.appleServicesId != null);
    // Apple's script ahead of the tap (a popup must open right away); no-op on phones.
    if (kIsWeb && apple) loadAppleSignIn().ignore();
    final google = server.googleLogin && (!kIsWeb || web?.googleWebClientId != null);
    final email = server.emailLogin;
    final dev = Env.devLogin || (web?.devLogin ?? false);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.savings_outlined, size: 72, color: cs.primary),
                  const SizedBox(height: 16),
                  Text('Evensies',
                      style: text.displayMedium?.copyWith(fontWeight: FontWeight.w700, color: cs.primary),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(l.loginTagline,
                      style: text.bodyLarge?.copyWith(color: cs.onSurfaceVariant), textAlign: TextAlign.center),
                  const SizedBox(height: 48),
                  if (kIsWeb && info.isLoading) const Center(child: CircularProgressIndicator()),
                  if (apple) ...[
                    FilledButton.icon(
                      onPressed: _busy
                          ? null
                          : () => _run(() async {
                                await loadAppleSignIn();
                                await auth.apple(servicesId: web?.appleServicesId);
                              }),
                      icon: const Icon(Icons.apple),
                      label: Text(l.loginApple),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (google && kIsWeb)
                    Center(child: googleWebButton(ref.watch(languageProvider)))
                  else if (google)
                    OutlinedButton.icon(
                      onPressed: _busy ? null : () => _run(auth.google),
                      icon: const Icon(Icons.g_mobiledata, size: 28),
                      label: Text(l.loginGoogle),
                    ),
                  if (email) ...[
                    if (apple || google) const SizedBox(height: 12),
                    OutlinedButton.icon(
                      key: const Key('login-email'),
                      onPressed: _busy
                          ? null
                          : () {
                              // Keeps where the sign-in goes next (a join link).
                              final next = GoRouterState.of(context).uri.queryParameters['next'];
                              context.push(Uri(path: '/login/email', queryParameters: next == null ? null : {'next': next})
                                  .toString());
                            },
                      icon: const Icon(Icons.mail_outline),
                      label: Text(l.loginEmail),
                    ),
                  ],
                  if (kIsWeb && !info.isLoading && !apple && !google && !dev && !email)
                    Text(l.loginWebUnavailable, textAlign: TextAlign.center, style: TextStyle(color: cs.onSurfaceVariant)),
                  if (dev) ...[
                    const SizedBox(height: 32),
                    Row(children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('DEV', style: text.labelSmall?.copyWith(color: cs.onSurfaceVariant)),
                      ),
                      const Expanded(child: Divider()),
                    ]),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _devName,
                      decoration: const InputDecoration(labelText: 'Dev name', border: OutlineInputBorder(), isDense: true),
                      onSubmitted: (_) => _devLogin(auth),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: _busy ? null : () => _devLogin(auth),
                      child: const Text('Dev login'),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 4,
                    child: _busy ? const LinearProgressIndicator() : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _devLogin(AuthService auth) {
    final n = _devName.text.trim();
    _run(() => auth.dev(n.isEmpty ? 'Dev' : n));
  }
}
