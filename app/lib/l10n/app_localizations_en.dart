// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Evensies';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get remove => 'Remove';

  @override
  String get save => 'Save';

  @override
  String get done => 'Done';

  @override
  String get undo => 'Undo';

  @override
  String get retry => 'Retry';

  @override
  String get ok => 'OK';

  @override
  String get close => 'Close';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get offlineBanner => 'Offline — changes will sync later';

  @override
  String get tooLong => 'Too long';

  @override
  String get allCurrencies => 'All currencies';

  @override
  String get errorUnexpected => 'Something went wrong. Try again.';

  @override
  String get errorNetwork => 'You are offline. Try again later.';

  @override
  String get errorRateLimited => 'Too many tries. Wait a minute and try again.';

  @override
  String get errorNotFound => 'That doesn\'t exist any more.';

  @override
  String get errorForbidden => 'You\'re not allowed to do that.';

  @override
  String get errorValidation => 'The server refused it.';

  @override
  String get errorSumMismatch => 'The split doesn\'t add up.';

  @override
  String get errorPayersSumMismatch => 'The payers don\'t add up.';

  @override
  String get errorNegativeAmount => 'An amount is below zero.';

  @override
  String get errorNegativeShare => 'Someone\'s share would be below zero.';

  @override
  String get errorNegativeTotal => 'The total would be below zero.';

  @override
  String get errorZeroSubtotal =>
      'Add item prices before tax, tip or discount.';

  @override
  String get errorUnassignedItem => 'Every item needs at least one person.';

  @override
  String get errorNoMembers => 'Pick at least one person to split with.';

  @override
  String get errorInvalidInput => 'Check the numbers.';

  @override
  String get errorBadRate => 'The exchange rate must be above zero.';

  @override
  String get errorUnknownMember =>
      'It refers to someone who isn\'t in the group.';

  @override
  String get errorUnknownCurrency => 'The currency isn\'t supported.';

  @override
  String get errorMemberTaken => 'That member is already taken.';

  @override
  String get errorLimitExceeded => 'The limit is reached.';

  @override
  String get errorTooLarge => 'The photo is too large.';

  @override
  String get errorNotJpeg => 'Choose a JPEG photo';

  @override
  String get errorFxUnavailable =>
      'Exchange rates aren\'t available right now.';

  @override
  String get errorImportFailed => 'That file couldn\'t be imported.';

  @override
  String get errorAuthNotConfigured =>
      'This server can\'t sign you in that way.';

  @override
  String get errorDuplicate => 'That already exists.';

  @override
  String errorGeneric(String code) {
    return 'Something went wrong ($code).';
  }

  @override
  String rejectedReceipt(String name, String reason) {
    return 'Couldn\'t save the receipt on “$name”: $reason';
  }

  @override
  String rejectedReceiptUnnamed(String reason) {
    return 'Couldn\'t save the receipt on an expense: $reason';
  }

  @override
  String rejectedReceiptRemove(String name, String reason) {
    return 'Couldn\'t save removing a receipt from “$name”: $reason';
  }

  @override
  String rejectedReceiptRemoveUnnamed(String reason) {
    return 'Couldn\'t save removing a receipt from an expense: $reason';
  }

  @override
  String rejectedRepeating(String name, String reason) {
    return 'Couldn\'t save repeating “$name”: $reason';
  }

  @override
  String rejectedRepeatingUnnamed(String reason) {
    return 'Couldn\'t save a repeating expense: $reason';
  }

  @override
  String rejectedSeriesChange(String name, String reason) {
    return 'Couldn\'t save a change to future “$name”: $reason';
  }

  @override
  String rejectedSeriesChangeUnnamed(String reason) {
    return 'Couldn\'t save a change to a repeating expense: $reason';
  }

  @override
  String rejectedSeriesStop(String name, String reason) {
    return 'Couldn\'t save stopping “$name” from repeating: $reason';
  }

  @override
  String rejectedSeriesStopUnnamed(String reason) {
    return 'Couldn\'t save stopping a repeating expense: $reason';
  }

  @override
  String rejectedSavedNoRepeat(String name, String reason) {
    return '“$name” was saved but won\'t repeat: $reason';
  }

  @override
  String rejectedPaymentRestore(String reason) {
    return 'Couldn\'t save restoring a payment: $reason';
  }

  @override
  String rejectedNewExpense(String name, String reason) {
    return 'Couldn\'t save the new expense “$name”: $reason';
  }

  @override
  String rejectedNewExpenseUnnamed(String reason) {
    return 'Couldn\'t save a new expense: $reason';
  }

  @override
  String rejectedExpenseChange(String name, String reason) {
    return 'Couldn\'t save a change to “$name”: $reason';
  }

  @override
  String rejectedExpenseChangeUnnamed(String reason) {
    return 'Couldn\'t save a change to an expense: $reason';
  }

  @override
  String rejectedExpenseDelete(String name, String reason) {
    return 'Couldn\'t save deleting “$name”: $reason';
  }

  @override
  String rejectedExpenseDeleteUnnamed(String reason) {
    return 'Couldn\'t save deleting an expense: $reason';
  }

  @override
  String rejectedExpenseRestore(String name, String reason) {
    return 'Couldn\'t save restoring “$name”: $reason';
  }

  @override
  String rejectedExpenseRestoreUnnamed(String reason) {
    return 'Couldn\'t save restoring an expense: $reason';
  }

  @override
  String rejectedComment(String name, String reason) {
    return 'Couldn\'t save a comment on “$name”: $reason';
  }

  @override
  String rejectedCommentUnnamed(String reason) {
    return 'Couldn\'t save a comment on an expense: $reason';
  }

  @override
  String rejectedPaymentComment(String reason) {
    return 'Couldn\'t save a comment on a payment: $reason';
  }

  @override
  String rejectedCommentDelete(String reason) {
    return 'Couldn\'t save deleting a comment: $reason';
  }

  @override
  String rejectedPayment(String reason) {
    return 'Couldn\'t save a payment: $reason';
  }

  @override
  String rejectedPaymentDelete(String reason) {
    return 'Couldn\'t save deleting a payment: $reason';
  }

  @override
  String rejectedPaymentConfirm(String reason) {
    return 'Couldn\'t save confirming a payment: $reason';
  }

  @override
  String rejectedGroupSettings(String reason) {
    return 'Couldn\'t save a group settings change: $reason';
  }

  @override
  String rejectedMemberAdd(String name, String reason) {
    return 'Couldn\'t save adding $name: $reason';
  }

  @override
  String rejectedMemberAddUnnamed(String reason) {
    return 'Couldn\'t save adding a member: $reason';
  }

  @override
  String rejectedMemberRemove(String reason) {
    return 'Couldn\'t save removing a member: $reason';
  }

  @override
  String rejectedOther(String reason) {
    return 'Couldn\'t save a change: $reason';
  }

  @override
  String get reasonReceiptLimit => 'an expense can have at most 10 receipts';

  @override
  String get reasonSeriesLimit =>
      'a group can have at most 100 repeating expenses';

  @override
  String get reasonNotUploaded => 'the photo didn\'t upload';

  @override
  String get reasonSumMismatch => 'the split doesn\'t add up';

  @override
  String get reasonPayersSumMismatch => 'the payers don\'t add up';

  @override
  String get reasonNegativeAmount => 'an amount is below zero';

  @override
  String get reasonUnknownMember =>
      'it refers to someone who isn\'t in the group';

  @override
  String get reasonUnknownCurrency => 'the currency isn\'t supported';

  @override
  String get reasonMemberTaken => 'that member is already taken';

  @override
  String get reasonGroupFull => 'the group is full';

  @override
  String get reasonForbidden => 'you\'re not allowed to make that change';

  @override
  String get reasonRefused => 'the server refused it';

  @override
  String leaveOwe(String amount) {
    return 'You owe $amount · settle up first';
  }

  @override
  String leaveOweIn(String amount, String currency) {
    return 'You owe $amount · settle up in $currency first';
  }

  @override
  String leaveOwed(String amount) {
    return 'You are owed $amount · settle up first';
  }

  @override
  String leaveOwedIn(String amount, String currency) {
    return 'You are owed $amount · settle up in $currency first';
  }

  @override
  String leaveSeries(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'You\'re still in $count repeating expenses ($names) · edit the latest one or stop them first',
      one:
          'You\'re still in 1 repeating expense ($names) · edit the latest one or stop it first',
    );
    return '$_temp0';
  }

  @override
  String seriesNamesMore(String names, int count) {
    return '$names and $count more';
  }

  @override
  String get seriesUnnamed => 'an expense';

  @override
  String get listJoiner => ', ';

  @override
  String get repeatNever => 'Never';

  @override
  String get repeatWeekly => 'Every week';

  @override
  String get repeatBiweekly => 'Every 2 weeks';

  @override
  String get repeatMonthly => 'Every month';

  @override
  String get repeatYearly => 'Every year';

  @override
  String summaryNotConverted(String currency) {
    return 'Not converted · $currency';
  }

  @override
  String summaryTotalSpent(String amount) {
    return 'Total spent: $amount';
  }

  @override
  String summaryPaidShare(String paid, String share) {
    return 'You paid: $paid · Your share: $share';
  }

  @override
  String summaryPayments(String made, String received) {
    return 'Payments made: $made · received: $received';
  }

  @override
  String summaryTopCategories(String list) {
    return 'Top categories: $list';
  }

  @override
  String get summaryBalancesToday => 'Balances today';

  @override
  String summaryGetsBack(String name, String amount) {
    return '$name gets back $amount';
  }

  @override
  String summaryOwes(String name, String amount) {
    return '$name owes $amount';
  }

  @override
  String get summaryFooter => 'Shared from Evensies';

  @override
  String get koreanBank => 'Korean bank';

  @override
  String requestText(String amount, String group) {
    return 'You owe me $amount for $group on Evensies.';
  }

  @override
  String requestTextWays(String amount, String group, String ways) {
    return 'You owe me $amount for $group on Evensies. Pay with: $ways';
  }

  @override
  String get requestNoGroup => 'our shared expenses';

  @override
  String get leaveSyncing => 'Still syncing. Try again in a moment.';

  @override
  String get leaveOffline => 'You need to be online to leave';

  @override
  String get moveOffline => 'Couldn\'t move it. Try again when you\'re online';

  @override
  String moveFailed(String reason) {
    return 'Couldn\'t move it: $reason';
  }

  @override
  String get photoNoAccess =>
      'Evensies has no access. Allow it in the Settings app.';

  @override
  String get photoNoCamera => 'Couldn\'t open the camera.';

  @override
  String get photoNoLibrary => 'Couldn\'t open the photo library.';

  @override
  String get photoUnusable => 'That photo couldn\'t be used. Try another one.';

  @override
  String get methodErrorUsername => 'Letters, digits, . _ - only (max 40)';

  @override
  String methodErrorLinkPrefix(String prefix) {
    return 'Must start with $prefix';
  }

  @override
  String get methodErrorTooLong => 'Max 200 characters';

  @override
  String get methodErrorIban => 'Not a valid IBAN';

  @override
  String get methodErrorHolder => 'Account holder name (1–70 characters)';

  @override
  String get methodErrorBic => 'BIC has 8 or 11 characters';

  @override
  String get methodErrorKrAccount => 'Digits and hyphens, 8–20 digits';

  @override
  String get methodErrorBank => 'Bank name (1–30 characters)';

  @override
  String get methodErrorUnknownType => 'Unknown type';

  @override
  String get methodErrorTooMany =>
      'At most 8 ways to get paid, and 3 of each bank type';

  @override
  String get bannerDismiss => 'Dismiss';

  @override
  String get bannerView => 'View';

  @override
  String get loginTagline => 'Split expenses with friends. No ads, no upsells.';

  @override
  String get loginApple => 'Continue with Apple';

  @override
  String get loginGoogle => 'Continue with Google';

  @override
  String get loginWebUnavailable =>
      'This server has no sign-in for the browser yet.';

  @override
  String get welcomeTitle => 'Welcome';

  @override
  String get yourNameTitle => 'Your name';

  @override
  String get nameQuestion => 'What should your friends call you?';

  @override
  String get nameExplain => 'This is the name other members see.';

  @override
  String get nameHelp =>
      'It is shown to people in your groups. You can change it later in Settings.';

  @override
  String get nameLabel => 'Name';

  @override
  String get lockReason => 'Unlock Evensies';

  @override
  String get lockTitle => 'Evensies is locked';

  @override
  String get lockSubtitle =>
      'Unlock with Face ID, Touch ID, your fingerprint or the device passcode.';

  @override
  String get lockUnlock => 'Unlock';

  @override
  String get lockSignOutConfirm =>
      'Sign out and remove this device\'s data? Your groups stay on the server.';

  @override
  String get signOut => 'Sign out';

  @override
  String get widgetOwed => 'You are owed';

  @override
  String get widgetOwe => 'You owe';

  @override
  String get widgetSignedOut => 'Sign in to see your balance';

  @override
  String get widgetSettled => 'All settled up';

  @override
  String widgetUpdated(String time) {
    return 'Updated $time';
  }

  @override
  String get receiptAdd => 'Add a receipt';

  @override
  String get photoTake => 'Take photo';

  @override
  String get photoChoose => 'Choose from library';

  @override
  String get photoChooseFile => 'Choose a file';

  @override
  String get availableWhenOnline => 'Available when online';

  @override
  String get receiptPhoto => 'Receipt photo';

  @override
  String get receiptAvailableOnline => 'The photo is available when online';

  @override
  String get receiptRemoveTitle => 'Remove receipt?';

  @override
  String get receiptRemoveMessage => 'It is removed for everyone in the group.';

  @override
  String get receiptTitle => 'Receipt';

  @override
  String receiptTitleOf(int index, int count) {
    return 'Receipt $index of $count';
  }

  @override
  String get shareOrSave => 'Share or save';

  @override
  String get share => 'Share';

  @override
  String get copiedToClipboard => 'Copied to the clipboard';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get photoRemove => 'Remove photo';

  @override
  String get photoNeedsConnection => 'Changing your photo needs a connection.';

  @override
  String get photoTooMany => 'Too many photo changes. Try again in an hour.';

  @override
  String get notifSaveFailed =>
      'Could not save notification settings. Check your connection.';

  @override
  String get homeCurrencyNeedsConnection =>
      'Changing your home currency needs a connection.';

  @override
  String get changePhoto => 'Change profile photo';

  @override
  String get yourNameTapToChange => 'Your name · tap to change';

  @override
  String get waysToGetPaid => 'Ways to get paid';

  @override
  String get waysToGetPaidHint => 'PayPal, Wise, IBAN, bank account…';

  @override
  String get homeCurrency => 'Home currency';

  @override
  String get homeCurrencyFromRegion =>
      'From your region · balances also show ≈ in it';

  @override
  String get homeCurrencyPicked => 'Balances also show ≈ in it';

  @override
  String get notifications => 'Notifications';

  @override
  String get notifExpenses => 'Expenses and payments';

  @override
  String get notifComments => 'Comments';

  @override
  String get notifMembers => 'Members and group changes';

  @override
  String get notifReminders => 'Reminders from friends';

  @override
  String get notifNeedConnection => 'Notification settings need a connection';

  @override
  String get notifOthersOnly => 'Only changes made by other people notify you.';

  @override
  String get notifWebNote =>
      'Notifications go to your phone; the browser updates every minute while it is open.';

  @override
  String get exportImport => 'Export & import';

  @override
  String get noGroupsToExport => 'No groups to export.';

  @override
  String get nonGroup => 'Non-group';

  @override
  String nonGroupWith(String name) {
    return 'Non-group · $name';
  }

  @override
  String get exportJson => 'Export JSON';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get exportZip => 'ZIP with receipts';

  @override
  String get importSplitwise => 'Import Splitwise CSV';

  @override
  String importedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Imported $count expenses',
      one: 'Imported 1 expense',
    );
    return '$_temp0';
  }

  @override
  String get server => 'Server';

  @override
  String get serverUrl => 'Server URL';

  @override
  String serverDefault(String url) {
    return 'Default: $url';
  }

  @override
  String get serverSaved => 'Server URL saved';

  @override
  String get account => 'Account';

  @override
  String get licenses => 'Licenses';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get signOutTitle => 'Sign out?';

  @override
  String get signOutMessage =>
      'Local data on this device is removed. Changes that have not synced yet will be lost.';

  @override
  String get deleteAccountTitle => 'Delete account?';

  @override
  String get deleteAccountMessage =>
      'Your memberships become placeholders. Group data stays with the other members. This cannot be undone.';

  @override
  String get language => 'Language';

  @override
  String languageSystem(String language) {
    return 'System ($language)';
  }

  @override
  String get appearance => 'Appearance';

  @override
  String get appearanceSystem => 'System';

  @override
  String get appearanceLight => 'Light';

  @override
  String get appearanceDark => 'Dark';

  @override
  String get security => 'Security';

  @override
  String get appLock => 'App lock';

  @override
  String get appLockHint =>
      'Face ID, Touch ID or fingerprint, with the device passcode as fallback. Locks after a minute away.';

  @override
  String methodRemoveTitle(String method) {
    return 'Remove $method?';
  }

  @override
  String get methodsOffline =>
      'Connect to the internet to edit your ways to get paid.';

  @override
  String get methodsLoadFailed => 'Couldn\'t load your ways to get paid.';

  @override
  String get methodsIntro =>
      'Group members see these when they owe you money, so they can pay you in one tap. Evensies never moves money itself.';

  @override
  String get methodsEmpty => 'No ways to get paid yet.';

  @override
  String get blurbPaypal => 'PayPal.me link, amount filled in';

  @override
  String get blurbWise => 'Wise Quick Pay link, amount filled in';

  @override
  String get blurbVenmo => 'Venmo username (US)';

  @override
  String get blurbRevolut => 'Revolut.me username';

  @override
  String get blurbKakaopay => 'KakaoPay 송금코드 link';

  @override
  String get blurbIban => 'Bank transfer (SEPA QR for EUR)';

  @override
  String get blurbKrBank => 'Korean bank account (Toss, bank apps)';

  @override
  String get fieldPaypal => 'PayPal.me username';

  @override
  String get fieldPaypalHint => 'Your PayPal.me username, e.g. anna';

  @override
  String get fieldRevolut => 'Revolut.me username';

  @override
  String get fieldRevolutHint => 'Your Revolut.me username, e.g. anna';

  @override
  String get fieldVenmo => 'Venmo username';

  @override
  String get fieldVenmoHint => 'Without the @, e.g. anna-rossi';

  @override
  String get fieldWise => 'Wise Quick Pay link';

  @override
  String get fieldWiseHint =>
      'In Wise: Payments → Quick Pay → copy link (https://wise.com/pay/…)';

  @override
  String get fieldKakaopay => 'KakaoPay 송금코드 link';

  @override
  String get fieldKakaopayHint =>
      'In KakaoPay: 송금 → 송금코드 → copy link (https://qr.kakaopay.com/…)';

  @override
  String get fieldHolder => 'Account holder';

  @override
  String get fieldHolderHint => 'Name exactly as on the account';

  @override
  String get fieldIban => 'IBAN';

  @override
  String get fieldIbanHint => 'e.g. DE89 3704 0044 0532 0130 00';

  @override
  String get fieldBic => 'BIC (optional)';

  @override
  String get fieldBicHint => '8 or 11 characters';

  @override
  String get fieldBank => 'Bank';

  @override
  String get fieldBankHint => 'e.g. 신한은행, Toss Bank';

  @override
  String get fieldAccountNumber => 'Account number';

  @override
  String get fieldAccountNumberHint => 'Digits, hyphens optional';

  @override
  String amountCopied(String amount) {
    return 'Amount copied: $amount';
  }

  @override
  String couldNotOpen(String link) {
    return 'Could not open $link';
  }

  @override
  String get payOffline => 'Offline: ways to pay are not available';

  @override
  String get payLoading => 'Loading ways to pay…';

  @override
  String payAskToAdd(String name) {
    return 'Ask $name to add a way to get paid';
  }

  @override
  String payTitle(String name, String amount) {
    return 'Pay $name $amount';
  }

  @override
  String get payScanQr => 'Scan with your banking app (SEPA QR)';

  @override
  String get payQrEurOnly => 'QR code is only available for EUR transfers.';

  @override
  String get bankLabel => 'Bank';

  @override
  String get ibanLabel => 'IBAN';

  @override
  String get accountLabel => 'Account';

  @override
  String get bicLabel => 'BIC';

  @override
  String get holderLabel => 'Holder';

  @override
  String get amountLabel => 'Amount';

  @override
  String get copyIban => 'Copy IBAN';

  @override
  String get copyAccount => 'Copy account';

  @override
  String get copyAmount => 'Copy amount';

  @override
  String get ibanCopied => 'IBAN copied';

  @override
  String get accountCopied => 'Account copied';

  @override
  String get paymentUpdated => 'Payment updated';

  @override
  String paymentRecordedPending(String amount, String name) {
    return 'Recorded $amount. $name will confirm.';
  }

  @override
  String paymentRecordedPendingUnnamed(String amount) {
    return 'Recorded $amount. They will confirm.';
  }

  @override
  String paymentRecorded(String amount) {
    return 'Payment of $amount recorded';
  }

  @override
  String youSuffix(String name) {
    return '$name (you)';
  }

  @override
  String get recordPayment => 'Record a payment';

  @override
  String get editPayment => 'Edit payment';

  @override
  String get fromLabel => 'From';

  @override
  String get toLabel => 'To';

  @override
  String get swap => 'Swap';

  @override
  String get pickTwoPeople => 'Pick two different people';

  @override
  String get commentsStayOld => 'Comments stay with the old payment';

  @override
  String get recordPaymentButton => 'Record payment';

  @override
  String get paymentNotHere => 'This payment isn\'t on this device';

  @override
  String get notSyncedOrLeft => 'It hasn\'t synced yet, or its group was left.';

  @override
  String get someone => 'Someone';

  @override
  String get paymentEdited => 'Edited payment';

  @override
  String get paymentDeleted => 'Deleted payment';

  @override
  String get payment => 'Payment';

  @override
  String get paymentWasEdited => 'This payment was edited';

  @override
  String get paymentWasEditedNote =>
      'The edited payment counts instead. Its comments stay here.';

  @override
  String get paymentWasDeleted => 'This payment was deleted';

  @override
  String get paymentNotCounted => 'It doesn\'t count in balances.';

  @override
  String get restore => 'Restore';

  @override
  String youPaidName(String name) {
    return 'You paid $name';
  }

  @override
  String namePaidYou(String name) {
    return '$name paid you';
  }

  @override
  String namePaidName(String from, String to) {
    return '$from paid $to';
  }

  @override
  String paymentSaysSent(String name) {
    return '$name says they sent you this. Did it arrive?';
  }

  @override
  String waitingForConfirm(String name) {
    return 'Waiting for $name to confirm';
  }

  @override
  String get notReceived => 'Not received';

  @override
  String get confirmReceived => 'Confirm received';

  @override
  String get deletePaymentTitle => 'Delete payment?';

  @override
  String get deletePaymentMessage => 'The debt it settled comes back.';

  @override
  String get paymentDeletedSnack => 'Payment deleted';

  @override
  String get notReceivedTitle => 'Not received?';

  @override
  String notReceivedMessage(String name) {
    return 'The payment from $name is removed and the debt comes back.';
  }

  @override
  String get paymentRemovedSnack => 'Payment removed';

  @override
  String get recordAPayment => 'Record a payment';

  @override
  String get nothingToSettle => 'Nothing to settle';

  @override
  String get everyoneEven => 'Everyone is even.';

  @override
  String get waitingForConfirmation => 'Waiting for confirmation';

  @override
  String get debtsAsRecorded => 'Debts as recorded · simplify debts is off';

  @override
  String transfersSettleEverything(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transfers settle everything',
      one: '1 transfer settles everything',
    );
    return '$_temp0';
  }

  @override
  String transfersSettleBalance(int count, String currency) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transfers settle the $currency balance',
      one: '1 transfer settles the $currency balance',
    );
    return '$_temp0';
  }

  @override
  String notConvertedSettlesIn(String currency) {
    return 'Not converted · $currency · settles in $currency';
  }

  @override
  String get convert => 'Convert';

  @override
  String get settleUp => 'Settle up';

  @override
  String saysTheySent(String name, String amount) {
    return '$name says they sent you $amount';
  }

  @override
  String waitingToConfirmAmount(String name, String amount) {
    return 'Waiting for $name to confirm $amount';
  }

  @override
  String get you => 'You';

  @override
  String get request => 'Request';

  @override
  String get iveSentIt => 'I\'ve sent it';

  @override
  String get markAsPaid => 'Mark as paid';

  @override
  String markedAsSent(String name) {
    return 'Marked as sent. $name will confirm.';
  }

  @override
  String approx(String amount) {
    return '≈ $amount';
  }

  @override
  String friendOwesYou(String name, String amount) {
    return '$name owes you $amount';
  }

  @override
  String friendYouOwe(String name, String amount) {
    return 'You owe $name $amount';
  }

  @override
  String friendYouOweLine(String name, String amount) {
    return 'you owe $name $amount';
  }

  @override
  String noSharedGroup(String name) {
    return 'You no longer share a group with $name. Send them your friend link to add expenses.';
  }

  @override
  String get shareFriendLink => 'Share friend link';

  @override
  String firstExpenseNeedsConnection(String name) {
    return 'The first expense with $name needs a connection.';
  }

  @override
  String reminderSent(String name) {
    return 'Reminder sent to $name';
  }

  @override
  String remindTomorrow(String name) {
    return 'You can remind $name again tomorrow';
  }

  @override
  String remindNothingOwed(String name) {
    return '$name doesn\'t owe you anything';
  }

  @override
  String get remindNeedsConnection => 'Sending a reminder needs a connection.';

  @override
  String amountsAnd(String a, String b) {
    return '$a and $b';
  }

  @override
  String inviteFriendText(String link) {
    return 'I added you on Evensies so we can split expenses. Join me: $link';
  }

  @override
  String get personNotHere => 'This person isn\'t on this device';

  @override
  String get personNotHereNote =>
      'It hasn\'t synced yet, or you no longer share a group.';

  @override
  String get more => 'More';

  @override
  String get exportNonGroupCsv => 'Export non-group expenses (CSV)';

  @override
  String get exportNonGroupJson => 'Export non-group expenses (JSON)';

  @override
  String get exportNonGroupZip =>
      'Export non-group expenses (ZIP with receipts)';

  @override
  String get notOnEvensies => 'Not on Evensies yet';

  @override
  String get allSettledUp => 'All settled up';

  @override
  String get remind => 'Remind';

  @override
  String get invite => 'Invite';

  @override
  String get balances => 'Balances';

  @override
  String get expensesAndPayments => 'Expenses and payments';

  @override
  String get nothingTogetherYet =>
      'Nothing together yet. Add an expense below.';

  @override
  String get addExpense => 'Add expense';

  @override
  String personOwesYou(String amount) {
    return 'owes you $amount';
  }

  @override
  String personYouOwe(String amount) {
    return 'you owe $amount';
  }

  @override
  String get personSettledUp => 'settled up';

  @override
  String recordedInGroups(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Recorded in $count groups',
      one: 'Recorded in 1 group',
    );
    return '$_temp0';
  }

  @override
  String get markAsReceived => 'Mark as received';

  @override
  String get clearBothSides => 'Clear both sides';

  @override
  String evenIn(String currency) {
    return 'Even in $currency';
  }

  @override
  String linePayThem(String group, String name, String amount) {
    return '$group: you pay $name $amount';
  }

  @override
  String lineTheyPay(String group, String name, String amount) {
    return '$group: $name pays you $amount';
  }

  @override
  String get noMoneyMoves =>
      'No money moves: this records both sides as settled.';

  @override
  String convertIn(String group) {
    return 'Convert in $group';
  }

  @override
  String settleUpWith(String name) {
    return 'Settle up with $name';
  }

  @override
  String nothingToSettleWith(String name) {
    return 'Nothing to settle with $name';
  }

  @override
  String settleWithIntro(String name) {
    return 'Everything between you and $name, per currency. Recording adds a payment in each group.';
  }

  @override
  String get searchFriendsGroups => 'Search friends and groups';

  @override
  String get friends => 'Friends';

  @override
  String get groups => 'Groups';

  @override
  String get noFriendsOrGroups => 'No friends or groups yet.';

  @override
  String nothingMatches(String query) {
    return 'Nothing matches “$query”.';
  }

  @override
  String get addExpenseWithWhom => 'Add expense · with whom?';

  @override
  String friendLinkShare(String link, String code) {
    return 'Add me on Evensies to split expenses: $link\nOr enter my code $code';
  }

  @override
  String get friendLinkNeedsConnection =>
      'Sharing your friend link needs a connection.';

  @override
  String get selfFriend => 'That\'s your own code';

  @override
  String get noOneForCode => 'No one found for this code';

  @override
  String get addFriendNeedsConnection => 'Adding a friend needs a connection.';

  @override
  String get newFriendCodeTitle => 'Get a new friend code?';

  @override
  String get newFriendCodeMessage =>
      'Your current link and code stop working. Friends you already have stay.';

  @override
  String get newCode => 'New code';

  @override
  String get addAFriend => 'Add a friend';

  @override
  String get friendLinkOffline => 'Your friend link needs a connection';

  @override
  String get yourFriendCode => 'Your friend code';

  @override
  String get friendQrLabel => 'QR code of your friend link';

  @override
  String get friendCodeHelp =>
      'Friends scan this, open the link, or type the code.';

  @override
  String get shareLink => 'Share link';

  @override
  String get codeCopied => 'Code copied';

  @override
  String get copyCode => 'Copy code';

  @override
  String get haveFriendCode => 'Have a friend\'s code?';

  @override
  String get onEvensies => 'on Evensies';

  @override
  String get notOnEvensiesSection => 'Someone not on Evensies yet';

  @override
  String get notOnEvensiesHelp =>
      'Add expenses with them right away, and invite them later.';

  @override
  String atMostChars(int max) {
    return 'At most $max characters';
  }

  @override
  String addName(String name) {
    return 'Add $name';
  }

  @override
  String get search => 'Search';

  @override
  String get activity => 'Activity';

  @override
  String get newGroup => 'New group';

  @override
  String get joinWithCode => 'Join with a code';

  @override
  String get filterAll => 'All';

  @override
  String get filterOwesMe => 'Owes me';

  @override
  String get filterIOwe => 'I owe';

  @override
  String settledUpCount(int count) {
    return 'Settled up ($count)';
  }

  @override
  String get nobodyOwesYou => 'Nobody owes you anything';

  @override
  String get youOweNothing => 'You don\'t owe anything';

  @override
  String get nothingHereYet => 'Nothing here yet';

  @override
  String get noFriendsYet => 'No friends yet';

  @override
  String get noFriendsHelp =>
      'Add a friend to split expenses outside a group. People you share a group with show up here too.';

  @override
  String get allSettledUpYou => 'You are all settled up';

  @override
  String youAreOwedList(String amounts) {
    return 'You are owed $amounts';
  }

  @override
  String youOweList(String amounts) {
    return 'You owe $amounts';
  }

  @override
  String get notOnEvensiesLower => 'not on Evensies yet';

  @override
  String get noGroupsYet => 'No groups yet';

  @override
  String get noGroupsHelp =>
      'Create one for a trip or a flat, or join a friend\'s group with their invite code.';

  @override
  String get createGroup => 'Create group';

  @override
  String get settledUp => 'Settled up';

  @override
  String netApprox(String amount) {
    return 'Net ≈ $amount';
  }

  @override
  String memberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String youOweAmount(String amount) {
    return 'You owe $amount';
  }

  @override
  String youAreOwedAmount(String amount) {
    return 'You are owed $amount';
  }

  @override
  String youOweAmountLine(String amount) {
    return 'you owe $amount';
  }

  @override
  String youAreOwedAmountLine(String amount) {
    return 'you are owed $amount';
  }

  @override
  String get createGroupNeedsConnection =>
      'Creating a group needs a connection.';

  @override
  String get groupName => 'Group name';

  @override
  String get yourNameInGroup => 'Your name in this group';

  @override
  String get defaultCurrency => 'Default currency';

  @override
  String get create => 'Create';

  @override
  String get noGroupOrFriendForCode => 'No group or friend found for this code';

  @override
  String get joinNeedsConnection => 'Joining a group needs a connection.';

  @override
  String get enterACode => 'Enter a code';

  @override
  String get enterCodeHelp =>
      'A group code is in the group → Members. A friend code is on their Friends tab → Add a friend.';

  @override
  String get pastedFromClipboard => 'Pasted from clipboard';

  @override
  String nameOnEvensies(String name) {
    return '$name · on Evensies';
  }

  @override
  String addAsFriend(String name) {
    return 'Add $name as a friend';
  }

  @override
  String addedYouAsFriend(String name) {
    return '$name added you as a friend';
  }

  @override
  String get someoneAddedYouAsFriend => 'Someone added you as a friend';

  @override
  String groupPreview(String name, String members) {
    return '$name · $members';
  }

  @override
  String get continueButton => 'Continue';

  @override
  String wantsToSplit(String name) {
    return '$name wants to split expenses with you';
  }

  @override
  String get joinGroup => 'Join group';

  @override
  String get inviteInvalid => 'This invite link is no longer valid';

  @override
  String inviteFailed(String reason) {
    return 'Couldn\'t open this invite: $reason';
  }

  @override
  String get friendInviteUsed => 'This friend invite was already used';

  @override
  String get joinToSeeShared => 'Join to see and add your shared expenses.';

  @override
  String imName(String name) {
    return 'I\'m $name';
  }

  @override
  String get join => 'Join';

  @override
  String get whoAreYou => 'Who are you?';

  @override
  String get newMemberName => 'New member name';

  @override
  String get insights => 'Insights';

  @override
  String get membersInvite => 'Members & invite';

  @override
  String get groupSettings => 'Group settings';

  @override
  String get expenses => 'Expenses';

  @override
  String get expenseFab => 'Expense';

  @override
  String get groupNotHere => 'This group isn\'t on this device';

  @override
  String get groupNotHereNote =>
      'You left it, someone removed you, or it hasn\'t synced yet.';

  @override
  String get backToGroups => 'Back to groups';

  @override
  String get noExpensesYet => 'No expenses yet';

  @override
  String get tapExpenseToAdd => 'Tap \"Expense\" to add the first one.';

  @override
  String tilePaidYou(String amount) {
    return 'you paid $amount';
  }

  @override
  String tilePaidName(String name, String amount) {
    return '$name paid $amount';
  }

  @override
  String tilePaidPeople(int count, String amount) {
    return '$count people paid $amount';
  }

  @override
  String get tileRefundYou => 'refund to you';

  @override
  String tileRefundName(String name) {
    return 'refund to $name';
  }

  @override
  String tileRefundPeople(int count) {
    return 'refund to $count people';
  }

  @override
  String get notInvolved => 'not involved';

  @override
  String get allYours => 'all yours';

  @override
  String get paidForYourself => 'you paid for yourself';

  @override
  String youGetBack(String amount) {
    return 'you get back $amount';
  }

  @override
  String youLent(String amount) {
    return 'you lent $amount';
  }

  @override
  String youBorrowed(String amount) {
    return 'you borrowed $amount';
  }

  @override
  String get repeatsLabel => 'Repeats';

  @override
  String hasReceipt(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Has $count receipts',
      one: 'Has a receipt',
    );
    return '$_temp0';
  }

  @override
  String get refund => 'Refund';

  @override
  String get notConverted => 'Not converted';

  @override
  String get pending => 'pending';

  @override
  String approxTotalOwe(String amount) {
    return 'You owe ≈ $amount in total';
  }

  @override
  String approxTotalOwed(String amount) {
    return 'You are owed ≈ $amount in total';
  }

  @override
  String get approxTotalNote => 'In your home currency, at the latest rates';

  @override
  String nothingOwedIn(String currency) {
    return 'Nothing owed in $currency';
  }

  @override
  String get allSettled => 'All settled';

  @override
  String get otherCurrenciesBelow => 'Expenses in other currencies are below.';

  @override
  String get nobodyOwes => 'Nobody owes anything.';

  @override
  String youPayNext(String amount) {
    return 'You should pay next (you owe $amount, the most)';
  }

  @override
  String namePaysNext(String name, String amount) {
    return '$name should pay next (owes $amount, the most)';
  }

  @override
  String settleUpWaiting(int count) {
    return 'Settle up · $count waiting';
  }

  @override
  String memberRemoved(String name) {
    return '$name (removed)';
  }

  @override
  String expensesWithoutRate(int count, String currency) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count expenses without a rate to $currency',
      one: '1 expense without a rate to $currency',
    );
    return '$_temp0';
  }

  @override
  String expensesBadRate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count expenses with a rate that can\'t be converted',
      one: '1 expense with a rate that can\'t be converted',
    );
    return '$_temp0';
  }

  @override
  String paymentsIn(String currency) {
    return 'Payments in $currency';
  }

  @override
  String everyoneEvenIn(String currency) {
    return 'everyone is even in $currency';
  }

  @override
  String convertTo(String currency) {
    return 'Convert to $currency';
  }

  @override
  String get balanceSettled => 'settled';

  @override
  String get balanceGetsBack => 'gets back';

  @override
  String get balanceOwes => 'owes';

  @override
  String convertedCount(int count, String currency) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Converted $count expenses to $currency',
      one: 'Converted 1 expense to $currency',
    );
    return '$_temp0';
  }

  @override
  String get noAutoRate => 'No automatic rate. Enter one.';

  @override
  String rateOf(String date) {
    return 'rate of $date';
  }

  @override
  String rateOfOffline(String date) {
    return 'offline · rate of $date';
  }

  @override
  String amountCountExpenses(String amount, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count expenses',
      one: '1 expense',
    );
    return '$amount · $_temp0';
  }

  @override
  String paymentsStayIn(String currency) {
    return 'Payments in $currency stay in $currency';
  }

  @override
  String rateLabel(String from, String to) {
    return 'Rate: 1 $from in $to';
  }

  @override
  String get nothingLeftToConvert => 'Nothing left to convert';

  @override
  String get lookingUpRate => 'Looking up the rate…';

  @override
  String get enterRateAbove0 => 'Enter a rate above 0';

  @override
  String convertExplain(String currency) {
    return 'Fills in this rate on every expense that has none, so they count in $currency balances. You can still change the rate on each expense.';
  }

  @override
  String get nameField => 'Name';

  @override
  String get cantChangeCurrency =>
      'Can\'t change after the first expense or payment';

  @override
  String get currencyUsedFor => 'Balances and payments use it';

  @override
  String get splitting => 'Splitting';

  @override
  String get simplifyDebts => 'Simplify debts';

  @override
  String get simplifyDebtsHelp =>
      'Combines debts so the group needs fewer payments. Nobody\'s total changes, only who pays whom.';

  @override
  String get defaultSplit => 'Default split';

  @override
  String get splitStale => 'No longer adds up · tap to fix';

  @override
  String get membership => 'Membership';

  @override
  String get leaveGroup => 'Leave group';

  @override
  String get balanceSettledNote => 'Your balance is settled';

  @override
  String get renameGroup => 'Rename group';

  @override
  String leaveTitle(String name) {
    return 'Leave “$name”?';
  }

  @override
  String get leaveMessage =>
      'You won\'t see this group any more. Your past expenses stay with the other members. To come back, ask for the invite code.';

  @override
  String get leave => 'Leave';

  @override
  String youLeft(String name) {
    return 'You left “$name”';
  }

  @override
  String get splitEqualEveryone => 'Equal · everyone';

  @override
  String splitPercentList(String list) {
    return 'Percent · $list';
  }

  @override
  String splitSharesList(String list) {
    return 'Shares · $list';
  }

  @override
  String percentValue(String value) {
    return '$value%';
  }

  @override
  String get defaultSplitHelp =>
      'New expenses start with this split. You can still change it on each expense.';

  @override
  String get useEqual => 'Use equal';

  @override
  String get inviteCode => 'Invite code';

  @override
  String get inviteQrLabel => 'QR code of the invite link';

  @override
  String get inviteCodeHelp =>
      'Anyone with this code can join and pick their name.';

  @override
  String inviteShareText(String group, String link, String code) {
    return 'Join my group \"$group\" on Evensies: $link\nOr open the app and enter code $code';
  }

  @override
  String get rotateCode => 'Rotate code';

  @override
  String get members => 'Members';

  @override
  String get notJoinedYet => 'not joined yet — share the invite code';

  @override
  String get linked => 'linked';

  @override
  String get addPlaceholder => 'Add placeholder member';

  @override
  String removeMemberTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get removeMemberMessage =>
      'Their past expenses and balance stay in the group.';

  @override
  String removeMemberSeries(int count, String name, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$name is still in $count repeating expenses ($names); they keep $name\'s share until you edit the latest one.',
      one:
          '$name is still in 1 repeating expense ($names); they keep $name\'s share until you edit the latest one.',
    );
    return '$_temp0';
  }

  @override
  String get addMember => 'Add member';

  @override
  String get rotateInviteTitle => 'Rotate invite code?';

  @override
  String get rotateInviteMessage =>
      'The current code and link stop working. People who already joined are not affected.';

  @override
  String get rotate => 'Rotate';

  @override
  String get newInviteReady => 'New invite code ready';

  @override
  String get activityNeedsConnection => 'Activity needs a connection';

  @override
  String get activityOfflineNote =>
      'Recent changes show up here once you are back online.';

  @override
  String get noActivityYet => 'No activity yet';

  @override
  String get activityAllGroups => 'Changes in your groups show up here.';

  @override
  String get activityThisGroup => 'Changes in this group show up here.';

  @override
  String get showingSaved => 'Showing saved activity. Pull to refresh.';

  @override
  String get loadMore => 'Load more';

  @override
  String get earlier => 'Earlier';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String forDate(String date) {
    return 'for $date';
  }

  @override
  String get youCommented => 'You commented';

  @override
  String nameCommented(String name) {
    return '$name commented';
  }

  @override
  String restoredName(String name) {
    return 'Restored “$name”';
  }

  @override
  String get paymentRestored => 'Payment restored';

  @override
  String get expenseNotHere => 'This expense isn\'t on this device';

  @override
  String get deletedExpense => 'Deleted expense';

  @override
  String get expense => 'Expense';

  @override
  String seriesRepeats(String frequency) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Repeats every week',
      'biweekly': 'Repeats every 2 weeks',
      'monthly': 'Repeats every month',
      'yearly': 'Repeats every year',
      'other': 'Repeats',
    });
    return '$_temp0';
  }

  @override
  String seriesRepeatsNext(String frequency, String date) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Repeats every week · next on $date',
      'biweekly': 'Repeats every 2 weeks · next on $date',
      'monthly': 'Repeats every month · next on $date',
      'yearly': 'Repeats every year · next on $date',
      'other': 'Repeats · next on $date',
    });
    return '$_temp0';
  }

  @override
  String seriesRepeatsNextAmount(String frequency, String amount, String date) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Repeats every week · next $amount on $date',
      'biweekly': 'Repeats every 2 weeks · next $amount on $date',
      'monthly': 'Repeats every month · next $amount on $date',
      'yearly': 'Repeats every year · next $amount on $date',
      'other': 'Repeats · next $amount on $date',
    });
    return '$_temp0';
  }

  @override
  String rateLine(String from, String rate, String to) {
    return 'Rate: 1 $from = $rate $to';
  }

  @override
  String notConvertedTo(String currency) {
    return 'Not converted to $currency';
  }

  @override
  String get receivedSplitBack => 'Received and split back';

  @override
  String get whoPaidOwes => 'Who paid and who owes';

  @override
  String get items => 'Items';

  @override
  String get notes => 'Notes';

  @override
  String get receipts => 'Receipts';

  @override
  String get history => 'History';

  @override
  String get deleteExpenseTitle => 'Delete expense?';

  @override
  String get deleteExpenseMessage =>
      'This removes it for everyone in the group. You can restore it from Activity.';

  @override
  String get deleteRepeatingTitle => 'Delete repeating expense?';

  @override
  String get deleteRepeatingMessage =>
      'This removes it for everyone in the group. You can restore it from Activity, but a series that stopped repeating can\'t be restarted. Repeats already added stay.';

  @override
  String get deleteThisOne => 'Delete this one';

  @override
  String get deleteAndStop => 'Delete and stop repeating';

  @override
  String deletedAndStopped(String name) {
    return 'Deleted “$name” and stopped repeating';
  }

  @override
  String deletedName(String name) {
    return 'Deleted “$name”';
  }

  @override
  String get movedToOtherGroup => 'Moved to another group';

  @override
  String get movedNote =>
      'It counts there now. Its comments and history stay here.';

  @override
  String get expenseWasDeleted => 'This expense was deleted';

  @override
  String get restoreToCount => 'Restore it to count it in balances again.';

  @override
  String get tax => 'Tax';

  @override
  String get tipService => 'Tip or service';

  @override
  String get discount => 'Discount';

  @override
  String youPaidOwe(String paid, String owe) {
    return 'You paid $paid and owe $owe';
  }

  @override
  String youPaid(String amount) {
    return 'You paid $amount';
  }

  @override
  String youOwe(String amount) {
    return 'You owe $amount';
  }

  @override
  String namePaidOwes(String name, String paid, String owe) {
    return '$name paid $paid and owes $owe';
  }

  @override
  String namePaid(String name, String amount) {
    return '$name paid $amount';
  }

  @override
  String nameOwes(String name, String amount) {
    return '$name owes $amount';
  }

  @override
  String youReceivedGetBack(String received, String back) {
    return 'You received $received and get back $back';
  }

  @override
  String youReceived(String amount) {
    return 'You received $amount';
  }

  @override
  String youGetBackLine(String amount) {
    return 'You get back $amount';
  }

  @override
  String nameReceivedGetsBack(String name, String received, String back) {
    return '$name received $received and gets back $back';
  }

  @override
  String nameReceived(String name, String amount) {
    return '$name received $amount';
  }

  @override
  String nameGetsBack(String name, String amount) {
    return '$name gets back $amount';
  }

  @override
  String get noHistoryYet => 'No history yet.';

  @override
  String get historyOffline => 'History shows up here once you are online.';

  @override
  String get showingSavedHistory => 'Showing saved history.';

  @override
  String get showMore => 'Show more';

  @override
  String get deleteCommentTitle => 'Delete comment?';

  @override
  String get comments => 'Comments';

  @override
  String get noCommentsYet => 'No comments yet.';

  @override
  String get deleteComment => 'Delete comment';

  @override
  String get addComment => 'Add a comment';

  @override
  String get send => 'Send';

  @override
  String get filterByCategory => 'Filter by category';

  @override
  String get category => 'Category';

  @override
  String get categoryAll => 'All';

  @override
  String get month => 'Month';

  @override
  String get searchUnavailable => 'Search isn\'t available';

  @override
  String get searchExpenses => 'Search expenses';

  @override
  String get searchHelp =>
      'Descriptions, notes, comments, categories and amounts: \"taxi\", \"airport\", \"12,50\".';

  @override
  String get noMatches => 'No matches';

  @override
  String get noMatchesHelp => 'Try another word, or remove a filter.';

  @override
  String expenseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count expenses',
      one: '1 expense',
    );
    return '$_temp0';
  }

  @override
  String get searchAllGroups => 'Search all groups';

  @override
  String searchGroup(String name) {
    return 'Search $name';
  }

  @override
  String get searchThisGroup => 'Search this group';

  @override
  String get clear => 'Clear';

  @override
  String get thisGroup => 'This group';

  @override
  String insightsError(String reason) {
    return 'Insights can\'t be shown: $reason';
  }

  @override
  String get nothingToShow => 'Nothing to show yet';

  @override
  String get insightsEmptyHelp =>
      'Totals and charts appear once the group has expenses.';

  @override
  String get allTime => 'All time';

  @override
  String get shareSummary => 'Share summary';

  @override
  String get printSummary => 'Print summary';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get byMonth => 'By month';

  @override
  String get groupSegment => 'Group';

  @override
  String get mineSegment => 'Mine';

  @override
  String get byCategory => 'By category';

  @override
  String get noExpensesPeriod => 'No expenses in this period.';

  @override
  String get byPerson => 'By person';

  @override
  String get nobodyPaidPeriod => 'Nobody paid or owed anything in this period.';

  @override
  String keptUntilConverted(String currency, String group) {
    return 'Kept in $currency until it is converted to $group.';
  }

  @override
  String get totalSpent => 'Total spent';

  @override
  String get yourShare => 'Your share';

  @override
  String get paymentsMade => 'Payments made';

  @override
  String get paymentsReceived => 'Payments received';

  @override
  String get youPaidRow => 'You paid';

  @override
  String get balanceChange => 'Change in your balance';

  @override
  String get paidLegend => 'Paid';

  @override
  String get shareLegend => 'Share';

  @override
  String paidShareLine(String paid, String share) {
    return 'paid $paid · share $share';
  }

  @override
  String get itemsGiveEveryone => 'Give every item a person';

  @override
  String get itemsAddPrices => 'Add the item prices before tax or tip';

  @override
  String get itemsDiscountTooBig => 'The discount is more than the bill';

  @override
  String get itemsDontAddUp => 'The items don\'t add up';

  @override
  String get adjustmentsDontFit => 'Adjustments don\'t fit the total';

  @override
  String get giveSomeoneShare => 'Give someone a share';

  @override
  String get checkNumbers => 'Check the numbers';

  @override
  String get splitDoesntAddUp => 'The split doesn\'t add up';

  @override
  String get addTheItems => 'Add the items';

  @override
  String get pickOnePerson => 'Pick at least one person';

  @override
  String splitEquallyBetween(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Split equally between $count people',
      one: 'Split equally between 1 person',
    );
    return '$_temp0';
  }

  @override
  String get allForOnePerson => 'All of it for 1 person';

  @override
  String splitEquallyEach(int count, String amount) {
    return 'Split equally between $count people · $amount each';
  }

  @override
  String get checkAmounts => 'Check the amounts';

  @override
  String get enterTotalFirst => 'Enter the total first';

  @override
  String remaining(String amount) {
    return 'remaining: $amount';
  }

  @override
  String overBy(String amount) {
    return 'over by: $amount';
  }

  @override
  String get addsUp => 'Adds up';

  @override
  String sharesInTotal(String count) {
    return '$count shares in total';
  }

  @override
  String get oneShareInTotal => '1 share in total';

  @override
  String get restSplitEqually => 'The rest is split equally';

  @override
  String get byPercent => 'By percent';

  @override
  String get byShares => 'By shares';

  @override
  String get byAdjustment =>
      'Adjust: extra or less for someone, the rest equally';

  @override
  String get modeEqual => 'Equal';

  @override
  String get modeExact => 'Exact';

  @override
  String get modeShares => 'Shares';

  @override
  String get byItem => 'By item, from a receipt';

  @override
  String get adjustmentHelp =>
      'Add or take off an amount for someone; the rest is split equally.';

  @override
  String get noMembers => 'No members';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get addAnItem => 'Add an item';

  @override
  String atMostItems(int max) {
    return 'At most $max items';
  }

  @override
  String get giveItemName => 'Give every item a name';

  @override
  String get itemNameTooLong => 'An item name is too long';

  @override
  String get addItem => 'Add item';

  @override
  String get giveRestToEveryone => 'Give the rest to everyone';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get total => 'Total';

  @override
  String receiptSays(String printed, String difference) {
    return 'Receipt says $printed · items differ by $difference';
  }

  @override
  String get eachPerson => 'Each person';

  @override
  String itemsWithoutPerson(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items without a person',
      one: '1 item without a person',
    );
    return '$_temp0';
  }

  @override
  String get itemHint => 'Item';

  @override
  String memberLeft(String name) {
    return '$name (left)';
  }

  @override
  String get whoHadThis => 'Who had this?';

  @override
  String get defaultSplitStartsEqual =>
      'The group\'s default split no longer adds up, so this starts equal';

  @override
  String leftToAssign(String amount) {
    return '$amount left to assign';
  }

  @override
  String get itemsTotal => 'The total of the items';

  @override
  String get newExpense => 'New expense';

  @override
  String get editExpense => 'Edit expense';

  @override
  String get scanReceipt => 'Scan receipt';

  @override
  String get rateAboveZeroOrEmpty => 'Enter a rate above 0, or leave it empty';

  @override
  String useAutoRate(String rate, String source) {
    return 'Use automatic rate: $rate ($source)';
  }

  @override
  String get description => 'Description';

  @override
  String get receivedBy => 'Received by';

  @override
  String get paidBy => 'Paid by';

  @override
  String get severalPeople => 'Several people';

  @override
  String get when => 'When';

  @override
  String get refundTooltip =>
      'Money that came back, e.g. the hotel returned a deposit';

  @override
  String get splitBackTo => 'Split back to';

  @override
  String get split => 'Split';

  @override
  String theyOweFull(String name) {
    return '$name owes the full amount';
  }

  @override
  String iOweFull(String name) {
    return 'I owe $name the full amount';
  }

  @override
  String get repeat => 'Repeat';

  @override
  String editLatestRepeat(String date) {
    return 'To change future repeats, edit the latest one ($date)';
  }

  @override
  String get stopsRepeating => 'Stops repeating. Repeats already added stay.';

  @override
  String nextRepeat(String date) {
    return 'Next: $date';
  }

  @override
  String get alsoChangeFuture => 'Also change future repeats';

  @override
  String get futureFields =>
      'Amount, split, payers, description, category and notes';

  @override
  String get onlyThisOne => 'Only this one changes';

  @override
  String get addPhoto => 'Add photo';

  @override
  String maxReceiptsNote(int max) {
    return '$max receipts is the most for one expense';
  }

  @override
  String get scanAReceipt => 'Scan a receipt';

  @override
  String receiptLooksLike(String currency) {
    return 'This receipt looks like $currency';
  }

  @override
  String switchToCurrencyQuestion(String currency) {
    return 'Switch the expense to $currency to read its items?';
  }

  @override
  String switchTo(String currency) {
    return 'Switch to $currency';
  }

  @override
  String get couldntReadItems => 'Couldn\'t read the items. Type them in.';

  @override
  String withName(String name) {
    return 'With $name';
  }

  @override
  String movesTo(String name) {
    return 'Moves to $name on Save';
  }

  @override
  String fromName(String name) {
    return 'From $name';
  }

  @override
  String get dontMove => 'Don\'t move';

  @override
  String get onlyLinkedMove =>
      'Only people on Evensies who are in both can be moved';

  @override
  String get auto => 'auto';

  @override
  String get noAutoRateForm =>
      'No automatic rate. Enter one, or leave it empty to keep this under Not converted.';

  @override
  String get emptyNotConverted => 'Empty: this stays under Not converted';

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
  String get yourRate => 'your rate';

  @override
  String get loginEmail => 'Continue with email';

  @override
  String get emailLoginTitle => 'Sign in with email';

  @override
  String get emailLoginIntro =>
      'We\'ll email you a 6-digit code. No password needed.';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailInvalid => 'Enter a valid email address';

  @override
  String get sendCode => 'Send code';

  @override
  String codeSentTo(String email) {
    return 'Enter the 6-digit code we sent to $email. It expires in 10 minutes.';
  }

  @override
  String get codeLabel => '6-digit code';

  @override
  String get verifyCode => 'Continue';

  @override
  String get resendCode => 'Resend code';

  @override
  String resendCodeIn(int seconds) {
    return 'Resend code in $seconds s';
  }

  @override
  String get codeResent => 'We sent a new code.';

  @override
  String get useDifferentEmail => 'Use a different email';

  @override
  String get codeCheckSpam => 'Nothing arrived? Check your spam folder.';

  @override
  String get errorCodeInvalid =>
      'That code is wrong or has expired. Ask for a new one.';

  @override
  String get errorEmailNotConfigured => 'This server doesn\'t send email.';

  @override
  String get errorEmailRejected =>
      'That address can\'t receive email. Check it for typos.';

  @override
  String get errorEmailTaken => 'Another account already uses this address.';

  @override
  String get errorEmailRequired =>
      'Email is your only way to sign in, so it can\'t be removed.';

  @override
  String get errorEmailUnavailable =>
      'Email isn\'t working right now. Try again later.';

  @override
  String get emailSaved => 'Email saved';

  @override
  String removeEmailTitle(String email) {
    return 'Remove $email?';
  }

  @override
  String get removeEmailMessage =>
      'You\'ll get no email summaries or reminders, and you can\'t sign in with it any more.';

  @override
  String get emailRemoved => 'Email removed';

  @override
  String get emailNeedsConnection => 'Changing your email needs a connection.';

  @override
  String get emailBouncedNote =>
      'Emails to this address bounce — change it or verify it again';

  @override
  String get emailVerifiedNote => 'Verified · other members never see it';

  @override
  String get changeEmail => 'Change email';

  @override
  String get emailAccountHelp =>
      'For signing in and email summaries. We send a code to check it\'s yours. Other members never see it.';

  @override
  String get removeEmail => 'Remove email';

  @override
  String get addEmail => 'Add email';

  @override
  String get addEmailHint => 'Sign in with it and get email summaries';

  @override
  String unblockedName(String name) {
    return 'Unblocked $name';
  }

  @override
  String get blockNeedsConnection => 'Blocking needs a connection.';

  @override
  String get blockedEmpty => 'You haven\'t blocked anyone.';

  @override
  String get blockedNeedsConnection => 'Blocked people need a connection';

  @override
  String get unblock => 'Unblock';

  @override
  String get blockedPeople => 'Blocked people';

  @override
  String get blockedHelp =>
      'Blocked people can\'t add you as a friend or send you reminders, and their changes don\'t notify or email you. Shared groups and balances stay as they are.';

  @override
  String get deletedGroupsEmpty => 'No deleted groups';

  @override
  String get deletedGroupsHelp =>
      'Restoring brings a group back for everyone, with everything in it.';

  @override
  String get deletedGroups => 'Deleted groups';

  @override
  String deletedGroupsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count groups can be restored',
      one: '1 group can be restored',
    );
    return '$_temp0';
  }

  @override
  String get exportNeedsConnection => 'Exporting needs a connection.';

  @override
  String get exportEverything => 'Export everything (JSON)';

  @override
  String get exportEverythingHint =>
      'Your profile, ways to get paid, settings and every group, deleted ones too';

  @override
  String get emailSummary => 'Email summary';

  @override
  String digestChoice(String choice) {
    String _temp0 = intl.Intl.selectLogic(choice, {
      'auto': 'Auto',
      'daily': 'Daily',
      'weekly': 'Weekly',
      'monthly': 'Monthly',
      'off': 'Off',
      'other': 'Auto',
    });
    return '$_temp0';
  }

  @override
  String get digestAutoHelp =>
      'Daily when your devices can\'t show notifications, otherwise monthly';

  @override
  String get digestAutoDaily => 'Auto — daily, because notifications are off';

  @override
  String get digestAutoMonthly =>
      'Auto — monthly, because your devices get notifications';

  @override
  String get digestNoEmail => 'Add an email under Account to get summaries';

  @override
  String get helpReportProblem => 'Report a problem or suggest a feature';

  @override
  String get helpReportProblemHint => 'On GitHub, where everyone can see it';

  @override
  String get helpContact => 'Email support';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get helpFeedback => 'Help & feedback';

  @override
  String get signOutEverywhere => 'Sign out on all devices';

  @override
  String get signOutEverywhereTitle => 'Sign out on all devices?';

  @override
  String get signOutEverywhereMessage =>
      'Every phone and browser signed in to your account is signed out, this one too. Your groups stay on the server.';

  @override
  String get signOutEverywhereOffline =>
      'Signing out on all devices needs a connection.';

  @override
  String get deleteAccountExportTip => 'Tip: Export everything first.';

  @override
  String get coverPhoto => 'Cover photo';

  @override
  String get coverPhotoHint =>
      'Shown on the group\'s header and in the list. Only members see it.';

  @override
  String get removeCover => 'Remove cover';

  @override
  String get coverNeedsConnection => 'Changing the cover needs a connection.';

  @override
  String get coverTooMany =>
      'That\'s a lot of cover changes. Try again in an hour.';

  @override
  String get deleteGroup => 'Delete group';

  @override
  String get deleteGroupHint => 'For everyone · any member can restore it';

  @override
  String deleteGroupTitle(String name) {
    return 'Delete “$name”?';
  }

  @override
  String get deleteGroupMessage =>
      'Deleted for everyone. Any member can restore it from Settings → Deleted groups.';

  @override
  String groupDeletedName(String name) {
    return 'Deleted “$name”';
  }

  @override
  String get groupDeletedBanner => 'This group is deleted';

  @override
  String get groupRestored => 'Group restored';

  @override
  String get deleteFriend => 'Delete friend';

  @override
  String deleteFriendTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String deleteFriendMessage(String name) {
    return 'Your non-group expenses with $name are deleted for both of you. Shared groups stay. You can restore them from Settings → Deleted groups, or by adding $name again.';
  }

  @override
  String friendDeleted(String name) {
    return 'Deleted $name';
  }

  @override
  String get block => 'Block';

  @override
  String blockTitle(String name) {
    return 'Block $name?';
  }

  @override
  String blockMessage(String name) {
    return '$name won\'t be able to add you as a friend or send you reminders, and their changes won\'t notify or email you. Shared groups and balances stay.';
  }

  @override
  String blockedName(String name) {
    return 'Blocked $name';
  }

  @override
  String get report => 'Report…';

  @override
  String get reportSubject => 'Evensies report';

  @override
  String reportBody(String userId) {
    return 'User id: $userId\n\nWhat happened:\n';
  }

  @override
  String get inviteByEmail => 'Invite by email…';

  @override
  String get inviteEmailField => 'Email (optional)';

  @override
  String get inviteEmailHelp =>
      'We\'ll email them an invite link. Only used for this invite.';

  @override
  String inviteByEmailTitle(String name) {
    return 'Invite $name by email';
  }

  @override
  String inviteEmailSent(String email) {
    return 'Invite sent to $email';
  }

  @override
  String get inviteEmailOfflineAdded =>
      'Member added. Inviting by email needs a connection — try again from the member list.';

  @override
  String get inviteEmailOffline => 'Inviting by email needs a connection.';

  @override
  String get inviteEmailLimit =>
      'Email limit reached for today — share the link instead.';

  @override
  String emailReminder(String choice) {
    return 'Email a reminder: $choice';
  }

  @override
  String get remindNever => 'Never';

  @override
  String remindDaysBefore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days before',
      one: '1 day before',
    );
    return '$_temp0';
  }

  @override
  String get blurbUpi => 'India: Paytm, PhonePe, Google Pay and other UPI apps';

  @override
  String get fieldUpi => 'UPI ID';

  @override
  String get fieldUpiHint => 'Like name@okicici';

  @override
  String get fieldUpiName => 'Name (optional)';

  @override
  String get fieldUpiNameHint => 'Shown to the person paying you';

  @override
  String get methodErrorUpi => 'Enter a UPI ID like name@bank';

  @override
  String get noUpiApp =>
      'No UPI app found. Copy the UPI ID and amount instead.';

  @override
  String get upiIdLabel => 'UPI ID';

  @override
  String get copyUpiId => 'Copy UPI ID';

  @override
  String get upiIdCopied => 'UPI ID copied';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get allExpenses => 'All expenses';

  @override
  String get groupBalances => 'Group balances';

  @override
  String get yourBalance => 'Your balance';

  @override
  String get dashboardOwesYou => 'Owes you';

  @override
  String get dashboardYouOwe => 'You owe';

  @override
  String get historyAndComments => 'History and comments';

  @override
  String get showEarlier => 'Show earlier';

  @override
  String get settleUpFirst => 'Settle up first';

  @override
  String deleteFriendSettleFirst(String name) {
    return 'You can delete $name as a friend once your non-group expenses are settled up.';
  }

  @override
  String get noMailApp =>
      'No email app found. Copy the details below and write from any email app.';

  @override
  String get copyAddress => 'Copy address';

  @override
  String get copyMessage => 'Copy message';

  @override
  String get browserNoStorage =>
      'This browser can\'t keep Evensies\' data. Try another browser, or a window that isn\'t private.';

  @override
  String get browserOtherTab =>
      'Evensies is already open in another tab of this browser. Use that tab, or close it and reload this one.';

  @override
  String get loginReview => 'Demo sign-in';

  @override
  String get loginReviewUsername => 'Username';

  @override
  String get loginReviewPassword => 'Password';

  @override
  String get loginReviewSubmit => 'Sign in';

  @override
  String get loginReviewWrong => 'Wrong username or password';
}
