-- Phase 10 (docs/API.md "이메일·계정"): account email, email codes and invites, digests, group type/cover/delete, blocks.

-- Account email. Only verified addresses are stored: an id-token claim with email_verified, or a code we sent.
ALTER TABLE users ADD COLUMN email text;
CREATE UNIQUE INDEX users_email_active ON users (email) WHERE deleted_at IS NULL;

-- Group type, cover, delete/restore. archived_at was never read or written. Cover files live in FileStore covers/.
ALTER TABLE groups RENAME COLUMN archived_at TO deleted_at;
ALTER TABLE groups ADD COLUMN type text NOT NULL DEFAULT 'other' CHECK (type IN ('trip', 'home', 'couple', 'other'));
ALTER TABLE groups ADD COLUMN cover_image_id uuid;

-- Whether the OS lets this device show notifications ("auto" digests go to people who can't get push).
ALTER TABLE devices ADD COLUMN notifications_allowed boolean NOT NULL DEFAULT true;

-- Digest choice and window (window = events.feed_id from Phase 2).
ALTER TABLE notification_prefs ADD COLUMN email_digest text NOT NULL DEFAULT 'auto'
    CHECK (email_digest IN ('auto', 'daily', 'weekly', 'monthly', 'off'));
ALTER TABLE notification_prefs ADD COLUMN last_digest_at timestamptz;
ALTER TABLE notification_prefs ADD COLUMN last_digest_feed_id bigint NOT NULL DEFAULT 0;

-- Reminder email before a repeating bill posts (rule 18).
ALTER TABLE recurrences ADD COLUMN remind_days_before smallint CHECK (remind_days_before BETWEEN 1 AND 7);
ALTER TABLE recurrences ADD COLUMN reminded_occurrence int NOT NULL DEFAULT 0;   -- scheduler-owned

CREATE TABLE user_blocks (
    blocker    uuid NOT NULL REFERENCES users (id),
    blocked    uuid NOT NULL REFERENCES users (id),
    created_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (blocker, blocked)
);

CREATE TABLE email_codes (
    email      text NOT NULL,
    purpose    text NOT NULL CHECK (purpose IN ('login', 'change')),
    user_id    uuid REFERENCES users (id),      -- 'change': who asked
    code_hash  text NOT NULL,                   -- HMAC, never the code
    expires_at timestamptz NOT NULL,
    attempts   int NOT NULL DEFAULT 0,
    PRIMARY KEY (email, purpose)
);

-- Third-party addresses typed by an inviter; purged 14 days after sent_at.
CREATE TABLE email_invites (
    member_id   uuid PRIMARY KEY REFERENCES members (id),
    group_id    uuid NOT NULL REFERENCES groups (id),
    email       text NOT NULL,
    invited_by  uuid NOT NULL REFERENCES users (id),
    sent_at     timestamptz NOT NULL DEFAULT now(),
    reminded_at timestamptz
);

-- Addresses we must not email except for codes they request. sha256 hex of the lower-cased address.
CREATE TABLE email_suppressions (
    email_hash text PRIMARY KEY,
    reason     text NOT NULL CHECK (reason IN ('unsubscribe', 'bounce', 'complaint')),
    created_at timestamptz NOT NULL DEFAULT now()
);

-- One row per sent email; drives budgets and per-address limits. Purged after 30 days.
CREATE TABLE email_log (
    id      bigserial PRIMARY KEY,
    kind    text NOT NULL,                      -- login_code, change_code, invite, invite_reminder, digest, recurring_reminder
    to_hash text NOT NULL,
    user_id uuid,                               -- account charged: the inviter for invites, the recipient otherwise
    sent_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX email_log_to_hash ON email_log (to_hash, sent_at);
CREATE INDEX email_log_sent_at ON email_log (sent_at);
