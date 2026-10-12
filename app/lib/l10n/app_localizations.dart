import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_id.dart';
import 'app_localizations_it.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_nl.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_sv.dart';
import 'app_localizations_th.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('de'),
    Locale('es'),
    Locale('fr'),
    Locale('id'),
    Locale('it'),
    Locale('ja'),
    Locale('ko'),
    Locale('nl'),
    Locale('pl'),
    Locale('pt'),
    Locale('sv'),
    Locale('th'),
  ];

  /// The app's name; not translated.
  ///
  /// In en, this message translates to:
  /// **'Evensies'**
  String get appTitle;

  /// Button that closes a dialog without doing anything.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Button that deletes something.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Button that removes something (a receipt, a member, a payment method).
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// Button that saves a form.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Button that finishes a step.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Snackbar action that reverts a delete.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// Button that retries a failed load.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Button that acknowledges a message.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Button that closes a screen or sheet.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Button or menu item that opens a form to change something.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Button that adds something.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Banner shown while the app can't reach the server.
  ///
  /// In en, this message translates to:
  /// **'Offline — changes will sync later'**
  String get offlineBanner;

  /// Error under a text field whose text is over the limit.
  ///
  /// In en, this message translates to:
  /// **'Too long'**
  String get tooLong;

  /// Divider in the currency menu between the pinned currencies and the full list.
  ///
  /// In en, this message translates to:
  /// **'All currencies'**
  String get allCurrencies;

  /// An unexpected error with no code.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get errorUnexpected;

  /// The server can't be reached.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Try again later.'**
  String get errorNetwork;

  /// The server answered 429.
  ///
  /// In en, this message translates to:
  /// **'Too many tries. Wait a minute and try again.'**
  String get errorRateLimited;

  /// The server answered 404 NOT_FOUND.
  ///
  /// In en, this message translates to:
  /// **'That doesn\'t exist any more.'**
  String get errorNotFound;

  /// The server answered 403 FORBIDDEN.
  ///
  /// In en, this message translates to:
  /// **'You\'re not allowed to do that.'**
  String get errorForbidden;

  /// The server answered 400 VALIDATION.
  ///
  /// In en, this message translates to:
  /// **'The server refused it.'**
  String get errorValidation;

  /// Error code SUM_MISMATCH.
  ///
  /// In en, this message translates to:
  /// **'The split doesn\'t add up.'**
  String get errorSumMismatch;

  /// Error code PAYERS_SUM_MISMATCH.
  ///
  /// In en, this message translates to:
  /// **'The payers don\'t add up.'**
  String get errorPayersSumMismatch;

  /// Error code NEGATIVE_AMOUNT.
  ///
  /// In en, this message translates to:
  /// **'An amount is below zero.'**
  String get errorNegativeAmount;

  /// Error code NEGATIVE_SHARE (adjustment split).
  ///
  /// In en, this message translates to:
  /// **'Someone\'s share would be below zero.'**
  String get errorNegativeShare;

  /// Error code NEGATIVE_TOTAL (itemized split).
  ///
  /// In en, this message translates to:
  /// **'The total would be below zero.'**
  String get errorNegativeTotal;

  /// Error code ZERO_SUBTOTAL (itemized split).
  ///
  /// In en, this message translates to:
  /// **'Add item prices before tax, tip or discount.'**
  String get errorZeroSubtotal;

  /// Error code UNASSIGNED_ITEM (itemized split).
  ///
  /// In en, this message translates to:
  /// **'Every item needs at least one person.'**
  String get errorUnassignedItem;

  /// Error code NO_MEMBERS.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one person to split with.'**
  String get errorNoMembers;

  /// Error code INVALID_INPUT (a share or adjustment that isn't a number).
  ///
  /// In en, this message translates to:
  /// **'Check the numbers.'**
  String get errorInvalidInput;

  /// Error code BAD_RATE.
  ///
  /// In en, this message translates to:
  /// **'The exchange rate must be above zero.'**
  String get errorBadRate;

  /// Error code UNKNOWN_MEMBER.
  ///
  /// In en, this message translates to:
  /// **'It refers to someone who isn\'t in the group.'**
  String get errorUnknownMember;

  /// Error code UNKNOWN_CURRENCY.
  ///
  /// In en, this message translates to:
  /// **'The currency isn\'t supported.'**
  String get errorUnknownCurrency;

  /// Error code MEMBER_TAKEN.
  ///
  /// In en, this message translates to:
  /// **'That member is already taken.'**
  String get errorMemberTaken;

  /// Error code LIMIT_EXCEEDED.
  ///
  /// In en, this message translates to:
  /// **'The limit is reached.'**
  String get errorLimitExceeded;

  /// Error codes TOO_LARGE and IMAGE_TOO_LARGE.
  ///
  /// In en, this message translates to:
  /// **'The photo is too large.'**
  String get errorTooLarge;

  /// The picked photo isn't a JPEG (web) or the server answered NOT_JPEG.
  ///
  /// In en, this message translates to:
  /// **'Choose a JPEG photo'**
  String get errorNotJpeg;

  /// Error code FX_UNAVAILABLE.
  ///
  /// In en, this message translates to:
  /// **'Exchange rates aren\'t available right now.'**
  String get errorFxUnavailable;

  /// Error code IMPORT_FAILED.
  ///
  /// In en, this message translates to:
  /// **'That file couldn\'t be imported.'**
  String get errorImportFailed;

  /// Error code AUTH_NOT_CONFIGURED.
  ///
  /// In en, this message translates to:
  /// **'This server can\'t sign you in that way.'**
  String get errorAuthNotConfigured;

  /// Error code DUPLICATE.
  ///
  /// In en, this message translates to:
  /// **'That already exists.'**
  String get errorDuplicate;

  /// Any other error code; {code} is the server's code, e.g. VALIDATION. Keep it as is.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong ({code}).'**
  String errorGeneric(String code);

  /// A receipt photo the server refused. {name} is the expense's description, {reason} one of the rejection reasons.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the receipt on “{name}”: {reason}'**
  String rejectedReceipt(String name, String reason);

  /// Like rejectedReceipt when the expense isn't known.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the receipt on an expense: {reason}'**
  String rejectedReceiptUnnamed(String reason);

  /// Removing a receipt was refused.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save removing a receipt from “{name}”: {reason}'**
  String rejectedReceiptRemove(String name, String reason);

  /// Like rejectedReceiptRemove when the expense isn't known.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save removing a receipt from an expense: {reason}'**
  String rejectedReceiptRemoveUnnamed(String reason);

  /// A new repeating expense was refused.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save repeating “{name}”: {reason}'**
  String rejectedRepeating(String name, String reason);

  /// Like rejectedRepeating without a description.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save a repeating expense: {reason}'**
  String rejectedRepeatingUnnamed(String reason);

  /// A change to a repeating expense's future was refused.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save a change to future “{name}”: {reason}'**
  String rejectedSeriesChange(String name, String reason);

  /// Like rejectedSeriesChange without a description.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save a change to a repeating expense: {reason}'**
  String rejectedSeriesChangeUnnamed(String reason);

  /// Stopping a repeating expense was refused.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save stopping “{name}” from repeating: {reason}'**
  String rejectedSeriesStop(String name, String reason);

  /// Like rejectedSeriesStop without a description.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save stopping a repeating expense: {reason}'**
  String rejectedSeriesStopUnnamed(String reason);

  /// The first expense of a new repeating expense was saved, but the series was refused.
  ///
  /// In en, this message translates to:
  /// **'“{name}” was saved but won\'t repeat: {reason}'**
  String rejectedSavedNoRepeat(String name, String reason);

  /// Restoring a deleted payment was refused.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save restoring a payment: {reason}'**
  String rejectedPaymentRestore(String reason);

  /// A new expense was refused.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save the new expense “{name}”: {reason}'**
  String rejectedNewExpense(String name, String reason);

  /// Like rejectedNewExpense without a description.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save a new expense: {reason}'**
  String rejectedNewExpenseUnnamed(String reason);

  /// A change to an expense was refused.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save a change to “{name}”: {reason}'**
  String rejectedExpenseChange(String name, String reason);

  /// Like rejectedExpenseChange without a description.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save a change to an expense: {reason}'**
  String rejectedExpenseChangeUnnamed(String reason);

  /// Deleting an expense was refused.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save deleting “{name}”: {reason}'**
  String rejectedExpenseDelete(String name, String reason);

  /// Like rejectedExpenseDelete without a description.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save deleting an expense: {reason}'**
  String rejectedExpenseDeleteUnnamed(String reason);

  /// Restoring an expense was refused.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save restoring “{name}”: {reason}'**
  String rejectedExpenseRestore(String name, String reason);

  /// Like rejectedExpenseRestore without a description.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save restoring an expense: {reason}'**
  String rejectedExpenseRestoreUnnamed(String reason);

  /// A comment on an expense was refused.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save a comment on “{name}”: {reason}'**
  String rejectedComment(String name, String reason);

  /// Like rejectedComment without a description.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save a comment on an expense: {reason}'**
  String rejectedCommentUnnamed(String reason);

  /// A comment on a payment was refused.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save a comment on a payment: {reason}'**
  String rejectedPaymentComment(String reason);

  /// Deleting a comment was refused.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save deleting a comment: {reason}'**
  String rejectedCommentDelete(String reason);

  /// A new payment was refused.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save a payment: {reason}'**
  String rejectedPayment(String reason);

  /// Deleting a payment was refused.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save deleting a payment: {reason}'**
  String rejectedPaymentDelete(String reason);

  /// Confirming a payment was refused.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save confirming a payment: {reason}'**
  String rejectedPaymentConfirm(String reason);

  /// A change to the group's settings was refused.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save a group settings change: {reason}'**
  String rejectedGroupSettings(String reason);

  /// Adding a member was refused; {name} is the member's name.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save adding {name}: {reason}'**
  String rejectedMemberAdd(String name, String reason);

  /// Like rejectedMemberAdd without a name.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save adding a member: {reason}'**
  String rejectedMemberAddUnnamed(String reason);

  /// Removing a member was refused.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save removing a member: {reason}'**
  String rejectedMemberRemove(String reason);

  /// Any other refused change.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save a change: {reason}'**
  String rejectedOther(String reason);

  /// {reason} in the rejected* messages: the receipt limit. Lower case, it continues a sentence.
  ///
  /// In en, this message translates to:
  /// **'an expense can have at most 10 receipts'**
  String get reasonReceiptLimit;

  /// {reason}: the repeating expense limit.
  ///
  /// In en, this message translates to:
  /// **'a group can have at most 100 repeating expenses'**
  String get reasonSeriesLimit;

  /// {reason}: the receipt photo never reached the server.
  ///
  /// In en, this message translates to:
  /// **'the photo didn\'t upload'**
  String get reasonNotUploaded;

  /// {reason}: code SUM_MISMATCH.
  ///
  /// In en, this message translates to:
  /// **'the split doesn\'t add up'**
  String get reasonSumMismatch;

  /// {reason}: code PAYERS_SUM_MISMATCH.
  ///
  /// In en, this message translates to:
  /// **'the payers don\'t add up'**
  String get reasonPayersSumMismatch;

  /// {reason}: code NEGATIVE_AMOUNT.
  ///
  /// In en, this message translates to:
  /// **'an amount is below zero'**
  String get reasonNegativeAmount;

  /// {reason}: code UNKNOWN_MEMBER.
  ///
  /// In en, this message translates to:
  /// **'it refers to someone who isn\'t in the group'**
  String get reasonUnknownMember;

  /// {reason}: code UNKNOWN_CURRENCY.
  ///
  /// In en, this message translates to:
  /// **'the currency isn\'t supported'**
  String get reasonUnknownCurrency;

  /// {reason}: code MEMBER_TAKEN.
  ///
  /// In en, this message translates to:
  /// **'that member is already taken'**
  String get reasonMemberTaken;

  /// {reason}: code LIMIT_EXCEEDED.
  ///
  /// In en, this message translates to:
  /// **'the group is full'**
  String get reasonGroupFull;

  /// {reason}: code FORBIDDEN.
  ///
  /// In en, this message translates to:
  /// **'you\'re not allowed to make that change'**
  String get reasonForbidden;

  /// {reason}: any other code.
  ///
  /// In en, this message translates to:
  /// **'the server refused it'**
  String get reasonRefused;

  /// Why you can't leave a group yet. {amount} is formatted money, e.g. €12.00.
  ///
  /// In en, this message translates to:
  /// **'You owe {amount} · settle up first'**
  String leaveOwe(String amount);

  /// Like leaveOwe for a debt in another currency; {currency} is a code like USD.
  ///
  /// In en, this message translates to:
  /// **'You owe {amount} · settle up in {currency} first'**
  String leaveOweIn(String amount, String currency);

  /// Why you can't leave yet: others owe you.
  ///
  /// In en, this message translates to:
  /// **'You are owed {amount} · settle up first'**
  String leaveOwed(String amount);

  /// Like leaveOwed for another currency.
  ///
  /// In en, this message translates to:
  /// **'You are owed {amount} · settle up in {currency} first'**
  String leaveOwedIn(String amount, String currency);

  /// Why you can't leave: repeating expenses still include you. {names} is a list like "Rent, Netflix and 2 more".
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{You\'re still in 1 repeating expense ({names}) · edit the latest one or stop it first} other{You\'re still in {count} repeating expenses ({names}) · edit the latest one or stop them first}}'**
  String leaveSeries(int count, String names);

  /// The end of a list of at most three repeating expense names, e.g. "Rent, Netflix, Gym and 2 more".
  ///
  /// In en, this message translates to:
  /// **'{names} and {count} more'**
  String seriesNamesMore(String names, int count);

  /// Stands in for a repeating expense without a description in a list of names.
  ///
  /// In en, this message translates to:
  /// **'an expense'**
  String get seriesUnnamed;

  /// Separator between names in a list, e.g. "Rent, Netflix". Include any spaces.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get listJoiner;

  /// Repeat menu: the expense doesn't repeat.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get repeatNever;

  /// Repeat menu option.
  ///
  /// In en, this message translates to:
  /// **'Every week'**
  String get repeatWeekly;

  /// Repeat menu option.
  ///
  /// In en, this message translates to:
  /// **'Every 2 weeks'**
  String get repeatBiweekly;

  /// Repeat menu option.
  ///
  /// In en, this message translates to:
  /// **'Every month'**
  String get repeatMonthly;

  /// Repeat menu option.
  ///
  /// In en, this message translates to:
  /// **'Every year'**
  String get repeatYearly;

  /// Share summary of a period: heading for a currency that wasn't converted to the group currency.
  ///
  /// In en, this message translates to:
  /// **'Not converted · {currency}'**
  String summaryNotConverted(String currency);

  /// Share summary line.
  ///
  /// In en, this message translates to:
  /// **'Total spent: {amount}'**
  String summaryTotalSpent(String amount);

  /// Share summary line.
  ///
  /// In en, this message translates to:
  /// **'You paid: {paid} · Your share: {share}'**
  String summaryPaidShare(String paid, String share);

  /// Share summary line.
  ///
  /// In en, this message translates to:
  /// **'Payments made: {made} · received: {received}'**
  String summaryPayments(String made, String received);

  /// Share summary line; {list} is like "Dining out €30.00, Groceries €12.00".
  ///
  /// In en, this message translates to:
  /// **'Top categories: {list}'**
  String summaryTopCategories(String list);

  /// Share summary heading for the balances as of today.
  ///
  /// In en, this message translates to:
  /// **'Balances today'**
  String get summaryBalancesToday;

  /// Share summary balance line.
  ///
  /// In en, this message translates to:
  /// **'{name} gets back {amount}'**
  String summaryGetsBack(String name, String amount);

  /// Share summary balance line.
  ///
  /// In en, this message translates to:
  /// **'{name} owes {amount}'**
  String summaryOwes(String name, String amount);

  /// Last line of a shared text.
  ///
  /// In en, this message translates to:
  /// **'Shared from Evensies'**
  String get summaryFooter;

  /// Payment method type: a Korean bank account.
  ///
  /// In en, this message translates to:
  /// **'Korean bank'**
  String get koreanBank;

  /// Share text of Request. {group} is the group name, or "our shared expenses" for expenses outside a group.
  ///
  /// In en, this message translates to:
  /// **'You owe me {amount} for {group} on Evensies.'**
  String requestText(String amount, String group);

  /// Like requestText with the ways to pay, e.g. "PayPal https://… · IBAN •••• 1234".
  ///
  /// In en, this message translates to:
  /// **'You owe me {amount} for {group} on Evensies. Pay with: {ways}'**
  String requestTextWays(String amount, String group, String ways);

  /// {group} in requestText for expenses with a friend outside any group.
  ///
  /// In en, this message translates to:
  /// **'our shared expenses'**
  String get requestNoGroup;

  /// Leaving a group while changes are still being sent.
  ///
  /// In en, this message translates to:
  /// **'Still syncing. Try again in a moment.'**
  String get leaveSyncing;

  /// Leaving a group needs a connection.
  ///
  /// In en, this message translates to:
  /// **'You need to be online to leave'**
  String get leaveOffline;

  /// Moving an expense to another group failed offline.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t move it. Try again when you\'re online'**
  String get moveOffline;

  /// Moving an expense failed; {reason} is an error sentence.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t move it: {reason}'**
  String moveFailed(String reason);

  /// The camera or photo library permission was denied.
  ///
  /// In en, this message translates to:
  /// **'Evensies has no access. Allow it in the Settings app.'**
  String get photoNoAccess;

  /// The camera couldn't be opened.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the camera.'**
  String get photoNoCamera;

  /// The photo library couldn't be opened.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the photo library.'**
  String get photoNoLibrary;

  /// The picked photo couldn't be read.
  ///
  /// In en, this message translates to:
  /// **'That photo couldn\'t be used. Try another one.'**
  String get photoUnusable;

  /// Payment method form error (code USERNAME): a PayPal, Venmo or Revolut username.
  ///
  /// In en, this message translates to:
  /// **'Letters, digits, . _ - only (max 40)'**
  String get methodErrorUsername;

  /// Payment method form error (code LINK_PREFIX); {prefix} is a URL like https://wise.com/.
  ///
  /// In en, this message translates to:
  /// **'Must start with {prefix}'**
  String methodErrorLinkPrefix(String prefix);

  /// Payment method form error (code TOO_LONG): a link over 200 characters.
  ///
  /// In en, this message translates to:
  /// **'Max 200 characters'**
  String get methodErrorTooLong;

  /// Payment method form error (code IBAN).
  ///
  /// In en, this message translates to:
  /// **'Not a valid IBAN'**
  String get methodErrorIban;

  /// Payment method form error (code HOLDER).
  ///
  /// In en, this message translates to:
  /// **'Account holder name (1–70 characters)'**
  String get methodErrorHolder;

  /// Payment method form error (code BIC).
  ///
  /// In en, this message translates to:
  /// **'BIC has 8 or 11 characters'**
  String get methodErrorBic;

  /// Payment method form error (code KR_ACCOUNT): a Korean bank account number.
  ///
  /// In en, this message translates to:
  /// **'Digits and hyphens, 8–20 digits'**
  String get methodErrorKrAccount;

  /// Payment method form error (code BANK).
  ///
  /// In en, this message translates to:
  /// **'Bank name (1–30 characters)'**
  String get methodErrorBank;

  /// Payment method error (code UNKNOWN_TYPE).
  ///
  /// In en, this message translates to:
  /// **'Unknown type'**
  String get methodErrorUnknownType;

  /// Payment method error (code TOO_MANY).
  ///
  /// In en, this message translates to:
  /// **'At most 8 ways to get paid, and 3 of each bank type'**
  String get methodErrorTooMany;

  /// In-app notification banner: hides it.
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get bannerDismiss;

  /// In-app notification banner: opens what it is about.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get bannerView;

  /// Login screen line under the app name.
  ///
  /// In en, this message translates to:
  /// **'Split expenses with friends. No ads, no upsells.'**
  String get loginTagline;

  /// Sign-in button.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get loginApple;

  /// Sign-in button.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get loginGoogle;

  /// Web login screen when the server offers neither Apple, Google nor dev sign-in.
  ///
  /// In en, this message translates to:
  /// **'This server has no sign-in for the browser yet.'**
  String get loginWebUnavailable;

  /// Title of the name screen right after the first sign-in.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcomeTitle;

  /// Title of the name screen opened from Settings.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourNameTitle;

  /// Name screen heading after the first sign-in.
  ///
  /// In en, this message translates to:
  /// **'What should your friends call you?'**
  String get nameQuestion;

  /// Name screen heading when opened from Settings.
  ///
  /// In en, this message translates to:
  /// **'This is the name other members see.'**
  String get nameExplain;

  /// Name screen help text.
  ///
  /// In en, this message translates to:
  /// **'It is shown to people in your groups. You can change it later in Settings.'**
  String get nameHelp;

  /// Label of a person's name field.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// The reason the system's Face ID, Touch ID or passcode prompt shows.
  ///
  /// In en, this message translates to:
  /// **'Unlock Evensies'**
  String get lockReason;

  /// Lock screen title.
  ///
  /// In en, this message translates to:
  /// **'Evensies is locked'**
  String get lockTitle;

  /// Lock screen explanation.
  ///
  /// In en, this message translates to:
  /// **'Unlock with Face ID, Touch ID, your fingerprint or the device passcode.'**
  String get lockSubtitle;

  /// Lock screen button that asks for Face ID, a fingerprint or the passcode.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get lockUnlock;

  /// Lock screen: confirming sign-out (the way out when the passcode is forgotten).
  ///
  /// In en, this message translates to:
  /// **'Sign out and remove this device\'s data? Your groups stay on the server.'**
  String get lockSignOutConfirm;

  /// Button that signs out.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// Home-screen widget line before an amount others owe you. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'You are owed'**
  String get widgetOwed;

  /// Home-screen widget line before an amount you owe. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'You owe'**
  String get widgetOwe;

  /// Home-screen widget when signed out.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see your balance'**
  String get widgetSignedOut;

  /// Home-screen widget when every balance is zero.
  ///
  /// In en, this message translates to:
  /// **'All settled up'**
  String get widgetSettled;

  /// Home-screen widget footer; {time} is a short date and time like "11 Oct, 10:42".
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String widgetUpdated(String time);

  /// Title of the sheet that picks a receipt photo.
  ///
  /// In en, this message translates to:
  /// **'Add a receipt'**
  String get receiptAdd;

  /// Picks a photo with the camera.
  ///
  /// In en, this message translates to:
  /// **'Take photo'**
  String get photoTake;

  /// Picks a photo from the photo library.
  ///
  /// In en, this message translates to:
  /// **'Choose from library'**
  String get photoChoose;

  /// In the browser: picks a photo file (phones' browsers also offer the camera).
  ///
  /// In en, this message translates to:
  /// **'Choose a file'**
  String get photoChooseFile;

  /// A receipt photo that isn't on this device and can't be downloaded now.
  ///
  /// In en, this message translates to:
  /// **'Available when online'**
  String get availableWhenOnline;

  /// Accessibility label of a receipt photo.
  ///
  /// In en, this message translates to:
  /// **'Receipt photo'**
  String get receiptPhoto;

  /// Sharing a receipt photo that isn't on this device while offline.
  ///
  /// In en, this message translates to:
  /// **'The photo is available when online'**
  String get receiptAvailableOnline;

  /// Confirm dialog title.
  ///
  /// In en, this message translates to:
  /// **'Remove receipt?'**
  String get receiptRemoveTitle;

  /// Confirm dialog text when removing a receipt photo.
  ///
  /// In en, this message translates to:
  /// **'It is removed for everyone in the group.'**
  String get receiptRemoveMessage;

  /// Title of the full-screen receipt photo.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receiptTitle;

  /// Title of the full-screen receipt photo when there are several.
  ///
  /// In en, this message translates to:
  /// **'Receipt {index} of {count}'**
  String receiptTitleOf(int index, int count);

  /// Tooltip of the share button on a receipt photo.
  ///
  /// In en, this message translates to:
  /// **'Share or save'**
  String get shareOrSave;

  /// Button or tooltip that opens the share sheet (copies to the clipboard in the browser).
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Snackbar after copying a text to share (the browser has no share sheet).
  ///
  /// In en, this message translates to:
  /// **'Copied to the clipboard'**
  String get copiedToClipboard;

  /// Settings screen title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Removes the profile photo.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get photoRemove;

  /// Error when changing the profile photo offline.
  ///
  /// In en, this message translates to:
  /// **'Changing your photo needs a connection.'**
  String get photoNeedsConnection;

  /// Error after too many profile photo changes.
  ///
  /// In en, this message translates to:
  /// **'Too many photo changes. Try again in an hour.'**
  String get photoTooMany;

  /// Error when a notification switch couldn't be saved.
  ///
  /// In en, this message translates to:
  /// **'Could not save notification settings. Check your connection.'**
  String get notifSaveFailed;

  /// Error when changing the home currency offline.
  ///
  /// In en, this message translates to:
  /// **'Changing your home currency needs a connection.'**
  String get homeCurrencyNeedsConnection;

  /// Accessibility label of the profile photo button.
  ///
  /// In en, this message translates to:
  /// **'Change profile photo'**
  String get changePhoto;

  /// Subtitle under the user's name in Settings.
  ///
  /// In en, this message translates to:
  /// **'Your name · tap to change'**
  String get yourNameTapToChange;

  /// Settings entry and screen title for the user's payment methods (PayPal, IBAN…).
  ///
  /// In en, this message translates to:
  /// **'Ways to get paid'**
  String get waysToGetPaid;

  /// Subtitle of the Ways to get paid entry.
  ///
  /// In en, this message translates to:
  /// **'PayPal, Wise, IBAN, bank account…'**
  String get waysToGetPaidHint;

  /// Settings entry: the currency balances are also shown in.
  ///
  /// In en, this message translates to:
  /// **'Home currency'**
  String get homeCurrency;

  /// Subtitle of Home currency when the user never picked one.
  ///
  /// In en, this message translates to:
  /// **'From your region · balances also show ≈ in it'**
  String get homeCurrencyFromRegion;

  /// Subtitle of Home currency.
  ///
  /// In en, this message translates to:
  /// **'Balances also show ≈ in it'**
  String get homeCurrencyPicked;

  /// Settings section heading.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// Notification switch.
  ///
  /// In en, this message translates to:
  /// **'Expenses and payments'**
  String get notifExpenses;

  /// Notification switch.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get notifComments;

  /// Notification switch.
  ///
  /// In en, this message translates to:
  /// **'Members and group changes'**
  String get notifMembers;

  /// Notification switch.
  ///
  /// In en, this message translates to:
  /// **'Reminders from friends'**
  String get notifReminders;

  /// Shown when the notification settings couldn't be loaded.
  ///
  /// In en, this message translates to:
  /// **'Notification settings need a connection'**
  String get notifNeedConnection;

  /// Note under the notification switches.
  ///
  /// In en, this message translates to:
  /// **'Only changes made by other people notify you.'**
  String get notifOthersOnly;

  /// Note under the notification switches in the browser (no web push).
  ///
  /// In en, this message translates to:
  /// **'Notifications go to your phone; the browser updates every minute while it is open.'**
  String get notifWebNote;

  /// Settings section heading.
  ///
  /// In en, this message translates to:
  /// **'Export & import'**
  String get exportImport;

  /// Shown when there is nothing to export.
  ///
  /// In en, this message translates to:
  /// **'No groups to export.'**
  String get noGroupsToExport;

  /// Label for expenses with a friend outside any group.
  ///
  /// In en, this message translates to:
  /// **'Non-group'**
  String get nonGroup;

  /// Label of the expenses with one friend outside any group; {name} is the friend's name.
  ///
  /// In en, this message translates to:
  /// **'Non-group · {name}'**
  String nonGroupWith(String name);

  /// Export menu item.
  ///
  /// In en, this message translates to:
  /// **'Export JSON'**
  String get exportJson;

  /// Export menu item.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// Export menu item: the data plus every receipt photo.
  ///
  /// In en, this message translates to:
  /// **'ZIP with receipts'**
  String get exportZip;

  /// Import menu item.
  ///
  /// In en, this message translates to:
  /// **'Import Splitwise CSV'**
  String get importSplitwise;

  /// Snackbar after importing a Splitwise file.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Imported 1 expense} other{Imported {count} expenses}}'**
  String importedCount(int count);

  /// Settings section heading.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get server;

  /// Text field label.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get serverUrl;

  /// Helper under the server URL field.
  ///
  /// In en, this message translates to:
  /// **'Default: {url}'**
  String serverDefault(String url);

  /// Snackbar after saving the server URL.
  ///
  /// In en, this message translates to:
  /// **'Server URL saved'**
  String get serverSaved;

  /// Settings section heading.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// Opens the open-source licenses of the libraries the app uses.
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get licenses;

  /// Settings entry.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// Confirm dialog title.
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get signOutTitle;

  /// Confirm dialog text.
  ///
  /// In en, this message translates to:
  /// **'Local data on this device is removed. Changes that have not synced yet will be lost.'**
  String get signOutMessage;

  /// Confirm dialog title.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get deleteAccountTitle;

  /// Confirm dialog text.
  ///
  /// In en, this message translates to:
  /// **'Your memberships become placeholders. Group data stays with the other members. This cannot be undone.'**
  String get deleteAccountMessage;

  /// Settings entry and dialog title: the app's language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// The language option that follows the phone; {language} is the language it gives, in that language, e.g. "Deutsch".
  ///
  /// In en, this message translates to:
  /// **'System ({language})'**
  String languageSystem(String language);

  /// Settings section heading: light or dark look.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// Appearance option that follows the phone.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get appearanceSystem;

  /// Appearance option.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get appearanceLight;

  /// Appearance option.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get appearanceDark;

  /// Settings section heading.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// Switch: ask for Face ID, Touch ID, a fingerprint or the passcode to open the app.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get appLock;

  /// Explanation under the App lock switch.
  ///
  /// In en, this message translates to:
  /// **'Face ID, Touch ID or fingerprint, with the device passcode as fallback. Locks after a minute away.'**
  String get appLockHint;

  /// Confirm dialog title; {method} is a payment method name like PayPal or IBAN.
  ///
  /// In en, this message translates to:
  /// **'Remove {method}?'**
  String methodRemoveTitle(String method);

  /// Ways to get paid screen when offline.
  ///
  /// In en, this message translates to:
  /// **'Connect to the internet to edit your ways to get paid.'**
  String get methodsOffline;

  /// Ways to get paid screen when loading failed for another reason.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your ways to get paid.'**
  String get methodsLoadFailed;

  /// Ways to get paid screen intro.
  ///
  /// In en, this message translates to:
  /// **'Group members see these when they owe you money, so they can pay you in one tap. Evensies never moves money itself.'**
  String get methodsIntro;

  /// Ways to get paid screen with none added.
  ///
  /// In en, this message translates to:
  /// **'No ways to get paid yet.'**
  String get methodsEmpty;

  /// Payment method type description.
  ///
  /// In en, this message translates to:
  /// **'PayPal.me link, amount filled in'**
  String get blurbPaypal;

  /// Payment method type description.
  ///
  /// In en, this message translates to:
  /// **'Wise Quick Pay link, amount filled in'**
  String get blurbWise;

  /// Payment method type description.
  ///
  /// In en, this message translates to:
  /// **'Venmo username (US)'**
  String get blurbVenmo;

  /// Payment method type description.
  ///
  /// In en, this message translates to:
  /// **'Revolut.me username'**
  String get blurbRevolut;

  /// Payment method type description. Keep "송금코드" (KakaoPay's own Korean name for it).
  ///
  /// In en, this message translates to:
  /// **'KakaoPay 송금코드 link'**
  String get blurbKakaopay;

  /// Payment method type description.
  ///
  /// In en, this message translates to:
  /// **'Bank transfer (SEPA QR for EUR)'**
  String get blurbIban;

  /// Payment method type description.
  ///
  /// In en, this message translates to:
  /// **'Korean bank account (Toss, bank apps)'**
  String get blurbKrBank;

  /// Payment method form field.
  ///
  /// In en, this message translates to:
  /// **'PayPal.me username'**
  String get fieldPaypal;

  /// Helper text.
  ///
  /// In en, this message translates to:
  /// **'Your PayPal.me username, e.g. anna'**
  String get fieldPaypalHint;

  /// Payment method form field.
  ///
  /// In en, this message translates to:
  /// **'Revolut.me username'**
  String get fieldRevolut;

  /// Helper text.
  ///
  /// In en, this message translates to:
  /// **'Your Revolut.me username, e.g. anna'**
  String get fieldRevolutHint;

  /// Payment method form field.
  ///
  /// In en, this message translates to:
  /// **'Venmo username'**
  String get fieldVenmo;

  /// Helper text.
  ///
  /// In en, this message translates to:
  /// **'Without the @, e.g. anna-rossi'**
  String get fieldVenmoHint;

  /// Payment method form field.
  ///
  /// In en, this message translates to:
  /// **'Wise Quick Pay link'**
  String get fieldWise;

  /// Helper text; Wise's menu names are in English in many languages, translate if Wise does.
  ///
  /// In en, this message translates to:
  /// **'In Wise: Payments → Quick Pay → copy link (https://wise.com/pay/…)'**
  String get fieldWiseHint;

  /// Payment method form field.
  ///
  /// In en, this message translates to:
  /// **'KakaoPay 송금코드 link'**
  String get fieldKakaopay;

  /// Helper text; keep the Korean menu names.
  ///
  /// In en, this message translates to:
  /// **'In KakaoPay: 송금 → 송금코드 → copy link (https://qr.kakaopay.com/…)'**
  String get fieldKakaopayHint;

  /// Payment method form field.
  ///
  /// In en, this message translates to:
  /// **'Account holder'**
  String get fieldHolder;

  /// Helper text.
  ///
  /// In en, this message translates to:
  /// **'Name exactly as on the account'**
  String get fieldHolderHint;

  /// Payment method form field.
  ///
  /// In en, this message translates to:
  /// **'IBAN'**
  String get fieldIban;

  /// Helper text with an example IBAN.
  ///
  /// In en, this message translates to:
  /// **'e.g. DE89 3704 0044 0532 0130 00'**
  String get fieldIbanHint;

  /// Payment method form field.
  ///
  /// In en, this message translates to:
  /// **'BIC (optional)'**
  String get fieldBic;

  /// Helper text.
  ///
  /// In en, this message translates to:
  /// **'8 or 11 characters'**
  String get fieldBicHint;

  /// Payment method form field.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get fieldBank;

  /// Helper text with Korean bank names; keep them.
  ///
  /// In en, this message translates to:
  /// **'e.g. 신한은행, Toss Bank'**
  String get fieldBankHint;

  /// Payment method form field.
  ///
  /// In en, this message translates to:
  /// **'Account number'**
  String get fieldAccountNumber;

  /// Helper text.
  ///
  /// In en, this message translates to:
  /// **'Digits, hyphens optional'**
  String get fieldAccountNumberHint;

  /// Snackbar after copying an amount; {amount} is formatted money.
  ///
  /// In en, this message translates to:
  /// **'Amount copied: {amount}'**
  String amountCopied(String amount);

  /// A payment app link couldn't be opened.
  ///
  /// In en, this message translates to:
  /// **'Could not open {link}'**
  String couldNotOpen(String link);

  /// Settle up when the other person's payment methods can't be loaded.
  ///
  /// In en, this message translates to:
  /// **'Offline: ways to pay are not available'**
  String get payOffline;

  /// Settle up while loading the other person's payment methods.
  ///
  /// In en, this message translates to:
  /// **'Loading ways to pay…'**
  String get payLoading;

  /// Settle up when the person you pay has no payment methods.
  ///
  /// In en, this message translates to:
  /// **'Ask {name} to add a way to get paid'**
  String payAskToAdd(String name);

  /// Bank transfer sheet title.
  ///
  /// In en, this message translates to:
  /// **'Pay {name} {amount}'**
  String payTitle(String name, String amount);

  /// Under the EU bank transfer QR code.
  ///
  /// In en, this message translates to:
  /// **'Scan with your banking app (SEPA QR)'**
  String get payScanQr;

  /// Bank sheet note for non-EUR amounts.
  ///
  /// In en, this message translates to:
  /// **'QR code is only available for EUR transfers.'**
  String get payQrEurOnly;

  /// Bank sheet row label.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get bankLabel;

  /// Bank sheet row label.
  ///
  /// In en, this message translates to:
  /// **'IBAN'**
  String get ibanLabel;

  /// Bank sheet row label: account number.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountLabel;

  /// Bank sheet row label.
  ///
  /// In en, this message translates to:
  /// **'BIC'**
  String get bicLabel;

  /// Bank sheet row label: account holder.
  ///
  /// In en, this message translates to:
  /// **'Holder'**
  String get holderLabel;

  /// Label of an amount (field or row).
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Copy IBAN'**
  String get copyIban;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Copy account'**
  String get copyAccount;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Copy amount'**
  String get copyAmount;

  /// Snackbar.
  ///
  /// In en, this message translates to:
  /// **'IBAN copied'**
  String get ibanCopied;

  /// Snackbar.
  ///
  /// In en, this message translates to:
  /// **'Account copied'**
  String get accountCopied;

  /// Snackbar after editing a payment.
  ///
  /// In en, this message translates to:
  /// **'Payment updated'**
  String get paymentUpdated;

  /// Snackbar after recording a payment the receiver still has to confirm.
  ///
  /// In en, this message translates to:
  /// **'Recorded {amount}. {name} will confirm.'**
  String paymentRecordedPending(String amount, String name);

  /// Like paymentRecordedPending when the receiver's name is unknown.
  ///
  /// In en, this message translates to:
  /// **'Recorded {amount}. They will confirm.'**
  String paymentRecordedPendingUnnamed(String amount);

  /// Snackbar after recording a payment.
  ///
  /// In en, this message translates to:
  /// **'Payment of {amount} recorded'**
  String paymentRecorded(String amount);

  /// A member name marked as the user, in pickers.
  ///
  /// In en, this message translates to:
  /// **'{name} (you)'**
  String youSuffix(String name);

  /// Payment sheet title.
  ///
  /// In en, this message translates to:
  /// **'Record a payment'**
  String get recordPayment;

  /// Payment sheet title when editing.
  ///
  /// In en, this message translates to:
  /// **'Edit payment'**
  String get editPayment;

  /// Payment sheet: who paid.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get fromLabel;

  /// Payment sheet: who received.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get toLabel;

  /// Tooltip of the button that swaps From and To.
  ///
  /// In en, this message translates to:
  /// **'Swap'**
  String get swap;

  /// Payment sheet error.
  ///
  /// In en, this message translates to:
  /// **'Pick two different people'**
  String get pickTwoPeople;

  /// Note when editing a payment that has comments.
  ///
  /// In en, this message translates to:
  /// **'Comments stay with the old payment'**
  String get commentsStayOld;

  /// Payment sheet save button.
  ///
  /// In en, this message translates to:
  /// **'Record payment'**
  String get recordPaymentButton;

  /// Payment screen when the payment isn't stored locally.
  ///
  /// In en, this message translates to:
  /// **'This payment isn\'t on this device'**
  String get paymentNotHere;

  /// Explanation under paymentNotHere and expenseNotHere.
  ///
  /// In en, this message translates to:
  /// **'It hasn\'t synced yet, or its group was left.'**
  String get notSyncedOrLeft;

  /// Stands in for a member whose name isn't known.
  ///
  /// In en, this message translates to:
  /// **'Someone'**
  String get someone;

  /// Payment screen title for a payment replaced by an edit.
  ///
  /// In en, this message translates to:
  /// **'Edited payment'**
  String get paymentEdited;

  /// Payment screen title for a deleted payment.
  ///
  /// In en, this message translates to:
  /// **'Deleted payment'**
  String get paymentDeleted;

  /// Payment screen title.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get payment;

  /// Banner on a payment replaced by an edit.
  ///
  /// In en, this message translates to:
  /// **'This payment was edited'**
  String get paymentWasEdited;

  /// Banner text.
  ///
  /// In en, this message translates to:
  /// **'The edited payment counts instead. Its comments stay here.'**
  String get paymentWasEditedNote;

  /// Banner on a deleted payment.
  ///
  /// In en, this message translates to:
  /// **'This payment was deleted'**
  String get paymentWasDeleted;

  /// Banner text on a deleted payment.
  ///
  /// In en, this message translates to:
  /// **'It doesn\'t count in balances.'**
  String get paymentNotCounted;

  /// Button that brings back something deleted.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// Payment screen headline.
  ///
  /// In en, this message translates to:
  /// **'You paid {name}'**
  String youPaidName(String name);

  /// Payment screen headline.
  ///
  /// In en, this message translates to:
  /// **'{name} paid you'**
  String namePaidYou(String name);

  /// Payment screen headline.
  ///
  /// In en, this message translates to:
  /// **'{from} paid {to}'**
  String namePaidName(String from, String to);

  /// Payment waiting for the user's confirmation.
  ///
  /// In en, this message translates to:
  /// **'{name} says they sent you this. Did it arrive?'**
  String paymentSaysSent(String name);

  /// Payment the other person still has to confirm.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name} to confirm'**
  String waitingForConfirm(String name);

  /// Button: the payment never arrived.
  ///
  /// In en, this message translates to:
  /// **'Not received'**
  String get notReceived;

  /// Button: the payment arrived.
  ///
  /// In en, this message translates to:
  /// **'Confirm received'**
  String get confirmReceived;

  /// Confirm dialog title.
  ///
  /// In en, this message translates to:
  /// **'Delete payment?'**
  String get deletePaymentTitle;

  /// Confirm dialog text.
  ///
  /// In en, this message translates to:
  /// **'The debt it settled comes back.'**
  String get deletePaymentMessage;

  /// Snackbar with Undo.
  ///
  /// In en, this message translates to:
  /// **'Payment deleted'**
  String get paymentDeletedSnack;

  /// Confirm dialog title.
  ///
  /// In en, this message translates to:
  /// **'Not received?'**
  String get notReceivedTitle;

  /// Confirm dialog text.
  ///
  /// In en, this message translates to:
  /// **'The payment from {name} is removed and the debt comes back.'**
  String notReceivedMessage(String name);

  /// Snackbar with Undo.
  ///
  /// In en, this message translates to:
  /// **'Payment removed'**
  String get paymentRemovedSnack;

  /// Button on Settle up.
  ///
  /// In en, this message translates to:
  /// **'Record a payment'**
  String get recordAPayment;

  /// Settle up when everyone is even.
  ///
  /// In en, this message translates to:
  /// **'Nothing to settle'**
  String get nothingToSettle;

  /// Settle up when everyone is even.
  ///
  /// In en, this message translates to:
  /// **'Everyone is even.'**
  String get everyoneEven;

  /// Settle up section heading for payments not confirmed yet.
  ///
  /// In en, this message translates to:
  /// **'Waiting for confirmation'**
  String get waitingForConfirmation;

  /// Settle up heading when "simplify debts" is off.
  ///
  /// In en, this message translates to:
  /// **'Debts as recorded · simplify debts is off'**
  String get debtsAsRecorded;

  /// Settle up heading.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 transfer settles everything} other{{count} transfers settle everything}}'**
  String transfersSettleEverything(int count);

  /// Settle up heading when other currencies are listed below; {currency} is a code like EUR.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 transfer settles the {currency} balance} other{{count} transfers settle the {currency} balance}}'**
  String transfersSettleBalance(int count, String currency);

  /// Settle up heading for a currency that wasn't converted to the group currency.
  ///
  /// In en, this message translates to:
  /// **'Not converted · {currency} · settles in {currency}'**
  String notConvertedSettlesIn(String currency);

  /// Button that converts expenses to the group currency.
  ///
  /// In en, this message translates to:
  /// **'Convert'**
  String get convert;

  /// Screen title and button: pay back what is owed.
  ///
  /// In en, this message translates to:
  /// **'Settle up'**
  String get settleUp;

  /// Settle up card for a payment the user should confirm.
  ///
  /// In en, this message translates to:
  /// **'{name} says they sent you {amount}'**
  String saysTheySent(String name, String amount);

  /// Settle up card for a payment the other person should confirm.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name} to confirm {amount}'**
  String waitingToConfirmAmount(String name, String amount);

  /// The user, in a list of names (e.g. "You → Ben").
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// Button that shares a "you owe me" message.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get request;

  /// Button after paying through a payment app.
  ///
  /// In en, this message translates to:
  /// **'I\'ve sent it'**
  String get iveSentIt;

  /// Button that records a payment.
  ///
  /// In en, this message translates to:
  /// **'Mark as paid'**
  String get markAsPaid;

  /// Snackbar after marking a payment as sent.
  ///
  /// In en, this message translates to:
  /// **'Marked as sent. {name} will confirm.'**
  String markedAsSent(String name);

  /// An approximate amount converted to the home currency; {amount} is formatted money.
  ///
  /// In en, this message translates to:
  /// **'≈ {amount}'**
  String approx(String amount);

  /// A friend's balance: they owe the user.
  ///
  /// In en, this message translates to:
  /// **'{name} owes you {amount}'**
  String friendOwesYou(String name, String amount);

  /// A friend's balance: the user owes them.
  ///
  /// In en, this message translates to:
  /// **'You owe {name} {amount}'**
  String friendYouOwe(String name, String amount);

  /// Like friendYouOwe on a line under a group name (lower case in English).
  ///
  /// In en, this message translates to:
  /// **'you owe {name} {amount}'**
  String friendYouOweLine(String name, String amount);

  /// Friend page and dialog when no group links the two people any more.
  ///
  /// In en, this message translates to:
  /// **'You no longer share a group with {name}. Send them your friend link to add expenses.'**
  String noSharedGroup(String name);

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Share friend link'**
  String get shareFriendLink;

  /// Error: creating the friend's group needs to be online.
  ///
  /// In en, this message translates to:
  /// **'The first expense with {name} needs a connection.'**
  String firstExpenseNeedsConnection(String name);

  /// Snackbar.
  ///
  /// In en, this message translates to:
  /// **'Reminder sent to {name}'**
  String reminderSent(String name);

  /// Error: one reminder a day.
  ///
  /// In en, this message translates to:
  /// **'You can remind {name} again tomorrow'**
  String remindTomorrow(String name);

  /// Error when reminding someone who owes nothing.
  ///
  /// In en, this message translates to:
  /// **'{name} doesn\'t owe you anything'**
  String remindNothingOwed(String name);

  /// Error.
  ///
  /// In en, this message translates to:
  /// **'Sending a reminder needs a connection.'**
  String get remindNeedsConnection;

  /// Joins the last two amounts in a list, e.g. "€12.00 and ₩5,000".
  ///
  /// In en, this message translates to:
  /// **'{a} and {b}'**
  String amountsAnd(String a, String b);

  /// Share text inviting someone not on Evensies; {link} is a URL.
  ///
  /// In en, this message translates to:
  /// **'I added you on Evensies so we can split expenses. Join me: {link}'**
  String inviteFriendText(String link);

  /// Friend page when the person isn't known locally.
  ///
  /// In en, this message translates to:
  /// **'This person isn\'t on this device'**
  String get personNotHere;

  /// Explanation.
  ///
  /// In en, this message translates to:
  /// **'It hasn\'t synced yet, or you no longer share a group.'**
  String get personNotHereNote;

  /// Tooltip of a "more actions" menu button.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get more;

  /// Friend page menu item.
  ///
  /// In en, this message translates to:
  /// **'Export non-group expenses (CSV)'**
  String get exportNonGroupCsv;

  /// Friend page menu item.
  ///
  /// In en, this message translates to:
  /// **'Export non-group expenses (JSON)'**
  String get exportNonGroupJson;

  /// Friend page menu item.
  ///
  /// In en, this message translates to:
  /// **'Export non-group expenses (ZIP with receipts)'**
  String get exportNonGroupZip;

  /// Under the name of a person without an account.
  ///
  /// In en, this message translates to:
  /// **'Not on Evensies yet'**
  String get notOnEvensies;

  /// A person or group with no balance.
  ///
  /// In en, this message translates to:
  /// **'All settled up'**
  String get allSettledUp;

  /// Button that sends a reminder push.
  ///
  /// In en, this message translates to:
  /// **'Remind'**
  String get remind;

  /// Button that shares an invite link.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get invite;

  /// Section heading.
  ///
  /// In en, this message translates to:
  /// **'Balances'**
  String get balances;

  /// Section heading.
  ///
  /// In en, this message translates to:
  /// **'Expenses and payments'**
  String get expensesAndPayments;

  /// Friend page with no shared expenses.
  ///
  /// In en, this message translates to:
  /// **'Nothing together yet. Add an expense below.'**
  String get nothingTogetherYet;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get addExpense;

  /// A person's balance on the Friends tab, under their name.
  ///
  /// In en, this message translates to:
  /// **'owes you {amount}'**
  String personOwesYou(String amount);

  /// A person's balance on the Friends tab, under their name.
  ///
  /// In en, this message translates to:
  /// **'you owe {amount}'**
  String personYouOwe(String amount);

  /// A person with no balance, on the Friends tab.
  ///
  /// In en, this message translates to:
  /// **'settled up'**
  String get personSettledUp;

  /// Snackbar after settling with a friend across groups with no money moving.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Recorded in 1 group} other{Recorded in {count} groups}}'**
  String recordedInGroups(int count);

  /// Button: the friend paid the user.
  ///
  /// In en, this message translates to:
  /// **'Mark as received'**
  String get markAsReceived;

  /// Button: debts in both directions cancel out, no money moves.
  ///
  /// In en, this message translates to:
  /// **'Clear both sides'**
  String get clearBothSides;

  /// A friend balance of zero in one currency; {currency} is a code like EUR.
  ///
  /// In en, this message translates to:
  /// **'Even in {currency}'**
  String evenIn(String currency);

  /// One line behind a friend balance; {group} is a group name or "Non-group".
  ///
  /// In en, this message translates to:
  /// **'{group}: you pay {name} {amount}'**
  String linePayThem(String group, String name, String amount);

  /// One line behind a friend balance.
  ///
  /// In en, this message translates to:
  /// **'{group}: {name} pays you {amount}'**
  String lineTheyPay(String group, String name, String amount);

  /// Note for Clear both sides.
  ///
  /// In en, this message translates to:
  /// **'No money moves: this records both sides as settled.'**
  String get noMoneyMoves;

  /// Button converting expenses in one group.
  ///
  /// In en, this message translates to:
  /// **'Convert in {group}'**
  String convertIn(String group);

  /// Screen title.
  ///
  /// In en, this message translates to:
  /// **'Settle up with {name}'**
  String settleUpWith(String name);

  /// Empty state.
  ///
  /// In en, this message translates to:
  /// **'Nothing to settle with {name}'**
  String nothingToSettleWith(String name);

  /// Intro on the settle-with-a-friend screen.
  ///
  /// In en, this message translates to:
  /// **'Everything between you and {name}, per currency. Recording adds a payment in each group.'**
  String settleWithIntro(String name);

  /// Search field hint.
  ///
  /// In en, this message translates to:
  /// **'Search friends and groups'**
  String get searchFriendsGroups;

  /// Section heading and tab.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friends;

  /// Section heading and tab.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get groups;

  /// Empty state.
  ///
  /// In en, this message translates to:
  /// **'No friends or groups yet.'**
  String get noFriendsOrGroups;

  /// Search with no result; {query} is what was typed.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches “{query}”.'**
  String nothingMatches(String query);

  /// Screen title: pick a friend or group for a new expense.
  ///
  /// In en, this message translates to:
  /// **'Add expense · with whom?'**
  String get addExpenseWithWhom;

  /// Share text of the user's friend link; {code} looks like K7P-4QX.
  ///
  /// In en, this message translates to:
  /// **'Add me on Evensies to split expenses: {link}\nOr enter my code {code}'**
  String friendLinkShare(String link, String code);

  /// Error.
  ///
  /// In en, this message translates to:
  /// **'Sharing your friend link needs a connection.'**
  String get friendLinkNeedsConnection;

  /// Error when adding your own friend code.
  ///
  /// In en, this message translates to:
  /// **'That\'s your own code'**
  String get selfFriend;

  /// Error for an unknown friend code.
  ///
  /// In en, this message translates to:
  /// **'No one found for this code'**
  String get noOneForCode;

  /// Error.
  ///
  /// In en, this message translates to:
  /// **'Adding a friend needs a connection.'**
  String get addFriendNeedsConnection;

  /// Confirm dialog title.
  ///
  /// In en, this message translates to:
  /// **'Get a new friend code?'**
  String get newFriendCodeTitle;

  /// Confirm dialog text.
  ///
  /// In en, this message translates to:
  /// **'Your current link and code stop working. Friends you already have stay.'**
  String get newFriendCodeMessage;

  /// Button: replace the friend code.
  ///
  /// In en, this message translates to:
  /// **'New code'**
  String get newCode;

  /// Screen title.
  ///
  /// In en, this message translates to:
  /// **'Add a friend'**
  String get addAFriend;

  /// Shown when the friend code can't be loaded.
  ///
  /// In en, this message translates to:
  /// **'Your friend link needs a connection'**
  String get friendLinkOffline;

  /// Heading above the user's QR code.
  ///
  /// In en, this message translates to:
  /// **'Your friend code'**
  String get yourFriendCode;

  /// Accessibility label of the QR code.
  ///
  /// In en, this message translates to:
  /// **'QR code of your friend link'**
  String get friendQrLabel;

  /// Under the friend code.
  ///
  /// In en, this message translates to:
  /// **'Friends scan this, open the link, or type the code.'**
  String get friendCodeHelp;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Share link'**
  String get shareLink;

  /// Snackbar.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get codeCopied;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get copyCode;

  /// Section heading.
  ///
  /// In en, this message translates to:
  /// **'Have a friend\'s code?'**
  String get haveFriendCode;

  /// Under a found person's name.
  ///
  /// In en, this message translates to:
  /// **'on Evensies'**
  String get onEvensies;

  /// Section heading: add a friend by name only.
  ///
  /// In en, this message translates to:
  /// **'Someone not on Evensies yet'**
  String get notOnEvensiesSection;

  /// Section help text.
  ///
  /// In en, this message translates to:
  /// **'Add expenses with them right away, and invite them later.'**
  String get notOnEvensiesHelp;

  /// Error under a text field.
  ///
  /// In en, this message translates to:
  /// **'At most {max} characters'**
  String atMostChars(int max);

  /// Button adding a friend by name.
  ///
  /// In en, this message translates to:
  /// **'Add {name}'**
  String addName(String name);

  /// Tooltip and screen title.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Tooltip, tab and screen title: the feed of changes.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activity;

  /// Menu item and tooltip.
  ///
  /// In en, this message translates to:
  /// **'New group'**
  String get newGroup;

  /// Menu item and button.
  ///
  /// In en, this message translates to:
  /// **'Join with a code'**
  String get joinWithCode;

  /// Filter chip.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// Filter chip: people or groups that owe the user.
  ///
  /// In en, this message translates to:
  /// **'Owes me'**
  String get filterOwesMe;

  /// Filter chip: people or groups the user owes.
  ///
  /// In en, this message translates to:
  /// **'I owe'**
  String get filterIOwe;

  /// Collapsed section of settled groups or people.
  ///
  /// In en, this message translates to:
  /// **'Settled up ({count})'**
  String settledUpCount(int count);

  /// Empty filter result.
  ///
  /// In en, this message translates to:
  /// **'Nobody owes you anything'**
  String get nobodyOwesYou;

  /// Empty filter result.
  ///
  /// In en, this message translates to:
  /// **'You don\'t owe anything'**
  String get youOweNothing;

  /// Empty list.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get nothingHereYet;

  /// Friends tab empty state title.
  ///
  /// In en, this message translates to:
  /// **'No friends yet'**
  String get noFriendsYet;

  /// Friends tab empty state text.
  ///
  /// In en, this message translates to:
  /// **'Add a friend to split expenses outside a group. People you share a group with show up here too.'**
  String get noFriendsHelp;

  /// Overall card when there are no balances.
  ///
  /// In en, this message translates to:
  /// **'You are all settled up'**
  String get allSettledUpYou;

  /// Overall card; {amounts} is like "€42.10 · $15.00".
  ///
  /// In en, this message translates to:
  /// **'You are owed {amounts}'**
  String youAreOwedList(String amounts);

  /// Overall card.
  ///
  /// In en, this message translates to:
  /// **'You owe {amounts}'**
  String youOweList(String amounts);

  /// Under a person on the Friends tab (lower case in English, joined with other words by " · ").
  ///
  /// In en, this message translates to:
  /// **'not on Evensies yet'**
  String get notOnEvensiesLower;

  /// Groups tab empty state title.
  ///
  /// In en, this message translates to:
  /// **'No groups yet'**
  String get noGroupsYet;

  /// Groups tab empty state text.
  ///
  /// In en, this message translates to:
  /// **'Create one for a trip or a flat, or join a friend\'s group with their invite code.'**
  String get noGroupsHelp;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Create group'**
  String get createGroup;

  /// A group with no balance for the user.
  ///
  /// In en, this message translates to:
  /// **'Settled up'**
  String get settledUp;

  /// Group card: the net in the home currency; {amount} starts with + or −.
  ///
  /// In en, this message translates to:
  /// **'Net ≈ {amount}'**
  String netApprox(String amount);

  /// Number of active members.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member} other{{count} members}}'**
  String memberCount(int count);

  /// The user's balance in a group.
  ///
  /// In en, this message translates to:
  /// **'You owe {amount}'**
  String youOweAmount(String amount);

  /// The user's balance in a group.
  ///
  /// In en, this message translates to:
  /// **'You are owed {amount}'**
  String youAreOwedAmount(String amount);

  /// Like youOweAmount mid-line (lower case in English).
  ///
  /// In en, this message translates to:
  /// **'you owe {amount}'**
  String youOweAmountLine(String amount);

  /// Like youAreOwedAmount mid-line (lower case in English).
  ///
  /// In en, this message translates to:
  /// **'you are owed {amount}'**
  String youAreOwedAmountLine(String amount);

  /// Error.
  ///
  /// In en, this message translates to:
  /// **'Creating a group needs a connection.'**
  String get createGroupNeedsConnection;

  /// Text field label.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get groupName;

  /// Text field label.
  ///
  /// In en, this message translates to:
  /// **'Your name in this group'**
  String get yourNameInGroup;

  /// Currency picker label: the group's currency.
  ///
  /// In en, this message translates to:
  /// **'Default currency'**
  String get defaultCurrency;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// Error for an unknown code.
  ///
  /// In en, this message translates to:
  /// **'No group or friend found for this code'**
  String get noGroupOrFriendForCode;

  /// Error.
  ///
  /// In en, this message translates to:
  /// **'Joining a group needs a connection.'**
  String get joinNeedsConnection;

  /// Screen title.
  ///
  /// In en, this message translates to:
  /// **'Enter a code'**
  String get enterACode;

  /// Where to find codes.
  ///
  /// In en, this message translates to:
  /// **'A group code is in the group → Members. A friend code is on their Friends tab → Add a friend.'**
  String get enterCodeHelp;

  /// Note under the code field.
  ///
  /// In en, this message translates to:
  /// **'Pasted from clipboard'**
  String get pastedFromClipboard;

  /// A found person.
  ///
  /// In en, this message translates to:
  /// **'{name} · on Evensies'**
  String nameOnEvensies(String name);

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Add {name} as a friend'**
  String addAsFriend(String name);

  /// Preview of a friend's invite code.
  ///
  /// In en, this message translates to:
  /// **'{name} added you as a friend'**
  String addedYouAsFriend(String name);

  /// Like addedYouAsFriend without a name.
  ///
  /// In en, this message translates to:
  /// **'Someone added you as a friend'**
  String get someoneAddedYouAsFriend;

  /// Preview of a group invite; {members} is memberCount, e.g. "3 members".
  ///
  /// In en, this message translates to:
  /// **'{name} · {members}'**
  String groupPreview(String name, String members);

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// Join screen for a friend's invite.
  ///
  /// In en, this message translates to:
  /// **'{name} wants to split expenses with you'**
  String wantsToSplit(String name);

  /// Screen title.
  ///
  /// In en, this message translates to:
  /// **'Join group'**
  String get joinGroup;

  /// Join screen for an unknown or rotated code.
  ///
  /// In en, this message translates to:
  /// **'This invite link is no longer valid'**
  String get inviteInvalid;

  /// Join screen for any other error; {reason} is an error sentence.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open this invite: {reason}'**
  String inviteFailed(String reason);

  /// Join screen.
  ///
  /// In en, this message translates to:
  /// **'This friend invite was already used'**
  String get friendInviteUsed;

  /// Join screen for a friend's invite.
  ///
  /// In en, this message translates to:
  /// **'Join to see and add your shared expenses.'**
  String get joinToSeeShared;

  /// Choice on the join screen: claim a placeholder member.
  ///
  /// In en, this message translates to:
  /// **'I\'m {name}'**
  String imName(String name);

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// Join screen: pick a member or type a new name.
  ///
  /// In en, this message translates to:
  /// **'Who are you?'**
  String get whoAreYou;

  /// Text field label.
  ///
  /// In en, this message translates to:
  /// **'New member name'**
  String get newMemberName;

  /// Tooltip and screen title: charts and totals.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get insights;

  /// Tooltip of the group's members button.
  ///
  /// In en, this message translates to:
  /// **'Members & invite'**
  String get membersInvite;

  /// Tooltip and screen title.
  ///
  /// In en, this message translates to:
  /// **'Group settings'**
  String get groupSettings;

  /// Tab of a group.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses;

  /// Button that adds an expense to the group (short).
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expenseFab;

  /// Group screen when the group isn't stored locally.
  ///
  /// In en, this message translates to:
  /// **'This group isn\'t on this device'**
  String get groupNotHere;

  /// Explanation.
  ///
  /// In en, this message translates to:
  /// **'You left it, someone removed you, or it hasn\'t synced yet.'**
  String get groupNotHereNote;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Back to groups'**
  String get backToGroups;

  /// Empty group.
  ///
  /// In en, this message translates to:
  /// **'No expenses yet'**
  String get noExpensesYet;

  /// Empty group hint; "Expense" is the expenseFab button.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Expense\" to add the first one.'**
  String get tapExpenseToAdd;

  /// Expense row: the user paid. Lower case in English, the line continues with " · ".
  ///
  /// In en, this message translates to:
  /// **'you paid {amount}'**
  String tilePaidYou(String amount);

  /// Expense row.
  ///
  /// In en, this message translates to:
  /// **'{name} paid {amount}'**
  String tilePaidName(String name, String amount);

  /// Expense row with several payers.
  ///
  /// In en, this message translates to:
  /// **'{count} people paid {amount}'**
  String tilePaidPeople(int count, String amount);

  /// Expense row of a refund the user received.
  ///
  /// In en, this message translates to:
  /// **'refund to you'**
  String get tileRefundYou;

  /// Expense row of a refund.
  ///
  /// In en, this message translates to:
  /// **'refund to {name}'**
  String tileRefundName(String name);

  /// Expense row of a refund to several people.
  ///
  /// In en, this message translates to:
  /// **'refund to {count} people'**
  String tileRefundPeople(int count);

  /// Expense row: the user has no part in it.
  ///
  /// In en, this message translates to:
  /// **'not involved'**
  String get notInvolved;

  /// Refund row: it was all the user's.
  ///
  /// In en, this message translates to:
  /// **'all yours'**
  String get allYours;

  /// Expense row: the user paid exactly their share.
  ///
  /// In en, this message translates to:
  /// **'you paid for yourself'**
  String get paidForYourself;

  /// Expense row of a refund.
  ///
  /// In en, this message translates to:
  /// **'you get back {amount}'**
  String youGetBack(String amount);

  /// Expense row.
  ///
  /// In en, this message translates to:
  /// **'you lent {amount}'**
  String youLent(String amount);

  /// Expense row.
  ///
  /// In en, this message translates to:
  /// **'you borrowed {amount}'**
  String youBorrowed(String amount);

  /// Accessibility label of the repeat mark on an expense row.
  ///
  /// In en, this message translates to:
  /// **'Repeats'**
  String get repeatsLabel;

  /// Accessibility label of the receipt mark.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Has a receipt} other{Has {count} receipts}}'**
  String hasReceipt(int count);

  /// Refund mark and chip.
  ///
  /// In en, this message translates to:
  /// **'Refund'**
  String get refund;

  /// Accessibility label: the expense has no usable exchange rate.
  ///
  /// In en, this message translates to:
  /// **'Not converted'**
  String get notConverted;

  /// Tag on a payment not confirmed yet.
  ///
  /// In en, this message translates to:
  /// **'pending'**
  String get pending;

  /// Balances tab and the overall card on the home screen: everything in the home currency.
  ///
  /// In en, this message translates to:
  /// **'You owe ≈ {amount} in total'**
  String approxTotalOwe(String amount);

  /// Balances tab and the overall card on the home screen: everything in the home currency.
  ///
  /// In en, this message translates to:
  /// **'You are owed ≈ {amount} in total'**
  String approxTotalOwed(String amount);

  /// Balances tab note.
  ///
  /// In en, this message translates to:
  /// **'In your home currency, at the latest rates'**
  String get approxTotalNote;

  /// Balances tab when only other currencies have balances.
  ///
  /// In en, this message translates to:
  /// **'Nothing owed in {currency}'**
  String nothingOwedIn(String currency);

  /// Balances tab when nobody owes anything.
  ///
  /// In en, this message translates to:
  /// **'All settled'**
  String get allSettled;

  /// Balances tab note.
  ///
  /// In en, this message translates to:
  /// **'Expenses in other currencies are below.'**
  String get otherCurrenciesBelow;

  /// Balances tab note.
  ///
  /// In en, this message translates to:
  /// **'Nobody owes anything.'**
  String get nobodyOwes;

  /// Balances tab hint.
  ///
  /// In en, this message translates to:
  /// **'You should pay next (you owe {amount}, the most)'**
  String youPayNext(String amount);

  /// Balances tab hint.
  ///
  /// In en, this message translates to:
  /// **'{name} should pay next (owes {amount}, the most)'**
  String namePaysNext(String name, String amount);

  /// Button with the number of payments waiting for confirmation.
  ///
  /// In en, this message translates to:
  /// **'Settle up · {count} waiting'**
  String settleUpWaiting(int count);

  /// A member who left or was removed.
  ///
  /// In en, this message translates to:
  /// **'{name} (removed)'**
  String memberRemoved(String name);

  /// Not converted section.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 expense without a rate to {currency}} other{{count} expenses without a rate to {currency}}}'**
  String expensesWithoutRate(int count, String currency);

  /// Not converted section.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 expense with a rate that can\'t be converted} other{{count} expenses with a rate that can\'t be converted}}'**
  String expensesBadRate(int count);

  /// Not converted section.
  ///
  /// In en, this message translates to:
  /// **'Payments in {currency}'**
  String paymentsIn(String currency);

  /// Not converted section (lower case in English, joined with " · ").
  ///
  /// In en, this message translates to:
  /// **'everyone is even in {currency}'**
  String everyoneEvenIn(String currency);

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Convert to {currency}'**
  String convertTo(String currency);

  /// Balance row label.
  ///
  /// In en, this message translates to:
  /// **'settled'**
  String get balanceSettled;

  /// Balance row label before an amount.
  ///
  /// In en, this message translates to:
  /// **'gets back'**
  String get balanceGetsBack;

  /// Balance row label before an amount.
  ///
  /// In en, this message translates to:
  /// **'owes'**
  String get balanceOwes;

  /// Snackbar after converting.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Converted 1 expense to {currency}} other{Converted {count} expenses to {currency}}}'**
  String convertedCount(int count, String currency);

  /// Under the rate field when no rate could be fetched.
  ///
  /// In en, this message translates to:
  /// **'No automatic rate. Enter one.'**
  String get noAutoRate;

  /// Under the rate field: the date of the rate, e.g. "11 Oct".
  ///
  /// In en, this message translates to:
  /// **'rate of {date}'**
  String rateOf(String date);

  /// Like rateOf when the rate came from this device's cache.
  ///
  /// In en, this message translates to:
  /// **'offline · rate of {date}'**
  String rateOfOffline(String date);

  /// Convert sheet line: the total and how many expenses.
  ///
  /// In en, this message translates to:
  /// **'{amount} · {count, plural, =1{1 expense} other{{count} expenses}}'**
  String amountCountExpenses(String amount, int count);

  /// Convert sheet note.
  ///
  /// In en, this message translates to:
  /// **'Payments in {currency} stay in {currency}'**
  String paymentsStayIn(String currency);

  /// Rate field label, e.g. "Rate: 1 JPY in EUR".
  ///
  /// In en, this message translates to:
  /// **'Rate: 1 {from} in {to}'**
  String rateLabel(String from, String to);

  /// Rate field helper.
  ///
  /// In en, this message translates to:
  /// **'Nothing left to convert'**
  String get nothingLeftToConvert;

  /// Rate field helper while loading.
  ///
  /// In en, this message translates to:
  /// **'Looking up the rate…'**
  String get lookingUpRate;

  /// Rate field error.
  ///
  /// In en, this message translates to:
  /// **'Enter a rate above 0'**
  String get enterRateAbove0;

  /// Convert sheet explanation.
  ///
  /// In en, this message translates to:
  /// **'Fills in this rate on every expense that has none, so they count in {currency} balances. You can still change the rate on each expense.'**
  String convertExplain(String currency);

  /// Settings row label: the group's name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameField;

  /// Why the group currency is locked.
  ///
  /// In en, this message translates to:
  /// **'Can\'t change after the first expense or payment'**
  String get cantChangeCurrency;

  /// Group currency explanation.
  ///
  /// In en, this message translates to:
  /// **'Balances and payments use it'**
  String get currencyUsedFor;

  /// Group settings section heading.
  ///
  /// In en, this message translates to:
  /// **'Splitting'**
  String get splitting;

  /// Switch.
  ///
  /// In en, this message translates to:
  /// **'Simplify debts'**
  String get simplifyDebts;

  /// Switch explanation.
  ///
  /// In en, this message translates to:
  /// **'Combines debts so the group needs fewer payments. Nobody\'s total changes, only who pays whom.'**
  String get simplifyDebtsHelp;

  /// Settings row and sheet title.
  ///
  /// In en, this message translates to:
  /// **'Default split'**
  String get defaultSplit;

  /// The default split no longer fits the members.
  ///
  /// In en, this message translates to:
  /// **'No longer adds up · tap to fix'**
  String get splitStale;

  /// Group settings section heading.
  ///
  /// In en, this message translates to:
  /// **'Membership'**
  String get membership;

  /// Settings row.
  ///
  /// In en, this message translates to:
  /// **'Leave group'**
  String get leaveGroup;

  /// Under Leave group when leaving is possible.
  ///
  /// In en, this message translates to:
  /// **'Your balance is settled'**
  String get balanceSettledNote;

  /// Dialog title.
  ///
  /// In en, this message translates to:
  /// **'Rename group'**
  String get renameGroup;

  /// Confirm dialog title.
  ///
  /// In en, this message translates to:
  /// **'Leave “{name}”?'**
  String leaveTitle(String name);

  /// Confirm dialog text.
  ///
  /// In en, this message translates to:
  /// **'You won\'t see this group any more. Your past expenses stay with the other members. To come back, ask for the invite code.'**
  String get leaveMessage;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// Snackbar after leaving a group.
  ///
  /// In en, this message translates to:
  /// **'You left “{name}”'**
  String youLeft(String name);

  /// Default split summary.
  ///
  /// In en, this message translates to:
  /// **'Equal · everyone'**
  String get splitEqualEveryone;

  /// Default split summary; {list} is like "Anna 60%, Ben 40%".
  ///
  /// In en, this message translates to:
  /// **'Percent · {list}'**
  String splitPercentList(String list);

  /// Default split summary; {list} is like "Anna 2, Ben 1".
  ///
  /// In en, this message translates to:
  /// **'Shares · {list}'**
  String splitSharesList(String list);

  /// A percentage; {value} is a number like 33,3.
  ///
  /// In en, this message translates to:
  /// **'{value}%'**
  String percentValue(String value);

  /// Default split sheet explanation.
  ///
  /// In en, this message translates to:
  /// **'New expenses start with this split. You can still change it on each expense.'**
  String get defaultSplitHelp;

  /// Button: no default split.
  ///
  /// In en, this message translates to:
  /// **'Use equal'**
  String get useEqual;

  /// Heading above the group's invite code.
  ///
  /// In en, this message translates to:
  /// **'Invite code'**
  String get inviteCode;

  /// Accessibility label.
  ///
  /// In en, this message translates to:
  /// **'QR code of the invite link'**
  String get inviteQrLabel;

  /// Under the invite code.
  ///
  /// In en, this message translates to:
  /// **'Anyone with this code can join and pick their name.'**
  String get inviteCodeHelp;

  /// Share text of a group invite.
  ///
  /// In en, this message translates to:
  /// **'Join my group \"{group}\" on Evensies: {link}\nOr open the app and enter code {code}'**
  String inviteShareText(String group, String link, String code);

  /// Button: replace the invite code.
  ///
  /// In en, this message translates to:
  /// **'Rotate code'**
  String get rotateCode;

  /// Section heading.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get members;

  /// Under a placeholder member.
  ///
  /// In en, this message translates to:
  /// **'not joined yet — share the invite code'**
  String get notJoinedYet;

  /// Under a member who joined with an account.
  ///
  /// In en, this message translates to:
  /// **'linked'**
  String get linked;

  /// Button: add someone who hasn't joined.
  ///
  /// In en, this message translates to:
  /// **'Add placeholder member'**
  String get addPlaceholder;

  /// Confirm dialog title.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String removeMemberTitle(String name);

  /// Confirm dialog text.
  ///
  /// In en, this message translates to:
  /// **'Their past expenses and balance stay in the group.'**
  String get removeMemberMessage;

  /// Extra confirm text when removing a member who is in repeating expenses.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{{name} is still in 1 repeating expense ({names}); they keep {name}\'s share until you edit the latest one.} other{{name} is still in {count} repeating expenses ({names}); they keep {name}\'s share until you edit the latest one.}}'**
  String removeMemberSeries(int count, String name, String names);

  /// Dialog title.
  ///
  /// In en, this message translates to:
  /// **'Add member'**
  String get addMember;

  /// Confirm dialog title.
  ///
  /// In en, this message translates to:
  /// **'Rotate invite code?'**
  String get rotateInviteTitle;

  /// Confirm dialog text.
  ///
  /// In en, this message translates to:
  /// **'The current code and link stop working. People who already joined are not affected.'**
  String get rotateInviteMessage;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Rotate'**
  String get rotate;

  /// Snackbar.
  ///
  /// In en, this message translates to:
  /// **'New invite code ready'**
  String get newInviteReady;

  /// Activity empty state while offline.
  ///
  /// In en, this message translates to:
  /// **'Activity needs a connection'**
  String get activityNeedsConnection;

  /// Activity empty state text.
  ///
  /// In en, this message translates to:
  /// **'Recent changes show up here once you are back online.'**
  String get activityOfflineNote;

  /// Activity empty state.
  ///
  /// In en, this message translates to:
  /// **'No activity yet'**
  String get noActivityYet;

  /// Activity empty state text (all groups).
  ///
  /// In en, this message translates to:
  /// **'Changes in your groups show up here.'**
  String get activityAllGroups;

  /// Activity empty state text (one group).
  ///
  /// In en, this message translates to:
  /// **'Changes in this group show up here.'**
  String get activityThisGroup;

  /// Note when the list comes from this device's cache.
  ///
  /// In en, this message translates to:
  /// **'Showing saved activity. Pull to refresh.'**
  String get showingSaved;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// Day heading for items without a date.
  ///
  /// In en, this message translates to:
  /// **'Earlier'**
  String get earlier;

  /// Day heading.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// Day heading.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// Activity row: the date a repeating expense was added for, e.g. "for Sun, 1 Nov".
  ///
  /// In en, this message translates to:
  /// **'for {date}'**
  String forDate(String date);

  /// Expense history row: the user commented.
  ///
  /// In en, this message translates to:
  /// **'You commented'**
  String get youCommented;

  /// Expense history row.
  ///
  /// In en, this message translates to:
  /// **'{name} commented'**
  String nameCommented(String name);

  /// Snackbar after restoring an expense.
  ///
  /// In en, this message translates to:
  /// **'Restored “{name}”'**
  String restoredName(String name);

  /// Snackbar.
  ///
  /// In en, this message translates to:
  /// **'Payment restored'**
  String get paymentRestored;

  /// Expense screen when the expense isn't stored locally.
  ///
  /// In en, this message translates to:
  /// **'This expense isn\'t on this device'**
  String get expenseNotHere;

  /// Expense screen title for a deleted expense.
  ///
  /// In en, this message translates to:
  /// **'Deleted expense'**
  String get deletedExpense;

  /// Expense screen title.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// Line on an expense of a repeating series; same words as the form's Repeat options.
  ///
  /// In en, this message translates to:
  /// **'{frequency, select, weekly{Repeats every week} biweekly{Repeats every 2 weeks} monthly{Repeats every month} yearly{Repeats every year} other{Repeats}}'**
  String seriesRepeats(String frequency);

  /// Like seriesRepeats on the latest repeat; {date} is like "Sun, 1 Nov".
  ///
  /// In en, this message translates to:
  /// **'{frequency, select, weekly{Repeats every week · next on {date}} biweekly{Repeats every 2 weeks · next on {date}} monthly{Repeats every month · next on {date}} yearly{Repeats every year · next on {date}} other{Repeats · next on {date}}}'**
  String seriesRepeatsNext(String frequency, String date);

  /// Like seriesRepeatsNext when the next repeat's amount differs; {amount} is formatted money.
  ///
  /// In en, this message translates to:
  /// **'{frequency, select, weekly{Repeats every week · next {amount} on {date}} biweekly{Repeats every 2 weeks · next {amount} on {date}} monthly{Repeats every month · next {amount} on {date}} yearly{Repeats every year · next {amount} on {date}} other{Repeats · next {amount} on {date}}}'**
  String seriesRepeatsNextAmount(String frequency, String amount, String date);

  /// The exchange rate of a foreign expense, e.g. "Rate: 1 JPY = 0,0062 EUR".
  ///
  /// In en, this message translates to:
  /// **'Rate: 1 {from} = {rate} {to}'**
  String rateLine(String from, String rate, String to);

  /// A foreign expense without a rate.
  ///
  /// In en, this message translates to:
  /// **'Not converted to {currency}'**
  String notConvertedTo(String currency);

  /// Expense section heading of a refund.
  ///
  /// In en, this message translates to:
  /// **'Received and split back'**
  String get receivedSplitBack;

  /// Expense section heading.
  ///
  /// In en, this message translates to:
  /// **'Who paid and who owes'**
  String get whoPaidOwes;

  /// Section heading and split mode: an itemized bill.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get items;

  /// Section heading and field label.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// Section heading.
  ///
  /// In en, this message translates to:
  /// **'Receipts'**
  String get receipts;

  /// Section heading: the expense's changes.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// Confirm dialog title.
  ///
  /// In en, this message translates to:
  /// **'Delete expense?'**
  String get deleteExpenseTitle;

  /// Confirm dialog text.
  ///
  /// In en, this message translates to:
  /// **'This removes it for everyone in the group. You can restore it from Activity.'**
  String get deleteExpenseMessage;

  /// Confirm dialog title.
  ///
  /// In en, this message translates to:
  /// **'Delete repeating expense?'**
  String get deleteRepeatingTitle;

  /// Confirm dialog text.
  ///
  /// In en, this message translates to:
  /// **'This removes it for everyone in the group. You can restore it from Activity, but a series that stopped repeating can\'t be restarted. Repeats already added stay.'**
  String get deleteRepeatingMessage;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Delete this one'**
  String get deleteThisOne;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Delete and stop repeating'**
  String get deleteAndStop;

  /// Snackbar.
  ///
  /// In en, this message translates to:
  /// **'Deleted “{name}” and stopped repeating'**
  String deletedAndStopped(String name);

  /// Snackbar with Undo.
  ///
  /// In en, this message translates to:
  /// **'Deleted “{name}”'**
  String deletedName(String name);

  /// Banner on a moved expense.
  ///
  /// In en, this message translates to:
  /// **'Moved to another group'**
  String get movedToOtherGroup;

  /// Banner text.
  ///
  /// In en, this message translates to:
  /// **'It counts there now. Its comments and history stay here.'**
  String get movedNote;

  /// Banner on a deleted expense.
  ///
  /// In en, this message translates to:
  /// **'This expense was deleted'**
  String get expenseWasDeleted;

  /// Banner text.
  ///
  /// In en, this message translates to:
  /// **'Restore it to count it in balances again.'**
  String get restoreToCount;

  /// Itemized bill row.
  ///
  /// In en, this message translates to:
  /// **'Tax'**
  String get tax;

  /// Itemized bill row.
  ///
  /// In en, this message translates to:
  /// **'Tip or service'**
  String get tipService;

  /// Itemized bill row.
  ///
  /// In en, this message translates to:
  /// **'Discount'**
  String get discount;

  /// Expense person line.
  ///
  /// In en, this message translates to:
  /// **'You paid {paid} and owe {owe}'**
  String youPaidOwe(String paid, String owe);

  /// Expense person line.
  ///
  /// In en, this message translates to:
  /// **'You paid {amount}'**
  String youPaid(String amount);

  /// Expense person line.
  ///
  /// In en, this message translates to:
  /// **'You owe {amount}'**
  String youOwe(String amount);

  /// Expense person line.
  ///
  /// In en, this message translates to:
  /// **'{name} paid {paid} and owes {owe}'**
  String namePaidOwes(String name, String paid, String owe);

  /// Expense person line.
  ///
  /// In en, this message translates to:
  /// **'{name} paid {amount}'**
  String namePaid(String name, String amount);

  /// Expense person line.
  ///
  /// In en, this message translates to:
  /// **'{name} owes {amount}'**
  String nameOwes(String name, String amount);

  /// Refund person line.
  ///
  /// In en, this message translates to:
  /// **'You received {received} and get back {back}'**
  String youReceivedGetBack(String received, String back);

  /// Refund person line.
  ///
  /// In en, this message translates to:
  /// **'You received {amount}'**
  String youReceived(String amount);

  /// Refund person line.
  ///
  /// In en, this message translates to:
  /// **'You get back {amount}'**
  String youGetBackLine(String amount);

  /// Refund person line.
  ///
  /// In en, this message translates to:
  /// **'{name} received {received} and gets back {back}'**
  String nameReceivedGetsBack(String name, String received, String back);

  /// Refund person line.
  ///
  /// In en, this message translates to:
  /// **'{name} received {amount}'**
  String nameReceived(String name, String amount);

  /// Refund person line.
  ///
  /// In en, this message translates to:
  /// **'{name} gets back {amount}'**
  String nameGetsBack(String name, String amount);

  /// Expense history empty.
  ///
  /// In en, this message translates to:
  /// **'No history yet.'**
  String get noHistoryYet;

  /// Expense history while offline.
  ///
  /// In en, this message translates to:
  /// **'History shows up here once you are online.'**
  String get historyOffline;

  /// Note when history comes from this device's cache.
  ///
  /// In en, this message translates to:
  /// **'Showing saved history.'**
  String get showingSavedHistory;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get showMore;

  /// Confirm dialog title.
  ///
  /// In en, this message translates to:
  /// **'Delete comment?'**
  String get deleteCommentTitle;

  /// Section heading.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get comments;

  /// Empty comments.
  ///
  /// In en, this message translates to:
  /// **'No comments yet.'**
  String get noCommentsYet;

  /// Tooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete comment'**
  String get deleteComment;

  /// Comment field hint.
  ///
  /// In en, this message translates to:
  /// **'Add a comment'**
  String get addComment;

  /// Tooltip of the send button.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// Category picker title in search.
  ///
  /// In en, this message translates to:
  /// **'Filter by category'**
  String get filterByCategory;

  /// Category picker title and form button.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// Category picker chip: the whole parent category.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get categoryAll;

  /// Search filter chip and dialog title.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// Search error state.
  ///
  /// In en, this message translates to:
  /// **'Search isn\'t available'**
  String get searchUnavailable;

  /// Search empty state title.
  ///
  /// In en, this message translates to:
  /// **'Search expenses'**
  String get searchExpenses;

  /// Search empty state text; adapt the example words.
  ///
  /// In en, this message translates to:
  /// **'Descriptions, notes, comments, categories and amounts: \"taxi\", \"airport\", \"12,50\".'**
  String get searchHelp;

  /// Search with no results.
  ///
  /// In en, this message translates to:
  /// **'No matches'**
  String get noMatches;

  /// Search with no results.
  ///
  /// In en, this message translates to:
  /// **'Try another word, or remove a filter.'**
  String get noMatchesHelp;

  /// Number of results.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 expense} other{{count} expenses}}'**
  String expenseCount(int count);

  /// Search field hint; also the tooltip that removes the group filter.
  ///
  /// In en, this message translates to:
  /// **'Search all groups'**
  String get searchAllGroups;

  /// Search field hint within one group.
  ///
  /// In en, this message translates to:
  /// **'Search {name}'**
  String searchGroup(String name);

  /// Search field hint within one group whose name isn't loaded yet.
  ///
  /// In en, this message translates to:
  /// **'Search this group'**
  String get searchThisGroup;

  /// Tooltip of the clear button.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Filter chip of the current group when its name isn't loaded yet.
  ///
  /// In en, this message translates to:
  /// **'This group'**
  String get thisGroup;

  /// Insights error state; {reason} is an error sentence.
  ///
  /// In en, this message translates to:
  /// **'Insights can\'t be shown: {reason}'**
  String insightsError(String reason);

  /// Insights empty state.
  ///
  /// In en, this message translates to:
  /// **'Nothing to show yet'**
  String get nothingToShow;

  /// Insights empty state text.
  ///
  /// In en, this message translates to:
  /// **'Totals and charts appear once the group has expenses.'**
  String get insightsEmptyHelp;

  /// Insights period chip.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get allTime;

  /// Tooltip.
  ///
  /// In en, this message translates to:
  /// **'Share summary'**
  String get shareSummary;

  /// Tooltip, web only: opens the summary on its own tab with the browser's print dialog.
  ///
  /// In en, this message translates to:
  /// **'Print summary'**
  String get printSummary;

  /// Tooltip.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get previousMonth;

  /// Tooltip.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get nextMonth;

  /// Insights section heading.
  ///
  /// In en, this message translates to:
  /// **'By month'**
  String get byMonth;

  /// Insights toggle: the whole group's spending.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get groupSegment;

  /// Insights toggle: the user's share.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get mineSegment;

  /// Insights section heading.
  ///
  /// In en, this message translates to:
  /// **'By category'**
  String get byCategory;

  /// Insights empty section.
  ///
  /// In en, this message translates to:
  /// **'No expenses in this period.'**
  String get noExpensesPeriod;

  /// Insights section heading.
  ///
  /// In en, this message translates to:
  /// **'By person'**
  String get byPerson;

  /// Insights empty section.
  ///
  /// In en, this message translates to:
  /// **'Nobody paid or owed anything in this period.'**
  String get nobodyPaidPeriod;

  /// Insights note for a currency not converted.
  ///
  /// In en, this message translates to:
  /// **'Kept in {currency} until it is converted to {group}.'**
  String keptUntilConverted(String currency, String group);

  /// Insights totals row.
  ///
  /// In en, this message translates to:
  /// **'Total spent'**
  String get totalSpent;

  /// Insights totals row.
  ///
  /// In en, this message translates to:
  /// **'Your share'**
  String get yourShare;

  /// Insights totals row.
  ///
  /// In en, this message translates to:
  /// **'Payments made'**
  String get paymentsMade;

  /// Insights totals row.
  ///
  /// In en, this message translates to:
  /// **'Payments received'**
  String get paymentsReceived;

  /// Insights totals row.
  ///
  /// In en, this message translates to:
  /// **'You paid'**
  String get youPaidRow;

  /// Insights totals row.
  ///
  /// In en, this message translates to:
  /// **'Change in your balance'**
  String get balanceChange;

  /// Chart legend.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paidLegend;

  /// Chart legend.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareLegend;

  /// Insights person row.
  ///
  /// In en, this message translates to:
  /// **'paid {paid} · share {share}'**
  String paidShareLine(String paid, String share);

  /// Itemized split error.
  ///
  /// In en, this message translates to:
  /// **'Give every item a person'**
  String get itemsGiveEveryone;

  /// Itemized split error.
  ///
  /// In en, this message translates to:
  /// **'Add the item prices before tax or tip'**
  String get itemsAddPrices;

  /// Itemized split error.
  ///
  /// In en, this message translates to:
  /// **'The discount is more than the bill'**
  String get itemsDiscountTooBig;

  /// Itemized split error.
  ///
  /// In en, this message translates to:
  /// **'The items don\'t add up'**
  String get itemsDontAddUp;

  /// Split error (adjustment mode).
  ///
  /// In en, this message translates to:
  /// **'Adjustments don\'t fit the total'**
  String get adjustmentsDontFit;

  /// Split error.
  ///
  /// In en, this message translates to:
  /// **'Give someone a share'**
  String get giveSomeoneShare;

  /// Split error.
  ///
  /// In en, this message translates to:
  /// **'Check the numbers'**
  String get checkNumbers;

  /// Split error.
  ///
  /// In en, this message translates to:
  /// **'The split doesn\'t add up'**
  String get splitDoesntAddUp;

  /// Split status in Items mode with no items.
  ///
  /// In en, this message translates to:
  /// **'Add the items'**
  String get addTheItems;

  /// Split error (equal mode).
  ///
  /// In en, this message translates to:
  /// **'Pick at least one person'**
  String get pickOnePerson;

  /// Split status before an amount is typed.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Split equally between 1 person} other{Split equally between {count} people}}'**
  String splitEquallyBetween(int count);

  /// Split status.
  ///
  /// In en, this message translates to:
  /// **'All of it for 1 person'**
  String get allForOnePerson;

  /// Split status.
  ///
  /// In en, this message translates to:
  /// **'Split equally between {count} people · {amount} each'**
  String splitEquallyEach(int count, String amount);

  /// Split error.
  ///
  /// In en, this message translates to:
  /// **'Check the amounts'**
  String get checkAmounts;

  /// Split status.
  ///
  /// In en, this message translates to:
  /// **'Enter the total first'**
  String get enterTotalFirst;

  /// Split status: still to assign; {amount} is money or a percentage.
  ///
  /// In en, this message translates to:
  /// **'remaining: {amount}'**
  String remaining(String amount);

  /// Split status: assigned too much.
  ///
  /// In en, this message translates to:
  /// **'over by: {amount}'**
  String overBy(String amount);

  /// Split status.
  ///
  /// In en, this message translates to:
  /// **'Adds up'**
  String get addsUp;

  /// Split status (shares mode); {count} may have decimals, e.g. 2,5.
  ///
  /// In en, this message translates to:
  /// **'{count} shares in total'**
  String sharesInTotal(String count);

  /// Split status (shares mode).
  ///
  /// In en, this message translates to:
  /// **'1 share in total'**
  String get oneShareInTotal;

  /// Split status (adjustment mode).
  ///
  /// In en, this message translates to:
  /// **'The rest is split equally'**
  String get restSplitEqually;

  /// Tooltip of the % mode chip.
  ///
  /// In en, this message translates to:
  /// **'By percent'**
  String get byPercent;

  /// Tooltip of the Shares mode chip.
  ///
  /// In en, this message translates to:
  /// **'By shares'**
  String get byShares;

  /// Tooltip of the ± mode chip.
  ///
  /// In en, this message translates to:
  /// **'Adjust: extra or less for someone, the rest equally'**
  String get byAdjustment;

  /// Split mode chip.
  ///
  /// In en, this message translates to:
  /// **'Equal'**
  String get modeEqual;

  /// Split mode chip: exact amounts.
  ///
  /// In en, this message translates to:
  /// **'Exact'**
  String get modeExact;

  /// Split mode chip.
  ///
  /// In en, this message translates to:
  /// **'Shares'**
  String get modeShares;

  /// Tooltip of the Items mode chip.
  ///
  /// In en, this message translates to:
  /// **'By item, from a receipt'**
  String get byItem;

  /// Adjustment mode explanation.
  ///
  /// In en, this message translates to:
  /// **'Add or take off an amount for someone; the rest is split equally.'**
  String get adjustmentHelp;

  /// Split editor with no members.
  ///
  /// In en, this message translates to:
  /// **'No members'**
  String get noMembers;

  /// Number of items on a bill.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String itemCount(int count);

  /// Itemize error with no lines.
  ///
  /// In en, this message translates to:
  /// **'Add an item'**
  String get addAnItem;

  /// Itemize error.
  ///
  /// In en, this message translates to:
  /// **'At most {max} items'**
  String atMostItems(int max);

  /// Itemize error.
  ///
  /// In en, this message translates to:
  /// **'Give every item a name'**
  String get giveItemName;

  /// Itemize error.
  ///
  /// In en, this message translates to:
  /// **'An item name is too long'**
  String get itemNameTooLong;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addItem;

  /// Button: puts everyone on items without a person.
  ///
  /// In en, this message translates to:
  /// **'Give the rest to everyone'**
  String get giveRestToEveryone;

  /// Itemize row.
  ///
  /// In en, this message translates to:
  /// **'Subtotal'**
  String get subtotal;

  /// Itemize row.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// Itemize warning when the items don't match the scanned total.
  ///
  /// In en, this message translates to:
  /// **'Receipt says {printed} · items differ by {difference}'**
  String receiptSays(String printed, String difference);

  /// Itemize section heading.
  ///
  /// In en, this message translates to:
  /// **'Each person'**
  String get eachPerson;

  /// Itemize error.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item without a person} other{{count} items without a person}}'**
  String itemsWithoutPerson(int count);

  /// Item name field hint.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get itemHint;

  /// A member who left, on an item.
  ///
  /// In en, this message translates to:
  /// **'{name} (left)'**
  String memberLeft(String name);

  /// Under an item without a person.
  ///
  /// In en, this message translates to:
  /// **'Who had this?'**
  String get whoHadThis;

  /// Expense form note.
  ///
  /// In en, this message translates to:
  /// **'The group\'s default split no longer adds up, so this starts equal'**
  String get defaultSplitStartsEqual;

  /// Several payers status.
  ///
  /// In en, this message translates to:
  /// **'{amount} left to assign'**
  String leftToAssign(String amount);

  /// Helper under the amount in Items mode.
  ///
  /// In en, this message translates to:
  /// **'The total of the items'**
  String get itemsTotal;

  /// Expense form title.
  ///
  /// In en, this message translates to:
  /// **'New expense'**
  String get newExpense;

  /// Expense form title.
  ///
  /// In en, this message translates to:
  /// **'Edit expense'**
  String get editExpense;

  /// Button and tooltip: read a receipt photo into items.
  ///
  /// In en, this message translates to:
  /// **'Scan receipt'**
  String get scanReceipt;

  /// Rate field error.
  ///
  /// In en, this message translates to:
  /// **'Enter a rate above 0, or leave it empty'**
  String get rateAboveZeroOrEmpty;

  /// Button; {rate} is a number, {source} like "rate of 11 Oct".
  ///
  /// In en, this message translates to:
  /// **'Use automatic rate: {rate} ({source})'**
  String useAutoRate(String rate, String source);

  /// Expense field label.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// Expense form section heading for a refund.
  ///
  /// In en, this message translates to:
  /// **'Received by'**
  String get receivedBy;

  /// Expense form section heading.
  ///
  /// In en, this message translates to:
  /// **'Paid by'**
  String get paidBy;

  /// Chip: more than one person paid.
  ///
  /// In en, this message translates to:
  /// **'Several people'**
  String get severalPeople;

  /// Expense form section heading: the date and repeat.
  ///
  /// In en, this message translates to:
  /// **'When'**
  String get when;

  /// Tooltip of the Refund chip.
  ///
  /// In en, this message translates to:
  /// **'Money that came back, e.g. the hotel returned a deposit'**
  String get refundTooltip;

  /// Expense form section heading for a refund.
  ///
  /// In en, this message translates to:
  /// **'Split back to'**
  String get splitBackTo;

  /// Expense form section heading.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get split;

  /// Chip in a two-person group.
  ///
  /// In en, this message translates to:
  /// **'{name} owes the full amount'**
  String theyOweFull(String name);

  /// Chip in a two-person group.
  ///
  /// In en, this message translates to:
  /// **'I owe {name} the full amount'**
  String iOweFull(String name);

  /// Tooltip of the Repeat button.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeat;

  /// Note on an older repeat; {date} like "1 Nov".
  ///
  /// In en, this message translates to:
  /// **'To change future repeats, edit the latest one ({date})'**
  String editLatestRepeat(String date);

  /// Note when Repeat is set to Never on a series.
  ///
  /// In en, this message translates to:
  /// **'Stops repeating. Repeats already added stay.'**
  String get stopsRepeating;

  /// When the next repeat comes; {date} like "Sun, 1 Nov 2026".
  ///
  /// In en, this message translates to:
  /// **'Next: {date}'**
  String nextRepeat(String date);

  /// Checkbox on the latest repeat.
  ///
  /// In en, this message translates to:
  /// **'Also change future repeats'**
  String get alsoChangeFuture;

  /// What carries forward.
  ///
  /// In en, this message translates to:
  /// **'Amount, split, payers, description, category and notes'**
  String get futureFields;

  /// When "Also change future repeats" is off.
  ///
  /// In en, this message translates to:
  /// **'Only this one changes'**
  String get onlyThisOne;

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get addPhoto;

  /// Note when the receipt limit is reached.
  ///
  /// In en, this message translates to:
  /// **'{max} receipts is the most for one expense'**
  String maxReceiptsNote(int max);

  /// Title of the photo source sheet when scanning.
  ///
  /// In en, this message translates to:
  /// **'Scan a receipt'**
  String get scanAReceipt;

  /// Confirm dialog title after a scan.
  ///
  /// In en, this message translates to:
  /// **'This receipt looks like {currency}'**
  String receiptLooksLike(String currency);

  /// Confirm dialog text.
  ///
  /// In en, this message translates to:
  /// **'Switch the expense to {currency} to read its items?'**
  String switchToCurrencyQuestion(String currency);

  /// Button.
  ///
  /// In en, this message translates to:
  /// **'Switch to {currency}'**
  String switchTo(String currency);

  /// Snackbar after a scan found nothing.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read the items. Type them in.'**
  String get couldntReadItems;

  /// Expense form: the group or friend the expense is in.
  ///
  /// In en, this message translates to:
  /// **'With {name}'**
  String withName(String name);

  /// Expense form after picking another group.
  ///
  /// In en, this message translates to:
  /// **'Moves to {name} on Save'**
  String movesTo(String name);

  /// Expense form: where it moves from.
  ///
  /// In en, this message translates to:
  /// **'From {name}'**
  String fromName(String name);

  /// Tooltip.
  ///
  /// In en, this message translates to:
  /// **'Don\'t move'**
  String get dontMove;

  /// Error when moving an expense.
  ///
  /// In en, this message translates to:
  /// **'Only people on Evensies who are in both can be moved'**
  String get onlyLinkedMove;

  /// Tag on a guessed category.
  ///
  /// In en, this message translates to:
  /// **'auto'**
  String get auto;

  /// Rate field helper.
  ///
  /// In en, this message translates to:
  /// **'No automatic rate. Enter one, or leave it empty to keep this under Not converted.'**
  String get noAutoRateForm;

  /// Rate field helper.
  ///
  /// In en, this message translates to:
  /// **'Empty: this stays under Not converted'**
  String get emptyNotConverted;

  /// Rate field helper; {source} is like "rate of 11 Oct" or "your rate".
  ///
  /// In en, this message translates to:
  /// **'1 {from} = {rate} {to} (1 {to} = {inverse} {from}) · {source}'**
  String rateExplain(
    String from,
    String rate,
    String to,
    String inverse,
    String source,
  );

  /// {source} in rateExplain when the rate was typed.
  ///
  /// In en, this message translates to:
  /// **'your rate'**
  String get yourRate;

  /// Login button that signs in with a code sent by email.
  ///
  /// In en, this message translates to:
  /// **'Continue with email'**
  String get loginEmail;

  /// Title of the email sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'Sign in with email'**
  String get emailLoginTitle;

  /// Text above the email field on the sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'We\'ll email you a 6-digit code. No password needed.'**
  String get emailLoginIntro;

  /// Label of an email address field.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// Error under an email field.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get emailInvalid;

  /// Button that emails a 6-digit code.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// Text above the code field.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code we sent to {email}. It expires in 10 minutes.'**
  String codeSentTo(String email);

  /// Label of the code field.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get codeLabel;

  /// Button that checks the typed code.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get verifyCode;

  /// Button that emails a new code.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get resendCode;

  /// Disabled resend button with the seconds left.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds} s'**
  String resendCodeIn(int seconds);

  /// Snackbar after Resend code.
  ///
  /// In en, this message translates to:
  /// **'We sent a new code.'**
  String get codeResent;

  /// Button that goes back to the email field.
  ///
  /// In en, this message translates to:
  /// **'Use a different email'**
  String get useDifferentEmail;

  /// Hint under the code field.
  ///
  /// In en, this message translates to:
  /// **'Nothing arrived? Check your spam folder.'**
  String get codeCheckSpam;

  /// Error when the typed code is refused.
  ///
  /// In en, this message translates to:
  /// **'That code is wrong or has expired. Ask for a new one.'**
  String get errorCodeInvalid;

  /// Error when the server has email turned off.
  ///
  /// In en, this message translates to:
  /// **'This server doesn\'t send email.'**
  String get errorEmailNotConfigured;

  /// Error when the mail server refused the address.
  ///
  /// In en, this message translates to:
  /// **'That address can\'t receive email. Check it for typos.'**
  String get errorEmailRejected;

  /// Error when a new account email belongs to someone else.
  ///
  /// In en, this message translates to:
  /// **'Another account already uses this address.'**
  String get errorEmailTaken;

  /// Error when removing the only way to sign in.
  ///
  /// In en, this message translates to:
  /// **'Email is your only way to sign in, so it can\'t be removed.'**
  String get errorEmailRequired;

  /// Error when the server can't send email at the moment.
  ///
  /// In en, this message translates to:
  /// **'Email isn\'t working right now. Try again later.'**
  String get errorEmailUnavailable;

  /// Snackbar after a new account email was verified.
  ///
  /// In en, this message translates to:
  /// **'Email saved'**
  String get emailSaved;

  /// Confirm dialog title for removing the account email.
  ///
  /// In en, this message translates to:
  /// **'Remove {email}?'**
  String removeEmailTitle(String email);

  /// Confirm dialog text for removing the account email.
  ///
  /// In en, this message translates to:
  /// **'You\'ll get no email summaries or reminders, and you can\'t sign in with it any more.'**
  String get removeEmailMessage;

  /// Snackbar after the account email was removed.
  ///
  /// In en, this message translates to:
  /// **'Email removed'**
  String get emailRemoved;

  /// Error when changing the account email offline.
  ///
  /// In en, this message translates to:
  /// **'Changing your email needs a connection.'**
  String get emailNeedsConnection;

  /// Warning under an account email that bounces.
  ///
  /// In en, this message translates to:
  /// **'Emails to this address bounce — change it or verify it again'**
  String get emailBouncedNote;

  /// Note under the verified account email.
  ///
  /// In en, this message translates to:
  /// **'Verified · other members never see it'**
  String get emailVerifiedNote;

  /// Heading above the form that changes the account email.
  ///
  /// In en, this message translates to:
  /// **'Change email'**
  String get changeEmail;

  /// Help text on the account email screen.
  ///
  /// In en, this message translates to:
  /// **'For signing in and email summaries. We send a code to check it\'s yours. Other members never see it.'**
  String get emailAccountHelp;

  /// Button that removes the account email.
  ///
  /// In en, this message translates to:
  /// **'Remove email'**
  String get removeEmail;

  /// Settings row when the account has no email.
  ///
  /// In en, this message translates to:
  /// **'Add email'**
  String get addEmail;

  /// Subtitle of the Add email row.
  ///
  /// In en, this message translates to:
  /// **'Sign in with it and get email summaries'**
  String get addEmailHint;

  /// Snackbar after unblocking someone.
  ///
  /// In en, this message translates to:
  /// **'Unblocked {name}'**
  String unblockedName(String name);

  /// Error when blocking or unblocking offline.
  ///
  /// In en, this message translates to:
  /// **'Blocking needs a connection.'**
  String get blockNeedsConnection;

  /// Empty state of Blocked people.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t blocked anyone.'**
  String get blockedEmpty;

  /// Error state of Blocked people when offline.
  ///
  /// In en, this message translates to:
  /// **'Blocked people need a connection'**
  String get blockedNeedsConnection;

  /// Button that unblocks someone.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblock;

  /// Settings row and screen title listing blocked people.
  ///
  /// In en, this message translates to:
  /// **'Blocked people'**
  String get blockedPeople;

  /// Help text on Blocked people.
  ///
  /// In en, this message translates to:
  /// **'Blocked people can\'t add you as a friend or send you reminders, and their changes don\'t notify or email you. Shared groups and balances stay as they are.'**
  String get blockedHelp;

  /// Empty state of Deleted groups.
  ///
  /// In en, this message translates to:
  /// **'No deleted groups'**
  String get deletedGroupsEmpty;

  /// Help text on Deleted groups.
  ///
  /// In en, this message translates to:
  /// **'Restoring brings a group back for everyone, with everything in it.'**
  String get deletedGroupsHelp;

  /// Settings row and screen title listing deleted groups.
  ///
  /// In en, this message translates to:
  /// **'Deleted groups'**
  String get deletedGroups;

  /// Subtitle of the Deleted groups row.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 group can be restored} other{{count} groups can be restored}}'**
  String deletedGroupsCount(int count);

  /// Error when exporting offline.
  ///
  /// In en, this message translates to:
  /// **'Exporting needs a connection.'**
  String get exportNeedsConnection;

  /// Settings row that downloads the whole account.
  ///
  /// In en, this message translates to:
  /// **'Export everything (JSON)'**
  String get exportEverything;

  /// Subtitle of Export everything.
  ///
  /// In en, this message translates to:
  /// **'Your profile, ways to get paid, settings and every group, deleted ones too'**
  String get exportEverythingHint;

  /// Settings row choosing how often an email summary comes.
  ///
  /// In en, this message translates to:
  /// **'Email summary'**
  String get emailSummary;

  /// An email summary choice.
  ///
  /// In en, this message translates to:
  /// **'{choice, select, auto{Auto} daily{Daily} weekly{Weekly} monthly{Monthly} off{Off} other{Auto}}'**
  String digestChoice(String choice);

  /// Explains the Auto email summary choice.
  ///
  /// In en, this message translates to:
  /// **'Daily when your devices can\'t show notifications, otherwise monthly'**
  String get digestAutoHelp;

  /// Current email summary when Auto means daily.
  ///
  /// In en, this message translates to:
  /// **'Auto — daily, because notifications are off'**
  String get digestAutoDaily;

  /// Current email summary when Auto means monthly.
  ///
  /// In en, this message translates to:
  /// **'Auto — monthly, because your devices get notifications'**
  String get digestAutoMonthly;

  /// Email summary row when the account has no email.
  ///
  /// In en, this message translates to:
  /// **'Add an email under Account to get summaries'**
  String get digestNoEmail;

  /// Help row that opens a new GitHub issue.
  ///
  /// In en, this message translates to:
  /// **'Report a problem or suggest a feature'**
  String get helpReportProblem;

  /// Subtitle of the GitHub help row.
  ///
  /// In en, this message translates to:
  /// **'On GitHub, where everyone can see it'**
  String get helpReportProblemHint;

  /// Help row that writes to the server operator.
  ///
  /// In en, this message translates to:
  /// **'Email support'**
  String get helpContact;

  /// Help row that opens the privacy policy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// Settings section and row for help.
  ///
  /// In en, this message translates to:
  /// **'Help & feedback'**
  String get helpFeedback;

  /// Settings row that signs out every phone and browser.
  ///
  /// In en, this message translates to:
  /// **'Sign out on all devices'**
  String get signOutEverywhere;

  /// Confirm dialog title.
  ///
  /// In en, this message translates to:
  /// **'Sign out on all devices?'**
  String get signOutEverywhereTitle;

  /// Confirm dialog text.
  ///
  /// In en, this message translates to:
  /// **'Every phone and browser signed in to your account is signed out, this one too. Your groups stay on the server.'**
  String get signOutEverywhereMessage;

  /// Error when offline.
  ///
  /// In en, this message translates to:
  /// **'Signing out on all devices needs a connection.'**
  String get signOutEverywhereOffline;

  /// Line added to the delete-account confirmation.
  ///
  /// In en, this message translates to:
  /// **'Tip: Export everything first.'**
  String get deleteAccountExportTip;

  /// Group settings row that changes the group's cover photo.
  ///
  /// In en, this message translates to:
  /// **'Cover photo'**
  String get coverPhoto;

  /// Subtitle of the cover photo row.
  ///
  /// In en, this message translates to:
  /// **'Shown on the group\'s header and in the list. Only members see it.'**
  String get coverPhotoHint;

  /// Sheet item that removes the group's cover photo.
  ///
  /// In en, this message translates to:
  /// **'Remove cover'**
  String get removeCover;

  /// Error when uploading a cover offline.
  ///
  /// In en, this message translates to:
  /// **'Changing the cover needs a connection.'**
  String get coverNeedsConnection;

  /// Error when too many covers were uploaded.
  ///
  /// In en, this message translates to:
  /// **'That\'s a lot of cover changes. Try again in an hour.'**
  String get coverTooMany;

  /// Group settings row that deletes the group for everyone.
  ///
  /// In en, this message translates to:
  /// **'Delete group'**
  String get deleteGroup;

  /// Subtitle of Delete group.
  ///
  /// In en, this message translates to:
  /// **'For everyone · any member can restore it'**
  String get deleteGroupHint;

  /// Confirm dialog title for deleting a group.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”?'**
  String deleteGroupTitle(String name);

  /// Confirm dialog text for deleting a group.
  ///
  /// In en, this message translates to:
  /// **'Deleted for everyone. Any member can restore it from Settings → Deleted groups.'**
  String get deleteGroupMessage;

  /// Snackbar with Undo after deleting a group.
  ///
  /// In en, this message translates to:
  /// **'Deleted “{name}”'**
  String groupDeletedName(String name);

  /// Banner on a deleted group's page, next to Restore.
  ///
  /// In en, this message translates to:
  /// **'This group is deleted'**
  String get groupDeletedBanner;

  /// Snackbar after restoring a group.
  ///
  /// In en, this message translates to:
  /// **'Group restored'**
  String get groupRestored;

  /// Friend page menu item.
  ///
  /// In en, this message translates to:
  /// **'Delete friend'**
  String get deleteFriend;

  /// Confirm dialog title for deleting a friend.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteFriendTitle(String name);

  /// Confirm dialog text for deleting a friend.
  ///
  /// In en, this message translates to:
  /// **'Your non-group expenses with {name} are deleted for both of you. Shared groups stay. You can restore them from Settings → Deleted groups, or by adding {name} again.'**
  String deleteFriendMessage(String name);

  /// Snackbar with Undo after deleting a friend.
  ///
  /// In en, this message translates to:
  /// **'Deleted {name}'**
  String friendDeleted(String name);

  /// Friend page menu item and confirm button.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// Confirm dialog title for blocking someone.
  ///
  /// In en, this message translates to:
  /// **'Block {name}?'**
  String blockTitle(String name);

  /// Confirm dialog text for blocking someone.
  ///
  /// In en, this message translates to:
  /// **'{name} won\'t be able to add you as a friend or send you reminders, and their changes won\'t notify or email you. Shared groups and balances stay.'**
  String blockMessage(String name);

  /// Snackbar after blocking someone.
  ///
  /// In en, this message translates to:
  /// **'Blocked {name}'**
  String blockedName(String name);

  /// Friend page menu item that emails the server's support address.
  ///
  /// In en, this message translates to:
  /// **'Report…'**
  String get report;

  /// Subject of the report email.
  ///
  /// In en, this message translates to:
  /// **'Evensies report'**
  String get reportSubject;

  /// Body of the report email; the user id identifies the reported person.
  ///
  /// In en, this message translates to:
  /// **'User id: {userId}\n\nWhat happened:\n'**
  String reportBody(String userId);

  /// Menu item on a placeholder member.
  ///
  /// In en, this message translates to:
  /// **'Invite by email…'**
  String get inviteByEmail;

  /// Field in Add member.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get inviteEmailField;

  /// Help under the invite email field.
  ///
  /// In en, this message translates to:
  /// **'We\'ll email them an invite link. Only used for this invite.'**
  String get inviteEmailHelp;

  /// Dialog title.
  ///
  /// In en, this message translates to:
  /// **'Invite {name} by email'**
  String inviteByEmailTitle(String name);

  /// Snackbar after an email invite.
  ///
  /// In en, this message translates to:
  /// **'Invite sent to {email}'**
  String inviteEmailSent(String email);

  /// Snackbar when the new member was added offline.
  ///
  /// In en, this message translates to:
  /// **'Member added. Inviting by email needs a connection — try again from the member list.'**
  String get inviteEmailOfflineAdded;

  /// Error when inviting by email offline.
  ///
  /// In en, this message translates to:
  /// **'Inviting by email needs a connection.'**
  String get inviteEmailOffline;

  /// Error when too many invite emails were sent.
  ///
  /// In en, this message translates to:
  /// **'Email limit reached for today — share the link instead.'**
  String get inviteEmailLimit;

  /// Button under Repeat; choice is Never or N days before.
  ///
  /// In en, this message translates to:
  /// **'Email a reminder: {choice}'**
  String emailReminder(String choice);

  /// No email reminder before a repeating expense.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get remindNever;

  /// Email reminder this many days before a repeat.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day before} other{{count} days before}}'**
  String remindDaysBefore(int count);

  /// What the UPI payment method is.
  ///
  /// In en, this message translates to:
  /// **'India: Paytm, PhonePe, Google Pay and other UPI apps'**
  String get blurbUpi;

  /// Field for a UPI ID.
  ///
  /// In en, this message translates to:
  /// **'UPI ID'**
  String get fieldUpi;

  /// Hint under the UPI ID field.
  ///
  /// In en, this message translates to:
  /// **'Like name@okicici'**
  String get fieldUpiHint;

  /// Field for the name shown to payers in UPI apps.
  ///
  /// In en, this message translates to:
  /// **'Name (optional)'**
  String get fieldUpiName;

  /// Hint under the UPI name field.
  ///
  /// In en, this message translates to:
  /// **'Shown to the person paying you'**
  String get fieldUpiNameHint;

  /// Error under an invalid UPI ID.
  ///
  /// In en, this message translates to:
  /// **'Enter a UPI ID like name@bank'**
  String get methodErrorUpi;

  /// Note in the pay sheet when no UPI app opened.
  ///
  /// In en, this message translates to:
  /// **'No UPI app found. Copy the UPI ID and amount instead.'**
  String get noUpiApp;

  /// Label in the pay sheet.
  ///
  /// In en, this message translates to:
  /// **'UPI ID'**
  String get upiIdLabel;

  /// Button that copies a UPI ID.
  ///
  /// In en, this message translates to:
  /// **'Copy UPI ID'**
  String get copyUpiId;

  /// Snackbar after copying a UPI ID.
  ///
  /// In en, this message translates to:
  /// **'UPI ID copied'**
  String get upiIdCopied;

  /// The overview page in the web app's wide layout.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// Sidebar entry in the web app's wide layout: every expense of every group, newest first (the search page without a query).
  ///
  /// In en, this message translates to:
  /// **'All expenses'**
  String get allExpenses;

  /// Heading of the balances column next to a group.
  ///
  /// In en, this message translates to:
  /// **'Group balances'**
  String get groupBalances;

  /// Heading of the balance column next to a friend.
  ///
  /// In en, this message translates to:
  /// **'Your balance'**
  String get yourBalance;

  /// Dashboard column of people who owe me.
  ///
  /// In en, this message translates to:
  /// **'Owes you'**
  String get dashboardOwesYou;

  /// Dashboard column of people I owe.
  ///
  /// In en, this message translates to:
  /// **'You owe'**
  String get dashboardYouOwe;

  /// Heading of the expense's thread of changes and comments.
  ///
  /// In en, this message translates to:
  /// **'History and comments'**
  String get historyAndComments;

  /// Button that loads older history at the top of the thread.
  ///
  /// In en, this message translates to:
  /// **'Show earlier'**
  String get showEarlier;

  /// Title of the dialog shown instead of deleting a friend while a non-group balance is open.
  ///
  /// In en, this message translates to:
  /// **'Settle up first'**
  String get settleUpFirst;

  /// Text under the non-group balance in that dialog.
  ///
  /// In en, this message translates to:
  /// **'You can delete {name} as a friend once your non-group expenses are settled up.'**
  String deleteFriendSettleFirst(String name);

  /// Sheet text when no email app opened (Report…, Email support).
  ///
  /// In en, this message translates to:
  /// **'No email app found. Copy the details below and write from any email app.'**
  String get noMailApp;

  /// Button that copies an email address.
  ///
  /// In en, this message translates to:
  /// **'Copy address'**
  String get copyAddress;

  /// Button that copies the prepared email text.
  ///
  /// In en, this message translates to:
  /// **'Copy message'**
  String get copyMessage;

  /// Whole-page message when the browser cannot open the app database.
  ///
  /// In en, this message translates to:
  /// **'This browser can\'t keep Evensies\' data. Try another browser, or a window that isn\'t private.'**
  String get browserNoStorage;

  /// Whole-page message in a browser that keeps a database copy per tab, when another tab already has it.
  ///
  /// In en, this message translates to:
  /// **'Evensies is already open in another tab of this browser. Use that tab, or close it and reload this one.'**
  String get browserOtherTab;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'de',
    'en',
    'es',
    'fr',
    'id',
    'it',
    'ja',
    'ko',
    'nl',
    'pl',
    'pt',
    'sv',
    'th',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'id':
      return AppLocalizationsId();
    case 'it':
      return AppLocalizationsIt();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'nl':
      return AppLocalizationsNl();
    case 'pl':
      return AppLocalizationsPl();
    case 'pt':
      return AppLocalizationsPt();
    case 'sv':
      return AppLocalizationsSv();
    case 'th':
      return AppLocalizationsTh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
