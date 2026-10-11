-- Exchange-rate cache for GET /fx (docs/API.md "환율"); FxService is its only reader.
CREATE TABLE fx_days (
    day        date        PRIMARY KEY,  -- day asked for (UTC, future clamped to today)
    rates      jsonb       NOT NULL,     -- {"EUR": 1, "USD": 1.1217, ...}: units per 1 EUR
    rate_date  date        NOT NULL,     -- latest per-quote date in rates (FxTable.date)
    fetched_at timestamptz NOT NULL
);
-- Display currency for "≈" lines; null = the app uses the phone region's currency.
ALTER TABLE users ADD COLUMN home_currency text;
