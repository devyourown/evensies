# Tally 출시 1 구현 계획

> **For agentic workers:** 이 계획은 2026-10-10 효준님 외출 중 한 세션에서 Claude가 골격 전체를 구현하고(병렬 서브에이전트: 서버·앱), 효준님 몫은 `TODO(효준)`로 남기는 방식으로 실행한다. 실행 방식은 효준님이 직접 지정했다("이번 세션에서 전부, 제가 해야 하는 부분만 남겨라").

**Goal:** Flutter 앱 + Spring Boot 서버가 iOS 시뮬레이터와 로컬 Docker PostgreSQL로 end-to-end 동작하는 골격. 핵심 로직 4곳은 비어 있어도 앱이 켜지고 화면을 오갈 수 있다.

**Architecture:** 오프라인 우선 앱(drift) + 이벤트 로그 동기화(서버 seq) + 서버도 같은 이벤트를 테이블에 반영. 계약은 `docs/API.md`, 공유 테스트는 `shared/*.json`.

**Tech Stack:** Flutter 3.41 / Dart 3.11, Riverpod, drift, go_router, dio · Spring Boot 4.1.1, Kotlin 2.3, Spring Data JDBC, PostgreSQL 16, Flyway, Spring Security(JWT), Testcontainers · Docker Compose · GitHub Actions

**Spec:** `docs/superpowers/specs/2026-10-10-tally-release1-design.md`

## Global Constraints
- 금액은 정수(최소 단위). 분할은 멤버별 확정 금액으로 저장. 통화 자릿수는 `shared/currencies.json`.
- 이벤트 멱등: `UNIQUE(group_id, client_id)`. seq는 그룹별 단조 증가, 그룹 행 `FOR UPDATE`.
- 충돌 규칙: 필드 단위 LWW, 삭제가 이김, 없는 대상은 무시(`docs/API.md` 적용 규칙 1~5).
- 효준님 몫은 `TODO(효준)` 주석 + `UnimplementedError`/`TODO()`로 비워 둔다. 그 자리가 비어도 앱·서버가 기동되어야 한다(해당 기능만 "미구현" 표시).
- 서버 JDK: `/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home` (arm64). `./gradlew --no-daemon`.
- 라이선스 AGPL-3.0. 분석 SDK 없음. 새 외부 의존성은 스펙에 적힌 것만.

## Review Focus
1. 두 사람이 오프라인에서 같은 지출을 고치고 동시에 push → 필드 단위 병합, 아무 입력도 사라지지 않음 (서버 통합 테스트 `EventSyncTest`, 앱 `apply_event_test`).
2. 같은 push를 네트워크 재시도로 두 번 보냄 → 지출 1개, 같은 seq 반환 (`EventSyncTest.duplicatePushReturnsSameSeq`).
3. KRW 같은 0자릿수 통화와 EUR 2자릿수가 한 그룹에 섞임 → 표시·입력·내보내기에서 자릿수가 맞음 (`money_format_test`).
4. 그룹 밖 memberId를 payload에 넣은 push → 400, 아무것도 저장 안 됨 (`EventValidationTest`).
5. 계정 삭제 후 그 사람이 낸 지출이 남의 그룹 잔액에 남아 있음 (`AccountDeletionTest`).

## 파일 구조
```
tally/
  shared/        split-cases.json settlement-cases.json sync-cases.json currencies.json
  docs/          API.md, specs/, plans/
  deploy/        docker-compose.yml (server+postgres+caddy), docker-compose.dev.yml (postgres만), Caddyfile, .env.example
  server/        Spring Boot (아래)
  app/           Flutter (아래)
  .github/workflows/ci.yml
  HANDOFF.md     효준님이 돌아와서 읽을 단 하나의 파일
```

### server/src/main/kotlin/dev/nariinfo/tally/
```
TallyServerApplication.kt
config/   SecurityConfig.kt JwtService.kt AppProperties.kt JacksonConfig.kt
auth/     AuthController.kt AuthService.kt AppleTokenVerifier.kt GoogleTokenVerifier.kt DevLogin.kt UserRepository.kt User.kt RefreshTokenRepository.kt
group/    GroupController.kt GroupService.kt Group.kt Member.kt GroupRepository.kt MemberRepository.kt InviteController.kt
sync/     EventController.kt EventService.kt (push 트랜잭션: TODO(효준) 잠금·중복·seq)  Event.kt EventRepository.kt
          EventApplier.kt (Kotlin 적용기, Claude 작성) SnapshotService.kt
money/    Money.kt (통화 자릿수) Split.kt (TODO(효준)) Settlement.kt (TODO(효준))
export/   ExportController.kt CsvExporter.kt SplitwiseImporter.kt
push/     FcmNotifier.kt (자격 증명 없으면 no-op)
common/   ApiError.kt GlobalExceptionHandler.kt RateLimiter.kt
resources/ application.yml, db/migration/V1__init.sql
test/     SplitTest.kt SettlementTest.kt (shared JSON, TODO(효준) 단언) EventApplierTest.kt (shared sync JSON)
          EventSyncTest.kt EventValidationTest.kt AccountDeletionTest.kt AuthTest.kt (Testcontainers + 실제 HTTP)
```

### app/lib/
```
main.dart app.dart router.dart
core/      money.dart (통화 자릿수·포맷) ids.dart (uuid) env.dart (서버 주소, DEV_LOGIN)
data/db/   database.dart (drift 테이블: groups members expenses expense_shares payments outbox sync_state session)
data/api/  api_client.dart (dio, 토큰 갱신 인터셉터) dto.dart
data/sync/ sync_service.dart (push outbox → pull → applyEvent 저장) apply_event.dart (TODO(효준)) event_types.dart
domain/    split.dart (TODO(효준)) settlement.dart (TODO(효준)) models.dart
features/  auth/ groups/ group_detail/ expense_form/ settle/ members/ settings/  (화면 7개)
test/      split_test.dart settlement_test.dart apply_event_test.dart (shared JSON) money_format_test.dart expense_form_test.dart
```

## 작업 (실행 순서)
- [x] T0 스펙·계약·공유 JSON (`docs/API.md`, `shared/*.json`)
- [ ] T1 서버 (서브에이전트 A): Flyway 스키마, 인증(dev/apple/google/refresh), 그룹·초대, 이벤트 push/pull/snapshot, Kotlin 적용기, 내보내기·가져오기, FCM no-op, 테스트 전부. 효준님 몫: `Split.kt`·`Settlement.kt` 본문, `EventService.push` 트랜잭션 본문, 테스트 단언.
- [ ] T2 앱 (서브에이전트 B): drift DB, API 클라이언트, 동기화 서비스, 화면 7개, dev 로그인 버튼, 테스트 뼈대. 효준님 몫: `split.dart`·`settlement.dart`·`apply_event.dart` 본문, 테스트 단언.
- [ ] T3 deploy/ (Docker Compose, Caddy, Dockerfile), CI, README(지속 가능 규칙), LICENSE, 개인정보 처리방침 초안
- [ ] T4 통합: Docker PostgreSQL → 서버 기동(dev-login) → iOS 시뮬레이터에서 앱 → 그룹 생성·멤버 추가·지출 입력·동기화 확인(핵심 로직이 비어 있는 곳은 "미구현" 배너)
- [ ] T5 HANDOFF.md: 효준님이 할 일 순서(파일·줄·검증 명령), 시뮬레이터 실행법, 남은 설정(Apple/Google/FCM/도메인)
