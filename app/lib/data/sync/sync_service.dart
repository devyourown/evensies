import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../domain/models.dart';
import '../api/api_client.dart';
import '../api/dto.dart';
import '../db/database.dart';
import '../receipts.dart';
import 'apply_event.dart';
import 'event_types.dart';
import 'group_state_store.dart';

/// upload pending receipts → push unsent outbox → pull after lastSeq → fold through applyEvent → save.
class SyncService {
  final AppDatabase db;
  final ApiClient api;
  final GroupStateStore store;
  final ReceiptFiles receipts;
  SyncService({required this.db, required this.api, ReceiptFiles? receipts})
      : store = GroupStateStore(db),
        receipts = receipts ?? ReceiptFiles(api);

  /// True after the last sync attempt failed (network or server). Shown as a chip in the UI.
  final offline = ValueNotifier<bool>(false);
  final _inFlight = <String, Future<void>>{};

  /// "Couldn't save the new expense “Hotel”: …" for each event the server refused on its own (docs/API.md 거부된 이벤트).
  Stream<String> get rejections => _rejections.stream;
  final _rejections = StreamController<String>.broadcast();

  static GroupState _apply(GroupState s, SyncEvent e) => applyEvent(s, e);

  /// A second call while one runs for the same group waits for that one.
  Future<void> sync(String groupId) => _inFlight[groupId] ??= _sync(groupId).whenComplete(() {
        _inFlight.remove(groupId); // a block: returning the removed future would make it wait for itself
      });

  Future<void> _sync(String groupId) async {
    try {
      try {
        await _upload(groupId);
        await _push(groupId);
      } on ApiException {
        await _settleRejected(groupId); // what was refused before the pass stopped
        rethrow;
      }
      await _settleRejected(groupId);
      var last = await db.lastSeq(groupId);
      // lastSeq 0 = full replay (the schema v3/v4 upgrades reset it): fold from empty, because replaying on top of
      // stored rows would keep what older code dropped (notes, comments, restores, payers, group settings).
      final replay = last == 0;
      var state = replay ? GroupState.empty : await store.load(groupId);
      final before = state;
      var rebuild = false;
      while (true) {
        final page = await _gone(groupId, () => api.pullEvents(groupId, after: last));
        if (page.events.isEmpty) break;
        for (final e in page.events) {
          state = _apply(state, e);
          rebuild |= e.type == EventTypes.expenseRestored ||
              e.type == EventTypes.paymentRestored ||
              (e.type == EventTypes.groupUpdated && e.payload['defaultCurrency'] != null);
        }
        last = page.events.last.seq;
        await store.save(groupId, state, last);
        if (page.events.length < 500) break;
      }
      // A replay folds from empty: events still held back (behind a receipt upload) keep their local changes.
      final held = replay && last > 0 ? await db.unsentOutbox(groupId) : const <OutboxRow>[];
      if (held.isNotEmpty) {
        for (final o in held) {
          final e = _out(o);
          state = _apply(state, SyncEvent(seq: 0, clientId: e.clientId, type: e.type, payload: e.payload));
        }
        await store.save(groupId, state, last);
      }
      await _dropRemoved(state, before);
      // The stored rows include my optimistic writes, so folding on them can differ from the server:
      // - a deleted row may hold values the server never applied (an update it ignored under rule 3, or one I ignored
      //   because my delete was local first: an update, or someone's payment.confirmed), and a restore of an expense or
      //   a payment makes that row live again;
      // - the currency lock (rule 12) looks at the state, which already holds my expenses and payments with later
      //   seqs (or my own currency change the server ignored).
      // Then take the server's state. The outbox was pushed above; what was queued since is re-applied.
      // ponytail: snapshot per restore / currency change; keep confirmed state apart from the optimistic layer if
      // they get frequent.
      if (rebuild && !replay) {
        try {
          await _rebuild(groupId);
        } catch (_) {
          await db.setLastSeq(groupId, 0); // replay from empty next time instead
          rethrow;
        }
      }
      offline.value = false;
    } on _Gone {
      // Left or removed (here or on another device): nothing to show or keep.
      await dropGroup(groupId);
      offline.value = false;
    } catch (e) {
      offline.value = true;
      debugPrint('sync($groupId) failed: $e');
      rethrow;
    }
  }

  OutboundEvent _out(OutboxRow o) => OutboundEvent(
        clientId: o.clientId,
        type: o.type,
        payload: (jsonDecode(o.payloadJson) as Map).cast<String, dynamic>(),
        createdAt: o.createdAt,
      );

  /// The group's local rows and its receipt files (left, removed, or gone from `GET /groups`).
  Future<void> dropGroup(String groupId) async {
    await receipts.delete(await db.receiptIds(groupId));
    await db.deleteGroupData(groupId);
  }

  /// Receipts removed for everyone in [state] (and not yet in [before]): this device's copies go too, whoever removed
  /// them.
  Future<void> _dropRemoved(GroupState state, [GroupState before = GroupState.empty]) => receipts.delete({
        for (final a in state.attachments)
          if (a.deleted) a.id,
      }.difference({
        for (final a in before.attachments)
          if (a.deleted) a.id,
      }));

  /// Receipt [ids] gone for good: files, rows, pending uploads and unsent `attachment.added`.
  Future<void> _dropReceipts(List<String> ids) async {
    await receipts.delete(ids);
    await db.dropReceipts(ids);
  }

  /// Uploads the group's pending receipts, oldest first (docs/API.md 영수증 sync 1). A missing file, or a refusal of
  /// the photo itself (400, 409, 413), drops that receipt; a 403/404 checks the membership; anything else (401, 429,
  /// 5xx, offline) stops this round, and the push below then holds back that receipt's `attachment.added`.
  Future<void> _upload(String groupId) async {
    for (final u in await db.pendingUploadsOf(groupId)) {
      final id = u.attachmentId;
      if (!await receipts.hasPending(id)) {
        await _dropReceipts([id]);
        continue;
      }
      try {
        await api.uploadAttachment(groupId, id, await receipts.pending(id), await receipts.pending(id, thumb: true));
      } on ApiException catch (e) {
        if (e.code == 'NETWORK') return;
        if (e.status == 400 || e.status == 409 || e.status == 413) {
          final what = await _expenseName((await db.getAttachment(id))?.expenseId);
          await _dropReceipts([id]);
          _rejections.add("Couldn't save the receipt on $what: the server refused it");
          continue;
        }
        if (e.status == 403 || e.status == 404) {
          try {
            await _gone(groupId, () => Future<void>.error(e)); // _Gone when I'm out of the group
          } on ApiException {
            return;
          }
        }
        return;
      }
      await (db.delete(db.pendingUploads)..where((p) => p.attachmentId.equals(id))).go();
      await receipts.uploaded(id);
    }
  }

  /// The server takes 120 events a minute per user (429 above), so a bigger batch could never be sent.
  static const _batch = 100;

  /// Pushes the outbox in batches of [_batch], up to (not including) the first `attachment.added` whose photo is still
  /// waiting to upload. A batch refused with 400/409 (or a 403 while I'm still a member) is re-sent one event at a
  /// time; an event refused on its own is marked rejected. 401, 429, 5xx and network errors stop and keep the rest.
  /// ponytail: one slow upload holds back the group's later events; add per-event dependencies if that hurts.
  Future<void> _push(String groupId) async {
    final pending = {for (final u in await db.pendingUploadsOf(groupId)) u.attachmentId};
    var all = await db.unsentOutbox(groupId);
    final held = all.indexWhere(
        (o) => o.type == EventTypes.attachmentAdded && pending.contains(jsonDecode(o.payloadJson)['attachmentId']));
    if (held >= 0) all = all.sublist(0, held);
    for (var i = 0; i < all.length; i += _batch) {
      await _pushBatch(groupId, all.sublist(i, min(i + _batch, all.length)));
    }
  }

  Future<void> _pushBatch(String groupId, List<OutboxRow> unsent) async {
    try {
      await api.pushEvents(groupId, [for (final o in unsent) _out(o)]);
      await db.dropSent(unsent.map((o) => o.clientId).toList());
      return;
    } on ApiException catch (e) {
      if (!await _refused(groupId, e)) rethrow;
    }
    // ponytail: the one-by-one pass spends the rate limit a second time (N + N events); bisect if batches grow big.
    for (final o in unsent) {
      try {
        await api.pushEvents(groupId, [_out(o)]);
        await db.dropSent([o.clientId]);
      } on ApiException catch (e) {
        if (!await _refused(groupId, e)) rethrow;
        await db.markRejected(o.clientId, e.code);
      }
    }
  }

  /// Whether the server refused the events themselves (400, 409, or 403 while the group still answers).
  /// Throws [_Gone] when the 403 means I'm no longer in the group. An answer without the server's error body
  /// (`NETWORK`: a proxy, captive portal, WAF) is never a refusal.
  Future<bool> _refused(String groupId, ApiException e) async {
    if (e.code == 'NETWORK') return false;
    if (e.status == 400 || e.status == 409) return true;
    if (e.status != 403) return false;
    try {
      await api.getGroup(groupId);
    } on ApiException catch (g) {
      if (_notMember(g)) throw const _Gone();
      return false; // can't tell now: stop and retry later
    }
    return true;
  }

  /// Runs [f]; a 403 or 404 that `GET /groups/{id}` confirms means I'm out of the group → [_Gone].
  Future<T> _gone<T>(String groupId, Future<T> Function() f) async {
    try {
      return await f();
    } on ApiException catch (e) {
      if ((e.status != 403 && e.status != 404) || e.code == 'NETWORK') rethrow;
      try {
        await api.getGroup(groupId);
      } on ApiException catch (g) {
        if (_notMember(g)) throw const _Gone();
      }
      rethrow;
    }
  }

  /// The server's own 403/404 for the group (its error body), not one from something in between.
  static bool _notMember(ApiException g) =>
      (g.status == 403 && g.code == 'FORBIDDEN') || (g.status == 404 && g.code == 'NOT_FOUND');

  /// Rejected rows (from this pass or one the app did not finish): rebuild the group without their optimistic
  /// changes, tell the user, delete the rows.
  Future<void> _settleRejected(String groupId) async {
    final rejected = await db.rejectedOutbox(groupId);
    if (rejected.isEmpty) return;
    // Before the rebuild drops a refused new expense: its name is in the local rows.
    final messages = [for (final o in rejected) await _message(o, rejected)];
    // A refused receipt goes from this device too (its upload stays on the server until the Phase 8 sweep).
    await _dropReceipts([
      for (final o in rejected)
        if (o.type == EventTypes.attachmentAdded) (jsonDecode(o.payloadJson) as Map)['attachmentId'] as String,
    ]);
    try {
      await _rebuild(groupId);
    } catch (e) {
      debugPrint('rebuild($groupId) after a rejected event failed: $e');
      await db.setLastSeq(groupId, 0); // replay from empty next time instead
    }
    messages.forEach(_rejections.add);
    await db.dropSent(rejected.map((o) => o.clientId).toList());
  }

  /// The server's state plus the unsent (not rejected) outbox events in order, so no optimistic change of a dropped
  /// event survives and none of a queued one is lost.
  Future<void> _rebuild(String groupId) async {
    final snap = await api.snapshot(groupId);
    var state = snap.state;
    for (final o in await db.unsentOutbox(groupId)) {
      final e = _out(o);
      state = _apply(state, SyncEvent(seq: 0, clientId: e.clientId, type: e.type, payload: e.payload));
    }
    await _adopt(snap.group, state, snap.latestSeq);
  }

  /// "Couldn't save {what}: {why}" for refused [o]. A new series refused while its first expense went through (the
  /// server stores that one without the series) reads "“Water” was saved but won't repeat: {why}", so nobody adds it
  /// again.
  Future<String> _message(OutboxRow o, List<OutboxRow> rejected) async {
    final why = rejectionReason(o.rejected!, o.type);
    if (o.type == EventTypes.recurrenceCreated) {
      final rid = (jsonDecode(o.payloadJson) as Map)['recurrenceId'] as String?;
      bool tags(OutboxRow x) {
        final p = jsonDecode(x.payloadJson) as Map;
        return x.type.startsWith('expense.') && (p['recurrenceId'] ?? (p['fields'] as Map?)?['recurrenceId']) == rid;
      }

      final first = rid == null || rejected.any(tags)
          ? null
          : await (db.select(db.expenses)
                ..where((e) => e.recurrenceId.equals(rid))
                ..where((e) => e.deleted.equals(false))
                ..limit(1))
              .getSingleOrNull();
      if (first != null) return "“${first.description}” was saved but won't repeat: $why";
    }
    return "Couldn't save ${await _what(o)}: $why";
  }

  /// “Hotel” for an expense id, or "an expense" when it isn't known here.
  Future<String> _expenseName(String? id) async =>
      switch (id == null ? null : (await db.getExpense(id))?.description) { final n? => '“$n”', null => 'an expense' };

  /// What a refused event was: "the new expense “Hotel”", "a change to “Hotel”", "a group settings change", …
  Future<String> _what(OutboxRow o) async {
    final p = (jsonDecode(o.payloadJson) as Map).cast<String, dynamic>();
    final id = p['expenseId'] as String?;
    final name = p['description'] as String? ??
        (p['fields'] as Map?)?['description'] as String? ??
        (id == null ? null : (await db.getExpense(id))?.description);
    final x = name == null ? 'an expense' : '“$name”';
    // A series is named by its template: the payload's, else the local copy's (docs/API.md 거부된 이벤트).
    final rid = o.type.startsWith('recurrence.') ? p['recurrenceId'] as String? : null;
    final series = (p['template'] as Map?)?['description'] as String? ??
        (p['fields'] as Map?)?['description'] as String? ??
        (rid == null ? null : (await store.load(o.groupId)).recurrence(rid)?.description);
    final r = series == null ? null : '“$series”';
    return switch (o.type) {
      EventTypes.recurrenceCreated => r == null ? 'a repeating expense' : 'repeating $r',
      EventTypes.recurrenceUpdated => r == null ? 'a change to a repeating expense' : 'a change to future $r',
      EventTypes.recurrenceDeleted => r == null ? 'stopping a repeating expense' : 'stopping $r from repeating',
      EventTypes.attachmentAdded => 'the receipt on $x',
      EventTypes.attachmentDeleted => 'removing a receipt from $x',
      EventTypes.paymentRestored => 'restoring a payment',
      EventTypes.expenseCreated => name == null ? 'a new expense' : 'the new expense $x',
      EventTypes.expenseUpdated => 'a change to $x',
      EventTypes.expenseDeleted => 'deleting $x',
      EventTypes.expenseRestored => 'restoring $x',
      EventTypes.commentAdded => p['paymentId'] != null ? 'a comment on a payment' : 'a comment on $x',
      EventTypes.commentDeleted => 'deleting a comment',
      EventTypes.paymentCreated => 'a payment',
      EventTypes.paymentDeleted => 'deleting a payment',
      EventTypes.paymentConfirmed => 'confirming a payment',
      EventTypes.groupUpdated => 'a group settings change',
      EventTypes.memberAdded => 'adding ${p['name'] ?? 'a member'}',
      EventTypes.memberRemoved => 'removing a member',
      _ => 'a change',
    };
  }

  /// While [offline], runs [syncAll] every [every], so changes saved offline go out once the server answers again,
  /// not only on the next resume or write. Returns the stop function.
  /// ponytail: a fixed interval; a connectivity listener would need a new dependency.
  VoidCallback retryWhileOffline({Duration every = const Duration(seconds: 30)}) {
    Timer? timer;
    void check() {
      if (offline.value) {
        timer ??= Timer.periodic(every, (_) => syncAll());
      } else {
        timer?.cancel();
        timer = null;
      }
    }

    offline.addListener(check);
    check();
    return () {
      offline.removeListener(check);
      timer?.cancel();
    };
  }

  /// Fire-and-forget variant; errors only flip [offline].
  void syncLater(String groupId) {
    sync(groupId).catchError((_) {});
  }

  Future<void> syncAll() async {
    if (await db.getSession() == null) return;
    // Read before asking: a group created while the request runs is not in the answer but must stay.
    final local = (await db.select(db.groups).get()).map((g) => g.id).toSet();
    try {
      final listed = await api.listGroups();
      final remote = listed.map((g) => g.id).toSet();
      // Left or removed on another device, or removed by someone else.
      for (final id in local.difference(remote)) {
        await dropGroup(id);
      }
      for (final g in listed) {
        final row = await db.getGroup(g.id);
        if (row == null) {
          await adoptFromSnapshot(g.id); // joined on another device
        } else if (row.kind != g.kind) {
          // A friend group stored before schema v6 reads 'group' (no replay then, docs/API.md 호환 6단계); kind never
          // changes afterwards, so the list's is right.
          await db.upsertGroup(row.copyWith(kind: g.kind));
        }
      }
      offline.value = false;
    } catch (e) {
      offline.value = true;
      return;
    }
    for (final g in await db.select(db.groups).get()) {
      await sync(g.id).catchError((_) {});
    }
  }

  /// New device / just joined: snapshot → local rows (no applyEvent needed).
  Future<void> adoptFromSnapshot(String groupId) async {
    final snap = await api.snapshot(groupId);
    await _adopt(snap.group, snap.state, snap.latestSeq);
  }

  Future<void> _adopt(GroupDto g, GroupState state, int latestSeq) async {
    await db.upsertGroup(GroupRow(
      id: g.id,
      name: g.name,
      defaultCurrency: g.defaultCurrency,
      inviteCode: g.inviteCode,
      latestSeq: latestSeq,
      myMemberId: g.myMemberId,
      simplifyDebts: g.simplifyDebts,
      defaultSplitJson: splitToJson(g.defaultSplit),
      kind: g.kind,
    ));
    await store.save(g.id, state, latestSeq);
    await _dropRemoved(state);
  }
}

class _Gone implements Exception {
  const _Gone();
}

/// {이유} in "Couldn't save {what}: {이유}" (docs/API.md 거부된 이벤트); [type] is the refused event's.
String rejectionReason(String code, [String? type]) => switch (code) {
      'LIMIT_EXCEEDED' when type == EventTypes.attachmentAdded => 'an expense can have at most 10 receipts',
      'LIMIT_EXCEEDED' when type == EventTypes.recurrenceCreated => 'a group can have at most 100 repeating expenses',
      'ATTACHMENT_NOT_UPLOADED' => "the photo didn't upload",
      'SUM_MISMATCH' => "the split doesn't add up",
      'PAYERS_SUM_MISMATCH' => "the payers don't add up",
      'NEGATIVE_AMOUNT' => 'an amount is below zero',
      'UNKNOWN_MEMBER' => "it refers to someone who isn't in the group",
      'UNKNOWN_CURRENCY' => "the currency isn't supported",
      'MEMBER_TAKEN' => 'that member is already taken',
      'LIMIT_EXCEEDED' => 'the group is full',
      'FORBIDDEN' => "you're not allowed to make that change",
      _ => 'the server refused it',
    };
