# HANDOFF — 효준님이 돌아와서 읽을 파일 (2026-10-10)


## 효준님 차례 — Splitwise parity (3·4단계 몫 전부 완료, 2026-10-11. 새 몫이 생기면 이 표에 추가)
규칙은 각 함수 바로 위 doc comment에 다 적혀 있습니다. 테스트: `cd app && flutter test test/hyojun/fx_test.dart test/balances_test.dart`
5단계(분류·검색·인사이트·수정 기록·상세 화면)는 효준님 몫이 없습니다. 남은 것은 4단계 환산 두 함수(6–7)와 끝난 TODO 문구 정리(8)뿐입니다.

| # | 파일:줄 | 함수 | 쓸 것 | 통과시킬 것 |
|---|---|---|---|---|
| 1 | `app/lib/domain/split.dart:38` | `computeSplit` (percent 나머지) | ✅ 완료 (커밋됨) | 통과 |
| 2 | `app/lib/domain/split.dart:38` | `computeSplit` (shares) | ✅ 완료 (커밋됨) | 통과 (+ 반올림 케이스 1개 추가) |
| 3 | `app/lib/domain/split.dart:38` | `computeSplit` (adjustment) | ✅ 완료 (커밋됨) | 통과 |
| 4 | `app/lib/domain/settlement.dart:52` | `computeBalances` (여러 명이 낸 지출·환불) | ✅ 완료 (커밋됨) | 통과. 5단계 `test/insights_test.dart:63`의 "올타임 잔액 변화 = 내 잔액" 검사도 `shared/totals-cases.json` 4케이스 전부(환불 3·4번 포함) 이 함수로 돌아갑니다 |
| 5 | `app/test/hyojun/settlement_test.dart` | 테스트 | ✅ 완료 | 통과 |
| 6 | `app/lib/domain/fx.dart` | `convertAmount` (Phase 4) | ✅ 완료 (커밋됨, Kotlin `money/Fx.kt` 이식) | `shared/fx-cases.json` 케이스 1–10 통과 |
| 7 | `app/lib/domain/fx.dart` | `convertExpense` (Phase 4) | ✅ 완료 (커밋됨, Kotlin 이식) | 케이스 11–20 통과 |
| 8 | `split.dart`, `settlement.dart`, `fx.dart` | 정리 | ✅ 효준님 요청으로 이름·중복 정리(동작 동일, 테스트로 확인), 끝난 TODO 문구 삭제 | 전부 통과 |

끝나면 통과한 케이스의 `"pending": "hyojun"`를 `shared/fx-cases.json`에서 지우세요. Kotlin 이식(`server/src/main/kotlin/dev/nariinfo/evensies/money/Fx.kt:22-23`·`:31-32`의 `TODO(...)`, 서버 `FxCasesTest` 20개가 지금 skip)은 Claude가 같은 push에 넣고, 효준님은 검토만 합니다.
6–7이 들어가면 따로 켤 것 없이(`fxReady`) 환율 있는 외화 지출이 그룹 통화 잔액·인사이트 합계에 합쳐지고("Not converted" 카드에서 빠짐), Convert 시트와 "≈" 줄이 보입니다. 그때 Claude가 시뮬레이터에서 Convert 합치기, 홈 통화 "≈ $", 로그인 화면의 홈 통화 단계, 인사이트 합계를 다시 확인합니다.
**확인 방법:** `shared/fx-cases.json` 4–23줄의 `, "pending": "hyojun"`을 지운 뒤 `flutter test test/hyojun/fx_test.dart`. pending이 남아 있으면 실패해도 skip으로 보입니다.

## 지금 상태 (전부 확인됨)
- **서버**(Spring Boot 4.1.1 + Kotlin): 인증(dev/Apple/Google/refresh), 그룹·초대, 이벤트 push/pull/snapshot, Kotlin 적용기, 내보내기·Splitwise 가져오기, FCM(자격 증명 없으면 no-op). `./gradlew test` **28개 통과**.
- **앱**(Flutter 3.41): drift 로컬 DB, API 클라이언트(토큰 갱신), 오프라인 outbox → push → pull 동기화, 화면 7개, 딥링크. `flutter analyze` 0건, `flutter test --exclude-tags hyojun` **18개 통과**, iOS 시뮬레이터 빌드·실행 확인.
- **시뮬레이터 E2E 확인**: dev 로그인 → 그룹 생성 → 자리표시 멤버 추가 → 지출 입력(서버 seq 4로 push됨) → 두 번째 사용자가 curl로 초대 참여·지출 push → 앱 복귀 시 pull로 "Lunch paid by Ben" 표시. 잔액 탭은 설계대로 "정산 로직 미구현" 칩.
- 커밋: `git log --oneline` 참고. 원격 저장소는 아직 없음(아래 "남은 설정").

## 핵심 로직 4곳 — 완료 (2026-10-11)
| # | 내용 | 작성 | 상태 |
|---|---|---|---|
| 1 | 분할 계산 Dart `app/lib/domain/split.dart` | 효준님 | 테스트 15개 통과 |
| 2 | 분할 계산 Kotlin `money/Split.kt` | Claude 이식, 효준님 검토 | 14개 통과 |
| 3 | 잔액·부채 단순화 Dart `app/lib/domain/settlement.dart` | 효준님 | 23개 통과 |
| 4 | `app/lib/domain/settlement.dart` | `computeBalances` (여러 명이 낸 지출·환불) | ✅ 완료 (커밋됨) | 통과 |
| 5 | `app/test/hyojun/settlement_test.dart` | 테스트 | ✅ 완료 | 통과 |
| 6 | `app/lib/domain/fx.dart` | `convertAmount` (Phase 4) | ✅ 완료 (커밋됨, Kotlin `money/Fx.kt` 이식) | `shared/fx-cases.json` 케이스 1–10 통과 |

임시 경로(`NAIVE_APPLY`, `pushNaive`, `tally.sync.naive`, hyojun 태그)는 전부 제거됐고 CI는 모든 테스트를 기본으로 돌립니다.
면접에서 설명할 부분: 1·3·6과 `docs/API.md`의 적용 규칙 1~5(왜 삭제가 이기나, 왜 seq 순서인가).

## 실행 방법
```bash
# 1) DB
docker compose -f deploy/docker-compose.dev.yml up -d
# 2) 서버 (JDK 21 arm64 필수 — 기본 java는 17이라 실패함)
cd server && export JAVA_HOME=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home
./gradlew --no-daemon bootRun --args='--spring.profiles.active=dev'
# 3) 앱 (iPhone 16 Pro 시뮬레이터, 영어 키보드로 설정돼 있음)
cd app && flutter run -d 82A31F6F-D3CC-44C1-8EBF-47ACA260BA2D \
  --dart-define=DEV_LOGIN=true --dart-define=EVENSIES_SERVER_URL=http://localhost:8080
```
dev 프로필은 `/auth/dev`(이름만으로 로그인)를 켭니다. 운영에서는 절대 쓰지 않습니다.

## 남은 설정 (효준님만 할 수 있는 것)
1. **GitHub 공개 저장소** `devyourown/evensies` 만들고 push. CI는 `.github/workflows/ci.yml`에 있음.
2. **Apple**: App ID `dev.nariinfo.evensies`에 Sign in with Apple 활성화, Xcode에서 capability 추가. 서버 `EVENSIES_APPLE_CLIENT_ID`.
3. **Google**: Firebase 프로젝트 → iOS/Android 앱 등록 → `GoogleService-Info.plist`·`google-services.json` 넣기(둘 다 .gitignore 대상으로 두세요). OAuth 클라이언트 ID → 서버 `EVENSIES_GOOGLE_CLIENT_IDS`. FCM 서비스 계정 JSON → `deploy/secrets/fcm.json`.
4. **도메인·호스팅**: Hetzner CX22 생성 → `deploy/.env` 채우기 → `docker compose up -d`. 딥링크용 `apple-app-site-association`·`assetlinks.json`은 출시 직전에(앱 `README.md` 참고).
5. **제품명·스토어**: 이름 결정 → 번들 ID 유지 가능. 개인정보 처리방침 `docs/privacy.md`를 웹에 올리고 스토어에 링크.

## 알려진 단순화 (출시 1에서 의도한 것)
- 송금(Payment)은 그룹 기본 통화로만 기록. 외화 지출은 환율 없으면 잔액에서 제외되고 경고 행으로 표시.
- 로그인 전 둘러보기 없음(로컬 데이터가 없으면 볼 게 없어서). `router.dart`에서 완화 가능.
- `GroupStateStore.save`는 동기화마다 그룹 행 전체를 다시 씀(`ponytail:` 표시). 출시 1 규모에서는 충분.
- Splitwise 가져오기: 결제자는 순액이 가장 큰 열, 결제자가 여러 명인 행은 거부.

## 문서
- 계약: `docs/API.md` · 스펙: `docs/superpowers/specs/2026-10-10-tally-release1-design.md` · 계획: `docs/superpowers/plans/2026-10-10-tally-release1.md`
- 서버 상세: `server/README.md` · 앱 상세: `app/README.md`

## 운영 주소 (2026-10-11 결정)
- 서버: **https://evensies.nariinfo.dev** (nariinfo.dev 서브도메인, 별도 도메인 등록 없음). 앱 기본 서버 URL과 `deploy/.env.example`에 반영됨.
- 필요한 DNS: `evensies` A 레코드 → Hetzner 서버 IP (nariinfo.dev를 관리하는 DNS에서). Caddy가 Let's Encrypt 인증서를 자동 발급한다.
- 개발 실행은 그대로 `--dart-define=EVENSIES_SERVER_URL=http://localhost:8080`.
