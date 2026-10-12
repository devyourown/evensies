import 'package:flutter/material.dart';

void showError(BuildContext context, Object e) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));

void showInfo(BuildContext context, String msg) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

/// [msg] with Undo for 10 s (after a delete). Take [messenger] before leaving the screen, so it outlives it.
void showUndo(ScaffoldMessengerState messenger, String msg, VoidCallback undo) => messenger.showSnackBar(SnackBar(
      content: Text(msg),
      duration: const Duration(seconds: 10),
      persist: false, // actions persist by default; Undo is only offered for 10 s
      action: SnackBarAction(label: 'Undo', onPressed: undo),
    ));
