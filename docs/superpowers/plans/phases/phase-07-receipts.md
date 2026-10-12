# Phase 7 design — Receipts

This phase adds receipt photos on expenses, plus an itemized split that a receipt scan can fill in. Text recognition runs on the phone (ML Kit), so neither the image nor the recognized text goes anywhere for OCR. The only upload is the photo the user chooses to attach, and only members of that group can download it. Storage, image cleaning and the app's JPEG pipeline are Phase 6's.

It covers Splitwise rows #6 (itemized), #7 (scan; Pro there) and #16 (receipt photo; Pro gets 10 GB there), all free.

### What users get
1. **Receipt photos on an expense.**
   - Attach from the camera or the photo library, up to 10 per expense.
   - Thumbnails show on the expense screen. Tapping one opens it full screen with pinch-zoom, share/save, and remove (for everyone, after a confirmation).
   - Rows in the list show a receipt icon.
   - A photo taken offline uploads on the next sync.
2. **Itemized split.** "Items" is a sixth way to split.
   - Lines with prices; tap the people on each line. A shared line is split equally between its people.
   - Tax, tip/service (as an amount or a %) and a discount, spread in proportion to each person's subtotal.
   - Live per-person totals. The expense amount is the itemized total.
   - Reopening the expense opens Items with every line.
3. **Scan a receipt.**
   - "Scan receipt" fills the lines, tax, tip, discount, total and merchant (as the description) from on-device recognition.
   - The user corrects, assigns and saves, and the photo is attached.
   - A mismatch with the printed total is shown as a warning, not an error.
4. **Activity and push:** "Ben added a receipt to *Dinner*", "Ben removed a receipt from *Dinner*". Item edits show as "split".
5. **Export with receipts:** Settings → Export → "ZIP with receipts" (the group JSON plus every image).

### How (server)
- **Storage:** Phase 6 `FileStore`, with keys `attachments/{groupId}/{attachmentId}.jpg` and `…_thumb.jpg`. Every upload goes through `Jpeg.clean`, with max edge 4096 for `image` and 1024 for `thumb`.
- **Upload first, event second.**
  - `POST /groups/{id}/attachments/{attachmentId}` (multipart `image` + `thumb`) stores both files and inserts an `attachments` row with `expense_id = NULL`.
  - The app then pushes `attachment.added {attachmentId, expenseId}`, which the validator rejects unless that upload exists in the same group.
  - Retries are safe: the app makes the id. If the id is already stored for this group → 200 and the files are not replaced (first write wins).
  - Handler order: look up the row; if new, write the files, then insert. A `DuplicateKeyException` race re-checks the row.
- **Download.** `GET …/{attachmentId}` and `…/thumb` stream the file after `requireMember`.
  - A deleted id, or an id from another group → 404.
  - Headers: `Content-Type: image/jpeg`, `Cache-Control: private, max-age=31536000, immutable`, `nosniff`.
- **Events.** `attachment.added` / `attachment.deleted` go through the normal push.
  - `EventValidator` gets `uploadGroup(attachmentId): UUID?`, passed in like `paymentCreator`.
  - `GroupStateStore.persist` gets an attachment branch: `UPDATE attachments SET expense_id = …, deleted_at = CASE … END WHERE id = … AND group_id = …`.
  - `load` reads attached rows ordered by `created_at, id`.
  - `GroupState` gains `attachments`, which the snapshot carries.
- **Deleting.** After a push commits, `pushValidated` deletes both files of every `attachment.deleted` in the batch. The row stays with `deleted_at`.
  - `expense.deleted` keeps its receipts, so a Phase 2 restore brings them back.
  - Phase 10 group delete keeps them too.
- **Itemized split = `SplitSpec` mode `itemized`** (`expenses.split`, from Phase 3).
  - Under Phase 3's rule the server validates only the shape and does not recompute shares. The editor checks the bill against the shares when it loads.
  - There is no Kotlin twin.
- **Abuse caps** (documented as abuse caps):
  - 60 uploads per user per hour (`RateLimiter(60.0, 60.0 / 3600)`) → 429;
  - 10 live attachments per expense → 409.
- **ZIP export.** `GET /groups/{id}/export?format=zip` streams with `StreamingResponseBody` + `ZipOutputStream`: `group.json` plus `receipts/{attachmentId}.jpg` for every live attachment.

### How (app)
- **New package:** `google_mlkit_text_recognition` (Latin script). `image_picker` and `flutter_image_compress` are already in from Phase 6. The viewer is `InteractiveViewer`, and sharing is `share_plus`.
- **Spike first** (half a session): build ML Kit on the Apple-silicon iOS simulator and write down the app-size increase (budget: 15 MB or less).
  - ML Kit needs iOS 15.5, so `Podfile` and the target go up from 15.0.
  - If the pods won't build for the arm64 simulator, iOS uses Apple Vision (`VNRecognizeTextRequest`) through `MethodChannel('evensies/ocr')`, about 50 lines. Android keeps ML Kit.
  - Either way, Dart sees `Future<List<OcrLine>> recognizeLines(String imagePath)`, where `OcrLine = {text, left, top, right, bottom}`.
- **Taking a photo** (`data/receipts.dart`):
  1. `image_picker` returns the original.
  2. `prepareJpeg` (Phase 6) writes `{appSupport}/pending_attachments/{id}.jpg` (`maxEdge: 2048, quality: 80`, about 300–700 KB) and `{id}_thumb.jpg` (512, 70).
  3. The original temp file is deleted.
  4. When scanning, OCR runs on the prepared 2048 px JPEG (a 50 MP original is too big to decode at once on Android).

  A new expense's id is made when the form opens. Cancel deletes the prepared files.
- **Local writes.**
  - `attachReceipt(groupId, expenseId, attachmentId)` writes the local `attachments` row, a `pending_uploads` row and the outbox `attachment.added` (after `expense.created` for a new expense).
  - `removeReceipt` while still pending deletes the files, the pending row and the unsent event; nothing reaches the server.
  - `removeReceipt` after upload queues `attachment.deleted` and deletes the cache.
- **Sync** (`SyncService.sync`):
  1. Upload each pending row. On success, delete the row and move the files to `{appCache}/attachments/`. A missing local file drops the row and its event. The first failure stops this round.
  2. Push the outbox only up to the first `attachment.added` whose upload is still pending.
  3. Pull.

  `ponytail:` one slow upload holds back the group's later events; add per-event dependencies if that hurts.
- **Showing receipts.** `ReceiptFiles.thumb/full` return the cached file, else the pending file, else a download through `ApiClient`.
  - Offline and not cached: "Available when online".
  - `deleteGroupData` and `wipeAll` delete the files.
  - The list icon comes from `watchAttachmentCounts(groupId)`.
- **Itemized split** (`app/lib/domain/itemized.dart`, Claude, Dart only):
  ```dart
  class ItemLine { final String name; final int amount; final List<String> memberIds; /* fromJson/toJson */ }
  class ItemizedBill { final List<ItemLine> lines; final int tax, tip, discount; /* fromJson: missing tax/tip/discount = 0 */ }

  /// Σ lines.amount + tax + tip − discount.
  int itemizedTotal(ItemizedBill b);

  /// memberId → share. Throws SplitException: NEGATIVE_AMOUNT, UNASSIGNED_ITEM, ZERO_SUBTOTAL, NEGATIVE_TOTAL.
  /// 1. Any line amount, tax, tip or discount < 0 → NEGATIVE_AMOUNT. A line with no memberIds → UNASSIGNED_ITEM.
  /// 2. Each line: computeSplit(amount: line.amount, mode: equal, members: line.memberIds)
  ///    (remainder +1 to memberId ascending). subtotal[m] = Σ m's parts. S = Σ subtotal = Σ line amounts.
  /// 3. net = tax + tip − discount; total = S + net. total < 0 → NEGATIVE_TOTAL. S == 0 and net != 0 → ZERO_SUBTOTAL.
  /// 4. Spread |net|: base[m] = floor(|net| × subtotal[m] / S) with a BigInt product (exact on web).
  ///    r = |net| − Σ base; add 1 to the first r members with subtotal > 0 in memberId ascending order.
  /// 5. share[m] = subtotal[m] + extra[m] if net ≥ 0, else subtotal[m] − extra[m] (never negative).
  /// 6. The result has every member on any line (0 allowed). Σ result == itemizedTotal. Deterministic.
  Map<String, int> computeItemizedSplit(ItemizedBill b);

  /// UI only: pct % of subtotal, rounded half up.
  int percentOf(int subtotal, num pct);
  ```
- **Receipt parser** (`domain/receipt_parser.dart`, pure Dart, app fixtures): `ReceiptDraft parseReceipt(List<OcrLine> lines, {required int decimals})` → `{lines: [{name, amount}], tax, tip, discount, total?, merchant?}`. Best effort; the user always reviews it.
  1. **Rows.** Sort by vertical centre. A line joins the current row when its centre is within half the median line height. Text is joined left to right. A text-only row followed by a price-only row is merged.
  2. **Price** = the row's last token:
     - optional currency sign or code;
     - digits, possibly grouped with `.` `,` `'` or a space;
     - a fraction of exactly `decimals` digits (required when decimals > 0, never present otherwise);
     - optional trailing `-`;
     - an optional single VAT letter or `*`.

     The separator before the fraction is the decimal mark.
  3. **Total.** The largest price among rows matching a total keyword and not a subtotal keyword, else the largest price. Rows below it are ignored.
  4. **Classify rows above the total**, first match wins:
     - subtotal → ignored;
     - tax → `tax +=`;
     - tip/service → `tip +=`;
     - discount keyword or negative price → `discount += |price|`;
     - other total keyword → ignored;
     - payment noise (cash, card, change, visa, …) → ignored;
     - anything else with a price → a line ("2x" stays in the name).
  5. **VAT already included:** if lines + tip − discount == total, set tax to 0.
  6. **Merchant:** the first row with no price, if it has 40 characters or fewer.

  Keywords live in one `const` map for EN, IT, DE, FR, ES, NL, PT, SV, PL and ID.
- **Itemize screen** (`features/itemize/itemize_screen.dart`):
  - the receipt image on top (collapsible);
  - each line has a name, an amount and member chips with "All"; lines can be added and swiped away;
  - unassigned lines are highlighted, and Done is disabled until each line has a person ("Give the rest to everyone");
  - footer: Subtotal; Tax / Tip / Discount, each with an amount/% toggle (stored as the amount); Total; and "Receipt says €41.25 · items differ by €0.05" after a scan;
  - per-person live totals;
  - removed members already on a line are kept and shown by name.
- **Expense form.**
  - The mode selector becomes a `ChoiceChip` row (six modes don't fit a segmented control).
  - Items mode shows a summary ("4 items · Anna €18.40 · Ben €22.80 · Edit"), and the amount is read-only (`itemizedTotal`).
  - Save sends `split: {"mode":"itemized","bill":…}` together with `shares`/`amount` (Phase 3 rule).
  - Opening: Items when `itemizedTotal(bill) == amount` and `computeItemizedSplit(bill)` equals the shares (ignoring zeros), else Exact.
  - The receipt strip shows on the expense screen.
- **Moving an expense** (extends Phase 6 `remapForMove`):
  - `split.bill.lines[].memberIds` are remapped like shares.
  - Receipts are downloaded if not cached, uploaded under new ids into the target group, and attached there, before the source delete is queued.
- **Platform.**
  - iOS camera and photo strings are already in (Phase 6). Android needs no permissions.
  - ML Kit sends anonymous SDK usage and diagnostics to Google (never images or text). The App Store label, the Play data-safety form and `docs/privacy.md` must say so; that is a release-time owner step.
- **Web (Phase 9):** "Scan receipt" is hidden. Manual Items and photo upload work.
- **Order of work:** spike → `docs/API.md` + fixtures → server → app → simulator.

### Contract changes
**Events**

| type | payload | validation |
|---|---|---|
| `attachment.added` | `{"attachmentId","expenseId"}` | Any member. Uploaded to **this** group (400 `ATTACHMENT_NOT_UPLOADED`); `expenseId` known (400 `VALIDATION`); not attached to a different expense (400 `VALIDATION`); at most 10 live per expense (409 `LIMIT_EXCEEDED`) |
| `attachment.deleted` | `{"attachmentId"}` | Any member. An unknown id is accepted and ignored; the server deletes the files after commit |

**`SplitSpec` mode `itemized`** (extends Phase 3):
```
{"mode": "itemized", "bill": {"lines": [{"name": "Burger", "amount": 1450, "memberIds": ["m1"]}], "tax": 284, "tip": 600, "discount": 0}}
```
Shape rules (400 `VALIDATION` unless noted):
- `lines` has 1–200 entries;
- `name` is trimmed, 1–100 characters;
- `amount` is an integer ≥ 0;
- `memberIds` are non-empty and unique, and must be group members (else `UNKNOWN_MEMBER`);
- `tax`, `tip`, `discount` are integers ≥ 0, missing = 0;
- `bill` is required for this mode, and `input` must be absent.

The server does not check that the bill matches the shares (Phase 3 principle).

**Applier rule 14 (attachments).**
- `attachment.added` with an existing id leaves the state unchanged (idempotent; a re-add after a delete stays deleted).
- For an unknown expense it is ignored.
- Otherwise it appends `{id, expenseId, deleted: false}`, also for a deleted expense.
- `attachment.deleted` for an unknown id is ignored; otherwise it sets `deleted = true`.

**Activity kinds:**
- `receipt_added` (`attachment.added`) and `receipt_removed` (`attachment.deleted`).
- Fills `expenseId` and `description`. Push category `expenses`.
- Sentences: "{A} added a receipt to “{description}”" / "{A} removed a receipt from “{description}”".

**Endpoints**

| method | path | request | response |
|---|---|---|---|
| POST | `/groups/{id}/attachments/{attachmentId}` | multipart `image` (JPEG, 2 MB or less, edges 4096 or less) + `thumb` (JPEG, 200 KB or less, edges 1024 or less) | 201 `{"id"}`; 200 if already stored for this group |
| GET | `/groups/{id}/attachments/{attachmentId}` | | `image/jpeg` |
| GET | `/groups/{id}/attachments/{attachmentId}/thumb` | | `image/jpeg` |
| GET | `/groups/{id}/export?format=zip` | | `application/zip` |

Errors:
- 400 `VALIDATION` (a part is missing);
- 400 `NOT_JPEG`;
- 400 `IMAGE_TOO_LARGE`;
- 413 `TOO_LARGE`;
- 403;
- 404 (group; for GET also unknown, other-group or deleted id);
- 409 `DUPLICATE` (the id is stored for another group);
- 429.

**Snapshot:** a top-level `"attachments": [{"id","expenseId","deleted"}]`, attached rows only, deleted ones included. CSV is unchanged.

**Migration `V9__receipts.sql`:**
```sql
-- Receipt photos (Phase 7). The upload creates the row; attachment.added sets expense_id.
CREATE TABLE attachments (
    id          uuid PRIMARY KEY,
    group_id    uuid NOT NULL REFERENCES groups (id),
    expense_id  uuid REFERENCES expenses (id),
    uploaded_by uuid NOT NULL REFERENCES users (id),
    created_at  timestamptz NOT NULL DEFAULT now(),
    deleted_at  timestamptz
);
CREATE INDEX attachments_group_id ON attachments (group_id);
```

**drift (schemaVersion 8):**
- `attachments (id PK, groupId, expenseId, deleted bool default false)`;
- `pending_uploads (attachmentId PK, groupId, createdAt)`.

**Compatibility.** Old clients ignore `attachment.*` and the new snapshot key. An old client's edit of an itemized expense clears `split` (Phase 3 rule 10).

### Shared fixtures
- **`app/test/fixtures/itemized-cases.json`** (Dart only; there is no server twin):
```json
{"_doc": "Itemized split cases. Minor-unit integers. Each line splits equally between its memberIds (remainder +1 to memberId ascending); tax + tip - discount is spread by subtotal: floor first, then +1 to members with a subtotal > 0 in memberId ascending order. Missing tax/tip/discount = 0.",
 "cases": [
  {"name": "shared line, tax and tip spread by subtotal",
   "bill": {"lines": [{"name": "Burger", "amount": 1450, "memberIds": ["a"]}, {"name": "Salad", "amount": 1100, "memberIds": ["b"]},
                      {"name": "Fries to share", "amount": 700, "memberIds": ["c", "a", "b"]}, {"name": "Soda", "amount": 300, "memberIds": ["c"]}],
            "tax": 284, "tip": 600, "discount": 0},
   "expectedTotal": 4434, "expected": {"a": 2104, "b": 1665, "c": 665}},
  {"name": "discount outweighs tax: the net is taken off by subtotal",
   "bill": {"lines": [{"name": "Pizza", "amount": 1000, "memberIds": ["a"]}, {"name": "Pasta", "amount": 2000, "memberIds": ["b"]}], "tax": 120, "tip": 0, "discount": 500},
   "expectedTotal": 2620, "expected": {"a": 873, "b": 1747}},
  {"name": "zero-decimal currency, service charge only, .5 tie goes to memberId ascending",
   "bill": {"lines": [{"name": "Ramen", "amount": 980, "memberIds": ["a"]}, {"name": "Gyoza", "amount": 450, "memberIds": ["b", "a"]}], "tip": 143},
   "expectedTotal": 1573, "expected": {"a": 1326, "b": 247}},
  {"name": "a line with nobody on it is rejected",
   "bill": {"lines": [{"name": "Wine", "amount": 2400, "memberIds": []}], "tax": 0, "tip": 0, "discount": 0}, "error": "UNASSIGNED_ITEM"}
 ]}
```
  Further cases:
  - "one line one person";
  - "zero-amount line: its member gets no tax or tip";
  - "net zero (tip equals discount)";
  - "everything discounted to zero";
  - "tip on zero subtotal" → `ZERO_SUBTOTAL`;
  - "discount larger than the bill" → `NEGATIVE_TOTAL`;
  - "negative tax" → `NEGATIVE_AMOUNT`.
- **`shared/sync-cases.json`:** `_doc` default `attachments=[]`, and both `actual()` builders add `attachments`.
```json
{"name": "attachment added then deleted; re-add of the same id and unknown expense are ignored",
 "events": [
  {"seq": 1, "clientId": "e1", "type": "member.added", "payload": {"memberId": "m1", "name": "Anna", "userId": null}},
  {"seq": 2, "clientId": "e2", "type": "expense.created", "payload": {"expenseId": "x1", "description": "Dinner", "amount": 1000, "currency": "EUR", "fxRateToDefault": null, "paidBy": "m1", "date": "2026-10-10", "category": null, "shares": [{"memberId": "m1", "amount": 1000}]}},
  {"seq": 3, "clientId": "e3", "type": "attachment.added", "payload": {"attachmentId": "a1", "expenseId": "x1"}},
  {"seq": 4, "clientId": "e4", "type": "attachment.added", "payload": {"attachmentId": "a2", "expenseId": "x9"}},
  {"seq": 5, "clientId": "e5", "type": "attachment.deleted", "payload": {"attachmentId": "a1"}},
  {"seq": 6, "clientId": "e6", "type": "attachment.added", "payload": {"attachmentId": "a1", "expenseId": "x1"}}],
 "expected": {"members": [{"id": "m1", "name": "Anna", "userId": null}],
  "expenses": [{"id": "x1", "description": "Dinner", "amount": 1000, "currency": "EUR", "fxRateToDefault": null, "paidBy": "m1", "date": "2026-10-10", "category": null, "deleted": false, "shares": [{"memberId": "m1", "amount": 1000}]}],
  "payments": [], "attachments": [{"id": "a1", "expenseId": "x1", "deleted": true}]}}
```
  Further cases:
  - "itemized split survives a description-only update";
  - "itemized replaced by a newer itemized update" (`permute: true`);
  - "attachment.deleted for an unknown id is ignored";
  - "attachment on a deleted expense is kept".
- **`shared/activity-cases.json`:** `receipt_added`, `receipt_removed`; an `expense.updated` that changes only `split` (item names) → "split".
- **App only: `app/test/fixtures/receipts/*.json`.** Hand-made OCR line sets:
  - US diner (tax line, card slip below the total);
  - Italian trattoria (IVA included, coperto, "TOTALE EURO");
  - German supermarket (VAT letters, a negative Rabatt, `1.234,50`);
  - JPY café (0 decimals, `¥1,200`).

### Hyojun's part
None. The itemized split is Claude-owned. It reuses `computeSplit(equal)` and calls none of his Phase 3 or 4 functions, so Items works while his stubs still throw. Per-line weights ("2 of the 3 beers") would need his `shares` mode, so they are left out.

### Tests
- **Server** (Testcontainers + HTTP; `EVENSIES_STORAGE_DIR` is a temp directory per test):
  - **Upload:**
    - 201, then a retry → 200 with unchanged files;
    - other group's id → 409;
    - non-member → 403;
    - PNG → `NOT_JPEG`; 5000 px → `IMAGE_TOO_LARGE`;
    - 2.5 MB → 413, 6 MB → 413;
    - the 61st upload in an hour → 429.
  - **Download:** full and thumb bytes and headers; non-member → 403; other group → 404; after `attachment.deleted` → 404 and the files are gone.
  - **Events:**
    - attach without upload → `ATTACHMENT_NOT_UPLOADED`;
    - uploaded in A, attached in B → the same error;
    - re-attach to a different expense → 400;
    - the 11th → 409;
    - `expense.created` + `attachment.added` in one batch passes.
  - **Itemized shape:** a good bill round-trips through the snapshot; empty `memberIds` → `VALIDATION`; a non-member → `UNKNOWN_MEMBER`; 201 lines → `VALIDATION`; a shares-only update → `split: null`.
  - **ZIP:** `group.json` plus live receipts only; non-member → 403.
- **App:**
  - `itemized_test.dart` (+ `percentOf`, .5 rounds up);
  - `receipt_parser_test.dart`;
  - the new sync cases;
  - `SyncService` with a fake API: a pending upload holds back only the outbox from its own event on; a failed upload is retried; a missing file drops the event; removing a pending receipt sends nothing;
  - `GroupStateStore` round trip; the drift 6→7 migration keeps rows;
  - Itemize screen: assigning, "All", Done gating, tip % recalculated, totals;
  - Expense form Items mode: read-only amount, sends split + shares, switching to Exact sends `split: null`, reopens in Items, a mismatched bill reopens in Exact;
  - `remapForMove` with itemized memberIds.
- **Simulator** (light and dark):
  1. Drag three test receipts we make ourselves (no card numbers; US, Italian, JPY) into Photos.
  2. Scan from the library, assign people, save.
  3. A second user pulls the snapshot and downloads the thumbnail, and the shares match.
  4. Stop the server, attach a photo, restart: it uploads and the event follows.
  5. Check zoom, share and remove; open the ZIP in Files.

  Camera capture is checked on a device after parity.

### Depends on other phases
- **Phase 6:** `FileStore`, `Jpeg.clean`, `prepareJpeg`, `image_picker`, the volume and its backup, `remapForMove`.
- **Phase 2:** the expense screen, activity and push.
- **Phase 3:** `SplitSpec` and its rules; no Hyojun function is called.
- **Phase 8:** its daily sweep deletes uploads never attached after 7 days, and files of deleted rows left behind by a crash.
- **Phase 9:** ML Kit has no web build, so Scan is hidden on web.
- **Phase 10:** group delete keeps receipts (restore must work). The account export is JSON only; receipts come from the per-group ZIP.

### Left out (deliberately)
- PDF or e-mailed receipts.
- Cloud OCR (it costs money and sends receipts to a third party).
- CJK and Devanagari models (several MB each; prices still read).
- Per-line weights.
- Edge detection and auto-crop.
- Date extraction (formats like 03/04/2026 are ambiguous across countries).
- Full-resolution originals (2048 px is readable).
- Server-made thumbnails.
- Receipts on payments.

### Cost
- **Now: €0.** Files sit on the existing server's disk.
- **Growth:** about 0.5 MB per receipt, so 50,000 receipts ≈ 25 GB.
- **Backup:** R2 is free up to 10 GB, then $0.015/GB/month (about $0.25/month at 25 GB).
- **Past about 70% disk**, propose one of these with its cost:
  - a Hetzner Volume, about €0.05/GB/month (≈ €2.50 for 50 GB);
  - Hetzner Object Storage, about €5/month including 1 TB.
- **Self-hosters** use their own disk.

### Done when
- In a group of two, one person scans a receipt from the library, itemizes it with tax and tip, and saves; the other sees the photo and the same amounts.
- A receipt added offline arrives after reconnecting.
- A removed receipt is gone from the server disk.
- The ZIP contains the receipts.
- All fixture suites and tests pass, including old-client cases (no split hint, unknown `attachment.*`).

---
