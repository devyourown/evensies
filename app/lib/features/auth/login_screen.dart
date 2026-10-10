import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/env.dart';
import '../../core/snack.dart';
import 'auth_service.dart';

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
                  Text('Tally',
                      style: text.displayMedium?.copyWith(fontWeight: FontWeight.w700, color: cs.primary),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text('Split expenses with friends. No ads, no upsells.',
                      style: text.bodyLarge?.copyWith(color: cs.onSurfaceVariant), textAlign: TextAlign.center),
                  const SizedBox(height: 48),
                  if (AuthService.appleAvailable) ...[
                    FilledButton.icon(
                      onPressed: _busy ? null : () => _run(auth.apple),
                      icon: const Icon(Icons.apple),
                      label: const Text('Continue with Apple'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  OutlinedButton.icon(
                    onPressed: _busy ? null : () => _run(auth.google),
                    icon: const Icon(Icons.g_mobiledata, size: 28),
                    label: const Text('Continue with Google'),
                  ),
                  if (Env.devLogin) ...[
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
