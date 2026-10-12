-- Language for server-rendered text (push now, email in Phase 10). NULL = English.
ALTER TABLE users ADD COLUMN language text CHECK (language ~ '^[a-z]{2,3}$');
