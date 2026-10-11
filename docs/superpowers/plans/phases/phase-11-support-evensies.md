# Phase 11 design — Support Evensies (tips) and the official-server app

Decided by Hyojun on 2026-10-11: the code moves from AGPL-3.0 to FSL-1.1-ALv2 with a trademark policy, and Evensies is funded by optional tips instead of ads or a paid tier. **Cost: 0** to build; Apple and Google keep 15% of each tip under their small-business programmes.

### What users get
1. **Settings → Support Evensies**: a short note ("Evensies has no ads and no paywall. If it saved you an argument, you can leave a tip."), three buttons with store-localised prices (Small, Medium, Large; around $2.99 / $4.99 / $9.99), and a thank-you message after a tip. Tips can be given any number of times.
2. **Nothing is unlocked by a tip.** No badge, no feature, no server state. The thank-you is local only.
3. **The official app connects only to the official server.** The "Server URL" field in Settings exists only in debug builds and in builds made with `--dart-define=EVENSIES_ALLOW_CUSTOM_SERVER=true`; release builds always use `Env.defaultServerUrl`. A stored custom URL from an earlier build is ignored in a release build.

### How (app)
- Package `in_app_purchase` (Flutter team). Products are **consumables**: `evensies.tip.small`, `evensies.tip.medium`, `evensies.tip.large` (same ids on both stores).
- A small `TipStore` wrapper (`app/lib/features/support/tip_store.dart`) with `Future<List<TipProduct>> load()` and `Future<void> buy(TipProduct)` plus a `Stream<TipResult>` (success / pending / cancelled / error), so widget tests use a fake. It listens to `purchaseStream` from app start (purchases that finish while the app is closed are completed on next launch) and always calls `completePurchase` for `pendingCompletePurchase` items.
- `SupportScreen` (`app/lib/features/support/support_screen.dart`): loading, store unavailable ("Tips aren't available on this device" — simulator without a StoreKit config, web, a store outage), products, pending ("Waiting for confirmation…" for Ask to Buy / slow cards), success (thank-you card), cancelled (silent), error (SnackBar). Light and dark mode, large text.
- Route `/settings/support`; a Settings tile "Support Evensies" with a heart icon, shown on iOS and Android only (hidden on web, Phase 9).
- Server URL: `Env.allowCustomServer = kDebugMode || bool.fromEnvironment('EVENSIES_ALLOW_CUSTOM_SERVER')`. `ServerUrl.build()` returns `Env.defaultServerUrl` when it is false; the Settings field is hidden. Docs (`README`, `docs/API.md` env table) say how to build a renamed app for another server.
- iOS local testing: `app/ios/Runner/Tips.storekit` (StoreKit configuration with the three consumables), selected in the Runner scheme so the simulator shows prices and completes purchases without App Store Connect.

### How (server)
Nothing. Tips are consumables with no entitlement, so there is no receipt validation and no new endpoint.

### Docs
- `docs/privacy.md`: tips are processed by Apple / Google; Evensies receives no payment details, only the stores' anonymous sales reports.
- `docs/store/listing.md`: In-App Purchases section with the three tips; review notes explain that tips unlock nothing.
- App Store privacy label stays "Data Not Collected" for purchases (Apple handles them).

### Owner-only setup (release time)
- App Store Connect: accept the Paid Applications agreement, add banking and tax info, create the three consumable IAPs with review screenshots, enrol in the App Store Small Business Program (15%).
- Play Console: set up the payments profile (merchant account), create the three in-app products.

### Tests
- Widget tests with a fake `TipStore`: products listed in order with store prices; tapping buys the right id; pending → waiting text; success → thank-you; cancelled → no message; error → SnackBar; store unavailable → message, no buttons; tile hidden on web.
- Unit test: `ServerUrl` ignores a stored custom URL when `allowCustomServer` is false, honours it when true.
- Simulator: Settings → Support Evensies with `Tips.storekit`, buy each tip, thank-you shows; light and dark.

### Done when
- In the simulator, the three tips show prices from the StoreKit file, a purchase completes and shows the thank-you, and a second tip of the same size works.
- A release-mode build has no Server URL field and talks only to the official server.
- All tests green; privacy policy and store listing updated.
