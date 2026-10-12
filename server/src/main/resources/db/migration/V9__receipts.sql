-- Receipt photos (Phase 7, docs/API.md "영수증"). The upload creates the row; attachment.added sets expense_id.
CREATE TABLE attachments (
    id          uuid PRIMARY KEY,
    group_id    uuid NOT NULL REFERENCES groups (id),
    expense_id  uuid REFERENCES expenses (id),
    uploaded_by uuid NOT NULL REFERENCES users (id),
    created_at  timestamptz NOT NULL DEFAULT now(),
    deleted_at  timestamptz
);
CREATE INDEX attachments_group_id ON attachments (group_id);
-- A payment deleted by an edit (payment.deleted with replacedBy) can't be restored (applier rule 7). Edits stored
-- before this migration carry no marker and stay false (docs/API.md 호환(7단계)).
ALTER TABLE payments ADD COLUMN replaced boolean NOT NULL DEFAULT false;
