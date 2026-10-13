import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

import '../../core/env.dart';
import '../../core/l10n.dart';
import '../../core/snack.dart';
import '../../data/api/dto.dart' show ApiException;
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
    final review = server.reviewLogin;
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
                  if (review) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      key: const Key('login-review'),
                      onPressed: _busy
                          ? null
                          : () => showDialog<void>(context: context, builder: (_) => const _ReviewSignIn()),
                      child: Text(l.loginReview),
                    ),
                  ],
                  if (kIsWeb && !info.isLoading && !apple && !google && !dev && !email && !review)
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

/// The store reviewers' sign-in (docs/API.md POST /auth/review) with the username and password from the store consoles.
/// No autofill hints, so the password manager doesn't offer to save it. On success the router goes on like after
/// Apple or Google (the name screen, or home).
class _ReviewSignIn extends ConsumerStatefulWidget {
  const _ReviewSignIn();
  @override
  ConsumerState<_ReviewSignIn> createState() => _ReviewSignInState();
}

class _ReviewSignInState extends ConsumerState<_ReviewSignIn> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  bool get _ready => !_busy && _username.text.trim().isNotEmpty && _password.text.isNotEmpty;

  Future<void> _submit() async {
    if (!_ready) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authServiceProvider).review(_username.text.trim(), _password.text);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      // One message for either part (the server doesn't say which); 429 and offline as everywhere. 404: the server
      // turned it off since /info was read, so read /info again (the button goes) and say only that it failed.
      if (!mounted) return;
      final l = context.l;
      final status = e is ApiException ? e.status : null;
      if (status == 404) ref.invalidate(serverInfoProvider);
      setState(() => _error = switch (status) { 401 => l.loginReviewWrong, 404 => l.errorUnexpected, _ => errorText(l, e) });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return AlertDialog(
      title: Text(l.loginReview),
      // A fixed width: AlertDialog would otherwise grow with the typed text on wide screens.
      content: SizedBox(width: 320, child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
          key: const Key('review-username'),
          controller: _username,
          autofocus: true,
          autofillHints: null,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(labelText: l.loginReviewUsername),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _submit(), // Enter: the password field next, or sign in when both are typed
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('review-password'),
          controller: _password,
          obscureText: true,
          autofillHints: null,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
              labelText: l.loginReviewPassword,
              errorText: _error == null ? null : keepAll(_error!, l.localeName),
              errorMaxLines: 3),
          onChanged: (_) => setState(() {}),
          onEditingComplete: () {}, // keep the focus, so Enter works again after a wrong password
          onSubmitted: (_) => _submit(),
        ),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l.cancel)),
        FilledButton(key: const Key('review-submit'), onPressed: _ready ? _submit : null, child: Text(l.loginReviewSubmit)),
      ],
    );
  }
}
