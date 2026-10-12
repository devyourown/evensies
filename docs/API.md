# Evensies API·동기화 계약

서버(Spring Boot)와 앱(Flutter)이 공유하는 계약. 양쪽 구현은 이 문서를 따른다. 바꾸려면 이 문서부터 고친다.

## 공통 규칙
- 모든 ID는 UUID 문자열(앱이 생성). 이벤트 payload의 id는 소문자 표준 표기(`xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`, `UUID.toString()`과 같은 값)만 받는다. 대문자나 `1-1-1-1-1` 같은 짧은 표기는 400 `VALIDATION`(상태는 문자열로, 테이블은 파싱한 UUID로 찾으므로 다른 표기는 같은 행을 다른 엔티티처럼 덮어쓸 수 있다). 금액은 정수(최소 단위, `shared/currencies.json` — 4단계부터 ISO 4217 155개, "통화 환산"). 날짜는 `YYYY-MM-DD`, 시각은 ISO-8601 UTC.
- JSON 키는 camelCase. null 허용 필드는 명시적으로 `null`로 보낸다.
- 인증: `Authorization: Bearer <access>`. 미인증 → 401. 그룹 멤버가 아님 → 403. 없음 → 404.
- 오류 본문: `{"code": "SUM_MISMATCH", "message": "..."}`. 검증 오류는 400.

## 인증
| 메서드 | 경로 | 요청 | 응답 |
|---|---|---|---|
| POST | `/auth/apple` | `{"idToken": "...", "displayName"?: "..."}` — Apple은 이름을 토큰에 넣지 않고 첫 로그인 때만 앱에 주므로 앱이 함께 보낸다 | `{"accessToken","refreshToken","user": UserDto}` |
| POST | `/auth/google` | `{"idToken": "..."}` | 위와 같음 |
| POST | `/auth/dev` | `{"name": "Anna"}` — **`evensies.auth.dev-login=true`일 때만** 존재. 같은 name이면 같은 사용자 | 위와 같음 |
| POST | `/auth/refresh` | `{"refreshToken"}` | `{"accessToken","refreshToken"}` (refresh 회전) |
| GET | `/me` | | `UserDto`. `displayName`이 빈 문자열이면 앱은 이름 입력 화면을 띄운다(이메일은 이름으로 쓰지 않음) |
| PATCH | `/me` | `{"displayName"?: string, "homeCurrency"?: string}` — 하나 이상 필요. `displayName`은 공백 제거 후 1~30자(이모지 허용), `homeCurrency`는 `shared/currencies.json`의 코드(대문자 그대로) | `UserDto`(바꾼 뒤). 아래 규칙 |
| DELETE | `/me` | | 204. 사용자 행은 deleted_at, 모든 Member.user_id는 null(자리표시로 전환). 6단계: `friend_code`를 `NULL`로 하고 그 사용자의 `friendships`·`reminders`(보낸 것·받은 것)·`activity_seen` 행을 지우며, 커밋 뒤 프로필 사진 파일을 지운다(친구에게는 기록이 그대로인 자리표시 친구로 보인다) |
| POST | `/devices` | `{"deviceId","fcmToken"}` | 204. 사용자당 최근에 등록한 기기 10개만 남기고 오래된 것은 지운다. 같은 `fcmToken`을 가진 다른 기기 행(다른 사용자 포함)도 지운다(한 폰에서 다른 계정으로 로그인하면 이전 사용자의 푸시가 끊긴다) |
| DELETE | `/devices/{deviceId}` | | 204. 호출자 본인의 그 기기 행만 지운다(없거나 다른 사용자의 기기면 아무것도 안 하고 204). 앱은 로그아웃할 때 세션을 지우기 **전에** 보낸다. 오프라인이면 실패해도 로그아웃은 진행한다. 앱은 세션이 사라지면(로그아웃, 계정 삭제, 토큰 갱신 실패) 그 폰의 FCM 토큰도 지운다(FCM `deleteToken`, 오프라인이면 로그아웃 상태로 다음 실행·복귀 때 다시 시도). 그러면 서버의 다음 발송이 `UNREGISTERED`를 받아 남은 행을 지운다 |

```
UserDto {"id","displayName","homeCurrency": string|null}
```
- `homeCurrency`(4단계): 사용자의 표시용 통화("≈ $13.46"). 저장한 적 없으면 `null`이고 앱은 기기 지역의 통화(`Money.currencyForLocale`)를 쓴다. 로그인 응답의 `user`, `GET /me`, `PATCH /me` 모두 같은 `UserDto`다. 앱은 키가 없는 응답(이전 서버)을 `null`로 읽는다.
- 새로 고침(5단계): 앱은 저장된 세션으로 시작할 때와 앞으로 돌아올 때마다(resume, `syncAll`과 함께) `GET /me`를 불러 받은 `displayName`·`homeCurrency`를 세션에 덮어쓴다. 다른 폰에서 바꾼 이름·홈 통화가 다시 로그인하지 않아도 보인다. 오프라인·5xx·429면 저장된 값을 그대로 둔다. 401은 지금처럼(토큰 갱신이 실패하면 로그아웃). 로그인 직후에는 로그인 응답의 `user`를 쓴다. 받은 `displayName`이 빈 문자열이면 이름 입력 화면(위).
- `PATCH /me` 검사(모두 검사한 뒤 한꺼번에 저장): `null`인 키는 없는 것으로 본다. 두 키가 모두 없으면(`{}` 포함) 400 `VALIDATION`. `displayName`이 범위 밖이면 400 `VALIDATION`. `homeCurrency`가 문자열이 아니면 400 `VALIDATION`, 목록에 없는 코드면(`"usd"` 포함) 400 `UNKNOWN_CURRENCY`. 홈 통화는 지울 수 없다(바꾸기만). 이전 본문 `{"displayName"}`은 그대로 동작한다. 앱은 온라인일 때만 보낸다(오프라인 큐 없음). 삭제된 계정은 401(지금과 같음).

access 15분, refresh 30일. JWT HS256, 비밀은 `EVENSIES_JWT_SECRET`.

## 그룹
| 메서드 | 경로 | 요청 | 응답 |
|---|---|---|---|
| POST | `/groups` | `{"id","name","defaultCurrency","memberId","memberName"}` — id·memberId는 앱이 생성, `name`은 1~100자 | `GroupDto` (seq 1·2에 `group.created`, `member.added` 이벤트가 기록됨) |
| GET | `/groups` | | `[GroupSummaryDto]` |
| GET | `/groups/{id}` | | `GroupDto` |
| POST | `/groups/{id}/invite/rotate` | | `{"inviteCode"}` |
| GET | `/invites/{code}` | 인증 불필요 | `{"groupId","name","kind","memberCount","members":[{"id","name","linked":bool}]}` |
| POST | `/invites/{code}/join` | `{"memberId": "<기존 자리표시 멤버>"}` 또는 `{"newMemberId","name"}` | `GroupDto`. `member.linked` 또는 `member.added`(userId 포함) 이벤트 기록. 6단계: 친구 그룹이면 `newMemberId`는 409 `LIMIT_EXCEEDED`(멤버는 2명), 자리표시 claim은 그룹 상한 검사 없이 받고 `friendships` 행을 넣는다(아래 "친구") |

```
GroupDto        {"id","name","defaultCurrency","inviteCode","createdAt","latestSeq","myMemberId","simplifyDebts","defaultSplit","kind"}
GroupSummaryDto {"id","name","defaultCurrency","latestSeq","memberCount","kind"}
```
- `kind`(6단계): `"group"`(보통 그룹) 또는 `"friend"`(친구 그룹, 아래 "친구"). `GroupDto`·`GroupSummaryDto`·snapshot의 `group`·`GET /invites/{code}`에 있다. 앱은 키가 없는 응답(이전 서버)을 `"group"`으로 읽는다. 그룹을 만들 때 정해지고 바뀌지 않는다(적용 규칙 13). `POST /groups`는 언제나 `"group"`이고 친구 그룹은 `POST /friends`만 만든다. 앱의 Groups 탭은 `"group"`만 보이고, 친구 그룹은 Friends 탭에서 사람으로 보인다(`/groups/{id}`로 열면 친구 페이지로 보낸다).
- `simplifyDebts`(boolean, 기본 `true`)와 `defaultSplit`(`SplitSpec|null`, 기본 `null`, 아래 "SplitSpec")은 그룹 설정이다. `POST /groups`·`GET /groups/{id}`·`POST /invites/{code}/join` 응답과 snapshot의 `group`에 있다(`GroupSummaryDto`에는 없다). 앱은 두 키가 없는 응답을 기본값으로 읽는다. `POST /groups`는 기본값으로 만든다(요청에 두 키 없음).
- 그룹 설정(이름, 기본 통화, 부채 단순화, 기본 분할)을 바꾸는 엔드포인트는 없다. `group.updated` 이벤트로 바꾸고, 그룹 멤버 누구나 보낼 수 있다(관리자 없음). 기본 통화는 지출이나 송금이 하나라도 생기면(삭제된 것 포함) 더 바뀌지 않는다(적용 규칙 12).
- **그룹 나가기** = 자기 멤버에 대한 `member.removed`. 서버는 다른 멤버를 빼는 것과 똑같이 처리한다(잔액이 0인지는 앱만 확인한다. 4단계부터는 모든 통화 칸에서 0, "통화별 잔액"). 그 뒤 그 그룹은 `GET /groups`에서 빠지고 그 그룹의 엔드포인트는 403이다. 나간 멤버는 removed로 남고(사용자 연결도 남는다) 잔액 계산에도 남는다(규칙 5). 초대로 다시 들어오면 새 멤버(또는 다른 자리표시 멤버)가 된다. 8단계: 내가 활성 반복 시리즈의 template(`payers`나 `shares`에 0보다 큰 금액)에 있으면 앱이 나가기를 막는다(나간 뒤에도 내 몫으로 반복이 생겨 아무도 정산할 수 없는 빚이 되므로): `You're still in 2 repeating expenses (Rent, Netflix) · edit the latest one or stop them first`(이름은 `seriesNames`, 최대 3개 뒤 `and N more`). 설정 화면이 누르기 전에, `leaveGroup`이 동기화한 뒤 잔액 검사 옆에서 다시 확인한다. 서버는 확인하지 않는다.
상한: 그룹당 멤버 50, 사용자당 그룹 100 → 초과 시 409 `LIMIT_EXCEEDED`. 6단계: 사용자당 100은 `kind = 'group'`만 센다(`POST /friends`와 친구 그룹 claim은 이 검사를 하지 않는다). 대신 자리표시 친구는 사용자당 200(아래 "`POST /friends`"). 친구 그룹의 멤버는 정확히 2명이다. 8단계: 그룹당 멈추지 않은 반복 시리즈 100(`recurrence.created`, 아래 "반복 지출").

초대 코드: **6자, 알파벳 `23456789ABCDEFGHJKMNPQRSTUVWXYZ`**(0/O, 1/I/L 제외). 이전에 발급된 10자 코드도 계속 유효하다. `/invites/{code}`, `/invites/{code}/join`, `/j/{code}`는 코드를 정규화한다(대문자로 바꾸고 영문·숫자 외 문자는 제거: `k7p-4qx` = `K7P4QX`). 세 엔드포인트는 **클라이언트 IP당 분당 10회**(`EVENSIES_INVITE_RATE_PER_MINUTE`)로 제한되며 초과 시 429 `RATE_LIMITED`.

친구 코드(6단계, `users.friend_code`)도 같은 알파벳·길이·정규화를 쓴다. 그룹 초대 코드와 이름 공간이 하나다: 새 코드는 `groups.invite_code`와 `users.friend_code` 어디에도 없는 것만 쓴다(`GroupService.newInviteCode`도 두 표를 본다). 그래서 한 코드는 그룹이거나 친구이고 둘 다는 아니다. IP당 버킷은 **하나**를 초대 세 엔드포인트와 친구 코드 조회(`GET /friend-invites/{code}`, `GET /f/{code}`, `POST /friends {code}`)가 함께 쓴다(`InviteController`의 필드에서 bean으로 옮긴다). 앱의 코드 입력 칸은 `/invites/{code}`를 먼저 부르고 404면 `/friend-invites/{code}`를 부르므로 친구 코드 하나에 2회를 쓴다.

## 이벤트 (동기화)
### push
`POST /groups/{id}/events`
```
요청: [{"clientId":"uuid","type":"expense.created","payload":{...},"createdAt":"2026-10-10T09:00:00Z"}]
응답: {"results":[{"clientId":"uuid","seq":12}], "latestSeq": 12}
```
- 배열 전체가 한 트랜잭션. 그룹 행 `SELECT ... FOR UPDATE`로 잠근 뒤 seq 부여.
- `(group_id, client_id)` UNIQUE. 중복은 기존 seq를 돌려준다(오류 아님).
- 서버는 같은 트랜잭션에서 이벤트를 테이블(member/expense/expense_share/payment/comment, 7단계 attachment, 8단계 recurrence)에 반영하고, 활동 피드용 `meta`를 이벤트 행에 기록한다("활동·알림").
- 검증 실패(그룹 밖 memberId, 분할 합 불일치, 음수, 새로 만드는 이벤트(`*.created`·`member.added`·`comment.added`, 8단계 `recurrence.created` 포함)의 id가 다른 그룹에 이미 있음, 7단계: 이 그룹에 올리지 않은 `attachment.added`)는 배열 전체 거부 400(7단계 영수증 개수 상한은 409). `group.created`는 서버만 만든다(앱이 push하면 400 `VALIDATION`). 다른 이벤트(`updated`·`deleted`·`restored`·`linked`·`removed`·`confirmed`, 7단계 `attachment.deleted`·`payment.restored`, 8단계 `recurrence.updated`·`recurrence.deleted` 포함)가 다른 그룹의 id를 가리키면 이 그룹에는 없는 대상이므로 통과하고 적용 규칙 4로 무시된다(다른 그룹은 바뀌지 않음, 다른 그룹의 영수증 파일도 지우지 않는다). 속도 제한: 사용자당 분당 120 이벤트 → 429.
- 결제자·분할·그룹 설정의 검증과 오류 코드는 아래 "결제자·분할·그룹 설정 검증", 반복 시리즈(8단계)는 "반복 지출 검증".
- 오프라인 기기가 알 수 없는 상태(다른 사람이 먼저 한 변경) 때문에 400을 내지 않는다. 그런 경우는 적용 규칙(예: 규칙 12)이나 서버의 정규화(예: `paidBy`를 주요 결제자로 고침)로 처리한다.

#### 거부된 이벤트 (앱)
한 이벤트가 거부되어 outbox가 영원히 막히지 않도록 앱은 다음처럼 한다.
1. push가 **400 또는 409**로 실패하면, 같은 배치를 순서대로 **한 이벤트씩** 다시 보낸다. 받아들여진 이벤트는 바로 outbox에서 지운다(clientId로 멱등이므로 안전).
2. 한 이벤트만 보내도 400·409이면 그 이벤트를 버린다: outbox 행의 `rejected`에 오류 `code`를 적고(다시 보내지 않고 로컬에 다시 적용하지도 않는다) 사용자에게 `Couldn't save {무엇}: {이유}`를 보여 준 뒤 행을 지운다(보여 주기 전에 앱이 꺼지면 다음 실행 때 보여 준다). {무엇}은 이벤트 종류별 문구다: `the new expense “Hotel”`, `a change to “Hotel”`, `deleting “Hotel”`, `a payment`, `a group settings change` 등(설명을 모르면 `an expense`). 7단계: `attachment.added` → `the receipt on “Hotel”`, `attachment.deleted` → `removing a receipt from “Hotel”`, `payment.restored` → `restoring a payment`. 8단계: `recurrence.created` → `repeating “Rent”`, `recurrence.updated` → `a change to future “Rent”`, `recurrence.deleted` → `stopping “Rent” from repeating`(설명은 payload의 `template`·`fields`, 없으면 로컬 시리즈의 template에서. 모르면 각각 `a repeating expense`·`a change to a repeating expense`·`stopping a repeating expense`). 거부된 `recurrence.created`의 첫 지출(그 `recurrenceId`의 `expense.created`)은 받아들여졌으면(정규화가 시리즈 표시를 빼고 저장) `Couldn't save …` 대신 `“Water” was saved but won't repeat: {이유}`를 보인다(같은 지출을 다시 넣지 않게). 그 지출도 거부됐으면 위 문구 그대로. 버린 `attachment.added`의 영수증은 로컬 행과 캐시 파일도 지운다(서버에 남은 올린 파일은 8단계 정리가 지운다).
3. push가 **403**이거나 pull이 **403·404**이면 먼저 `GET /groups/{id}`를 부른다. 서버 자신의 403 `FORBIDDEN`·404 `NOT_FOUND`(오류 본문이 있는 응답)면 그 그룹에서 빠진 것이므로(나감·제외) 거부 처리 없이 그 그룹의 로컬 데이터를 지운다(syncAll과 같음). 200이면 push의 403은 이벤트 권한 문제이므로 1·2의 400처럼 다룬다. 오류 본문이 없는 응답(`NETWORK`: 프록시·캡티브 포털 등)은 거부로 보지 않고 4처럼 다시 보낸다.
4. 하나씩 보내는 중 401·429·5xx·네트워크 오류가 나면 거기서 멈추고 남은 이벤트는 outbox에 그대로 두어 지금처럼 나중에 다시 보낸다. (하나씩 다시 보내면 속도 제한을 한 번 더 쓴다: 실패한 배치 N개 + 다시 N개.)
5. 하나라도 버렸으면 그룹을 다시 만든다: `adoptFromSnapshot` 뒤에 남은(아직 안 보낸, 버리지 않은) outbox 이벤트를 순서대로 적용한다. 버린 이벤트의 낙관적 로컬 변경이 남지 않게 하기 위해서다.

| code | {이유} |
|---|---|
| `SUM_MISMATCH` | the split doesn't add up |
| `PAYERS_SUM_MISMATCH` | the payers don't add up |
| `NEGATIVE_AMOUNT` | an amount is below zero |
| `UNKNOWN_MEMBER` | it refers to someone who isn't in the group |
| `UNKNOWN_CURRENCY` | the currency isn't supported |
| `MEMBER_TAKEN` | that member is already taken |
| `LIMIT_EXCEEDED` | the group is full (7단계 `attachment.added`이면 an expense can have at most 10 receipts, 8단계 `recurrence.created`이면 a group can have at most 100 repeating expenses) |
| `ATTACHMENT_NOT_UPLOADED` | the photo didn't upload (7단계) |
| `FORBIDDEN` | you're not allowed to make that change |
| 그 밖(`VALIDATION` 등) | the server refused it |

### pull
`GET /groups/{id}/events?after=<seq>&limit=500`
```
응답: {"events":[{"seq","clientId","type","payload","actorUserId","createdAt"}], "latestSeq": 57}
```
- 8단계: 서버 스케줄러가 만든 반복 지출(`expense.created`)은 `"actorUserId": null`이고 `createdAt`은 그 반복의 `dueAt`(아래 "반복 지출")이다. 앱은 `actorUserId`를 이미 `string|null`로 읽는다.
### snapshot
`GET /groups/{id}/snapshot`
```
{"group": GroupDto,
 "members":  [{"id","name","userId","removed":bool}],
 "expenses": [{"id","description","amount","currency","fxRateToDefault","paidBy","payers":[{"memberId","amount"}],"refund":bool,"split","date","category","notes","deleted":bool,"moved":bool,"recurrenceId","occurrence","shares":[{"memberId","amount"}]}],
 "payments": [{"id","fromMember","toMember","amount","currency","date","deleted":bool,"status","replaced":bool}],
 "comments": [{"id","expenseId","paymentId","authorMemberId","text","createdAt","deleted":bool}],
 "attachments": [{"id","expenseId","deleted":bool}],
 "recurrences": [RecurrenceDto],
 "latestSeq": 57}
```
- `recurrences`(8단계, "반복 지출"): 그룹의 모든 시리즈, 멈춘 것도 `deleted: true`로 포함한다. 순서는 만든 순서(`created_at, id`). 스케줄러 칸(`next_occurrence`·`next_due_at`)은 보내지 않는다. `template`은 저장된 JSON(jsonb라 키 순서는 다를 수 있다). 앱은 키가 없는 응답(이전 서버)을 `[]`로 읽는다.
- `recurrenceId`(`string|null`)·`occurrence`(`int|null`)(8단계): 반복 시리즈의 지출이면 그 시리즈 id와 번호(첫 지출 0, 서버가 올린 반복 1, 2, …), 아니면 둘 다 `null`. 앱은 키가 없는 응답을 `null`로 읽는다.
- `attachments`(7단계, "영수증"): 지출에 붙은(`attachment.added`가 적용된) 영수증만, 삭제된 것도 `deleted: true`로 포함한다. 올렸지만 아직 붙지 않은 것은 없다. 순서는 올린 순서(`created_at, id`)라 로그를 다시 적용한 순서와 다를 수 있다(보이는 순서만 다르다). 앱은 키가 없는 응답(이전 서버)을 `[]`로 읽는다.
- `replaced`(7단계)는 편집으로 바뀐(`replacedBy`가 있는 `payment.deleted`) 송금이면 `true`(적용 규칙 7, 언제나 `deleted: true`와 함께), 아니면 `false`. 앱은 키가 없는 응답을 `false`로 읽는다.
- `paidBy`는 주요 결제자(적용 규칙 10), `payers`는 1개 이상(보낸 순서), `refund`는 boolean, `split`은 `SplitSpec|null`. 이 단계 전의 지출은 `payers: [{paidBy, amount}]`, `refund: false`, `split: null`.
- `moved`(6단계)는 옮겨서 삭제된 지출이면 `true`(적용 규칙 13, 언제나 `deleted: true`와 함께), 아니면 `false`. 앱은 키가 없는 응답(이전 서버)을 `false`로 읽는다.
- `notes`는 `string|null`. `comments`는 삭제된 댓글도 `deleted: true`로 포함한다(지출·송금과 같음). `expenseId`·`paymentId`(6단계, 송금 댓글)는 하나만 문자열이고 다른 하나는 `null`이다. 이 단계 전의 댓글은 `paymentId: null`. snapshot의 `group`(`GroupDto`)에는 `kind`가 있다. pull 응답의 이벤트 모양은 바뀌지 않는다(서버 내부 `meta`는 보내지 않음).
- 삭제된 댓글의 `text`는 `""`(빈 문자열)이다(적용 규칙 8). 서버는 `comment.deleted`를 저장하는 push 트랜잭션에서 그 댓글의 저장된 `comment.added` 이벤트 payload `text`도 `""`로 바꾼다(로그에서 저장 뒤에 바뀌는 유일한 값. seq·clientId·나머지 payload는 그대로). 그래서 snapshot·내보내기·pull 어디에도 남지 않는다. 앱은 댓글 행의 글과 그 댓글의 활동 캐시 행을 지우고, 서버가 받은(push 성공한) outbox 행은 지운다.

### 이벤트 종류와 payload
| type | payload |
|---|---|
| `group.created` | `{"name","defaultCurrency","kind"?: "group"\|"friend"}` (서버가 POST /groups·POST /friends에서 생성). `kind`(6단계)는 POST /friends만 `"friend"`로 넣는다. 없으면 `"group"`(적용 규칙 13) |
| `group.updated` | `{"name"?: string, "defaultCurrency"?: string, "simplifyDebts"?: bool, "defaultSplit"?: SplitSpec\|null}` — 없는 키는 그대로, `"defaultSplit": null`은 지운다(규칙 11). `defaultSplit`의 mode는 `percent`·`shares`만. 지출·송금이 있는 그룹의 `defaultCurrency`는 400 없이 받아 저장하지만 적용하지 않는다(규칙 12). `kind` 키가 있으면(값과 상관없이, 모든 그룹) 400 `VALIDATION`(6단계) |
| `member.added` | `{"memberId","name","userId": string|null}` — 친구 그룹(6단계)에 셋째 멤버를 더하면 409 `LIMIT_EXCEEDED` |
| `member.linked` | `{"memberId","userId"}` — `userId`는 보낸 사람 본인. 이미 사용자에 연결된 멤버이거나 보낸 사람이 이 그룹에 이미 (removed 아닌) 멤버를 가지고 있으면 400 `MEMBER_TAKEN`. 앱은 보내지 않고 `/invites/{code}/join`이 만든다. `member.added`에 `userId`(본인)를 넣을 때도 이미 멤버가 있으면 같은 400 |
| `member.removed` | `{"memberId"}` (removed=true 표시, 삭제 아님). 보낸 사람 자신의 멤버면 그룹 나가기(활동 `member_left`). 친구 그룹(6단계)에서는 400 `VALIDATION`(나가기·빼기 없음, 친구 삭제는 10단계) |
| `expense.created` | `{"expenseId","description","amount","currency","fxRateToDefault": number|null,"paidBy","payers":[{"memberId","amount"}],"refund": bool,"split": SplitSpec|null,"date","category": string|null,"notes": string|null,"shares":[{"memberId","amount"}]}` — `description` 1~200자. `notes`(메모) 없으면 `null`(이전 이벤트 호환). 문자열이면 500자 이하. `payers` 없으면 `[{"memberId": paidBy, "amount": amount}]`, `refund` 없으면 `false`, `split` 없으면 `null`(이전 이벤트 호환). `paidBy`는 계속 보낸다(주요 결제자). `payers`가 있으면 서버가 저장 전에 `paidBy`를 주요 결제자로 고친다(pull되는 payload도 고친 값). 8단계: `"recurrenceId": string\|null, "occurrence": int\|null`(반복 시리즈 표시, 없으면 둘 다 `null`, 아래 "반복 지출 검증"·적용 규칙 16). 앱은 언제나 넣는다(반복 시리즈의 첫 지출은 `occurrence: 0`, 시리즈가 없으면 둘 다 `null`). `occurrence` ≥ 1은 서버 스케줄러만 만든다(`actorUserId: null`) |
| `expense.updated` | `{"expenseId","fields":{...바뀐 필드만, shares·notes·payers·refund·split 포함 가능}}` — `"notes": null`은 메모를, `"split": null`은 분할 입력을 지운다. 앱은 돈에 관한 필드(`amount`·`paidBy`·`payers`·`shares`·`split`·`refund`) 중 하나라도 바뀌면 여섯 개를 모두 보낸다. `fields.payers`가 있으면 서버가 `fields.paidBy`를 주요 결제자로 고치거나 넣는다. 8단계: `recurrenceId`·`occurrence`는 **함께** 넣는다(다른 시리즈에 다시 붙이기 `{"recurrenceId": 새 id, "occurrence": 0}`, 둘 다 `null`이면 시리즈에서 뺀다) |
| `expense.deleted` | `{"expenseId","movedTo"?: {"groupId","expenseId"}\|null}` — `movedTo`(6단계, "지출 옮기기"): 이 지출을 다른 그룹(친구 포함)의 새 지출로 옮겼다는 표시. 없거나 `null`이면 보통 삭제. 있으면 객체이고 두 값 모두 UUID 문자열(아니면 400 `VALIDATION`, 다른 키는 무시). 서버는 대상 그룹·지출이 있는지 보지 않는다. 적용은 보통 삭제에 더해 `moved=true`(규칙 13: 그 뒤 `expense.restored`는 무시). 활동은 `expense_moved` |
| `expense.restored` | `{"expenseId"}` — 삭제된 지출을 되살린다. 그룹 멤버 누구나 보낼 수 있다(삭제와 같음). 옮긴(`moved`) 지출에는 아무것도 바꾸지 않는다(규칙 13) |
| `comment.added` | `{"commentId","expenseId"?,"paymentId"?,"authorMemberId","text","createdAt"}` — `expenseId`와 `paymentId`(6단계, 송금 댓글) 가운데 **정확히 하나**(둘 다 있거나 둘 다 없으면 400 `VALIDATION`. `null`은 없는 것, 있으면 UUID 문자열). `authorMemberId`는 **호출자 본인의 멤버**(아니면 403 `FORBIDDEN`). `expenseId`는 그룹에 있는 지출, `paymentId`는 그룹에 있는 송금(둘 다 삭제된 것도 가능, 없으면 400 `VALIDATION`). `text`는 공백만이 아닌 1~1000자. `createdAt`은 ISO-8601 UTC 시각(앱이 이벤트의 createdAt과 같은 값을 넣는다) |
| `comment.deleted` | `{"commentId"}` — **작성자 본인만**(아니면 403 `FORBIDDEN`). 없는 댓글이면 통과하고 적용기가 무시. 댓글의 `text`를 `""`로 지운다(규칙 8) |
| `payment.created` | `{"paymentId","fromMember","toMember","amount","currency","date","status"?: "sent"\|"confirmed"}` — `status` 없으면 `confirmed`(이전 이벤트 호환). 받는 멤버가 자리표시자이거나 보내는 사람이 받는 사람 본인이면 서버가 `confirmed`로 저장. 6단계: `fromMember`와 `toMember`가 같으면 400 `VALIDATION`. `currency`는 목록의 어느 통화든 된다(지금처럼, 앱은 6단계부터 고르게 한다 — "송금 기록·편집") |
| `payment.confirmed` | `{"paymentId"}` — **받는 멤버에 연결된 사용자만** 보낼 수 있다(아니면 403 `FORBIDDEN`) |
| `payment.deleted` | `{"paymentId","replacedBy"?: string\|null}` — 보낸 사람 또는 받는 사람("받지 못함")이 보낼 수 있다(그리고 그 송금을 만든 사용자, 지금처럼 `paymentCreator`). `replacedBy`(7단계): 송금 편집(아래 "송금 기록·편집")이 넣는 새 송금의 id. 없거나 `null`이면 보통 삭제. 있으면 UUID 문자열(아니면 400 `VALIDATION`). 서버는 그 송금이 있는지 보지 않는다. 적용은 보통 삭제에 더해 `replaced=true`(규칙 7: 그 뒤 `payment.restored`는 무시) |
| `payment.restored` | `{"paymentId"}`(7단계) — 삭제된 송금을 되살린다(규칙 7). **그 송금을 지울 수 있는 사용자만**(`payment.deleted`와 같다: 만든 사용자, 보내는·받는 멤버에 연결된 사용자. 아니면 403 `FORBIDDEN`). 없는 송금이면 통과하고 적용기가 무시한다(규칙 4). 편집으로 바뀐(`replaced`) 송금이나 살아 있는 송금이면 400 없이 받아 저장하고 아무것도 바꾸지 않는다(오프라인 기기는 편집을 모를 수 있다) |
| `attachment.added` | `{"attachmentId","expenseId"}`(7단계, "영수증") — 그룹 멤버 누구나. 검사 순서: 두 값이 UUID 문자열(400 `VALIDATION`) → 상태에 이미 있는 `attachmentId`면 같은 `expenseId`일 때 통과(적용기가 무시, 멱등), 다른 지출이면 400 `VALIDATION` → 이 그룹에 올린 파일이 없으면(`POST /groups/{id}/attachments/{attachmentId}`를 하지 않았거나 다른 그룹에 올림) 400 `ATTACHMENT_NOT_UPLOADED` → `expenseId`가 상태에 없는 지출이면(삭제된 지출은 있는 것) 400 `VALIDATION` → 그 지출에 삭제 안 된 영수증이 이미 10개면 409 `LIMIT_EXCEEDED`. 같은 배치의 `expense.created` 뒤라면 통과한다(상태가 이벤트마다 나아간다) |
| `recurrence.created` | `{"recurrenceId","frequency": "weekly"\|"biweekly"\|"monthly"\|"yearly","startDate": "YYYY-MM-DD","timeZone": string,"template": {...}}`(8단계, "반복 지출") — 그룹 멤버 누구나(친구 그룹 포함). `template` = 이 시리즈가 만들 `expense.created` payload에서 `expenseId`·`date`·`recurrenceId`·`occurrence`를 뺀 것. 이미 있는 id면 받고 아무것도 바꾸지 않는다(규칙 15). payload의 다른 키는 적용기가 읽지 않는다(10단계가 `remindDaysBefore`를 더한다) |
| `recurrence.updated` | `{"recurrenceId","fields": {...}}`(8단계) — template에서 바뀐 키만, 키 이름·JSON 타입은 `expense.updated.fields`와 같다(`shares`·`payers`는 통째로). 앱은 `expense.updated`와 같은 규칙으로 보낸다: 돈 필드 하나가 바뀌면 여섯 개 모두, `currency`·`fxRateToDefault`는 둘 다(합치기는 키 단위뿐이고 규칙 10 같은 파생이 없다). 일정(`frequency`·`startDate`·`timeZone`)은 바꿀 수 없다(멈추고 새 시리즈). 없거나 멈춘 시리즈면 받고 무시. 이미 올라간 반복은 바뀌지 않는다 |
| `recurrence.deleted` | `{"recurrenceId"}`(8단계) — 시리즈를 멈춘다. 되살리는 이벤트는 없다(다시 반복하려면 새 시리즈). 이미 올라간 반복은 남는다. 없거나 이미 멈춘 시리즈면 받고 무시 |
| `attachment.deleted` | `{"attachmentId","expenseId"?}`(7단계) — 그룹 멤버 누구나. `attachmentId`는 UUID 문자열(400 `VALIDATION`). 없는 영수증이면 통과하고 적용기가 무시한다. `expenseId`는 선택이고 검사하지 않는다: 서버는 저장 전에 그 영수증이 붙은 지출의 id로 고치고(없는 영수증이면 키를 뺀다) pull되는 payload도 고친 값이다(활동의 `expenseId` 필터가 찾도록). 적용기는 읽지 않는다. 앱은 넣어 보낸다. 커밋한 뒤 서버가 두 파일을 지운다("영수증") |

예 (`expense.created`, 두 사람이 내고 몫 2:1:1로 나눔):
```json
{"expenseId": "…", "description": "Hotel", "amount": 10000, "currency": "EUR", "fxRateToDefault": null,
 "paidBy": "m-anna",
 "payers": [{"memberId": "m-anna", "amount": 6000}, {"memberId": "m-ben", "amount": 4000}],
 "refund": false,
 "split": {"mode": "shares", "input": {"m-anna": 2, "m-ben": 1, "m-cara": 1}},
 "date": "2026-10-11", "category": null, "notes": null,
 "shares": [{"memberId": "m-anna", "amount": 5000}, {"memberId": "m-ben", "amount": 2500}, {"memberId": "m-cara", "amount": 2500}]}
```
```
SplitSpec {"mode": "equal" | "percent" | "shares" | "adjustment" | "itemized", "input"?: {"<memberId>": number}, "bill"?: ItemizedBill}
ItemizedBill {"lines": [{"name": string, "amount": int, "memberIds": [memberId]}], "tax": int, "tip": int, "discount": int}
```
- 금액의 기준은 언제나 `shares`와 `payers`다. `split`은 편집기가 그 지출을 같은 방식·같은 숫자로 다시 열기 위한 힌트이고, 서버는 `split`으로 `shares`를 다시 계산하지 않는다. 앱은 열 때 `computeSplit(amount, split.mode, shares의 memberId들, split.input)`이 저장된 shares와 같을 때(0인 항목은 빼고 비교)만 그 모드로 열고, 아니면 exact로 연다. `itemized`는 `itemizedTotal(bill) == amount`이고 `computeItemizedSplit(bill)`이 저장된 shares와 같을 때(0인 항목은 빼고 비교)만 Items로 연다(아래 "항목별 분할").
- `itemized`(7단계, "항목별 분할"): `bill`이 꼭 있어야 하고 `input`은 없어야 한다(`null`은 없는 것). 그 밖의 mode에 온 `bill`은 다른 키처럼 무시하고 그대로 저장한다. 예: `{"mode": "itemized", "bill": {"lines": [{"name": "Burger", "amount": 1450, "memberIds": ["m-anna"]}, {"name": "Fries to share", "amount": 700, "memberIds": ["m-anna", "m-ben"]}], "tax": 284, "tip": 600, "discount": 0}}`. 서버는 bill이 shares와 맞는지 보지 않는다(3단계 원칙). 앱은 `tax`·`tip`·`discount`를 언제나 넣어 보내고(0 포함), 읽을 때 없으면 0이다. `defaultSplit`에는 쓸 수 없다.
- `equal`: `input` 없음(또는 null). 나누는 사람은 `shares`에 있다(체크한 멤버만). 그 밖의 모드는 화면의 모든 멤버를 0 포함해 `shares`에 넣는다.
- `percent`: `input` = 퍼센트. `shares`: `input` = 몫 개수(소수 가능). `adjustment`: `input` = 최소 단위 조정액(음수 가능, 정수 값 — `1000`과 `1000.0`은 같고 `1000.5`는 400). 세 모드는 `input`이 꼭 있어야 한다. `input`에 없는 멤버는 0.
- exact(금액 직접 입력) 분할은 `split: null`이다. mode `exact`는 없다(400).
- `split`·`defaultSplit`의 다른 키(`bill`과 그 `lines[]` 안의 다른 키 포함)는 무시하고 그대로 저장한다. 앱은 모르는 mode를 오류 없이 "split 없음"으로 읽는다(6단계까지의 앱은 `itemized`를 그렇게 읽는다).
- `defaultSplit`(그룹 기본 분할)은 `percent`·`shares`만 쓴다. 새 지출은 `defaultSplit`이 있으면 그것으로, 없으면 모두 체크한 equal로 시작한다. `input`에 없는 멤버(나중에 들어온 사람)는 0. 그 분할을 계산할 수 없으면(합 오류 등) equal로 시작한다.
- `refund: true` = 돌려받은 돈(예: 호텔이 Anna에게 €60을 돌려줌). `payers` = 받은 사람, `shares` = 다시 나눠 받는 사람. 잔액 효과는 지출의 반대다.
- 잔액(앱, `shared/settlement-cases.json`): 지출마다 `sign = refund ? −1 : +1`, 결제자마다 `잔액[m] += sign × payers[m]`, 몫마다 `잔액[m] −= sign × shares[m]`. 송금은 `잔액[from] += amount`, `잔액[to] −= amount`. 양수 = 받을 돈.

- 글자 수(`description` 200, `notes` 500, `text` 1000, 그룹 `name` 100, 멤버 `name` 100)는 UTF-16 길이(Kotlin·Dart `String.length`)로 센다. `notes`가 문자열·null이 아니거나 너무 길면, `text`·`createdAt`이 규칙에 맞지 않으면, 그룹 `name`(`group.created`·`group.updated`, 그래서 POST /groups도)이나 멤버 `name`(`member.added`, 그래서 POST /groups의 `memberName`과 초대 참여의 `name`도)이 100자를 넘으면 400 `VALIDATION`. 이미 저장된 긴 멤버 이름 이벤트는 그대로 읽힌다(보낼 때만 검사).
- 금액 상한: 지출 `amount`·`payers[].amount`·`shares[].amount`와 `payment.created`의 `amount`는 `10000000000000`(10^13 최소 단위) 이하. 넘으면 400 `VALIDATION`. 멤버가 50명까지이므로 결제자·몫의 합이 64비트 정수를 넘어 한 바퀴 돌아 `amount`와 같아지는 일이 없다. 200자 제한은 새로 보내는 `description`에만 적용한다(이미 저장된 긴 설명의 지출도 다른 필드는 고칠 수 있다). Splitwise 가져오기는 200자로 자른다.
- JSON 타입(앱 적용기는 형변환 없이 읽으므로 서버가 막는다. 어기면 400 `VALIDATION`): `expense.created`와 `expense.updated.fields`에 있는 키는 `description`·`currency`·`paidBy`·`date`·`category`·`notes`는 문자열, `amount`는 정수, `fxRateToDefault`는 유한한 숫자(`1e999`처럼 무한대로 읽히는 값은 400), `shares`와 `payers`는 `[{"memberId": 문자열, "amount": 정수}]`, `refund`는 boolean, `split`은 객체. `group.updated`의 `simplifyDebts`는 boolean(null도 400), `defaultSplit`은 객체 또는 null. `null`은 규칙 9대로 허용(`expense.created`에서 값이 필요한 키는 다른 검증이 거부). `expense.created`에는 `amount`·`shares`가 꼭 있어야 한다. `payment.created`의 `amount`도 정수. `group.*`·`member.added`의 `name`은 공백만이 아닌 문자열. `expense.created`·`payment.created`·`comment.added`에 `deleted` 키는 없거나 `false`(만들면서 삭제할 수 없다). 8단계: `recurrenceId`는 소문자 UUID 문자열, `occurrence`는 정수(둘 다 `null` 가능, 아래 "반복 지출 검증"). `recurrence.*`의 `recurrenceId`·`frequency`·`startDate`·`timeZone`은 문자열, `template`·`fields`는 객체.
- `category`(`expense.created`·`expense.updated.fields`)는 `string|null`이고 뜻은 아래 "카테고리"(5단계): `shared/categories.json`의 key, `null` = General, 그 밖의 문자열 = 이전 자유 입력. 서버는 문자열·null인지만 본다(값 검사·변환 없음).
- `comment.added`의 `text` 1~1000자 검증은 보낼 때만 적용한다. 삭제된 댓글의 저장된 이벤트는 `text: ""`로 pull된다(적용 규칙 8).
- 호환: 출시 1 앱은 `comment.*`·`expense.restored`를 모르는 type으로 건너뛰고 `notes`를 버린 채 lastSeq를 올렸다. 그래서 앱 DB가 schemaVersion 3으로 올라갈 때 모든 그룹의 lastSeq를 0으로 되돌리고, lastSeq 0에서 시작하는 pull은 **빈 상태부터** 로그 전체를 다시 적용한다(저장된 상태 위에 다시 적용하면 `expense.created`의 notes가 돌아오지 않는다). 구 앱이 계속 쓰이는 동안 그 앱에서는 복원된 지출이 삭제된 채로 보인다.

#### 결제자·분할·그룹 설정 검증 (400, 배열 전체 거부)
타입 검사는 원래 payload에서, 합·멤버 검사는 그 이벤트를 적용한 지출·그룹에서 한다(`description` 등 기존 검사와 같음). 삭제됐거나 없는 지출의 `expense.updated`는 타입 검사만 한다(규칙 3·4로 무시되므로).

| code | 언제 |
|---|---|
| `PAYERS_SUM_MISMATCH` | 적용 뒤 Σ `payers[].amount` ≠ `amount` (예: 결제자가 여럿인 지출에 `amount`만 바꾸는 수정, 규칙 10d) |
| `UNKNOWN_MEMBER` | 결제자, `split.input`의 키, `split.bill.lines[].memberIds`의 값(7단계), `defaultSplit.input`의 키가 그룹 멤버가 아님(removed 멤버는 멤버다) |
| `NEGATIVE_AMOUNT` | 결제자 금액 < 0 |
| `SUM_MISMATCH` | `defaultSplit`이 percent인데 합이 100(±0.001)이 아님. 지출의 `split`은 합을 검사하지 않는다(`shares` 합 검사는 그대로) |
| `VALIDATION` | `payers`가 빈 배열이거나 배열이 아님, 항목 모양이 틀림, 같은 멤버가 두 번; `refund`가 boolean이 아님; `split`·`defaultSplit`이 객체도 null도 아님; mode가 허용되지 않음(`split`: equal·percent·shares·adjustment·itemized, `defaultSplit`: percent·shares); equal에 `input`이 있음, percent·shares·adjustment에 `input` 객체가 없음; `input` 값이 숫자가 아니거나 유한하지 않음; percent·shares 값 < 0; adjustment 값이 정수 값이 아님; `defaultSplit` shares 합이 0; `simplifyDebts`가 boolean이 아님. 7단계 itemized: `input`이 있음; `bill`이 객체가 아님; `bill.lines`가 배열이 아니거나 항목이 1~200개가 아님; 항목이 객체가 아님; `name`이 문자열이 아니거나 trim 뒤 1~100자(UTF-16)가 아님; `amount`가 0 이상 `10000000000000` 이하의 정수가 아님; `memberIds`가 문자열 배열이 아니거나 비었거나 같은 id가 두 번; `tax`·`tip`·`discount`가 있는데(`null`은 없는 것 = 0) 0 이상 `10000000000000` 이하의 정수가 아님 |

통화 잠금(규칙 12)은 오류가 아니다. `payers` 등이 `null`이면 타입 검사를 통과한다(규칙 9: 무시).

#### 반복 지출 검증 (8단계, 배열 전체 거부)
"금지 키" = `expenseId`·`date`·`recurrenceId`·`occurrence`·`frequency`·`startDate`·`timeZone`. "지출로 맞다" = `template + {"expenseId": 상태에 없는 아무 UUID, "date": startDate}`를 `expense.created`와 똑같이 검사한다(JSON 타입, `amount`·`shares` 필수, `deleted` 없음, 글자 수·금액 상한, 결제자·몫의 합과 멤버, 통화, `split` 모양과 itemized `bill`). 그래서 오류 코드도 지출과 같다(`VALIDATION`·`SUM_MISMATCH`·`PAYERS_SUM_MISMATCH`·`NEGATIVE_AMOUNT`·`UNKNOWN_MEMBER`·`UNKNOWN_CURRENCY`).

| 이벤트 | 규칙 | 오류 |
|---|---|---|
| `recurrence.created` | `recurrenceId`는 소문자 UUID; `frequency`는 `weekly`·`biweekly`·`monthly`·`yearly` 가운데 하나; `startDate`는 `YYYY-MM-DD`의 있는 날짜(`requireDate`) | 400 `VALIDATION` |
| | `timeZone`은 1~64자 문자열이고 `ZoneId.of`가 받는다(IANA 이름, `Z`, `±HH:MM` 등) | 400 `VALIDATION` |
| | `template`은 객체이고 금지 키가 없다 | 400 `VALIDATION` |
| | `template`이 지출로 맞다(이미 있는 id여도 검사한다) | 지출과 같은 코드 |
| | 상태에 없는 id이고 이 그룹에 멈추지 않은 시리즈가 이미 100개(abuse cap) | 409 `LIMIT_EXCEEDED` |
| | 다른 그룹의 id(저장할 때 `ON CONFLICT … WHERE group_id` 0행, 다른 `*.created`와 같다) | 400 `VALIDATION` |
| `recurrence.updated` | `recurrenceId`는 소문자 UUID; `fields`는 객체이고 금지 키가 없다; `fields`의 키는 `expense.updated.fields`와 같은 JSON 타입 검사 | 400 `VALIDATION` |
| | 시리즈가 멈추지 않았으면 합친 template(template에 `fields`를 키마다 덮어쓴 것, 규칙 15)이 지출로 맞다. 없거나 멈춘 시리즈면 위 검사만 하고 받는다(적용기가 무시) | 지출과 같은 코드 |
| `recurrence.deleted` | `recurrenceId`는 소문자 UUID. 없거나 이미 멈춘 시리즈도 받는다 | 400 `VALIDATION` |
| `expense.created`·`expense.updated` | `recurrenceId`(소문자 UUID 문자열\|null)와 `occurrence`(정수\|null)는 둘 다 값이 있거나 둘 다 `null`. `expense.created`에서 없는 키는 `null`. `expense.updated.fields`에서는 두 키가 함께 있거나 함께 없다(하나만 있으면 상태가 어긋난다) | 400 `VALIDATION` |
| | `occurrence`는 0 이상 2147483647 이하 정수이고, 사용자가 보내면(앱) `0`만. 1 이상은 서버 스케줄러(actor 없음)만 | 400 `VALIDATION` |
| | **정규화**(검사보다 먼저, `normalize`): `recurrenceId`가 문자열이고 이 그룹 상태에 없는 시리즈면 두 키를 뺀다. `expense.created`는 시리즈 없이, `expense.updated`는 지금 표시 그대로 저장된다(pull되는 payload도 뺀 것). 오프라인 기기는 그 시리즈가 거부됐는지 모르므로 400을 내지 않는다("오프라인 기기가 알 수 없는 상태"). 멈춘 시리즈는 그대로 받는다 | — |

권한: 그룹 멤버 누구나 만들고 고치고 멈춘다(지출과 같다, 관리자 없음). 서버는 템플릿의 `paidBy`를 고치지 않는다(반복을 올릴 때 `expense.created` 정규화가 고친다).

- 호환(3단계): drift가 schemaVersion 4로 올라갈 때 `expense_payers`를 `paid_by`·`amount`로 채우고(오프라인에서도 잔액이 맞게) lastSeq를 0으로 되돌린다(이전 앱 코드가 모른 채 건너뛴 `payers`·`refund`·`split`·`simplifyDebts`·`defaultSplit`을 로그에서 다시 적용). 이 단계 전의 앱은 여러 명이 낸 지출과 환불을 `paidBy`가 전액 낸 보통 지출로 보인다(출시 전이라 받아들인다).
- 호환(5단계): 이벤트 모양과 저장소가 그대로다. Flyway 마이그레이션 없음(마지막은 V6), drift schemaVersion 5 그대로, lastSeq도 되돌리지 않는다. 이전 앱은 새 앱이 쓴 key(`food.dining_out`)를 자유 입력 칸에 글자 그대로 보이고, 고치지 않으면 그대로 다시 보낸다(출시 전이라 받아들인다). 새 앱이 이전 서버를 만나면 `GET /groups/{id}/activity`의 `expenseId`가 무시되므로 앱은 받은 항목 중 `expenseId`가 같은 것만 보여 준다(아래 "피드").
- 호환(6단계): Flyway V7·V8, drift schemaVersion 6·7(`Groups.kind` 기본 `'group'`, `Comments.paymentId`, `Comments.expenseId`는 null 허용, `Expenses.moved` 기본 `false`). 이전 이벤트에는 `kind`·`paymentId`·`movedTo`가 없고 그 기본값이 맞다. 6단계 개발 빌드가 저장한 옮기기에는 `moved`가 없으므로 V8은 `movedTo`가 객체인 `expense.deleted`가 로그에 있는 지출을 `moved = true`·삭제로 채우고(로그를 다시 적용한 결과와 같다), schemaVersion 7은 lastSeq를 0으로 되돌린다(출시된 앱은 schemaVersion 3·4 단계에서 어차피 다시 적용하므로 추가 비용이 없다). 출시된 앱(출시 1)은 `comment.*`를 모르는 type으로 건너뛰고, `kind`를 몰라 친구 그룹을 이름이 `Anna & Ben`인 보통 그룹으로 보이며(멤버 추가는 409), `movedTo`가 있는 삭제를 보통 삭제로 본다(출시 전이라 받아들인다). 2~5단계 앱은 출시되지 않았다(빌드 보류). 그 코드의 적용기는 `expenseId` 없는 `comment.added`에서 멈추므로(`as String`) 개발 기기는 새 앱으로 올린다. 서버를 먼저 올린다: 이전 서버는 송금 댓글을 400으로 거부하고 `/friends`·`/activity/unread`가 없다(앱은 404를 기능 없음으로 본다: 배지 숨김).
- 호환(7단계): Flyway V9(`attachments` 표, `payments.replaced`), drift schemaVersion 8(`Attachments`·`PendingUploads` 표, `Payments.replaced` 기본 `false`). 6단계까지의 앱은 `attachment.*`·`payment.restored`를 모르는 type으로 건너뛰고 itemized `split`을 `null`로 읽어 저장한 채 lastSeq를 올렸으므로 schemaVersion 8은 lastSeq를 0으로 되돌린다(빈 상태부터 다시 적용). 이전 이벤트에는 `replacedBy`·`attachment.*`가 없고 기본값(`replaced=false`, `attachments=[]`)이 맞다. 단 6단계 개발 빌드의 송금 편집으로 지워진 송금은 표시가 없어 Restore가 보이고, 되살리면 새 송금과 함께 두 번 센다(로그에서 편집을 알아낼 수 없어 V9는 채우지 않는다. 출시 전이라 받아들인다). 출시된 앱(출시 1)은 `attachment.*`·`payment.restored`를 건너뛰고(되살린 송금이 삭제된 채로 보인다), itemized 지출을 보통 지출로 보이고, 그 지출의 금액·분할을 고치면 `split` 키 없이 `shares`·`amount`를 보내 `split`이 지워진다(규칙 10). snapshot의 새 키는 무시한다. 서버를 먼저 올린다: 이전 서버는 `attachment.*`·`payment.restored`를 400 `UNKNOWN_TYPE`, itemized를 400 `VALIDATION`으로 거부하고(앱은 "거부된 이벤트"대로 버린다) 올리기 엔드포인트가 없다(404).
- 호환(8단계): Flyway V10(`recurrences` 표, `expenses.recurrence_id`·`occurrence`), drift schemaVersion 9(`Recurrences` 표, `Expenses.recurrenceId`·`occurrence`). 이전 이벤트에는 `recurrence.*`와 두 키가 없고 기본값(`recurrences=[]`, 둘 다 `null`)이 맞다. 7단계까지의 앱은 `recurrence.*`를 모르는 type으로 건너뛰고 두 키를 버린 채 lastSeq를 올렸을 수 있으므로(서버를 먼저 올린다) schemaVersion 9는 lastSeq를 0으로 되돌린다(빈 상태부터 다시 적용). 출시된 앱(출시 1)과 이전 개발 빌드는 서버가 올린 반복을 보통 지출로 보이고(활동은 모르는 kind라 `Someone made a change`), 시리즈를 고치거나 멈출 수 없으며, 반복 지출을 고치면 두 키 없이 `expense.updated`를 보내 표시가 그대로 남는다. snapshot의 새 키는 무시한다. 서버를 먼저 올린다: 이전 서버는 `recurrence.*`를 400 `UNKNOWN_TYPE`으로 거부하고(앱은 "거부된 이벤트"대로 버린다) 두 키를 검사·정규화 없이 payload에 남긴다.
- 호환(4단계): 이벤트 모양이 그대로이므로 lastSeq를 되돌리지 않는다. drift schemaVersion 5는 `FxDays` 표와 `Session.homeCurrency`만 더한다. 서버를 먼저 올린다: 이전 서버는 새 통화 코드를 400 `UNKNOWN_CURRENCY`로 거부한다(앱은 "거부된 이벤트"대로 "the currency isn't supported"). 이전 앱은 모르는 통화를 소수 2자리로 보이고(`Money.digits` 기본값) `homeCurrency`를 무시한다(출시 전이라 받아들인다).

### 적용 규칙 (앱 Dart·서버 Kotlin 동일, `shared/sync-cases.json`으로 검증)
1. `applyEvent(state, event)`는 순수 함수. 같은 이벤트 두 번 적용 = 한 번 적용.
2. 수정 vs 수정: 필드 단위로 seq 큰 쪽이 이긴다(순서대로 적용하면 자연히 성립).
3. 삭제 vs 수정: `deleted=true`인 지출·송금에 오는 `updated`는 무시한다(삭제가 이김). 삭제된 지출을 되살리는 것은 `expense.restored`뿐이고, 삭제되어 있던 동안 무시된 `updated`는 복원 뒤에도 되살아나지 않는다.
4. 없는 대상에 오는 `updated`·`deleted`·`restored`·`linked`·`removed`·`confirmed`·`comment.deleted`(8단계 `recurrence.updated`·`recurrence.deleted` 포함)는 무시한다.
5. `member.removed`는 `removed=true`만 표시한다. 잔액 계산에는 계속 포함된다.
6. `payment.confirmed`는 `status`를 `confirmed`로 바꾼다. 없거나 삭제된 송금이면 무시한다. 잔액은 `sent`와 `confirmed` 송금을 똑같이 반영한다(앱은 `sent`를 "확인 대기"로 표시).
7. `expense.restored`는 `deleted=false`로 되돌린다. 삭제되지 않은 지출이면 아무것도 바꾸지 않는다. 삭제와 복원이 엇갈리면 seq 순서상 나중 것이 이긴다. 예외(6단계): 옮긴(`moved`) 지출은 되살리지 않는다(규칙 13). 7단계: `payment.restored`도 송금에 똑같이 한다(`deleted=false`, `status`는 그대로 — `sent`면 다시 확인 대기, 살아 있거나 없는 송금이면 무시). 예외: `replacedBy`가 문자열인 `payment.deleted`(송금 편집)는 보통 삭제에 더해 `replaced=true`를 표시하고(그 뒤 어떤 이벤트도 지우지 않는다. `replacedBy` 없는 삭제가 다시 와도 그대로), `replaced`인 송금에 오는 `payment.restored`는 무시한다(편집이 만든 새 송금과 두 번 세지 않게). 기본값 `replaced = false`.
8. `comment.added`는 `commentId`가 처음일 때만 댓글을 뒤에 추가한다(이미 있으면 — 삭제된 댓글 포함 — 무시, 멱등). `comment.deleted`는 `deleted=true`로 표시하고 `text`를 `""`로 비운다(목록에서 빼지 않는다). 서버 로그의 `comment.added`도 `text: ""`로 오므로(snapshot 아래), 글을 본 기기와 못 본 기기가 같은 상태가 된다. 적용기는 지출 존재 여부를 확인하지 않는다(서버 검증이 보장). 6단계: 댓글은 `expenseId`와 `paymentId`를 받은 그대로 저장한다(없으면 `null`, 송금 댓글은 `expenseId: null`). 송금 존재 여부도 확인하지 않는다.
9. 빠진 필드: `expense.created`에 `notes`가 없으면 `null`. `expense.updated`는 `fields`에 있는 키만 바꾸며(규칙 10의 `payers`·`paidBy`·`split` 예외), `notes`·`category`·`fxRateToDefault`·`split`은 `null`이 오면 지우고, 나머지 키(`payers`·`refund` 포함)의 `null`은 무시한다.
10. 결제자·환불·분할 입력.
    - 기준은 `payers`이고 `paidBy`는 거기서 정한다. **주요 결제자** = 금액이 가장 큰 결제자, 같으면 memberId가 가장 작은 결제자(문자열 오름차순). 적용기는 payload의 `paidBy`를 믿지 않고 언제나 다시 정한다. `payers`는 보낸 순서를 지킨다.
    - `expense.created`: `payers`가 없거나 null이면 `[{paidBy, amount}]`. `refund`가 없거나 null이면 `false`. `split`이 없으면 `null`.
    - `expense.updated`(삭제 안 된 지출, 규칙 3)의 결제자: (a) `fields.payers`가 있으면(null 아님) 그것으로 바꾼다. (b) 아니고 `fields.paidBy`가 있으면 `[{paidBy, 이 수정 뒤의 amount}]`. (c) 아니고 `fields.amount`가 있고 결제자가 한 명이면 그 결제자의 금액을 새 amount로 바꾼다. (d) 그 밖에는 그대로.
    - `refund`: `fields.refund`가 boolean이면 바꾼다.
    - `split`: `fields`에 `split` 키가 있으면 그 값(null이면 지움). 없고 `fields`에 `shares`나 `amount`가 (null 아닌 값으로) 있으면 `null`(값이 같아도 키만 보고 정한다). 그 밖에는 그대로.
11. 그룹 설정: `group.updated`에서 없는 키는 그대로, `simplifyDebts`는 그 값으로, `"defaultSplit": null`은 지운다. 기본값 `simplifyDebts = true`, `defaultSplit = null`. `group.created`는 이 둘을 바꾸지 않는다.
12. 통화 잠금: 상태에 지출이나 송금이 하나라도 있으면(삭제된 것 포함 — 복원될 수 있다) `group.updated`의 `defaultCurrency`를 무시한다. 같은 이벤트의 다른 키는 적용한다. 서버는 이 이벤트를 400 없이 받아 저장한다. 이유: 모든 `fxRateToDefault`와 송금 금액이 그룹 통화 기준이다. 이 규칙은 상태를 보므로 "로그 전체를 최종 상태 위에 한 번 더 적용"하면 결과가 다를 수 있다(`group.created`가 통화를 되돌린 뒤 변경이 무시됨). 동기화는 그렇게 하지 않는다(seq 순서로 한 번씩, 또는 빈 상태부터).
13. 그룹 종류(6단계): `group.created`가 `kind`를 정한다(없거나 문자열이 아니면 `"group"`). 그 뒤 어떤 이벤트도 바꾸지 않는다(`group.updated`의 `kind` 키는 서버가 400으로 막고 적용기도 무시한다). 기본값 `kind = "group"`. 옮기기: `movedTo`가 객체인 `expense.deleted`는 보통 삭제처럼 `deleted=true`로 만들고 `moved=true`도 표시한다(그 뒤 어떤 이벤트도 지우지 않는다. `movedTo` 없는 삭제가 다시 와도 그대로). `moved`인 지출에 오는 `expense.restored`는 무시한다(규칙 7의 예외: 그 지출은 이제 다른 그룹에서 계산되므로 되살리면 두 번 센다). 서버는 그 `expense.restored`를 400 없이 받아 저장하고(오프라인에서 옮기기보다 먼저 넣은 복원일 수 있다), 상태가 바뀌지 않으므로 활동에서 숨긴다(숨김 1). 앱은 옮긴 지출에 Restore를 보이지 않는다. 기본값 `moved = false`.
14. 영수증(7단계): 상태에 `attachments`(`{id, expenseId, deleted}`, 붙은 순서)가 있다. 기본값 `[]`.
    - `attachment.added`: `attachmentId`가 이미 있으면(삭제된 것 포함) 아무것도 바꾸지 않는다(멱등. 삭제 뒤 다시 와도 삭제된 채). `expenseId`가 상태에 없는 지출이면 무시한다. 그 밖에는 `{id, expenseId, deleted: false}`를 뒤에 더한다(삭제된 지출에도 붙는다 — 복원하면 영수증도 돌아온다).
    - `attachment.deleted`: 없는 `attachmentId`면 무시, 있으면 `deleted=true`(목록에서 빼지 않는다). payload의 `expenseId`는 읽지 않는다.
    - 지출의 `deleted`·`moved`는 영수증을 바꾸지 않는다(`expense.deleted`는 영수증을 지우지 않는다).
15. 반복 시리즈(8단계): 상태에 `recurrences`(`{id, frequency, startDate, timeZone, template, deleted}`, 만든 순서)가 있다. 기본값 `[]`.
    - `recurrence.created`: 그 id가 이미 있으면(멈춘 것 포함) 아무것도 바꾸지 않는다(멱등, 첫 일정·template 그대로). 없으면 `{id, frequency, startDate, timeZone, template: 받은 그대로, deleted: false}`를 뒤에 더한다(payload의 다른 키, 예를 들어 `deleted`는 읽지 않는다).
    - `recurrence.updated`: 없거나 `deleted`인 시리즈면 무시한다. 아니면 `fields`의 키마다 template의 그 키를 받은 값으로 바꾼다. `null`도 `null`로 저장하고 키를 지우지 않는다. `fields`에 없는 키는 그대로, 배열·객체 값은 통째로 바꾼다(Kotlin `template.deepCopy().setAll(fields)`, Dart `{...template, ...fields}`). 규칙 10 같은 파생은 없다.
    - `recurrence.deleted`: 있으면 `deleted = true`(목록에서 빼지 않는다), 없으면 무시. 되돌리는 이벤트는 없다.
    - 시리즈 이벤트는 지출을 바꾸지 않는다: template을 고치거나 멈춰도 이미 올라간 반복은 그대로다.
16. 지출의 시리즈 표시(8단계): 지출에 `recurrenceId`(`string|null`)와 `occurrence`(`int|null`)가 있다. 기본값 둘 다 `null`(이전 이벤트).
    - `expense.created`: 받은 값(없으면 `null`).
    - `expense.updated`(삭제 안 된 지출, 규칙 3): `fields`에 키가 있으면 그 값으로 바꾸고 `null`이면 지운다(규칙 9의 `notes`와 같다). 없으면 그대로.
    - 적용기는 그 시리즈가 있는지, 멈췄는지 보지 않는다(서버 정규화가 없는 시리즈를 뺀다). `expense.deleted`·`expense.restored`·옮기기는 표시를 바꾸지 않는다.

4·5단계는 적용 규칙을 더하지 않는다. 6단계는 규칙 13을 더하고(규칙 7에 옮긴 지출 예외) 규칙 8을 송금 댓글로 넓힌다. 7단계는 규칙 14를 더하고 규칙 7을 송금(`payment.restored`, 편집으로 바뀐 송금 예외)으로 넓힌다. 8단계는 규칙 15·16을 더하고 규칙 4를 `recurrence.*`로 넓힌다. 9단계 이후의 규칙 번호는 17부터다.
- 4단계: `fxRateToDefault`는 받은 숫자 그대로 저장한다(`0`도 `0`으로 저장, `null`은 규칙 9대로 지움). 그 뜻과 잔액에서 쓰는 법은 아래 "통화 환산".
- 5단계: `category`는 받은 문자열 그대로 저장한다(key로 바꾸지 않음, `null`은 규칙 9대로 지움, `shared/sync-cases.json`의 category 케이스). 뜻은 아래 "카테고리".

## 통화 환산 (4단계)
지출마다 자기 통화를 가진다. 그룹 통화(D)와 다르면 D로 바꾸는 환율 `fxRateToDefault`를 함께 가진다. 새 이벤트 종류는 없다.

### `fxRateToDefault`
- 뜻: **지출 통화 1 주 단위당 D의 주 단위**(EUR 그룹의 JPY 지출: 1 JPY = 0.00563349 EUR → `0.00563349`). 최소 단위끼리의 비율이 아니다. 처음부터 이 뜻이었고(이전 앱은 잔액에서 자릿수 차이를 빠뜨렸다), 저장된 값은 고치지 않는다.
- `null` 또는 `0` = 환산 안 됨("Not converted"). 지출 통화가 D와 같으면 값과 상관없이 무시한다.
- 서버 검증: 유한한 숫자 또는 `null`(무한대도 400), 음수면 400 `VALIDATION`. `0`은 받는다(이전 클라이언트가 보냈을 수 있다). 앱은 0을 입력받지 않는다(폼에서 거부).
- 자동 환율 = `crossRate(perEur, from, to)` = `perEur[to] / perEur[from]`(아래 `GET /fx`의 `rates`)를 유효숫자 6자리로 반올림한 값(`double.parse(x.toStringAsPrecision(6))`, 1/177.51 → `0.00563349`). 둘 중 하나가 없거나 0 이하면 자동 환율 없음. 직접 입력한 환율은 그대로 저장한다.
- 앱은 `currency`나 `fxRateToDefault` 중 하나라도 바뀌면 `expense.updated.fields`에 **둘 다** 넣는다(D로 바꾸면 `"fxRateToDefault": null`). `currency`만 보내면 규칙 9 때문에 이전 통화의 환율이 남기 때문이다.
- **Convert(한 통화로 환산)**: 그 통화(≠ D)의 삭제 안 된 지출 가운데 환율이 `null`이나 `0`인 것마다 `expense.updated {"expenseId", "fields": {"currency": 그 통화, "fxRateToDefault": r}}`(r > 0, 위 규칙대로 둘 다)를 한 로컬 트랜잭션으로 outbox에 넣는다. 스낵바의 Undo는 같은 모양으로 지출마다 이전 값(`null` 또는 `0`)을 다시 보낸다. 보통 한 push(outbox는 100개씩 보낸다)로 가므로 받는 사람에게는 표시 알림 하나(2개 이상이면 묶음 문장 `{A} made {n} changes`)이고, 활동 피드에는 지출마다 `exchange rate` 변경이 나온다. 사용자당 분당 120 이벤트 제한은 그대로다(넘는 것은 outbox에 남아 나중에 간다).
- 환산한 금액은 어디에도 저장하지 않는다. 언제나 지출 통화의 금액과 환율에서 다시 계산한다.

### 환산 규칙 (효준님 함수, `shared/fx-cases.json`)
Dart `app/lib/domain/fx.dart`의 `convertAmount`·`convertExpense`(효준님), Kotlin `money/Fx.kt`(Claude 이식, 6단계 리마인더·10단계 요약부터 서버가 쓴다). 모두 구현됐고 `shared/`에 `"pending"` 케이스는 없다(7단계에서 stub 시절의 대비 코드 — `tryCore`·`implemented`·`fxReady`·`notImplementedLabel`, Kotlin의 `NotImplementedError` catch, 테스트의 `pending` 건너뛰기 — 를 지운다). 순수 함수이고 자릿수는 인자로 받는다(`shared/currencies.json`).
- `convertAmount(amount, fromDecimals, toDecimals, rate) → int`: 정확한 값 = `amount × R × 10^(toDecimals − fromDecimals)`. R은 `rate.toString()`이 찍는 십진수(Dart는 최단 왕복 표기라 `7e-7`처럼 지수 표기도 나온다. Kotlin은 `BigDecimal(rate.toString())` — JDK 19+의 `Double.toString`도 최단 왕복이라 같은 수다). double 곱셈은 쓰지 않는다(100 × 0.285 = 28.499999999999996이지만 답은 29). 가장 가까운 정수로 반올림하고 정확히 .5는 0에서 먼 쪽(28.5 → 29, −28.5 → −29). rate가 유한하지 않거나 0 이하면 `FxException('BAD_RATE')`. amount는 음수일 수 있다(잔액).
- `convertExpense(amount, parts, fromDecimals, toDecimals, rate) → {amount, parts}`: 검사 순서 `BAD_RATE` → amount나 part가 음수면 `NEGATIVE_AMOUNT` → Σ parts ≠ amount면 `SUM_MISMATCH`. total = `convertAmount(amount)`. part마다 정확한 값을 내림하고, 남는 `total − Σ 내림` 개(0 이상 part 수 이하)를 버린 소수가 큰 part부터 1씩(같으면 memberId 오름차순, 0인 part는 받지 않음). 결과의 키는 `parts`와 같고 합은 total이다.

### 통화별 잔액 (앱 `domain/balances.dart`; 6단계 서버 `Balances.ofGroup`도 같은 규칙)
D = 그룹 기본 통화. 지출은 삭제 안 된 것만.
1. D 지출은 그대로 D 칸에 들어간다(남아 있는 환율은 무시).
2. 외화 지출이고 `fxRateToDefault > 0`이면 `convertExpense`로 D로 바꿔 D 칸에 넣는다. 몫(`shares`)에 한 번, 결제자(`payers`)에 한 번, 같은 amount·rate·자릿수로 부른다(둘의 total은 같다). 하나라도 `FxException`을 던지면 3으로 간다.
3. 그 밖의 지출은 자기 통화의 칸에 들어가고 `unconverted[통화]`가 1 오른다.
4. 송금은 `payment.currency`의 칸에 들어간다. 4·5단계의 Settle up은 언제나 D로 만들었고, 6단계부터는 칸마다 그 칸의 통화로 만든다(아래).
5. D 칸은 언제나 있다. 다른 칸은 누군가의 잔액이 0이 아닐 때만 남는다. 칸마다 잔액의 합은 0이다.
- 칸마다 따로 `computeBalances`(여러 결제자·환불 포함), 그리고 부채 단순화(`simplifyDebts`) 또는 끈 그룹은 pairwise를 한다. 빠지는 지출은 없다(7단계: `unsupported`와 그 안내 줄을 지운다).
- Settle up(4·5단계)은 D 칸의 송금만 보였고 다른 칸은 카드 하나("¥3,000 isn't converted yet · Convert")였다. **6단계**: 모든 칸의 송금을 보이고 그 칸의 통화로 기록한다(D 칸 먼저, 다른 칸은 통화 코드 순으로 "Not converted · JPY" 아래). 그래서 그룹 통화가 아닌 빚도 환산 없이 그 통화로 정산할 수 있다(parity #76). 그 칸에 환율 없는 지출이 있으면 Convert도 함께 보인다. 결제 링크는 그 칸의 통화로 연다(1단계 링크 규칙 그대로: EPC QR은 EUR만, 다른 통화의 IBAN은 복사만).
- Convert는 송금을 바꾸지 않는다: X로 정산한 뒤 X 지출을 환산하면 X 송금만 X 칸에 남아 반대 방향의 빚으로 보인다. 그래서 Convert 시트는 그 통화에 삭제 안 된 송금이 있으면 `Payments in JPY stay in JPY` 한 줄을 보인다.
- 서버(6단계) `money/Balances.kt`: `ofGroup(state)` = `balancesOf`의 이식, `transfers(result, simplify)` = `groupTransfers`(끈 그룹은 `pairwiseDebts` 이식. `shared/settlement-cases.json`의 `expectedPairwise`를 Kotlin도 검사). 환산이 `FxException`을 던지면 Dart `tryFx`처럼 그 지출은 자기 통화 칸에 남는다. `Settlement.balances`는 여러 결제자·환불을 세므로 `unsupported`는 없다.
- 그룹 나가기: 모든 칸에서 내 잔액이 0이어야 한다(환산 안 된 지출 자체는 막지 않는다). 6단계부터 다른 칸도 그 통화로 정산할 수 있으므로 나가는 데 환산이 필요 없다(앱 안내 `You owe ¥3,000 · settle up in JPY first`).
- 홈 통화 H의 "≈": 내 칸 X마다 `convertAmount(잔액, digits(X), digits(H), crossRate(최신 표, X, H))`의 합. 환율이 하나라도 없거나 H만 관련되면 숨긴다.

## 환율 (4단계)
| 메서드 | 경로 | 요청 | 응답 |
|---|---|---|---|
| GET | `/fx?date=YYYY-MM-DD` | `date` 선택. 없거나 미래면 오늘(UTC) | `FxTable` |

```
FxTable {"date": "2026-10-10", "base": "EUR", "rates": {"EUR": 1.0, "USD": 1.1217, "JPY": 177.51, ...}}
```
- `rates`: EUR 1 주 단위당 그 통화의 주 단위. `shared/currencies.json`에 있는 코드만 나오고, 출처가 내지 않은 코드는 빠질 수 있다. `EUR`은 언제나 `1`. 출처가 준 값 그대로(반올림 없음).
- `date`: 표에 든 환율 날짜 가운데 가장 늦은 날(요청한 날 이하). 출처(Frankfurter v2)는 통화마다 마지막 발표일이 다를 수 있다(주말·휴일·출처별 발표). 앱은 이 값을 "rate of {date}"로 보여 주고 로컬 캐시의 키로 쓴다.
- `base`는 언제나 `"EUR"`.
- 인증 필요(401). 그룹과 무관하게 로그인한 사용자 누구나.
- 오류: 날짜 형식이 `YYYY-MM-DD`가 아니거나 없는 날짜 → 400 `VALIDATION`. 사용자당 버킷 30, 초당 0.5 회복(분당 30) — 캐시에서 답하는 요청도 센다 → 429 `RATE_LIMITED`. 환율이 없으면 503 `FX_UNAVAILABLE`(아래).
- 앱은 Frankfurter를 직접 부르지 않는다. 서버만 부른다.

서버 캐시 `fx_days`(요청한 날 D 한 행, D = `date`를 오늘(UTC)로 자른 값):
1. `EVENSIES_FX_URL`이 비어 있으면 DB도 출처도 보지 않고 503 `FX_UNAVAILABLE`(자동 환율 끔).
2. D 행이 있고 **확정**(`fetched_at ≥ D + 2일 00:00 UTC`, 즉 D의 다음 날이 끝난 뒤 받음)이거나 **최근**(`fetched_at > 지금 − 6시간`)이면 그대로 돌려준다. (설계의 "어제 이전이면 그대로"를 이렇게 정했다. D 당일 일찍 받은 행이 그 전날 환율로 굳지 않게 하기 위해서다.)
3. 아니면 `GET {EVENSIES_FX_URL}/rates?base=EUR&date={D}`(끝의 `/`는 무시, 연결·읽기 시간 제한 각 5초). 성공 = 200이고 본문이 JSON 배열 `[{"date","base","quote","rate"}]`이며 `quote`가 우리 목록에 있고(EUR 제외) `rate`가 양수인 항목이 하나 이상. 그 항목만 남기고 `EUR: 1`을 넣어 `rates`로, 남은 항목 `date`의 최댓값을 `rate_date`로, `fetched_at = 지금`으로 D 행을 upsert하고 돌려준다.
4. 실패(연결 실패·시간 초과, 200 아님, 파싱 실패, 남는 항목 없음 — 출처는 데이터가 없는 날(1999년 이전 등)에 `[]`를 준다)면 D 행이 있으면 오래됐어도 그것을, 없으면 503 `FX_UNAVAILABLE`. 다른 날의 행으로 대신하지 않는다(앱이 자기 캐시에서 고른다). 실패한 D는 5분 동안 출처에 다시 묻지 않고 바로 같은 답(오래된 행 또는 503)을 준다(서버 메모리, 재시작하면 잊는다). 출처가 멈춰도 요청마다 최대 10초씩 붙잡히지 않게 하기 위해서다.
- 그래서 지난 날은 한 번(확정되면 끝), 오늘·어제는 6시간에 한 번까지만 출처를 부른다. 스케줄러는 없다. 같은 D를 동시에 받으면 둘 다 부를 수 있고 upsert라 안전하다.
- 서버에서 `fx_days`를 읽는 곳은 `FxService` 하나다(8단계 반복 지출 스케줄러가 재사용).

앱(로컬 캐시 drift `FxDays`, 키 = 응답의 `date`):
- 온라인: 서버에 묻고(3초 시간 제한) 받은 표를 저장한다. 앱을 켤 때 온라인이면 최신 표(`date` 없이)를 한 번 받아 둔다.
- 오프라인·오류(503·429 포함): 키가 그 날 이하인 행 중 가장 늦은 것, 없으면 가장 늦은 행, 없으면 자동 환율 없음("offline · rate of {date}" 또는 "No automatic rate. Enter one, or leave it empty to keep this under Not converted.").

## 카테고리 (5단계)
새 이벤트 종류·필드·엔드포인트·마이그레이션·오류 코드는 없다. 지출의 `category`(`string|null`) 값의 뜻만 정한다.

### 분류표 `shared/categories.json`
- Splitwise 분류 그대로: 부모 7개(`parents[]`), 하위 43개(`categories[]`). 사용자 정의 카테고리는 없다.
- 복사본 `app/assets/categories.json`(앱이 시작할 때 `Money.loadFromAssets()` 옆에서 읽는다)과 `server/src/main/resources/categories.json`은 바이트 단위로 같아야 한다(양쪽 테스트, `currencies.json`과 같은 방식).
- `key`: `expense.category`에 저장하는 값. `categories[]`의 key만 지출 카테고리다(부모 key `food`는 아니다). 이름을 바꾸거나 지우지 않는다.
- `label`: 영어(9단계가 key로 번역). `icon`: Flutter Material 아이콘 이름(`Icons.<icon>`). 없는 카테고리(`*.other`, `uncategorized.general`)는 부모의 것. `keywords`: 추측용, 사람이 쓰는 대로 적고 읽을 때 fold한다.
- 파일 순서 = 선택기 순서 = 추측 동점 순서.

### 값의 뜻
| 저장된 값 | 뜻 | 화면 |
|---|---|---|
| `categories[]`의 key | 새 앱이 쓰는 값 | 그 카테고리 |
| `null` | General | General |
| 그 밖의 문자열(이전 자유 입력, 부모 key 포함) | legacy | General로 보이고(label과 같은 글은 그 카테고리, 아래 `resolveCategory`), 저장·내보내기·snapshot에서는 원문 그대로 |

- **서버는 검사하지 않는다**(일부러). 400을 내면 이미 설치된 앱의 배치 전체가 거부된다. 지금처럼 문자열이나 null인지만 본다. 적용기도 받은 값 그대로 저장한다(위 "적용 규칙").
- 앱이 보내는 값: 고른 key(General을 고르면 `"uncategorized.general"`), 추측한 key, 고르지도 추측하지도 않았으면 `null`. legacy 값은 선택기에서 바꾸지 않는 한 그대로 두고 `expense.updated.fields`에 `category`를 넣지 않는다(바뀐 필드만 보내는 지금 규칙).
- 폼의 추측: 새 지출이거나 저장된 값이 `null`인 지출이고 사용자가 아직 고르지 않았으면, 설명이 바뀔 때 300ms 뒤 `guessCategory`(history = 그 그룹의 삭제 안 된 지출, 상태 순서, 편집 중인 지출 제외)로 칩을 채우고 "auto"로 표시한다. 설명을 비우면 추측도 지운다. 한 번 고르면(General 포함) 더 추측하지 않는다. key나 legacy 값이 저장된 지출은 추측하지 않는다.

### 규칙 (앱 `domain/categories.dart`, 서버 `export/Categories.kt`, `shared/category-cases.json`)
- `fold(s)`: 소문자로(Dart `toLowerCase`) → 결합 부호 U+0300–U+036F 제거 → U+00C0–U+017F의 글자는 유니코드 정준 분해의 첫 글자로(`é→e`, `ñ→n`, `ź→z`), 분해가 없는 글자는 `ß→ss, æ→ae, œ→oe, ø→o, ł→l, đ→d, ð→d, þ→th, ı→i, ħ→h, ŧ→t, ĸ→k, ŀ→l, ŉ→n, ŋ→n, ĳ→ij, ſ→s`. 그 밖의 문자(`×`, 한자, 한글 등)와 공백은 그대로.
- `resolveCategory(raw) → key`(앱): `t = raw.trim()`. `t`가 `categories[]`의 key면(대소문자 그대로) `t`. 아니면 `t`를 소문자로 바꾼 값이 `categories[]`의 label 가운데 **한 번만 나오는** label(소문자)과 같으면 그 key. 여기서 `*.other` 여섯 개의 label은 `{부모 label} - Other`(`Entertainment - Other`, 서버 CSV와 같은 표기)로 보므로 맨 `Other`는 어느 것도 아니다. 부모 label은 보지 않는다. 그 밖(`null`, `""`, 부모 key·label 포함)은 `uncategorized.general`.
- 서버 `Categories.label(key)`: `categories[]` key의 label이고 `*.other` 여섯 개만 `{부모 label} - Other`(`Entertainment - Other`, CSV에서 서로 구별되게), 아니면 `null`. `Categories.keyForLabel(raw)`: `resolveCategory`와 같고 마지막만 `null`(가져오기가 원문을 남긴다). 그래서 양쪽 다 `{부모 label} - Other`(대소문자 무시)를 그 `*.other` key로 읽는다(`keyForLabel(label(k)) == k`, 앱은 `resolveCategory(labelOf(k)) == k`). 맨 `Other`는 여전히 `null`. 영어 label이라 Kotlin `lowercase()`와 Dart `toLowerCase()`가 같다.
- `guessCategory(description, history) → key|null`(앱):
  1. `n(s)` = `fold(s)`를 trim하고 연속 공백을 하나로. `n(description)`이 비면 `null`.
  2. **history 먼저**: history(오래된 것부터)에서 `n(description)`이 같고 category가 `categories[]`의 key인 **마지막** 항목의 category.
  3. **토큰**: `fold(text)`를 `[^\p{L}\p{N}]+`(unicode)로 나눈, 빈 것을 뺀 조각. 키워드도 fold한 뒤 같은 방식.
  4. **띄어 쓰지 않는 문자**: fold한 키워드에 한자·히라가나·가타카나·한글·태국 문자가 있으면 fold한 설명 전체에 부분 문자열로 있을 때 맞는다(정확 일치로 본다). 점수 = 키워드의 rune 수.
  5. **그 밖의 키워드**: 키워드의 토큰이 설명의 토큰에 연속해서 나오면 맞는다. 마지막을 뺀 토큰은 같아야 하고, 마지막 토큰은 같거나(정확) 키워드 토큰이 4자 이상이고 설명 토큰이 그것으로 시작하며 2자 이하만 더 길다(접두). 점수 = 키워드 토큰들의 rune 수 합(공백 뺀 글자 수).
  6. **고르기**: 가장 높은 점수. 같으면 정확 > 접두, 그다음 파일 순서(앞의 카테고리), 그다음 키워드 순서. 맞는 것이 없으면 `null`. ("car rental" 9가 "rent" 4를 이긴다.)

## 검색 (5단계, 앱만)
서버 검색 엔드포인트는 없다. 앱이 로컬 DB(모든 그룹의 상태)에서 찾으므로 오프라인에서도 된다. `searchDocs`, `shared/search-cases.json`.
- 문서: 삭제 안 된 지출마다 `SearchDoc {id, groupId, date, description, notes, comments, category, amount, currency}`. `comments`는 삭제 안 된 댓글의 글, `category`는 저장된 원문, `amount`는 지출 통화 그대로(환산 안 함, 환불도 양수). 송금과 멤버 이름은 찾지 않는다.
- 질의를 공백으로 나눈 항이 **모두** 맞아야 한다. 항은 fold한 값이 fold한 description·notes·각 댓글·원문 category·resolve한 label·그 부모 label 가운데 하나의 부분 문자열이면 맞는다.
- 금액: 항이 `^\d+([.,]\d{1,3})?$`이면 금액으로도 맞을 수 있다. 소수 k자리 수 N(`,`는 소수점), 통화 자릿수 d(`shared/currencies.json` `decimals`)일 때 `k ≤ d`이고 `amount ~/ 10^(d−k) == N·10^k`. `12` = €12.00–€12.99, `12,5` = €12.50–€12.59, `12,50` = €12.50, JPY `12000` = ¥12,000. 정수로 읽을 수 없을 만큼 길면 금액으로는 안 맞는다.
- 필터: `category`는 하위 key(resolve 결과가 같음) 또는 부모 key(resolve 결과가 `{부모}.`로 시작. `uncategorized`는 `null`·legacy도 잡는다). `month`는 `YYYY-MM`(`date`의 앞 7자).
- 질의가 비고 필터도 없으면 `[]`. 결과는 date 내림차순, 같으면 id 오름차순. `ponytail:` 선형 탐색, 150ms 디바운스. 지출이 2만 개쯤 넘으면 SQLite FTS5.
- 화면: `/search?group=&category=&month=`(모두 선택). 그룹 목록에서 열면 모든 그룹, 그룹 화면에서 열면 그 그룹(지울 수 있는 칩).

## 인사이트 (5단계, 앱만)
그룹마다 합계와 막대. 서버 변경 없음. `computeTotals`, `shared/totals-cases.json`.
- **통화별 칸**("통화별 잔액"과 같은 칸): D 칸 = `convertToDefault(state).converted` + D 송금. 다른 통화 X 칸 = 환산 안 된 X 지출(`unconverted[X]`) + X 송금. 칸마다 따로 `computeTotals`를 부른다. 화면은 D 칸을 위에, 다른 칸은 "Not converted · JPY" 아래에 그 통화의 합계로 보여 준다. 금액을 버리지 않는다.
- `computeTotals(expenses, payments, me) → {months: {YYYY-MM: PeriodTotals}, allTime}`. `computeTotals`는 통화를 보지 않는다(한 칸만 넘긴다).
  - 삭제된 지출·송금은 뺀다. 월 = `date`의 앞 7자.
  - 지출마다 `sign = refund ? −1 : +1`. `spent`와 `byCategory[resolveCategory(category)]`에 `sign × amount`, `youPaid`에 `sign × (payers의 내 금액)`, `yourShare`에 `sign × (shares의 내 금액)`, `byMember[m].paid`에 `sign × (payers의 m 금액)`, `byMember[m].share`에 `sign × (shares의 m 금액)`.
  - 낸 금액은 언제나 저장된 `payers`에서 읽는다(`paidAmounts(Expense)`). `computeBalances`를 거치지 않으므로 여러 결제자·환불 지출도 합계에 들어간다.
  - 송금(`sent`·`confirmed` 모두)은 내가 `fromMember`면 `paymentsMade`, `toMember`면 `paymentsReceived`에만 더한다.
  - `netChange = youPaid − yourShare + paymentsMade − paymentsReceived`. `allTime` = 모든 월의 합. `byCategory`·`byMember`는 합한 뒤 0인 항목을 뺀다(`byMember`는 paid와 share가 모두 0인 멤버). 환불 때문에 월 값이 음수일 수 있다(막대는 0부터, 금액 글자는 그대로).
  - `allTime.netChange`는 그 칸에서 내 잔액과 같다(테스트).
- **누가 다음에 낼까**: `whoPaysNext(D 칸 잔액, removed 아닌 멤버 id) → memberId|null` = 잔액이 가장 음수인 멤버, 같으면 memberId가 가장 작은 멤버, 음수가 없으면 `null`. Balances 탭 맨 위 한 줄 `{name} should pay next (owes {M(−잔액)}, the most)`, 그 멤버가 `me`이면 `You should pay next (you owe {M(−잔액)}, the most)`(성별을 모르므로 대명사를 쓰지 않는다. 앱만, 9단계 번역). `balancesOf`가 null이면 숨긴다.
- **요약 공유**: 기간 합계, 상위 카테고리, 잔액을 담은 텍스트를 공유 시트로(`share_plus`). 앱만.

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

## 송금 기록·편집 (6단계)
새 이벤트 종류는 없다. `payment.created`·`payment.deleted`·`comment.added`를 쓴다.
- **아무 송금 기록**(Settle up의 **Record a payment**, 앱 `features/settle/payment_sheet.dart`): From·To(서로 다른, removed 아닌 아무 멤버), Amount(> 0), Currency(`shared/currencies.json`의 아무 통화, 기본 D. Settle up의 송금 카드에서 열면 그 카드의 from·to·금액·통화로 채운다), Date(기본 오늘, 바꿀 수 있다). `payment.created` 하나.
- **status**(앱이 정한다): From이 내 멤버이고 To가 다른 사용자에 연결된 멤버면 `"sent"`(받는 사람이 1단계대로 확인), 그 밖(내가 받는 사람, 자리표시에게 보냄, 다른 두 사람 사이의 기록)은 `"confirmed"`. 서버 정규화(받는 사람이 자리표시이거나 보낸 사람 본인이면 `confirmed`)는 그대로다.
- **편집** = 이전 송금의 `payment.deleted {"paymentId": 이전 id, "replacedBy": 새 id}`(7단계부터 `replacedBy`) + 새 id의 `payment.created`를 한 로컬 트랜잭션으로 outbox에 넣는다(`payment.updated`는 없다). 이전 송금은 `replaced`가 되어 되살릴 수 없다(적용 규칙 7). 송금을 누르면 같은 시트가 편집으로 열린다. 편집·삭제는 그 송금의 From이나 To에 연결된 사용자에게만 보인다(앱. 서버의 `payment.deleted` 권한은 1단계 그대로). 새 송금의 status는 위 규칙으로 다시 정한다(보낸 사람이 고치면 다시 확인 대기). 보통 한 push로 가므로 받는 사람에게는 표시 알림 하나 `{A} made 2 changes`. 활동(7단계): 이전 송금의 삭제는 `payment_edited`(`{A} edited a payment of …`, 삭제처럼 읽히지 않게), 새 송금은 `payment_added`. 이전 송금의 상세 제목은 `Edited payment`(배너 `This payment was edited`). 6단계까지의 앱은 모르는 kind라 `{A} made a change`로 보인다.
- 편집하면 이전 송금의 댓글은 이전(삭제된) 송금에 남는다(옮기지 않는다). 댓글이 있는 송금을 고칠 때 시트는 `Comments stay with the old payment` 한 줄을 보인다.
- **삭제한 송금 되살리기**(7단계, parity #110) = `payment.restored {"paymentId"}`. 지출 복원(2단계)과 같은 자리에 둔다: 송금을 지운 뒤 10초 동안 SnackBar **Undo**(편집의 삭제에는 없다 — 편집은 다시 고친다), 삭제된 송금의 상세 화면 배너 `This payment was deleted` + **Restore**, 활동 목록에서 그 송금의 가장 최근 `payment_deleted` 행의 **Restore**. 셋 다 그 송금이 지금 삭제되어 있고 `replaced`가 아니며 보는 사람이 그 송금의 From이나 To에 연결된 사용자일 때만 보인다(서버 권한은 `payment.deleted`와 같다. 만든 사용자는 앱이 모르므로 앱은 From·To만 본다). `replaced`인 송금의 상세는 `This payment was edited` 배너만 보이고 Restore가 없다. 되살린 송금의 status는 지울 때 그대로다(`sent`면 받는 사람이 다시 확인한다). 활동은 `payment_restored`. 로컬 쓰기는 지출 복원과 같다(낙관적으로 `deleted=false`, outbox에 넣기).
- **송금 상세** `/groups/:id/payments/:pid`(앱): From → To, 금액, 날짜, status와 1단계 Confirm received / Not received, Edit·Delete(위 권한), 댓글 스레드(`comment.added {paymentId}`. 지출 댓글과 같은 규칙: 삭제된 송금에도 달 수 있고 작성자만 지운다). 활동의 `payment_*` 항목, 송금 댓글 항목, Settle up의 기록된 송금을 누르면 여기로 온다.
- **친구와 한 번에 정산**(친구 페이지 **Settle up**): 아래 "개요"의 원장(`GroupLedger.transfers`)에서 나와 그 사람 사이의 송금을 그룹·통화별로 모은다(내 멤버 하나와 그 사람의 멤버 하나 사이). 통화마다 net = Σ(그 사람이 나에게 줄 금액). 통화마다 한 줄이고, 환산 안 된 칸만 있는 통화도 그 통화로 정산한다(환율 없는 지출이 있으면 Convert도 함께).
  - 기록 = 그 송금마다 `payment.created` 하나(그 그룹, 그 통화, 그 송금의 from·to·amount). 내가 내는 송금이고 그 통화의 net < 0이면 `"sent"`(1단계 **I've sent it**), 그 밖(내가 받는 쪽 **Mark as received**, 그리고 net과 반대 방향인 상계 송금 — 실제로 돈이 오가지 않는다)은 `"confirmed"`.
  - 그룹마다 따로 outbox에 넣고 push한다(그룹 로그는 따로다).
  - net < 0이면 결제 수단 칩(1단계): 친구 그룹의 `GET /groups/{id}/payment-methods`, 친구 그룹이 없으면 공유 그룹 하나에서 그 사람의 멤버 id로 읽는다. `_pay`·`_bankSheet`는 `features/settle/pay_sheet.dart`로 옮긴다.

## 친구 (6단계)
친구 = 숨은 2인 그룹(`kind: "friend"`). 그룹 밖 지출(non-group)도 같은 이벤트 로그·outbox·두 적용기·내보내기·Settle up을 쓴다. 따로 된 장부는 없다. 사람별로 보이는 금액(Friends 탭, 전체 카드, 친구 페이지, 리마인더)은 모두 그룹마다의 Settle up 송금에서 아래 "개요" 규칙으로 만든다.

| 메서드 | 경로 | 요청 | 응답 |
|---|---|---|---|
| GET | `/me/friend-code` | | `FriendCode`. 처음 부를 때 만든다 |
| POST | `/me/friend-code/rotate` | | `FriendCode`(새 코드). 이전 코드는 그때부터 404 |
| GET | `/friend-invites/{code}` | 인증 불필요, 코드 정규화 | `{"displayName": "Anna"}`. 없는 코드 404 `NOT_FOUND`, IP 제한 429 `RATE_LIMITED` |
| GET | `/f/{code}` | 인증 불필요, 코드 정규화 | HTML 랜딩 "{displayName} wants to split expenses with you"와 **Open in app** → `evensies://f/{code}`(`/j/`와 같은 템플릿 함수, 이름은 HTML escape). 없는 코드 404, 429 |
| POST | `/friends` | `{"id", "defaultCurrency"}` + `"code"`·`"userId"`·`"name"` 가운데 정확히 하나 | `GroupDto`(`kind: "friend"`, `myMemberId` = 호출자의 멤버). 아래 |
| POST | `/friends/{userId}/remind` | | 아래 "리마인더" |

```
FriendCode {"friendCode": "K7P4QX", "link": "https://evensies.nariinfo.dev/f/K7P4QX"}
```
- `link` = `EVENSIES_PUBLIC_URL`(끝의 `/`는 뺀다) + `/f/` + 코드. 앱의 링크 해석(`extractInviteCode`)은 `/f/<code>`와 `evensies://f/<code>`를 친구 코드로 읽는다. Universal Links(`apple-app-site-association`의 `"/f/*"`)와 App Links(`host="f"`, `pathPrefix="/f/"`).
- 친구 코드: 6자(위 "초대 코드"), 사용자당 하나(`users.friend_code`, UNIQUE). 계정을 지우면 `NULL`.
- **공유 그룹** = 두 사용자가 모두 `user_id`로 연결된 member 행을 가진 그룹(removed 포함, `kind`와 상관없음). 프로필 사진과 리마인더의 권한이 이 정의를 쓴다. `userId`로 친구 추가는 더 좁게 두 행이 모두 removed 아닌 공유 그룹만 센다(친구 그룹은 나갈 수 없고 서로의 결제 수단을 보이므로, 나간 사람·내보낸 사람을 동의 없이 넣지 않는다).

**`POST /friends`**
- `id`: 앱이 만든 새 그룹 UUID(재시도 멱등, `POST /groups`와 같다). 그 id의 그룹이 이미 있으면 다른 검사 없이 그 그룹을 돌려준다(호출자가 멤버가 아니면 403).
- `defaultCurrency`: 새로 만들 때의 기본 통화(앱은 홈 통화). 필수, 목록에 없으면 400 `UNKNOWN_CURRENCY`. 이미 있는 친구 그룹을 돌려줄 때는 쓰지 않는다.
- 셋 가운데 하나(`null`은 없는 것. 셋 다 없거나 둘 이상이면, 또는 문자열이 아니면 400 `VALIDATION`):
  - `code`: 친구 코드(정규화). 없는 코드 404 `NOT_FOUND`. 위 IP당 버킷을 쓴다(429).
  - `userId`: 호출자와 지금 함께 있는(두 멤버 모두 removed 아님) 공유 그룹이 있는 사용자. 모르는 id, 삭제된 계정, 그런 공유 그룹 없음은 모두 403 `FORBIDDEN`(있는지 알리지 않는다).
  - `name`: 아직 Evensies를 쓰지 않는 사람(자리표시 친구). trim 뒤 1~30 code point, 아니면 400 `VALIDATION`.
- 코드나 userId가 호출자 본인이면 400 `SELF_FRIEND`.
- 속도: 호출마다 사용자당 이벤트 버킷(분당 120, `POST /groups/{id}/events`와 같은 버킷)에서 3개를 쓴다. 넘으면 429 `RATE_LIMITED`. `code`·`userId` 친구 수 상한은 없다(사람마다 하나). `name`(자리표시 친구)은 사용자당 200: 호출자가 removed 아닌 멤버이고 상대 멤버가 연결 안 된(claim 전이거나 계정을 지운) 친구 그룹이 이미 200개면 409 `LIMIT_EXCEEDED`(재시도 `id`는 위대로 그 그룹). claim되면 다시 자리가 난다.
- `code`·`userId`(A = 호출자, B = 상대). 한 트랜잭션:
  1. `SELECT id FROM users WHERE id IN (:a, :b) AND deleted_at IS NULL ORDER BY id FOR UPDATE`(두 사람의 동시 요청이 한 줄로 선다). 2행이 아니면(잠금을 기다리는 사이 계정이 지워졌으면) 앞의 조회와 같은 오류(`code` 404, `userId` 403).
  2. `friendships(user_lo, user_hi)` 행이 있으면 그 그룹을 돌려준다. 같은 두 사람은 어느 쪽에서 몇 번 해도 같은 그룹이다.
  3. 없으면 그룹 행(`kind = 'friend'`, 새 초대 코드)을 넣고 서버가 만든 이벤트 셋을 **검증 없이**(trusted, 같은 잠금·seq·적용·meta 경로) 저장한다: seq 1 `group.created {"name": "{A 이름} & {B 이름}", "defaultCurrency", "kind": "friend"}`, seq 2 `member.added {"memberId": 새 UUID, "name": A 이름, "userId": A}`, seq 3 `member.added {"memberId": 새 UUID, "name": B 이름, "userId": B}`. 이름은 `users.display_name`(비었으면 `Friend`). 세 이벤트의 actor는 A. 그다음 `friendships`에 (lo, hi, groupId)를 넣는다.
  4. 커밋한 **뒤** 푸시(`PushNotifier.notify`): B의 기기는 `friend_added` 표시 알림과 sync data를 받는다(B의 앱은 모르는 groupId라 `syncAll()`로 새 그룹을 받아들인다).
- `user_lo`·`user_hi`: 두 UUID를 **소문자 문자열**로 비교해 작은 쪽이 lo(Postgres uuid 순서와 같다. Kotlin `UUID.compareTo`는 부호 있는 long 비교라 쓰지 않는다).
- `name`: 사용자 잠금과 `friendships` 행 없이 같은 방법으로 만든다. seq 3은 `member.added {"memberId": 새 UUID, "name": name, "userId": null}`. 친구는 이 그룹의 초대 코드(`GroupDto.inviteCode`, `/j/{code}`)로 그 자리표시를 claim한다. 친구 그룹의 `/j/{code}` 랜딩은 그룹 이름 대신 연결된 멤버 이름으로 "{name} added you as a friend on Evensies."를 보인다(없으면 `Someone`).
- 응답은 언제나 200 `GroupDto`. 앱은 그 뒤 snapshot으로 그룹을 받아들인다(초대 참여와 같다). 온라인일 때만(친구가 생긴 뒤의 지출은 오프라인에서도 된다).

**친구 그룹 규칙** (검증기는 `state.kind`를 본다)
- 멤버는 정확히 2명. 셋째 `member.added`는 409 `LIMIT_EXCEEDED`(그래서 친구 그룹의 `/invites/{code}/join {newMemberId}`와 Splitwise 가져오기의 새 이름도 409). `member.removed`는 400 `VALIDATION`(나가기 없음. 친구 삭제는 10단계).
- 자리표시 친구 claim(`/invites/{code}/join {memberId}` → `member.linked`)은 그룹 상한 검사를 하지 않고, 같은 요청에서 `GroupService.join`이 두 연결 사용자의 `friendships` 행을 `ON CONFLICT DO NOTHING`으로 넣는다. 두 사람에게 이미 친구 그룹이 있었으면 둘 다 남고 `POST /friends`는 계속 `friendships`의 그룹을 돌려준다. 앱은 같은 userId의 친구 그룹을 한 사람으로 합쳐 보인다.
- 이름(`"Anna & Ben"`)은 내보내기에서만 보인다(앱 내보내기 목록은 `Non-group · Ben`). 앱은 상대 멤버의 이름을 쓴다. `group.updated`는 보통 그룹과 같게 받지만 앱에는 친구 그룹의 설정 화면이 없다.
- 활동: seq 1·2는 숨기고 seq 3은 `friend_added`(위 "피드"). 푸시 제목은 상대 이름.

## 개요 (6단계)
Friends 탭, 전체 카드, 친구 페이지, 리마인더가 쓰는 하나의 규칙. 앱 `domain/overview.dart`, 서버 `money/Overview.kt`, 양쪽이 `shared/overview-cases.json`을 읽는다(케이스마다 상태 → `balancesOf`/`Balances.ofGroup` → `groupTransfers`/`Balances.transfers` → 개요이므로 Kotlin `Balances` 이식도 함께 검사한다).

```
GroupLedger {
  groupId,
  myMemberId,                          // 새 송금에 쓰는 내 멤버: removed 아닌 내 멤버, 없으면 상태 순서로 첫 내 멤버
  personOf: {memberId: person},        // 모든 멤버(내 멤버 포함). 연결 → userId, 친구 그룹의 자리표시 → "g:<groupId>", 보통 그룹의 자리표시 → "m:<memberId>"
  transfers: {currency: [Transfer]}    // groupTransfers(state) (4단계 칸, 환산 안 된 칸 포함): Settle up이 보이는 그대로
}
Overview {
  people:   {person: {currency: amount}},             // + = 그 사람이 나에게 줄 돈, − = 내가 줄 돈
  byGroup:  {person: {groupId: {currency: amount}}},
  owedToMe: {currency: amount}, iOwe: {currency: amount}
}
```
- `GroupLedger.of(groupId, state, myUserId)`: `userId == myUserId`인 멤버가 없으면 `null`(7단계: 잔액을 계산할 수 없는 그룹은 더 없으므로 `{n} group(s) not included yet` 줄을 지운다).
- `computeOverview(ledgers)`:
  1. 내 멤버 = `personOf[m] == myUserId`인 모든 멤버(removed 포함. 나갔다 다시 들어온 사용자는 둘이다).
  2. 송금마다 `a = personOf[from]`, `b = personOf[to]`. `b`만 나면 `people[a][통화] += amount`, `a`만 나면 `people[b][통화] −= amount`. 둘 다 나거나 둘 다 내가 아니면 무시한다.
  3. 사람·통화별(`people`), 사람·그룹·통화별(`byGroup`)로 더한다. 환산·반올림은 없다.
  4. 0을 빼고, 그다음 빈 사람·빈 그룹을 뺀다.
  5. `owedToMe[c]` = Σ max(0, people[p][c]), `iOwe[c]` = Σ max(0, −people[p][c]). 0이면 키가 없다.
  6. 불변식(테스트): 통화마다 `owedToMe[c] − iOwe[c]` = 모든 원장에서 내 멤버들 잔액의 합.
- 설계(phase-06)의 "상태 순서로 첫 내 멤버만 나"를 1·2로 정했다: 첫 멤버만 보면 다시 들어온 멤버의 송금이 빠지고, 내 두 멤버 사이의 송금이 나와의 빚처럼 보인다(`overview-cases` "left and rejoined").
- 서버 리마인더는 같은 규칙으로 계산한다.
- 화면(앱, 9단계 번역 전 영어):
  - 사람 = 모든 원장의 `personOf` 값 가운데 나를 뺀 것. `m:` 키(보통 그룹의 자리표시)는 `people`에 있을 때(잔액이 있을 때)만 보이고 부제는 그 그룹 이름이다. `g:` 키(자리표시 친구)와 연결 사용자는 정산됐어도 보인다(Settled up 아래). 이름 = 친구 그룹의 그 멤버 이름, 없으면 그룹 이름순으로 첫 공유 그룹의 멤버 이름. 라우트 `/friends/:key`(`key` = userId, `g:<groupId>`, `m:<memberId>`).
  - 같은 userId의 친구 그룹이 여럿이면 한 페이지로 합치고, 새 non-group 지출은 id(문자열)가 가장 작은 친구 그룹에 넣는다. 친구 그룹이 없는 연결 사용자에게 지출을 더하면 먼저 `POST /friends {userId, defaultCurrency: 홈 통화}`(온라인만).
  - **Add expense**(7단계에 정함): 친구 그룹이 있으면 언제나 보인다. 보통 그룹의 자리표시(`m:` 키)에는 없다(그 그룹에서 더한다). 친구 그룹이 없는 연결 사용자는 **지금 함께 있는 그룹**(로컬의 `kind: "group"` 그룹 가운데 나에게 연결된 removed 아닌 멤버와 그 사람에게 연결된 removed 아닌 멤버가 둘 다 있는 그룹 — `POST /friends {userId}`의 서버 조건과 같다)이 있을 때만 보인다. 없으면 버튼 대신 `You no longer share a group with {name}. Send them your friend link to add expenses.` 한 줄과 **Share friend link**(`GET /me/friend-code`의 링크를 Add friend 화면과 같은 글 `Add me on Evensies to split expenses: {link}\nOr enter my code {code}`로 공유 시트에. 오프라인이면 `Sharing your friend link needs a connection.`)를 보인다. 로컬 상태가 늦어 `POST /friends`가 403 `FORBIDDEN`이면 서버 오류 글 대신 같은 한 줄과 버튼을 보인다. 홈의 Add expense(*with whom?* 고르기)에서 그런 사람을 누르면 같은 글과 **Share friend link**·Cancel 대화 상자.
  - 행: 통화가 하나면 `owes you €12.00` 또는 `you owe $5.00`. 여럿이면 가장 큰 것 뒤에 `*`. "가장 큰 것" = 최신 로컬 환율 표(4단계 `FxDays`)로 EUR 주 단위로 바꾼 절댓값(`|amount| / 10^digits / perEur[c]`, 정렬에만 쓰고 보이지 않는다)이 가장 큰 통화. 환율이 없는 통화는 뒤로, 같으면 통화 코드순.
  - 칩 All · Owes me(어느 통화든 > 0) · I owe(어느 통화든 < 0)는 두 탭(사람, 그룹의 내 잔액)에 같다. 모든 통화에서 0인 사람·그룹은 **Settled up (n)** 아래(기본 닫힘).
  - 전체 카드(두 탭 위): `You are owed €42.10 · $15.00`(`owedToMe`, 통화 코드순), `You owe €8.00`(`iOwe`), `≈ €61.20 overall`(홈 통화 H로 통화마다 `convertAmount(owedToMe − iOwe, …, crossRate(최신 표, c, H))`의 합. 환율이 하나라도 없으면 숨긴다).
  - `overviewProvider`는 로컬 그룹이 바뀔 때마다 모두 다시 계산한다(`ponytail:` 전체 재계산. 그룹이 수백 개면 그룹별 캐시).
  - 친구 페이지: 머리(사진, 통화별 net), 그룹별 줄(`byGroup`, 누르면 그 그룹. 친구 그룹 줄은 `Non-group`), 함께한 기록(아래), **Settle up**(위 "송금 기록·편집"), **Remind**(연결된 사람이 나에게 줄 돈이 있을 때) 또는 **Request**(자리표시), 자리표시 친구면 **Invite**(그 그룹의 `/j/` 링크), 더 보기에서 non-group 지출 CSV·JSON 내보내기.
  - **함께한 기록**(7단계, parity #109 — Splitwise의 친구 화면): 그 사람과 함께 있는 모든 로컬 그룹의 지출·송금을 **그룹별 섹션**으로 보인다(앱만, 서버 변경 없음). 그룹은 `personOf`로 내 멤버와 그 사람의 멤버(removed 포함)가 둘 다 있는 그룹이다. 친구 그룹은 삭제 안 된 지출·송금 전부. 그 밖의 그룹은 삭제 안 된 지출 가운데 내 멤버 하나와 그 사람의 멤버 하나가 각각 `payers`나 `shares`에 0이 아닌 금액으로 있는 것, 그리고 삭제 안 된 송금 가운데 내 멤버와 그 사람의 멤버 사이(방향 무관)의 것. 섹션 순서: 친구 그룹(여럿이면 하나로 합침) `Non-group`이 먼저, 그다음 보통 그룹을 그 섹션의 가장 최근 행 날짜 내림차순(같으면 이름순). 섹션 머리는 그룹 이름이고 누르면 그 그룹. 섹션 안은 date 내림차순, 같으면 상태에서 나중 것 먼저. 행은 그룹 목록과 같은 읽기 전용 타일이고 누르면 지출 상세(`/groups/:id/expenses/:eid`)나 송금 상세(`/groups/:id/payments/:pid`)를 연다. 기록이 없고 친구 그룹이 있으면 `Nothing together yet. Add an expense below.` 8단계: 섹션마다 날짜가 바뀌는 곳에 그룹 목록과 같은 날짜 머리(`DateHeader`, `EEE, d MMM`)를 넣는다(친구 그룹 섹션과 공유 그룹 섹션 모두. 지금은 행에 날짜가 없다).

## 지출 옮기기 (6단계)
편집 중 *With*(그룹 또는 친구)를 바꾸면 옮긴다. 온라인일 때만.
- `remapForMove(Expense e, List<Member> source, List<Member> target) → Expense?`(앱, 순수): 금액이 0보다 큰 `payers`·`shares`의 멤버(관련된 사람)마다 같은 `userId`를 가진 대상 그룹의 removed 아닌 멤버로 바꾼다. 관련된 사람 가운데 자리표시(`userId` 없음)가 있거나 대상에 그 사용자의 활성 멤버가 없으면 `null`(앱: `Only people on Evensies who are in both can be moved`). 0인 `payers`·`shares` 항목과 대상 멤버가 없는 `split.input` 키는 뺀다. `paidBy`는 주요 결제자로 다시 정한다(규칙 10). `fxRateToDefault`는 두 그룹의 기본 통화가 같을 때만 남기고 아니면 `null`. 그 뒤 수정 화면이 지출 통화가 대상 기본 통화와 다르고 환율이 `null`이면 새 지출처럼 그 날짜의 자동 환율(`GET /fx`)을 넣는다(없으면 `null`, 대상에서 환산 안 됨). 설명·금액·통화·날짜·카테고리·메모·환불·분할 모드는 그대로, expenseId는 새로 만든다.
- 순서: 1. 대상 그룹에 그 `expense.created`를 바로 push한다(outbox를 거치지 않는다). 2. 성공한 뒤에만 원래 그룹의 outbox에 `expense.deleted {"expenseId", "movedTo": {"groupId": 대상, "expenseId": 새 id}}`를 넣는다. 1이 실패하면 아무것도 바뀌지 않는다(`Couldn't move it. Try again when you're online`).
- 다시 시도(같은 대상): 1의 `expenseId`·`clientId`를 그대로 쓴다(첫 시도가 저장되고 응답만 잃었으면 서버가 중복으로 보고 그 seq를 돌려준다). 같은 배치에 그 지출의 지금 값 전부(`expense.created` payload에서 `expenseId`를 뺀 것)를 `fields`로 하는 `expense.updated`(새 `clientId`)를 붙인다. 첫 시도가 저장됐으면 그 사이 고친 값이 이것으로 들어가고, 아니면 같은 값이라 상태가 바뀌지 않는다(활동 숨김 1).
- 댓글·편집 기록은 원래(삭제된) 지출에 남는다. 활동은 원래 그룹에 `expense_moved`(Restore 없음), 대상 그룹에 `expense_added`. 원래 지출은 `moved`가 되어 복원되지 않는다(적용 규칙 13: 다른 기기가 오프라인에서 넣어 둔 `expense.restored`가 나중에 와도 두 그룹에서 세지 않는다).
- 대상이 친구 그룹이 아직 없는 연결 사용자면 먼저 `POST /friends {userId}`.

## 프로필 사진 (6단계)
| 메서드 | 경로 | 요청 | 응답 |
|---|---|---|---|
| PUT | `/me/avatar` | multipart `file`: JPEG, 307,200바이트(300 KB) 이하, 가로·세로 1024px 이하 | 204(있던 사진은 바꾼다) |
| DELETE | `/me/avatar` | | 204(없어도) |
| GET | `/users/{userId}/avatar` | | 200 `image/jpeg` |
- 보는 사람: 본인, 그리고 그 사용자와 공유 그룹이 있는 사용자. 아니면 403 `FORBIDDEN`(사진이 있는지 알리지 않도록 404보다 먼저 본다). 사진이 없으면 404 `NOT_FOUND`. 삭제된 계정은 멤버 연결이 풀려 공유 그룹이 없으므로 다른 사람에게는 403이다(사진 파일도 지워진다). 응답 헤더 `Cache-Control: private, max-age=3600`, `X-Content-Type-Options: nosniff`. 내려받기는 언제나 API를 거친다(Bearer 토큰).
- `PUT` 검사 순서: 속도(사용자당 시간당 10회, 실패한 시도도 센다, 메모리 `RateLimiter`) → 429 `RATE_LIMITED`. 크기: 307,200바이트 초과, 또는 5 MB multipart 상한 초과(`GlobalExceptionHandler`가 `MaxUploadSizeExceededException`을 413으로 바꾼다. 지금은 500) → 413 `TOO_LARGE`. `file` 파트가 없으면 400 `VALIDATION`. 그다음 `Jpeg.clean(bytes, 1024)`: SOI(`FF D8`)로 시작하지 않거나 구조가 깨졌으면(세그먼트 길이가 넘침, 잘림, SOS 전에 SOFn 없음) 400 `NOT_JPEG`. SOFn의 가로나 세로가 1024를 넘으면 400 `IMAGE_TOO_LARGE`. 서버는 믿을 수 없는 픽셀을 디코딩하지 않는다(앱이 이미 다시 인코딩했다). Content-Type 헤더는 보지 않는다.
- `Jpeg.clean`은 마커를 따라가며 APP0·APP14는 남기고 APP1~APP13·APP15·COM(EXIF와 GPS, XMP, IPTC, 내장 썸네일)은 버린다. 다른 세그먼트(DQT, DHT, SOFn, DRI, SOS…)는 그대로. SOS 뒤 엔트로피 데이터에서 `FF 00`과 `FF D0`~`FF D7`은 데이터이고, 마커 앞의 연속된 `FF`는 채움 바이트. progressive JPEG(SOS 여러 개)도 된다. EOI에서 멈추고 그 뒤의 바이트는 버린다. 결과는 같은 크기로 디코딩되어야 한다(테스트).
- 저장: `storage/FileStore.kt` `write(key, bytes)`(같은 디렉터리의 임시 파일 → `Files.move(…, ATOMIC_MOVE)`), `path(key): Path?`, `delete(key)`. 루트는 `EVENSIES_STORAGE_DIR`. 키는 Spring이 이미 파싱한 UUID로만 만든다(경로 탐색 불가): `avatars/{userId}.jpg`, 7단계 `attachments/{groupId}/{id}.jpg`·`{id}_thumb.jpg`, 10단계 `covers/{groupId}/{coverId}.jpg`. `ponytail:` 로컬 디스크만. 디스크가 70%쯤 차면 S3 호환 저장소를 비용과 함께 제안한다.
- 계정 삭제는 커밋 뒤 `avatars/{userId}.jpg`를 지운다.
- 앱: Settings에서 내 사진을 누르면 Take photo / Choose from library / Remove. `data/images.dart` `prepareJpeg(XFile picked, {required int maxEdge, required int quality})`(방향을 픽셀에 적용, EXIF 제거, HEIC → JPEG. 새 의존성 `image_picker`·`flutter_image_compress`, iOS `NSCameraUsageDescription`·`NSPhotoLibraryUsageDescription`). 사진은 `maxEdge: 512, quality: 85`(약 50 KB). `PersonAvatar(userId?, name)`: 원 안에 `BoxFit.cover`, 없거나 오류면 이름 머리글자. `avatarProvider(userId)`는 `ApiClient`로 받아(토큰 갱신) 세션 동안 기억하고, 내 사진은 올리거나 지운 뒤 다시 받는다. `docs/privacy.md`에 프로필 사진 항목(누가 보는지, 서버 디스크의 512px JPEG, 계정과 함께 삭제).

## 리마인더 (6단계)
| 메서드 | 경로 | 요청 | 응답 |
|---|---|---|---|
| POST | `/friends/{userId}/remind` | | `{"amounts": [{"currency": "EUR", "amount": 1500}]}` |
1. 호출자와 `{userId}`의 공유 그룹을 모두 읽는다(removed 포함, 친구 그룹 포함). `{userId}`가 본인이거나 공유 그룹이 없으면 403 `FORBIDDEN`.
2. 그룹마다 `Balances.ofGroup` → `Balances.transfers` → `GroupLedger`(나 = 호출자), 그리고 `Overview.compute`("개요").
3. `people[userId]`에서 양수인 통화(그 사람이 나에게 줄 돈)만 남긴다. 없으면 409 `NOTHING_OWED`(오늘의 기회를 쓰지 않는다. 내가 그 사람에게 줄 돈만 있어도 409).
4. 기회를 원자적으로 잡는다: `INSERT INTO reminders (from_user, to_user, sent_at) VALUES (:me, :them, now()) ON CONFLICT (from_user, to_user) DO UPDATE SET sent_at = now() WHERE reminders.sent_at < now() - interval '24 hours'`. 바뀐 행이 0이면 429 `RATE_LIMITED`, `Retry-After` = 남은 초(올림, 1 이상).
5. 상대의 `notification_prefs.reminders`가 `true`면 상대의 모든 기기로 표시 알림을 보낸다(`PushSender`, 죽은 토큰은 다른 푸시처럼 지운다). `false`면 보내지 않는다. 응답은 어느 쪽이든 같은 200이다.
- `amounts`: 통화 코드 오름차순, 금액은 최소 단위 양수.
- 푸시: title `{A} sent a reminder`. body: 통화 1개 `You owe {A} {M1}.`, 2개 `You owe {A} {M1} and {M2}.`, 3개 이상 `You owe {A} {M1}, {M2} and more.`(`amounts` 순서). `{A}` = 보낸 사람의 `displayName`(비었으면 `Someone`), 금액 표기와 title/body 자르기는 "문장"·"푸시"와 같다(`ActivityText`). data `{"type": "remind", "fromUserId": "<uuid>"}`. 배지 없음, APNs `thread-id` 없음.
- 앱: 친구 페이지의 **Remind**(연결된 사람이 나에게 줄 돈이 있을 때). 429면 `You can remind {name} again tomorrow`, 409면 `{name} doesn't owe you anything`. 자리표시에게는 1단계 **Request** 공유 텍스트. 알림을 누르면 `/friends/{fromUserId}`. Settings의 알림 스위치에 Reminders(`PUT /me/notifications`의 `reminders`).

## 6단계 오류 코드
새 코드: `SELF_FRIEND`(400), `NOTHING_OWED`(409), `NOT_JPEG`(400), `IMAGE_TOO_LARGE`(400), `TOO_LARGE`(413). 다시 쓰는 코드: `LIMIT_EXCEEDED`(409), `RATE_LIMITED`(429), `FORBIDDEN`(403), `NOT_FOUND`(404), `VALIDATION`(400), `UNKNOWN_CURRENCY`(400). 앱의 "거부된 이벤트" 표는 그대로다(새 이벤트 오류는 `VALIDATION`·`LIMIT_EXCEEDED`).

## 영수증 (7단계)
지출에 영수증 사진을 붙인다(지출당 10장까지). 그 그룹 멤버만 내려받는다. 글자 인식(스캔)은 폰에서만 하고, 서버로 가는 것은 사용자가 붙인 사진뿐이다. 저장소는 6단계 `FileStore`(`EVENSIES_STORAGE_DIR`)와 `Jpeg.clean`을 쓴다.

| 메서드 | 경로 | 요청 | 응답 |
|---|---|---|---|
| POST | `/groups/{id}/attachments/{attachmentId}` | multipart `image`(JPEG, 2,097,152바이트 이하, 가로·세로 4096px 이하) + `thumb`(JPEG, 204,800바이트 이하, 1024px 이하). `attachmentId`는 앱이 만든 UUID | 201 `{"id": "<attachmentId>"}`. 이 그룹에 이미 저장된 id면 200 같은 본문 |
| GET | `/groups/{id}/attachments/{attachmentId}` | | 200 `image/jpeg`(큰 사진) |
| GET | `/groups/{id}/attachments/{attachmentId}/thumb` | | 200 `image/jpeg`(썸네일) |

**올리기** 검사 순서:
1. 그룹 없음 404 `NOT_FOUND`, 호출자가 지금(removed 아님) 멤버가 아님 403 `FORBIDDEN`(`requireMember`).
2. 속도(abuse cap): 사용자당 시간당 60회(메모리 `RateLimiter(60.0, 60.0 / 3600)`, 프로필 사진과 다른 버킷. 실패한 시도와 200 재시도도 센다) → 429 `RATE_LIMITED`.
3. `image`나 `thumb` 파트가 없음 → 400 `VALIDATION`.
4. 크기: `image` > 2,097,152바이트 또는 `thumb` > 204,800바이트 → 413 `TOO_LARGE`. 요청이 multipart 상한(5 MB)을 넘으면 지금처럼 413 `TOO_LARGE`.
5. `attachments` 행 조회: 이 그룹의 행이면(붙었든 삭제됐든) 200이고 파일을 쓰지 않는다(처음 쓴 것이 이긴다. 재시도가 안전하다). 다른 그룹의 행이면 409 `DUPLICATE`.
6. `Jpeg.clean(image, 4096)`, `Jpeg.clean(thumb, 1024)`(6단계와 같은 함수, 메타데이터 제거, 픽셀은 디코딩하지 않음) → 400 `NOT_JPEG` / 400 `IMAGE_TOO_LARGE`.
7. 파일 두 개 `attachments/{groupId}/{attachmentId}.jpg`·`attachments/{groupId}/{attachmentId}_thumb.jpg`를 쓰고(`FileStore.write`), 그다음 행을 넣는다(`expense_id = NULL`, `uploaded_by` = 호출자). 동시에 같은 id가 들어와 `DuplicateKeyException`이면 5를 다시 본다(이 그룹이면 200, 다른 그룹이면 409). → 201.
- 올린 행은 `attachment.added`가 올 때까지 어느 지출에도 붙지 않고 snapshot에 없다. 8단계의 하루 정리("반복 지출"의 "하루 정리")가 7일 동안 붙지 않은 올리기(행과 파일)와 크래시로 남은 삭제된 행의 파일을 지운다.

**내려받기**: 그룹 없음 404, 멤버 아님 403(먼저 본다). 이 그룹의 행이 없거나(없는 id, 다른 그룹의 id), 삭제됐거나(`deleted_at`), 파일이 없으면 404 `NOT_FOUND`. 붙기 전의 올리기도 같은 그룹 멤버는 받는다. 헤더 `Content-Type: image/jpeg`, `Cache-Control: private, max-age=31536000, immutable`(한 id의 파일은 바뀌지 않는다), `X-Content-Type-Options: nosniff`. 언제나 API(Bearer 토큰)를 거친다.

**이벤트와 저장** (`attachment.added`·`attachment.deleted`, 위 "이벤트 종류와 payload"와 적용 규칙 14. 보통 push로 간다):
- 검증기는 "이 그룹에 올렸는지"를 `attachments` 행(`id`, `group_id = 이 그룹`, 삭제 여부 무관)으로 본다(`paymentCreator`처럼 함수로 넘긴다). 붙은 영수증의 지출·개수는 상태에서 본다.
- 저장(`GroupStateStore.persist`): 적용 뒤 상태의 그 영수증으로 `UPDATE attachments SET expense_id = :expenseId, deleted_at = CASE WHEN :deleted THEN COALESCE(deleted_at, now()) ELSE NULL END WHERE id = :id AND group_id = :groupId`(상태에 없으면 아무것도 하지 않는다). `load`는 `expense_id IS NOT NULL`인 행을 `created_at, id` 순서로 읽는다. `GroupState.attachments`를 snapshot이 싣는다.
- **파일 지우기**: push가 커밋된 **뒤**, 그 push에서 상태를 바꾼(`meta.noop == false`) `attachment.deleted`마다 두 파일을 지운다. 행은 `deleted_at`과 함께 남는다. 없는 id, 이미 삭제된 영수증, 다른 그룹의 id는 상태를 바꾸지 않으므로 파일을 건드리지 않는다.
- `expense.deleted`(옮기기 포함)와 10단계 그룹 삭제는 영수증을 지우지 않는다(복원하면 돌아온다). `DELETE /me`도 그대로 둔다(그룹의 기록이다).
- 상한(abuse cap): 지출당 삭제 안 된 영수증 10개(409 `LIMIT_EXCEEDED`), 사용자당 올리기 시간당 60회(429).

**앱**
- 사진: `image_picker`의 원본 → `prepareJpeg`(6단계)로 `{appSupport}/pending_attachments/{id}.jpg`(`maxEdge: 2048, quality: 80`, 300~700 KB쯤)와 `{id}_thumb.jpg`(`maxEdge: 512, quality: 70`) → 원본 임시 파일 삭제 → (스캔이면 준비한 2048px 사진으로 글자 인식. 50MP가 넘는 원본은 Android에서 한 번에 디코딩하기에 너무 크다). 새 지출의 id는 폼을 열 때 만든다. 폼을 취소하면 준비한 파일을 지운다.
- 로컬 쓰기: `attachReceipt(groupId, expenseId, attachmentId)` = 로컬 `attachments` 행 + `pending_uploads` 행 + outbox `attachment.added`(새 지출이면 그 `expense.created` 뒤)를 한 트랜잭션으로. `removeReceipt`: 아직 올리지 않았으면(pending 행 있음) 파일·pending 행·보내지 않은 `attachment.added`·로컬 행을 지우고 서버에는 아무것도 가지 않는다. 올린 뒤면 outbox `attachment.deleted {"attachmentId", "expenseId"}`, 로컬 행 `deleted=true`, 캐시 파일 삭제.
- `SyncService.sync(groupId)` 순서:
  1. **올리기**: 그 그룹의 pending 행을 `createdAt` 순서로. 201·200 → pending 행을 지우고 두 파일을 `{appCache}/attachments/`로 옮긴다. 로컬 파일이 없으면 → pending 행, 그 보내지 않은 `attachment.added`, 로컬 행을 지운다. 400·409·413(영구 실패) → 같이 지우고 `Couldn't save the receipt on “{description}”: the server refused it`. 403·404 → "거부된 이벤트" 3처럼 `GET /groups/{id}`(그룹에서 빠졌으면 로컬 데이터 삭제, 200이면 아래처럼 멈춤). 401·429·5xx·네트워크 → 이번 라운드의 올리기를 멈춘다(첫 실패에서).
  2. **push**: outbox를 지금처럼 보내되, 아직 pending인 영수증의 `attachment.added`를 만나면 그 **앞까지만** 보낸다(그 뒤 이벤트도 다음 라운드). `ponytail:` 느린 올리기 하나가 그 그룹의 뒤 이벤트를 붙잡는다. 아프면 이벤트별 의존성으로.
  3. **pull**(지금과 같음).
- 보이기: `ReceiptFiles.thumb/full(groupId, attachmentId)` = 캐시 파일, 없으면 pending 파일, 없으면 `ApiClient`로 받아 캐시에 둔다. 오프라인이고 없으면 `Available when online`. 목록 행의 영수증 아이콘은 `watchAttachmentCounts(groupId)`(지출별 삭제 안 된 영수증 수). 지출 화면의 썸네일 줄 → 전체 화면(`InteractiveViewer` 확대, 공유·저장 `share_plus`, Remove는 확인 뒤 모두에게서). `deleteGroupData`·`wipeAll`은 영수증·pending 행과 파일(pending·캐시)을 지운다.
- 스캔: Dart는 `Future<List<OcrLine>> recognizeLines(String imagePath)`, `OcrLine {text, left, top, right, bottom}`(똑바로 세운 사진의 픽셀, 왼쪽 위 원점)만 본다. 스파이크 결과(7단계): ML Kit iOS pod(`MLImage`)이 arm64 시뮬레이터용으로 링크되지 않아 Flutter 플러그인은 쓰지 않고, `MethodChannel('evensies/ocr')` `recognize {path}` 하나를 iOS는 Apple Vision(`VNRecognizeTextRequest`, `AppDelegate.swift`), Android는 ML Kit Latin(`com.google.mlkit:text-recognition`, `MainActivity.kt`)으로 구현한다. 그래서 iOS 배포 대상은 15.0 그대로다. 앱 크기(예산 15 MB 이하, 7단계에 잼): iOS는 시스템 프레임워크라 0. Android는 Latin 모델을 앱에 묶어 ABI 하나(arm64-v8a)에 네이티브 라이브러리 `libmlkit_google_ocr_pipeline.so` 11.1 MB(APK에 압축 없이 저장) + 모델 assets 1.5 MB + 코드 0.9 MB(R8 전 dex) ≈ 설치 크기 13.5 MB, 내려받기(압축) ≈ 6 MB. Play는 AAB를 ABI별로 나눠 주므로 이것이 사용자가 보는 증가분이다. 잰 곳: 디버그 APK(`apkanalyzer dex packages`)와 Gradle 캐시의 AAR(`text-recognition` 16.0.1, `text-recognition-bundled-common` 17.0.0). 릴리스 빌드로는 아직 재지 않았다(R8로 코드 몫만 줄어든다). ABI 셋(armeabi-v7a·arm64-v8a·x86_64)을 다 담은 universal APK(`flutter build apk` 기본)는 ≈ 32 MB 늘어나므로 APK를 따로 배포하면 `--split-per-abi`로. `parseReceipt`(앱 `domain/receipt_parser.dart`, 규칙은 phase-07 설계, 앱 fixture `app/test/fixtures/receipts/*.json`)가 줄·세금·팁·할인·합계·가게 이름(설명)을 채우고 사용자가 고친다. 인쇄된 합계와 다르면 경고(`Receipt says €41.25 · items differ by €0.05`)이지 오류가 아니다. 저장하면 그 사진이 붙는다. 웹(9단계)에서는 Scan을 숨긴다.
- 옮기기(6단계 "지출 옮기기"에 더함): 1단계 전에 원래 지출의 삭제 안 된 영수증마다 파일을(캐시에 없으면 내려받아) 대상 그룹에 **새 id로** 올리고, 1단계의 바로 push에 `expense.created` 뒤 `attachment.added {새 id, 새 expenseId}`들을 함께 넣는다. 다시 시도는 같은 새 id·clientId(올리기는 200). 서버가 404로 답하는 영수증(그 사이 지워짐)은 옮기지 않는다. 원래 영수증은 원래(삭제된) 지출에 남는다(댓글과 같다).
- `docs/privacy.md`: 영수증 사진(누가 보는지, 서버 디스크의 2048px JPEG, 지우면 파일도 삭제)과 ML Kit의 익명 SDK 사용·진단 정보(사진·글자는 보내지 않음). 스토어 라벨과 데이터 보안 양식은 출시 때 효준님.

## 항목별 분할 (7단계, 앱만)
SplitSpec mode `itemized`의 계산(parity #6·#7). 서버는 shares를 다시 계산하지 않으므로(위 "SplitSpec") Kotlin 쌍둥이는 없다. 앱 `domain/itemized.dart`, fixture `app/test/fixtures/itemized-cases.json`.
- `itemizedTotal(bill)` = Σ `lines[].amount` + `tax` + `tip` − `discount`.
- `computeItemizedSplit(bill) → {memberId: 몫}`, 오류는 `SplitException(code)`:
  1. line `amount`·`tax`·`tip`·`discount` 가운데 하나라도 < 0 → `NEGATIVE_AMOUNT`(먼저). `memberIds`가 빈 line → `UNASSIGNED_ITEM`.
  2. `memberIds`가 같은 집합(순서 무관)인 line들의 `amount`를 먼저 더하고, 그 합마다 `computeSplit(amount: 합, mode: equal, members: 그 멤버들)`(나머지는 memberId 오름차순 +1). 그래서 a·b·c가 함께 먹은 1.00 세 줄은 a 1.02가 아니라 셋 다 1.00이다(줄마다 같은 사람이 나머지를 받지 않는다). subtotal[m] = m의 몫 합, S = Σ subtotal(= Σ line amount).
  3. net = tax + tip − discount, total = S + net. total < 0 → `NEGATIVE_TOTAL`. S == 0이고 net ≠ 0 → `ZERO_SUBTOTAL`.
  4. |net|을 나눈다: base[m] = ⌊|net| × subtotal[m] / S⌋(곱은 `BigInt` — 웹에서도 정확), r = |net| − Σ base, subtotal > 0인 멤버 가운데 memberId 오름차순으로 앞의 r명에게 +1(남는 소수가 큰 순서가 아니다).
  5. 몫[m] = net ≥ 0이면 subtotal[m] + extra[m], 아니면 subtotal[m] − extra[m](음수가 되지 않는다).
  6. 결과의 키는 어느 line에든 있는 모든 멤버(0 포함)이고 합은 `itemizedTotal(bill)`. 결정적.
- `percentOf(subtotal, pct)` = `(subtotal × pct / 100).round()`(UI만, .5는 올림). 세금·팁·할인의 % 입력은 금액으로 저장한다(bill에는 금액만 있다).
- 폼: 분할 방식은 `ChoiceChip` 6개(Equal · Exact · % · Shares · ± · Items). Items면 요약(`4 items · Anna €18.40 · Ben €22.80 · Edit`)과 읽기 전용 금액(`itemizedTotal`). 저장은 `split: {"mode": "itemized", "bill": …}`과 `shares`(= `computeItemizedSplit`의 모든 키, 0 포함)·`amount` 등 돈 필드를 함께(3단계 규칙). 다른 방식으로 바꾸면 그 방식의 `split`(exact는 `null`). 열 때는 위 "SplitSpec"의 비교(맞지 않으면 Exact). 항목 화면 `features/itemize/itemize_screen.dart`는 설계대로(줄 이름·금액·멤버 칩과 All, 사람 없는 줄 강조와 Done 막기 + `Give the rest to everyone`, 세금·팁·할인의 금액/% 전환, 사람별 실시간 합계, 이미 줄에 있는 나간 멤버도 이름으로).
- 옮기기(`remapForMove`): `split.bill.lines[].memberIds`를 shares처럼 대상 멤버로 바꾼다. 바꿀 수 없는 id가 하나라도 있으면 `split`을 `null`로(shares가 기준이므로 Exact로 열린다).
- 효준님 `computeSplit`은 `itemized`를 계산하지 않는다(equal만 빌려 쓴다). 줄별 가중치("맥주 3잔 중 2잔")는 없다.

## 7단계 오류 코드
새 코드: `ATTACHMENT_NOT_UPLOADED`(400). 다시 쓰는 코드: `DUPLICATE`(409, 다른 그룹에 저장된 영수증 id — 지금은 `DuplicateKeyException`의 응답), `NOT_JPEG`·`IMAGE_TOO_LARGE`·`VALIDATION`·`UNKNOWN_MEMBER`(400), `FORBIDDEN`(403), `NOT_FOUND`(404), `LIMIT_EXCEEDED`(409), `TOO_LARGE`(413), `RATE_LIMITED`(429). 새 환경 변수는 없다(파일은 `EVENSIES_STORAGE_DIR` 아래).

## 반복 지출 (8단계)
월세·구독·매주 청소처럼 되풀이되는 지출은 **서버**가 더한다. 아무도 앱을 열지 않아도 제때 생긴다. 시리즈는 그룹의 엔티티이고 이벤트로 다닌다(`recurrence.*`, 위 "이벤트 종류와 payload", "반복 지출 검증", 적용 규칙 15·16). 서버가 더하는 반복 하나하나는 보통 `expense.created`이므로 잔액·내보내기·검색·활동은 그대로 동작한다. 친구 그룹(6단계)도 같다. 새 엔드포인트와 새 환경 변수는 없다.

```
RecurrenceDto {"id","frequency": "weekly"|"biweekly"|"monthly"|"yearly","startDate": "YYYY-MM-DD","timeZone": string,"template": {...},"deleted": bool}
```

**template** = 그 시리즈가 만들 `expense.created` payload에서 `expenseId`·`date`·`recurrenceId`·`occurrence`를 뺀 것(받은 JSON 그대로, 서버는 jsonb). 3단계 결제자·환불·분할 힌트(`split`, 7단계 itemized `bill` 포함), 2단계 메모, 4단계 통화·환율, 5단계 카테고리가 마이그레이션 없이 함께 간다. 반복은 template의 `shares`·`payers`를 그대로 쓴다: 서버는 분할을 다시 계산하지 않으므로(3단계 원칙) itemized 지출도 저장된 몫으로 되풀이된다. 영수증은 반복하지 않는다(지출의 필드가 아니라 `attachment.added`다).

**날짜** (서버 `recurrence/Schedule.kt`, 앱 `domain/recurrence.dart`, `shared/recurrence-cases.json`):
- `occurrenceDate(frequency, startDate, n)`: weekly = startDate + 7n일, biweekly = + 14n일, monthly = + n개월, yearly = + n년. 그 달에 없는 날은 그 달의 마지막 날(1/31 → 2/28 → 3/31 → 4/30, 2/29 → 다음 해 2/28). **언제나 startDate에서** 계산한다(이전 날짜에서 계산하면 31일이 28일로 굳는다). n = 0이 startDate(시리즈의 첫 지출). Kotlin은 `plusDays`·`plusMonths`·`plusYears`, Dart는 `DateTime.utc`만 쓰고 달의 마지막 날로 직접 자른다(로컬 시각으로 더하면 DST에서 하루가 밀리고 `DateTime(y, m + 1, 31)`은 다음 달로 넘친다. fixture가 둘 다 잡는다).
- `firstOnOrAfter(frequency, startDate, date, minN = 1) → {n, date}` = n ≥ minN이고 `occurrenceDate(n) ≥ date`인 가장 작은 n(앱 이름 `firstOccurrenceOnOrAfter`). 0은 돌려주지 않는다(minN ≥ 1).
- `dueAt(date, timeZone)`(서버만) = 그 날짜의 **09:00**을 시리즈의 `timeZone`에서 본 UTC 시각: `ZonedDateTime.of(date, LocalTime.of(9, 0), ZoneId.of(timeZone)).toInstant()`(그 시각이 DST 틈에 걸리면 `ZonedDateTime` 규칙대로 뒤로 민다).
- `timeZone`: 앱은 기기의 지금 오프셋 `±HH:MM`(`core/ids.dart` `deviceTimeZone()` = `DateTime.now().timeZoneOffset`, UTC는 `+00:00`, 웹은 브라우저의 오프셋)을 보낸다. IANA 이름은 플러그인 없이 얻을 수 없어서다(새 의존성 없음). 그래서 DST가 바뀌면 올리는 시각만 한 시간 움직이고 날짜는 움직이지 않는다. 서버는 `ZoneId.of`가 받는 것(IANA 이름, `Z`, `±HH:MM` 등)을 모두 받는다. 시리즈마다 만든 사람의 시간대를 가지므로 계정 시간대 설정(parity #96)은 없다.

**서버 저장** — Flyway `V10__recurrences.sql`:
```sql
-- Repeating expenses (Phase 8, docs/API.md "반복 지출").
CREATE TABLE recurrences (
    id              uuid PRIMARY KEY,
    group_id        uuid NOT NULL REFERENCES groups (id),
    frequency       text NOT NULL CHECK (frequency IN ('weekly', 'biweekly', 'monthly', 'yearly')),
    start_date      date NOT NULL,
    time_zone       text NOT NULL,
    template        jsonb NOT NULL,
    created_by      uuid REFERENCES users (id),
    created_at      timestamptz NOT NULL DEFAULT now(),
    deleted_at      timestamptz,
    next_occurrence int NOT NULL,          -- scheduler-owned, never sent to clients
    next_due_at     timestamptz NOT NULL   -- scheduler-owned
);
CREATE INDEX recurrences_group_id ON recurrences (group_id);
CREATE INDEX recurrences_due ON recurrences (next_due_at) WHERE deleted_at IS NULL;
ALTER TABLE expenses
    ADD COLUMN recurrence_id uuid REFERENCES recurrences (id),
    ADD COLUMN occurrence    int CHECK (occurrence >= 0),
    ADD CONSTRAINT expenses_series_pair CHECK ((recurrence_id IS NULL) = (occurrence IS NULL));
```
- `GroupState.recurrences: Map<String, RecurrenceDto>`(`RecurrenceDto(id, frequency, startDate, timeZone, template: JsonNode, deleted)`), `ExpenseDto.recurrenceId: String? = null`·`occurrence: Int? = null`(기본값이 이전 `events.meta`도 읽는다). `SnapshotDto.recurrences`. `load`는 `created_at, id` 순서로 읽는다.
- `GroupStateStore.persist(groupId, actorUserId: UUID?, state, type, payload, createdAt: Instant)`: `recurrence.*`는 적용 뒤 상태의 그 시리즈를 `INSERT … ON CONFLICT (id) DO UPDATE SET template = EXCLUDED.template, deleted_at = CASE WHEN :deleted THEN COALESCE(recurrences.deleted_at, now()) ELSE NULL END WHERE recurrences.group_id = EXCLUDED.group_id`(0행이면 400 `VALIDATION`, 다른 그룹의 id. 상태에 없는 시리즈면 아무것도 안 한다). 지출 upsert는 `recurrence_id`·`occurrence`도 쓴다(같은 push에서 시리즈 행이 먼저 들어가므로 외래 키가 맞다. 정규화가 다른 그룹·없는 시리즈를 뺀다).
- 처음 넣을 때만 스케줄러 칸을 정한다(위 `ON CONFLICT`는 건드리지 않는다): c = 그 `recurrence.created` 이벤트의 `createdAt`(앱 시계)을 [지금 − 30일, 지금]으로 자른 값, `next_occurrence = firstOnOrAfter(frequency, startDate, LocalDate.ofInstant(c, ZoneId.of(timeZone))).n`, `next_due_at = dueAt(occurrenceDate(next_occurrence), timeZone)`. 그래서 오프라인에서 만든 시리즈는 30일 안에 동기화되면 그 사이의 반복을 잃지 않고(이미 지난 `next_due_at`은 다음 tick에 올라간다), 틀린 시계가 반복을 한꺼번에 쏟아 내지 못한다. 만든 날보다 앞선 날짜는 채우지 않는다(startDate가 석 달 전이어도 첫 반복은 만든 날 이후. 앱의 `Next:` 줄이 보여 준다). 만든 날의 09:00이 이미 지났으면 그 반복은 다음 tick에 바로 올라간다.
- 일정(`frequency`·`startDate`·`timeZone`)과 스케줄러 칸은 그 뒤 이벤트로 바뀌지 않는다. 일정을 바꾸려면 앱이 옛 시리즈를 멈추고 새 시리즈를 만든다(아래 "앱"). 멈춘 시리즈는 되살리지 않는다.

**올리기** (`recurrence/RecurrenceScheduler.kt`: `@Scheduled(fixedDelay = 60_000) fun tick() = runDue(Instant.now())`, `@EnableScheduling`은 `EvensiesServerApplication`에. 새 의존성 없음):
1. `SELECT id, group_id FROM recurrences WHERE deleted_at IS NULL AND next_due_at <= :now ORDER BY next_due_at LIMIT 200`.
2. 행마다, 다음 반복이 due인 동안 하나씩(반복 하나 = 트랜잭션 하나):
   1. 잠금 없이 행을 읽어 `n = next_occurrence`, `date = occurrenceDate(n)`. 환율 표 `FxService.rates(date)`를 **그룹 잠금 밖에서** 받는다(출처를 부르면 최대 10초. 4단계 캐시가 있으면 바로 답한다).
   2. 트랜잭션: `groups.lockForUpdate(groupId)` → 행을 다시 읽는다. 멈췄거나 `next_due_at > now`이거나 `next_occurrence ≠ n`(다른 인스턴스가 이미 올림)이면 이 행은 끝.
   3. `oid = UUID.nameUUIDFromBytes(HmacSHA256(key = EVENSIES_JWT_SECRET, "evensies:recurrence:{id}:{n}".toByteArray(UTF_8)))`(id는 소문자 표기, `RecurrenceScheduler.derivedId`)를 clientId와 expenseId로 쓴다. 이벤트 = `expense.created`, payload = template + `{"expenseId": oid, "date": date, "recurrenceId": id, "occurrence": n}`, `createdAt` = 그 행의 `next_due_at`.
   4. **환율 갱신**: D = 그룹 기본 통화, c = template의 `currency`, r = template의 `fxRateToDefault`. c ≠ D이고 r이 0보다 큰 숫자이고 1의 표로 `crossRate(perEur, c, D)`가 있으면 payload의 `fxRateToDefault`를 그 값으로 바꾼다(앱이 새 지출에 채우는 그 날의 자동 환율과 같은 값: `perEur[D] / perEur[c]`를 유효숫자 6자리로, Kotlin `BigDecimal(x).round(MathContext(6, RoundingMode.HALF_UP)).toDouble()` = Dart `double.parse(x.toStringAsPrecision(6))`, `shared/recurrence-cases.json` kind=crossRate). 아니면 template 값 그대로: `null`·`0`(사용자가 고른 "Not converted")은 그대로, 표가 없으면 template의 이전 환율. template 자체는 바꾸지 않는다.
   5. `EventValidator.validateAll(state, actorUserId = null, [event])`(정규화 포함), 그다음 push 핵심(아래 "시스템 actor")으로 저장한다. 이미 있는 clientId면 저장 없이 넘어간다(멱등).
   6. `next_occurrence = n + 1`, `next_due_at = dueAt(occurrenceDate(n + 1), timeZone)`. 커밋.
   7. 커밋한 **뒤**, 새로 저장된 이벤트가 있으면 `PushNotifier.notify(groupId, actorUserId = null, stored)`.
3. 검증이나 저장이 실패하면(버그나 DB 문제(잠금 시간 초과·연결 끊김)로만 가능: template은 저장할 때 지출로 검사했다) 그 트랜잭션은 롤백하고 WARN 로그, 새 트랜잭션에서 `UPDATE recurrences SET next_due_at = now + 1시간 WHERE id = :id AND next_occurrence = :n`(1에서 읽은 n)만 한다. 그 반복은 미뤄지고 다른 시리즈는 계속된다. 그사이 다른 인스턴스가 n을 올렸으면 0행이라 그 인스턴스가 정한 다음 due를 덮지 않는다.
- 안전: 그룹 잠금을 먼저 잡고 행을 다시 읽으므로 동시에 온 멈춤·수정(같은 잠금을 잡는 push)을 언제나 본다. 크래시·재시도·두 번째 인스턴스는 같은 파생 clientId로 `UNIQUE(group_id, client_id)`에 막힌다. 서버가 멈춰 있던 동안의 반복은 다음 tick에 순서대로 모두 올린다(30일 자르기는 시리즈를 처음 넣을 때만).
- 파생 id는 서버만 만든다. 앱은 0보다 큰 `occurrence`를 보낼 수 없으므로 두 오프라인 폰이 같은 반복을 만들 수 없다. 서버 비밀로 키를 걸므로 시리즈 id를 아는 사람(옛 멤버 포함)도 다음 반복의 id를 알 수 없다: 키가 없으면 미리 그 id로 다른 그룹에 지출을 넣거나(지출 id는 전역 PK라 반복이 400으로 영원히 미뤄진다) 그 clientId로 이벤트를 넣어(반복이 조용히 건너뛰어진다) 시리즈를 멈출 수 있다. 한 번만 올리기는 그룹 잠금·행 다시 읽기·같은 트랜잭션의 advance가 보장하고 파생 id는 뒷받침일 뿐이므로, 비밀을 바꿔도 문제없다.
- `ponytail:` 반복마다 `stateStore.load` 한 번. 따라잡을 반복이 많아지면 그룹별로 묶는다.
- 테스트는 2031년 이후 날짜를 써서 실제 tick이 건드리지 않게 하고 `runDue(Instant)`를 직접 부른다(실제 tick이 먼저 올려도 결과는 같다: 반복마다 이벤트 하나).

**시스템 actor**: 스케줄러의 이벤트에는 사용자가 없다(`null` = Evensies). `EventService`의 push 핵심, `GroupStateStore.persist`, `EventValidator.validateAll`, `Activity.meta`, `PushNotifier.notify`가 `null` 사용자를 받는다. 저장된 이벤트는 `actor_user_id NULL`(pull `"actorUserId": null`), 지출 행은 `created_by NULL`. 멤버 검사와 사용자당 속도 제한(분당 120)은 건너뛴다. pull되는 `createdAt`은 `dueAt`이고, 활동의 `createdAt`(`received_at`)은 실제로 저장한 시각이다. 활동은 `expense_repeated`(위 "피드"), 푸시는 모든 연결 멤버(위 "푸시").

**하루 정리** (`storage/Sweep.kt`, `@Scheduled(cron = "0 30 3 * * *")`, 서버 시계. 7단계의 남은 일):
1. `DELETE FROM attachments WHERE expense_id IS NULL AND created_at < now() - interval '7 days' RETURNING id, group_id`: 7일 동안 어느 지출에도 붙지 않은 올리기(거부된 `attachment.added`, 올린 뒤 앱이 사라짐). 지운 행마다 두 파일(`AttachmentController.keys`)을 지운다. 행을 먼저 지우므로 그 사이에 붙을 수 없다(붙은 행은 조건에서 빠진다). 7일인 이유: 올리기와 그 `attachment.added` push 사이에 연결이 끊긴 폰이 며칠 오프라인이어도 영수증을 잃지 않게(그 뒤의 `attachment.added`는 400 `ATTACHMENT_NOT_UPLOADED`).
2. `deleted_at`이 있는 행의 두 파일을 지운다(커밋과 파일 삭제 사이의 크래시로 남은 것. 없는 파일은 아무것도 안 한다). `ponytail:` 삭제된 행 전부를 매일 본다. 수십만 행이 되면 최근 7일로 좁힌다.
- 파일 삭제가 실패하면 WARN 로그만 남긴다(2는 다음 날 다시 본다. 1의 파일은 고아로 남는다 — `ponytail:` 문제가 되면 디렉터리를 훑는다). 10단계가 같은 정리에 표지 파일을 더한다.

**상한**: 그룹당 멈추지 않은 시리즈 100(abuse cap, 409 `LIMIT_EXCEEDED`). 그 밖에는 무료·무제한이다.

**앱**
- 모델(`domain/models.dart`): `Recurrence {id, frequency, startDate, timeZone, Map<String, dynamic> template, deleted}`와 JSON. `Expense.recurrenceId`·`occurrence`(null 허용, `copyWith`에 `clearRecurrence`). `GroupState.recurrences`(기본 `[]`)와 `recurrence(id)`. `GroupState.fromJson`(snapshot·sync-cases `expected`)은 없는 `recurrences`를 `[]`로 읽는다.
- 적용기: `EventTypes`에 세 type, `applyEvent`에 규칙 15·16.
- drift schemaVersion **9**: `Recurrences` 표(`id` PK, `groupId`, `frequency`, `startDate`, `timeZone`, `templateJson`, `deleted` 기본 `false`. 순서 = rowid), `Expenses.recurrenceId`(text null)·`Expenses.occurrence`(int null). `onUpgrade`(`from < 9`)는 표·칸을 더하고 lastSeq를 0으로 되돌린다(위 "호환(8단계)"). `GroupStateStore`·`adoptFromSnapshot`·`deleteGroupData`가 시리즈를 다룬다. `unsentOutbox`는 이미 `createdAt` 다음 `rowid` 순서다(7단계): 같은 트랜잭션의 `recurrence.created`가 언제나 그 지출보다 먼저 간다(뒤집히면 정규화가 시리즈 표시를 뺀다).
- `expenseCreatedPayload(e)`는 언제나 `recurrenceId`·`occurrence`를 넣는다(없으면 둘 다 `null`). `templateOf(e)` = 그 payload에서 `expenseId`·`date`·`recurrenceId`·`occurrence`를 뺀 것.
- 로컬 쓰기(`local_writes.dart`, 각각 한 로컬 트랜잭션 + outbox):
  - `createExpense(groupId, e, {String? repeat})`: `repeat`이 있으면 시리즈 행(새 id, `startDate = e.date`, `timeZone = deviceTimeZone()`, `template = templateOf(e)`)과 `recurrenceId`·`occurrence: 0`인 지출. outbox는 `recurrence.created` 다음 `expense.created`.
  - `updateRecurrence(groupId, id, fields)`: 로컬 template에 키 단위로 합치고 `recurrence.updated`.
  - `stopRecurrence(groupId, id)`: 로컬 `deleted = true`, `recurrence.deleted`.
  - `repeatFrom(groupId, e, frequency, {String? stop})`: `stop`이 있으면 그 시리즈의 `recurrence.deleted`, 그다음 새 `recurrence.created`(`startDate = e.date`, `template = templateOf(e)`), 그다음 `expense.updated {…바뀐 필드, "recurrenceId": 새 id, "occurrence": 0}`.
- 용어: 시리즈의 **마지막 반복** = 그 `recurrenceId`의 삭제 안 된 지출 가운데 `occurrence`가 가장 큰 것. `lastPosted` = 그 시리즈 지출(삭제된 것 포함)의 `occurrence` 최댓값. **활성 시리즈** = 상태에 있고 `deleted`가 아닌 시리즈.
- 지출 폼: 날짜 옆 **Repeat** 드롭다운 Never / Every week / Every 2 weeks / Every month / Every year(= `weekly`·`biweekly`·`monthly`·`yearly`). Never가 아니면 `Next: Sun, 1 Nov 2026`(`DateFormat('EEE, d MMM yyyy')`, `firstOccurrenceOnOrAfter(frequency, startDate, todayIso(), minN: lastPosted + 1)`. 새 지출은 startDate = 폼의 날짜, lastPosted = 0). 저장한 지출이 시리즈의 첫 번째(`occurrence: 0`).
  - 활성 시리즈의 마지막 반복: **Also change future repeats** 체크 상자(기본 체크). 저장하면:
    - Repeat → Never: `stopRecurrence` + (바뀐 필드가 있으면) `updateExpense`.
    - Repeat가 바뀜(체크 상자와 상관없이. 그동안 체크 상자는 숨는다), 또는 체크했고 날짜가 바뀜: `repeatFrom(…, stop: 옛 id)`(일정을 이 지출부터 다시 시작). 체크 상자는 Repeat가 그대로일 때 날짜와 필드를 앞으로 가져갈지만 정한다.
    - 체크, 그 밖: `updateExpense` + `updateRecurrence(같은 바뀐 필드에서 date를 뺀 것)`(남는 것이 없으면 보내지 않는다).
    - 체크 안 함: `updateExpense`만.
  - 활성 시리즈의 마지막이 아닌 반복: Repeat는 꺼진 채 `To change future repeats, edit the latest one (1 Oct)`(`d MMM`, 마지막 반복의 날짜).
  - 시리즈가 없거나 멈춘 시리즈의 지출: Repeat는 Never에서 시작하고, 고르면 저장할 때 `repeatFrom(…)`(stop 없음, 새 시리즈).
  - 활성 시리즈 지출의 Delete: Cancel / Delete this one / **Delete and stop repeating**(`expense.deleted` + `recurrence.deleted`, 한 트랜잭션).
- Expenses 탭: 활성 시리즈의 지출에 `Icons.repeat`.
- 지출 상세: 활성 시리즈의 지출은 날짜 줄 끝에 `Repeats monthly`(빈도 단어는 활동과 같다). 마지막 반복이면 `· next Sun, 1 Nov 2026`(위 `Next:`와 같은 계산), template의 금액·통화가 이 지출과 다르면 `· next €1,300.00 on Sun, 1 Nov 2026`.
- Members 화면: 활성 시리즈의 template(`payers`나 `shares`에 0보다 큰 금액)에 있는 멤버를 빼려 하면 한 줄을 더한다: `Ben is still in 2 repeating expenses (Rent, Netflix); they keep Ben's share until you edit the latest one.`(이름은 시리즈를 만든 순서로 최대 3개, 그 뒤는 `and N more`. removed 멤버도 멤버라 서버는 그대로 받고 반복은 그 몫으로 생긴다).
- 옮기기(6단계): `remapForMove`는 `recurrenceId`·`occurrence`를 버린다(대상의 새 지출은 시리즈 없음). 시리즈는 원래 그룹에 남는다.
- 오프라인: 만들기·고치기·멈추기는 오프라인에서도 된다. 첫 번째 뒤의 반복은 서버만 만든다(동기화하면 pull로 온다).

**일부러 뺀 것**: 만들 때 지난 날짜 채우기(`Next:` 줄이 첫 반복을 보여 준다), 사용자 정의 간격·끝나는 날·평일만(Splitwise에도 없다), "Repeating expenses" 목록 화면, 오프라인 멈춤이 닿기 전에 올라간 반복 지우기(기기 시계를 믿어야 한다), 두 사람이 모두 오프라인에서 한 시리즈의 일정을 바꾸면 시리즈가 둘이 된다(클라이언트가 만든 파생 id는 로컬 사본을 서버와 어긋나게 한다). 반복 전 이메일 알림(`remindDaysBefore`)은 10단계가 이 스케줄러 위에 더한다.

## 8단계 오류 코드
새 코드는 없다. 다시 쓰는 코드: `VALIDATION`(400), `LIMIT_EXCEEDED`(409, 그룹당 시리즈 100), template 검사의 지출 코드(`SUM_MISMATCH`·`PAYERS_SUM_MISMATCH`·`NEGATIVE_AMOUNT`·`UNKNOWN_MEMBER`·`UNKNOWN_CURRENCY`, 400). 이전 서버는 `recurrence.*`에 `UNKNOWN_TYPE`(400). 새 환경 변수는 없다.

## 내보내기·가져오기
- `GET /groups/{id}/export?format=json` → snapshot과 같은 JSON(`payers`·`refund`·`split`·`simplifyDebts`·`defaultSplit` 포함). `format=csv` → 지출 CSV (`date,description,category,amount,currency,fxRateToDefault,paidBy,<멤버이름별 share>...`). `category` 칸(5단계)은 key면 그 영어 label(`Categories.label`, 예 `Dining out`, `*.other`는 `Entertainment - Other`), `null`이거나 공백뿐이면 `General`, 그 밖(이전 자유 입력)은 원문 그대로다. `fxRateToDefault` 칸(4단계)은 저장된 값을 지수 표기와 끝의 0 없는 십진수로(`BigDecimal.valueOf(r).stripTrailingZeros().toPlainString()`: `0.00616`, `0.0000007`, `1.0` → `1`, `0` → `0`) 쓰고, `null`이면 빈 칸이다(0이나 D 지출의 남은 값도 저장된 그대로). 금액은 지금처럼 지출 통화 그대로다(환산하지 않음). `paidBy` 칸은 결제자가 한 명이면 그 이름, 여럿이면 `Anna 60.00; Ben 40.00`(`payers` 순서, 주 단위 금액). 환불 행은 `amount`와 share 칸이 음수(`-60.00`)이고 `paidBy` 칸의 금액은 양수 그대로다. 글자 칸(멤버 이름 머리글, `description`, `category`, `paidBy`)이 `=`·`+`·`-`·`@`·탭·CR로 시작하면 앞에 `'`를 붙인다(스프레드시트 수식 실행 방지, CSV injection). 금액 칸은 그대로다.
- `GET /groups/{id}/export?format=zip`(7단계, Settings → Export의 `ZIP with receipts`) → 200 `application/zip`, `Content-Disposition: attachment; filename="evensies-{id}.zip"`. 항목: `group.json`(= `format=json`의 본문, `attachments` 포함)과 삭제 안 된 영수증마다 `receipts/{attachmentId}.jpg`(큰 사진. 붙은 지출이 삭제됐어도 넣는다. 파일이 없으면 건너뛴다). 요청 스레드에서 응답 스트림에 바로 쓰는 `ZipOutputStream`이고(`StreamingResponseBody`의 비동기 디스패치는 상태 없는 JWT 필터가 다시 인증하지 않아 403으로 끊긴다) 멤버 검사(404·403)는 쓰기 전에 해서 보통 오류 본문으로 답한다. `format`이 `json`·`csv`·`zip`이 아니면 400 `VALIDATION`. CSV와 JSON은 바뀌지 않는다(JSON에 `attachments`·`replaced`가 더해질 뿐). 8단계: JSON(그래서 ZIP의 `group.json`도)에 `recurrences`와 지출의 `recurrenceId`·`occurrence`가 더해진다(= snapshot). CSV는 그대로다(반복도 보통 지출 행).
- `POST /groups/{id}/import/splitwise` multipart `file` (Splitwise CSV: `Date,Description,Category,Cost,Currency,<이름>...`). 서버가 이름을 그룹 멤버와 매칭(없으면 자리표시 멤버 생성)하고 `expense.created` 이벤트로 변환. 응답 `{"imported": n, "latestSeq"}`.
  - 이름 칸은 그 행에서 그 사람의 순액(낸 돈 − 부담)이다. 순액이 양수인 사람은 모두 그 순액만큼 낸다. 순액이 가장 큰 사람(같으면 memberId가 가장 작은 사람)은 남는 금액 `s = Cost − Σ 양수 순액`도 내고 `Cost − Σ 다른 사람들의 부담`을 부담한다(순액의 합이 0이면 `s`와 같고, 합이 0이 아닌 행도 몫의 합이 Cost가 된다). 순액이 음수인 사람은 `−순액`을 부담한다. `s < 0`이거나 그 부담이 음수면 400 `IMPORT_FAILED`. 0인 결제자·몫은 넣지 않는다. 결제자가 둘 이상이면 `payers`를 넣는다(`paidBy`는 주요 결제자). 예: Cost 100.00, Anna +26.66, Ben +6.67, Cara −33.33 → payers Anna 93.33·Ben 6.67, shares Cara 33.33·Anna 66.67. 양수 순액이 하나인 행은 지금과 같게 들어온다. Cost가 음수인 환불 행은 아직 가져오지 않는다.
  - `Category` 칸(5단계): trim한 값의 `Categories.keyForLabel`(아래 "카테고리")이 있으면 그 key, 없으면 trim한 원문(빈 칸·칸 없음은 `null`). `Dining out` → `food.dining_out`, `General` → `uncategorized.general`, `Entertainment - Other` → `entertainment.other`, `Other`·`Food` → 원문 그대로.
  - Payment 행(5단계): `Category`가 대소문자 무시하고 `Payment`이고 Cost > 0이며, 순액이 0이 아닌 사람이 정확히 둘이고 그 순액이 +Cost와 −Cost이면 지출 대신 `payment.created {"paymentId": 새 UUID, "fromMember": 순액이 +Cost인 멤버, "toMember": 순액이 −Cost인 멤버, "amount": Cost, "currency": 그 행의 Currency, "date": 그 행의 Date, "status": "confirmed"}`를 만든다(잔액 효과는 같은 행을 지출로 가져올 때와 같다). 이 조건에 맞지 않는 Payment 행은 지금처럼 지출로 가져온다(category는 원문 `Payment`).
  - 응답의 `imported` = 만든 지출 수 + 송금 수(5단계). 멤버 이벤트는 세지 않는다. 응답 모양은 그대로다.

## 활동·알림
변경 기록(이벤트 로그)에서 만든 **활동 피드**, 다른 사람의 변경을 알려 주는 **표시 푸시**, 알림 설정. 피드 항목은 구조화된 데이터이고 문장은 앱(목록)과 서버(푸시)가 같은 규칙으로 만든다(아래 "문장", `shared/activity-cases.json`으로 양쪽 검증).

### 피드
| 메서드 | 경로 | 요청 | 응답 |
|---|---|---|---|
| GET | `/groups/{id}/activity?before=<seq>&limit=50&expenseId=<uuid>` | `expenseId` 선택(5단계) | `ActivityPage` — seq 큰 순. 호출자는 멤버여야 함(403), 그룹 없음 404 |
| GET | `/activity?before=<feedId>&limit=50` | | `ActivityPage` — 호출자가 지금(removed 아님) 멤버인 모든 그룹, feedId 큰 순 |

```
ActivityPage {"items": [ActivityItem], "nextBefore": number|null}
ActivityItem {"groupId","feedId","seq","kind","createdAt","actorMemberId",
              "memberId","expenseId","commentId","paymentId",
              "name","description","amount","currency","fromMember","toMember","status","myDelta","refund","text",
              "recurrenceId","frequency",
              "changes": [{"field","from","to"}]}
```
- `expenseId`(5단계, 지출의 편집 기록): payload의 `expenseId` 문자열이 그 값과 같은 이벤트만 본다(`expense.*`, `comment.added`, 7단계 `attachment.*` — `attachment.deleted`는 서버가 정규화해 넣은 `expenseId`, 위 "이벤트 종류와 payload"). UUID가 아니면 400 `VALIDATION`. 빈 값(`expenseId=`)은 없는 것으로 본다(필터 없음, `limit` 등과 같은 방식). 비교는 문자열 그대로이고 파라미터는 소문자 표기로 바꿔 비교한다(앱은 id를 소문자로 만든다). 그룹에 없는 지출(아직 push되지 않은 것 포함)이면 404가 아니라 빈 페이지 `{"items": [], "nextBefore": null}`. `before`·`limit`·`nextBefore`·숨김 규칙은 그대로이고 `limit`은 걸러진 이벤트 수로 센다(SQL `AND payload->>'expenseId' = :expenseId`). `GET /activity`(전체 피드)에는 없다(보내도 무시). `ponytail:` 그룹 이벤트를 훑는다. 한 그룹이 5만 이벤트쯤 넘으면 `(group_id, (payload->>'expenseId'))` 식 인덱스를 더한다.
- 앱의 History(지출 상세): `limit=20`, "Show more"는 `before=nextBefore`. 받은 항목은 활동 캐시(drift `Activity`)에도 넣는다. 오프라인·오류면 캐시에서 그 그룹의 `json_extract(json, '$.expenseId') = ?`인 행을 feedId 내림차순으로 보여 준다. 받은 항목도 `expenseId`가 같은 것만 보여 준다(이전 서버는 필터를 무시한다). 문장은 활동 목록과 같다(아래 "문장").
- `before` 생략 = 최신부터. 그룹 피드는 `seq < before`, 전체 피드는 `feedId < before`. `limit`은 1~100으로 잘라 맞추고 기본 50. 숫자가 아니면 400 `VALIDATION`.
- 숨김 이벤트 때문에 `items`가 `limit`보다 적거나 비어 있어도 끝이 아닐 수 있다. **`nextBefore`가 null일 때만 끝**이고, 아니면 그 값을 다음 요청의 `before`로 넘긴다.
- `feedId`: 서버가 이벤트를 저장한 순서의 전역 번호(그룹 안에서는 seq와 같은 순서). 앱은 오프라인용 캐시를 이 순서로 정렬한다.
- 모든 키는 항상 있다. 해당 없는 필드는 `null`, `changes`는 `[]`.
- `createdAt`은 **서버가 이벤트를 저장한 시각**(`events.received_at`)이다. 이벤트의 createdAt(앱 시계)은 오프라인 수정을 나중에 올리거나 기기 시계가 틀리면 목록 순서(seq·feedId)와 어긋나므로 쓰지 않는다. 이 기능 전에 저장된 이벤트는 그 이벤트의 createdAt. 앱은 이 값으로 시각과 날짜 머리글을 그린다(목록 순서와 같은 순서). `seq`는 그룹 안 이벤트 번호(탭하면 `expenseId`의 지출을 연다).

| kind | 원본 이벤트 | 채워지는 필드 |
|---|---|---|
| `group_created` | `group.created` | `name`(그룹 이름) |
| `group_updated` | `group.updated` | `changes`(`name`, `defaultCurrency`, `simplifyDebts`, `defaultSplit`) |
| `member_added` | 보통 그룹의 `member.added`(payload `userId`가 보낸 사람이 아님 — 자리표시 추가) | `memberId` |
| `member_joined` | `member.added`(payload `userId` = 보낸 사람, 초대로 새 멤버), `member.linked` | `memberId` |
| `member_removed` | `member.removed`(빠지는 멤버가 보낸 사용자의 멤버가 아님) | `memberId` |
| `member_left` | `member.removed`(직전 상태에서 `members[memberId].userId == actorUserId` — 그룹 나가기). 이때 `actorMemberId`는 언제나 그 `memberId`다(나갔다 다시 들어와 또 나간 사용자의 이전 멤버가 아님) | `memberId` |
| `friend_added` | 친구 그룹(6단계)의 `member.added`(seq 2 제외 — 친구 그룹에서는 seq 3 하나뿐, 상대가 연결 사용자든 자리표시든) | `memberId` |
| `expense_added` | `expense.created`(아래 `expense_repeated`가 아닌 것) | `expenseId`, `description`, `amount`, `currency`, `myDelta`, `refund`(환불이면 `true`, 아니면 `null`) |
| `expense_repeated` | `actorUserId`가 null이고 payload `recurrenceId`가 문자열인 `expense.created`(8단계, 서버 스케줄러가 올린 반복) | `expense_added`와 같음 + `frequency`. `actorMemberId`는 언제나 `null` |
| `expense_updated` | `expense.updated` | 위와 같음 + `changes` |
| `expense_deleted` | `expense.deleted`(`movedTo` 없음·`null`) | `expenseId`, `description`, `amount`, `currency`, `myDelta` |
| `expense_restored` | `expense.restored` | `expenseId`, `description`, `amount`, `currency`, `myDelta` |
| `expense_moved` | `movedTo`가 객체인 `expense.deleted`(6단계, "지출 옮기기") | `expense_deleted`와 같음 |
| `comment_added` | `comment.added` | 지출 댓글: `expenseId`, `commentId`, `description`(그 지출의), `text`(댓글). 송금 댓글(6단계, payload에 `paymentId`): `paymentId`, `commentId`, `fromMember`, `toMember`, `amount`, `currency`(댓글 시점의 송금 값), `text`. `expenseId`·`description`·`status`는 `null` |
| `payment_added` | `payment.created` | `paymentId`, `fromMember`, `toMember`, `amount`, `currency`, `status` |
| `payment_confirmed` | `payment.confirmed` | 위와 같음 |
| `payment_deleted` | `payment.deleted`(`replacedBy` 없음·`null`) | 위와 같음 |
| `payment_edited` | `replacedBy`가 문자열인 `payment.deleted`(7단계, 송금 편집. 이전 송금의 값) | 위와 같음 |
| `payment_restored` | `payment.restored`(7단계) | 위와 같음 |
| `receipt_added` | `attachment.added`(7단계) | `expenseId`, `description`(그 영수증이 붙은 지출의 직후 값) |
| `receipt_removed` | `attachment.deleted`(7단계) | 위와 같음 |
| `recurrence_created` | `recurrence.created`(8단계) | `recurrenceId`, `frequency`, `description`·`amount`·`currency`(적용 직후 template의 값) |
| `recurrence_updated` | `recurrence.updated`(8단계) | 위와 같음 + `changes` |
| `recurrence_deleted` | `recurrence.deleted`(8단계) | 위와 같음(멈출 때의 template) |

- `recurrenceId`(8단계): `recurrence_*`는 그 시리즈, `expense_*`(`expense_repeated` 포함)는 적용 직후 지출의 `recurrenceId`(없으면 `null`. 묶음 규칙이 쓴다). `frequency`는 `expense_repeated`와 `recurrence_*`만(그 시리즈의 값), 그 밖은 `null`.

값을 정하는 규칙:
- `actorMemberId`: 이벤트의 `actorUserId`에 연결된 멤버. 이벤트 적용 **직후** 상태에서 찾고, 없으면 같은 push 배치를 모두 적용한 상태에서 찾는다(그래서 seq 1 `group.created`의 actor는 seq 2에서 추가된 만든 사람). 그래도 없으면 `null`.
- 지출 필드(`description`, `amount`, `currency`)는 이벤트 적용 직후의 그 지출 값(`expense_deleted`는 삭제 직전과 같은 값). `receipt_*`(7단계)는 그 영수증이 붙은 지출(적용 직후 상태의 `attachments[attachmentId].expenseId`)의 `expenseId`·`description`만 채운다. `comment_added`의 `description`도 댓글이 달린 시점의 지출 설명이다. 송금 필드도 적용 직후의 송금 값(`status` 포함).
- `myDelta`(지출 kind, 8단계 `expense_repeated` 포함. `recurrence_*`는 `null`): 보는 사람(호출자의 그 그룹 멤버)에게 이 지출이 주는 잔액 변화, 적용 직후 값으로 `sign × ((payers의 내 금액, 없으면 0) − (내 share, 없으면 0))`, `sign = refund ? −1 : +1`, `currency`의 최소 단위. 내가 `payers`에도 `shares`에도 없으면 `null`.
- `changes`(`expense_updated`): 직전 값과 직후 값이 다른 필드 전부(규칙 10 때문에 `fields`에 없는 `payers`·`paidBy`·`split`도 바뀔 수 있다), 단 결제자는 하나만: 직전·직후 모두 결제자가 한 명이면 `payers`는 넣지 않고(`amount`·`paidBy` 수정을 따라 바뀐 것), 어느 한쪽이라도 여럿이면 `paidBy`를 넣지 않는다(`payers`에서 정해진 주요 결제자라 동점이나 작은 금액 수정으로도 뒤집힌다). 순서 `description, amount, currency, fxRateToDefault, paidBy, payers, refund, date, category, shares, split, notes`. `from`/`to`는 직전/직후 값이고 `payers`·`shares`·`split`·`notes`는 둘 다 `null`(목록에는 이름으로만 나온다), `refund`는 boolean. `recurrence_updated`(8단계)는 직전·직후 template을 각각 지출로 읽은 값(`expense.created`처럼 적용, id·date는 아무것이나 같게)으로 `expense_updated`와 같은 규칙·순서·`from`/`to`로 만든다(template에 `date`는 없다). `group_updated`는 `name, defaultCurrency, simplifyDebts, defaultSplit` 순서이고 `simplifyDebts`는 boolean, `defaultSplit`은 둘 다 `null`. 규칙 12로 무시된 `defaultCurrency`는 바뀐 것이 아니다.
- 숨김(항목을 만들지 않고 푸시도 없음):
  1. 적용기가 상태를 바꾸지 않은 이벤트 — 이미 있는 id의 `created`·`added`, 삭제된 지출의 `updated`, 같은 값으로의 `updated`, 삭제 안 된 지출이나 옮긴 지출(규칙 13)의 `restored`, 없거나 삭제된 송금의 `confirmed` 등. 7단계: 이미 있는 id나 없는 지출의 `attachment.added`, 없거나 이미 삭제된 영수증의 `attachment.deleted`, 삭제 안 된·없는·편집으로 바뀐(`replaced`) 송금의 `payment.restored`. 8단계: 이미 있는 id의 `recurrence.created`, 없거나 멈춘 시리즈의 `recurrence.updated`·`recurrence.deleted`.
  2. seq 2의 `member.added`(POST /groups·POST /friends가 만든 사람 자신을 넣는 이벤트. `group_created`와 겹친다).
  3. `comment.deleted`.
  4. 모르는 type.
  5. 댓글이 **지금** 삭제되어 있는 `comment_added`(삭제하면 글이 피드와 아직 묶여 있던 푸시에서 빠진다. 같은 push에서 쓰고 지운 댓글은 알리지 않는다). 이것만 현재 상태를 보므로 `shared/activity-cases.json`(이벤트 시점 규칙)에는 없고 서버 테스트가 검증한다.
  6. 친구 그룹의 seq 1 `group.created`(6단계. seq 2는 2로 이미 숨김). 서버는 이벤트 적용 직후 상태의 `kind == "friend"`를 `EventMeta.friend`(이전 meta는 `false` — 친구 그룹은 6단계부터 있다)에 기록하고 6과 `friend_added`를 그것으로 정한다. 그래서 검증기·`Activity.meta`·푸시 제목이 모두 `state.kind`(= `groups.kind`) 하나를 본다.
  7. `changes`가 빈 `expense_updated`·`recurrence_updated`(8단계: 시리즈 표시 `recurrenceId`·`occurrence`만 바뀐 수정 — 일정을 바꿀 때 지출을 새 시리즈에 다시 붙이는 것. `changes`는 표시를 보지 않는다. template의 지출 필드가 아닌 키만 바뀐 `recurrence.updated`도).
- 서버는 push 트랜잭션 안에서 이벤트마다 직전·직후 상태를 알고 있으므로 피드에 필요한 값(actorMemberId, 대상 지출·송금의 직전·직후 값, 상태 변화 여부)을 이벤트 행의 `meta`(서버 내부, pull에 없음)에 기록하고 피드는 그것만 읽는다. 이 기능 이전에 저장된 이벤트는 서버가 시작할 때 그룹 로그를 seq 1부터 다시 적용해 `meta`를 채운다.

### 문장 (영어, 앱 목록·서버 푸시 공통)
보는 사람을 `me`(그 그룹의 내 멤버)로 두고 만든다. 9단계(언어)에서 번역할 때까지 영어 한 가지.
- 이름: `me`이면 문장 맨 앞 `You`, 그 밖 `you`. id가 `null`이거나 이름을 모르면 `Someone`/`someone`. 그 밖에는 멤버 이름 그대로.
- 금액 표기: `shared/currencies.json`의 `symbols[통화]` + 정수부 3자리마다 `,` + (소수 자릿수가 0이 아니면) `.`과 소수부(자릿수만큼 0 채움). 기호와 숫자 사이 공백 없음: `€30.00`, `₩15,000`, `CHF12.50`, `din1,234.567`. 앱의 `formatMoney`(intl en_US)와 같은 결과다. `symbols`에 없는 통화(4단계의 새 통화)는 ISO 코드가 기호 자리에 온다: `ZAR1,234.56`, `OMR1,234.567`, `XOF1,500`(앱 `formatMoney`도 intl의 기호 대신 코드를 쓴다. 9단계가 최종 표기를 정한다). 음수는 쓰지 않는다(`myDelta`는 절댓값).
- 따옴표는 `“ ”`(U+201C/U+201D), 구분점은 ` · `(U+00B7 앞뒤 공백), 화살표는 ` → `(U+2192 앞뒤 공백). `{A}` = actor 이름(문장 맨 앞 규칙), `{M(x)}` = 금액 표기.

| kind | 문장 |
|---|---|
| `group_created` | `{A} created the group “{name}”` |
| `group_updated` | `{A} changed the group: {변경들}` — `name “{from}” → “{to}”`, `currency {from} → {to}`, `simplify debts on`/`simplify debts off`(`to` 값), `default split`을 `, `로 잇는다 |
| `member_added` | `{A} added {member}` |
| `member_joined` | `{member} joined` (member가 맨 앞) |
| `member_removed` | `{A} removed {member}` |
| `member_left` | `{member} left the group` (member가 맨 앞) |
| `expense_added` | `{A} added “{description}” · {M(amount)}` + `myDelta < 0`이면 ` · you owe {M(−myDelta)}`, `> 0`이면 ` · you lent {M(myDelta)}`, 0·null이면 없음. `refund`면 `{A} added a refund “{description}” · {M(amount)}`이고 `> 0`은 ` · you get back {M(myDelta)}` |
| `expense_updated` | `{A} changed “{description}”: {변경들}` (아래, `, `로 잇는다) |
| `expense_deleted` | `{A} deleted “{description}”` |
| `expense_restored` | `{A} restored “{description}”` |
| `expense_moved` | `{A} moved “{description}” to another group` (대상 이름은 쓰지 않는다: 보는 사람이 대상 그룹에 없을 수 있다) |
| `comment_added` | `{A} commented on “{description}”: {text}`. 송금 댓글(`paymentId`가 있음): `{A} commented on a payment of {M(amount)} from {from} to {to}: {text}` |
| `friend_added` | `{A} added {member} as a friend` (`You added Ben as a friend`, `Anna added you as a friend`) |
| `payment_added` | `{from} paid {to} {M(amount)}` (from이 맨 앞) + `status`가 `sent`면 ` · waiting for {to} to confirm` |
| `payment_confirmed` | `{A} confirmed receiving {M(amount)} from {from}` |
| `payment_deleted` | `{A} deleted a payment of {M(amount)} from {from} to {to}` |
| `payment_edited` | `{A} edited a payment of {M(amount)} from {from} to {to}` (7단계. 새 송금은 따로 `payment_added`) |
| `payment_restored` | `{A} restored a payment of {M(amount)} from {from} to {to}` (7단계) |
| `receipt_added` | `{A} added a receipt to “{description}”` (7단계) |
| `receipt_removed` | `{A} removed a receipt from “{description}”` (7단계) |
| `expense_repeated` | `“{description}” · {M(amount)} was added (repeats {frequency})` + `expense_added`와 같은 꼬리(` · you owe …`/` · you lent …`). `refund`면 `A refund “{description}” · {M(amount)} was added (repeats {frequency})`이고 `> 0`은 ` · you get back …` (8단계, actor는 쓰지 않는다) |
| `recurrence_created` | `{A} set “{description}” to repeat {frequency}` (8단계) |
| `recurrence_updated` | `{A} changed future “{description}”: {변경들}` (8단계, 변경 표기는 `expense_updated`와 같다) |
| `recurrence_deleted` | `{A} stopped “{description}” repeating` (8단계) |

`{frequency}`(8단계): `weekly` → `weekly`, `biweekly` → `every 2 weeks`, `monthly` → `monthly`, `yearly` → `yearly`(9단계가 번역한다).

`expense_updated`의 변경 표기: `description` → `description “{from}” → “{to}”` · `amount` → `{M(from)} → {M(to)}`(from은 `currency` 변경이 있으면 그 `from` 통화로, 없으면 `currency`로 표기) · `currency` → `currency {from} → {to}` · `fxRateToDefault` → `exchange rate` · `paidBy` → `paid by {from 이름} → {to 이름}` · `payers` → `payers` · `refund` → `refund on`/`refund off`(`to` 값) · `date` → `date {from} → {to}`(YYYY-MM-DD 그대로) · `category` → `category {from 이름} → {to 이름}`(이름은 앱이 그 저장 값을 보여 주는 이름(`labelOf`): `categories[]` key·한 번만 나오는 label이면 그 label, `*.other`는 `{부모 label} - Other`, `null`·legacy는 `General`. 서버는 `Categories.label(Categories.keyForLabel(v)) ?: "General"`. 두 이름이 같으면(`null` → `uncategorized.general` 등) 그냥 `category`) · `shares` → `split`(단, `amount`도 바뀌었으면 생략 — 금액이 바뀌면 분할은 늘 바뀐다) · `split` → `split`(단, `shares`나 `amount`도 바뀌었으면 생략) · `notes` → `notes`.

### 푸시
- 이벤트가 **새로 저장된** push가 커밋되면(clientId 중복만 있는 재시도는 알림 없음) 그룹의 연결된·removed 아닌 멤버 가운데 **보낸 사용자가 아닌** 사용자의 기기(FCM 토큰 있는)로 보낸다. 내 변경은 내 기기에 알리지 않는다(지금과 같음). 8단계: 스케줄러가 올린 반복은 보낸 사용자가 없으므로 모든 연결 멤버(시리즈를 만든 사람 포함)에게 간다. 읽지 않은 활동도 그것을 센다(`actor_user_id IS DISTINCT FROM`).
- 수신자마다 이번 push의 새 이벤트로 ActivityItem을 만들고(`me` = 수신자의 멤버), 숨김 항목과 수신자의 알림 설정이 끈 분류를 뺀다. 분류: `expenses` = `expense_*`·`payment_*`(7단계 `payment_restored` 포함)·`receipt_*`(7단계)·`recurrence_*`(8단계, `expense_repeated`는 `expense_*`), `comments` = `comment_added`(송금 댓글 포함), `members` = `member_*`(`member_left` 포함)·`friend_added`(6단계)·`group_updated`.
- 남은 항목이 있으면 **표시 알림**(FCM notification + data): title = 그룹 이름(보낼 때의 이름. 친구 그룹(6단계)이면 수신자의 멤버가 아닌 쪽 멤버의 이름), body = 항목이 1개면 그 문장, 2개 이상이면 묶음 문장. 표시 알림에는 수신자의 그때 읽지 않은 수 `total`을 배지로 넣는다(6단계, 아래 "읽지 않은 활동").
- 묶음: 수신자·그룹마다 마지막 표시 알림 뒤 `EVENSIES_PUSH_BATCH_SECONDS`(기본 30)초 안에 생긴 항목은 바로 보내지 않고 모아 두었다가, 그 시간이 지나는 순간 모은 항목 전부를 표시 알림 하나로 보낸다. 서버 메모리에만 두므로 재시작하면 모은 항목은 버려진다.
- 표시 알림을 보내지 않는 push(남은 항목 없음, 알림 꺼짐, 묶는 중)에도 **data만 있는 메시지**는 바로 보낸다(동기화용, 지금과 같음).
- 그룹 이벤트 알림의 data는 언제나 `{"type":"sync","groupId":"...","seq":"<보낼 때의 latestSeq>"}`(FCM data 값은 문자열). 6단계 리마인더는 `{"type":"remind","fromUserId"}`(아래 "리마인더"). 앱은 모르는 `groupId`의 sync를 받으면(새 친구 그룹) `syncAll()`을 한다.
- 8단계: 표시 알림의 항목에서 같은 묶음에 같은 `recurrenceId`이고 **같은 `actorMemberId`**인 `expense_*` 항목이 있는 `recurrence_*` 항목도 먼저 뺀다(짝은 언제나 한 사람의 한 저장에서 나온다. 30초 묶음에 다른 사람의 멈춤이나 Evensies의 반복(actor 없음)이 같이 있으면 둘 다 남는다. 반복 지출 만들기 `recurrence_created` + `expense_added`, 마지막 반복을 미래까지 고치기 `expense_updated` + `recurrence_updated`, 지우고 멈추기 `expense_deleted` + `recurrence_deleted`가 각각 지출의 문장 하나. `shared/activity-cases.json`의 `batches`). 피드에서는 빼지 않는다.
- 7단계: 표시 알림의 항목에서 같은 묶음에 같은 `expenseId`의 `expense_added`가 있는 `receipt_added`는 먼저 뺀다(영수증을 붙여 새 지출을 저장하면 그 지출의 문장 하나. `shared/activity-cases.json`의 `batches`). 피드에서는 빼지 않는다.
- 묶음 문장(항목 2개 이상, 수신자는 actor가 아니므로 `You`는 나오지 않는다): 모든 항목의 `actorMemberId`가 같고 모두 `expense_added`면 `{A} added {n} expenses`, 모두 `comment_added`면 `{A} added {n} comments`, 모두 `expense_repeated`(8단계, actor 없음)면 `{n} repeating expenses were added`, 그 밖이면 `{A} made {n} changes`. actor가 섞이면 `{n} new changes`(actor 없음도 하나의 actor다).
- 앱: 표시 알림을 누르면 그 그룹의 활동 탭을 연다(친구 그룹이면 친구 페이지, `remind`면 `/friends/{fromUserId}`). 8단계: 활동 목록의 `expense_repeated` 행은 그 지출을, `recurrence_*` 행은 그 시리즈의 마지막 반복(아래 "반복 지출"의 "앱", 없으면 아무것도 안 함)을 연다. 앱의 `myDeltaText`는 `expense_repeated`에도 쓴다. 앱이 앞에 있을 때 온 알림은 시스템 알림 대신 앱 안 배너(같은 title/body)로 보여 주고 sync한다.
- 길이: title은 100자, body는 200자(UTF-16)를 넘으면 잘라서 끝을 `…`로 한다(`…` 포함 그 길이, 서로게이트 쌍은 자르지 않음). 긴 댓글·설명·그룹 이름이 FCM/APNs 4096바이트 한도를 넘겨 data까지 잃지 않게 하기 위해서다. 앱 목록의 문장은 자르지 않는다.
- FCM 멀티캐스트는 토큰 500개씩 나눠 보낸다. FCM이 `UNREGISTERED`로 답한 토큰과, 같은 멀티캐스트에서 다른 토큰은 성공했는데 `INVALID_ARGUMENT`로 답한 토큰은 기기 행을 지운다.
- iOS(APNs): 표시 알림은 `sound: default`, `thread-id: <groupId>`(그룹별로 묶임), 6단계부터 `badge: <total>`(Android는 `notification.notification_count`). 수신자마다 배지가 다르므로 `PushNotifier`는 (body, badge)가 같은 토큰끼리 묶어 멀티캐스트한다. data만 있는 메시지는 `content-available: 1`, `apns-priority: 5`, `apns-push-type: background`(앱이 백그라운드에서 깨어 sync).
- FCM 자격 증명(`EVENSIES_FCM_CREDENTIALS_FILE`)이 없으면 조용히 건너뛴다.

### 읽지 않은 활동 (6단계)
| 메서드 | 경로 | 요청 | 응답 |
|---|---|---|---|
| GET | `/activity/unread` | | `ActivityUnread` |
| POST | `/activity/seen` | `{"feedId": number, "groupId"?: "<uuid>"}` | `ActivityUnread`(바꾼 뒤) |

```
ActivityUnread {"total": 3, "groups": {"<groupId>": 2, "<groupId>": 1}}
```
- 기준점: (사용자, 그룹)마다 `activity_seen.feed_id`(행 없음 = 0). `POST /activity/seen`은 `groupId`가 있으면 그 그룹(그룹 없음 404, 지금 멤버가 아니면 403), 없으면 호출자가 지금(removed 아님) 멤버인 모든 그룹의 기준점을 `GREATEST(저장값, LEAST(feedId, 지금 events의 최대 feed_id))`로 올린다(내려가지 않는다. 너무 큰 값으로 앞으로의 항목을 미리 읽음 처리할 수 없다). `feedId`가 0 이상 정수가 아니면 400 `VALIDATION`, `groupId`가 UUID가 아니면 400 `VALIDATION`.
- 읽지 않은 항목 = 전체 피드(`GET /activity`)와 같은 그룹·같은 `me`·같은 숨김 규칙(숨김 5 포함)으로 만든 항목 가운데 (a) `feedId > 그 그룹의 기준점`, (b) 이벤트의 `actorUserId`가 호출자가 아님, (c) 이벤트의 `received_at` ≥ 그 그룹에서 피드가 고른 내 멤버 행의 `created_at`(초대로 새로 들어오면 들어오기 전 기록은 세지 않는다. 자리표시를 claim하면 그 자리표시가 생긴 뒤의 기록은 센다 — 나에 관한 기록이다). `groups`는 0인 그룹을 빼고, `total` = `groups`의 합.
- 그룹마다 기준점 뒤의 이벤트만 읽는다(인덱스 `events (group_id, feed_id)`, V7). 다 읽은 사용자는 그룹당 인덱스 조회 한 번이다.
- `ponytail:` 최신부터 후보 최대 500행만 훑는다(그보다 많으면 덜 센다). 앱은 99를 넘으면 `99+`.
- 앱: 그룹 활동 탭 배지 = `groups[groupId]`, 전체 활동 버튼 배지 = `total`. 활동 탭이나 전체 활동 화면의 첫 페이지를 받으면 그 페이지의 가장 큰 `feedId`로 `POST /activity/seen`(그룹 탭은 `groupId`와 함께, 전체 화면은 없이. 빈 페이지면 보내지 않는다). 앱을 켤 때, 앞으로 돌아올 때, 푸시를 받을 때 `GET /activity/unread`. 온라인일 때만(오프라인 큐 없음, 실패하면 배지를 그대로 둔다. 404면 이전 서버이므로 배지를 숨긴다). 받은 `total`로 앱 아이콘 배지를 맞춘다(iOS: 작은 platform channel `evensies/badge`, `UNUserNotificationCenter.setBadgeCount`. Android는 no-op — 런처가 알림의 개수를 보인다). 새 의존성 없음.
- 푸시 배지: 그룹 이벤트의 표시 알림에만 수신자의 그때 `total`을 넣는다(위 "푸시"). data만 있는 메시지와 리마인더에는 넣지 않는다(iOS는 배지가 없는 알림이면 지금 배지를 둔다).

### 알림 설정
| 메서드 | 경로 | 요청 | 응답 |
|---|---|---|---|
| GET | `/me/notifications` | | `NotificationPrefs` — 저장한 적 없으면 모두 `true` |
| PUT | `/me/notifications` | `NotificationPrefs` (`expenses`·`comments`·`members`는 필수 boolean, 전체 교체. `reminders`(6단계)는 선택: 없으면 저장된 값 그대로, 있으면 boolean) | `NotificationPrefs`(네 키 모두). 필수 키가 빠지거나 boolean이 아니면, `reminders`가 boolean이 아니면(`null` 포함) 400 `VALIDATION` |

```
NotificationPrefs {"expenses": bool, "comments": bool, "members": bool, "reminders": bool}
```
`expenses` = 지출·송금, `comments` = 댓글, `members` = 멤버 참여·추가·제외·나감과 그룹 설정(이름·통화·부채 단순화·기본 분할) 변경. `reminders`(6단계) = 다른 사람이 보낸 리마인더 표시 알림(저장한 적 없으면 `true`). 2~5단계 앱은 `reminders`를 보내지 않으므로 그 값이 바뀌지 않는다. 꺼도 동기화용 data 메시지는 계속 온다. `DELETE /me`는 설정도 지운다.

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
| `EVENSIES_FX_URL` | `https://api.frankfurter.dev/v2` | 환율 출처(`{url}/rates?base=EUR&date=`, Frankfurter v2 응답 모양). 빈 값이면 자동 환율 끔(`GET /fx`는 언제나 503). 키 없음, 무료 |
| `EVENSIES_STORAGE_DIR` | `./data` | 6단계: 올린 파일(프로필 사진, 7단계 영수증, 10단계 그룹 표지)의 디렉터리. Docker 이미지는 `ENV EVENSIES_STORAGE_DIR=/data`, `deploy/docker-compose.yml`이 `./data:/data`를 마운트한다. DB 덤프와 함께 백업한다(출시 때 효준님이 호스트의 rclone cron에 `deploy/data`를 더한다. 자체 호스팅은 `./data`를 백업) |
