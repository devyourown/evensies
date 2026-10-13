import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/confirm.dart';
import '../../core/l10n.dart';
import '../../core/snack.dart';
import '../../data/api/dto.dart';
import '../../providers.dart';
import '../auth/email_code_form.dart';

/// Settings → Email (route `/settings/email`, docs/API.md, Account email): add or change the account address with a code
/// sent to it, or remove it. Other members never see it. Online only.
class AccountEmailScreen extends ConsumerStatefulWidget {
  const AccountEmailScreen({super.key});
  @override
  ConsumerState<AccountEmailScreen> createState() => _AccountEmailScreenState();
}

class _AccountEmailScreenState extends ConsumerState<AccountEmailScreen> {
  bool _removing = false;

  Future<void> _verify(String email, String code) async {
    final user = await ref.read(apiProvider).verifyEmail(email, code);
    await ref.read(dbProvider).updateEmail(user.id, user.email, bounced: user.emailBounced);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final l = context.l;
    context.pop();
    messenger.showSnackBar(SnackBar(content: Text(l.emailSaved)));
  }

  Future<void> _remove(String userId, String email) async {
    final l = context.l;
    if (!await confirm(context, title: l.removeEmailTitle(email), message: l.removeEmailMessage, confirmLabel: l.remove)) {
      return;
    }
    setState(() => _removing = true);
    try {
      await ref.read(apiProvider).removeEmail();
      await ref.read(dbProvider).updateEmail(userId, null);
      if (mounted) showInfo(context, context.l.emailRemoved);
    } catch (e) {
      if (mounted) showError(context, e is ApiException && e.code == 'NETWORK' ? context.l.emailNeedsConnection : e);
    } finally {
      if (mounted) setState(() => _removing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider).value;
    final email = session?.email;
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l = context.l;
    return Scaffold(
      appBar: AppBar(title: Text(l.emailLabel)),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
        if (email != null) ...[
          Card(
            key: const Key('current-email'),
            color: session?.emailBounced == true ? cs.errorContainer : cs.surfaceContainerHigh,
            child: ListTile(
              leading: Icon(session?.emailBounced == true ? Icons.warning_amber_rounded : Icons.verified_outlined,
                  color: session?.emailBounced == true ? cs.onErrorContainer : cs.primary),
              title: Text(email, style: TextStyle(color: session?.emailBounced == true ? cs.onErrorContainer : null)),
              subtitle: Text(keepAll(session?.emailBounced == true ? l.emailBouncedNote : l.emailVerifiedNote, l.localeName),
                  style: TextStyle(color: session?.emailBounced == true ? cs.onErrorContainer : cs.onSurfaceVariant)),
            ),
          ),
          const SizedBox(height: 24),
          Text(l.changeEmail, style: text.titleMedium),
          const SizedBox(height: 4),
        ],
        Text(keepAll(l.emailAccountHelp, l.localeName), style: text.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        const SizedBox(height: 16),
        EmailCodeForm(
          // Bounced: the same address can be verified again.
          initialEmail: session?.emailBounced == true ? email : null,
          onSend: ref.read(apiProvider).addEmail,
          onVerify: _verify,
        ),
        if (email != null && session != null) ...[
          const SizedBox(height: 32),
          const Divider(),
          ListTile(
            key: const Key('remove-email'),
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.delete_outline, color: cs.error),
            title: Text(l.removeEmail, style: TextStyle(color: cs.error)),
            enabled: !_removing,
            trailing: _removing
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : null,
            onTap: () => _remove(session.userId, email),
          ),
        ],
      ]),
    );
  }
}
