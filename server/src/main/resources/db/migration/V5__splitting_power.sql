-- Multiple payers (docs/API.md rule 10). expenses.paid_by stays as the primary payer for old readers and the CSV.
CREATE TABLE expense_payers (
    expense_id uuid     NOT NULL REFERENCES expenses (id) ON DELETE CASCADE,
    member_id  uuid     NOT NULL REFERENCES members (id),
    amount     bigint   NOT NULL,
    position   smallint NOT NULL,
    PRIMARY KEY (expense_id, member_id)
);
INSERT INTO expense_payers (expense_id, member_id, amount, position) SELECT id, paid_by, amount, 0 FROM expenses;
ALTER TABLE expenses ADD COLUMN refund boolean NOT NULL DEFAULT false, ADD COLUMN split jsonb;
ALTER TABLE groups ADD COLUMN simplify_debts boolean NOT NULL DEFAULT true, ADD COLUMN default_split jsonb;
