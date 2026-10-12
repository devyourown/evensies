import 'package:flutter/material.dart';

import 'l10n.dart';

/// Yes/no dialog for destructive actions. Resolves true only on the confirm button.
Future<bool> confirm(
  BuildContext context, {
  required String title,
  String? message,
  String? confirmLabel,
  bool destructive = true,
}) async {
  final cs = Theme.of(context).colorScheme;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(keepAll(title, context.l.localeName)),
      content: message == null ? null : Text(keepAll(message, context.l.localeName)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.l.cancel)),
        FilledButton(
          style: destructive ? FilledButton.styleFrom(backgroundColor: cs.error, foregroundColor: cs.onError) : null,
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel ?? context.l.delete),
        ),
      ],
    ),
  );
  return ok ?? false;
}
