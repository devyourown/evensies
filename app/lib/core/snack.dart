import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:share_plus/share_plus.dart';

import '../data/api/dto.dart';
import '../data/local_writes.dart' show LeaveException, MoveException;
import '../domain/fx.dart';
import '../domain/split.dart';
import 'l10n.dart';

/// [e] as the user reads it: a String as given (already worded), an error code by its message; never a server
/// `message` or a raw error (docs/API.md 9단계).
void showError(BuildContext context, Object e) => showInfo(context, errorText(context.l, e));

void showInfo(BuildContext context, String msg) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(keepAll(msg, context.l.localeName))));

/// [msg] with Undo for 10 s (after a delete). Take [messenger] before leaving the screen, so it outlives it.
void showUndo(ScaffoldMessengerState messenger, String msg, VoidCallback undo) => messenger.showSnackBar(SnackBar(
      content: Text(keepAll(msg, messenger.context.l.localeName)),
      duration: const Duration(seconds: 10),
      persist: false, // actions persist by default; Undo is only offered for 10 s
      action: SnackBarAction(label: messenger.context.l.undo, onPressed: undo),
    ));

/// The share sheet on phones; the browser copies [text] to the clipboard and says so (docs/API.md 웹 앱).
Future<void> shareText(BuildContext context, String text) async {
  if (!kIsWeb) {
    await SharePlus.instance.share(ShareParams(text: text));
    return;
  }
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) showInfo(context, context.l.copiedToClipboard);
}

String errorText(AppLocalizations l, Object e) => switch (e) {
      String() => e,
      MoveException(:final message) || LeaveException(:final message) => message,
      ApiException(:final code) || SplitException(:final code) || FxException(:final code) => errorForCode(l, code),
      _ => l.errorUnexpected,
    };

/// A server or domain error code's sentence; an unknown code names itself (`errorGeneric`).
String errorForCode(AppLocalizations l, String code) => switch (code) {
      'NETWORK' => l.errorNetwork,
      'RATE_LIMITED' => l.errorRateLimited,
      'NOT_FOUND' => l.errorNotFound,
      'FORBIDDEN' => l.errorForbidden,
      'VALIDATION' => l.errorValidation,
      'SUM_MISMATCH' => l.errorSumMismatch,
      'PAYERS_SUM_MISMATCH' => l.errorPayersSumMismatch,
      'NEGATIVE_AMOUNT' => l.errorNegativeAmount,
      'NEGATIVE_SHARE' => l.errorNegativeShare,
      'NEGATIVE_TOTAL' => l.errorNegativeTotal,
      'ZERO_SUBTOTAL' => l.errorZeroSubtotal,
      'UNASSIGNED_ITEM' => l.errorUnassignedItem,
      'NO_MEMBERS' => l.errorNoMembers,
      'INVALID_INPUT' => l.errorInvalidInput,
      'BAD_RATE' => l.errorBadRate,
      'UNKNOWN_MEMBER' => l.errorUnknownMember,
      'UNKNOWN_CURRENCY' => l.errorUnknownCurrency,
      'MEMBER_TAKEN' => l.errorMemberTaken,
      'LIMIT_EXCEEDED' => l.errorLimitExceeded,
      'TOO_LARGE' || 'IMAGE_TOO_LARGE' => l.errorTooLarge,
      'NOT_JPEG' => l.errorNotJpeg,
      'FX_UNAVAILABLE' => l.errorFxUnavailable,
      'IMPORT_FAILED' => l.errorImportFailed,
      'AUTH_NOT_CONFIGURED' => l.errorAuthNotConfigured,
      'DUPLICATE' => l.errorDuplicate,
      _ => l.errorGeneric(code),
    };
