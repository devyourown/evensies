// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'Evensies';

  @override
  String get cancel => '취소';

  @override
  String get delete => '삭제';

  @override
  String get remove => '제거';

  @override
  String get save => '저장';

  @override
  String get done => '완료';

  @override
  String get undo => '되돌리기';

  @override
  String get retry => '다시 시도';

  @override
  String get ok => '확인';

  @override
  String get close => '닫기';

  @override
  String get edit => '수정';

  @override
  String get add => '추가';

  @override
  String get offlineBanner => '오프라인 — 변경 사항은 나중에 동기화돼요';

  @override
  String get tooLong => '너무 길어요';

  @override
  String get allCurrencies => '모든 통화';

  @override
  String get errorUnexpected => '문제가 생겼어요. 다시 시도해 주세요.';

  @override
  String get errorNetwork => '오프라인이에요. 나중에 다시 시도해 주세요.';

  @override
  String get errorRateLimited => '시도가 너무 많아요. 1분 뒤에 다시 시도해 주세요.';

  @override
  String get errorNotFound => '더 이상 존재하지 않아요.';

  @override
  String get errorForbidden => '그렇게 할 수 없어요.';

  @override
  String get errorValidation => '서버가 거부했어요.';

  @override
  String get errorSumMismatch => '분할 금액이 합계와 맞지 않아요.';

  @override
  String get errorPayersSumMismatch => '결제한 사람들의 금액이 합계와 맞지 않아요.';

  @override
  String get errorNegativeAmount => '0보다 작은 금액이 있어요.';

  @override
  String get errorNegativeShare => '누군가의 몫이 0보다 작아져요.';

  @override
  String get errorNegativeTotal => '합계가 0보다 작아져요.';

  @override
  String get errorZeroSubtotal => '세금, 팁, 할인 전에 항목 가격을 입력해 주세요.';

  @override
  String get errorUnassignedItem => '모든 항목에 한 명 이상이 필요해요.';

  @override
  String get errorNoMembers => '나눌 사람을 한 명 이상 골라 주세요.';

  @override
  String get errorInvalidInput => '숫자를 확인해 주세요.';

  @override
  String get errorBadRate => '환율은 0보다 커야 해요.';

  @override
  String get errorUnknownMember => '그룹에 없는 사람이 포함돼 있어요.';

  @override
  String get errorUnknownCurrency => '지원하지 않는 통화예요.';

  @override
  String get errorMemberTaken => '이미 다른 사람이 선택한 멤버예요.';

  @override
  String get errorLimitExceeded => '한도에 도달했어요.';

  @override
  String get errorTooLarge => '사진이 너무 커요.';

  @override
  String get errorNotJpeg => 'JPEG 사진을 골라 주세요';

  @override
  String get errorFxUnavailable => '지금은 환율을 가져올 수 없어요.';

  @override
  String get errorImportFailed => '이 파일을 가져올 수 없어요.';

  @override
  String get errorAuthNotConfigured => '이 서버는 이 방법으로 로그인할 수 없어요.';

  @override
  String get errorDuplicate => '이미 있어요.';

  @override
  String errorGeneric(String code) {
    return '문제가 생겼어요 ($code).';
  }

  @override
  String rejectedReceipt(String name, String reason) {
    return '“$name”의 영수증을 저장하지 못했어요: $reason';
  }

  @override
  String rejectedReceiptUnnamed(String reason) {
    return '지출의 영수증을 저장하지 못했어요: $reason';
  }

  @override
  String rejectedReceiptRemove(String name, String reason) {
    return '“$name”에서 영수증 제거를 저장하지 못했어요: $reason';
  }

  @override
  String rejectedReceiptRemoveUnnamed(String reason) {
    return '지출에서 영수증 제거를 저장하지 못했어요: $reason';
  }

  @override
  String rejectedRepeating(String name, String reason) {
    return '“$name” 반복을 저장하지 못했어요: $reason';
  }

  @override
  String rejectedRepeatingUnnamed(String reason) {
    return '반복 지출을 저장하지 못했어요: $reason';
  }

  @override
  String rejectedSeriesChange(String name, String reason) {
    return '“$name”의 앞으로의 반복 변경을 저장하지 못했어요: $reason';
  }

  @override
  String rejectedSeriesChangeUnnamed(String reason) {
    return '반복 지출의 변경을 저장하지 못했어요: $reason';
  }

  @override
  String rejectedSeriesStop(String name, String reason) {
    return '“$name” 반복 중지를 저장하지 못했어요: $reason';
  }

  @override
  String rejectedSeriesStopUnnamed(String reason) {
    return '반복 지출 중지를 저장하지 못했어요: $reason';
  }

  @override
  String rejectedSavedNoRepeat(String name, String reason) {
    return '“$name” 지출은 저장됐지만 반복되지 않아요: $reason';
  }

  @override
  String rejectedPaymentRestore(String reason) {
    return '송금 되살리기를 저장하지 못했어요: $reason';
  }

  @override
  String rejectedNewExpense(String name, String reason) {
    return '새로 추가한 “$name” 지출을 저장하지 못했어요: $reason';
  }

  @override
  String rejectedNewExpenseUnnamed(String reason) {
    return '새 지출을 저장하지 못했어요: $reason';
  }

  @override
  String rejectedExpenseChange(String name, String reason) {
    return '“$name” 변경을 저장하지 못했어요: $reason';
  }

  @override
  String rejectedExpenseChangeUnnamed(String reason) {
    return '지출 변경을 저장하지 못했어요: $reason';
  }

  @override
  String rejectedExpenseDelete(String name, String reason) {
    return '“$name” 삭제를 저장하지 못했어요: $reason';
  }

  @override
  String rejectedExpenseDeleteUnnamed(String reason) {
    return '지출 삭제를 저장하지 못했어요: $reason';
  }

  @override
  String rejectedExpenseRestore(String name, String reason) {
    return '“$name” 되살리기를 저장하지 못했어요: $reason';
  }

  @override
  String rejectedExpenseRestoreUnnamed(String reason) {
    return '지출 되살리기를 저장하지 못했어요: $reason';
  }

  @override
  String rejectedComment(String name, String reason) {
    return '“$name”의 댓글을 저장하지 못했어요: $reason';
  }

  @override
  String rejectedCommentUnnamed(String reason) {
    return '지출의 댓글을 저장하지 못했어요: $reason';
  }

  @override
  String rejectedPaymentComment(String reason) {
    return '송금의 댓글을 저장하지 못했어요: $reason';
  }

  @override
  String rejectedCommentDelete(String reason) {
    return '댓글 삭제를 저장하지 못했어요: $reason';
  }

  @override
  String rejectedPayment(String reason) {
    return '송금을 저장하지 못했어요: $reason';
  }

  @override
  String rejectedPaymentDelete(String reason) {
    return '송금 삭제를 저장하지 못했어요: $reason';
  }

  @override
  String rejectedPaymentConfirm(String reason) {
    return '송금 확인을 저장하지 못했어요: $reason';
  }

  @override
  String rejectedGroupSettings(String reason) {
    return '그룹 설정 변경을 저장하지 못했어요: $reason';
  }

  @override
  String rejectedMemberAdd(String name, String reason) {
    return '$name 추가를 저장하지 못했어요: $reason';
  }

  @override
  String rejectedMemberAddUnnamed(String reason) {
    return '멤버 추가를 저장하지 못했어요: $reason';
  }

  @override
  String rejectedMemberRemove(String reason) {
    return '멤버 제거를 저장하지 못했어요: $reason';
  }

  @override
  String rejectedOther(String reason) {
    return '변경을 저장하지 못했어요: $reason';
  }

  @override
  String get reasonReceiptLimit => '지출 하나에 영수증은 최대 10장이에요';

  @override
  String get reasonSeriesLimit => '그룹 하나에 반복 지출은 최대 100개예요';

  @override
  String get reasonNotUploaded => '사진이 업로드되지 않았어요';

  @override
  String get reasonSumMismatch => '분할 금액이 합계와 맞지 않아요';

  @override
  String get reasonPayersSumMismatch => '결제한 사람들의 금액이 합계와 맞지 않아요';

  @override
  String get reasonNegativeAmount => '0보다 작은 금액이 있어요';

  @override
  String get reasonUnknownMember => '그룹에 없는 사람이 포함돼 있어요';

  @override
  String get reasonUnknownCurrency => '지원하지 않는 통화예요';

  @override
  String get reasonMemberTaken => '이미 다른 사람이 선택한 멤버예요';

  @override
  String get reasonGroupFull => '그룹이 가득 찼어요';

  @override
  String get reasonForbidden => '이 변경을 할 수 없어요';

  @override
  String get reasonRefused => '서버가 거부했어요';

  @override
  String leaveOwe(String amount) {
    return '갚을 돈 $amount · 먼저 정산해 주세요';
  }

  @override
  String leaveOweIn(String amount, String currency) {
    return '갚을 돈 $amount · 먼저 $currency 통화로 정산해 주세요';
  }

  @override
  String leaveOwed(String amount) {
    return '받을 돈 $amount · 먼저 정산해 주세요';
  }

  @override
  String leaveOwedIn(String amount, String currency) {
    return '받을 돈 $amount · 먼저 $currency 통화로 정산해 주세요';
  }

  @override
  String leaveSeries(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '아직 반복 지출 $count개($names)에 포함돼 있어요 · 먼저 가장 최근 지출을 수정하거나 반복을 멈춰 주세요',
    );
    return '$_temp0';
  }

  @override
  String seriesNamesMore(String names, int count) {
    return '$names 외 $count개';
  }

  @override
  String get seriesUnnamed => '지출';

  @override
  String get listJoiner => ', ';

  @override
  String get repeatNever => '안 함';

  @override
  String get repeatWeekly => '매주';

  @override
  String get repeatBiweekly => '2주마다';

  @override
  String get repeatMonthly => '매월';

  @override
  String get repeatYearly => '매년';

  @override
  String summaryNotConverted(String currency) {
    return '환산 안 됨 · $currency';
  }

  @override
  String summaryTotalSpent(String amount) {
    return '총 지출: $amount';
  }

  @override
  String summaryPaidShare(String paid, String share) {
    return '내가 낸 돈: $paid · 내 몫: $share';
  }

  @override
  String summaryPayments(String made, String received) {
    return '보낸 송금: $made · 받은 송금: $received';
  }

  @override
  String summaryTopCategories(String list) {
    return '주요 카테고리: $list';
  }

  @override
  String get summaryBalancesToday => '오늘의 잔액';

  @override
  String summaryGetsBack(String name, String amount) {
    return '$name: $amount 받을 돈';
  }

  @override
  String summaryOwes(String name, String amount) {
    return '$name: $amount 갚을 돈';
  }

  @override
  String get summaryFooter => 'Evensies에서 공유함';

  @override
  String get koreanBank => '한국 은행 계좌';

  @override
  String requestText(String amount, String group) {
    return 'Evensies의 $group에서 나에게 갚을 돈이 있어요: $amount';
  }

  @override
  String requestTextWays(String amount, String group, String ways) {
    return 'Evensies의 $group에서 나에게 갚을 돈이 있어요: $amount. 보내는 방법: $ways';
  }

  @override
  String get requestNoGroup => '우리 둘의 지출';

  @override
  String get leaveSyncing => '아직 동기화 중이에요. 잠시 후 다시 시도해 주세요.';

  @override
  String get leaveOffline => '그룹을 나가려면 온라인이어야 해요';

  @override
  String get moveOffline => '옮기지 못했어요. 온라인일 때 다시 시도해 주세요';

  @override
  String moveFailed(String reason) {
    return '옮기지 못했어요: $reason';
  }

  @override
  String get photoNoAccess => 'Evensies에 접근 권한이 없어요. 설정 앱에서 허용해 주세요.';

  @override
  String get photoNoCamera => '카메라를 열 수 없어요.';

  @override
  String get photoNoLibrary => '사진 보관함을 열 수 없어요.';

  @override
  String get photoUnusable => '이 사진은 쓸 수 없어요. 다른 사진을 골라 주세요.';

  @override
  String get methodErrorUsername => '영문, 숫자, . _ - 만 (최대 40자)';

  @override
  String methodErrorLinkPrefix(String prefix) {
    return '이 주소로 시작해야 해요: $prefix';
  }

  @override
  String get methodErrorTooLong => '최대 200자';

  @override
  String get methodErrorIban => '올바른 IBAN이 아니에요';

  @override
  String get methodErrorHolder => '예금주 이름 (1–70자)';

  @override
  String get methodErrorBic => 'BIC는 8자 또는 11자예요';

  @override
  String get methodErrorKrAccount => '숫자와 하이픈, 숫자 8–20자리';

  @override
  String get methodErrorBank => '은행 이름 (1–30자)';

  @override
  String get methodErrorUnknownType => '알 수 없는 종류';

  @override
  String get methodErrorTooMany => '받는 방법은 최대 8개, 은행 종류마다 3개까지예요';

  @override
  String get bannerDismiss => '닫기';

  @override
  String get bannerView => '보기';

  @override
  String get loginTagline => '친구와 지출을 나눠요. 광고도, 유료 유도도 없어요.';

  @override
  String get loginApple => 'Apple로 계속하기';

  @override
  String get loginGoogle => 'Google로 계속하기';

  @override
  String get loginWebUnavailable => '이 서버는 아직 브라우저 로그인을 지원하지 않아요.';

  @override
  String get welcomeTitle => '환영해요';

  @override
  String get yourNameTitle => '내 이름';

  @override
  String get nameQuestion => '친구들이 나를 뭐라고 부르면 될까요?';

  @override
  String get nameExplain => '다른 멤버에게 보이는 이름이에요.';

  @override
  String get nameHelp => '내 그룹의 사람들에게 보여요. 나중에 설정에서 바꿀 수 있어요.';

  @override
  String get nameLabel => '이름';

  @override
  String get lockReason => 'Evensies 잠금 해제';

  @override
  String get lockTitle => 'Evensies가 잠겨 있어요';

  @override
  String get lockSubtitle => 'Face ID, Touch ID, 지문 또는 기기 암호로 잠금을 해제하세요.';

  @override
  String get lockUnlock => '잠금 해제';

  @override
  String get lockSignOutConfirm => '로그아웃하고 이 기기의 데이터를 지울까요? 그룹은 서버에 남아 있어요.';

  @override
  String get signOut => '로그아웃';

  @override
  String get widgetOwed => '받을 돈';

  @override
  String get widgetOwe => '갚을 돈';

  @override
  String get widgetSignedOut => '로그인하면 잔액이 보여요';

  @override
  String get widgetSettled => '모두 정산됐어요';

  @override
  String widgetUpdated(String time) {
    return '$time 업데이트';
  }

  @override
  String get receiptAdd => '영수증 추가';

  @override
  String get photoTake => '사진 찍기';

  @override
  String get photoChoose => '보관함에서 선택';

  @override
  String get photoChooseFile => '파일 선택';

  @override
  String get availableWhenOnline => '온라인일 때 볼 수 있어요';

  @override
  String get receiptPhoto => '영수증 사진';

  @override
  String get receiptAvailableOnline => '사진은 온라인일 때 볼 수 있어요';

  @override
  String get receiptRemoveTitle => '영수증을 제거할까요?';

  @override
  String get receiptRemoveMessage => '그룹의 모든 사람에게서 제거돼요.';

  @override
  String get receiptTitle => '영수증';

  @override
  String receiptTitleOf(int index, int count) {
    return '영수증 $index/$count';
  }

  @override
  String get shareOrSave => '공유 또는 저장';

  @override
  String get share => '공유';

  @override
  String get copiedToClipboard => '클립보드에 복사했어요';

  @override
  String get settingsTitle => '설정';

  @override
  String get photoRemove => '사진 제거';

  @override
  String get photoNeedsConnection => '사진을 바꾸려면 인터넷 연결이 필요해요.';

  @override
  String get photoTooMany => '사진을 너무 자주 바꿨어요. 1시간 뒤에 다시 시도해 주세요.';

  @override
  String get notifSaveFailed => '알림 설정을 저장하지 못했어요. 연결을 확인해 주세요.';

  @override
  String get homeCurrencyNeedsConnection => '기본 통화를 바꾸려면 인터넷 연결이 필요해요.';

  @override
  String get changePhoto => '프로필 사진 바꾸기';

  @override
  String get yourNameTapToChange => '내 이름 · 눌러서 바꾸기';

  @override
  String get waysToGetPaid => '받는 방법';

  @override
  String get waysToGetPaidHint => 'PayPal, Wise, IBAN, 은행 계좌…';

  @override
  String get homeCurrency => '기본 통화';

  @override
  String get homeCurrencyFromRegion => '내 지역 기준 · 잔액이 이 통화로도 ≈ 표시돼요';

  @override
  String get homeCurrencyPicked => '잔액이 이 통화로도 ≈ 표시돼요';

  @override
  String get notifications => '알림';

  @override
  String get notifExpenses => '지출과 송금';

  @override
  String get notifComments => '댓글';

  @override
  String get notifMembers => '멤버와 그룹 변경';

  @override
  String get notifReminders => '친구의 리마인더';

  @override
  String get notifNeedConnection => '알림 설정에는 인터넷 연결이 필요해요';

  @override
  String get notifOthersOnly => '다른 사람이 바꾼 것만 알려 드려요.';

  @override
  String get notifWebNote => '알림은 휴대폰으로 가요. 브라우저는 열려 있는 동안 1분마다 새로 고쳐요.';

  @override
  String get exportImport => '내보내기 및 가져오기';

  @override
  String get noGroupsToExport => '내보낼 그룹이 없어요.';

  @override
  String get nonGroup => '그룹 밖';

  @override
  String nonGroupWith(String name) {
    return '그룹 밖 · $name';
  }

  @override
  String get exportJson => 'JSON 내보내기';

  @override
  String get exportCsv => 'CSV 내보내기';

  @override
  String get exportZip => '영수증 포함 ZIP';

  @override
  String get importSplitwise => 'Splitwise CSV 가져오기';

  @override
  String importedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '지출 $count개를 가져왔어요',
    );
    return '$_temp0';
  }

  @override
  String get server => '서버';

  @override
  String get serverUrl => '서버 URL';

  @override
  String serverDefault(String url) {
    return '기본값: $url';
  }

  @override
  String get serverSaved => '서버 URL을 저장했어요';

  @override
  String get account => '계정';

  @override
  String get licenses => '라이선스';

  @override
  String get deleteAccount => '계정 삭제';

  @override
  String get signOutTitle => '로그아웃할까요?';

  @override
  String get signOutMessage => '이 기기의 로컬 데이터가 지워져요. 아직 동기화되지 않은 변경은 사라져요.';

  @override
  String get deleteAccountTitle => '계정을 삭제할까요?';

  @override
  String get deleteAccountMessage =>
      '그룹에서 나는 이름만 남은 멤버로 바뀌어요. 그룹 데이터는 다른 멤버에게 남아요. 되돌릴 수 없어요.';

  @override
  String get language => '언어';

  @override
  String languageSystem(String language) {
    return '시스템 ($language)';
  }

  @override
  String get appearance => '화면 모드';

  @override
  String get appearanceSystem => '시스템';

  @override
  String get appearanceLight => '라이트';

  @override
  String get appearanceDark => '다크';

  @override
  String get security => '보안';

  @override
  String get appLock => '앱 잠금';

  @override
  String get appLockHint =>
      'Face ID, Touch ID 또는 지문을 쓰고, 안 되면 기기 암호를 써요. 1분 동안 나가 있으면 잠겨요.';

  @override
  String methodRemoveTitle(String method) {
    return '$method 결제 수단을 제거할까요?';
  }

  @override
  String get methodsOffline => '받는 방법을 수정하려면 인터넷에 연결해 주세요.';

  @override
  String get methodsLoadFailed => '받는 방법을 불러오지 못했어요.';

  @override
  String get methodsIntro =>
      '그룹 멤버가 나에게 갚을 돈이 있을 때 이 방법들이 보여서 한 번에 보낼 수 있어요. Evensies는 직접 돈을 옮기지 않아요.';

  @override
  String get methodsEmpty => '아직 받는 방법이 없어요.';

  @override
  String get blurbPaypal => 'PayPal.me 링크, 금액 자동 입력';

  @override
  String get blurbWise => 'Wise Quick Pay 링크, 금액 자동 입력';

  @override
  String get blurbVenmo => 'Venmo 사용자 이름 (미국)';

  @override
  String get blurbRevolut => 'Revolut.me 사용자 이름';

  @override
  String get blurbKakaopay => '카카오페이 송금코드 링크';

  @override
  String get blurbIban => '계좌 이체 (EUR은 SEPA QR)';

  @override
  String get blurbKrBank => '한국 은행 계좌 (토스, 은행 앱)';

  @override
  String get fieldPaypal => 'PayPal.me 사용자 이름';

  @override
  String get fieldPaypalHint => 'PayPal.me 사용자 이름, 예: anna';

  @override
  String get fieldRevolut => 'Revolut.me 사용자 이름';

  @override
  String get fieldRevolutHint => 'Revolut.me 사용자 이름, 예: anna';

  @override
  String get fieldVenmo => 'Venmo 사용자 이름';

  @override
  String get fieldVenmoHint => '@ 없이, 예: anna-rossi';

  @override
  String get fieldWise => 'Wise Quick Pay 링크';

  @override
  String get fieldWiseHint =>
      'Wise에서: Payments → Quick Pay → 링크 복사 (https://wise.com/pay/…)';

  @override
  String get fieldKakaopay => '카카오페이 송금코드 링크';

  @override
  String get fieldKakaopayHint =>
      '카카오페이에서: 송금 → 송금코드 → 링크 복사 (https://qr.kakaopay.com/…)';

  @override
  String get fieldHolder => '예금주';

  @override
  String get fieldHolderHint => '계좌에 적힌 그대로의 이름';

  @override
  String get fieldIban => 'IBAN';

  @override
  String get fieldIbanHint => '예: DE89 3704 0044 0532 0130 00';

  @override
  String get fieldBic => 'BIC (선택)';

  @override
  String get fieldBicHint => '8자 또는 11자';

  @override
  String get fieldBank => '은행';

  @override
  String get fieldBankHint => '예: 신한은행, 토스뱅크';

  @override
  String get fieldAccountNumber => '계좌 번호';

  @override
  String get fieldAccountNumberHint => '숫자, 하이픈은 선택';

  @override
  String amountCopied(String amount) {
    return '금액을 복사했어요: $amount';
  }

  @override
  String couldNotOpen(String link) {
    return '열 수 없어요: $link';
  }

  @override
  String get payOffline => '오프라인: 보내는 방법을 볼 수 없어요';

  @override
  String get payLoading => '보내는 방법을 불러오는 중…';

  @override
  String payAskToAdd(String name) {
    return '$name에게 받는 방법을 추가해 달라고 해 주세요';
  }

  @override
  String payTitle(String name, String amount) {
    return '$name에게 $amount 보내기';
  }

  @override
  String get payScanQr => '은행 앱으로 스캔하세요 (SEPA QR)';

  @override
  String get payQrEurOnly => 'QR 코드는 EUR 이체에만 쓸 수 있어요.';

  @override
  String get bankLabel => '은행';

  @override
  String get ibanLabel => 'IBAN';

  @override
  String get accountLabel => '계좌';

  @override
  String get bicLabel => 'BIC';

  @override
  String get holderLabel => '예금주';

  @override
  String get amountLabel => '금액';

  @override
  String get copyIban => 'IBAN 복사';

  @override
  String get copyAccount => '계좌 복사';

  @override
  String get copyAmount => '금액 복사';

  @override
  String get ibanCopied => 'IBAN을 복사했어요';

  @override
  String get accountCopied => '계좌를 복사했어요';

  @override
  String get paymentUpdated => '송금을 수정했어요';

  @override
  String paymentRecordedPending(String amount, String name) {
    return '송금을 기록했어요 · $amount. $name님의 확인을 기다려요.';
  }

  @override
  String paymentRecordedPendingUnnamed(String amount) {
    return '송금을 기록했어요 · $amount. 상대방의 확인을 기다려요.';
  }

  @override
  String paymentRecorded(String amount) {
    return '$amount 송금을 기록했어요';
  }

  @override
  String youSuffix(String name) {
    return '$name (나)';
  }

  @override
  String get recordPayment => '송금 기록';

  @override
  String get editPayment => '송금 수정';

  @override
  String get fromLabel => '보낸 사람';

  @override
  String get toLabel => '받는 사람';

  @override
  String get swap => '바꾸기';

  @override
  String get pickTwoPeople => '서로 다른 두 사람을 골라 주세요';

  @override
  String get commentsStayOld => '댓글은 이전 송금에 남아요';

  @override
  String get recordPaymentButton => '송금 기록하기';

  @override
  String get paymentNotHere => '이 송금은 이 기기에 없어요';

  @override
  String get notSyncedOrLeft => '아직 동기화되지 않았거나, 그룹에서 나갔어요.';

  @override
  String get someone => '알 수 없는 멤버';

  @override
  String get paymentEdited => '수정된 송금';

  @override
  String get paymentDeleted => '삭제된 송금';

  @override
  String get payment => '송금';

  @override
  String get paymentWasEdited => '이 송금은 수정됐어요';

  @override
  String get paymentWasEditedNote => '대신 수정된 송금이 반영돼요. 댓글은 여기에 남아요.';

  @override
  String get paymentWasDeleted => '이 송금은 삭제됐어요';

  @override
  String get paymentNotCounted => '잔액에 반영되지 않아요.';

  @override
  String get restore => '되살리기';

  @override
  String youPaidName(String name) {
    return '$name에게 송금했어요';
  }

  @override
  String namePaidYou(String name) {
    return '$name님이 나에게 송금했어요';
  }

  @override
  String namePaidName(String from, String to) {
    return '$from → $to 송금';
  }

  @override
  String paymentSaysSent(String name) {
    return '$name님이 보냈다고 해요. 받았나요?';
  }

  @override
  String waitingForConfirm(String name) {
    return '$name의 확인을 기다리는 중';
  }

  @override
  String get notReceived => '받지 못함';

  @override
  String get confirmReceived => '받았어요';

  @override
  String get deletePaymentTitle => '송금을 삭제할까요?';

  @override
  String get deletePaymentMessage => '이 송금으로 정산된 빚이 다시 생겨요.';

  @override
  String get paymentDeletedSnack => '송금을 삭제했어요';

  @override
  String get notReceivedTitle => '받지 못했나요?';

  @override
  String notReceivedMessage(String name) {
    return '$name의 송금이 제거되고 빚이 다시 생겨요.';
  }

  @override
  String get paymentRemovedSnack => '송금을 제거했어요';

  @override
  String get recordAPayment => '송금 기록';

  @override
  String get nothingToSettle => '정산할 게 없어요';

  @override
  String get everyoneEven => '모두 정산됐어요.';

  @override
  String get waitingForConfirmation => '확인 대기 중';

  @override
  String get debtsAsRecorded => '기록된 그대로의 빚 · 빚 단순화 꺼짐';

  @override
  String transfersSettleEverything(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '송금 $count번이면 모두 정산돼요',
    );
    return '$_temp0';
  }

  @override
  String transfersSettleBalance(int count, String currency) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '송금 $count번이면 $currency 잔액이 정산돼요',
    );
    return '$_temp0';
  }

  @override
  String notConvertedSettlesIn(String currency) {
    return '환산 안 됨 · $currency · $currency로 정산';
  }

  @override
  String get convert => '환산';

  @override
  String get settleUp => '정산하기';

  @override
  String saysTheySent(String name, String amount) {
    return '$name님이 보냈다고 해요 · $amount';
  }

  @override
  String waitingToConfirmAmount(String name, String amount) {
    return '$name의 $amount 확인을 기다리는 중';
  }

  @override
  String get you => '나';

  @override
  String get request => '요청';

  @override
  String get iveSentIt => '보냈어요';

  @override
  String get markAsPaid => '갚음으로 표시';

  @override
  String markedAsSent(String name) {
    return '보냄으로 표시했어요. $name의 확인을 기다려요.';
  }

  @override
  String approx(String amount) {
    return '≈ $amount';
  }

  @override
  String friendOwesYou(String name, String amount) {
    return '$name님에게 받을 돈 $amount';
  }

  @override
  String friendYouOwe(String name, String amount) {
    return '$name님에게 갚을 돈 $amount';
  }

  @override
  String friendYouOweLine(String name, String amount) {
    return '$name님에게 갚을 돈 $amount';
  }

  @override
  String noSharedGroup(String name) {
    return '이제 $name님과 함께하는 그룹이 없어요. 지출을 추가하려면 친구 링크를 보내 주세요.';
  }

  @override
  String get shareFriendLink => '친구 링크 공유';

  @override
  String firstExpenseNeedsConnection(String name) {
    return '$name님과의 첫 지출에는 인터넷 연결이 필요해요.';
  }

  @override
  String reminderSent(String name) {
    return '$name에게 리마인더를 보냈어요';
  }

  @override
  String remindTomorrow(String name) {
    return '$name에게는 내일 다시 리마인더를 보낼 수 있어요';
  }

  @override
  String remindNothingOwed(String name) {
    return '$name님은 나에게 갚을 돈이 없어요';
  }

  @override
  String get remindNeedsConnection => '리마인더를 보내려면 인터넷 연결이 필요해요.';

  @override
  String amountsAnd(String a, String b) {
    return '$a, $b';
  }

  @override
  String inviteFriendText(String link) {
    return '지출을 나누려고 Evensies에 당신을 추가했어요. 함께해요: $link';
  }

  @override
  String get personNotHere => '이 사람은 이 기기에 없어요';

  @override
  String get personNotHereNote => '아직 동기화되지 않았거나, 더 이상 함께하는 그룹이 없어요.';

  @override
  String get more => '더 보기';

  @override
  String get exportNonGroupCsv => '그룹 밖 지출 내보내기 (CSV)';

  @override
  String get exportNonGroupJson => '그룹 밖 지출 내보내기 (JSON)';

  @override
  String get exportNonGroupZip => '그룹 밖 지출 내보내기 (영수증 포함 ZIP)';

  @override
  String get notOnEvensies => '아직 Evensies를 쓰지 않아요';

  @override
  String get allSettledUp => '모두 정산됐어요';

  @override
  String get remind => '리마인더';

  @override
  String get invite => '초대';

  @override
  String get balances => '잔액';

  @override
  String get expensesAndPayments => '지출과 송금';

  @override
  String get nothingTogetherYet => '아직 함께한 기록이 없어요. 아래에서 지출을 추가해 보세요.';

  @override
  String get addExpense => '지출 추가';

  @override
  String personOwesYou(String amount) {
    return '$amount 받을 돈';
  }

  @override
  String personYouOwe(String amount) {
    return '$amount 갚을 돈';
  }

  @override
  String get personSettledUp => '정산 완료';

  @override
  String recordedInGroups(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '그룹 $count개에 기록했어요',
    );
    return '$_temp0';
  }

  @override
  String get markAsReceived => '받음으로 표시';

  @override
  String get clearBothSides => '양쪽 모두 정리';

  @override
  String evenIn(String currency) {
    return '$currency로는 정산 완료';
  }

  @override
  String linePayThem(String group, String name, String amount) {
    return '$group: $name님에게 갚을 돈 $amount';
  }

  @override
  String lineTheyPay(String group, String name, String amount) {
    return '$group: $name님에게 받을 돈 $amount';
  }

  @override
  String get noMoneyMoves => '돈은 오가지 않아요: 양쪽을 정산된 것으로 기록해요.';

  @override
  String convertIn(String group) {
    return '$group에서 환산';
  }

  @override
  String settleUpWith(String name) {
    return '$name님과 정산하기';
  }

  @override
  String nothingToSettleWith(String name) {
    return '$name님과 정산할 게 없어요';
  }

  @override
  String settleWithIntro(String name) {
    return '$name님과의 모든 것을 통화별로 보여 줘요. 기록하면 그룹마다 송금이 하나씩 추가돼요.';
  }

  @override
  String get searchFriendsGroups => '친구와 그룹 검색';

  @override
  String get friends => '친구';

  @override
  String get groups => '그룹';

  @override
  String get noFriendsOrGroups => '아직 친구나 그룹이 없어요.';

  @override
  String nothingMatches(String query) {
    return '“$query” 검색 결과가 없어요.';
  }

  @override
  String get addExpenseWithWhom => '지출 추가 · 누구와?';

  @override
  String friendLinkShare(String link, String code) {
    return 'Evensies에서 나를 추가하고 지출을 나눠요: $link\n또는 내 코드를 입력하세요: $code';
  }

  @override
  String get friendLinkNeedsConnection => '친구 링크를 공유하려면 인터넷 연결이 필요해요.';

  @override
  String get selfFriend => '내 코드예요';

  @override
  String get noOneForCode => '이 코드에 해당하는 사람이 없어요';

  @override
  String get addFriendNeedsConnection => '친구를 추가하려면 인터넷 연결이 필요해요.';

  @override
  String get newFriendCodeTitle => '새 친구 코드를 받을까요?';

  @override
  String get newFriendCodeMessage =>
      '지금 링크와 코드는 더 이상 쓸 수 없어요. 이미 추가된 친구는 그대로예요.';

  @override
  String get newCode => '새 코드';

  @override
  String get addAFriend => '친구 추가';

  @override
  String get friendLinkOffline => '친구 링크에는 인터넷 연결이 필요해요';

  @override
  String get yourFriendCode => '내 친구 코드';

  @override
  String get friendQrLabel => '내 친구 링크 QR 코드';

  @override
  String get friendCodeHelp => '친구가 이 QR을 스캔하거나, 링크를 열거나, 코드를 입력하면 돼요.';

  @override
  String get shareLink => '링크 공유';

  @override
  String get codeCopied => '코드를 복사했어요';

  @override
  String get copyCode => '코드 복사';

  @override
  String get haveFriendCode => '친구 코드가 있나요?';

  @override
  String get onEvensies => 'Evensies 사용 중';

  @override
  String get notOnEvensiesSection => '아직 Evensies를 쓰지 않는 사람';

  @override
  String get notOnEvensiesHelp => '지금 바로 지출을 함께 추가하고, 나중에 초대하세요.';

  @override
  String atMostChars(int max) {
    return '최대 $max자';
  }

  @override
  String addName(String name) {
    return '$name 추가';
  }

  @override
  String get search => '검색';

  @override
  String get activity => '활동';

  @override
  String get newGroup => '새 그룹';

  @override
  String get joinWithCode => '코드로 참여';

  @override
  String get filterAll => '전체';

  @override
  String get filterOwesMe => '받을 돈';

  @override
  String get filterIOwe => '갚을 돈';

  @override
  String settledUpCount(int count) {
    return '정산 완료 ($count)';
  }

  @override
  String get nobodyOwesYou => '나에게 갚을 사람이 없어요';

  @override
  String get youOweNothing => '갚을 돈이 없어요';

  @override
  String get nothingHereYet => '아직 아무것도 없어요';

  @override
  String get noFriendsYet => '아직 친구가 없어요';

  @override
  String get noFriendsHelp =>
      '그룹 밖에서 지출을 나누려면 친구를 추가하세요. 함께하는 그룹의 사람들도 여기에 보여요.';

  @override
  String get allSettledUpYou => '모두 정산됐어요';

  @override
  String youAreOwedList(String amounts) {
    return '받을 돈 $amounts';
  }

  @override
  String youOweList(String amounts) {
    return '갚을 돈 $amounts';
  }

  @override
  String get notOnEvensiesLower => '아직 Evensies를 쓰지 않아요';

  @override
  String get noGroupsYet => '아직 그룹이 없어요';

  @override
  String get noGroupsHelp => '여행이나 함께 사는 집을 위한 그룹을 만들거나, 친구의 초대 코드로 그룹에 참여하세요.';

  @override
  String get createGroup => '그룹 만들기';

  @override
  String get settledUp => '정산 완료';

  @override
  String netApprox(String amount) {
    return '합계 ≈ $amount';
  }

  @override
  String memberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '멤버 $count명',
    );
    return '$_temp0';
  }

  @override
  String youOweAmount(String amount) {
    return '$amount 갚을 돈';
  }

  @override
  String youAreOwedAmount(String amount) {
    return '$amount 받을 돈';
  }

  @override
  String youOweAmountLine(String amount) {
    return '$amount 갚을 돈';
  }

  @override
  String youAreOwedAmountLine(String amount) {
    return '$amount 받을 돈';
  }

  @override
  String get createGroupNeedsConnection => '그룹을 만들려면 인터넷 연결이 필요해요.';

  @override
  String get groupName => '그룹 이름';

  @override
  String get yourNameInGroup => '이 그룹에서 내 이름';

  @override
  String get defaultCurrency => '기본 통화';

  @override
  String get create => '만들기';

  @override
  String get noGroupOrFriendForCode => '이 코드에 해당하는 그룹이나 친구가 없어요';

  @override
  String get joinNeedsConnection => '그룹에 참여하려면 인터넷 연결이 필요해요.';

  @override
  String get enterACode => '코드 입력';

  @override
  String get enterCodeHelp => '그룹 코드는 그룹 → 멤버에 있어요. 친구 코드는 친구 탭 → 친구 추가에 있어요.';

  @override
  String get pastedFromClipboard => '클립보드에서 붙여 넣었어요';

  @override
  String nameOnEvensies(String name) {
    return '$name · Evensies 사용 중';
  }

  @override
  String addAsFriend(String name) {
    return '$name님을 친구로 추가';
  }

  @override
  String addedYouAsFriend(String name) {
    return '$name님이 나를 친구로 추가했어요';
  }

  @override
  String get someoneAddedYouAsFriend => '누군가 나를 친구로 추가했어요';

  @override
  String groupPreview(String name, String members) {
    return '$name · $members';
  }

  @override
  String get continueButton => '계속';

  @override
  String wantsToSplit(String name) {
    return '$name님이 나와 지출을 나누고 싶어 해요';
  }

  @override
  String get joinGroup => '그룹 참여';

  @override
  String get inviteInvalid => '이 초대 링크는 더 이상 유효하지 않아요';

  @override
  String inviteFailed(String reason) {
    return '이 초대를 열 수 없어요: $reason';
  }

  @override
  String get friendInviteUsed => '이 친구 초대는 이미 사용됐어요';

  @override
  String get joinToSeeShared => '참여하면 함께한 지출을 보고 추가할 수 있어요.';

  @override
  String imName(String name) {
    return '제 이름은 $name';
  }

  @override
  String get join => '참여';

  @override
  String get whoAreYou => '누구세요?';

  @override
  String get newMemberName => '새 멤버 이름';

  @override
  String get insights => '통계';

  @override
  String get membersInvite => '멤버 및 초대';

  @override
  String get groupSettings => '그룹 설정';

  @override
  String get expenses => '지출';

  @override
  String get expenseFab => '지출';

  @override
  String get groupNotHere => '이 그룹은 이 기기에 없어요';

  @override
  String get groupNotHereNote => '그룹에서 나갔거나, 누군가 나를 제외했거나, 아직 동기화되지 않았어요.';

  @override
  String get backToGroups => '그룹으로 돌아가기';

  @override
  String get noExpensesYet => '아직 지출이 없어요';

  @override
  String get tapExpenseToAdd => '“지출”을 눌러 첫 지출을 추가하세요.';

  @override
  String tilePaidYou(String amount) {
    return '내가 $amount 냄';
  }

  @override
  String tilePaidName(String name, String amount) {
    return '$name님이 $amount 냄';
  }

  @override
  String tilePaidPeople(int count, String amount) {
    return '$count명이 $amount 냄';
  }

  @override
  String get tileRefundYou => '나에게 환불';

  @override
  String tileRefundName(String name) {
    return '$name에게 환불';
  }

  @override
  String tileRefundPeople(int count) {
    return '$count명에게 환불';
  }

  @override
  String get notInvolved => '관련 없음';

  @override
  String get allYours => '모두 내 몫';

  @override
  String get paidForYourself => '내 몫을 직접 냄';

  @override
  String youGetBack(String amount) {
    return '$amount 돌려받음';
  }

  @override
  String youLent(String amount) {
    return '$amount 빌려줌';
  }

  @override
  String youBorrowed(String amount) {
    return '$amount 빌림';
  }

  @override
  String get repeatsLabel => '반복';

  @override
  String hasReceipt(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '영수증 $count장',
    );
    return '$_temp0';
  }

  @override
  String get refund => '환불';

  @override
  String get notConverted => '환산 안 됨';

  @override
  String get pending => '대기 중';

  @override
  String approxTotalOwe(String amount) {
    return '모두 합쳐 ≈ $amount 갚을 돈';
  }

  @override
  String approxTotalOwed(String amount) {
    return '모두 합쳐 ≈ $amount 받을 돈';
  }

  @override
  String get approxTotalNote => '내 기본 통화, 최신 환율 기준';

  @override
  String nothingOwedIn(String currency) {
    return '$currency로는 갚을 돈이 없어요';
  }

  @override
  String get allSettled => '모두 정산됐어요';

  @override
  String get otherCurrenciesBelow => '다른 통화의 지출은 아래에 있어요.';

  @override
  String get nobodyOwes => '아무도 갚을 돈이 없어요.';

  @override
  String youPayNext(String amount) {
    return '다음엔 내가 낼 차례예요 (가장 많은 $amount 갚을 돈)';
  }

  @override
  String namePaysNext(String name, String amount) {
    return '다음엔 $name님이 낼 차례예요 (갚을 돈이 가장 많아요: $amount)';
  }

  @override
  String settleUpWaiting(int count) {
    return '정산하기 · $count건 대기';
  }

  @override
  String memberRemoved(String name) {
    return '$name (제외됨)';
  }

  @override
  String expensesWithoutRate(int count, String currency) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$currency 환율이 없는 지출 $count개',
    );
    return '$_temp0';
  }

  @override
  String expensesBadRate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '환산할 수 없는 환율의 지출 $count개',
    );
    return '$_temp0';
  }

  @override
  String paymentsIn(String currency) {
    return '$currency 송금';
  }

  @override
  String everyoneEvenIn(String currency) {
    return '$currency로는 모두 정산됨';
  }

  @override
  String convertTo(String currency) {
    return '$currency로 환산';
  }

  @override
  String get balanceSettled => '정산됨';

  @override
  String get balanceGetsBack => '받을 돈';

  @override
  String get balanceOwes => '갚을 돈';

  @override
  String convertedCount(int count, String currency) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '지출 $count개를 $currency로 환산했어요',
    );
    return '$_temp0';
  }

  @override
  String get noAutoRate => '자동 환율이 없어요. 직접 입력하세요.';

  @override
  String rateOf(String date) {
    return '$date 환율';
  }

  @override
  String rateOfOffline(String date) {
    return '오프라인 · $date 환율';
  }

  @override
  String amountCountExpenses(String amount, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '지출 $count개',
    );
    return '$amount · $_temp0';
  }

  @override
  String paymentsStayIn(String currency) {
    return '$currency 송금은 $currency로 남아요';
  }

  @override
  String rateLabel(String from, String to) {
    return '환율: 1 $from당 $to';
  }

  @override
  String get nothingLeftToConvert => '환산할 지출이 없어요';

  @override
  String get lookingUpRate => '환율을 찾는 중…';

  @override
  String get enterRateAbove0 => '0보다 큰 환율을 입력하세요';

  @override
  String convertExplain(String currency) {
    return '환율이 없는 모든 지출에 이 환율을 넣어서 $currency 잔액에 반영해요. 지출마다 환율을 다시 바꿀 수 있어요.';
  }

  @override
  String get nameField => '이름';

  @override
  String get cantChangeCurrency => '첫 지출이나 송금 후에는 바꿀 수 없어요';

  @override
  String get currencyUsedFor => '잔액과 송금에 쓰여요';

  @override
  String get splitting => '나누기';

  @override
  String get simplifyDebts => '빚 단순화';

  @override
  String get simplifyDebtsHelp =>
      '빚을 합쳐서 그룹에 필요한 송금 횟수를 줄여요. 각자의 합계는 그대로이고, 누가 누구에게 보내는지만 바뀌어요.';

  @override
  String get defaultSplit => '기본 나누기';

  @override
  String get splitStale => '더 이상 맞지 않아요 · 눌러서 고치기';

  @override
  String get membership => '멤버십';

  @override
  String get leaveGroup => '그룹 나가기';

  @override
  String get balanceSettledNote => '내 잔액이 정산됐어요';

  @override
  String get renameGroup => '그룹 이름 바꾸기';

  @override
  String leaveTitle(String name) {
    return '“$name”에서 나갈까요?';
  }

  @override
  String get leaveMessage =>
      '이 그룹이 더 이상 보이지 않아요. 지난 지출은 다른 멤버에게 남아요. 다시 들어오려면 초대 코드를 받으세요.';

  @override
  String get leave => '나가기';

  @override
  String youLeft(String name) {
    return '“$name”에서 나갔어요';
  }

  @override
  String get splitEqualEveryone => '똑같이 · 모두';

  @override
  String splitPercentList(String list) {
    return '비율 · $list';
  }

  @override
  String splitSharesList(String list) {
    return '몫 · $list';
  }

  @override
  String percentValue(String value) {
    return '$value%';
  }

  @override
  String get defaultSplitHelp => '새 지출은 이 나누기로 시작해요. 지출마다 다시 바꿀 수 있어요.';

  @override
  String get useEqual => '똑같이 나누기';

  @override
  String get inviteCode => '초대 코드';

  @override
  String get inviteQrLabel => '초대 링크 QR 코드';

  @override
  String get inviteCodeHelp => '이 코드가 있으면 누구나 참여해서 자기 이름을 고를 수 있어요.';

  @override
  String inviteShareText(String group, String link, String code) {
    return 'Evensies의 내 그룹 “$group”에 참여하세요: $link\n또는 앱을 열고 코드를 입력하세요: $code';
  }

  @override
  String get rotateCode => '코드 바꾸기';

  @override
  String get members => '멤버';

  @override
  String get notJoinedYet => '아직 참여 안 함 — 초대 코드를 공유하세요';

  @override
  String get linked => '연결됨';

  @override
  String get addPlaceholder => '이름만으로 멤버 추가';

  @override
  String removeMemberTitle(String name) {
    return '$name님을 제외할까요?';
  }

  @override
  String get removeMemberMessage => '지난 지출과 잔액은 그룹에 남아요.';

  @override
  String removeMemberSeries(int count, String name, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$name님은 아직 반복 지출 $count개($names)에 포함돼 있어요. 가장 최근 지출을 수정할 때까지 $name님의 몫은 그대로예요.',
    );
    return '$_temp0';
  }

  @override
  String get addMember => '멤버 추가';

  @override
  String get rotateInviteTitle => '초대 코드를 바꿀까요?';

  @override
  String get rotateInviteMessage =>
      '지금 코드와 링크는 더 이상 쓸 수 없어요. 이미 참여한 사람은 영향을 받지 않아요.';

  @override
  String get rotate => '바꾸기';

  @override
  String get newInviteReady => '새 초대 코드가 준비됐어요';

  @override
  String get activityNeedsConnection => '활동에는 인터넷 연결이 필요해요';

  @override
  String get activityOfflineNote => '다시 온라인이 되면 최근 변경이 여기에 보여요.';

  @override
  String get noActivityYet => '아직 활동이 없어요';

  @override
  String get activityAllGroups => '내 그룹의 변경이 여기에 보여요.';

  @override
  String get activityThisGroup => '이 그룹의 변경이 여기에 보여요.';

  @override
  String get showingSaved => '저장된 활동이에요. 당겨서 새로 고치세요.';

  @override
  String get loadMore => '더 불러오기';

  @override
  String get earlier => '이전';

  @override
  String get today => '오늘';

  @override
  String get yesterday => '어제';

  @override
  String forDate(String date) {
    return '$date 분';
  }

  @override
  String get youCommented => '내가 댓글을 남겼어요';

  @override
  String nameCommented(String name) {
    return '$name님이 댓글을 남겼어요';
  }

  @override
  String restoredName(String name) {
    return '“$name” 지출을 되살렸어요';
  }

  @override
  String get paymentRestored => '송금을 되살렸어요';

  @override
  String get expenseNotHere => '이 지출은 이 기기에 없어요';

  @override
  String get deletedExpense => '삭제된 지출';

  @override
  String get expense => '지출';

  @override
  String seriesRepeats(String frequency) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': '매주 반복',
      'biweekly': '2주마다 반복',
      'monthly': '매월 반복',
      'yearly': '매년 반복',
      'other': '반복',
    });
    return '$_temp0';
  }

  @override
  String seriesRepeatsNext(String frequency, String date) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': '매주 반복 · 다음 $date',
      'biweekly': '2주마다 반복 · 다음 $date',
      'monthly': '매월 반복 · 다음 $date',
      'yearly': '매년 반복 · 다음 $date',
      'other': '반복 · 다음 $date',
    });
    return '$_temp0';
  }

  @override
  String seriesRepeatsNextAmount(String frequency, String amount, String date) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': '매주 반복 · 다음 $date에 $amount',
      'biweekly': '2주마다 반복 · 다음 $date에 $amount',
      'monthly': '매월 반복 · 다음 $date에 $amount',
      'yearly': '매년 반복 · 다음 $date에 $amount',
      'other': '반복 · 다음 $date에 $amount',
    });
    return '$_temp0';
  }

  @override
  String rateLine(String from, String rate, String to) {
    return '환율: 1 $from = $rate $to';
  }

  @override
  String notConvertedTo(String currency) {
    return '$currency로 환산 안 됨';
  }

  @override
  String get receivedSplitBack => '받은 사람과 돌려받을 몫';

  @override
  String get whoPaidOwes => '낸 사람과 갚을 사람';

  @override
  String get items => '항목';

  @override
  String get notes => '메모';

  @override
  String get receipts => '영수증';

  @override
  String get history => '기록';

  @override
  String get deleteExpenseTitle => '지출을 삭제할까요?';

  @override
  String get deleteExpenseMessage => '그룹의 모든 사람에게서 삭제돼요. 활동에서 되살릴 수 있어요.';

  @override
  String get deleteRepeatingTitle => '반복 지출을 삭제할까요?';

  @override
  String get deleteRepeatingMessage =>
      '그룹의 모든 사람에게서 삭제돼요. 활동에서 되살릴 수 있지만, 반복을 멈춘 시리즈는 다시 시작할 수 없어요. 이미 추가된 반복은 남아요.';

  @override
  String get deleteThisOne => '이것만 삭제';

  @override
  String get deleteAndStop => '삭제하고 반복 멈추기';

  @override
  String deletedAndStopped(String name) {
    return '“$name” 지출을 삭제하고 반복을 멈췄어요';
  }

  @override
  String deletedName(String name) {
    return '“$name” 지출을 삭제했어요';
  }

  @override
  String get movedToOtherGroup => '다른 그룹으로 옮겨졌어요';

  @override
  String get movedNote => '이제 그 그룹에 반영돼요. 댓글과 기록은 여기에 남아요.';

  @override
  String get expenseWasDeleted => '이 지출은 삭제됐어요';

  @override
  String get restoreToCount => '되살리면 다시 잔액에 반영돼요.';

  @override
  String get tax => '세금';

  @override
  String get tipService => '팁 또는 봉사료';

  @override
  String get discount => '할인';

  @override
  String youPaidOwe(String paid, String owe) {
    return '내가 $paid 냈고 $owe 갚을 몫이에요';
  }

  @override
  String youPaid(String amount) {
    return '내가 $amount 냈어요';
  }

  @override
  String youOwe(String amount) {
    return '내 몫은 $amount이에요';
  }

  @override
  String namePaidOwes(String name, String paid, String owe) {
    return '$name: $paid 냄 · $owe 몫';
  }

  @override
  String namePaid(String name, String amount) {
    return '$name: $amount 냄';
  }

  @override
  String nameOwes(String name, String amount) {
    return '$name: $amount 몫';
  }

  @override
  String youReceivedGetBack(String received, String back) {
    return '내가 $received 받았고 $back 돌려받아요';
  }

  @override
  String youReceived(String amount) {
    return '내가 $amount 받았어요';
  }

  @override
  String youGetBackLine(String amount) {
    return '내가 $amount 돌려받아요';
  }

  @override
  String nameReceivedGetsBack(String name, String received, String back) {
    return '$name: $received 받음 · $back 돌려받음';
  }

  @override
  String nameReceived(String name, String amount) {
    return '$name: $amount 받음';
  }

  @override
  String nameGetsBack(String name, String amount) {
    return '$name: $amount 돌려받음';
  }

  @override
  String get noHistoryYet => '아직 기록이 없어요.';

  @override
  String get historyOffline => '온라인이 되면 기록이 여기에 보여요.';

  @override
  String get showingSavedHistory => '저장된 기록이에요.';

  @override
  String get showMore => '더 보기';

  @override
  String get deleteCommentTitle => '댓글을 삭제할까요?';

  @override
  String get comments => '댓글';

  @override
  String get noCommentsYet => '아직 댓글이 없어요.';

  @override
  String get deleteComment => '댓글 삭제';

  @override
  String get addComment => '댓글 달기';

  @override
  String get send => '보내기';

  @override
  String get filterByCategory => '카테고리로 거르기';

  @override
  String get category => '카테고리';

  @override
  String get categoryAll => '전체';

  @override
  String get month => '월';

  @override
  String get searchUnavailable => '검색을 쓸 수 없어요';

  @override
  String get searchExpenses => '지출 검색';

  @override
  String get searchHelp => '설명, 메모, 댓글, 카테고리, 금액: “택시”, “공항”, “12.50”.';

  @override
  String get noMatches => '결과가 없어요';

  @override
  String get noMatchesHelp => '다른 단어로 찾거나 필터를 지워 보세요.';

  @override
  String expenseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '지출 $count개',
    );
    return '$_temp0';
  }

  @override
  String get searchAllGroups => '모든 그룹 검색';

  @override
  String searchGroup(String name) {
    return '$name 검색';
  }

  @override
  String get searchThisGroup => '이 그룹 검색';

  @override
  String get clear => '지우기';

  @override
  String get thisGroup => '이 그룹';

  @override
  String insightsError(String reason) {
    return '통계를 보여 줄 수 없어요: $reason';
  }

  @override
  String get nothingToShow => '아직 보여 줄 게 없어요';

  @override
  String get insightsEmptyHelp => '그룹에 지출이 생기면 합계와 차트가 나타나요.';

  @override
  String get allTime => '전체 기간';

  @override
  String get shareSummary => '요약 공유';

  @override
  String get printSummary => '요약 인쇄';

  @override
  String get previousMonth => '이전 달';

  @override
  String get nextMonth => '다음 달';

  @override
  String get byMonth => '월별';

  @override
  String get groupSegment => '그룹';

  @override
  String get mineSegment => '나';

  @override
  String get byCategory => '카테고리별';

  @override
  String get noExpensesPeriod => '이 기간에는 지출이 없어요.';

  @override
  String get byPerson => '사람별';

  @override
  String get nobodyPaidPeriod => '이 기간에 낸 사람도 갚을 사람도 없어요.';

  @override
  String keptUntilConverted(String currency, String group) {
    return '$group로 환산될 때까지 $currency로 남아요.';
  }

  @override
  String get totalSpent => '총 지출';

  @override
  String get yourShare => '내 몫';

  @override
  String get paymentsMade => '보낸 송금';

  @override
  String get paymentsReceived => '받은 송금';

  @override
  String get youPaidRow => '내가 낸 돈';

  @override
  String get balanceChange => '내 잔액 변화';

  @override
  String get paidLegend => '낸 돈';

  @override
  String get shareLegend => '몫';

  @override
  String paidShareLine(String paid, String share) {
    return '낸 돈 $paid · 몫 $share';
  }

  @override
  String get itemsGiveEveryone => '모든 항목에 사람을 지정하세요';

  @override
  String get itemsAddPrices => '세금이나 팁 전에 항목 가격을 입력하세요';

  @override
  String get itemsDiscountTooBig => '할인이 계산서보다 커요';

  @override
  String get itemsDontAddUp => '항목 합계가 맞지 않아요';

  @override
  String get adjustmentsDontFit => '조정 금액이 합계와 맞지 않아요';

  @override
  String get giveSomeoneShare => '누군가에게 몫을 주세요';

  @override
  String get checkNumbers => '숫자를 확인하세요';

  @override
  String get splitDoesntAddUp => '분할 금액이 합계와 맞지 않아요';

  @override
  String get addTheItems => '항목을 추가하세요';

  @override
  String get pickOnePerson => '한 명 이상 고르세요';

  @override
  String splitEquallyBetween(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count명이 똑같이 나눠요',
    );
    return '$_temp0';
  }

  @override
  String get allForOnePerson => '1명이 모두 부담';

  @override
  String splitEquallyEach(int count, String amount) {
    return '$count명이 똑같이 나눠요 · 1인당 $amount';
  }

  @override
  String get checkAmounts => '금액을 확인하세요';

  @override
  String get enterTotalFirst => '먼저 합계를 입력하세요';

  @override
  String remaining(String amount) {
    return '남음: $amount';
  }

  @override
  String overBy(String amount) {
    return '초과: $amount';
  }

  @override
  String get addsUp => '합계가 맞아요';

  @override
  String sharesInTotal(String count) {
    return '총 $count몫';
  }

  @override
  String get oneShareInTotal => '총 1몫';

  @override
  String get restSplitEqually => '나머지는 똑같이 나눠요';

  @override
  String get byPercent => '비율로';

  @override
  String get byShares => '몫으로';

  @override
  String get byAdjustment => '조정: 누군가에게 더하거나 빼고, 나머지는 똑같이';

  @override
  String get modeEqual => '똑같이';

  @override
  String get modeExact => '금액';

  @override
  String get modeShares => '몫';

  @override
  String get byItem => '영수증 항목별';

  @override
  String get adjustmentHelp => '누군가에게 금액을 더하거나 빼요. 나머지는 똑같이 나눠요.';

  @override
  String get noMembers => '멤버가 없어요';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '항목 $count개',
    );
    return '$_temp0';
  }

  @override
  String get addAnItem => '항목을 추가하세요';

  @override
  String atMostItems(int max) {
    return '항목은 최대 $max개';
  }

  @override
  String get giveItemName => '모든 항목에 이름을 붙이세요';

  @override
  String get itemNameTooLong => '항목 이름이 너무 길어요';

  @override
  String get addItem => '항목 추가';

  @override
  String get giveRestToEveryone => '나머지는 모두에게';

  @override
  String get subtotal => '소계';

  @override
  String get total => '합계';

  @override
  String receiptSays(String printed, String difference) {
    return '영수증 합계 $printed · 항목과 $difference 차이';
  }

  @override
  String get eachPerson => '사람별';

  @override
  String itemsWithoutPerson(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '사람이 없는 항목 $count개',
    );
    return '$_temp0';
  }

  @override
  String get itemHint => '항목';

  @override
  String memberLeft(String name) {
    return '$name (나감)';
  }

  @override
  String get whoHadThis => '누가 먹었나요?';

  @override
  String get defaultSplitStartsEqual => '그룹의 기본 나누기가 더 이상 맞지 않아서 똑같이 나누기로 시작해요';

  @override
  String leftToAssign(String amount) {
    return '$amount 남음';
  }

  @override
  String get itemsTotal => '항목의 합계';

  @override
  String get newExpense => '새 지출';

  @override
  String get editExpense => '지출 수정';

  @override
  String get scanReceipt => '영수증 스캔';

  @override
  String get rateAboveZeroOrEmpty => '0보다 큰 환율을 입력하거나 비워 두세요';

  @override
  String useAutoRate(String rate, String source) {
    return '자동 환율 사용: $rate ($source)';
  }

  @override
  String get description => '설명';

  @override
  String get receivedBy => '받은 사람';

  @override
  String get paidBy => '낸 사람';

  @override
  String get severalPeople => '여러 명';

  @override
  String get when => '날짜';

  @override
  String get refundTooltip => '돌려받은 돈, 예: 호텔이 돌려준 보증금';

  @override
  String get splitBackTo => '돌려줄 사람';

  @override
  String get split => '나누기';

  @override
  String theyOweFull(String name) {
    return '$name님이 전액 부담';
  }

  @override
  String iOweFull(String name) {
    return '내가 $name에게 전액 부담';
  }

  @override
  String get repeat => '반복';

  @override
  String editLatestRepeat(String date) {
    return '앞으로의 반복을 바꾸려면 가장 최근 지출($date)을 수정하세요';
  }

  @override
  String get stopsRepeating => '반복을 멈춰요. 이미 추가된 반복은 남아요.';

  @override
  String nextRepeat(String date) {
    return '다음: $date';
  }

  @override
  String get alsoChangeFuture => '앞으로의 반복도 바꾸기';

  @override
  String get futureFields => '금액, 나누기, 낸 사람, 설명, 카테고리, 메모';

  @override
  String get onlyThisOne => '이것만 바뀌어요';

  @override
  String get addPhoto => '사진 추가';

  @override
  String maxReceiptsNote(int max) {
    return '지출 하나에 영수증은 최대 $max장이에요';
  }

  @override
  String get scanAReceipt => '영수증 스캔';

  @override
  String receiptLooksLike(String currency) {
    return '이 영수증은 $currency 같아요';
  }

  @override
  String switchToCurrencyQuestion(String currency) {
    return '항목을 읽으려면 지출을 $currency로 바꿀까요?';
  }

  @override
  String switchTo(String currency) {
    return '$currency로 바꾸기';
  }

  @override
  String get couldntReadItems => '항목을 읽지 못했어요. 직접 입력해 주세요.';

  @override
  String withName(String name) {
    return '$name에서';
  }

  @override
  String movesTo(String name) {
    return '저장하면 이 그룹으로 옮겨져요: $name';
  }

  @override
  String fromName(String name) {
    return '$name에서';
  }

  @override
  String get dontMove => '옮기지 않기';

  @override
  String get onlyLinkedMove => '양쪽에 모두 있는 Evensies 사용자만 옮길 수 있어요';

  @override
  String get auto => '자동';

  @override
  String get noAutoRateForm => '자동 환율이 없어요. 직접 입력하거나 비워 두면 “환산 안 됨”에 남아요.';

  @override
  String get emptyNotConverted => '비워 두면 “환산 안 됨”에 남아요';

  @override
  String rateExplain(
    String from,
    String rate,
    String to,
    String inverse,
    String source,
  ) {
    return '1 $from = $rate $to (1 $to = $inverse $from) · $source';
  }

  @override
  String get yourRate => '직접 입력한 환율';
}
