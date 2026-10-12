# Phase 11 design — the official-server app and the store listing

Decided by Hyojun on 2026-10-11: the code moves from AGPL-3.0 to FSL-1.1-ALv2 with a trademark policy, and the store app talks only to the official server. **Cost: 0.**

**Optional tips (in-app purchases): Dropped (owner decision 2026-10-13).** No in-app purchases, no tip or support screen, no sponsor or donation link. Every feature stays free.

### What users get
1. **The official app connects only to the official server.** The "Server URL" field in Settings exists only in debug builds and in builds made with `--dart-define=EVENSIES_ALLOW_CUSTOM_SERVER=true`; release builds always use `Env.defaultServerUrl`. A stored custom URL from an earlier build is ignored in a release build (and kept, not deleted).
2. **Store listing** (`docs/store/listing.md`): App Store and Google Play texts that describe the current app.

### How (app)
- `Env.allowCustomServer = kDebugMode || bool.fromEnvironment('EVENSIES_ALLOW_CUSTOM_SERVER')`, read through `allowCustomServerProvider` so tests can see a release build. `ServerUrl.build()` returns `Env.defaultServerUrl` when it is false; the Settings field is hidden. Docs (`README`, `app/README.md`, `docs/API.md` 빌드 변수) say how to build a renamed app for another server.

### How (server)
Nothing.

### Tests
- Widget test: no Server URL field when `allowCustomServerProvider` is false, the field when true.
- Unit test: `ServerUrl` ignores a stored custom URL when `allowCustomServer` is false, honours it when true, and keeps the stored value.

### Done when
- A release-mode build has no Server URL field and talks only to the official server.
- All tests green; store listing updated.
