import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/l10n.dart';
import '../../core/snack.dart';

/// An address as the server stores it: trimmed and lower-cased (docs/API.md 이메일 검증).
String normalizeEmail(String s) => s.trim().toLowerCase();

final _emailShape = RegExp(r'^[^\s@]{1,64}@[a-z0-9-]+(\.[a-z0-9-]+)+$');

/// The server's check (no SMTPUTF8): at most 254 characters, `local@domain.tld` with an ASCII domain.
bool emailValid(String s) {
  final e = normalizeEmail(s);
  return e.length <= 254 && _emailShape.hasMatch(e);
}

/// Email, then a 6-digit code (docs/API.md 이메일 로그인), for signing in and for Settings → Email: [onSend] emails
/// a code to the address, [onVerify] checks it. Both throw what the server answered; the form words it. Resend unlocks
/// 30 s after each code; "Use a different email" goes back to the first step.
class EmailCodeForm extends StatefulWidget {
  final Future<void> Function(String email) onSend;
  final Future<void> Function(String email, String code) onVerify;
  final String? initialEmail;
  const EmailCodeForm({super.key, required this.onSend, required this.onVerify, this.initialEmail});
  @override
  State<EmailCodeForm> createState() => _EmailCodeFormState();
}

class _EmailCodeFormState extends State<EmailCodeForm> {
  static const resendAfter = 30; // seconds
  late final _email = TextEditingController(text: widget.initialEmail ?? '');
  final _code = TextEditingController();
  String? _sentTo;
  int _wait = 0; // seconds until Resend unlocks
  Timer? _tick;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _tick?.cancel();
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() f) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await f();
    } catch (e) {
      if (mounted) setState(() => _error = errorText(context.l, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send({bool again = false}) => _run(() async {
        final email = normalizeEmail(_email.text);
        await widget.onSend(email);
        if (!mounted) return;
        _code.clear();
        _tick?.cancel();
        _tick = Timer.periodic(const Duration(seconds: 1), (t) {
          if (!mounted) return t.cancel();
          setState(() => _wait--);
          if (_wait <= 0) t.cancel();
        });
        setState(() {
          _sentTo = email;
          _wait = resendAfter;
        });
        if (again) showInfo(context, context.l.codeResent);
      });

  Future<void> _verify() => _run(() => widget.onVerify(_sentTo!, _code.text));

  void _back() {
    _tick?.cancel();
    setState(() {
      _sentTo = null;
      _wait = 0;
      _error = null;
      _code.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final sentTo = _sentTo;
    final error = _error == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(keepAll(_error!, l.localeName), key: const Key('email-error'), style: TextStyle(color: cs.error)),
          );
    final progress = SizedBox(height: 4, child: _busy ? const LinearProgressIndicator() : null);
    if (sentTo == null) {
      final ok = emailValid(_email.text) && !_busy;
      return AutofillGroup(
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(
            key: const Key('email-field'),
            controller: _email,
            autofocus: true,
            keyboardType: TextInputType.emailAddress,
            autocorrect: false,
            textInputAction: TextInputAction.send,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(
              labelText: l.emailLabel,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.mail_outline),
              errorText: _email.text.trim().isNotEmpty && !emailValid(_email.text) ? l.emailInvalid : null,
            ),
            onChanged: (_) => setState(() => _error = null),
            onSubmitted: (_) => ok ? _send() : null,
          ),
          ?error,
          const SizedBox(height: 16),
          FilledButton(key: const Key('send-code'), onPressed: ok ? _send : null, child: Text(l.sendCode)),
          const SizedBox(height: 12),
          progress,
        ]),
      );
    }
    final wait = _wait;
    final ok = _code.text.length == 6 && !_busy;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(keepAll(l.codeSentTo(sentTo), l.localeName), style: text.bodyLarge),
      const SizedBox(height: 16),
      TextField(
        key: const Key('code-field'),
        controller: _code,
        autofocus: true,
        keyboardType: TextInputType.number,
        autofillHints: const [AutofillHints.oneTimeCode],
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
        textAlign: TextAlign.center,
        style: text.headlineSmall?.copyWith(letterSpacing: 8, fontFeatures: const [FontFeature.tabularFigures()]),
        decoration: InputDecoration(labelText: l.codeLabel, border: const OutlineInputBorder(), counterText: ''),
        onChanged: (v) {
          setState(() => _error = null);
          if (v.length == 6 && !_busy) _verify(); // the sixth digit submits, like the system's code autofill
        },
        onSubmitted: (_) => ok ? _verify() : null,
      ),
      ?error,
      const SizedBox(height: 8),
      Text(l.codeCheckSpam, style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
      const SizedBox(height: 16),
      FilledButton(key: const Key('verify-code'), onPressed: ok ? _verify : null, child: Text(l.verifyCode)),
      const SizedBox(height: 8),
      Wrap(alignment: WrapAlignment.spaceBetween, children: [
        TextButton(
          key: const Key('resend-code'),
          onPressed: wait > 0 || _busy ? null : () => _send(again: true),
          child: Text(wait > 0 ? l.resendCodeIn(wait) : l.resendCode),
        ),
        TextButton(key: const Key('other-email'), onPressed: _busy ? null : _back, child: Text(l.useDifferentEmail)),
      ]),
      const SizedBox(height: 8),
      progress,
    ]);
  }
}
