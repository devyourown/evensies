import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../domain/models.dart';
import '../api/api_client.dart';
import '../api/dto.dart';
import '../db/database.dart';
import 'apply_event.dart';
import 'event_types.dart';
import 'group_state_store.dart';

/// push unsent outbox → pull after lastSeq → fold through applyEvent → save.
class SyncService {
  final AppDatabase db;
  final ApiClient api;
  final GroupStateStore store;
  SyncService({required this.db, required this.api}) : store = GroupStateStore(db);

  /// True after the last sync attempt failed (network or server). Shown as a chip in the UI.
  final offline = ValueNotifier<bool>(false);
  final _inFlight = <String>{};

  static GroupState _apply(GroupState s, SyncEvent e) => applyEvent(s, e);

  Future<void> sync(String groupId) async {
    if (!_inFlight.add(groupId)) return;
    try {
      final unsent = await db.unsentOutbox(groupId);
      if (unsent.isNotEmpty) {
        await api.pushEvents(groupId, [
          for (final o in unsent)
            OutboundEvent(
              clientId: o.clientId,
              type: o.type,
              payload: (jsonDecode(o.payloadJson) as Map).cast<String, dynamic>(),
              createdAt: o.createdAt,
            ),
        ]);
        await db.dropSent(unsent.map((o) => o.clientId).toList());
      }
      var last = await db.lastSeq(groupId);
      // lastSeq 0 = full replay (the schema v3 upgrade resets it): fold from empty, because replaying on top of
      // stored rows would keep what release 1 dropped (notes, comments, restores).
      final replay = last == 0;
      var state = replay ? GroupState.empty : await store.load(groupId);
      var restored = false;
      while (true) {
        final page = await api.pullEvents(groupId, after: last);
        if (page.events.isEmpty) break;
        for (final e in page.events) {
          state = _apply(state, e);
          restored |= e.type == EventTypes.expenseRestored;
        }
        last = page.events.last.seq;
        await store.save(groupId, state, last);
        if (page.events.length < 500) break;
      }
      // The stored rows include my optimistic writes, so a deleted row may hold values the server never applied
      // (an update it ignored under rule 3, or one I ignored because my delete was local first). A restore makes
      // that row live again: take the server's state instead. The outbox was pushed above, so nothing is lost.
      // ponytail: snapshot per restore; keep confirmed state apart from the optimistic layer if restores get frequent.
      if (restored && !replay) {
        try {
          await adoptFromSnapshot(groupId);
        } catch (_) {
          await db.setLastSeq(groupId, 0); // replay from empty next time instead
          rethrow;
        }
      }
      offline.value = false;
    } catch (e) {
      offline.value = true;
      debugPrint('sync($groupId) failed: $e');
      rethrow;
    } finally {
      _inFlight.remove(groupId);
    }
  }

  /// Fire-and-forget variant; errors only flip [offline].
  void syncLater(String groupId) {
    sync(groupId).catchError((_) {});
  }

  Future<void> syncAll() async {
    if (await db.getSession() == null) return;
    // Pick up groups joined on another device.
    try {
      for (final g in await api.listGroups()) {
        if (await db.getGroup(g.id) == null) await adoptFromSnapshot(g.id);
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
    await db.upsertGroup(GroupRow(
      id: snap.group.id,
      name: snap.group.name,
      defaultCurrency: snap.group.defaultCurrency,
      inviteCode: snap.group.inviteCode,
      latestSeq: snap.latestSeq,
      myMemberId: snap.group.myMemberId,
    ));
    await store.save(groupId, snap.state, snap.latestSeq);
  }
}
