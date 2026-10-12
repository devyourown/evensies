import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n.dart';
import 'auth_service.dart';
import 'email_code_form.dart';

/// Sign in with an emailed code (route `/login/email`, docs/API.md 이메일 로그인). Success stores the session, and the
/// router moves on (the name screen for a new account).
class EmailLoginScreen extends ConsumerWidget {
  const EmailLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.read(authServiceProvider);
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l = context.l;
    return Scaffold(
      appBar: AppBar(title: Text(l.emailLoginTitle)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Icon(Icons.mark_email_unread_outlined, size: 56, color: cs.primary),
                const SizedBox(height: 16),
                Text(keepAll(l.emailLoginIntro, l.localeName),
                    textAlign: TextAlign.center, style: text.bodyLarge?.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 24),
                EmailCodeForm(onSend: auth.emailStart, onVerify: auth.emailVerify),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
