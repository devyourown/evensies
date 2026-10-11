-- Payment confirmation (docs/API.md rule 6): existing payments were recorded as done, so they are confirmed.
ALTER TABLE payments ADD COLUMN status text NOT NULL DEFAULT 'confirmed' CHECK (status IN ('sent', 'confirmed'));

-- "Ways to get paid": per-user list, replaced as a whole by PUT /me/payment-methods.
CREATE TABLE payment_methods (
    user_id  uuid NOT NULL REFERENCES users (id),
    position int  NOT NULL,
    type     text NOT NULL,
    value    text NOT NULL,
    holder   text,
    bank     text,
    bic      text,
    PRIMARY KEY (user_id, position)
);
