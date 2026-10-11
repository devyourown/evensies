-- Emails were used as display names when the id token had no name claim (always the case for Apple).
-- Clear them so the app asks the user for a name; names are visible to other group members.
UPDATE users SET display_name = '' WHERE display_name LIKE '%@%';
