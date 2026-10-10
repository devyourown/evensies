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
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Tally', style: Theme.of(context).textTheme.displayMedium, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                const Text('Split expenses with friends', textAlign: TextAlign.center),
                const SizedBox(height: 32),
                if (AuthService.appleAvailable)
                  FilledButton.icon(
                    onPressed: _busy ? null : () => _run(auth.apple),
                    icon: const Icon(Icons.apple),
                    label: const Text('Sign in with Apple'),
                  ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () => _run(auth.google),
                  icon: const Icon(Icons.g_mobiledata),
                  label: const Text('Sign in with Google'),
                ),
                if (Env.devLogin) ...[
                  const Divider(height: 48),
                  TextField(
                    controller: _devName,
                    decoration: const InputDecoration(labelText: 'Dev name', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _busy ? null : () => _run(() => auth.dev(_devName.text.trim().isEmpty ? 'Dev' : _devName.text.trim())),
                    child: const Text('Dev login'),
                  ),
                ],
                if (_busy) const Padding(padding: EdgeInsets.only(top: 16), child: LinearProgressIndicator()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
