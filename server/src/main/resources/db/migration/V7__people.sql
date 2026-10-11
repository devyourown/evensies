-- Phase 6 (docs/API.md "친구", "프로필 사진", "리마인더", "읽지 않은 활동", "송금 기록·편집").
-- Friends are hidden two-person groups. kind is set at creation and never changes (applier rule 13).
ALTER TABLE groups ADD COLUMN kind text NOT NULL DEFAULT 'group' CHECK (kind IN ('group', 'friend'));
-- One namespace with groups.invite_code (the generators check both tables).
ALTER TABLE users ADD COLUMN friend_code text UNIQUE;
ALTER TABLE users DROP COLUMN avatar_url;  -- unused since V1; photos are files under EVENSIES_STORAGE_DIR

-- One canonical friend group per pair of users. user_lo < user_hi (uuid order = lowercase string order).
CREATE TABLE friendships (
    user_lo    uuid NOT NULL REFERENCES users (id),
    user_hi    uuid NOT NULL REFERENCES users (id),
    group_id   uuid NOT NULL REFERENCES groups (id),
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (user_lo, user_hi),
    CHECK (user_lo < user_hi)
);

-- Last reminder per pair; the 24-hour rule is one conditional upsert.
CREATE TABLE reminders (
    from_user uuid NOT NULL REFERENCES users (id),
    to_user   uuid NOT NULL REFERENCES users (id),
    sent_at   timestamptz NOT NULL,
    PRIMARY KEY (from_user, to_user)
);

ALTER TABLE notification_prefs ADD COLUMN reminders boolean NOT NULL DEFAULT true;

-- Comments on payments: exactly one target.
ALTER TABLE comments ALTER COLUMN expense_id DROP NOT NULL;
ALTER TABLE comments ADD COLUMN payment_id uuid REFERENCES payments (id);
ALTER TABLE comments ADD CONSTRAINT comments_one_target CHECK ((expense_id IS NULL) <> (payment_id IS NULL));

-- Unread activity: per user and group, the feed_id seen up to (no row = 0).
CREATE TABLE activity_seen (
    user_id  uuid NOT NULL REFERENCES users (id),
    group_id uuid NOT NULL REFERENCES groups (id),
    feed_id  bigint NOT NULL,
    PRIMARY KEY (user_id, group_id)
);
-- The unread count reads each group's events past its mark (EventRepository.unreadCandidates).
CREATE INDEX events_group_feed_id ON events (group_id, feed_id);
-- Everything before this migration counts as seen, so nobody starts with a badge for old history.
INSERT INTO activity_seen (user_id, group_id, feed_id)
SELECT DISTINCT m.user_id, m.group_id, COALESCE((SELECT max(e.feed_id) FROM events e WHERE e.group_id = m.group_id), 0)
FROM members m WHERE m.user_id IS NOT NULL;
