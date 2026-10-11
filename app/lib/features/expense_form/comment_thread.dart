import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/confirm.dart';
import '../../core/person_avatar.dart';
import '../../core/snack.dart';
import '../../data/db/database.dart';
import '../../providers.dart';

/// Comments under an expense or (Phase 6) a payment (docs/API.md `comment.*`): pass exactly one of [expenseId] and
/// [paymentId]. Local first like every write; deleted ones are hidden.
class CommentThread extends ConsumerStatefulWidget {
  final String groupId;
  final String? expenseId;
  final String? paymentId;
  const CommentThread({super.key, required this.groupId, this.expenseId, this.paymentId})
      : assert((expenseId == null) != (paymentId == null));
  @override
  ConsumerState<CommentThread> createState() => _CommentThreadState();
}

class _CommentThreadState extends ConsumerState<CommentThread> {
  static const _maxLength = 1000; // UTF-16 units, like the server
  final _ctl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _sending = true);
    try {
      await ref
          .read(localWritesProvider)
          .addComment(widget.groupId, _ctl.text.trim(), expenseId: widget.expenseId, paymentId: widget.paymentId);
      _ctl.clear();
    } catch (e) {
      if (mounted) showError(context, e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _delete(CommentRow c) async {
    if (!await confirm(context, title: 'Delete comment?')) return;
    await ref.read(localWritesProvider).deleteComment(widget.groupId, c.id);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final me = ref.watch(groupProvider(widget.groupId)).value?.myMemberId;
    final members = ref.watch(membersProvider(widget.groupId)).value ?? const <MemberRow>[];
    final names = {for (final m in members) m.id: m.name};
    final users = {for (final m in members) m.id: m.userId};
    DateTime at(CommentRow c) => DateTime.tryParse(c.createdAt)?.toLocal() ?? DateTime(0);
    final comments = (ref.watch(commentsProvider(widget.groupId)).value ?? const <CommentRow>[])
        .where((c) =>
            (widget.expenseId != null ? c.expenseId == widget.expenseId : c.paymentId == widget.paymentId) && !c.deleted)
        .toList()
      ..sort((a, b) => at(a).compareTo(at(b)));
    final draft = _ctl.text.trim();
    final canSend = me != null && !_sending && draft.isNotEmpty && draft.length <= _maxLength;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Comments', style: text.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
      const SizedBox(height: 8),
      if (comments.isEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text('No comments yet.', style: text.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        ),
      for (final c in comments)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            PersonAvatar(userId: users[c.authorMemberId], name: names[c.authorMemberId] ?? '?', radius: 16),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text.rich(TextSpan(children: [
                  TextSpan(
                    text: c.authorMemberId == me ? 'You' : names[c.authorMemberId] ?? 'Someone',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: '  ${DateFormat.MMMd().add_jm().format(at(c))}',
                    style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ])),
                const SizedBox(height: 2),
                Text(c.body),
              ]),
            ),
            if (c.authorMemberId == me)
              IconButton(
                tooltip: 'Delete comment',
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.close, size: 18, color: cs.onSurfaceVariant),
                onPressed: () => _delete(c),
              ),
          ]),
        ),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child: TextField(
            key: const Key('comment-input'),
            controller: _ctl,
            minLines: 1,
            maxLines: 4,
            // No maxLength: Flutter counts characters as seen (an emoji is 1), the limit counts UTF-16 units.
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Add a comment',
              isDense: true,
              border: const OutlineInputBorder(),
              counterText: draft.length > _maxLength - 100 ? '${draft.length}/$_maxLength' : null,
              errorText: draft.length > _maxLength ? 'Too long' : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          tooltip: 'Send',
          onPressed: canSend ? _send : null,
          icon: _sending
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.send),
        ),
      ]),
    ]);
  }
}
