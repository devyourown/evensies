# HANDOFF — 효준님이 돌아와서 읽을 파일 (2026-10-10)

## 지금 상태 (전부 확인됨)
- **서버**(Spring Boot 4.1.1 + Kotlin): 인증(dev/Apple/Google/refresh), 그룹·초대, 이벤트 push/pull/snapshot, Kotlin 적용기, 내보내기·Splitwise 가져오기, FCM(자격 증명 없으면 no-op). `./gradlew test` **28개 통과**.
- **앱**(Flutter 3.41): drift 로컬 DB, API 클라이언트(토큰 갱신), 오프라인 outbox → push → pull 동기화, 화면 7개, 딥링크. `flutter analyze` 0건, `flutter test --exclude-tags hyojun` **18개 통과**, iOS 시뮬레이터 빌드·실행 확인.
- **시뮬레이터 E2E 확인**: dev 로그인 → 그룹 생성 → 자리표시 멤버 추가 → 지출 입력(서버 seq 4로 push됨) → 두 번째 사용자가 curl로 초대 참여·지출 push → 앱 복귀 시 pull로 "Lunch paid by Ben" 표시. 잔액 탭은 설계대로 "정산 로직 미구현" 칩.
- 커밋: `git log --oneline` 참고. 원격 저장소는 아직 없음(아래 "남은 설정").

## 효준님 몫 — 이 순서로 (각 15~45분, 총 약 3시간)
핵심 로직 4곳 + 테스트 단언. 전부 `TODO(효준)`으로 표시돼 있고, 그 자리가 비어도 앱은 돌아갑니다.

| # | 할 일 | 파일:줄 | 검증 명령 |
|---|---|---|---|
| 1 | 분할 계산(Dart) | `app/lib/domain/split.dart:28` (규칙은 :13 주석) | `cd app && flutter test test/hyojun/split_test.dart` — 단언은 `test/hyojun/split_test.dart:20,23,31,35,39` |
| 2 | 분할 계산(Kotlin) — 1과 같은 규칙 | `server/src/main/kotlin/dev/nariinfo/tally/money/Split.kt:26` | `cd server && ./gradlew test -PincludeHyojun --tests '*SplitTest*'` — 단언 `SplitTest.kt:31,40` |
| 3 | 잔액 + 부채 단순화(Dart) | `app/lib/domain/settlement.dart:40` (balances), `:52` (simplify) | `flutter test test/hyojun/settlement_test.dart` — 단언 `:33,39,47,51,55,58,61` |
| 4 | 잔액 + 부채 단순화(Kotlin) | `money/Settlement.kt:17`, `:30` | `./gradlew test -PincludeHyojun --tests '*SettlementTest*'` — 단언 `SettlementTest.kt:32,40,47,53,59` |
| 5 | 이벤트 적용기(Dart) | `app/lib/data/sync/apply_event.dart:25` (규칙 1~5는 :5 주석, Kotlin 참고 구현은 `server/.../sync/EventApplier.kt`) | `flutter test test/hyojun/apply_event_test.dart` — 단언 `:19,24,30,39`. 통과하면 `apply_event_naive.dart` 삭제하고 `--dart-define=NAIVE_APPLY` 없이 실행 |
| 6 | push 트랜잭션(Kotlin): 잠금·중복 제거·seq 부여 | `server/.../sync/EventService.kt:78` (6단계 설명 :56~75, 참고용 `pushNaive` :81~100) | `./gradlew test -PincludeHyojun --tests '*EventSyncTest*'` (duplicatePushReturnsSameSeq). 통과하면 `pushNaive` 삭제, `application-dev.yml`과 `IntegrationTestBase.kt:16`의 `tally.sync.naive=true` 제거 |

규칙 요약(스펙 §5·§6): 금액은 정수, 나머지는 memberId 오름차순으로 앞에서부터 1씩, 탐욕법은 절댓값 큰 채권자·채무자부터(동률은 memberId 오름차순), 송금 ≤ n−1, 적용기는 순수 함수·멱등·삭제가 이김·없는 대상 무시.

전부 끝나면: CI에서 `TALLY_INCLUDE_HYOJUN=true` 저장소 변수를 켜면 hyojun 태그 테스트도 돌아갑니다.

## 실행 방법
```bash
# 1) DB
docker compose -f deploy/docker-compose.dev.yml up -d
# 2) 서버 (JDK 21 arm64 필수 — 기본 java는 17이라 실패함)
cd server && export JAVA_HOME=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home
./gradlew --no-daemon bootRun --args='--spring.profiles.active=dev'
# 3) 앱 (iPhone 16 Pro 시뮬레이터, 영어 키보드로 설정돼 있음)
cd app && flutter run -d 82A31F6F-D3CC-44C1-8EBF-47ACA260BA2D \
  --dart-define=DEV_LOGIN=true --dart-define=TALLY_SERVER_URL=http://localhost:8080
```
dev 프로필은 `/auth/dev`(이름만으로 로그인)와 naive sync를 켭니다. 운영에서는 절대 쓰지 않습니다.

## 남은 설정 (효준님만 할 수 있는 것)
1. **GitHub 공개 저장소** `devyourown/tally` 만들고 push. CI는 `.github/workflows/ci.yml`에 있음.
2. **Apple**: App ID `dev.nariinfo.tally`에 Sign in with Apple 활성화, Xcode에서 capability 추가. 서버 `TALLY_APPLE_CLIENT_ID`.
3. **Google**: Firebase 프로젝트 → iOS/Android 앱 등록 → `GoogleService-Info.plist`·`google-services.json` 넣기(둘 다 .gitignore 대상으로 두세요). OAuth 클라이언트 ID → 서버 `TALLY_GOOGLE_CLIENT_IDS`. FCM 서비스 계정 JSON → `deploy/secrets/fcm.json`.
4. **도메인·호스팅**: Hetzner CX22 생성 → `deploy/.env` 채우기 → `docker compose up -d`. 딥링크용 `apple-app-site-association`·`assetlinks.json`은 출시 직전에(앱 `README.md` 참고).
5. **제품명·스토어**: 이름 결정 → 번들 ID 유지 가능. 개인정보 처리방침 `docs/PRIVACY.md`를 웹에 올리고 스토어에 링크.

## 알려진 단순화 (출시 1에서 의도한 것)
- 송금(Payment)은 그룹 기본 통화로만 기록. 외화 지출은 환율 없으면 잔액에서 제외되고 경고 행으로 표시.
- 로그인 전 둘러보기 없음(로컬 데이터가 없으면 볼 게 없어서). `router.dart`에서 완화 가능.
- `GroupStateStore.save`는 동기화마다 그룹 행 전체를 다시 씀(`ponytail:` 표시). 출시 1 규모에서는 충분.
- Splitwise 가져오기: 결제자는 순액이 가장 큰 열, 결제자가 여러 명인 행은 거부.
- 서버 `pushNaive` 경로에서는 중복 clientId가 409 `DUPLICATE`(효준님 `push` 구현 전까지).

## 문서
- 계약: `docs/API.md` · 스펙: `docs/superpowers/specs/2026-10-10-tally-release1-design.md` · 계획: `docs/superpowers/plans/2026-10-10-tally-release1.md`
- 서버 상세: `server/README.md` · 앱 상세: `app/README.md`
