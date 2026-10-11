-- Phase 6 (docs/API.md 적용 규칙 13, "지출 옮기기"): an expense deleted by a move stays deleted, because it counts in
-- the other group now; expense.restored on it is ignored. The applier keeps the flag in GroupState.
ALTER TABLE expenses ADD COLUMN moved boolean NOT NULL DEFAULT false;
-- Moves stored before this migration get the state a replay of the log gives (a restore after the move is ignored).
UPDATE expenses x SET moved = true, deleted_at = COALESCE(x.deleted_at, now())
WHERE EXISTS (SELECT 1 FROM events e WHERE e.group_id = x.group_id AND e.type = 'expense.deleted'
              AND e.payload ->> 'expenseId' = x.id::text AND jsonb_typeof(e.payload -> 'movedTo') = 'object');
