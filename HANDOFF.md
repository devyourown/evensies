# HANDOFF — 효준님이 돌아와서 읽을 파일 (2026-10-10)


## 효준님 차례 — Splitwise parity (HEAD 기준, 2026-10-12. 새 몫이 생기면 이 표에 추가)
규칙은 각 함수 바로 위 doc comment에 다 적혀 있습니다. 테스트: `cd app && flutter test test/hyojun/ test/balances_test.dart test/overview_test.dart test/split_form_test.dart test/group_settings_test.dart`
5단계(분류·검색·인사이트·상세 화면), 6단계(친구·전체 잔액·사진·알림·송금 기록), 7단계(영수증·스캔·항목별 분할·친구 화면의 그룹 거래·송금 복원), 8단계(반복 지출·서버 스케줄러·미첨부 영수증 정리), 9단계(웹 앱·13개 언어·지역별 금액/날짜 표기·홈 화면 위젯·화면 모드·앱 잠금)는 효준님 몫이 없습니다. 8단계 반복분은 템플릿에 저장된 멤버별 최종 금액을 그대로 복사하므로 서버가 분할을 다시 계산하지 않고, 외화 반복분은 환율만 그날 값(`FxService.crossRate`, 서버 `recurrence/RecurrenceScheduler.kt`)으로 바꿉니다. 항목별 분할 `computeItemizedSplit`(`app/lib/domain/itemized.dart`)은 Claude 몫이고 줄마다 `computeSplit`의 equal 모드(1단계부터 있던 부분)만 씁니다. 9단계 위젯은 `computeOverview` 결과를 그대로 쓰고(`app/lib/features/home_widget/widget_summary.dart`), 금액 표기 `formatMoney`/`parseMoney`(`app/lib/core/money.dart`)는 Claude 몫입니다.
`grep -rn "TODO(효준)" app server` 결과는 3줄이고 전부 아래 10번의 테스트 건너뛰기 표시입니다: `app/test/hyojun/split_test.dart:12-13`, `server/src/test/kotlin/dev/nariinfo/evensies/SplitTest.kt:20`.

| # | 파일:줄 | 함수 | 쓸 것 | 통과시킬 것 |
|---|---|---|---|---|
| 1 | `app/lib/domain/split.dart:28` | `computeSplit` (percent 나머지) | ✅ 완료 (커밋됨) | 통과 |
| 2 | `app/lib/domain/split.dart:28` | `computeSplit` (shares) | ✅ 완료 (커밋됨) | 통과 (`shared/split-cases.json` shares 케이스, Kotlin `money/Split.kt`) |
| 3 | `app/lib/domain/split.dart:28` | `computeSplit` (adjustment) | ✅ 완료 (커밋됨) | 통과 |
| 4 | `app/lib/domain/settlement.dart:46` | `computeBalances` (여러 명이 낸 지출·환불) | ✅ 완료 (커밋됨) | 통과 (`shared/settlement-cases.json` 13케이스, `shared/totals-cases.json` 4케이스, Kotlin `money/Settlement.kt`). 6단계 `Balances.ofGroup`(서버 알림)·`computeOverview`(친구 탭·전체 카드·9단계 위젯)도 이 함수로 돌아갑니다 |
| 5 | `app/test/hyojun/settlement_test.dart:34` | 테스트 (`balances: …` fixture 루프) | ✅ 완료 | 통과 |
| 6 | `app/lib/domain/fx.dart:25` | `convertAmount` (Phase 4) | ✅ 완료 (커밋됨, Kotlin `money/Fx.kt` 이식) | `shared/fx-cases.json` 1–10 통과 |
| 7 | `app/lib/domain/fx.dart:44` | `convertExpense` (Phase 4) | ✅ 완료 (커밋됨, Kotlin 이식) | `shared/fx-cases.json` 11–20 통과. 6단계 `shared/overview-cases.json`의 환산 케이스(EUR로 합쳐지는 USD 지출)도 이 함수로 통과 |
| 8 | `split.dart`, `settlement.dart`, `fx.dart` | 정리 | ✅ 효준님 요청으로 이름·중복 정리(동작 동일, 테스트로 확인), 끝난 TODO 문구 삭제 | 전부 통과 |
| 9 | — | 6·7·8·9단계 | 없음 (집계 `app/lib/domain/overview.dart`·`server/.../money/Overview.kt`·`Balances.kt`, 항목별 분할 `app/lib/domain/itemized.dart`, 위젯 요약 `widget_summary.dart`는 Claude가 효준님 함수를 입력으로 씀) | `shared/overview-cases.json` 7케이스 Dart·Kotlin, `app/test/fixtures/itemized-cases.json` 14케이스(Dart만), `widget_summary_test.dart` 통과 |
| 10 | `app/lib/domain/split.dart:48-57` (작업 트리 16:34 버전, 아직 커밋 안 됨: 49–53줄 가중치, **54줄 합계 검사**, 55줄 몫, 18–20줄 doc comment. HEAD는 48–53줄) | `computeSplit` (percent 분기) | 토론에서 찾은 버그: 퍼센트 합이 허용 오차(±0.001) 안에서 100을 넘으면(예: 50.0009 + 50) HEAD의 `/ 100` 내림 합이 금액을 넘습니다. 16:34 버전은 가중치 `(pct × 10⁶).round()`(BigInt)와 `÷ 가중치 합`까지 맞습니다. **남은 것은 54줄 하나**: 조건이 거꾸로라 합 = 100인 정상 입력에서 throw하고 60 + 50 같은 틀린 입력은 통과시킵니다. `<= BigInt.from(1000)`을 `>= BigInt.from(1000)`으로 바꾸세요(HEAD의 `>= 0.001`, Kotlin `money/Split.kt:56`과 같은 ±0.001 = 가중치 1000). 그리고 18–20줄 doc comment의 "각 몫 = (amount * pct / 100).floor()"를 새 규칙(정수 가중치 ÷ 가중치 합, 나머지는 지금처럼 percent > 0 멤버에게 memberId 오름차순 +1)으로 고치세요. 이미 지킨 주의: 가중치는 버림이 아니라 `.round()`(버림은 2.01 × 10⁶ = 2009999.99…처럼 1이 모자람), 합계는 정확 비교(`!= 10⁸`)가 아니라 허용 오차 비교(33.33/33.33/33.34도 정상), `amount × 가중치`는 BigInt라 int 범위 걱정 없음. 확인: Claude가 별도 복사본에서 54줄만 바꾸고 `pending`을 지워 돌리면 `flutter test` 745개 통과(건너뜀 2개는 activity의 서버 전용 케이스) | `shared/split-cases.json:28` "percent within tolerance but over 100 still adds up" — 고친 뒤 그 줄 끝의 `, "pending": "hyojun"`을 지우면 Dart `test/hyojun/split_test.dart:13`과 Kotlin `SplitTest.kt:21`의 건너뛰기가 풀립니다. 지금 작업 트리에서 54줄 때문에 실패하는 8개(고치면 다시 통과): `test/hyojun/split_test.dart`의 `percent 50/30/20`·`percent with rounding remainder`·`percent must sum to 100`·`percent leftover skips 0% members`(fixture 11–13·29줄), `test/split_form_test.dart:247` "percent, with the live amount per row"·`:274` "editing reopens in the stored mode…"·`:315` "a percent default split pre-fills new expenses…", `test/group_settings_test.dart:308` "a default split that no longer adds up after someone left says so". Kotlin `money/Split.kt:54-59` PERCENT 이식은 Claude가 같은 push에 넣습니다 |

`"pending": "hyojun"`인 fixture 케이스는 10번의 1개뿐입니다. 3단계 규칙대로 Dart는 `skip: 'TODO(효준): pending fixture case'`, Kotlin은 `assumeTrue(case["pending"] == null)`로 **건너뜀**으로 보고되고(실패 아님), 서버 테스트 skip은 이 1개입니다.

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
| 5 | `app/test/hyojun/settlement_test.dart:34` | 테스트 (`balances: …` fixture 루프) | ✅ 완료 | 통과 |
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
5. **제품명·스토어**: 이름 결정 → 번들 ID 유지 가능. 개인정보 처리방침 `docs/privacy.md`를 웹에 올리고 스토어에 링크. App Store 개인정보 라벨·Play 데이터 보안 양식은 `docs/privacy.md` 기준으로 채우기(7단계: 영수증 사진은 그룹 멤버만, Android ML Kit은 익명 SDK 진단 정보만 Google로).

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
