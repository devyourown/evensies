// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'Evensies';

  @override
  String get cancel => 'キャンセル';

  @override
  String get delete => '削除';

  @override
  String get remove => '取り除く';

  @override
  String get save => '保存';

  @override
  String get done => '完了';

  @override
  String get undo => '元に戻す';

  @override
  String get retry => '再試行';

  @override
  String get ok => 'OK';

  @override
  String get close => '閉じる';

  @override
  String get edit => '編集';

  @override
  String get add => '追加';

  @override
  String get offlineBanner => 'オフライン — 変更はあとで同期されます';

  @override
  String get tooLong => '長すぎます';

  @override
  String get allCurrencies => 'すべての通貨';

  @override
  String get errorUnexpected => '問題が発生しました。もう一度お試しください。';

  @override
  String get errorNetwork => 'オフラインです。あとでもう一度お試しください。';

  @override
  String get errorRateLimited => '試行回数が多すぎます。1分待ってからもう一度お試しください。';

  @override
  String get errorNotFound => 'もう存在しません。';

  @override
  String get errorForbidden => 'その操作はできません。';

  @override
  String get errorValidation => 'サーバーに拒否されました。';

  @override
  String get errorSumMismatch => '分担の合計が合いません。';

  @override
  String get errorPayersSumMismatch => '支払った人の合計が合いません。';

  @override
  String get errorNegativeAmount => '0未満の金額があります。';

  @override
  String get errorNegativeShare => '誰かの負担が0未満になります。';

  @override
  String get errorNegativeTotal => '合計が0未満になります。';

  @override
  String get errorZeroSubtotal => '税・チップ・割引の前に品目の価格を入力してください。';

  @override
  String get errorUnassignedItem => 'すべての品目に1人以上が必要です。';

  @override
  String get errorNoMembers => '割り勘する人を1人以上選んでください。';

  @override
  String get errorInvalidInput => '数値を確認してください。';

  @override
  String get errorBadRate => '為替レートは0より大きくしてください。';

  @override
  String get errorUnknownMember => 'グループにいない人が含まれています。';

  @override
  String get errorUnknownCurrency => 'この通貨には対応していません。';

  @override
  String get errorMemberTaken => 'そのメンバーはすでに選ばれています。';

  @override
  String get errorLimitExceeded => '上限に達しました。';

  @override
  String get errorTooLarge => '写真が大きすぎます。';

  @override
  String get errorNotJpeg => 'JPEG の写真を選んでください';

  @override
  String get errorFxUnavailable => '現在、為替レートを取得できません。';

  @override
  String get errorImportFailed => 'このファイルを読み込めませんでした。';

  @override
  String get errorAuthNotConfigured => 'このサーバーではその方法でサインインできません。';

  @override
  String get errorDuplicate => 'すでに存在します。';

  @override
  String errorGeneric(String code) {
    return '問題が発生しました（$code）。';
  }

  @override
  String rejectedReceipt(String name, String reason) {
    return '「$name」のレシートを保存できませんでした: $reason';
  }

  @override
  String rejectedReceiptUnnamed(String reason) {
    return '支出のレシートを保存できませんでした: $reason';
  }

  @override
  String rejectedReceiptRemove(String name, String reason) {
    return '「$name」からのレシート削除を保存できませんでした: $reason';
  }

  @override
  String rejectedReceiptRemoveUnnamed(String reason) {
    return '支出からのレシート削除を保存できませんでした: $reason';
  }

  @override
  String rejectedRepeating(String name, String reason) {
    return '「$name」の繰り返しを保存できませんでした: $reason';
  }

  @override
  String rejectedRepeatingUnnamed(String reason) {
    return '繰り返しの支出を保存できませんでした: $reason';
  }

  @override
  String rejectedSeriesChange(String name, String reason) {
    return '今後の「$name」の変更を保存できませんでした: $reason';
  }

  @override
  String rejectedSeriesChangeUnnamed(String reason) {
    return '繰り返しの支出の変更を保存できませんでした: $reason';
  }

  @override
  String rejectedSeriesStop(String name, String reason) {
    return '「$name」の繰り返し停止を保存できませんでした: $reason';
  }

  @override
  String rejectedSeriesStopUnnamed(String reason) {
    return '繰り返しの支出の停止を保存できませんでした: $reason';
  }

  @override
  String rejectedSavedNoRepeat(String name, String reason) {
    return '「$name」は保存されましたが、繰り返されません: $reason';
  }

  @override
  String rejectedPaymentRestore(String reason) {
    return '支払いの復元を保存できませんでした: $reason';
  }

  @override
  String rejectedNewExpense(String name, String reason) {
    return '新しい支出「$name」を保存できませんでした: $reason';
  }

  @override
  String rejectedNewExpenseUnnamed(String reason) {
    return '新しい支出を保存できませんでした: $reason';
  }

  @override
  String rejectedExpenseChange(String name, String reason) {
    return '「$name」の変更を保存できませんでした: $reason';
  }

  @override
  String rejectedExpenseChangeUnnamed(String reason) {
    return '支出の変更を保存できませんでした: $reason';
  }

  @override
  String rejectedExpenseDelete(String name, String reason) {
    return '「$name」の削除を保存できませんでした: $reason';
  }

  @override
  String rejectedExpenseDeleteUnnamed(String reason) {
    return '支出の削除を保存できませんでした: $reason';
  }

  @override
  String rejectedExpenseRestore(String name, String reason) {
    return '「$name」の復元を保存できませんでした: $reason';
  }

  @override
  String rejectedExpenseRestoreUnnamed(String reason) {
    return '支出の復元を保存できませんでした: $reason';
  }

  @override
  String rejectedComment(String name, String reason) {
    return '「$name」へのコメントを保存できませんでした: $reason';
  }

  @override
  String rejectedCommentUnnamed(String reason) {
    return '支出へのコメントを保存できませんでした: $reason';
  }

  @override
  String rejectedPaymentComment(String reason) {
    return '支払いへのコメントを保存できませんでした: $reason';
  }

  @override
  String rejectedCommentDelete(String reason) {
    return 'コメントの削除を保存できませんでした: $reason';
  }

  @override
  String rejectedPayment(String reason) {
    return '支払いを保存できませんでした: $reason';
  }

  @override
  String rejectedPaymentDelete(String reason) {
    return '支払いの削除を保存できませんでした: $reason';
  }

  @override
  String rejectedPaymentConfirm(String reason) {
    return '支払いの確認を保存できませんでした: $reason';
  }

  @override
  String rejectedGroupSettings(String reason) {
    return 'グループ設定の変更を保存できませんでした: $reason';
  }

  @override
  String rejectedMemberAdd(String name, String reason) {
    return '$name の追加を保存できませんでした: $reason';
  }

  @override
  String rejectedMemberAddUnnamed(String reason) {
    return 'メンバーの追加を保存できませんでした: $reason';
  }

  @override
  String rejectedMemberRemove(String reason) {
    return 'メンバーの削除を保存できませんでした: $reason';
  }

  @override
  String rejectedOther(String reason) {
    return '変更を保存できませんでした: $reason';
  }

  @override
  String get reasonReceiptLimit => '1つの支出に付けられるレシートは10枚までです';

  @override
  String get reasonSeriesLimit => '1つのグループの繰り返しの支出は100件までです';

  @override
  String get reasonNotUploaded => '写真がアップロードされませんでした';

  @override
  String get reasonSumMismatch => '分担の合計が合いません';

  @override
  String get reasonPayersSumMismatch => '支払った人の合計が合いません';

  @override
  String get reasonNegativeAmount => '0未満の金額があります';

  @override
  String get reasonUnknownMember => 'グループにいない人が含まれています';

  @override
  String get reasonUnknownCurrency => 'この通貨には対応していません';

  @override
  String get reasonMemberTaken => 'そのメンバーはすでに選ばれています';

  @override
  String get reasonGroupFull => 'グループが満員です';

  @override
  String get reasonForbidden => 'その変更はできません';

  @override
  String get reasonRefused => 'サーバーに拒否されました';

  @override
  String leaveOwe(String amount) {
    return '$amount の借りがあります · 先に精算してください';
  }

  @override
  String leaveOweIn(String amount, String currency) {
    return '$amount の借りがあります · 先に $currency で精算してください';
  }

  @override
  String leaveOwed(String amount) {
    return '$amount を受け取る予定です · 先に精算してください';
  }

  @override
  String leaveOwedIn(String amount, String currency) {
    return '$amount を受け取る予定です · 先に $currency で精算してください';
  }

  @override
  String leaveSeries(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'まだ $count 件の繰り返しの支出（$names）に含まれています · 先に最新のものを編集するか、繰り返しを止めてください',
    );
    return '$_temp0';
  }

  @override
  String seriesNamesMore(String names, int count) {
    return '$names ほか $count 件';
  }

  @override
  String get seriesUnnamed => '支出';

  @override
  String get listJoiner => '、';

  @override
  String get repeatNever => 'しない';

  @override
  String get repeatWeekly => '毎週';

  @override
  String get repeatBiweekly => '2週間ごと';

  @override
  String get repeatMonthly => '毎月';

  @override
  String get repeatYearly => '毎年';

  @override
  String summaryNotConverted(String currency) {
    return '換算されていません · $currency';
  }

  @override
  String summaryTotalSpent(String amount) {
    return '支出合計: $amount';
  }

  @override
  String summaryPaidShare(String paid, String share) {
    return 'あなたの支払い: $paid · あなたの負担: $share';
  }

  @override
  String summaryPayments(String made, String received) {
    return '送った支払い: $made · 受け取った支払い: $received';
  }

  @override
  String summaryTopCategories(String list) {
    return '上位カテゴリ: $list';
  }

  @override
  String get summaryBalancesToday => '今日の残高';

  @override
  String summaryGetsBack(String name, String amount) {
    return '$name の受け取り $amount';
  }

  @override
  String summaryOwes(String name, String amount) {
    return '$name の支払い $amount';
  }

  @override
  String get summaryFooter => 'Evensies から共有';

  @override
  String get koreanBank => '韓国の銀行口座';

  @override
  String requestText(String amount, String group) {
    return 'Evensies の $group で、私に $amount の支払いをお願いします。';
  }

  @override
  String requestTextWays(String amount, String group, String ways) {
    return 'Evensies の $group で、私に $amount の支払いをお願いします。支払い方法: $ways';
  }

  @override
  String get requestNoGroup => '私たちの共通の支出';

  @override
  String get leaveSyncing => 'まだ同期中です。少し待ってからもう一度お試しください。';

  @override
  String get leaveOffline => '退出するにはオンラインである必要があります';

  @override
  String get moveOffline => '移動できませんでした。オンラインのときにもう一度お試しください';

  @override
  String moveFailed(String reason) {
    return '移動できませんでした: $reason';
  }

  @override
  String get photoNoAccess => 'Evensies にアクセス権がありません。設定アプリで許可してください。';

  @override
  String get photoNoCamera => 'カメラを開けませんでした。';

  @override
  String get photoNoLibrary => '写真ライブラリを開けませんでした。';

  @override
  String get photoUnusable => 'この写真は使えませんでした。別の写真をお試しください。';

  @override
  String get methodErrorUsername => '英字、数字、. _ - のみ（40文字まで）';

  @override
  String methodErrorLinkPrefix(String prefix) {
    return '$prefix で始まる必要があります';
  }

  @override
  String get methodErrorTooLong => '200文字まで';

  @override
  String get methodErrorIban => '有効な IBAN ではありません';

  @override
  String get methodErrorHolder => '口座名義（1〜70文字）';

  @override
  String get methodErrorBic => 'BIC は8文字または11文字です';

  @override
  String get methodErrorKrAccount => '数字とハイフン、数字8〜20桁';

  @override
  String get methodErrorBank => '銀行名（1〜30文字）';

  @override
  String get methodErrorUnknownType => '不明な種類';

  @override
  String get methodErrorTooMany => '受け取り方法は8件まで、銀行の種類ごとに3件までです';

  @override
  String get bannerDismiss => '閉じる';

  @override
  String get bannerView => '見る';

  @override
  String get loginTagline => '友だちと支出を割り勘。広告もアップセルもありません。';

  @override
  String get loginApple => 'Apple で続ける';

  @override
  String get loginGoogle => 'Google で続ける';

  @override
  String get loginWebUnavailable => 'このサーバーはまだブラウザでのサインインに対応していません。';

  @override
  String get welcomeTitle => 'ようこそ';

  @override
  String get yourNameTitle => 'あなたの名前';

  @override
  String get nameQuestion => '友だちからは何と呼ばれたいですか？';

  @override
  String get nameExplain => 'ほかのメンバーに表示される名前です。';

  @override
  String get nameHelp => 'あなたのグループの人に表示されます。あとで設定から変更できます。';

  @override
  String get nameLabel => '名前';

  @override
  String get lockReason => 'Evensies のロックを解除';

  @override
  String get lockTitle => 'Evensies はロックされています';

  @override
  String get lockSubtitle => 'Face ID、Touch ID、指紋、またはデバイスのパスコードでロックを解除してください。';

  @override
  String get lockUnlock => 'ロックを解除';

  @override
  String get lockSignOutConfirm => 'サインアウトして、このデバイスのデータを消去しますか？グループはサーバーに残ります。';

  @override
  String get signOut => 'サインアウト';

  @override
  String get widgetOwed => '受け取る予定';

  @override
  String get widgetOwe => '支払う予定';

  @override
  String get widgetSignedOut => 'サインインすると残高が表示されます';

  @override
  String get widgetSettled => 'すべて精算済み';

  @override
  String widgetUpdated(String time) {
    return '$time に更新';
  }

  @override
  String get receiptAdd => 'レシートを追加';

  @override
  String get photoTake => '写真を撮る';

  @override
  String get photoChoose => 'ライブラリから選ぶ';

  @override
  String get photoChooseFile => 'ファイルを選ぶ';

  @override
  String get availableWhenOnline => 'オンライン時に表示できます';

  @override
  String get receiptPhoto => 'レシートの写真';

  @override
  String get receiptAvailableOnline => '写真はオンライン時に表示できます';

  @override
  String get receiptRemoveTitle => 'レシートを取り除きますか？';

  @override
  String get receiptRemoveMessage => 'グループの全員から取り除かれます。';

  @override
  String get receiptTitle => 'レシート';

  @override
  String receiptTitleOf(int index, int count) {
    return 'レシート $index/$count';
  }

  @override
  String get shareOrSave => '共有または保存';

  @override
  String get share => '共有';

  @override
  String get copiedToClipboard => 'クリップボードにコピーしました';

  @override
  String get settingsTitle => '設定';

  @override
  String get photoRemove => '写真を取り除く';

  @override
  String get photoNeedsConnection => '写真を変更するには接続が必要です。';

  @override
  String get photoTooMany => '写真の変更が多すぎます。1時間後にもう一度お試しください。';

  @override
  String get notifSaveFailed => '通知設定を保存できませんでした。接続を確認してください。';

  @override
  String get homeCurrencyNeedsConnection => '基本通貨を変更するには接続が必要です。';

  @override
  String get changePhoto => 'プロフィール写真を変更';

  @override
  String get yourNameTapToChange => 'あなたの名前 · タップして変更';

  @override
  String get waysToGetPaid => '受け取り方法';

  @override
  String get waysToGetPaidHint => 'PayPal、Wise、IBAN、銀行口座…';

  @override
  String get homeCurrency => '基本通貨';

  @override
  String get homeCurrencyFromRegion => '地域から設定 · 残高はこの通貨でも ≈ 表示されます';

  @override
  String get homeCurrencyPicked => '残高はこの通貨でも ≈ 表示されます';

  @override
  String get notifications => '通知';

  @override
  String get notifExpenses => '支出と支払い';

  @override
  String get notifComments => 'コメント';

  @override
  String get notifMembers => 'メンバーとグループの変更';

  @override
  String get notifReminders => '友だちからのリマインダー';

  @override
  String get notifNeedConnection => '通知設定には接続が必要です';

  @override
  String get notifOthersOnly => 'ほかの人による変更だけを通知します。';

  @override
  String get notifWebNote => '通知はスマートフォンに届きます。ブラウザは開いている間、1分ごとに更新されます。';

  @override
  String get exportImport => 'エクスポートとインポート';

  @override
  String get noGroupsToExport => 'エクスポートするグループがありません。';

  @override
  String get nonGroup => 'グループ外';

  @override
  String nonGroupWith(String name) {
    return 'グループ外 · $name';
  }

  @override
  String get exportJson => 'JSON をエクスポート';

  @override
  String get exportCsv => 'CSV をエクスポート';

  @override
  String get exportZip => 'レシート付き ZIP';

  @override
  String get importSplitwise => 'Splitwise の CSV をインポート';

  @override
  String importedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件の支出をインポートしました',
    );
    return '$_temp0';
  }

  @override
  String get server => 'サーバー';

  @override
  String get serverUrl => 'サーバー URL';

  @override
  String serverDefault(String url) {
    return 'デフォルト: $url';
  }

  @override
  String get serverSaved => 'サーバー URL を保存しました';

  @override
  String get account => 'アカウント';

  @override
  String get licenses => 'ライセンス';

  @override
  String get deleteAccount => 'アカウントを削除';

  @override
  String get signOutTitle => 'サインアウトしますか？';

  @override
  String get signOutMessage => 'このデバイスのローカルデータが消去されます。まだ同期されていない変更は失われます。';

  @override
  String get deleteAccountTitle => 'アカウントを削除しますか？';

  @override
  String get deleteAccountMessage =>
      'あなたのメンバー枠は仮メンバーになります。グループのデータはほかのメンバーに残ります。この操作は取り消せません。';

  @override
  String get language => '言語';

  @override
  String languageSystem(String language) {
    return 'システム（$language）';
  }

  @override
  String get appearance => '外観';

  @override
  String get appearanceSystem => 'システム';

  @override
  String get appearanceLight => 'ライト';

  @override
  String get appearanceDark => 'ダーク';

  @override
  String get security => 'セキュリティ';

  @override
  String get appLock => 'アプリロック';

  @override
  String get appLockHint =>
      'Face ID、Touch ID、または指紋。だめなときはデバイスのパスコード。1分離れるとロックされます。';

  @override
  String methodRemoveTitle(String method) {
    return '$method を取り除きますか？';
  }

  @override
  String get methodsOffline => '受け取り方法を編集するにはインターネットに接続してください。';

  @override
  String get methodsLoadFailed => '受け取り方法を読み込めませんでした。';

  @override
  String get methodsIntro =>
      'グループのメンバーがあなたにお金を返すときに表示され、ワンタップで支払えます。Evensies がお金を動かすことはありません。';

  @override
  String get methodsEmpty => 'まだ受け取り方法がありません。';

  @override
  String get blurbPaypal => 'PayPal.me リンク、金額入力済み';

  @override
  String get blurbWise => 'Wise Quick Pay リンク、金額入力済み';

  @override
  String get blurbVenmo => 'Venmo ユーザー名（米国）';

  @override
  String get blurbRevolut => 'Revolut.me ユーザー名';

  @override
  String get blurbKakaopay => 'KakaoPay 송금코드 リンク';

  @override
  String get blurbIban => '銀行振込（EUR は SEPA QR）';

  @override
  String get blurbKrBank => '韓国の銀行口座（Toss、銀行アプリ）';

  @override
  String get fieldPaypal => 'PayPal.me ユーザー名';

  @override
  String get fieldPaypalHint => 'PayPal.me のユーザー名（例: anna）';

  @override
  String get fieldRevolut => 'Revolut.me ユーザー名';

  @override
  String get fieldRevolutHint => 'Revolut.me のユーザー名（例: anna）';

  @override
  String get fieldVenmo => 'Venmo ユーザー名';

  @override
  String get fieldVenmoHint => '@ なしで（例: anna-rossi）';

  @override
  String get fieldWise => 'Wise Quick Pay リンク';

  @override
  String get fieldWiseHint =>
      'Wise で: Payments → Quick Pay → リンクをコピー（https://wise.com/pay/…）';

  @override
  String get fieldKakaopay => 'KakaoPay 송금코드 リンク';

  @override
  String get fieldKakaopayHint =>
      'KakaoPay で: 송금 → 송금코드 → リンクをコピー（https://qr.kakaopay.com/…）';

  @override
  String get fieldHolder => '口座名義';

  @override
  String get fieldHolderHint => '口座に記載どおりの名前';

  @override
  String get fieldIban => 'IBAN';

  @override
  String get fieldIbanHint => '例: DE89 3704 0044 0532 0130 00';

  @override
  String get fieldBic => 'BIC（任意）';

  @override
  String get fieldBicHint => '8文字または11文字';

  @override
  String get fieldBank => '銀行';

  @override
  String get fieldBankHint => '例: 신한은행、Toss Bank';

  @override
  String get fieldAccountNumber => '口座番号';

  @override
  String get fieldAccountNumberHint => '数字、ハイフンは任意';

  @override
  String amountCopied(String amount) {
    return '金額をコピーしました: $amount';
  }

  @override
  String couldNotOpen(String link) {
    return '$link を開けませんでした';
  }

  @override
  String get payOffline => 'オフライン: 支払い方法を表示できません';

  @override
  String get payLoading => '支払い方法を読み込み中…';

  @override
  String payAskToAdd(String name) {
    return '$name に受け取り方法の追加を頼んでください';
  }

  @override
  String payTitle(String name, String amount) {
    return '$name に $amount を支払う';
  }

  @override
  String get payScanQr => '銀行アプリでスキャン（SEPA QR）';

  @override
  String get payQrEurOnly => 'QR コードは EUR の振込でのみ利用できます。';

  @override
  String get bankLabel => '銀行';

  @override
  String get ibanLabel => 'IBAN';

  @override
  String get accountLabel => '口座';

  @override
  String get bicLabel => 'BIC';

  @override
  String get holderLabel => '名義';

  @override
  String get amountLabel => '金額';

  @override
  String get copyIban => 'IBAN をコピー';

  @override
  String get copyAccount => '口座をコピー';

  @override
  String get copyAmount => '金額をコピー';

  @override
  String get ibanCopied => 'IBAN をコピーしました';

  @override
  String get accountCopied => '口座をコピーしました';

  @override
  String get paymentUpdated => '支払いを更新しました';

  @override
  String paymentRecordedPending(String amount, String name) {
    return '$amount を記録しました。$name が確認します。';
  }

  @override
  String paymentRecordedPendingUnnamed(String amount) {
    return '$amount を記録しました。相手が確認します。';
  }

  @override
  String paymentRecorded(String amount) {
    return '$amount の支払いを記録しました';
  }

  @override
  String youSuffix(String name) {
    return '$name（あなた）';
  }

  @override
  String get recordPayment => '支払いを記録';

  @override
  String get editPayment => '支払いを編集';

  @override
  String get fromLabel => '支払った人';

  @override
  String get toLabel => '受け取った人';

  @override
  String get swap => '入れ替え';

  @override
  String get pickTwoPeople => '別々の2人を選んでください';

  @override
  String get commentsStayOld => 'コメントは元の支払いに残ります';

  @override
  String get recordPaymentButton => '支払いを記録';

  @override
  String get paymentNotHere => 'この支払いはこのデバイスにありません';

  @override
  String get notSyncedOrLeft => 'まだ同期されていないか、そのグループから退出しています。';

  @override
  String get someone => '不明なメンバー';

  @override
  String get paymentEdited => '編集された支払い';

  @override
  String get paymentDeleted => '削除された支払い';

  @override
  String get payment => '支払い';

  @override
  String get paymentWasEdited => 'この支払いは編集されました';

  @override
  String get paymentWasEditedNote => '代わりに編集後の支払いが計算されます。コメントはここに残ります。';

  @override
  String get paymentWasDeleted => 'この支払いは削除されました';

  @override
  String get paymentNotCounted => '残高には計算されません。';

  @override
  String get restore => '復元';

  @override
  String youPaidName(String name) {
    return 'あなたが $name に支払いました';
  }

  @override
  String namePaidYou(String name) {
    return '$name があなたに支払いました';
  }

  @override
  String namePaidName(String from, String to) {
    return '$from が $to に支払いました';
  }

  @override
  String paymentSaysSent(String name) {
    return '$name は送ったと言っています。届きましたか？';
  }

  @override
  String waitingForConfirm(String name) {
    return '$name の確認待ち';
  }

  @override
  String get notReceived => '届いていない';

  @override
  String get confirmReceived => '受け取りを確認';

  @override
  String get deletePaymentTitle => '支払いを削除しますか？';

  @override
  String get deletePaymentMessage => 'この支払いで精算された借りが元に戻ります。';

  @override
  String get paymentDeletedSnack => '支払いを削除しました';

  @override
  String get notReceivedTitle => '届いていませんか？';

  @override
  String notReceivedMessage(String name) {
    return '$name からの支払いが取り除かれ、借りが元に戻ります。';
  }

  @override
  String get paymentRemovedSnack => '支払いを取り除きました';

  @override
  String get recordAPayment => '支払いを記録';

  @override
  String get nothingToSettle => '精算するものはありません';

  @override
  String get everyoneEven => '全員の精算が済んでいます。';

  @override
  String get waitingForConfirmation => '確認待ち';

  @override
  String get debtsAsRecorded => '記録どおりの借り · 借りの簡略化はオフ';

  @override
  String transfersSettleEverything(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 回の送金ですべて精算できます',
    );
    return '$_temp0';
  }

  @override
  String transfersSettleBalance(int count, String currency) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 回の送金で $currency の残高を精算できます',
    );
    return '$_temp0';
  }

  @override
  String notConvertedSettlesIn(String currency) {
    return '換算されていません · $currency · $currency で精算';
  }

  @override
  String get convert => '換算';

  @override
  String get settleUp => '精算する';

  @override
  String saysTheySent(String name, String amount) {
    return '$name は $amount を送ったと言っています';
  }

  @override
  String waitingToConfirmAmount(String name, String amount) {
    return '$name が $amount を確認するのを待っています';
  }

  @override
  String get you => 'あなた';

  @override
  String get request => '請求';

  @override
  String get iveSentIt => '送りました';

  @override
  String get markAsPaid => '支払い済みにする';

  @override
  String markedAsSent(String name) {
    return '送金済みにしました。$name が確認します。';
  }

  @override
  String approx(String amount) {
    return '≈ $amount';
  }

  @override
  String friendOwesYou(String name, String amount) {
    return '$name があなたに $amount を返す予定です';
  }

  @override
  String friendYouOwe(String name, String amount) {
    return 'あなたが $name に $amount を返す予定です';
  }

  @override
  String friendYouOweLine(String name, String amount) {
    return 'あなたが $name に $amount を返す予定です';
  }

  @override
  String noSharedGroup(String name) {
    return '$name とはもう共通のグループがありません。支出を追加するには友だちリンクを送ってください。';
  }

  @override
  String get shareFriendLink => '友だちリンクを共有';

  @override
  String firstExpenseNeedsConnection(String name) {
    return '$name との最初の支出には接続が必要です。';
  }

  @override
  String reminderSent(String name) {
    return '$name にリマインダーを送りました';
  }

  @override
  String remindTomorrow(String name) {
    return '$name にはまた明日リマインドできます';
  }

  @override
  String remindNothingOwed(String name) {
    return '$name があなたに返すものはありません';
  }

  @override
  String get remindNeedsConnection => 'リマインダーを送るには接続が必要です。';

  @override
  String amountsAnd(String a, String b) {
    return '$a と $b';
  }

  @override
  String inviteFriendText(String link) {
    return '支出を割り勘できるように Evensies であなたを追加しました。参加してください: $link';
  }

  @override
  String get personNotHere => 'この人はこのデバイスにいません';

  @override
  String get personNotHereNote => 'まだ同期されていないか、もう共通のグループがありません。';

  @override
  String get more => 'その他';

  @override
  String get exportNonGroupCsv => 'グループ外の支出をエクスポート（CSV）';

  @override
  String get exportNonGroupJson => 'グループ外の支出をエクスポート（JSON）';

  @override
  String get exportNonGroupZip => 'グループ外の支出をエクスポート（レシート付き ZIP）';

  @override
  String get notOnEvensies => 'まだ Evensies を使っていません';

  @override
  String get allSettledUp => 'すべて精算済み';

  @override
  String get remind => 'リマインド';

  @override
  String get invite => '招待';

  @override
  String get balances => '残高';

  @override
  String get expensesAndPayments => '支出と支払い';

  @override
  String get nothingTogetherYet => 'まだ一緒の記録はありません。下から支出を追加してください。';

  @override
  String get addExpense => '支出を追加';

  @override
  String personOwesYou(String amount) {
    return '$amount を受け取る予定';
  }

  @override
  String personYouOwe(String amount) {
    return '$amount を支払う予定';
  }

  @override
  String get personSettledUp => '精算済み';

  @override
  String recordedInGroups(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 個のグループに記録しました',
    );
    return '$_temp0';
  }

  @override
  String get markAsReceived => '受け取り済みにする';

  @override
  String get clearBothSides => '双方を相殺';

  @override
  String evenIn(String currency) {
    return '$currency では精算済み';
  }

  @override
  String linePayThem(String group, String name, String amount) {
    return '$group: あなたが $name に $amount';
  }

  @override
  String lineTheyPay(String group, String name, String amount) {
    return '$group: $name があなたに $amount';
  }

  @override
  String get noMoneyMoves => 'お金は動きません: 双方を精算済みとして記録します。';

  @override
  String convertIn(String group) {
    return '$group で換算';
  }

  @override
  String settleUpWith(String name) {
    return '$name と精算';
  }

  @override
  String nothingToSettleWith(String name) {
    return '$name と精算するものはありません';
  }

  @override
  String settleWithIntro(String name) {
    return 'あなたと $name のすべてを通貨ごとに表示します。記録すると各グループに支払いが追加されます。';
  }

  @override
  String get searchFriendsGroups => '友だちとグループを検索';

  @override
  String get friends => '友だち';

  @override
  String get groups => 'グループ';

  @override
  String get noFriendsOrGroups => 'まだ友だちもグループもありません。';

  @override
  String nothingMatches(String query) {
    return '「$query」に一致するものはありません。';
  }

  @override
  String get addExpenseWithWhom => '支出を追加 · 誰と？';

  @override
  String friendLinkShare(String link, String code) {
    return 'Evensies で私を追加して、支出を割り勘しましょう: $link\nまたは私のコード $code を入力してください';
  }

  @override
  String get friendLinkNeedsConnection => '友だちリンクを共有するには接続が必要です。';

  @override
  String get selfFriend => 'あなた自身のコードです';

  @override
  String get noOneForCode => 'このコードの人が見つかりません';

  @override
  String get addFriendNeedsConnection => '友だちを追加するには接続が必要です。';

  @override
  String get newFriendCodeTitle => '新しい友だちコードを作りますか？';

  @override
  String get newFriendCodeMessage => '今のリンクとコードは使えなくなります。すでにいる友だちはそのままです。';

  @override
  String get newCode => '新しいコード';

  @override
  String get addAFriend => '友だちを追加';

  @override
  String get friendLinkOffline => '友だちリンクには接続が必要です';

  @override
  String get yourFriendCode => 'あなたの友だちコード';

  @override
  String get friendQrLabel => '友だちリンクの QR コード';

  @override
  String get friendCodeHelp => '友だちにスキャンしてもらうか、リンクを開くかコードを入力してもらいます。';

  @override
  String get shareLink => 'リンクを共有';

  @override
  String get codeCopied => 'コードをコピーしました';

  @override
  String get copyCode => 'コードをコピー';

  @override
  String get haveFriendCode => '友だちのコードをお持ちですか？';

  @override
  String get onEvensies => 'Evensies を利用中';

  @override
  String get notOnEvensiesSection => 'まだ Evensies を使っていない人';

  @override
  String get notOnEvensiesHelp => '今すぐ一緒に支出を追加して、あとで招待できます。';

  @override
  String atMostChars(int max) {
    return '$max 文字まで';
  }

  @override
  String addName(String name) {
    return '$name を追加';
  }

  @override
  String get search => '検索';

  @override
  String get activity => 'アクティビティ';

  @override
  String get newGroup => '新しいグループ';

  @override
  String get joinWithCode => 'コードで参加';

  @override
  String get filterAll => 'すべて';

  @override
  String get filterOwesMe => '受け取る予定';

  @override
  String get filterIOwe => '支払う予定';

  @override
  String settledUpCount(int count) {
    return '精算済み（$count）';
  }

  @override
  String get nobodyOwesYou => 'あなたに返す人はいません';

  @override
  String get youOweNothing => '返すものはありません';

  @override
  String get nothingHereYet => 'まだ何もありません';

  @override
  String get noFriendsYet => 'まだ友だちがいません';

  @override
  String get noFriendsHelp => 'グループ外で割り勘するには友だちを追加してください。グループが同じ人もここに表示されます。';

  @override
  String get allSettledUpYou => 'すべて精算済みです';

  @override
  String youAreOwedList(String amounts) {
    return '受け取る予定 $amounts';
  }

  @override
  String youOweList(String amounts) {
    return '支払う予定 $amounts';
  }

  @override
  String get notOnEvensiesLower => 'まだ Evensies を使っていません';

  @override
  String get noGroupsYet => 'まだグループがありません';

  @override
  String get noGroupsHelp => '旅行やシェアハウス用のグループを作るか、友だちの招待コードでグループに参加してください。';

  @override
  String get createGroup => 'グループを作成';

  @override
  String get settledUp => '精算済み';

  @override
  String netApprox(String amount) {
    return '差し引き ≈ $amount';
  }

  @override
  String memberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'メンバー $count 人',
    );
    return '$_temp0';
  }

  @override
  String youOweAmount(String amount) {
    return '$amount を支払う予定';
  }

  @override
  String youAreOwedAmount(String amount) {
    return '$amount を受け取る予定';
  }

  @override
  String youOweAmountLine(String amount) {
    return '$amount を支払う予定';
  }

  @override
  String youAreOwedAmountLine(String amount) {
    return '$amount を受け取る予定';
  }

  @override
  String get createGroupNeedsConnection => 'グループを作るには接続が必要です。';

  @override
  String get groupName => 'グループ名';

  @override
  String get yourNameInGroup => 'このグループでのあなたの名前';

  @override
  String get defaultCurrency => 'デフォルトの通貨';

  @override
  String get create => '作成';

  @override
  String get noGroupOrFriendForCode => 'このコードのグループも友だちも見つかりません';

  @override
  String get joinNeedsConnection => 'グループに参加するには接続が必要です。';

  @override
  String get enterACode => 'コードを入力';

  @override
  String get enterCodeHelp =>
      'グループのコードはグループ → メンバーにあります。友だちのコードは相手の友だちタブ → 友だちを追加にあります。';

  @override
  String get pastedFromClipboard => 'クリップボードから貼り付けました';

  @override
  String nameOnEvensies(String name) {
    return '$name · Evensies を利用中';
  }

  @override
  String addAsFriend(String name) {
    return '$name を友だちに追加';
  }

  @override
  String addedYouAsFriend(String name) {
    return '$name があなたを友だちに追加しました';
  }

  @override
  String get someoneAddedYouAsFriend => '誰かがあなたを友だちに追加しました';

  @override
  String groupPreview(String name, String members) {
    return '$name · $members';
  }

  @override
  String get continueButton => '続ける';

  @override
  String wantsToSplit(String name) {
    return '$name があなたと支出を割り勘したいと言っています';
  }

  @override
  String get joinGroup => 'グループに参加';

  @override
  String get inviteInvalid => 'この招待リンクはもう無効です';

  @override
  String inviteFailed(String reason) {
    return 'この招待を開けませんでした: $reason';
  }

  @override
  String get friendInviteUsed => 'この友だち招待はすでに使われています';

  @override
  String get joinToSeeShared => '参加すると共通の支出を見たり追加したりできます。';

  @override
  String imName(String name) {
    return '私は $name です';
  }

  @override
  String get join => '参加';

  @override
  String get whoAreYou => 'あなたは誰ですか？';

  @override
  String get newMemberName => '新しいメンバーの名前';

  @override
  String get insights => '分析';

  @override
  String get membersInvite => 'メンバーと招待';

  @override
  String get groupSettings => 'グループ設定';

  @override
  String get expenses => '支出';

  @override
  String get expenseFab => '支出';

  @override
  String get groupNotHere => 'このグループはこのデバイスにありません';

  @override
  String get groupNotHereNote => '退出したか、誰かに削除されたか、まだ同期されていません。';

  @override
  String get backToGroups => 'グループに戻る';

  @override
  String get noExpensesYet => 'まだ支出がありません';

  @override
  String get tapExpenseToAdd => '「支出」をタップして最初の支出を追加してください。';

  @override
  String tilePaidYou(String amount) {
    return 'あなたが $amount を支払い';
  }

  @override
  String tilePaidName(String name, String amount) {
    return '$name が $amount を支払い';
  }

  @override
  String tilePaidPeople(int count, String amount) {
    return '$count 人が $amount を支払い';
  }

  @override
  String get tileRefundYou => 'あなたへの払い戻し';

  @override
  String tileRefundName(String name) {
    return '$name への払い戻し';
  }

  @override
  String tileRefundPeople(int count) {
    return '$count 人への払い戻し';
  }

  @override
  String get notInvolved => '関係なし';

  @override
  String get allYours => 'すべてあなたの分';

  @override
  String get paidForYourself => '自分の分を支払い';

  @override
  String youGetBack(String amount) {
    return '$amount が戻ります';
  }

  @override
  String youLent(String amount) {
    return '$amount を立て替え';
  }

  @override
  String youBorrowed(String amount) {
    return '$amount を立て替えてもらいました';
  }

  @override
  String get repeatsLabel => '繰り返し';

  @override
  String hasReceipt(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'レシート $count 枚',
    );
    return '$_temp0';
  }

  @override
  String get refund => '払い戻し';

  @override
  String get notConverted => '換算されていません';

  @override
  String get pending => '保留中';

  @override
  String approxTotalOwe(String amount) {
    return '合計で ≈ $amount を支払う予定です';
  }

  @override
  String approxTotalOwed(String amount) {
    return '合計で ≈ $amount を受け取る予定です';
  }

  @override
  String get approxTotalNote => '基本通貨、最新レートで換算';

  @override
  String nothingOwedIn(String currency) {
    return '$currency での借りはありません';
  }

  @override
  String get allSettled => 'すべて精算済み';

  @override
  String get otherCurrenciesBelow => 'ほかの通貨の支出は下にあります。';

  @override
  String get nobodyOwes => '誰にも借りはありません。';

  @override
  String youPayNext(String amount) {
    return '次はあなたが支払う番です（最も多い $amount を返す予定）';
  }

  @override
  String namePaysNext(String name, String amount) {
    return '次は $name が支払う番です（最も多い $amount を返す予定）';
  }

  @override
  String settleUpWaiting(int count) {
    return '精算する · 確認待ち $count 件';
  }

  @override
  String memberRemoved(String name) {
    return '$name（削除済み）';
  }

  @override
  String expensesWithoutRate(int count, String currency) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$currency へのレートがない支出 $count 件',
    );
    return '$_temp0';
  }

  @override
  String expensesBadRate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '換算できないレートの支出 $count 件',
    );
    return '$_temp0';
  }

  @override
  String paymentsIn(String currency) {
    return '$currency の支払い';
  }

  @override
  String everyoneEvenIn(String currency) {
    return '$currency では全員精算済み';
  }

  @override
  String convertTo(String currency) {
    return '$currency に換算';
  }

  @override
  String get balanceSettled => '精算済み';

  @override
  String get balanceGetsBack => '受け取り';

  @override
  String get balanceOwes => '支払い';

  @override
  String convertedCount(int count, String currency) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 件の支出を $currency に換算しました',
    );
    return '$_temp0';
  }

  @override
  String get noAutoRate => '自動レートがありません。入力してください。';

  @override
  String rateOf(String date) {
    return '$date のレート';
  }

  @override
  String rateOfOffline(String date) {
    return 'オフライン · $date のレート';
  }

  @override
  String amountCountExpenses(String amount, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '支出 $count 件',
    );
    return '$amount · $_temp0';
  }

  @override
  String paymentsStayIn(String currency) {
    return '$currency の支払いは $currency のままです';
  }

  @override
  String rateLabel(String from, String to) {
    return 'レート: 1 $from あたりの $to';
  }

  @override
  String get nothingLeftToConvert => '換算するものはありません';

  @override
  String get lookingUpRate => 'レートを検索中…';

  @override
  String get enterRateAbove0 => '0より大きいレートを入力してください';

  @override
  String convertExplain(String currency) {
    return 'レートのないすべての支出にこのレートを入れ、$currency の残高に計算されるようにします。支出ごとにレートは変更できます。';
  }

  @override
  String get nameField => '名前';

  @override
  String get cantChangeCurrency => '最初の支出または支払いのあとは変更できません';

  @override
  String get currencyUsedFor => '残高と支払いに使われます';

  @override
  String get splitting => '割り勘';

  @override
  String get simplifyDebts => '借りを簡略化';

  @override
  String get simplifyDebtsHelp =>
      '借りをまとめて、グループに必要な支払い回数を減らします。各自の合計は変わらず、誰が誰に払うかだけが変わります。';

  @override
  String get defaultSplit => 'デフォルトの割り方';

  @override
  String get splitStale => '合計が合わなくなりました · タップして修正';

  @override
  String get membership => 'メンバーシップ';

  @override
  String get leaveGroup => 'グループを退出';

  @override
  String get balanceSettledNote => 'あなたの残高は精算済みです';

  @override
  String get renameGroup => 'グループ名を変更';

  @override
  String leaveTitle(String name) {
    return '「$name」を退出しますか？';
  }

  @override
  String get leaveMessage =>
      'このグループは表示されなくなります。過去の支出はほかのメンバーに残ります。戻るには招待コードをもらってください。';

  @override
  String get leave => '退出';

  @override
  String youLeft(String name) {
    return '「$name」を退出しました';
  }

  @override
  String get splitEqualEveryone => '均等 · 全員';

  @override
  String splitPercentList(String list) {
    return '割合 · $list';
  }

  @override
  String splitSharesList(String list) {
    return '口数 · $list';
  }

  @override
  String percentValue(String value) {
    return '$value%';
  }

  @override
  String get defaultSplitHelp => '新しい支出はこの割り方で始まります。支出ごとに変更できます。';

  @override
  String get useEqual => '均等にする';

  @override
  String get inviteCode => '招待コード';

  @override
  String get inviteQrLabel => '招待リンクの QR コード';

  @override
  String get inviteCodeHelp => 'このコードがあれば誰でも参加して名前を選べます。';

  @override
  String inviteShareText(String group, String link, String code) {
    return 'Evensies のグループ「$group」に参加してください: $link\nまたはアプリを開いてコード $code を入力してください';
  }

  @override
  String get rotateCode => 'コードを変更';

  @override
  String get members => 'メンバー';

  @override
  String get notJoinedYet => '未参加 — 招待コードを共有してください';

  @override
  String get linked => '連携済み';

  @override
  String get addPlaceholder => '仮メンバーを追加';

  @override
  String removeMemberTitle(String name) {
    return '$name を削除しますか？';
  }

  @override
  String get removeMemberMessage => '過去の支出と残高はグループに残ります。';

  @override
  String removeMemberSeries(int count, String name, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$name はまだ $count 件の繰り返しの支出（$names）に含まれています。最新のものを編集するまで、$name の負担は残ります。',
    );
    return '$_temp0';
  }

  @override
  String get addMember => 'メンバーを追加';

  @override
  String get rotateInviteTitle => '招待コードを変更しますか？';

  @override
  String get rotateInviteMessage => '今のコードとリンクは使えなくなります。すでに参加している人には影響しません。';

  @override
  String get rotate => '変更';

  @override
  String get newInviteReady => '新しい招待コードの準備ができました';

  @override
  String get activityNeedsConnection => 'アクティビティには接続が必要です';

  @override
  String get activityOfflineNote => 'オンラインに戻ると最近の変更がここに表示されます。';

  @override
  String get noActivityYet => 'まだアクティビティはありません';

  @override
  String get activityAllGroups => 'あなたのグループの変更がここに表示されます。';

  @override
  String get activityThisGroup => 'このグループの変更がここに表示されます。';

  @override
  String get showingSaved => '保存済みのアクティビティです。引っ張って更新してください。';

  @override
  String get loadMore => 'さらに読み込む';

  @override
  String get earlier => '以前';

  @override
  String get today => '今日';

  @override
  String get yesterday => '昨日';

  @override
  String forDate(String date) {
    return '$date の分';
  }

  @override
  String get youCommented => 'あなたがコメントしました';

  @override
  String nameCommented(String name) {
    return '$name がコメントしました';
  }

  @override
  String restoredName(String name) {
    return '「$name」を復元しました';
  }

  @override
  String get paymentRestored => '支払いを復元しました';

  @override
  String get expenseNotHere => 'この支出はこのデバイスにありません';

  @override
  String get deletedExpense => '削除された支出';

  @override
  String get expense => '支出';

  @override
  String seriesRepeats(String frequency) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': '毎週繰り返し',
      'biweekly': '2週間ごとに繰り返し',
      'monthly': '毎月繰り返し',
      'yearly': '毎年繰り返し',
      'other': '繰り返し',
    });
    return '$_temp0';
  }

  @override
  String seriesRepeatsNext(String frequency, String date) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': '毎週繰り返し · 次回 $date',
      'biweekly': '2週間ごとに繰り返し · 次回 $date',
      'monthly': '毎月繰り返し · 次回 $date',
      'yearly': '毎年繰り返し · 次回 $date',
      'other': '繰り返し · 次回 $date',
    });
    return '$_temp0';
  }

  @override
  String seriesRepeatsNextAmount(String frequency, String amount, String date) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': '毎週繰り返し · 次回 $date に $amount',
      'biweekly': '2週間ごとに繰り返し · 次回 $date に $amount',
      'monthly': '毎月繰り返し · 次回 $date に $amount',
      'yearly': '毎年繰り返し · 次回 $date に $amount',
      'other': '繰り返し · 次回 $date に $amount',
    });
    return '$_temp0';
  }

  @override
  String rateLine(String from, String rate, String to) {
    return 'レート: 1 $from = $rate $to';
  }

  @override
  String notConvertedTo(String currency) {
    return '$currency に換算されていません';
  }

  @override
  String get receivedSplitBack => '受け取った人と払い戻しの分け方';

  @override
  String get whoPaidOwes => '支払った人と負担する人';

  @override
  String get items => '品目';

  @override
  String get notes => 'メモ';

  @override
  String get receipts => 'レシート';

  @override
  String get history => '履歴';

  @override
  String get deleteExpenseTitle => '支出を削除しますか？';

  @override
  String get deleteExpenseMessage => 'グループの全員から削除されます。アクティビティから復元できます。';

  @override
  String get deleteRepeatingTitle => '繰り返しの支出を削除しますか？';

  @override
  String get deleteRepeatingMessage =>
      'グループの全員から削除されます。アクティビティから復元できますが、止めた繰り返しは再開できません。すでに追加された分は残ります。';

  @override
  String get deleteThisOne => 'これだけ削除';

  @override
  String get deleteAndStop => '削除して繰り返しを止める';

  @override
  String deletedAndStopped(String name) {
    return '「$name」を削除し、繰り返しを止めました';
  }

  @override
  String deletedName(String name) {
    return '「$name」を削除しました';
  }

  @override
  String get movedToOtherGroup => '別のグループに移動しました';

  @override
  String get movedNote => '今は移動先で計算されます。コメントと履歴はここに残ります。';

  @override
  String get expenseWasDeleted => 'この支出は削除されました';

  @override
  String get restoreToCount => '復元すると、また残高に計算されます。';

  @override
  String get tax => '税';

  @override
  String get tipService => 'チップ・サービス料';

  @override
  String get discount => '割引';

  @override
  String youPaidOwe(String paid, String owe) {
    return 'あなたが $paid を支払い、$owe を負担';
  }

  @override
  String youPaid(String amount) {
    return 'あなたが $amount を支払いました';
  }

  @override
  String youOwe(String amount) {
    return 'あなたの負担は $amount です';
  }

  @override
  String namePaidOwes(String name, String paid, String owe) {
    return '$name: $paid を支払い、$owe を負担';
  }

  @override
  String namePaid(String name, String amount) {
    return '$name: $amount を支払い';
  }

  @override
  String nameOwes(String name, String amount) {
    return '$name: $amount を負担';
  }

  @override
  String youReceivedGetBack(String received, String back) {
    return 'あなたが $received を受け取り、$back が戻ります';
  }

  @override
  String youReceived(String amount) {
    return 'あなたが $amount を受け取りました';
  }

  @override
  String youGetBackLine(String amount) {
    return 'あなたに $amount が戻ります';
  }

  @override
  String nameReceivedGetsBack(String name, String received, String back) {
    return '$name: $received を受け取り、$back が戻る';
  }

  @override
  String nameReceived(String name, String amount) {
    return '$name: $amount を受け取り';
  }

  @override
  String nameGetsBack(String name, String amount) {
    return '$name: $amount が戻る';
  }

  @override
  String get noHistoryYet => 'まだ履歴はありません。';

  @override
  String get historyOffline => 'オンラインになると履歴がここに表示されます。';

  @override
  String get showingSavedHistory => '保存済みの履歴です。';

  @override
  String get showMore => 'さらに表示';

  @override
  String get deleteCommentTitle => 'コメントを削除しますか？';

  @override
  String get comments => 'コメント';

  @override
  String get noCommentsYet => 'まだコメントはありません。';

  @override
  String get deleteComment => 'コメントを削除';

  @override
  String get addComment => 'コメントを追加';

  @override
  String get send => '送信';

  @override
  String get filterByCategory => 'カテゴリで絞り込む';

  @override
  String get category => 'カテゴリ';

  @override
  String get categoryAll => 'すべて';

  @override
  String get month => '月';

  @override
  String get searchUnavailable => '検索を利用できません';

  @override
  String get searchExpenses => '支出を検索';

  @override
  String get searchHelp => '説明、メモ、コメント、カテゴリ、金額:「タクシー」「空港」「12.50」。';

  @override
  String get noMatches => '一致するものはありません';

  @override
  String get noMatchesHelp => '別の言葉を試すか、フィルタを外してください。';

  @override
  String expenseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '支出 $count 件',
    );
    return '$_temp0';
  }

  @override
  String get searchAllGroups => 'すべてのグループを検索';

  @override
  String searchGroup(String name) {
    return '$name を検索';
  }

  @override
  String get searchThisGroup => 'このグループを検索';

  @override
  String get clear => 'クリア';

  @override
  String get thisGroup => 'このグループ';

  @override
  String insightsError(String reason) {
    return '分析を表示できません: $reason';
  }

  @override
  String get nothingToShow => 'まだ表示するものはありません';

  @override
  String get insightsEmptyHelp => 'グループに支出ができると、合計とグラフが表示されます。';

  @override
  String get allTime => '全期間';

  @override
  String get shareSummary => '概要を共有';

  @override
  String get printSummary => '概要を印刷';

  @override
  String get previousMonth => '前の月';

  @override
  String get nextMonth => '次の月';

  @override
  String get byMonth => '月別';

  @override
  String get groupSegment => 'グループ';

  @override
  String get mineSegment => '自分';

  @override
  String get byCategory => 'カテゴリ別';

  @override
  String get noExpensesPeriod => 'この期間の支出はありません。';

  @override
  String get byPerson => '人別';

  @override
  String get nobodyPaidPeriod => 'この期間に支払った人も負担した人もいません。';

  @override
  String keptUntilConverted(String currency, String group) {
    return '$group に換算されるまで $currency のままです。';
  }

  @override
  String get totalSpent => '支出合計';

  @override
  String get yourShare => 'あなたの負担';

  @override
  String get paymentsMade => '送った支払い';

  @override
  String get paymentsReceived => '受け取った支払い';

  @override
  String get youPaidRow => 'あなたの支払い';

  @override
  String get balanceChange => 'あなたの残高の変化';

  @override
  String get paidLegend => '支払い';

  @override
  String get shareLegend => '負担';

  @override
  String paidShareLine(String paid, String share) {
    return '支払い $paid · 負担 $share';
  }

  @override
  String get itemsGiveEveryone => 'すべての品目に人を割り当ててください';

  @override
  String get itemsAddPrices => '税やチップの前に品目の価格を入力してください';

  @override
  String get itemsDiscountTooBig => '割引が会計より大きいです';

  @override
  String get itemsDontAddUp => '品目の合計が合いません';

  @override
  String get adjustmentsDontFit => '調整額が合計に収まりません';

  @override
  String get giveSomeoneShare => '誰かに負担を割り当ててください';

  @override
  String get checkNumbers => '数値を確認してください';

  @override
  String get splitDoesntAddUp => '分担の合計が合いません';

  @override
  String get addTheItems => '品目を追加してください';

  @override
  String get pickOnePerson => '1人以上選んでください';

  @override
  String splitEquallyBetween(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 人で均等に割り勘',
    );
    return '$_temp0';
  }

  @override
  String get allForOnePerson => '1人がすべて負担';

  @override
  String splitEquallyEach(int count, String amount) {
    return '$count 人で均等に割り勘 · 1人 $amount';
  }

  @override
  String get checkAmounts => '金額を確認してください';

  @override
  String get enterTotalFirst => '先に合計を入力してください';

  @override
  String remaining(String amount) {
    return '残り: $amount';
  }

  @override
  String overBy(String amount) {
    return '超過: $amount';
  }

  @override
  String get addsUp => '合計が合っています';

  @override
  String sharesInTotal(String count) {
    return '合計 $count 口';
  }

  @override
  String get oneShareInTotal => '合計 1 口';

  @override
  String get restSplitEqually => '残りは均等に割り勘';

  @override
  String get byPercent => '割合で';

  @override
  String get byShares => '口数で';

  @override
  String get byAdjustment => '調整: 誰かを多めや少なめにし、残りは均等';

  @override
  String get modeEqual => '均等';

  @override
  String get modeExact => '金額';

  @override
  String get modeShares => '口数';

  @override
  String get byItem => '品目ごと（レシートから）';

  @override
  String get adjustmentHelp => '誰かに金額を足したり引いたりします。残りは均等に割り勘します。';

  @override
  String get noMembers => 'メンバーがいません';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 品目',
    );
    return '$_temp0';
  }

  @override
  String get addAnItem => '品目を追加してください';

  @override
  String atMostItems(int max) {
    return '品目は $max 件まで';
  }

  @override
  String get giveItemName => 'すべての品目に名前を付けてください';

  @override
  String get itemNameTooLong => '品目名が長すぎます';

  @override
  String get addItem => '品目を追加';

  @override
  String get giveRestToEveryone => '残りを全員に';

  @override
  String get subtotal => '小計';

  @override
  String get total => '合計';

  @override
  String receiptSays(String printed, String difference) {
    return 'レシートの合計 $printed · 品目との差 $difference';
  }

  @override
  String get eachPerson => '1人ずつ';

  @override
  String itemsWithoutPerson(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '人が割り当てられていない品目 $count 件',
    );
    return '$_temp0';
  }

  @override
  String get itemHint => '品目';

  @override
  String memberLeft(String name) {
    return '$name（退出済み）';
  }

  @override
  String get whoHadThis => '誰の分ですか？';

  @override
  String get defaultSplitStartsEqual => 'グループのデフォルトの割り方の合計が合わなくなったので、均等から始めます';

  @override
  String leftToAssign(String amount) {
    return 'あと $amount を割り当て';
  }

  @override
  String get itemsTotal => '品目の合計';

  @override
  String get newExpense => '新しい支出';

  @override
  String get editExpense => '支出を編集';

  @override
  String get scanReceipt => 'レシートをスキャン';

  @override
  String get rateAboveZeroOrEmpty => '0より大きいレートを入力するか、空欄にしてください';

  @override
  String useAutoRate(String rate, String source) {
    return '自動レートを使う: $rate（$source）';
  }

  @override
  String get description => '説明';

  @override
  String get receivedBy => '受け取った人';

  @override
  String get paidBy => '支払った人';

  @override
  String get severalPeople => '複数人';

  @override
  String get when => '日付';

  @override
  String get refundTooltip => '戻ってきたお金（例: ホテルから返金された保証金）';

  @override
  String get splitBackTo => '払い戻しの分け方';

  @override
  String get split => '割り方';

  @override
  String theyOweFull(String name) {
    return '$name が全額負担';
  }

  @override
  String iOweFull(String name) {
    return '私が $name に全額負担';
  }

  @override
  String get repeat => '繰り返し';

  @override
  String editLatestRepeat(String date) {
    return '今後の繰り返しを変えるには最新のもの（$date）を編集してください';
  }

  @override
  String get stopsRepeating => '繰り返しを止めます。すでに追加された分は残ります。';

  @override
  String nextRepeat(String date) {
    return '次回: $date';
  }

  @override
  String get alsoChangeFuture => '今後の繰り返しも変更';

  @override
  String get futureFields => '金額、割り方、支払った人、説明、カテゴリ、メモ';

  @override
  String get onlyThisOne => 'これだけ変更されます';

  @override
  String get addPhoto => '写真を追加';

  @override
  String maxReceiptsNote(int max) {
    return '1つの支出に付けられるレシートは $max 枚までです';
  }

  @override
  String get scanAReceipt => 'レシートをスキャン';

  @override
  String receiptLooksLike(String currency) {
    return 'このレシートは $currency のようです';
  }

  @override
  String switchToCurrencyQuestion(String currency) {
    return '品目を読み取るために支出を $currency に切り替えますか？';
  }

  @override
  String switchTo(String currency) {
    return '$currency に切り替え';
  }

  @override
  String get couldntReadItems => '品目を読み取れませんでした。入力してください。';

  @override
  String withName(String name) {
    return '$name と';
  }

  @override
  String movesTo(String name) {
    return '保存すると $name に移動します';
  }

  @override
  String fromName(String name) {
    return '移動元: $name';
  }

  @override
  String get dontMove => '移動しない';

  @override
  String get onlyLinkedMove => '両方にいる Evensies ユーザーだけを移動できます';

  @override
  String get auto => '自動';

  @override
  String get noAutoRateForm => '自動レートがありません。入力するか、空欄にして「換算されていません」に残してください。';

  @override
  String get emptyNotConverted => '空欄: 「換算されていません」に残ります';

  @override
  String rateExplain(
    String from,
    String rate,
    String to,
    String inverse,
    String source,
  ) {
    return '1 $from = $rate $to（1 $to = $inverse $from）· $source';
  }

  @override
  String get yourRate => '入力したレート';

  @override
  String get loginEmail => 'メールで続ける';

  @override
  String get emailLoginTitle => 'メールでログイン';

  @override
  String get emailLoginIntro => '6桁のコードをメールでお送りします。パスワードは不要です。';

  @override
  String get emailLabel => 'メール';

  @override
  String get emailInvalid => '有効なメールアドレスを入力してください';

  @override
  String get sendCode => 'コードを送信';

  @override
  String codeSentTo(String email) {
    return '$email に送った6桁のコードを入力してください。有効期限は10分です。';
  }

  @override
  String get codeLabel => '6桁のコード';

  @override
  String get verifyCode => '続ける';

  @override
  String get resendCode => 'コードを再送信';

  @override
  String resendCodeIn(int seconds) {
    return '$seconds 秒後に再送信できます';
  }

  @override
  String get codeResent => '新しいコードを送りました。';

  @override
  String get useDifferentEmail => '別のメールアドレスを使う';

  @override
  String get codeCheckSpam => '届きませんか？迷惑メールフォルダを確認してください。';

  @override
  String get errorCodeInvalid => 'コードが違うか期限切れです。新しいコードを受け取ってください。';

  @override
  String get errorEmailNotConfigured => 'このサーバーはメールを送信しません。';

  @override
  String get errorEmailRejected => 'このアドレスはメールを受信できません。入力ミスがないか確認してください。';

  @override
  String get errorEmailTaken => 'このアドレスは別のアカウントで使われています。';

  @override
  String get errorEmailRequired => 'メールが唯一のログイン方法なので削除できません。';

  @override
  String get errorEmailUnavailable => '現在メールを送信できません。しばらくしてからもう一度お試しください。';

  @override
  String get emailSaved => 'メールアドレスを保存しました';

  @override
  String removeEmailTitle(String email) {
    return '$email を削除しますか？';
  }

  @override
  String get removeEmailMessage => 'メールのまとめやリマインダーは届かなくなり、このアドレスでログインできなくなります。';

  @override
  String get emailRemoved => 'メールアドレスを削除しました';

  @override
  String get emailNeedsConnection => 'メールアドレスを変更するには接続が必要です。';

  @override
  String get emailBouncedNote => 'このアドレス宛てのメールが届きません — 変更するか、もう一度確認してください';

  @override
  String get emailVerifiedNote => '確認済み · ほかのメンバーには表示されません';

  @override
  String get changeEmail => 'メールアドレスを変更';

  @override
  String get emailAccountHelp =>
      'ログインとメールのまとめに使います。ご本人のアドレスか確認するためにコードを送ります。ほかのメンバーには表示されません。';

  @override
  String get removeEmail => 'メールアドレスを削除';

  @override
  String get addEmail => 'メールアドレスを追加';

  @override
  String get addEmailHint => 'メールでログインし、まとめを受け取れます';

  @override
  String unblockedName(String name) {
    return '$name のブロックを解除しました';
  }

  @override
  String get blockNeedsConnection => 'ブロックするには接続が必要です。';

  @override
  String get blockedEmpty => 'ブロックしている人はいません。';

  @override
  String get blockedNeedsConnection => 'ブロックした人を表示するには接続が必要です';

  @override
  String get unblock => 'ブロックを解除';

  @override
  String get blockedPeople => 'ブロックした人';

  @override
  String get blockedHelp =>
      'ブロックした人はあなたを友だちに追加したりリマインダーを送ったりできず、その人の変更は通知やメールで届きません。共有グループと残高はそのままです。';

  @override
  String get deletedGroupsEmpty => '削除したグループはありません';

  @override
  String get deletedGroupsHelp => '復元すると、グループは中身ごと全員のもとに戻ります。';

  @override
  String get deletedGroups => '削除したグループ';

  @override
  String deletedGroupsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '復元できるグループ $count 件',
    );
    return '$_temp0';
  }

  @override
  String get exportNeedsConnection => 'エクスポートするには接続が必要です。';

  @override
  String get exportEverything => 'すべてエクスポート (JSON)';

  @override
  String get exportEverythingHint => 'プロフィール、受け取り方法、設定、すべてのグループ（削除したものも含む）';

  @override
  String get emailSummary => 'メールのまとめ';

  @override
  String digestChoice(String choice) {
    String _temp0 = intl.Intl.selectLogic(choice, {
      'auto': '自動',
      'daily': '毎日',
      'weekly': '毎週',
      'monthly': '毎月',
      'off': 'オフ',
      'other': '自動',
    });
    return '$_temp0';
  }

  @override
  String get digestAutoHelp => 'デバイスで通知を表示できないときは毎日、それ以外は毎月';

  @override
  String get digestAutoDaily => '自動 — 通知がオフなので毎日';

  @override
  String get digestAutoMonthly => '自動 — デバイスで通知を受け取れるので毎月';

  @override
  String get digestNoEmail => 'まとめを受け取るには、アカウントでメールアドレスを追加してください';

  @override
  String get helpReportProblem => '問題を報告・機能を提案';

  @override
  String get helpReportProblemHint => 'GitHub 上で、誰でも見られます';

  @override
  String get helpContact => 'メールで問い合わせる';

  @override
  String get privacyPolicy => 'プライバシーポリシー';

  @override
  String get helpFeedback => 'ヘルプとフィードバック';

  @override
  String get signOutEverywhere => 'すべてのデバイスでログアウト';

  @override
  String get signOutEverywhereTitle => 'すべてのデバイスでログアウトしますか？';

  @override
  String get signOutEverywhereMessage =>
      'このアカウントでログインしているすべてのスマートフォンとブラウザがログアウトします。このデバイスも含みます。グループはサーバーに残ります。';

  @override
  String get signOutEverywhereOffline => 'すべてのデバイスでログアウトするには接続が必要です。';

  @override
  String get deleteAccountExportTip => 'ヒント: 先にすべてエクスポートしておきましょう。';

  @override
  String get coverPhoto => 'カバー写真';

  @override
  String get coverPhotoHint => 'グループのヘッダーと一覧に表示されます。メンバーだけが見られます。';

  @override
  String get removeCover => 'カバーを削除';

  @override
  String get coverNeedsConnection => 'カバーを変更するには接続が必要です。';

  @override
  String get coverTooMany => 'カバーの変更が多すぎます。1時間後にもう一度お試しください。';

  @override
  String get deleteGroup => 'グループを削除';

  @override
  String get deleteGroupHint => '全員から削除 · どのメンバーでも復元できます';

  @override
  String deleteGroupTitle(String name) {
    return '「$name」を削除しますか？';
  }

  @override
  String get deleteGroupMessage =>
      '全員から削除されます。どのメンバーでも 設定 → 削除したグループ から復元できます。';

  @override
  String groupDeletedName(String name) {
    return '「$name」を削除しました';
  }

  @override
  String get groupDeletedBanner => 'このグループは削除されています';

  @override
  String get groupRestored => 'グループを復元しました';

  @override
  String get deleteFriend => '友だちを削除';

  @override
  String deleteFriendTitle(String name) {
    return '$name を削除しますか？';
  }

  @override
  String deleteFriendMessage(String name) {
    return '$name とのグループ外の支出が、二人とも削除されます。共有グループはそのままです。設定 → 削除したグループ から復元するか、$name をもう一度追加すると元に戻ります。';
  }

  @override
  String friendDeleted(String name) {
    return '$name を削除しました';
  }

  @override
  String get block => 'ブロック';

  @override
  String blockTitle(String name) {
    return '$name をブロックしますか？';
  }

  @override
  String blockMessage(String name) {
    return '$name はあなたを友だちに追加したりリマインダーを送ったりできなくなり、その変更は通知やメールで届かなくなります。共有グループと残高はそのままです。';
  }

  @override
  String blockedName(String name) {
    return '$name をブロックしました';
  }

  @override
  String get report => '報告…';

  @override
  String get reportSubject => 'Evensies への報告';

  @override
  String reportBody(String userId) {
    return 'ユーザー ID: $userId\n\n何がありましたか:\n';
  }

  @override
  String get inviteByEmail => 'メールで招待…';

  @override
  String get inviteEmailField => 'メール（任意）';

  @override
  String get inviteEmailHelp => '招待リンクをメールで送ります。この招待にだけ使います。';

  @override
  String inviteByEmailTitle(String name) {
    return '$name をメールで招待';
  }

  @override
  String inviteEmailSent(String email) {
    return '$email に招待を送りました';
  }

  @override
  String get inviteEmailOfflineAdded =>
      'メンバーを追加しました。メールでの招待には接続が必要です — メンバー一覧からもう一度お試しください。';

  @override
  String get inviteEmailOffline => 'メールで招待するには接続が必要です。';

  @override
  String get inviteEmailLimit => '今日送れるメールの上限に達しました — 代わりにリンクを共有してください。';

  @override
  String emailReminder(String choice) {
    return 'メールでリマインド: $choice';
  }

  @override
  String get remindNever => 'しない';

  @override
  String remindDaysBefore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 日前',
    );
    return '$_temp0';
  }

  @override
  String get blurbUpi => 'インド: Paytm、PhonePe、Google Pay などの UPI アプリ';

  @override
  String get fieldUpi => 'UPI ID';

  @override
  String get fieldUpiHint => '例: name@okicici';

  @override
  String get fieldUpiName => '名前（任意）';

  @override
  String get fieldUpiNameHint => '支払う人に表示されます';

  @override
  String get methodErrorUpi => 'name@bank のような UPI ID を入力してください';

  @override
  String get noUpiApp => 'UPI アプリが見つかりません。代わりに UPI ID と金額をコピーしてください。';

  @override
  String get upiIdLabel => 'UPI ID';

  @override
  String get copyUpiId => 'UPI ID をコピー';

  @override
  String get upiIdCopied => 'UPI ID をコピーしました';

  @override
  String get dashboard => 'ダッシュボード';

  @override
  String get allExpenses => 'すべての支出';

  @override
  String get groupBalances => 'グループの残高';

  @override
  String get yourBalance => 'あなたの残高';

  @override
  String get dashboardOwesYou => 'あなたに支払う人';

  @override
  String get dashboardYouOwe => 'あなたが支払う人';

  @override
  String get historyAndComments => '履歴とコメント';

  @override
  String get showEarlier => '以前の履歴を表示';

  @override
  String get settleUpFirst => '先に精算してください';

  @override
  String deleteFriendSettleFirst(String name) {
    return 'グループ外の支出を精算すると、$name を友達から削除できます。';
  }

  @override
  String get noMailApp => 'メールアプリが見つかりません。下の内容をコピーして、お使いのメールアプリから送ってください。';

  @override
  String get copyAddress => 'アドレスをコピー';

  @override
  String get copyMessage => '本文をコピー';

  @override
  String get browserNoStorage =>
      'このブラウザでは Evensies のデータを保存できません。別のブラウザか、プライベートではないウィンドウでお試しください。';

  @override
  String get browserOtherTab =>
      'Evensies はこのブラウザの別のタブですでに開いています。そのタブを使うか、閉じてからこのタブを再読み込みしてください。';

  @override
  String get loginReview => 'デモ用サインイン';

  @override
  String get loginReviewUsername => 'ユーザー名';

  @override
  String get loginReviewPassword => 'パスワード';

  @override
  String get loginReviewSubmit => 'サインイン';

  @override
  String get loginReviewWrong => 'ユーザー名またはパスワードが違います';
}
