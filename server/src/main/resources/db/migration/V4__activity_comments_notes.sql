-- Activity feed (docs/API.md "활동·알림"): per-event feed values captured while a push applies the event,
-- and a global storage order for the overall feed. Existing rows are numbered in physical (≈ insertion) order;
-- their meta is filled at startup by ActivityBackfill.
ALTER TABLE events ADD COLUMN meta jsonb;
ALTER TABLE events ADD COLUMN feed_id bigserial;
CREATE UNIQUE INDEX events_feed_id ON events (feed_id);

ALTER TABLE expenses ADD COLUMN notes text;

CREATE TABLE comments (
    id               uuid PRIMARY KEY,
    group_id         uuid NOT NULL REFERENCES groups (id),
    expense_id       uuid NOT NULL REFERENCES expenses (id),
    author_member_id uuid NOT NULL REFERENCES members (id),
    text             text NOT NULL,
    created_at       timestamptz NOT NULL,
    deleted_at       timestamptz
);
CREATE INDEX comments_group_id ON comments (group_id);

-- No row = everything on.
CREATE TABLE notification_prefs (
    user_id  uuid PRIMARY KEY REFERENCES users (id),
    expenses boolean NOT NULL DEFAULT true,
    comments boolean NOT NULL DEFAULT true,
    members  boolean NOT NULL DEFAULT true
);

-- Activity feed time (docs/API.md "피드"): when the server stored the event. created_at is the client's clock
-- (offline edits pushed later, wrong device clocks), so it can disagree with the feed's seq order. Old rows only have
-- created_at. clock_timestamp(), not now(): a push waits for the group lock, so its transaction start can predate an
-- earlier seq.
ALTER TABLE events ADD COLUMN received_at timestamptz;
UPDATE events SET received_at = created_at;
ALTER TABLE events ALTER COLUMN received_at SET DEFAULT clock_timestamp(), ALTER COLUMN received_at SET NOT NULL;
