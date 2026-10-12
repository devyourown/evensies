# HANDOFF — 효준님이 돌아와서 읽을 파일 (2026-10-10)


## 효준님 차례 — Splitwise parity (HEAD 기준. 새 몫이 생기면 이 표에 추가)
규칙은 각 함수 바로 위 doc comment에 다 적혀 있습니다. 테스트: `cd app && flutter test test/hyojun/ test/balances_test.dart test/overview_test.dart test/split_form_test.dart test/group_settings_test.dart`
**지금 남은 효준님 몫은 없습니다.** 표의 1–10번은 모두 완료이고, 10단계(이메일·계정)도 새 몫을 만들지 않았습니다.
5단계(분류·검색·인사이트·상세 화면), 6단계(친구·전체 잔액·사진·알림·송금 기록), 7단계(영수증·스캔·항목별 분할·친구 화면의 그룹 거래·송금 복원), 8단계(반복 지출·서버 스케줄러·미첨부 영수증 정리), 9단계(웹 앱·13개 언어·지역별 금액/날짜 표기·홈 화면 위젯·화면 모드·앱 잠금), 10단계(이메일 로그인·요약 메일·초대 메일·그룹 종류/표지/삭제·차단·UPI)는 효준님 몫이 없습니다. 8단계 반복분은 템플릿에 저장된 멤버별 최종 금액을 그대로 복사하므로 서버가 분할을 다시 계산하지 않고, 외화 반복분은 환율만 그날 값(`FxService.crossRate`, 서버 `recurrence/RecurrenceScheduler.kt`)으로 바꿉니다. 10단계 반복 지출 알림 메일의 "Your share"도 템플릿에 저장된 몫입니다. 항목별 분할 `computeItemizedSplit`(`app/lib/domain/itemized.dart`)은 Claude 몫이고 줄마다 `computeSplit`의 equal 모드(1단계부터 있던 부분)만 씁니다. 9단계 위젯은 `computeOverview` 결과를 그대로 쓰고(`app/lib/features/home_widget/widget_summary.dart`), 금액 표기 `formatMoney`/`parseMoney`(`app/lib/core/money.dart`)는 Claude 몫입니다.
`grep -rn "TODO(효준)" app server` 결과는 3줄이고, 전부 `"pending": "hyojun"` 케이스를 건너뛰는 장치(주석·skip 문구)입니다: `app/test/hyojun/split_test.dart:12`(주석), `app/test/hyojun/split_test.dart:13`(`skip: … 'TODO(효준): pending fixture case'`), `server/src/test/kotlin/dev/nariinfo/evensies/SplitTest.kt:20`(주석). 지금 pending 케이스가 0개라서 아무것도 건너뛰지 않습니다.

| # | 파일:줄 | 함수 | 쓸 것 | 통과시킬 것 |
|---|---|---|---|---|
| 1 | `app/lib/domain/split.dart:29` | `computeSplit` (percent 나머지) | ✅ 완료 (커밋됨) | 통과 |
| 2 | `app/lib/domain/split.dart:29` | `computeSplit` (shares) | ✅ 완료 (커밋됨) | 통과 (`shared/split-cases.json` shares 7케이스, Kotlin `money/Split.kt`) |
| 3 | `app/lib/domain/split.dart:29` | `computeSplit` (adjustment) | ✅ 완료 (커밋됨) | 통과 (`shared/split-cases.json` adjustment 5케이스) |
| 4 | `app/lib/domain/settlement.dart:46` | `computeBalances` (여러 명이 낸 지출·환불) | ✅ 완료 (커밋됨) | 통과 (`shared/settlement-cases.json` 13케이스, `shared/totals-cases.json` 4케이스, Kotlin `money/Settlement.kt`). 6단계 `Balances.ofGroup`(서버 알림·10단계 요약 메일의 "Your balances")·`computeOverview`(친구 탭·전체 카드·9단계 위젯)도 이 함수로 돌아갑니다 |
| 5 | `app/test/hyojun/settlement_test.dart:34` | 테스트 (`balances: …` fixture 루프) | ✅ 완료 | 통과 |
| 6 | `app/lib/domain/fx.dart:25` | `convertAmount` (Phase 4) | ✅ 완료 (커밋됨, Kotlin `money/Fx.kt` 이식) | `shared/fx-cases.json` 1–10 통과 |
| 7 | `app/lib/domain/fx.dart:44` | `convertExpense` (Phase 4) | ✅ 완료 (커밋됨, Kotlin 이식) | `shared/fx-cases.json` 11–20 통과. 6단계 `shared/overview-cases.json`의 환산 케이스(EUR로 합쳐지는 USD 지출)도 이 함수로 통과 |
| 8 | `app/lib/domain/split.dart:29`, `settlement.dart:46`, `fx.dart:25`·`44` | 정리 (`computeSplit`·`computeBalances`·`convertAmount`·`convertExpense`) | ✅ 효준님 요청으로 이름·중복 정리(동작 동일, 테스트로 확인), 끝난 TODO 문구 삭제 | 전부 통과 |
| 9 | 호출하는 곳: `server/src/main/kotlin/dev/nariinfo/evensies/email/DigestBuilder.kt:42`, `money/Balances.kt:38`·`58`, `app/lib/domain/overview.dart:41`, `app/lib/domain/itemized.dart:82` | 6·7·8·9·10단계 (새 함수 없음) | 없음 (집계 `app/lib/domain/overview.dart`·`server/.../money/Overview.kt`·`Balances.kt`, 항목별 분할 `app/lib/domain/itemized.dart`, 위젯 요약 `widget_summary.dart`, 요약 메일 잔액 `server/.../email/DigestBuilder.kt:42`는 Claude가 효준님 함수를 입력으로 씀) | `shared/overview-cases.json` 7케이스 Dart·Kotlin, `app/test/fixtures/itemized-cases.json` 14케이스(Dart만), `widget_summary_test.dart`, `server/src/test/resources/digest-cases.json` 7케이스(서버만) 통과 |
| 10 | `app/lib/domain/split.dart:29` | `computeSplit` (percent) | ✅ 완료 (커밋 `0a4cea1`): 정수 가중치(퍼센트 × 10⁶) ÷ 가중치 합(BigInt), 허용 오차 ±0.001% 유지. Kotlin `money/Split.kt` 이식 | `shared/split-cases.json` 26케이스 전부 통과(percent 5), pending 0 |

`grep -r '"pending"' shared/` 결과는 0줄입니다. 3단계 규칙(pending 케이스는 Dart `skip: 'TODO(효준): pending fixture case'`, Kotlin `assumeTrue(case["pending"] == null)`로 **건너뜀** 보고)은 앞으로 새 몫이 생길 때를 위해 남겨 둡니다. 지금 서버 테스트 skip은 0개, 앱 skip 2개는 서버 전용 활동 문장 케이스(푸시 묶음·리마인더)입니다.

## 지금 상태 (2026-10-12, 10단계까지 — Splitwise parity 1–10단계 구현, 11단계 팁은 아직)
- **서버**(Spring Boot 4.1 + Kotlin 2.3, PostgreSQL, Flyway V1–V13): 로그인(dev·Apple·Google·이메일 6자리 코드, 토큰 갱신, 모든 기기에서 로그아웃), 그룹·초대(링크·코드·QR·이메일 초대와 3일 뒤 한 번 리마인더), 이벤트 push/pull/snapshot과 Kotlin 적용기(규칙 1–18), 활동 피드와 FCM 푸시(받는 사람 언어 13개), 친구·리마인더·프로필 사진·차단, 영수증 사진, 반복 지출 스케줄러와 반복 지출 알림 메일, 요약 메일(자동·매일·매주·매달·끄기), 환율(Frankfurter), 내보내기(CSV·JSON·영수증 ZIP·계정 전체 JSON)·Splitwise 가져오기, 같은 서버의 웹 앱(`/app/`), 그룹 종류·표지 사진·삭제/복원, UPI. 이메일(SMTP)은 선택이고 `EVENSIES_SMTP_HOST`가 비면 전부 꺼진다(로그인 코드·요약 메일·반복 지출 알림·초대 메일 포함). 테스트는 Mailpit 컨테이너와 메일 캡처로 돌고, 유료 서비스는 추가하지 않았다(Resend는 출시 때 효준님이 넣을 수 있는 SMTP 주소일 뿐). `./gradlew --no-daemon test`(Testcontainers, JDK 21) **517개 통과·0개 실패·0개 건너뜀**.
- **앱**(Flutter 3.41, iOS·Android·웹): drift 로컬 DB(`schemaVersion` 10, 올릴 때마다 데이터를 지키며 다시 받기), 오프라인 outbox → push → pull 동기화, 13개 언어(ARB + `shared/strings.json`), 그룹·친구·전체 잔액·정산(결제 앱 링크, INR이면 금액이 채워지는 UPI 포함)·활동·검색·인사이트·영수증·반복 지출·위젯·앱 잠금·화면 모드, 10단계의 이메일 로그인·계정 이메일·이메일 요약 설정·이메일 초대·반복 지출 알림 설정·그룹 종류와 표지·그룹/친구 삭제와 복원(Undo, 설정 → 삭제한 그룹, 활동 행)·차단/신고·전체 내보내기·모든 기기 로그아웃·도움말, 웹의 넓은 창(1024px 이상) 3단 배치(왼쪽 대시보드·활동·모든 지출·그룹·친구, 가운데 페이지, 오른쪽 잔액), 웹에서 두 번째 탭은 "다른 탭에서 열려 있음" 안내, 지출 화면의 기록+댓글 한 줄 스레드(서버 시각 하나로 정렬). 친구 삭제는 그룹 밖 잔액을 정산한 뒤에만 된다(Splitwise와 같음). `flutter analyze` 0건, `flutter test` **804개 통과·2개 건너뜀**(서버 전용 문장 케이스, `TODO(효준)` 아님).
- **확인(10단계 E2E, iPhone 16 Pro 시뮬레이터, 라이트·다크, Mailpit)**: 이메일 코드 로그인, 계정 이메일 추가·변경·반송 경고, 요약 메일 선택, 그룹 종류·표지, 이메일 초대(링크 → 자리표시 미리 선택, 강제 실행에서 리마인더 한 번), 반복 지출 알림 한 번, 일간 요약(문장·잔액 맞음), 차단, 수신 거부 링크 두 가지, 그룹·친구 삭제와 복원, 전체 내보내기, 모든 기기 로그아웃, UPI, 도움말, 이메일 끈 서버(화면 숨김·로그 오류 없음), 데스크톱 Chrome 1360px의 넓은 배치. E2E가 찾은 12건은 수정 라운드에서 모두 고쳤다.
- **확인(웹, 내장 브라우저 창 + 로컬 서버 `java -jar`, Dockerfile과 같은 빌드 옵션)**: dev 로그인과 새로고침 후 유지(탭 하나짜리 IndexedDB 대체 경로), 서버를 끈 채 넣은 지출이 재시작 후 동기화, CSV 내보내기·Splitwise CSV 가져오기, 랜딩 → 브라우저에서 계속 → 이메일 코드 로그인 → 이름 → 참여(자리표시 미리 선택), 프로필 사진·표지·전체 내보내기, 모든 탭 콘솔에 CSP 위반 없음, 웹훅(로컬에서 만든 Svix 서명: 반송·신고 204, 잘못된/10분 지난 서명 401), 한국어 수신 거부 페이지와 한국어 일간 요약. 이 라운드에서 6건(넓은 화면 사이드바가 스크린 리더에 안 보임, 새로고침 때 로그인 화면 깜빡임, 로그아웃 상태 401 호출, 한국어 메일 조사 3곳, 넓은 화면의 잘못된 빈 그룹 안내, API.md 낡은 행)을 고쳤다. 마무리 라운드(같은 방식)에서 9단계 웹 문제 3건을 고치고 확인했다: `push`로 연 화면(새 그룹·멤버·지출 상세)도 주소창에 자기 경로가 보이고 새로고침·브라우저 뒤로 가기가 그 화면을 지킨다(넓은 창·좁은 창), Google 스크립트는 Google 로그인을 켠 서버의 로그인 화면에서만 받는다(꺼진 서버와 로그인 뒤 페이지는 Google 요청 0건, `web/gsi_lazy.js`), 공유 워커가 아예 없는 브라우저도 두 번째 탭에 "다른 탭에서 열려 있음" 안내(drift가 고르는 `unsafeIndexedDb` 앞에 Web Lock).
- **아직 확인 못 한 것**: ① `docker compose build`한 서버 이미지 — Docker VM 디스크가 160MB만 남아 시도하지 않았다(빌드 캐시 7.1GB 정리는 효준님 판단). 같은 내용물을 `java -jar`로 돌린 확인은 끝났다. ② 푸시가 필요한 경로(Firebase 설정 파일 없이 실행: 알림 허용 여부, 자동 → 매달, 차단한 사람 리마인더 푸시 없음 — 서버 테스트만), iOS 코드 자동 채우기, 실제 Resend 발송(출시 때 효준님 계정). ③ 공유 워커가 없는 브라우저의 탭 잠금은 내장 창에서 `SharedWorker`를 지운 테스트용 빌드로만 확인했다(실제 그런 브라우저에서는 아직). ④ 한국어 검토(parity #86, 효준님): 통화 코드 뒤 조사(`{currency}로`는 M·N으로 끝나는 코드에서 틀림)는 기존 `{currency} 통화로`·`그대로` 표현으로 바꿨고(`l10n_test`가 `(으)로` 같은 괄호 조사를 막는다), 금액 뒤 `이에요`(`내 몫은 {amount}이에요`)도 `내 몫: {amount}`로 바꿨다. 나머지 전체 검토는 그대로 효준님 차례.
- **로컬 dev DB**(`deploy-postgres-1`): Flyway V12까지 적용, 2026-10-12 최종 점검에서 V1–V12 체크섬이 파일과 같음을 다시 확인했다. V13(`users.email_removed`, `email_log.ref`)은 아직 없고 다음 서버 시작 때 Flyway가 적용한다(바뀐 파일이 아니라 새 파일이라 손댈 것 없음, 최종 점검에서 롤백하는 트랜잭션으로 dev DB에 그대로 적용되는 것까지 확인).
- **빌드·배포**: parity까지 TestFlight/Play 빌드와 운영 서버 배포는 보류(효준님 결정). 원격 저장소 `github.com/devyourown/evensies`, 커밋은 `git log --oneline` 참고.

## 핵심 로직 4곳 — 완료 (2026-10-11)
| # | 내용 | 작성 | 상태 |
|---|---|---|---|
| 1 | 분할 계산 Dart `app/lib/domain/split.dart` | 효준님 | 테스트 15개 통과 |
| 2 | 분할 계산 Kotlin `money/Split.kt` | Claude 이식, 효준님 검토 | 14개 통과 |
| 3 | 잔액·부채 단순화 Dart `app/lib/domain/settlement.dart` | 효준님 | 23개 통과 |
| 4 | 여러 명이 낸 지출·환불 `computeBalances` (`app/lib/domain/settlement.dart:46`) | 효준님 | 완료, `shared/settlement-cases.json` 13케이스 통과 |
| 5 | 잔액 fixture 루프 테스트 (`app/test/hyojun/settlement_test.dart:34`) | 효준님 | 완료 |
| 6 | 환산 `convertAmount` (`app/lib/domain/fx.dart:25`, Kotlin `money/Fx.kt` 이식) | 효준님 | 완료, `shared/fx-cases.json` 1–10 통과 |

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
