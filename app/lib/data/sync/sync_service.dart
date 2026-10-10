import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/ids.dart';
import '../../domain/models.dart';
import '../api/api_client.dart';
import '../api/dto.dart';
import '../db/database.dart';
import 'apply_event.dart';
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
        await db.markSent(unsent.map((o) => o.clientId).toList(), nowIsoUtc());
      }
      var last = await db.lastSeq(groupId);
      while (true) {
        final page = await api.pullEvents(groupId, after: last);
        if (page.events.isEmpty) break;
        var state = await store.load(groupId);
        for (final e in page.events) {
          state = _apply(state, e);
        }
        last = page.events.last.seq;
        await store.save(groupId, state, last);
        if (page.events.length < 500) break;
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
