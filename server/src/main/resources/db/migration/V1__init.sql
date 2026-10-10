CREATE TABLE users (
    id           uuid PRIMARY KEY,
    provider     text NOT NULL,
    subject      text NOT NULL,
    display_name text NOT NULL,
    avatar_url   text,
    created_at   timestamptz NOT NULL DEFAULT now(),
    deleted_at   timestamptz,
    UNIQUE (provider, subject)
);

CREATE TABLE refresh_tokens (
    token      text PRIMARY KEY,
    user_id    uuid NOT NULL REFERENCES users (id),
    expires_at timestamptz NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX refresh_tokens_user_id ON refresh_tokens (user_id);

CREATE TABLE devices (
    id           text PRIMARY KEY,
    user_id      uuid NOT NULL REFERENCES users (id),
    fcm_token    text,
    last_seen_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX devices_user_id ON devices (user_id);

CREATE TABLE groups (
    id               uuid PRIMARY KEY,
    name             text NOT NULL,
    default_currency text NOT NULL,
    invite_code      text NOT NULL UNIQUE,
    created_by       uuid NOT NULL REFERENCES users (id),
    created_at       timestamptz NOT NULL DEFAULT now(),
    archived_at      timestamptz,
    latest_seq       bigint NOT NULL DEFAULT 0
);

CREATE TABLE members (
    id         uuid PRIMARY KEY,
    group_id   uuid NOT NULL REFERENCES groups (id),
    user_id    uuid REFERENCES users (id),
    name       text NOT NULL,
    removed    boolean NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX members_group_id ON members (group_id);
CREATE INDEX members_user_id ON members (user_id);

CREATE TABLE expenses (
    id                 uuid PRIMARY KEY,
    group_id           uuid NOT NULL REFERENCES groups (id),
    description        text NOT NULL,
    amount             bigint NOT NULL,
    currency           text NOT NULL,
    fx_rate_to_default double precision,
    paid_by            uuid NOT NULL REFERENCES members (id),
    date               date NOT NULL,
    category           text,
    created_by         uuid REFERENCES users (id),
    created_at         timestamptz NOT NULL DEFAULT now(),
    updated_at         timestamptz NOT NULL DEFAULT now(),
    deleted_at         timestamptz
);
CREATE INDEX expenses_group_id ON expenses (group_id);

CREATE TABLE expense_shares (
    expense_id uuid NOT NULL REFERENCES expenses (id) ON DELETE CASCADE,
    member_id  uuid NOT NULL REFERENCES members (id),
    amount     bigint NOT NULL,
    position   smallint NOT NULL,
    PRIMARY KEY (expense_id, member_id)
);

CREATE TABLE payments (
    id          uuid PRIMARY KEY,
    group_id    uuid NOT NULL REFERENCES groups (id),
    from_member uuid NOT NULL REFERENCES members (id),
    to_member   uuid NOT NULL REFERENCES members (id),
    amount      bigint NOT NULL,
    currency    text NOT NULL,
    date        date NOT NULL,
    created_by  uuid REFERENCES users (id),
    created_at  timestamptz NOT NULL DEFAULT now(),
    deleted_at  timestamptz
);
CREATE INDEX payments_group_id ON payments (group_id);

CREATE TABLE events (
    group_id      uuid NOT NULL REFERENCES groups (id),
    seq           bigint NOT NULL,
    client_id     uuid NOT NULL,
    type          text NOT NULL,
    payload       jsonb NOT NULL,
    actor_user_id uuid REFERENCES users (id),
    device_id     text,
    created_at    timestamptz NOT NULL,
    PRIMARY KEY (group_id, seq),
    UNIQUE (group_id, client_id)
);
