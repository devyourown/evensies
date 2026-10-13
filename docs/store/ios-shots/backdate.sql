-- The feed shows when the server received an event; seeding happens "now", so use each event's own time instead.
UPDATE events SET received_at = created_at WHERE type NOT IN ('group.created', 'member.added');
-- Server-made creation and join events: just before the group's first pushed event.
UPDATE events e SET received_at = (SELECT min(created_at) FROM events x WHERE x.group_id = e.group_id
    AND x.type NOT IN ('group.created', 'member.added')) - interval '2 hours' + e.seq * interval '1 minute'
  WHERE e.type IN ('group.created', 'member.added');
