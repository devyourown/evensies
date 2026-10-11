# Phase 4 design — Currencies

Each expense keeps its own currency. When that differs from the group's, the expense also carries a rate into the group currency (`fxRateToDefault`, already in the contract). Phase 4 makes four changes:
- It fills that rate in automatically.
- It makes the conversion exact.
- Expenses with no rate show under their own currency instead of being hidden.
- Each user gets a home currency for display.

**No new event types. Cost: €0.** Frankfurter's public API is free, needs no key and has no quotas.
- Its v2 endpoint `GET /v2/rates?base=EUR&date=` was checked on 2026-10-11. It returns a JSON array of `{date, base, quote, rate}` with 165 quotes, including `EUR`→`EUR` 1.0, and AED, BHD, CLP, KWD, TWD, VND and INR are all present.
- Typing a rate by hand stays as the fallback.

### What users get
1. **Automatic rate.**
   - Pick JPY in a EUR group and the form fills "1 JPY = 0.00563349 EUR (1 EUR = 177.51 JPY) · rate of 10 Oct", with "≈ €69.55" under the amount.
   - Tapping the rate edits it. A typed rate is kept when the date changes.
2. **About 155 currencies**: every current ISO 4217 code that Frankfurter publishes.
   - The picker is searchable and pins the group currency, your home currency and the last one used.
   - A new expense starts in the last currency used in that group.
3. **One-currency balances that add up.**
   - Each foreign expense converts at its own rate, and its converted parts always add up to the converted total.
   - Different decimals convert correctly. Today ¥1,000 at 0.00616 counts as €0.06 instead of €6.16, and rounding each share on its own lets a group miss zero by a cent.
4. **Nothing silently left out.** An expense with no rate shows in its own "Not converted · JPY" section on Balances, the way Splitwise shows one line per currency.
5. **Convert to EUR**, free here (Pro in Splitwise). One tap fills today's rate (editable) into every unconverted expense in that currency.
6. **Home currency** in Settings, defaulting to the phone region's currency. The groups list, Balances, Settle up and the Phase 6 overall card add "≈ $13.46" next to your amounts.
7. **Offline.** The last rate table stays on the device ("offline · rate of 9 Oct").
8. The CSV export gains a `fxRateToDefault` column.

### How (server)
- **`GET /fx?date=`** returns units per 1 EUR for every code in `currencies.json`, from the cache table `fx_days` (one row per day):
  - A cached row is used as it is when its day is before yesterday (UTC), or it was fetched in the last 6 hours.
  - Otherwise the server calls `{EVENSIES_FX_URL}/rates?base=EUR&date={day}`. It keeps codes we list, sets `EUR: 1`, upserts the row and returns it.
  - If the upstream call fails, the server returns the stale row if there is one, otherwise 503.
  - There is no scheduler: each past day is fetched once, and today at most every 6 hours.
- **HTTP client.** Spring `RestClient`, which ships with `spring-boot-starter-webmvc`, with 5 s timeouts. No new dependency.
- **Apps never call Frankfurter.** The server makes every call. Self-hosters choose the source with `EVENSIES_FX_URL`; empty turns automatic rates off.
- **Abuse cap:** `RateLimiter(30.0, 0.5)` per user.
- **`FxService.rates(date): Map<String, Double>?`** is the only reader of `fx_days`. Phase 8's scheduler reuses it.
- **Home currency:** `users.home_currency`, in `GET /me` and `PATCH /me`.
- **Currency lock:** applier rule 12 is already in from Phase 3.
- **No validator change for rates.** They stay `null` or `>= 0`, and the app treats `0` as "not converted".
- **Kotlin port** `money/Fx.kt` (`convertAmount`, `convertExpense`). The stubs are `TODO()`, and Claude ports Hyojun's Dart in the same push that lands it, under the Phase 3 rule. Phase 6 (reminders) and Phase 10 (digest) build balances on the server and need it.
- **`currencies.json`** grows, and `CsvExporter` writes the rate column.

### How (app)
- **`lib/domain/fx.dart`** holds Hyojun's `convertAmount` and `convertExpense`. Claude creates the stubs.
- **`lib/data/fx_rates.dart`** (Claude):
  - `ApiClient.fx(date)`.
  - drift table `FxDays(day, ratesJson, fetchedAt)`.
  - `crossRate(perEur, from, to)` = `perEur[to] / perEur[from]`, rounded to 6 significant digits with `double.parse(x.toStringAsPrecision(6))`; null if either rate is missing.
  - Online: ask the server (3 s timeout) and store the row.
  - Offline or on error: the cached row with the greatest day ≤ date, else the newest row, else nothing.
  - The latest table is prefetched once per app start when online.
- **Balances** move from `features/group_detail/balances.dart` to **`domain/balances.dart`** (domain code must not import features). With D = the group currency:
  ```dart
  /// Expenses converted into D (amount, shares and payers via convertExpense; currency = D, fxRateToDefault = null),
  /// and the count of non-deleted expenses left in their own currency. Insights (Phase 5) and balancesOf both use it.
  ({List<Expense> converted, Map<String, List<Expense>> unconverted}) convertToDefault(GroupState s);

  class BalanceResult {
    final Map<String, Map<String, int>> byCurrency;   // currency → memberId → balance; D always present
    final Map<String, List<ExpenseLine>> lines;       // per currency, for pairwiseDebts
    final Map<String, List<PaymentLine>> payments;    // per currency
    final Map<String, int> unconverted;               // currency → number of expenses not converted
    final int unsupported;                            // Phase 3 lines left out while computeBalances is a stub
  }
  BalanceResult? balancesOf(GroupState s);          // null only if computeBalances throws on simple lines too

  /// What Settle up shows, per currency: simplifyDebts(bucket) or, with simplify off, pairwiseDebts(bucket lines, payments).
  /// Settle up, the Phase 6 overview and the Phase 9 widget all read this one function.
  Map<String, List<Transfer>> groupTransfers(GroupState s);
  ```
  Bucket rules:
  1. An expense in D counts as it is. A stray rate on it is ignored.
  2. A foreign expense with `fxRateToDefault > 0` goes into D through `convertExpense`, called once on shares and once on payers. If that throws (`UnimplementedError` via `tryCore`, or `FxException`), rule 3 applies.
  3. Any other expense goes into its own currency's bucket, and `unconverted[currency]` goes up by 1.
  4. A payment goes into the bucket of `payment.currency`.
  5. D is always present. Other buckets are kept only while someone's balance in them is non-zero. Every bucket sums to 0.

  Converted amounts are never stored.
- **Expense form.**
  - The rate auto-fills when the currency or date changes, unless the user typed one this session. "Use automatic rate" undoes a typed rate.
  - The source line reads "rate of {day}", "offline · rate of {day}", or "No automatic rate. Enter one, or leave it empty to keep this under Not converted."
  - A rate of 0 is rejected.
  - The "≈" preview uses `convertAmount`.
  - On save, the currency is stored as `lastCurrency.{groupId}`.
- **Currency picker:** `DropdownMenu(enableFilter: true)` showing code and symbol. Used by the expense form, Create group, home currency and Phase 6 `POST /friends`.
- **Expense tile:** "≈ €69.55" under a converted foreign amount; the warning icon when there is no rate.
- **Balances tab:**
  - rows in D;
  - then one "Not converted · JPY" section per other bucket, with member rows and **Convert to EUR**.
  - The old "missing an fx rate" card goes away.
- **Convert sheet.**
  - One row per unconverted currency: count, total, a rate field prefilled from `GET /fx` (or the cache), and a preview.
  - **Convert** writes `expense.updated {fields: {fxRateToDefault: r}}` for every non-deleted expense in that currency with rate null or 0, in one local transaction.
- **Settle up.**
  - Payable transfers come from the D bucket.
  - Each other bucket shows a card: "¥3,000 isn't converted yet · Convert".
  - Payments stay in D, so pay links and the EPC QR don't change.
  - **Leave group** (Phase 3) requires zero in every bucket.
- **Home currency.**
  - A Settings row that calls `PATCH /me` (online only).
  - Cached as `Session.homeCurrency`, falling back to `Money.currencyForLocale`.
  - "≈ H" = Σ over my buckets X of `convertAmount(balance, digits(X), digits(H), crossRate(latest, X, H))`. It is hidden if any rate is missing, or if H is the only currency involved.
  - Create group defaults to the last currency used, then the home currency.
- **Until Hyojun's functions exist**, detected with `fxReady = tryCore(() => convertAmount(amount: 0, fromDecimals: 2, toDecimals: 2, rate: 1)) != null`:
  - all foreign expenses show per currency;
  - Convert and every "≈" line are hidden, and `notImplementedLabel` shows on the Not converted section;
  - rates are still auto-filled and stored.
- **Money display for the new codes.** New codes have no `symbols` entry. Dart `formatMoney` (intl) and Kotlin `Money.display` fall back to the ISO code. Phase 9 sets the final notation.

### Contract changes
- **`fxRateToDefault`** (shape unchanged):
  - major units of the group currency per 1 major unit of the expense currency;
  - `null` or `0` means not converted;
  - ignored when the currencies are equal;
  - automatic rates are rounded to 6 significant digits.
- **New endpoint:**

  | Method | Path | Request | Response |
  |---|---|---|---|
  | GET | `/fx?date=YYYY-MM-DD` | `date` is optional; a future date means today (UTC) | `{"date":"2026-10-10","base":"EUR","rates":{"EUR":1,"USD":1.1217,"JPY":177.51,…}}`. Only codes in `currencies.json` appear, and a code can be missing |

  Errors: 400 `VALIDATION`, 401, 429 `RATE_LIMITED`, 503 `FX_UNAVAILABLE`.
- **`/me`.**
  - `UserDto` gains `homeCurrency: string|null`.
  - `PATCH /me` takes `{"displayName"?, "homeCurrency"?}`. At least one key is required (else 400 `VALIDATION`). An unknown currency gives 400 `UNKNOWN_CURRENCY`.
  - Phase 9 adds `language` to both.
- **`currencies.json`.**
  - Contents: Frankfurter's current ISO codes, minus non-ISO codes (CNH, CMD, GGP, IMP, JEP) and non-money codes (XAU, XAG, XPT, XPD, XDR). About 155 codes.
  - Decimals: 0 for BIF DJF GNF KMF PYG RWF UGX VUV XAF XOF XPF; 3 for IQD JOD LYD OMR TND; 2 for all others.
  - **The 32 existing codes keep their decimals** (HUF 0 and IDR 0 differ from ISO, but stored data uses them).
- **CSV:** `date,description,amount,currency,fxRateToDefault,paidBy,<members>…`. The rate is empty when absent; Phase 5 adds `category`.
- **Migration `V6__currencies.sql`:**
  ```sql
  CREATE TABLE fx_days (
      day        date        PRIMARY KEY,  -- calendar day asked for (UTC)
      rates      jsonb       NOT NULL,     -- {"USD": 1.1217, ...}: units per 1 EUR, latest on or before day
      fetched_at timestamptz NOT NULL
  );
  ALTER TABLE users ADD COLUMN home_currency text;
  ```
- **Env:** `EVENSIES_FX_URL`, default `https://api.frankfurter.dev/v2`. Empty turns automatic rates off.
- **drift (schemaVersion 5):** table `FxDays(day TEXT PK, ratesJson TEXT, fetchedAt TEXT)`; column `Session.homeCurrency TEXT NULL`.

### Shared fixtures
- **`shared/fx-cases.json`** (new). Every case carries `"pending": "hyojun"`. Read by `app/test/hyojun/fx_test.dart` and `server/…/FxTest.kt`:
```json
{"_doc": "Currency conversion. rate = major units of target per 1 major unit of source. fn: amount | expense.",
 "cases": [
  {"name": "JPY to EUR: decimals differ", "fn": "amount", "amount": 1000, "fromDecimals": 0, "toDecimals": 2, "rate": 0.00616, "expected": 616, "pending": "hyojun"},
  {"name": "half rounds away from zero (double math gives 28)", "fn": "amount", "amount": 100, "fromDecimals": 2, "toDecimals": 2, "rate": 0.285, "expected": 29, "pending": "hyojun"},
  {"name": "realistic: 12345 JPY split 4 ways", "fn": "expense", "amount": 12345, "parts": {"a": 3087, "b": 3086, "c": 3086, "d": 3086},
   "fromDecimals": 0, "toDecimals": 2, "rate": 0.00563349, "expected": {"amount": 6955, "parts": {"a": 1739, "b": 1739, "c": 1739, "d": 1738}}, "pending": "hyojun"},
  {"name": "equal fractions go by memberId; rounding each share alone gives 300 or 303", "fn": "expense", "amount": 300, "parts": {"c": 100, "b": 100, "a": 100},
   "fromDecimals": 2, "toDecimals": 2, "rate": 1.005, "expected": {"amount": 302, "parts": {"a": 101, "b": 101, "c": 100}}, "pending": "hyojun"}
 ]}
```
- **`shared/sync-cases.json`:** one new case, "rate set, changed, then cleared" (`0.00616` → `0.0056` → `null`). The currency-lock cases are in Phase 3.

### Hyojun's part
Write these two functions in `app/lib/domain/fx.dart`. Claude creates the file with the class definitions and stub bodies (`=> throw UnimplementedError()`). They are pure: decimals come in as arguments, and rates already arrive rounded to 6 significant digits.

```dart
/// Codes: BAD_RATE, NEGATIVE_AMOUNT, SUM_MISMATCH.
class FxException implements Exception {
  final String code;
  FxException(this.code);
  @override
  String toString() => 'FxException($code)';
}

class ConvertedExpense {
  final int amount;
  final Map<String, int> parts;
  const ConvertedExpense({required this.amount, required this.parts});
}

/// Converts a signed amount in minor units (shared/fx-cases.json, fn "amount").
/// - [rate] = major units of the target per 1 major unit of the source (1 JPY = 0.00616 EUR → 0.00616).
///   Not finite, or <= 0 → FxException('BAD_RATE').
/// - Exact value = amount × R × 10^(toDecimals − fromDecimals), where R is the decimal number that
///   `rate.toString()` prints (Dart's shortest round-trip form, sometimes exponent form such as `7e-7`).
///   Compute it exactly (e.g. BigInt numerator and power-of-ten denominator). Never multiply doubles:
///   100 × 0.285 is 28.499999999999996 as a double, but the answer is 29.
/// - Round to the nearest integer; exact halves go away from zero (28.5 → 29, −28.5 → −29),
///   so convertAmount(−x) == −convertAmount(x).
int convertAmount({required int amount, required int fromDecimals, required int toDecimals, required double rate});

/// Converts an expense total and its parts (shares, and separately the payer amounts: one call per map)
/// so the converted parts add up to the converted total (shared/fx-cases.json, fn "expense").
/// - Checks, in this order: bad rate → 'BAD_RATE'; amount < 0 or any part < 0 → 'NEGATIVE_AMOUNT';
///   sum(parts) != amount → 'SUM_MISMATCH'.
/// - total = convertAmount(amount, …).
/// - Each part: its exact value as in convertAmount, rounded down.
/// - leftover = total − sum of the rounded-down parts (always between 0 and the number of parts).
///   Give +1 to the `leftover` parts whose dropped fraction is largest; equal fractions → memberId ascending
///   (largest remainder method). A part of 0 has no fraction and never gets +1.
/// - The result has exactly the keys of [parts], and its parts sum to its amount. Input map order does not matter.
ConvertedExpense convertExpense({
  required int amount,
  required Map<String, int> parts,
  required int fromDecimals,
  required int toDecimals,
  required double rate,
});
```

Cases to pass, all in `shared/fx-cases.json`:

| # | fn | input (amount, parts, from→to decimals, rate) | expected |
|---|---|---|---|
| 1 | amount | 1000, 0→2, 0.00616 (JPY→EUR) | 616 |
| 2 | amount | 100, 2→2, 0.285 | 29 |
| 3 | amount | −100, 2→2, 0.285 | −29 |
| 4 | amount | 1234, 2→0, 1472.81 (EUR→KRW) | 18174 |
| 5 | amount | 10000, 3→2, 2.88268 (KWD→EUR) | 2883 |
| 6 | amount | 3000000000, 2→3, 7e-7 (`toString` is `7e-7`) | 21000 |
| 7 | amount | 0, 0→2, 0.00616 | 0 |
| 8 | amount | −250, 2→2, 1.0 | −250 |
| 9 / 10 | amount | 100, 2→2, rate 0 / −1.1 | BAD_RATE |
| 11 | expense | 1000 {a:333, b:334, c:333}, 0→2, 0.00616 | 616 {a:205, b:206, c:205}: largest fraction wins, not the memberId |
| 12 | expense | 300 {c:100, b:100, a:100}, 2→2, 1.005 | 302 {a:101, b:101, c:100} |
| 13 | expense | 12345 {a:3087, b:3086, c:3086, d:3086}, 0→2, 0.00563349 | 6955 {a:1739, b:1739, c:1739, d:1738}: fractions decide, so a's extra yen gets no extra cent |
| 14 | expense | 1001 {a:0, b:1001}, 0→2, 0.00616 | 617 {a:0, b:617} |
| 15 | expense | 0 {}, 0→2, 0.00616 | 0 {} |
| 16 | expense | 1000 {a:500, b:400}, 2→2, 1.1 | SUM_MISMATCH |
| 17 | expense | −100 {a:−100}, 2→2, 1.1 | NEGATIVE_AMOUNT |
| 18 | expense | 1000 {a:1000}, 2→2, 0 | BAD_RATE |

**Where they are called:**
- `convertToDefault` / `balancesOf` call `convertExpense` (shares and payers).
- The previews, the tile, the Convert sheet and the "≈" lines call `convertAmount`.
- On the server: the Kotlin port, used by Phase 6 `Balances.ofGroup`.

### Tests
- **Dart, Hyojun:** `test/hyojun/fx_test.dart` runs every case, and pending cases are skipped.
- **Dart, Claude:**
  - `balances_test`:
    - default currency only;
    - a rated JPY expense lands in D and the bucket sums to 0 (skipped until `fxReady`);
    - no rate or rate 0 → its own bucket;
    - a legacy USD payment → the USD bucket;
    - while the stub throws, rated expenses land in their own buckets;
    - a bucket netting to zero is dropped;
    - `groupTransfers` with simplify off is pairwise per bucket.
  - `fx_rates_test`:
    - `crossRate` (1/177.51 → 0.00563349; JPY→KRW through EUR);
    - the offline lookup order;
    - parsing the array response.
  - Expense form with a fake API:
    - auto-fill;
    - a typed rate survives a date change;
    - the offline label;
    - last currency preselected;
    - rate 0 rejected.
  - The original 32 codes keep their decimals.
- **Server:**
  - `FxTest` against a JDK `HttpServer` stub as upstream:
    - first call fetches and stores; a past day isn't fetched twice;
    - today refreshes after 6 h;
    - stale row when the upstream is down; 503 when nothing is cached;
    - an empty URL → 503 with no upstream call;
    - XAU dropped;
    - future date, bad date → 400, no token → 401, more than 30 a minute → 429.
  - `FxCasesTest` runs `fx-cases.json` against the Kotlin port.
  - `GET`/`PATCH /me` with `homeCurrency`: valid, unknown, missing, and the old body.
  - CSV has the rate column.
- **Simulator** (light and dark):
  - auto-fill and edit in a EUR group;
  - airplane mode with a cached rate;
  - a currency with no cache shows under Not converted, then Convert merges it;
  - home currency USD shows "≈ $";
  - the picker search.

### Dependencies and deliberately left out
- **Phase 3:** payers are converted with a second `convertExpense` call. Simplify and pairwise run per bucket.
- **Phase 2:** a Convert is one push, so it arrives as one batched notification.
- **Phase 5:** Insights reads `convertToDefault`.
- **Phase 6:** the overview reads `groupTransfers` (all buckets), and the overall "≈" line uses the home currency.
- **Phase 8:** the scheduler refreshes the rate of foreign-currency templates through `FxService`.
- **Phase 9:** `int` is a JS number on web. BigInt keeps `convertAmount` exact.
- **Left out:**
  - Converting a group to a currency other than its own.
  - Paying an unconverted currency in that currency: payments stay in D.
  - Changing the group currency after the first expense (rule 12).
  - BTC and other crypto (no free source).
  - Intraday rates.
  - Localized currency names in the picker.
  - A per-expense-date rate in the Convert sheet.
  - Clearing the home currency.

### Done when
- A ¥ expense in a EUR group gets its rate automatically, and the euro balances add up exactly.
- An expense added offline uses the cached rate.
- An expense with no rate shows under Not converted and merges after one Convert.
- With home currency USD, "≈ $" shows on the groups list, Balances and Settle up.
- All fx cases pass with Hyojun's functions and the Kotlin port; the server and app tests and the light/dark simulator checks pass.

---
