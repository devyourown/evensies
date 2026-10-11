# Phase 5 design — Organize & insights

Almost everything in this phase runs on the device, over the local drift DB that sync already fills. The server changes in three small places:
- CSV import and export learn about categories.
- Splitwise "Payment" rows are imported as payments.
- The group activity feed can be filtered by expense, for edit history.

It works offline, adds no hosting, and costs €0. There are no migrations.

### What users get
1. **Categories with icons.**
   - A category button replaces the free-text field. It opens a picker with subcategories grouped under their parent (Splitwise's taxonomy).
   - Every expense row shows its category icon.
2. **Auto-guess.**
   - "Uber to the airport" sets Taxi, and "Pizza at Luigi's" sets Dining out.
   - The chip says "auto" until the user picks a category.
   - A description this group has used before gets the category it had last time.
3. **Search** (Pro in Splitwise, free here).
   - It covers descriptions, notes, comments, category names and amounts, across all groups or within one.
   - Case and accents are ignored.
   - "12" finds €12.00–€12.99, and "12,50" finds €12.50.
   - Filters: category and month.
4. **Insights screen per group** (Splitwise "Totals" plus Pro "Charts"). A period bar offers All time, or a month with ‹ ›.
   - **Totals:** total spent, you paid, your share, payments made, payments received, change in your balance.
   - **By month:** bars, with a Group / Mine toggle.
   - **By category:** parent rows that expand into subcategories. Tapping a row opens Search filtered to it.
   - **By person:** what each member paid next to their share.
5. **Share summary** in place of Splitwise's printable web summary: a share-sheet text with the period totals, the top categories and the balances. Phase 9's web build adds browser printing.
6. **"Who should pay next"** line on Balances: "Ben should pay next. He owes the most (€42.10)."
7. **Edit history on the expense** (Splitwise system comments).
   - The expense screen shows a **History** list above the comments: "Anna added this · €18.00", "Ben changed it: €18.00 → €20.00", "Cara commented".
   - The list uses the same sentences as Activity.

### Category taxonomy
The source of truth is `shared/categories.json`. It is copied to `app/assets/` and `server/src/main/resources/`, and tests check the copies are equal.
- The **key** is what goes into `expense.category`. Keys are never renamed.
- The **label** is English. Phase 9 translates labels by key in ARB.
- **File order** decides the order in the picker and breaks ties in the guess.
- `*.other` and `uncategorized.general` use their parent's icon.
- Keywords are stored as people write them and folded when loaded.

| key | label | icon (Material) | starter keywords |
|---|---|---|---|
| *parent* `food` | Food and drink | `restaurant_menu` | |
| `food.dining_out` | Dining out | `restaurant` | restaurant, dinner, lunch, breakfast, brunch, pizza, sushi, burger, café, coffee, takeaway, cena, pranzo, almuerzo, dîner, déjeuner, abendessen, mittagessen, jantar, almoço, ラーメン, 식당 |
| `food.groceries` | Groceries | `shopping_cart_outlined` | groceries, grocery, supermarket, lidl, aldi, carrefour, tesco, mercadona, rewe, albert heijn, spesa, supermercado, supermarché, lebensmittel, boodschappen, スーパー, 마트 |
| `food.liquor` | Liquor | `local_bar` | beer, wine, drinks, bar, pub, cocktail, cerveza, vino, birra, bière, bier, wein, cerveja, 맥주 |
| `food.other` | Other | parent | snacks, ice cream, gelato, bakery, panadería, boulangerie, bakkerij, helado |
| *parent* `transportation` | Transportation | `commute` | |
| `transportation.plane` | Plane | `flight` | flight, flights, plane, airline, ryanair, easyjet, vueling, vuelo, volo, flug, vlucht, 항공권 |
| `transportation.bus_train` | Bus/train | `train_outlined` | train, bus, metro, subway, tram, tube, flixbus, eurostar, renfe, sncf, trenitalia, tren, treno, zug, trein, 電車, 지하철 |
| `transportation.taxi` | Taxi | `local_taxi_outlined` | taxi, uber, lyft, bolt, cab, cabify, grab, freenow, タクシー, 택시 |
| `transportation.car` | Car | `directions_car_outlined` | car, car rental, rental car, car hire, hertz, avis, europcar, sixt, toll, peaje, péage, maut, autostrada |
| `transportation.gas_fuel` | Gas/fuel | `local_gas_station_outlined` | gas, gas station, fuel, petrol, diesel, benzina, gasolina, essence, tanken, benzine, 주유 |
| `transportation.parking` | Parking | `local_parking` | parking, parcheggio, aparcamiento, parkhaus, parkeren, estacionamento, 주차 |
| `transportation.hotel` | Hotel | `hotel_outlined` | hotel, hostel, motel, airbnb, booking, accommodation, albergo, alojamiento, hébergement, unterkunft, ホテル, 숙소 |
| `transportation.bicycle` | Bicycle | `pedal_bike` | bike, bicycle, bici, bicicleta, vélo, fahrrad, fiets |
| `transportation.other` | Other | parent | ferry, scooter, boat, traghetto, fähre |
| *parent* `entertainment` | Entertainment | `local_activity_outlined` | |
| `entertainment.movies` | Movies | `movie_outlined` | cinema, movie, movies, film, netflix, cine, kino, bioscoop, 영화 |
| `entertainment.music` | Music | `music_note` | concert, festival, gig, spotify, concierto, concerto, konzert, 콘서트 |
| `entertainment.games` | Games | `sports_esports` | games, bowling, arcade, escape room, karaoke, steam, playstation, nintendo |
| `entertainment.sports` | Sports | `sports_soccer` | gym, ski, skiing, ski pass, football, tennis, padel, golf, swimming, fitness, palestra, gimnasio |
| `entertainment.other` | Other | parent | museum, tickets, tour, show, theatre, theater, zoo, museo, musée, teatro |
| *parent* `home` | Home | `home_outlined` | |
| `home.rent` | Rent | `house_outlined` | rent, alquiler, affitto, loyer, miete, huur, aluguel, 家賃, 월세 |
| `home.mortgage` | Mortgage | `account_balance_outlined` | mortgage, hipoteca, mutuo, hypothèque, hypothek, hypotheek |
| `home.household_supplies` | Household supplies | `inventory_2_outlined` | household, toilet paper, detergent, soap, paper towels, drogerie |
| `home.furniture` | Furniture | `chair_outlined` | furniture, ikea, sofa, desk, mattress, mueble, mobili, meubles, möbel |
| `home.electronics` | Electronics | `devices_outlined` | electronics, laptop, charger, headphones, mediamarkt, cable |
| `home.maintenance` | Maintenance | `build_outlined` | repair, plumber, maintenance, locksmith, hardware store, leroy merlin, bauhaus |
| `home.pets` | Pets | `pets` | pet food, dog, cat, vet, veterinario, tierarzt |
| `home.services` | Services | `handyman_outlined` | laundry, dry cleaning, gardener, movers, storage, lavandería |
| `home.other` | Other | parent | — |
| *parent* `life` | Life | `favorite_outline` | |
| `life.medical` | Medical expenses | `medical_services_outlined` | doctor, pharmacy, medicine, dentist, hospital, farmacia, pharmacie, apotheke, apotheek, 病院, 약국 |
| `life.gifts` | Gifts | `card_giftcard` | gift, present, birthday, regalo, cadeau, geschenk, プレゼント, 선물 |
| `life.clothing` | Clothing | `checkroom` | clothes, clothing, shoes, jacket, zara, uniqlo, ropa, vestiti, vêtements, kleidung |
| `life.education` | Education | `school_outlined` | school, tuition, course, books, textbook, lesson, university, escuela, scuola, école, schule |
| `life.childcare` | Childcare | `child_friendly_outlined` | babysitter, daycare, nanny, kindergarten, kita, guardería, crèche, asilo |
| `life.insurance` | Insurance | `shield_outlined` | insurance, seguro, assicurazione, assurance, versicherung, verzekering |
| `life.taxes` | Taxes | `request_quote_outlined` | tax, taxes, tourist tax, impuesto, impôt, steuer, belasting |
| `life.other` | Other | parent | — |
| *parent* `utilities` | Utilities | `lightbulb_outline` | |
| `utilities.electricity` | Electricity | `bolt` | electricity, electric bill, power bill, luz, luce, électricité, strom, stroom |
| `utilities.heat_gas` | Heat/gas | `local_fire_department_outlined` | heating, gas bill, calefacción, riscaldamento, chauffage, heizung |
| `utilities.water` | Water | `water_drop_outlined` | water bill |
| `utilities.tv_phone_internet` | TV/Phone/Internet | `wifi` | internet, wifi, broadband, phone bill, mobile plan, sim card, fibra |
| `utilities.trash` | Trash | `recycling` | trash, garbage, rubbish, waste collection |
| `utilities.cleaning` | Cleaning | `cleaning_services_outlined` | cleaning, cleaner, limpieza, pulizie, ménage, putzen, schoonmaak |
| `utilities.other` | Other | parent | utilities, bills, bill |
| *parent* `uncategorized` | Uncategorized | `receipt_outlined` | |
| `uncategorized.general` | General | parent | — |

That is 43 subcategories, the same set as Splitwise's `get_categories`. Splitwise has no custom categories, and neither does Evensies.

### How (server)
- **`export/Categories.kt`** (about 15 lines) loads `/categories.json`:
  - `label(key): String?`
  - `keyForLabel(text): String?`: a case-insensitive match on English labels that appear only once (the six "Other" labels are skipped). A key also matches itself.
- **`SplitwiseImporter`.**
  - The `Category` column becomes `Categories.keyForLabel(raw) ?: raw`.
  - Rows whose `Category` is `Payment` (case-insensitive) with exactly two non-zero nets of ±Cost become `payment.created {fromMember: net +Cost, toMember: net −Cost, amount: Cost, status: "confirmed"}`.
  - Any other Payment row is imported as an expense, as today.
  - `imported` counts expenses plus payments.
- **`CsvExporter`** adds `category` after `description`. It holds the English label for a known key, the raw text for a legacy value, and `General` for null.
- **Edit history:** `GET /groups/{id}/activity` takes an optional `expenseId` (UUID, else 400 `VALIDATION`).
  - It returns only events whose payload `expenseId` equals it: `expense.*`, `comment.added`, and Phase 7 `attachment.*`.
  - Paging is unchanged.
  - `ponytail:` it is a scan of the group's events; add an expression index on `(group_id, (payload->>'expenseId'))` if a group passes about 50k events.

### How (app)
- **Taxonomy:** `assets/categories.json` is loaded at startup next to `Money.loadFromAssets()`.
- **`app/lib/domain/categories.dart`** (pure Dart):
  - `String fold(String s)`:
    - lowercases and removes combining marks U+0300–U+036F;
    - maps Latin-1 Supplement and Latin Extended-A letters to their base letter;
    - `ß→ss`, `æ→ae`, `œ→oe`, `ø→o`, `ł→l`, `đ→d`, `ı→i`.
  - `String resolveCategory(String? raw)`: a known key returns itself; a label that appears once returns its key; anything else returns `uncategorized.general`.
  - `String? guessCategory(String description, {List<({String description, String? category})> history = const []})`:
    1. **History first.** Take the last entry (oldest first) whose folded, trimmed, whitespace-collapsed description equals the input treated the same way and whose category is a known key.
    2. **Tokens.** Split `fold(description)` on `[^\p{L}\p{N}]+` (unicode), dropping empty tokens. Keywords are tokenized the same way.
    3. **No-space scripts.** A keyword containing Han, Hiragana, Katakana, Hangul or Thai matches as a substring. Score = its rune count.
    4. **Other keywords.** These match when their tokens appear consecutively. Each token must be equal, except the last, which may also prefix-match a description token when the keyword token has at least 4 characters and the description token is at most 2 characters longer. Score = the keyword's character count without spaces.
    5. **Winner.** Highest score. On equal score: an exact match beats a prefix match, then file order, then keyword order. "car rental" (9) beats "rent" (4).
    6. No match → `null`.
- **`app/lib/domain/insights.dart`** (pure Dart):
  - `class PeriodTotals { int spent, youPaid, yourShare, paymentsMade, paymentsReceived; Map<String,int> byCategory; Map<String,({int paid,int share})> byMember; int get netChange => youPaid - yourShare + paymentsMade - paymentsReceived; PeriodTotals operator +(PeriodTotals o); }`
  - `({Map<String, PeriodTotals> months, PeriodTotals allTime}) computeTotals(List<Expense> expenses, List<Payment> payments, {required String? me})`:
    - skips deleted items; the month is `date.substring(0, 7)`;
    - **refunds count with sign −1** in `spent`, `byCategory`, `youPaid`, `yourShare` and `byMember`;
    - `byCategory` is keyed by `resolveCategory`;
    - `byMember` lists only members with a non-zero paid or share;
    - payments count when `sent` or `confirmed`, and only in made/received;
    - all-time `netChange` for `me` equals my balance (tested);
    - what a member paid comes from `paidAmounts(Expense) → Map<String,int>`, which reads Phase 3's `payers`.
  - Input is Phase 4's `convertToDefault(state).converted`, so everything is already in the group currency. The not-converted count shows as the Phase 4 "Not converted" card.
  - Search:
    - `class SearchDoc {id, groupId, date, description, String? notes, List<String> comments, String? category, int amount, String currency}`
    - `List<String> searchDocs(List<SearchDoc> docs, String query, {String? category, String? month})` returns ids:
      - Query terms split on whitespace, and all must match.
      - A term matches when its folded form is a substring of the folded description, notes, any comment, raw category, resolved label or parent label.
      - A term matching `^\d+([.,]\d{1,3})?$` also matches by amount: with N having k decimals and the currency having d, the doc matches when `k ≤ d` and `amount ~/ 10^(d−k) == N·10^k`.
      - `category` takes a full key or a parent key (`parent.*`); `month` takes `YYYY-MM`.
      - An empty query with no filter → `[]`.
      - Results are ordered by date descending, then id ascending.
      - `ponytail:` linear scan, debounced 150 ms; move to SQLite FTS5 past about 20k expenses.
- **`domain/balances.dart`** gains `String? whoPaysNext(Map<String,int> defaultBucket, Set<String> activeMemberIds)`: the most negative balance among non-removed members, ties to the lowest memberId; null if nobody owes.
- **`features/categories/category_ui.dart`:**
  - an icon map;
  - `CategoryAvatar(raw)`, which shows the General icon for a legacy value;
  - `showCategoryPicker(context, current) → Future<String?>`, a bottom sheet with parent headers and `ChoiceChip`s.
- **Expense form.**
  - The category button replaces the text field.
  - While `_categoryTouched` is false and the expense is new or uncategorized, a 300 ms debounce runs `guessCategory` with the group's history. Clearing the description clears the guess.
  - A legacy raw value is kept unless the picker changes it.
- **Expense screen** (the edit form, which already holds the Phase 2 comment thread):
  - A **History** section from `GET /groups/{id}/activity?expenseId=` (first 20, "Show more").
  - Offline, it shows the cached feed items with that `expenseId`.
  - It uses Phase 2's formatter.
- **Expense list:** `_ExpenseTile` becomes a public `ExpenseTile` with a leading `CategoryAvatar`. Search and Phase 6 reuse it.
- **Insights** (`features/insights/insights_screen.dart`, route `/groups/:id/insights`, `insights` icon in the group app bar):
  - `insightsProvider(groupId)` combines `groupStateProvider` → `convertToDefault` → `computeTotals`.
  - Bars are built from existing widgets (`LinearProgressIndicator`, `FractionallySizedBox`), each with its amount as text. No chart package.
  - Month bars run from the first to the last month with data, showing at most the latest 24 and scrolling sideways.
  - Share uses `share_plus`.
- **Search** (`features/search/search_screen.dart`, route `/search?group=&category=&month=`).
  - Opened from the groups screen (all groups) and the group app bar (one group, as a removable chip).
  - Docs come from every group's state, with notes and comments.
- **Balances tab:** one "{name} should pay next" line above the rows, from the D bucket. Hidden when balances are null.

### Contract changes
- **Events: none new.** `category` stays `string|null`, with this meaning:
  - a key from `shared/categories.json` (what new clients write);
  - `null` means General;
  - anything else is legacy free text, stored and exported unchanged and shown as General.

  **No server validation, on purpose**: a 400 would reject installed builds' batches.
- **Endpoints changed:**
  - CSV export header: `date,description,category,amount,currency,fxRateToDefault,paidBy,<member names…>`.
  - `POST /groups/{id}/import/splitwise` maps categories and Payment rows (same response shape).
  - `GET /groups/{id}/activity?expenseId=`.
- **No migrations and no new error codes.**
- **`docs/API.md`:** a section "카테고리", the CSV columns, the import rules, and the `expenseId` filter.

### Shared fixtures
These are Dart-only today. They live in `shared/` so that Phase 10's digest could port them later.

`shared/categories.json` (structure; full data per the table):
```json
{"_doc": "Expense categories (Splitwise taxonomy). key is stored in expense.category, never renamed. label is English (Phase 9 translates by key). keywords guess the category (folded). Order = picker order = tie-break order. Copies: app/assets/, server/src/main/resources/.",
 "parents": [{"key": "food", "label": "Food and drink"}, {"key": "transportation", "label": "Transportation"}],
 "categories": [{"key": "food.dining_out", "label": "Dining out", "keywords": ["restaurant", "dinner", "pizza", "café", "cena", "ラーメン"]},
                {"key": "transportation.car", "label": "Car", "keywords": ["car", "car rental", "toll"]}]}
```

`shared/category-cases.json`:
```json
{"fold": [{"in": "Café Crème", "out": "cafe creme"}, {"in": "Straße", "out": "strasse"}],
 "resolve": [
   {"raw": "food.dining_out", "expected": "food.dining_out"},
   {"raw": "Dining out", "expected": "food.dining_out"},
   {"raw": "Other", "expected": "uncategorized.general"},
   {"raw": null, "expected": "uncategorized.general"}],
 "guess": [
   {"name": "accent folded", "description": "Café con leche", "history": [], "expected": "food.dining_out"},
   {"name": "longest keyword beats prefix", "description": "Car rental Sardinia", "history": [], "expected": "transportation.car"},
   {"name": "group history beats keywords", "description": "netflix ", "history": [{"description": "Netflix", "category": "utilities.tv_phone_internet"}], "expected": "utilities.tv_phone_internet"},
   {"name": "no match", "description": "Stuff for Marco", "history": [], "expected": null}]}
```

`shared/search-cases.json`:
```json
{"items": [
   {"id": "x1", "date": "2026-10-02", "description": "Café Florian", "notes": null, "comments": [], "category": "food.dining_out", "amount": 1250, "currency": "EUR"},
   {"id": "x2", "date": "2026-10-05", "description": "Taxi", "notes": "to the airport, 4 bags", "comments": ["Anna paid the tip"], "category": "transportation.taxi", "amount": 1200, "currency": "EUR"},
   {"id": "x3", "date": "2026-09-30", "description": "Room upgrade", "notes": null, "comments": [], "category": null, "amount": 11200, "currency": "EUR"},
   {"id": "x4", "date": "2026-10-05", "description": "Ramen", "notes": null, "comments": [], "category": "Food", "amount": 12000, "currency": "JPY"}],
 "cases": [
   {"name": "diacritics", "query": "cafe", "expected": ["x1"]},
   {"name": "amount in major units; 112.00 and JPY 12000 don't match", "query": "12", "expected": ["x2", "x1"]},
   {"name": "decimal comma", "query": "12,5", "expected": ["x1"]},
   {"name": "AND across notes and comments", "query": "airport anna", "expected": ["x2"]},
   {"name": "legacy raw text and parent label", "query": "food", "expected": ["x4", "x1"]},
   {"name": "filters only", "query": "", "category": "transportation", "month": "2026-10", "expected": ["x2"]}]}
```

`shared/totals-cases.json`. Expenses use the snapshot shape, already in one currency; missing `payers` = `[{paidBy, amount}]` and missing `refund` = false.
```json
{"cases": [
 {"name": "two months, settle in between", "me": "a",
  "expenses": [
   {"id": "x1", "description": "Dinner", "amount": 3000, "currency": "EUR", "paidBy": "a", "date": "2026-09-05", "category": "food.dining_out", "shares": [{"memberId": "a", "amount": 1000}, {"memberId": "b", "amount": 1000}, {"memberId": "c", "amount": 1000}]},
   {"id": "x2", "description": "Lidl", "amount": 1500, "currency": "EUR", "paidBy": "b", "date": "2026-10-02", "category": "food.groceries", "shares": [{"memberId": "a", "amount": 500}, {"memberId": "b", "amount": 500}, {"memberId": "c", "amount": 500}]},
   {"id": "x3", "description": "Misc", "amount": 600, "currency": "EUR", "paidBy": "c", "date": "2026-10-03", "category": null, "shares": [{"memberId": "b", "amount": 300}, {"memberId": "c", "amount": 300}]}],
  "payments": [{"id": "p1", "fromMember": "b", "toMember": "a", "amount": 2000, "currency": "EUR", "date": "2026-10-04"}],
  "expected": {
   "months": {
    "2026-09": {"spent": 3000, "youPaid": 3000, "yourShare": 1000, "paymentsMade": 0, "paymentsReceived": 0, "netChange": 2000,
                "byCategory": {"food.dining_out": 3000},
                "byMember": {"a": {"paid": 3000, "share": 1000}, "b": {"paid": 0, "share": 1000}, "c": {"paid": 0, "share": 1000}}},
    "2026-10": {"spent": 2100, "youPaid": 0, "yourShare": 500, "paymentsMade": 0, "paymentsReceived": 2000, "netChange": -2500,
                "byCategory": {"food.groceries": 1500, "uncategorized.general": 600},
                "byMember": {"a": {"paid": 0, "share": 500}, "b": {"paid": 1500, "share": 800}, "c": {"paid": 600, "share": 800}}}},
   "allTime": {"spent": 5100, "youPaid": 3000, "yourShare": 1500, "paymentsMade": 0, "paymentsReceived": 2000, "netChange": -500,
               "byCategory": {"food.dining_out": 3000, "food.groceries": 1500, "uncategorized.general": 600},
               "byMember": {"a": {"paid": 3000, "share": 1500}, "b": {"paid": 1500, "share": 1800}, "c": {"paid": 600, "share": 1800}}}}},
 {"name": "deleted ignored, sent payment counts, label and legacy categories resolve", "me": "b",
  "expenses": [
   {"id": "x1", "description": "Hotel", "amount": 10000, "currency": "EUR", "paidBy": "a", "date": "2026-10-01", "category": "transportation.hotel", "shares": [{"memberId": "a", "amount": 5000}, {"memberId": "b", "amount": 5000}]},
   {"id": "x2", "description": "Dinner", "amount": 4000, "currency": "EUR", "paidBy": "b", "date": "2026-10-02", "category": "Dining out", "shares": [{"memberId": "a", "amount": 2000}, {"memberId": "b", "amount": 2000}]},
   {"id": "x3", "description": "Oops", "amount": 999, "currency": "EUR", "paidBy": "a", "date": "2026-10-03", "category": null, "deleted": true, "shares": [{"memberId": "a", "amount": 999}]},
   {"id": "x4", "description": "Snacks", "amount": 600, "currency": "EUR", "paidBy": "a", "date": "2026-10-04", "category": "Food", "shares": [{"memberId": "a", "amount": 300}, {"memberId": "b", "amount": 300}]}],
  "payments": [
   {"id": "p1", "fromMember": "b", "toMember": "a", "amount": 3000, "currency": "EUR", "date": "2026-10-05", "status": "sent"},
   {"id": "p2", "fromMember": "b", "toMember": "a", "amount": 500, "currency": "EUR", "date": "2026-10-05", "deleted": true}],
  "expected": {
   "months": {"2026-10": {"spent": 14600, "youPaid": 4000, "yourShare": 7300, "paymentsMade": 3000, "paymentsReceived": 0, "netChange": -300,
     "byCategory": {"transportation.hotel": 10000, "food.dining_out": 4000, "uncategorized.general": 600},
     "byMember": {"a": {"paid": 10600, "share": 7300}, "b": {"paid": 4000, "share": 7300}}}},
   "allTime": {"spent": 14600, "youPaid": 4000, "yourShare": 7300, "paymentsMade": 3000, "paymentsReceived": 0, "netChange": -300,
     "byCategory": {"transportation.hotel": 10000, "food.dining_out": 4000, "uncategorized.general": 600},
     "byMember": {"a": {"paid": 10600, "share": 7300}, "b": {"paid": 4000, "share": 7300}}}}},
 {"name": "refund is negative spend; several payers count per payer", "me": "a",
  "expenses": [
   {"id": "x1", "description": "Hotel", "amount": 10000, "currency": "EUR", "paidBy": "a", "date": "2026-10-01", "category": "transportation.hotel", "shares": [{"memberId": "a", "amount": 5000}, {"memberId": "b", "amount": 5000}]},
   {"id": "x2", "description": "Hotel refund", "amount": 2000, "currency": "EUR", "paidBy": "a", "payers": [{"memberId": "a", "amount": 2000}], "refund": true, "date": "2026-10-02", "category": "transportation.hotel", "shares": [{"memberId": "a", "amount": 1000}, {"memberId": "b", "amount": 1000}]},
   {"id": "x3", "description": "Dinner", "amount": 3000, "currency": "EUR", "paidBy": "b", "payers": [{"memberId": "a", "amount": 1000}, {"memberId": "b", "amount": 2000}], "date": "2026-10-03", "category": "food.dining_out", "shares": [{"memberId": "a", "amount": 1500}, {"memberId": "b", "amount": 1500}]}],
  "payments": [],
  "expected": {
   "months": {"2026-10": {"spent": 11000, "youPaid": 9000, "yourShare": 5500, "paymentsMade": 0, "paymentsReceived": 0, "netChange": 3500,
     "byCategory": {"transportation.hotel": 8000, "food.dining_out": 3000},
     "byMember": {"a": {"paid": 9000, "share": 5500}, "b": {"paid": 2000, "share": 5500}}}},
   "allTime": {"spent": 11000, "youPaid": 9000, "yourShare": 5500, "paymentsMade": 0, "paymentsReceived": 0, "netChange": 3500,
     "byCategory": {"transportation.hotel": 8000, "food.dining_out": 3000},
     "byMember": {"a": {"paid": 9000, "share": 5500}, "b": {"paid": 2000, "share": 5500}}}}}]}
```

### Hyojun's part
None. Insights reads his functions through code paths that already exist:
- Phase 4 conversion goes through `convertToDefault`. While it is a stub, foreign expenses count in the "Not converted" card.
- Phase 3 multi-payer: "you paid" reads the stored `payers` directly. The balance identity test for case 3 is skipped while `computeBalances` throws on refunds.

### Tests
- **Dart, unit:**
  - fold, resolve and guess cases;
  - search and totals cases;
  - for every totals case, `allTime.netChange == computeBalances(...)[me]`;
  - every key has an icon, and no folded keyword appears twice;
  - `whoPaysNext` ties and removed members;
  - the share summary text.
- **Dart, widget:**
  - typing "Pizza" shows Dining out marked auto;
  - picking Hotel, then editing the description, keeps Hotel;
  - a legacy "Food" saves without a `category` field;
  - Search shows the notes excerpt;
  - Insights month switching and drill-down;
  - History renders from a fake API and from the cache when offline.
- **Server:**
  - categories copy equality;
  - CSV header and labels;
  - import: "Dining out" → key, "Food" stays raw, `Payment` → `payment.created` with the same balances;
  - `ActivityTest`: the `expenseId` filter includes comments and excludes other expenses; a bad id → 400.
- **Simulator** (light and dark, largest Dynamic Type):
  - picker and auto-guess;
  - search offline across groups and in one group;
  - Insights and drill-down;
  - share text;
  - "should pay next";
  - History after two edits from two users.

### Depends on / left out
- **Phase 9:** translated labels by key, more keywords per language, and browser printing on web.
- **Phase 10:** deleted groups are left out of search.
- **Left out:**
  - Insights across all groups (overview belongs to Phase 6, home currency to Phase 4).
  - Custom categories.
  - Chart packages and pie charts.
  - PDF export.
  - ML/LLM guessing: it would cost money and send data off the device.
  - Searching payments and member names.
  - A server search endpoint.

### Done when
- "Uber to the airport" sets Taxi without opening the picker, and the list shows the taxi icon.
- In airplane mode, "cafe" finds "Café Florian" and "12,50" finds €12.50.
- All-time "change in your balance" equals my Balances amount, and tapping Groceries lists exactly the grocery expenses.
- A Splitwise CSV with "Dining out" and a Payment row imports categorized expenses plus a payment.
- An edited expense shows its history.
- All tests pass and the simulator checks are done. Rough size: 1–2 sessions.

---
