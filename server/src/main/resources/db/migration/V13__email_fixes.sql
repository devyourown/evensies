-- An address the user removed stays removed: an Apple/Google sign-in doesn't adopt the id-token address again.
ALTER TABLE users ADD COLUMN email_removed boolean NOT NULL DEFAULT false;

-- What a send was for, set once it succeeded: a recurring reminder's '{recurrenceId}:{occurrence}', so a run retried
-- after a failure or the budget stop skips the members who already got it.
ALTER TABLE email_log ADD COLUMN ref text;
