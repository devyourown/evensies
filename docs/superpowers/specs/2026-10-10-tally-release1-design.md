> 2026-10-11: product renamed Tally → Evensies; code identifiers below use the old name.

# Tally 출시 1 설계: 오픈소스 더치페이 앱

- 작성일: 2026-10-10
- 상태: 사용자 리뷰 대기
- 코드네임: `tally` (공개 제품명은 스토어 등록 전 결정, §10)
- 스택: Flutter(앱) · Spring Boot 3 + Kotlin(서버) · PostgreSQL · Docker

## 1. 목적과 성공 기준

### 1.1 목적
이 프로젝트는 "새 제품"이 아니라 **취업용 공개 코드**다. 글로벌 원격 풀스택·모바일 지원에서 "공개된 Flutter 코드가 없다"는 약점을 채우고, 면접에서 설명할 수 있는 실제 운영 소재(오프라인 동기화, 멱등성, 돈 계산)를 만든다. 스토어 순위는 보너스다.

### 1.2 제품 한 줄 정의
친구·가족·여행 그룹의 지출을 기록하고 누가 누구에게 얼마를 보내면 되는지 계산해 주는 앱. Splitwise의 대안으로, 입력 제한·광고·데이터 가두기가 없고 코드가 공개되어 있으며 셀프호스팅이 가능하다.

### 1.3 출시 1 완료 기준
1. App Store와 Google Play에 공개된다.
2. 공개 저장소의 README만 보고 제3자가 `docker compose up`으로 서버를 띄울 수 있다.
3. 지인 그룹 3개(이탈리아·한국)가 실제 여행·모임에서 2주 이상 쓴다.
4. 효준님이 §7의 핵심 로직 4개를 코드 없이 설명할 수 있다.
5. CI가 녹색이다(앱 analyze·test, 서버 test, 공유 정산 테스트 양쪽 통과).

### 1.4 운영 규칙 (career/GOALS.md에도 기록)
- 효준님 투입은 **주 3시간 상한**. 지원·루틴 지표(GOALS 1~5번)가 ❌인 주에는 이 프로젝트를 멈춘다. 컨트롤타워가 판정한다.
- 효준님이 설명하지 못하는 코드는 저장소에 넣지 않는다.
- 분담: 배관·화면·인프라·테스트 뼈대는 Claude, §7의 핵심 로직과 테스트 단언은 효준님(`TODO(효준)` 표시).

## 2. 범위

### 2.1 출시 1에 포함
- 그룹 생성, 초대 링크 참여, 자리표시 멤버
- 지출 입력: 균등·금액·비율 분할, 지출 단위 다중 통화(환율은 입력 시 수동)
- 잔액 계산, 부채 단순화 정산 제안, 송금 완료 기록
- 오프라인 입력 → 동기화, 충돌 처리, 푸시로 동기화 신호
- Apple·Google 로그인, 계정 삭제
- 내보내기(CSV·JSON), Splitwise CSV 가져오기
- 셀프호스팅 Docker 이미지, 앱에서 서버 주소 변경

### 2.2 출시 1에서 하지 않는 것
영수증 OCR, 실제 송금 연동, 반복 지출, 차트·통계, 자동 환율, 지출 변경 이력 화면, 실시간 WebSocket, 이메일 로그인, 커스텀 디자인, 웹 앱, 카테고리 예산.

## 3. 아키텍처

```
Flutter 앱 (iOS·Android)                  Spring Boot (Kotlin) 서버
┌──────────────────────────┐              ┌──────────────────────────┐
│ UI (Riverpod, go_router) │   HTTPS/JSON │ REST API                 │
│ 로컬 DB (drift/SQLite)   │ ◀──────────▶ │ 서비스 계층              │
│   - 모든 데이터의 사본   │   동기화     │ PostgreSQL (Flyway)      │
│   - outbox (보낼 변경)   │              │ 푸시 (FCM)               │
│ 정산 계산 (앱 안에서)    │              │ 로그인 (Apple·Google)    │
└──────────────────────────┘              └──────────────────────────┘
                                          Docker Compose (호스팅·셀프호스팅 동일 이미지)
```

| 결정 | 선택 | 이유 |
|---|---|---|
| 오프라인 우선 | 앱 로컬 DB가 진실, 서버는 동기화 허브 | 여행지에서 통신이 끊겨도 입력이 되어야 한다 |
| 동기화 | 변경 이벤트 로그(append-only) + 서버 순번 커서 | 여러 사람이 같은 지출을 만진다. 행 단위 마지막 쓰기 승리는 남의 입력을 지운다 |
| 계산 위치 | 잔액·정산은 앱에서, 서버는 저장·검증·내보내기 | 오프라인에서도 잔액이 보여야 한다 |
| 단일 이미지 | 호스팅과 셀프호스팅이 같은 Docker 이미지, 환경 변수만 다름 | 둘을 따로 만들면 셀프호스팅이 방치된다 |

- 앱: Flutter stable, Riverpod, drift(SQLite), go_router, dio, sign_in_with_apple, google_sign_in, firebase_messaging.
- 서버: Spring Boot 3, Kotlin, Spring Data JDBC, PostgreSQL 16, Flyway, Spring Security(JWT), Actuator.
- 실시간 없음: FCM 데이터 메시지로 "pull 하라"는 신호만 보낸다.

## 4. 데이터 모델

금액은 모두 **정수(통화의 최소 단위)**. 통화별 소수 자릿수 테이블을 앱·서버가 공유한다(KRW·JPY 0, EUR·USD 2, 등).

```
User          id(uuid), display_name, avatar_url?, created_at, deleted_at?
Group         id, name, default_currency, invite_code(재발급 가능), created_by, created_at, archived_at?
Member        id, group_id, user_id?, name            -- user_id 없으면 자리표시 멤버
Expense       id, group_id, description, amount, currency, fx_rate_to_default?,
              paid_by(member_id), date, category?, created_by, created_at, updated_at, deleted_at?
ExpenseShare  expense_id, member_id, amount           -- 합계 = Expense.amount (DB 제약 아님, 적용기가 보장)
Payment       id, group_id, from_member, to_member, amount, currency, date, created_by, deleted_at?
Event         seq(bigint, 그룹별 단조 증가), group_id, client_id(uuid), type, payload(jsonb),
              actor_user_id, device_id, created_at
              UNIQUE (group_id, client_id)
Device        id, user_id, fcm_token?, last_seen_at
```

| 결정 | 이유 |
|---|---|
| 분할은 항상 멤버별 확정 금액으로 저장 | 균등·비율·배수는 입력 방식일 뿐이다. 합계 = 지출액이 항상 성립하고, 분할 방식을 늘려도 데이터가 안 바뀐다 |
| 나머지 배분 규칙 | 균등 분할에서 나누어떨어지지 않는 최소 단위는 멤버 ID 오름차순으로 앞에서부터 1씩 더한다. 결정적이어야 두 구현이 일치한다 |
| 자리표시 멤버 | 앱을 안 깐 친구를 먼저 멤버로 넣을 수 있어야 한다. 초대 링크로 가입하면 그 자리에 연결한다 |
| soft delete | 동기화 충돌(삭제 vs 수정)을 풀려면 흔적이 필요하다 |
| 다중 통화는 지출 단위 | 지출에 통화와 수동 환율(`fx_rate_to_default`)을 적는다. 잔액은 그룹 기본 통화로 환산해 보여 준다. 환율이 없으면 그 지출은 잔액 화면에 "환율 필요" 표시 |

## 5. 정산 계산

1. **잔액**: 멤버별 `낸 돈 − 부담 몫 + 보낸 송금 − 받은 송금` (그룹 기본 통화 기준). 양수 = 받을 돈. 송금은 "보낸 사람이 낸 지출을 받은 사람이 전부 부담"한 것과 같다. 합계는 0.
2. **부채 단순화**: 양수(채권자)·음수(채무자)를 각각 절댓값 큰 순으로 정렬. 가장 큰 채권자와 가장 큰 채무자를 맞붙여 작은 쪽 금액만큼 송금을 만들고, 0이 된 쪽을 빼고 반복. 송금 수 ≤ n−1. 정확한 최소 횟수는 NP-hard이므로 탐욕법을 쓴다.
3. **동률 처리**: 금액이 같으면 멤버 ID 오름차순. 결정적이어야 한다.
4. **성질(테스트가 검증)**: 잔액 합 0 · 송금 적용 후 모든 잔액 0 · 송금 수 ≤ n−1 · 같은 입력에 같은 출력 · 나머지 배분 결정적.

같은 로직을 **Dart(앱)와 Kotlin(서버)** 두 번 구현한다. 테스트 케이스는 `shared/settlement-cases.json` 하나를 양쪽이 읽는다. 두 구현이 어긋나면 CI가 잡는다.

## 6. 동기화

### 6.1 흐름
```
[앱] 입력 → 로컬 DB 즉시 반영 → outbox에 이벤트 {client_id, type, payload}
     → 온라인이면 POST /groups/{id}/events [배열]
[서버] 멤버 검사 → client_id 중복 제거 → 그룹 행 잠금 → seq 부여 → 저장 → 커밋
     → 그룹의 다른 기기에 FCM "pull"
[앱] GET /groups/{id}/events?after={마지막 seq} → 순서대로 applyEvent → 마지막 seq 저장
```

### 6.2 이벤트 종류 (출시 1)
`group.created`, `group.updated`, `member.added`, `member.linked`(자리표시→사용자), `member.removed`,
`expense.created`, `expense.updated`(바뀐 필드만), `expense.deleted`,
`payment.created`, `payment.deleted`.

### 6.3 규칙
| 규칙 | 내용 |
|---|---|
| 멱등성 | `UNIQUE (group_id, client_id)`. 중복은 무시하고 기존 seq를 돌려준다. 재전송해도 지출이 두 번 들어가지 않는다 |
| 순서 | 서버가 그룹별 `seq`를 부여. 앱은 그룹별 "마지막으로 본 seq"만 저장한다. 기기 시계에 의존하지 않는다 |
| 원자성 | push 배열은 한 트랜잭션. seq 부여는 그룹 행 `SELECT … FOR UPDATE` |
| 충돌: 수정 vs 수정 | 필드 단위 마지막 쓰기 승리(seq 큰 쪽). `expense.updated` payload는 바뀐 필드만 담는다 |
| 충돌: 삭제 vs 수정 | 삭제가 이긴다. 수정한 사람에게 로컬 알림("A가 삭제한 지출을 수정했습니다") |
| 스냅샷 | 새 기기·새 멤버는 `GET /groups/{id}/snapshot` → 현재 상태 + 그 시점 seq. 이벤트 전체 재생을 피한다 |
| 권한 | 서버는 적용 전에 호출자가 그룹 멤버인지, payload의 member_id·expense_id가 그 그룹 소속인지 검사한다. 클라이언트가 보낸 ID를 믿지 않는다 |
| 적용기 | `applyEvent(state, event)`는 순수 함수이고 같은 이벤트를 두 번 적용해도 결과가 같다 |
| 서버 쪽 적용 | 서버도 push 트랜잭션 안에서 같은 이벤트를 §4의 테이블에 반영한다(스냅샷·내보내기·검증용). Kotlin 적용기는 Claude가 쓰되 Dart 적용기와 같은 규칙을 따르고, 두 적용기는 `shared/sync-cases.json`으로 함께 검증한다 |

### 6.4 동기화 테스트
이벤트 배열을 무작위로 섞고·중복시키고·끊어서 보내도 최종 상태가 같은지 검사한다(앱 적용기 단위 테스트 + 서버 통합 테스트).

## 7. 핵심 로직 (효준님 작성, 나머지는 Claude)
| # | 위치 | 내용 | 예상 분량 |
|---|---|---|---|
| 1 | Dart + Kotlin | 분할 계산(나머지 배분), 잔액, 부채 단순화 | 각 60~80줄 |
| 2 | Dart | `applyEvent` 적용기 | 80~100줄 |
| 3 | Kotlin | push 핸들러의 트랜잭션(잠금·중복 제거·seq 부여) | 40~60줄 |
| 4 | 양쪽 | 위 세 가지 테스트의 단언 | — |

면접에서 설명할 부분은 정확히 이 네 곳이다.

## 8. API (출시 1)
```
POST   /auth/apple            { id_token }            → { access, refresh }
POST   /auth/google           { id_token }            → { access, refresh }
POST   /auth/refresh
DELETE /me                                            (계정 삭제, 멤버는 자리표시로 전환)
POST   /devices               { fcm_token }
POST   /groups                                        → group + invite_code
GET    /groups                                        (내 그룹 목록 + 요약)
POST   /groups/{id}/invite/rotate
GET    /invites/{code}                                (미리보기, 인증 불필요)
POST   /invites/{code}/join   { member_id? | name }
POST   /groups/{id}/events    [event]                → [{client_id, seq}]
GET    /groups/{id}/events?after=seq
GET    /groups/{id}/snapshot
GET    /groups/{id}/export?format=csv|json
POST   /groups/{id}/import/splitwise  (CSV 업로드 → 이벤트로 변환)
GET    /actuator/health
```
인증: Bearer JWT(access 15분, refresh 30일). 셀프호스팅 운영자는 Apple·Google 클라이언트 ID를 환경 변수로 넣는다.

## 9. 화면과 초대

### 9.1 화면 7개
| # | 화면 | 핵심 |
|---|---|---|
| 1 | 그룹 목록 | 그룹별 받을/줄 금액. 비어 있으면 "그룹 만들기", "초대 링크 붙여넣기" |
| 2 | 그룹 상세 | 탭: 지출 목록 / 잔액(+ 정산하기) |
| 3 | 지출 입력 | 금액·설명·낸 사람·분할·통화·날짜. 입력 3번 안에 저장 |
| 4 | 정산 제안 | 송금 목록, "완료 표시" → Payment |
| 5 | 멤버·초대 | 멤버 목록, 자리표시 추가, 초대 링크 공유, 재발급 |
| 6 | 로그인 | Apple·Google |
| 7 | 설정 | 내보내기, 서버 주소 변경, 계정 삭제, 라이선스 |

### 9.2 초대 흐름
- 링크 `https://{도메인}/j/{invite_code}`. 그룹당 코드 하나, 재발급 가능, 만료 없음, 그룹 인원 상한 50.
- 앱 있음: 딥링크(Universal Links / App Links) → 미리보기 → 참여 → 자리표시 멤버 선택 또는 새 멤버.
- 앱 없음: 서버가 미리보기 웹 페이지 + 스토어 버튼 제공. 설치 후 첫 실행에서 클립보드 링크 감지.
- 로그인은 **지출 입력부터** 요구. 둘러보기는 로그인 없이 가능.

### 9.3 디자인
Material 3 기본 + 주 색상 하나. 커스텀 디자인은 하지 않는다. 다크 모드는 Material 3 기본값.

## 10. 운영과 지속 가능성
| 항목 | 내용 |
|---|---|
| 저장소 | GitHub 공개 모노레포 `app/` `server/` `shared/` `deploy/` `docs/`. 라이선스 **AGPL-3.0** |
| 제품명 | 스토어 등록 전 결정. 조건: 영어 발음 쉬움, 도메인 확보 가능, 상표 충돌 없음 |
| 호스팅 | Hetzner CX22 + Docker Compose(server, postgres, caddy). 백업 매일 `pg_dump` → Cloudflare R2 |
| 셀프호스팅 | 같은 이미지. README의 `docker compose up` 안내. 앱 설정에서 서버 주소 변경 |
| 지속 가능 규칙(README 공개) | 입력 제한 없음 · 셀프호스팅 영구 무료 · 내보내기 항상 제공 · 호스팅 비용 월 30유로 초과 시 호스팅에만 후원 등급 도입, 그 전까지는 신규 가입 제한으로 대응 · 기존 사용자 기능을 유료로 돌리지 않음 |
| 악용 방지 | 초대 코드 재발급, 그룹 인원 50, 로그인은 Apple·Google만, 사용자당 그룹 수 상한 100, 이벤트 push 속도 제한 |
| 관측 | Actuator + Prometheus + Grafana, Telegram 알림 |
| 개인정보 | 수집: 이름, 이메일(로그인 제공자에서), 지출 데이터, FCM 토큰. 분석 SDK 없음. 개인정보 처리방침 페이지 제공(스토어 필수) |

## 11. 테스트
| 층 | 내용 |
|---|---|
| ① 순수 함수 | 분할·잔액·정산(공유 JSON, Dart·Kotlin 양쪽), `applyEvent` |
| ② 서버 통합 | Testcontainers PostgreSQL + 실제 HTTP(WebTestClient). 부팅·Flyway·인증을 우회하지 않는다 |
| ③ 앱 위젯 | 지출 입력 화면만 |
| ④ 동기화 무작위 | 섞기·중복·끊기 후 최종 상태 동일 |
| CI | GitHub Actions: `flutter analyze && flutter test`, `./gradlew test`, 공유 JSON 양쪽 실행 |

## 12. 출시 순서
1. 저장소 골격, CI, Docker Compose, 서버 인증·그룹·이벤트 API (Claude)
2. 핵심 로직 1·3 + 테스트 단언 (효준님)
3. 앱 로컬 DB, 화면 7개, outbox·pull (Claude), 핵심 로직 2 (효준님)
4. 초대 딥링크, 내보내기·가져오기, 푸시 (Claude)
5. TestFlight·내부 테스트 → 지인 그룹 3개 2주 → 스토어 공개. ASO 키워드: "split expenses", "splitwise alternative", "dividi spese", "더치페이"
6. README·셀프호스팅 안내·개인정보 처리방침 → 공개 저장소 → r/selfhosted, awesome-selfhosted 등록

## 13. 출시 2 이후 후보
실시간 동기화, 자동 환율, 반복 지출, 영수증 OCR, 이메일 로그인(셀프호스팅용), 지출 이력 화면, 웹 앱, 차트.
