import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

/// `https://host/j/CODE` or `tally://j/CODE` → CODE. Also accepts a bare code.
String? inviteCodeFrom(String text) {
  final t = text.trim();
  if (t.isEmpty) return null;
  final m = RegExp(r'/j/([A-Za-z0-9_-]+)').firstMatch(t);
  if (m != null) return m.group(1);
  return RegExp(r'^[A-Za-z0-9_-]{4,}$').hasMatch(t) ? t : null;
}

Future<void> showPasteInviteDialog(BuildContext context) async {
  final clip = (await Clipboard.getData('text/plain'))?.text ?? '';
  if (!context.mounted) return;
  final ctl = TextEditingController(text: inviteCodeFrom(clip) != null ? clip : '');
  await showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Invite link'),
      content: TextField(controller: ctl, autofocus: true, decoration: const InputDecoration(hintText: 'https://…/j/CODE')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            final code = inviteCodeFrom(ctl.text);
            if (code == null) return;
            Navigator.pop(ctx);
            context.push('/join/$code');
          },
          child: const Text('Open'),
        ),
      ],
    ),
  );
}
