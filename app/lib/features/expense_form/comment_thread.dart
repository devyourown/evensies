import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/confirm.dart';
import '../../core/l10n.dart';
import '../../core/person_avatar.dart';
import '../../core/snack.dart';
import '../../data/db/database.dart';
import '../../domain/activity.dart';
import '../../providers.dart';
import '../activity/activity_screen.dart' show ActivityTile, dayLabel, foldReceipts;

/// Comments under an expense or (Phase 6) a payment (docs/API.md `comment.*`): pass exactly one of [expenseId] and
/// [paymentId]. Local first like every write; deleted ones are hidden. Like Splitwise, one chronological thread: chat
/// bubbles (mine on the right), and with [history] (an expense's own feed items, newest first) a line for each change
/// between them. A comment's own feed item isn't repeated: its bubble is the line.
class CommentThread extends ConsumerStatefulWidget {
  final String groupId;
  final String? expenseId;
  final String? paymentId;

  /// The expense's History items, newest first (from the server or the offline cache).
  final List<ActivityItem> history;

  /// The label above the thread; [header] goes under it (e.g. "Show earlier").
  final String? title;
  final Widget? header;
  const CommentThread({
    super.key,
    required this.groupId,
    this.expenseId,
    this.paymentId,
    this.history = const [],
    this.title,
    this.header,
  }) : assert((expenseId == null) != (paymentId == null));
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
    if (!await confirm(context, title: context.l.deleteCommentTitle)) return;
    await ref.read(localWritesProvider).deleteComment(widget.groupId, c.id);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final l = context.l;
    final me = ref.watch(groupProvider(widget.groupId)).value?.myMemberId;
    final members = ref.watch(membersProvider(widget.groupId)).value ?? const <MemberRow>[];
    final names = {for (final m in members) m.id: m.name};
    final users = {for (final m in members) m.id: m.userId};
    DateTime at(String? iso) => DateTime.tryParse(iso ?? '')?.toLocal() ?? DateTime(0);
    final comments = (ref.watch(commentsProvider(widget.groupId)).value ?? const <CommentRow>[])
        .where((c) =>
            (widget.expenseId != null ? c.expenseId == widget.expenseId : c.paymentId == widget.paymentId) && !c.deleted)
        .toList();
    // One clock for both kinds of row: the server's (a feed item's createdAt is when the server stored the event, in
    // seq order; docs/API.md, Feed). A comment uses its comment_added item when the history has it; one that has
    // none yet (unsent, or older than the loaded pages) falls back to its own time. Oldest first, same time by seq.
    final posted = {
      for (final i in widget.history)
        if (i.kind == 'comment_added' && i.commentId != null) i.commentId!: i,
    };
    final entries = <({DateTime at, String? iso, int seq, Widget row})>[
      for (final (item: i, :count) in foldReceipts(widget.history))
        if (i.kind != 'comment_added')
          (
            at: at(i.createdAt),
            iso: i.createdAt,
            seq: i.seq,
            row: ActivityTile(
                key: ValueKey('h${i.seq}'), item: i, count: count, groupId: widget.groupId, embedded: true),
          ),
      for (final c in comments)
        (
          at: at(posted[c.id]?.createdAt ?? c.createdAt),
          iso: posted[c.id]?.createdAt ?? c.createdAt,
          seq: posted[c.id]?.seq ?? 1 << 52, // not on the server yet: after what is
          row: _Bubble(
            key: ValueKey('c${c.id}'),
            text: c.body,
            name: c.authorMemberId == me ? l.you : names[c.authorMemberId] ?? l.someone,
            userId: users[c.authorMemberId],
            avatarName: names[c.authorMemberId] ?? '?',
            time: at(posted[c.id]?.createdAt ?? c.createdAt),
            // Under a day header, the time alone, like the change rows.
            withDate: widget.history.isEmpty,
            mine: c.authorMemberId == me,
            onDelete: c.authorMemberId == me ? () => _delete(c) : null,
          ),
        ),
    ]..sort((a, b) => a.at != b.at ? a.at.compareTo(b.at) : a.seq.compareTo(b.seq));
    final draft = _ctl.text.trim();
    final canSend = me != null && !_sending && draft.isNotEmpty && draft.length <= _maxLength;

    final rows = <Widget>[];
    String? lastDay;
    for (final e in entries) {
      final day = dayLabel(e.iso, l: l);
      if (widget.history.isNotEmpty && day != lastDay) {
        lastDay = day;
        rows.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Center(child: Text(day, style: text.labelSmall?.copyWith(color: cs.onSurfaceVariant))),
        ));
      }
      rows.add(e.row);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(widget.title ?? l.comments, style: text.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
      ?widget.header,
      const SizedBox(height: 8),
      if (comments.isEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(l.noCommentsYet, style: text.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
        ),
      ...rows,
      const SizedBox(height: 8),
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
              hintText: l.addComment,
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
              counterText: draft.length > _maxLength - 100 ? '${draft.length}/$_maxLength' : null,
              errorText: draft.length > _maxLength ? l.tooLong : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          tooltip: l.send,
          onPressed: canSend ? _send : null,
          icon: _sending
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.send),
        ),
      ]),
    ]);
  }
}

/// One comment: a bubble on the right in my colour, or on the left with the author's photo; name and time above.
class _Bubble extends StatelessWidget {
  final String text, name, avatarName;
  final String? userId;
  final DateTime time;

  /// "Oct 12 8:12 PM" without day headers (a payment's comments), else "8:12 PM".
  final bool withDate;
  final bool mine;
  final VoidCallback? onDelete;
  const _Bubble({
    super.key,
    required this.text,
    required this.name,
    required this.userId,
    required this.avatarName,
    required this.time,
    required this.withDate,
    required this.mine,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final l = context.l;
    final bubble = Flexible(
      child: Column(crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
        Text.rich(
          TextSpan(children: [
            TextSpan(text: name, style: const TextStyle(fontWeight: FontWeight.w600)),
            TextSpan(
                text: '  ${(withDate ? DateFormat.MMMd().add_jm() : DateFormat.jm()).format(time)}',
                style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
          ]),
          style: textTheme.bodySmall,
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: mine ? cs.primaryContainer : cs.surfaceContainerHighest,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(mine ? 16 : 4),
              bottomRight: Radius.circular(mine ? 4 : 16),
            ),
          ),
          child: Text(text, style: TextStyle(color: mine ? cs.onPrimaryContainer : cs.onSurface)),
        ),
      ]),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!mine) ...[PersonAvatar(userId: userId, name: avatarName, radius: 16), const SizedBox(width: 8)],
          if (mine) const SizedBox(width: 48),
          if (onDelete != null)
            IconButton(
              tooltip: l.deleteComment,
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.close, size: 16, color: cs.onSurfaceVariant),
              onPressed: onDelete,
            ),
          bubble,
          if (!mine) const SizedBox(width: 48),
        ],
      ),
    );
  }
}
