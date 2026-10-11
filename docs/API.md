# Evensies API·동기화 계약 (출시 1)

서버(Spring Boot)와 앱(Flutter)이 공유하는 계약. 양쪽 구현은 이 문서를 따른다. 바꾸려면 이 문서부터 고친다.

## 공통 규칙
- 모든 ID는 UUID 문자열(앱이 생성). 금액은 정수(최소 단위, `shared/currencies.json`). 날짜는 `YYYY-MM-DD`, 시각은 ISO-8601 UTC.
- JSON 키는 camelCase. null 허용 필드는 명시적으로 `null`로 보낸다.
- 인증: `Authorization: Bearer <access>`. 미인증 → 401. 그룹 멤버가 아님 → 403. 없음 → 404.
- 오류 본문: `{"code": "SUM_MISMATCH", "message": "..."}`. 검증 오류는 400.

## 인증
| 메서드 | 경로 | 요청 | 응답 |
|---|---|---|---|
| POST | `/auth/apple` | `{"idToken": "...", "displayName"?: "..."}` — Apple은 이름을 토큰에 넣지 않고 첫 로그인 때만 앱에 주므로 앱이 함께 보낸다 | `{"accessToken","refreshToken","user":{"id","displayName"}}` |
| POST | `/auth/google` | `{"idToken": "..."}` | 위와 같음 |
| POST | `/auth/dev` | `{"name": "Anna"}` — **`evensies.auth.dev-login=true`일 때만** 존재. 같은 name이면 같은 사용자 | 위와 같음 |
| POST | `/auth/refresh` | `{"refreshToken"}` | `{"accessToken","refreshToken"}` (refresh 회전) |
| GET | `/me` | | `{"id","displayName"}`. `displayName`이 빈 문자열이면 앱은 이름 입력 화면을 띄운다(이메일은 이름으로 쓰지 않음) |
| PATCH | `/me` | `{"displayName"}` (공백 제거 후 1~30자, 이모지 허용) | `{"id","displayName"}`. 범위 밖이면 400 `VALIDATION` |
| DELETE | `/me` | | 204. 사용자 행은 deleted_at, 모든 Member.user_id는 null(자리표시로 전환) |
| POST | `/devices` | `{"deviceId","fcmToken"}` | 204 |

access 15분, refresh 30일. JWT HS256, 비밀은 `EVENSIES_JWT_SECRET`.

## 그룹
| 메서드 | 경로 | 요청 | 응답 |
|---|---|---|---|
| POST | `/groups` | `{"id","name","defaultCurrency","memberId","memberName"}` — id·memberId는 앱이 생성 | `GroupDto` (seq 1·2에 `group.created`, `member.added` 이벤트가 기록됨) |
| GET | `/groups` | | `[GroupSummaryDto]` |
| GET | `/groups/{id}` | | `GroupDto` |
| POST | `/groups/{id}/invite/rotate` | | `{"inviteCode"}` |
| GET | `/invites/{code}` | 인증 불필요 | `{"groupId","name","memberCount","members":[{"id","name","linked":bool}]}` |
| POST | `/invites/{code}/join` | `{"memberId": "<기존 자리표시 멤버>"}` 또는 `{"newMemberId","name"}` | `GroupDto`. `member.linked` 또는 `member.added`(userId 포함) 이벤트 기록 |

```
GroupDto        {"id","name","defaultCurrency","inviteCode","createdAt","latestSeq","myMemberId"}
GroupSummaryDto {"id","name","defaultCurrency","latestSeq","memberCount"}
```
상한: 그룹당 멤버 50, 사용자당 그룹 100 → 초과 시 409 `LIMIT_EXCEEDED`.

초대 코드: **6자, 알파벳 `23456789ABCDEFGHJKMNPQRSTUVWXYZ`**(0/O, 1/I/L 제외). 이전에 발급된 10자 코드도 계속 유효하다. `/invites/{code}`, `/invites/{code}/join`, `/j/{code}`는 코드를 정규화한다(대문자로 바꾸고 영문·숫자 외 문자는 제거: `k7p-4qx` = `K7P4QX`). 세 엔드포인트는 **클라이언트 IP당 분당 10회**(`EVENSIES_INVITE_RATE_PER_MINUTE`)로 제한되며 초과 시 429 `RATE_LIMITED`.

## 이벤트 (동기화)
### push
`POST /groups/{id}/events`
```
요청: [{"clientId":"uuid","type":"expense.created","payload":{...},"createdAt":"2026-10-10T09:00:00Z"}]
응답: {"results":[{"clientId":"uuid","seq":12}], "latestSeq": 12}
```
- 배열 전체가 한 트랜잭션. 그룹 행 `SELECT ... FOR UPDATE`로 잠근 뒤 seq 부여.
- `(group_id, client_id)` UNIQUE. 중복은 기존 seq를 돌려준다(오류 아님).
- 서버는 같은 트랜잭션에서 이벤트를 테이블(member/expense/expense_share/payment)에 반영한다.
- 검증 실패(그룹 밖 memberId, 분할 합 불일치, 음수)는 배열 전체 거부 400. 속도 제한: 사용자당 분당 120 이벤트 → 429.

### pull
`GET /groups/{id}/events?after=<seq>&limit=500`
```
응답: {"events":[{"seq","clientId","type","payload","actorUserId","createdAt"}], "latestSeq": 57}
```
### snapshot
`GET /groups/{id}/snapshot`
```
{"group": GroupDto,
 "members":  [{"id","name","userId","removed":bool}],
 "expenses": [{"id","description","amount","currency","fxRateToDefault","paidBy","date","category","deleted":bool,"shares":[{"memberId","amount"}]}],
 "payments": [{"id","fromMember","toMember","amount","currency","date","deleted":bool}],
 "latestSeq": 57}
```

### 이벤트 종류와 payload
| type | payload |
|---|---|
| `group.created` | `{"name","defaultCurrency"}` (서버가 POST /groups에서 생성) |
| `group.updated` | `{"name"?: string, "defaultCurrency"?: string}` |
| `member.added` | `{"memberId","name","userId": string|null}` |
| `member.linked` | `{"memberId","userId"}` |
| `member.removed` | `{"memberId"}` (removed=true 표시, 삭제 아님) |
| `expense.created` | `{"expenseId","description","amount","currency","fxRateToDefault": number|null,"paidBy","date","category": string|null,"shares":[{"memberId","amount"}]}` |
| `expense.updated` | `{"expenseId","fields":{...바뀐 필드만, shares 포함 가능}}` |
| `expense.deleted` | `{"expenseId"}` |
| `payment.created` | `{"paymentId","fromMember","toMember","amount","currency","date","status"?: "sent"\|"confirmed"}` — `status` 없으면 `confirmed`(이전 이벤트 호환). 받는 멤버가 자리표시자이거나 보내는 사람이 받는 사람 본인이면 서버가 `confirmed`로 저장 |
| `payment.confirmed` | `{"paymentId"}` — **받는 멤버에 연결된 사용자만** 보낼 수 있다(아니면 403 `FORBIDDEN`) |
| `payment.deleted` | `{"paymentId"}` — 보낸 사람 또는 받는 사람("받지 못함")이 보낼 수 있다 |

### 적용 규칙 (앱 Dart·서버 Kotlin 동일, `shared/sync-cases.json`으로 검증)
1. `applyEvent(state, event)`는 순수 함수. 같은 이벤트 두 번 적용 = 한 번 적용.
2. 수정 vs 수정: 필드 단위로 seq 큰 쪽이 이긴다(순서대로 적용하면 자연히 성립).
3. 삭제 vs 수정: `deleted=true`인 지출·송금에 오는 `updated`는 무시한다(삭제가 이김).
4. 없는 대상에 오는 `updated`·`deleted`·`linked`·`removed`는 무시한다.
5. `member.removed`는 `removed=true`만 표시한다. 잔액 계산에는 계속 포함된다.
6. `payment.confirmed`는 `status`를 `confirmed`로 바꾼다. 없거나 삭제된 송금이면 무시한다. 잔액은 `sent`와 `confirmed` 송금을 똑같이 반영한다(앱은 `sent`를 "확인 대기"로 표시).

## 결제 수단 (송금 안내)
우리는 돈을 보관하거나 옮기지 않는다. 사용자가 "나에게 돈 보내는 방법"을 등록하면 같은 그룹 멤버의 앱이 해당 결제 앱을 연다.

| 메서드 | 경로 | 요청 | 응답 |
|---|---|---|---|
| GET | `/me/payment-methods` | | `[PaymentMethod]` |
| PUT | `/me/payment-methods` | `[PaymentMethod]` (전체 교체) | `[PaymentMethod]`. 검증 실패 400 `VALIDATION` |
| GET | `/groups/{id}/payment-methods` | | `{"<memberId>": [PaymentMethod]}` — 그 그룹의 **연결된** 멤버만, 호출자는 멤버여야 함(403) |

```
PaymentMethod {"type","value","holder"?: string, "bank"?: string, "bic"?: string}
```
| type | value | 추가 필드 | 검증 |
|---|---|---|---|
| `paypal` | PayPal.me 사용자명 | | `[A-Za-z0-9._-]{1,40}` |
| `revolut` | Revolut.me 사용자명 | | 위와 같음 |
| `venmo` | Venmo 사용자명 | | 위와 같음 |
| `wise` | Wise Quick Pay 링크 | | `https://wise.com/`로 시작, 200자 이하 |
| `kakaopay` | 카카오페이 송금코드 링크 | | `https://qr.kakaopay.com/`로 시작, 200자 이하 |
| `iban` | IBAN(공백 제거, 대문자) | `holder` 필수(1~70자), `bic` 선택(8 또는 11자) | mod-97 검사 |
| `kr_bank` | 계좌번호(숫자·하이픈) | `bank` 필수(1~30자), `holder` 필수 | 숫자 8~20자리 |

상한: 사용자당 8개, `iban`·`kr_bank`는 각 3개, 나머지 유형은 1개.

## 내보내기·가져오기
- `GET /groups/{id}/export?format=json` → snapshot과 같은 JSON. `format=csv` → 지출 CSV (`date,description,amount,currency,paidBy,<멤버이름별 share>...`).
- `POST /groups/{id}/import/splitwise` multipart `file` (Splitwise CSV: `Date,Description,Category,Cost,Currency,<이름>...`). 서버가 이름을 그룹 멤버와 매칭(없으면 자리표시 멤버 생성)하고 `expense.created` 이벤트로 변환. 응답 `{"imported": n, "latestSeq"}`.

## 푸시
push가 성공하면 그룹의 다른 기기(FCM 토큰 있는)에 데이터 메시지 `{"type":"sync","groupId":"..."}`를 보낸다. FCM 자격 증명(`EVENSIES_FCM_CREDENTIALS_FILE`)이 없으면 조용히 건너뛴다.

## 환경 변수 (서버)
| 변수 | 기본 | 설명 |
|---|---|---|
| `EVENSIES_DB_URL` | `jdbc:postgresql://localhost:5432/evensies` | |
| `EVENSIES_DB_USER` / `EVENSIES_DB_PASSWORD` | `evensies` / `evensies` | |
| `EVENSIES_JWT_SECRET` | (필수, 32자 이상) | |
| `EVENSIES_AUTH_DEV_LOGIN` | `false` | `true`면 `/auth/dev` 활성 (개발 전용) |
| `EVENSIES_APPLE_CLIENT_ID` | | Apple 서비스 ID (앱 번들 ID) |
| `EVENSIES_GOOGLE_CLIENT_IDS` | | 쉼표 구분 |
| `EVENSIES_FCM_CREDENTIALS_FILE` | | 없으면 푸시 비활성 |
| `EVENSIES_INVITE_RATE_PER_MINUTE` | `10` | 초대 조회·참여·랜딩의 IP당 분당 허용 횟수 |
| `EVENSIES_PUBLIC_URL` | `http://localhost:8080` | 초대 링크 도메인 |
