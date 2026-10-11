# Evensies API·동기화 계약

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
| POST | `/devices` | `{"deviceId","fcmToken"}` | 204. 사용자당 최근에 등록한 기기 10개만 남기고 오래된 것은 지운다. 같은 `fcmToken`을 가진 다른 기기 행(다른 사용자 포함)도 지운다(한 폰에서 다른 계정으로 로그인하면 이전 사용자의 푸시가 끊긴다) |
| DELETE | `/devices/{deviceId}` | | 204. 호출자 본인의 그 기기 행만 지운다(없거나 다른 사용자의 기기면 아무것도 안 하고 204). 앱은 로그아웃할 때 세션을 지우기 **전에** 보낸다. 오프라인이면 실패해도 로그아웃은 진행한다. 앱은 세션이 사라지면(로그아웃, 계정 삭제, 토큰 갱신 실패) 그 폰의 FCM 토큰도 지운다(FCM `deleteToken`, 오프라인이면 로그아웃 상태로 다음 실행·복귀 때 다시 시도). 그러면 서버의 다음 발송이 `UNREGISTERED`를 받아 남은 행을 지운다 |

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
- 서버는 같은 트랜잭션에서 이벤트를 테이블(member/expense/expense_share/payment/comment)에 반영하고, 활동 피드용 `meta`를 이벤트 행에 기록한다("활동·알림").
- 검증 실패(그룹 밖 memberId, 분할 합 불일치, 음수, 새로 만드는 이벤트(`*.created`·`member.added`·`comment.added`)의 id가 다른 그룹에 이미 있음)는 배열 전체 거부 400. 다른 이벤트(`updated`·`deleted`·`restored`·`linked`·`removed`·`confirmed`)가 다른 그룹의 id를 가리키면 이 그룹에는 없는 대상이므로 통과하고 적용 규칙 4로 무시된다(다른 그룹은 바뀌지 않음). 속도 제한: 사용자당 분당 120 이벤트 → 429.

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
 "expenses": [{"id","description","amount","currency","fxRateToDefault","paidBy","date","category","notes","deleted":bool,"shares":[{"memberId","amount"}]}],
 "payments": [{"id","fromMember","toMember","amount","currency","date","deleted":bool,"status"}],
 "comments": [{"id","expenseId","authorMemberId","text","createdAt","deleted":bool}],
 "latestSeq": 57}
```
- `notes`는 `string|null`. `comments`는 삭제된 댓글도 `deleted: true`로 포함한다(지출·송금과 같음). pull 응답의 이벤트 모양은 바뀌지 않는다(서버 내부 `meta`는 보내지 않음).
- 삭제된 댓글의 `text`는 `""`(빈 문자열)이다(적용 규칙 8). 서버는 `comment.deleted`를 저장하는 push 트랜잭션에서 그 댓글의 저장된 `comment.added` 이벤트 payload `text`도 `""`로 바꾼다(로그에서 저장 뒤에 바뀌는 유일한 값. seq·clientId·나머지 payload는 그대로). 그래서 snapshot·내보내기·pull 어디에도 남지 않는다. 앱은 댓글 행의 글과 그 댓글의 활동 캐시 행을 지우고, 서버가 받은(push 성공한) outbox 행은 지운다.

### 이벤트 종류와 payload
| type | payload |
|---|---|
| `group.created` | `{"name","defaultCurrency"}` (서버가 POST /groups에서 생성) |
| `group.updated` | `{"name"?: string, "defaultCurrency"?: string}` |
| `member.added` | `{"memberId","name","userId": string|null}` |
| `member.linked` | `{"memberId","userId"}` — `userId`는 보낸 사람 본인. 이미 사용자에 연결된 멤버이거나 보낸 사람이 이 그룹에 이미 (removed 아닌) 멤버를 가지고 있으면 400 `MEMBER_TAKEN`. 앱은 보내지 않고 `/invites/{code}/join`이 만든다. `member.added`에 `userId`(본인)를 넣을 때도 이미 멤버가 있으면 같은 400 |
| `member.removed` | `{"memberId"}` (removed=true 표시, 삭제 아님) |
| `expense.created` | `{"expenseId","description","amount","currency","fxRateToDefault": number|null,"paidBy","date","category": string|null,"notes": string|null,"shares":[{"memberId","amount"}]}` — `description` 1~200자. `notes`(메모) 없으면 `null`(이전 이벤트 호환). 문자열이면 500자 이하 |
| `expense.updated` | `{"expenseId","fields":{...바뀐 필드만, shares·notes 포함 가능}}` — `"notes": null`은 메모를 지운다 |
| `expense.deleted` | `{"expenseId"}` |
| `expense.restored` | `{"expenseId"}` — 삭제된 지출을 되살린다. 그룹 멤버 누구나 보낼 수 있다(삭제와 같음) |
| `comment.added` | `{"commentId","expenseId","authorMemberId","text","createdAt"}` — `authorMemberId`는 **호출자 본인의 멤버**(아니면 403 `FORBIDDEN`). `expenseId`는 그룹에 있는 지출(삭제된 지출도 가능, 없으면 400 `VALIDATION`). `text`는 공백만이 아닌 1~1000자. `createdAt`은 ISO-8601 UTC 시각(앱이 이벤트의 createdAt과 같은 값을 넣는다) |
| `comment.deleted` | `{"commentId"}` — **작성자 본인만**(아니면 403 `FORBIDDEN`). 없는 댓글이면 통과하고 적용기가 무시. 댓글의 `text`를 `""`로 지운다(규칙 8) |
| `payment.created` | `{"paymentId","fromMember","toMember","amount","currency","date","status"?: "sent"\|"confirmed"}` — `status` 없으면 `confirmed`(이전 이벤트 호환). 받는 멤버가 자리표시자이거나 보내는 사람이 받는 사람 본인이면 서버가 `confirmed`로 저장 |
| `payment.confirmed` | `{"paymentId"}` — **받는 멤버에 연결된 사용자만** 보낼 수 있다(아니면 403 `FORBIDDEN`) |
| `payment.deleted` | `{"paymentId"}` — 보낸 사람 또는 받는 사람("받지 못함")이 보낼 수 있다 |

- 글자 수(`description` 200, `notes` 500, `text` 1000)는 UTF-16 길이(Kotlin·Dart `String.length`)로 센다. `notes`가 문자열·null이 아니거나 너무 길면, `text`·`createdAt`이 규칙에 맞지 않으면 400 `VALIDATION`. 200자 제한은 새로 보내는 `description`에만 적용한다(이미 저장된 긴 설명의 지출도 다른 필드는 고칠 수 있다). Splitwise 가져오기는 200자로 자른다.
- JSON 타입(앱 적용기는 형변환 없이 읽으므로 서버가 막는다. 어기면 400 `VALIDATION`): `expense.created`와 `expense.updated.fields`에 있는 키는 `description`·`currency`·`paidBy`·`date`·`category`·`notes`는 문자열, `amount`는 정수, `fxRateToDefault`는 숫자, `shares`는 `[{"memberId": 문자열, "amount": 정수}]`. `null`은 규칙 9대로 허용(`expense.created`에서 값이 필요한 키는 다른 검증이 거부). `expense.created`에는 `amount`·`shares`가 꼭 있어야 한다. `payment.created`의 `amount`도 정수. `group.*`·`member.added`의 `name`은 공백만이 아닌 문자열. `expense.created`·`payment.created`·`comment.added`에 `deleted` 키는 없거나 `false`(만들면서 삭제할 수 없다).
- `comment.added`의 `text` 1~1000자 검증은 보낼 때만 적용한다. 삭제된 댓글의 저장된 이벤트는 `text: ""`로 pull된다(적용 규칙 8).
- 호환: 출시 1 앱은 `comment.*`·`expense.restored`를 모르는 type으로 건너뛰고 `notes`를 버린 채 lastSeq를 올렸다. 그래서 앱 DB가 schemaVersion 3으로 올라갈 때 모든 그룹의 lastSeq를 0으로 되돌리고, lastSeq 0에서 시작하는 pull은 **빈 상태부터** 로그 전체를 다시 적용한다(저장된 상태 위에 다시 적용하면 `expense.created`의 notes가 돌아오지 않는다). 구 앱이 계속 쓰이는 동안 그 앱에서는 복원된 지출이 삭제된 채로 보인다.

### 적용 규칙 (앱 Dart·서버 Kotlin 동일, `shared/sync-cases.json`으로 검증)
1. `applyEvent(state, event)`는 순수 함수. 같은 이벤트 두 번 적용 = 한 번 적용.
2. 수정 vs 수정: 필드 단위로 seq 큰 쪽이 이긴다(순서대로 적용하면 자연히 성립).
3. 삭제 vs 수정: `deleted=true`인 지출·송금에 오는 `updated`는 무시한다(삭제가 이김). 삭제된 지출을 되살리는 것은 `expense.restored`뿐이고, 삭제되어 있던 동안 무시된 `updated`는 복원 뒤에도 되살아나지 않는다.
4. 없는 대상에 오는 `updated`·`deleted`·`restored`·`linked`·`removed`·`confirmed`·`comment.deleted`는 무시한다.
5. `member.removed`는 `removed=true`만 표시한다. 잔액 계산에는 계속 포함된다.
6. `payment.confirmed`는 `status`를 `confirmed`로 바꾼다. 없거나 삭제된 송금이면 무시한다. 잔액은 `sent`와 `confirmed` 송금을 똑같이 반영한다(앱은 `sent`를 "확인 대기"로 표시).
7. `expense.restored`는 `deleted=false`로 되돌린다. 삭제되지 않은 지출이면 아무것도 바꾸지 않는다. 삭제와 복원이 엇갈리면 seq 순서상 나중 것이 이긴다.
8. `comment.added`는 `commentId`가 처음일 때만 댓글을 뒤에 추가한다(이미 있으면 — 삭제된 댓글 포함 — 무시, 멱등). `comment.deleted`는 `deleted=true`로 표시하고 `text`를 `""`로 비운다(목록에서 빼지 않는다). 서버 로그의 `comment.added`도 `text: ""`로 오므로(snapshot 아래), 글을 본 기기와 못 본 기기가 같은 상태가 된다. 적용기는 지출 존재 여부를 확인하지 않는다(서버 검증이 보장).
9. 빠진 필드: `expense.created`에 `notes`가 없으면 `null`. `expense.updated`는 `fields`에 있는 키만 바꾸며, `notes`·`category`·`fxRateToDefault`는 `null`이 오면 지우고, 나머지 키의 `null`은 무시한다.

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

## 활동·알림
변경 기록(이벤트 로그)에서 만든 **활동 피드**, 다른 사람의 변경을 알려 주는 **표시 푸시**, 알림 설정. 피드 항목은 구조화된 데이터이고 문장은 앱(목록)과 서버(푸시)가 같은 규칙으로 만든다(아래 "문장", `shared/activity-cases.json`으로 양쪽 검증).

### 피드
| 메서드 | 경로 | 요청 | 응답 |
|---|---|---|---|
| GET | `/groups/{id}/activity?before=<seq>&limit=50` | | `ActivityPage` — seq 큰 순. 호출자는 멤버여야 함(403), 그룹 없음 404 |
| GET | `/activity?before=<feedId>&limit=50` | | `ActivityPage` — 호출자가 지금(removed 아님) 멤버인 모든 그룹, feedId 큰 순 |

```
ActivityPage {"items": [ActivityItem], "nextBefore": number|null}
ActivityItem {"groupId","feedId","seq","kind","createdAt","actorMemberId",
              "memberId","expenseId","commentId","paymentId",
              "name","description","amount","currency","fromMember","toMember","status","myDelta","text",
              "changes": [{"field","from","to"}]}
```
- `before` 생략 = 최신부터. 그룹 피드는 `seq < before`, 전체 피드는 `feedId < before`. `limit`은 1~100으로 잘라 맞추고 기본 50. 숫자가 아니면 400 `VALIDATION`.
- 숨김 이벤트 때문에 `items`가 `limit`보다 적거나 비어 있어도 끝이 아닐 수 있다. **`nextBefore`가 null일 때만 끝**이고, 아니면 그 값을 다음 요청의 `before`로 넘긴다.
- `feedId`: 서버가 이벤트를 저장한 순서의 전역 번호(그룹 안에서는 seq와 같은 순서). 앱은 오프라인용 캐시를 이 순서로 정렬한다.
- 모든 키는 항상 있다. 해당 없는 필드는 `null`, `changes`는 `[]`.
- `createdAt`은 **서버가 이벤트를 저장한 시각**(`events.received_at`)이다. 이벤트의 createdAt(앱 시계)은 오프라인 수정을 나중에 올리거나 기기 시계가 틀리면 목록 순서(seq·feedId)와 어긋나므로 쓰지 않는다. 이 기능 전에 저장된 이벤트는 그 이벤트의 createdAt. 앱은 이 값으로 시각과 날짜 머리글을 그린다(목록 순서와 같은 순서). `seq`는 그룹 안 이벤트 번호(탭하면 `expenseId`의 지출을 연다).

| kind | 원본 이벤트 | 채워지는 필드 |
|---|---|---|
| `group_created` | `group.created` | `name`(그룹 이름) |
| `group_updated` | `group.updated` | `changes`(`name`, `defaultCurrency`) |
| `member_added` | `member.added`(payload `userId`가 보낸 사람이 아님 — 자리표시 추가) | `memberId` |
| `member_joined` | `member.added`(payload `userId` = 보낸 사람, 초대로 새 멤버), `member.linked` | `memberId` |
| `member_removed` | `member.removed` | `memberId` |
| `expense_added` | `expense.created` | `expenseId`, `description`, `amount`, `currency`, `myDelta` |
| `expense_updated` | `expense.updated` | 위와 같음 + `changes` |
| `expense_deleted` | `expense.deleted` | `expenseId`, `description`, `amount`, `currency`, `myDelta` |
| `expense_restored` | `expense.restored` | `expenseId`, `description`, `amount`, `currency`, `myDelta` |
| `comment_added` | `comment.added` | `expenseId`, `commentId`, `description`(그 지출의), `text`(댓글) |
| `payment_added` | `payment.created` | `paymentId`, `fromMember`, `toMember`, `amount`, `currency`, `status` |
| `payment_confirmed` | `payment.confirmed` | 위와 같음 |
| `payment_deleted` | `payment.deleted` | 위와 같음 |

값을 정하는 규칙:
- `actorMemberId`: 이벤트의 `actorUserId`에 연결된 멤버. 이벤트 적용 **직후** 상태에서 찾고, 없으면 같은 push 배치를 모두 적용한 상태에서 찾는다(그래서 seq 1 `group.created`의 actor는 seq 2에서 추가된 만든 사람). 그래도 없으면 `null`.
- 지출 필드(`description`, `amount`, `currency`)는 이벤트 적용 직후의 그 지출 값(`expense_deleted`는 삭제 직전과 같은 값). `comment_added`의 `description`도 댓글이 달린 시점의 지출 설명이다. 송금 필드도 적용 직후의 송금 값(`status` 포함).
- `myDelta`: 보는 사람(호출자의 그 그룹 멤버)에게 이 지출이 주는 잔액 변화, 적용 직후 값으로 `(paidBy가 나면 amount, 아니면 0) − (내 share, 없으면 0)`, `currency`의 최소 단위. 내가 낸 사람도 아니고 share에도 없으면 `null`.
- `changes`(`expense_updated`): `fields`에 있는 키 중 직전 값과 직후 값이 다른 것만, 순서 `description, amount, currency, fxRateToDefault, paidBy, date, category, shares, notes`. `from`/`to`는 직전/직후 값이고 `shares`·`notes`는 둘 다 `null`(목록에는 "split"·"notes"로만 나온다). `group_updated`는 `name, defaultCurrency` 순서.
- 숨김(항목을 만들지 않고 푸시도 없음):
  1. 적용기가 상태를 바꾸지 않은 이벤트 — 이미 있는 id의 `created`·`added`, 삭제된 지출의 `updated`, 같은 값으로의 `updated`, 삭제 안 된 지출의 `restored`, 없거나 삭제된 송금의 `confirmed` 등.
  2. seq 2의 `member.added`(POST /groups가 만든 사람 자신을 넣는 이벤트. `group_created`와 겹친다).
  3. `comment.deleted`.
  4. 모르는 type.
  5. 댓글이 **지금** 삭제되어 있는 `comment_added`(삭제하면 글이 피드와 아직 묶여 있던 푸시에서 빠진다. 같은 push에서 쓰고 지운 댓글은 알리지 않는다). 이것만 현재 상태를 보므로 `shared/activity-cases.json`(이벤트 시점 규칙)에는 없고 서버 테스트가 검증한다.
- 서버는 push 트랜잭션 안에서 이벤트마다 직전·직후 상태를 알고 있으므로 피드에 필요한 값(actorMemberId, 대상 지출·송금의 직전·직후 값, 상태 변화 여부)을 이벤트 행의 `meta`(서버 내부, pull에 없음)에 기록하고 피드는 그것만 읽는다. 이 기능 이전에 저장된 이벤트는 서버가 시작할 때 그룹 로그를 seq 1부터 다시 적용해 `meta`를 채운다.

### 문장 (영어, 앱 목록·서버 푸시 공통)
보는 사람을 `me`(그 그룹의 내 멤버)로 두고 만든다. 9단계(언어)에서 번역할 때까지 영어 한 가지.
- 이름: `me`이면 문장 맨 앞 `You`, 그 밖 `you`. id가 `null`이거나 이름을 모르면 `Someone`/`someone`. 그 밖에는 멤버 이름 그대로.
- 금액 표기: `shared/currencies.json`의 `symbols[통화]` + 정수부 3자리마다 `,` + (소수 자릿수가 0이 아니면) `.`과 소수부(자릿수만큼 0 채움). 기호와 숫자 사이 공백 없음: `€30.00`, `₩15,000`, `CHF12.50`, `din1,234.567`. 앱의 `formatMoney`(intl en_US)와 같은 결과다. 음수는 쓰지 않는다(`myDelta`는 절댓값).
- 따옴표는 `“ ”`(U+201C/U+201D), 구분점은 ` · `(U+00B7 앞뒤 공백), 화살표는 ` → `(U+2192 앞뒤 공백). `{A}` = actor 이름(문장 맨 앞 규칙), `{M(x)}` = 금액 표기.

| kind | 문장 |
|---|---|
| `group_created` | `{A} created the group “{name}”` |
| `group_updated` | `{A} changed the group: {변경들}` — `name “{from}” → “{to}”`, `currency {from} → {to}`를 `, `로 잇는다 |
| `member_added` | `{A} added {member}` |
| `member_joined` | `{member} joined` (member가 맨 앞) |
| `member_removed` | `{A} removed {member}` |
| `expense_added` | `{A} added “{description}” · {M(amount)}` + `myDelta < 0`이면 ` · you owe {M(−myDelta)}`, `> 0`이면 ` · you lent {M(myDelta)}`, 0·null이면 없음 |
| `expense_updated` | `{A} changed “{description}”: {변경들}` (아래, `, `로 잇는다) |
| `expense_deleted` | `{A} deleted “{description}”` |
| `expense_restored` | `{A} restored “{description}”` |
| `comment_added` | `{A} commented on “{description}”: {text}` |
| `payment_added` | `{from} paid {to} {M(amount)}` (from이 맨 앞) + `status`가 `sent`면 ` · waiting for {to} to confirm` |
| `payment_confirmed` | `{A} confirmed receiving {M(amount)} from {from}` |
| `payment_deleted` | `{A} deleted a payment of {M(amount)} from {from} to {to}` |

`expense_updated`의 변경 표기: `description` → `description “{from}” → “{to}”` · `amount` → `{M(from)} → {M(to)}`(from은 `currency` 변경이 있으면 그 `from` 통화로, 없으면 `currency`로 표기) · `currency` → `currency {from} → {to}` · `fxRateToDefault` → `exchange rate` · `paidBy` → `paid by {from 이름} → {to 이름}` · `date` → `date {from} → {to}`(YYYY-MM-DD 그대로) · `category` → `category` · `shares` → `split`(단, `amount`도 바뀌었으면 생략 — 금액이 바뀌면 분할은 늘 바뀐다) · `notes` → `notes`.

### 푸시
- 이벤트가 **새로 저장된** push가 커밋되면(clientId 중복만 있는 재시도는 알림 없음) 그룹의 연결된·removed 아닌 멤버 가운데 **보낸 사용자가 아닌** 사용자의 기기(FCM 토큰 있는)로 보낸다. 내 변경은 내 기기에 알리지 않는다(지금과 같음).
- 수신자마다 이번 push의 새 이벤트로 ActivityItem을 만들고(`me` = 수신자의 멤버), 숨김 항목과 수신자의 알림 설정이 끈 분류를 뺀다. 분류: `expenses` = `expense_*`·`payment_*`, `comments` = `comment_added`, `members` = `member_*`·`group_updated`.
- 남은 항목이 있으면 **표시 알림**(FCM notification + data): title = 그룹 이름(보낼 때의 이름), body = 항목이 1개면 그 문장, 2개 이상이면 묶음 문장.
- 묶음: 수신자·그룹마다 마지막 표시 알림 뒤 `EVENSIES_PUSH_BATCH_SECONDS`(기본 30)초 안에 생긴 항목은 바로 보내지 않고 모아 두었다가, 그 시간이 지나는 순간 모은 항목 전부를 표시 알림 하나로 보낸다. 서버 메모리에만 두므로 재시작하면 모은 항목은 버려진다.
- 표시 알림을 보내지 않는 push(남은 항목 없음, 알림 꺼짐, 묶는 중)에도 **data만 있는 메시지**는 바로 보낸다(동기화용, 지금과 같음).
- data는 언제나 `{"type":"sync","groupId":"...","seq":"<보낼 때의 latestSeq>"}`(FCM data 값은 문자열).
- 묶음 문장(항목 2개 이상, 수신자는 actor가 아니므로 `You`는 나오지 않는다): 모든 항목의 `actorMemberId`가 같고 모두 `expense_added`면 `{A} added {n} expenses`, 모두 `comment_added`면 `{A} added {n} comments`, 그 밖이면 `{A} made {n} changes`. actor가 섞이면 `{n} new changes`.
- 앱: 표시 알림을 누르면 그 그룹의 활동 탭을 연다. 앱이 앞에 있을 때 온 알림은 시스템 알림 대신 앱 안 배너(같은 title/body)로 보여 주고 sync한다.
- 길이: title은 100자, body는 200자(UTF-16)를 넘으면 잘라서 끝을 `…`로 한다(`…` 포함 그 길이, 서로게이트 쌍은 자르지 않음). 긴 댓글·설명·그룹 이름이 FCM/APNs 4096바이트 한도를 넘겨 data까지 잃지 않게 하기 위해서다. 앱 목록의 문장은 자르지 않는다.
- FCM 멀티캐스트는 토큰 500개씩 나눠 보낸다. FCM이 `UNREGISTERED`로 답한 토큰과, 같은 멀티캐스트에서 다른 토큰은 성공했는데 `INVALID_ARGUMENT`로 답한 토큰은 기기 행을 지운다.
- iOS(APNs): 표시 알림은 `sound: default`, `thread-id: <groupId>`(그룹별로 묶임). data만 있는 메시지는 `content-available: 1`, `apns-priority: 5`, `apns-push-type: background`(앱이 백그라운드에서 깨어 sync).
- FCM 자격 증명(`EVENSIES_FCM_CREDENTIALS_FILE`)이 없으면 조용히 건너뛴다.

### 알림 설정
| 메서드 | 경로 | 요청 | 응답 |
|---|---|---|---|
| GET | `/me/notifications` | | `NotificationPrefs` — 저장한 적 없으면 모두 `true` |
| PUT | `/me/notifications` | `NotificationPrefs` (세 키 모두 필수 boolean, 전체 교체) | `NotificationPrefs`. 키가 빠지거나 boolean이 아니면 400 `VALIDATION` |

```
NotificationPrefs {"expenses": bool, "comments": bool, "members": bool}
```
`expenses` = 지출·송금, `comments` = 댓글, `members` = 멤버 참여·추가·제외와 그룹 이름·통화 변경. 꺼도 동기화용 data 메시지는 계속 온다. `DELETE /me`는 설정도 지운다.

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
| `EVENSIES_PUSH_BATCH_SECONDS` | `30` | 수신자·그룹마다 표시 알림 사이의 최소 간격(그 안의 변경은 묶어서 보냄) |
| `EVENSIES_INVITE_RATE_PER_MINUTE` | `10` | 초대 조회·참여·랜딩의 IP당 분당 허용 횟수 |
| `EVENSIES_PUBLIC_URL` | `http://localhost:8080` | 초대 링크 도메인 |
