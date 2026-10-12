-- Repeating expenses (Phase 8, docs/API.md "반복 지출").
CREATE TABLE recurrences (
    id              uuid PRIMARY KEY,
    group_id        uuid NOT NULL REFERENCES groups (id),
    frequency       text NOT NULL CHECK (frequency IN ('weekly', 'biweekly', 'monthly', 'yearly')),
    start_date      date NOT NULL,
    time_zone       text NOT NULL,
    template        jsonb NOT NULL,
    created_by      uuid REFERENCES users (id),
    created_at      timestamptz NOT NULL DEFAULT now(),
    deleted_at      timestamptz,
    next_occurrence int NOT NULL,          -- scheduler-owned, never sent to clients
    next_due_at     timestamptz NOT NULL   -- scheduler-owned
);
CREATE INDEX recurrences_group_id ON recurrences (group_id);
CREATE INDEX recurrences_due ON recurrences (next_due_at) WHERE deleted_at IS NULL;
ALTER TABLE expenses
    ADD COLUMN recurrence_id uuid REFERENCES recurrences (id),
    ADD COLUMN occurrence    int CHECK (occurrence >= 0),
    ADD CONSTRAINT expenses_series_pair CHECK ((recurrence_id IS NULL) = (occurrence IS NULL));
