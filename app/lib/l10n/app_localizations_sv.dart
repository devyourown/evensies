// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get appTitle => 'Evensies';

  @override
  String get cancel => 'Avbryt';

  @override
  String get delete => 'Radera';

  @override
  String get remove => 'Ta bort';

  @override
  String get save => 'Spara';

  @override
  String get done => 'Klar';

  @override
  String get undo => 'Ångra';

  @override
  String get retry => 'Försök igen';

  @override
  String get ok => 'OK';

  @override
  String get close => 'Stäng';

  @override
  String get edit => 'Redigera';

  @override
  String get add => 'Lägg till';

  @override
  String get offlineBanner => 'Offline — ändringar synkas senare';

  @override
  String get tooLong => 'För långt';

  @override
  String get allCurrencies => 'Alla valutor';

  @override
  String get errorUnexpected => 'Något gick fel. Försök igen.';

  @override
  String get errorNetwork => 'Du är offline. Försök igen senare.';

  @override
  String get errorRateLimited =>
      'För många försök. Vänta en minut och försök igen.';

  @override
  String get errorNotFound => 'Det finns inte längre.';

  @override
  String get errorForbidden => 'Det får du inte göra.';

  @override
  String get errorValidation => 'Servern nekade det.';

  @override
  String get errorSumMismatch => 'Uppdelningen går inte ihop.';

  @override
  String get errorPayersSumMismatch => 'Betalarna går inte ihop.';

  @override
  String get errorNegativeAmount => 'Ett belopp är under noll.';

  @override
  String get errorNegativeShare => 'Någons andel skulle bli under noll.';

  @override
  String get errorNegativeTotal => 'Summan skulle bli under noll.';

  @override
  String get errorZeroSubtotal =>
      'Fyll i priserna före skatt, dricks eller rabatt.';

  @override
  String get errorUnassignedItem => 'Varje post behöver minst en person.';

  @override
  String get errorNoMembers => 'Välj minst en person att dela med.';

  @override
  String get errorInvalidInput => 'Kontrollera siffrorna.';

  @override
  String get errorBadRate => 'Växelkursen måste vara över noll.';

  @override
  String get errorUnknownMember =>
      'Det gäller någon som inte är med i gruppen.';

  @override
  String get errorUnknownCurrency => 'Valutan stöds inte.';

  @override
  String get errorMemberTaken => 'Den medlemmen är redan vald.';

  @override
  String get errorLimitExceeded => 'Gränsen är nådd.';

  @override
  String get errorTooLarge => 'Bilden är för stor.';

  @override
  String get errorNotJpeg => 'Välj en JPEG-bild';

  @override
  String get errorFxUnavailable => 'Växelkurser är inte tillgängliga just nu.';

  @override
  String get errorImportFailed => 'Filen kunde inte importeras.';

  @override
  String get errorAuthNotConfigured =>
      'Den här servern kan inte logga in dig på det sättet.';

  @override
  String get errorDuplicate => 'Det finns redan.';

  @override
  String errorGeneric(String code) {
    return 'Något gick fel ($code).';
  }

  @override
  String rejectedReceipt(String name, String reason) {
    return 'Kunde inte spara kvittot för ”$name”: $reason';
  }

  @override
  String rejectedReceiptUnnamed(String reason) {
    return 'Kunde inte spara kvittot för en utgift: $reason';
  }

  @override
  String rejectedReceiptRemove(String name, String reason) {
    return 'Kunde inte spara borttagningen av ett kvitto från ”$name”: $reason';
  }

  @override
  String rejectedReceiptRemoveUnnamed(String reason) {
    return 'Kunde inte spara borttagningen av ett kvitto från en utgift: $reason';
  }

  @override
  String rejectedRepeating(String name, String reason) {
    return 'Kunde inte spara upprepningen av ”$name”: $reason';
  }

  @override
  String rejectedRepeatingUnnamed(String reason) {
    return 'Kunde inte spara en återkommande utgift: $reason';
  }

  @override
  String rejectedSeriesChange(String name, String reason) {
    return 'Kunde inte spara en ändring av kommande ”$name”: $reason';
  }

  @override
  String rejectedSeriesChangeUnnamed(String reason) {
    return 'Kunde inte spara en ändring av en återkommande utgift: $reason';
  }

  @override
  String rejectedSeriesStop(String name, String reason) {
    return 'Kunde inte spara att ”$name” slutar upprepas: $reason';
  }

  @override
  String rejectedSeriesStopUnnamed(String reason) {
    return 'Kunde inte spara att en återkommande utgift slutar: $reason';
  }

  @override
  String rejectedSavedNoRepeat(String name, String reason) {
    return '”$name” sparades men upprepas inte: $reason';
  }

  @override
  String rejectedPaymentRestore(String reason) {
    return 'Kunde inte spara återställningen av en betalning: $reason';
  }

  @override
  String rejectedNewExpense(String name, String reason) {
    return 'Kunde inte spara den nya utgiften ”$name”: $reason';
  }

  @override
  String rejectedNewExpenseUnnamed(String reason) {
    return 'Kunde inte spara en ny utgift: $reason';
  }

  @override
  String rejectedExpenseChange(String name, String reason) {
    return 'Kunde inte spara en ändring av ”$name”: $reason';
  }

  @override
  String rejectedExpenseChangeUnnamed(String reason) {
    return 'Kunde inte spara en ändring av en utgift: $reason';
  }

  @override
  String rejectedExpenseDelete(String name, String reason) {
    return 'Kunde inte spara raderingen av ”$name”: $reason';
  }

  @override
  String rejectedExpenseDeleteUnnamed(String reason) {
    return 'Kunde inte spara raderingen av en utgift: $reason';
  }

  @override
  String rejectedExpenseRestore(String name, String reason) {
    return 'Kunde inte spara återställningen av ”$name”: $reason';
  }

  @override
  String rejectedExpenseRestoreUnnamed(String reason) {
    return 'Kunde inte spara återställningen av en utgift: $reason';
  }

  @override
  String rejectedComment(String name, String reason) {
    return 'Kunde inte spara en kommentar på ”$name”: $reason';
  }

  @override
  String rejectedCommentUnnamed(String reason) {
    return 'Kunde inte spara en kommentar på en utgift: $reason';
  }

  @override
  String rejectedPaymentComment(String reason) {
    return 'Kunde inte spara en kommentar på en betalning: $reason';
  }

  @override
  String rejectedCommentDelete(String reason) {
    return 'Kunde inte spara raderingen av en kommentar: $reason';
  }

  @override
  String rejectedPayment(String reason) {
    return 'Kunde inte spara en betalning: $reason';
  }

  @override
  String rejectedPaymentDelete(String reason) {
    return 'Kunde inte spara raderingen av en betalning: $reason';
  }

  @override
  String rejectedPaymentConfirm(String reason) {
    return 'Kunde inte spara bekräftelsen av en betalning: $reason';
  }

  @override
  String rejectedGroupSettings(String reason) {
    return 'Kunde inte spara en ändring av gruppinställningarna: $reason';
  }

  @override
  String rejectedMemberAdd(String name, String reason) {
    return 'Kunde inte spara att $name läggs till: $reason';
  }

  @override
  String rejectedMemberAddUnnamed(String reason) {
    return 'Kunde inte spara att en medlem läggs till: $reason';
  }

  @override
  String rejectedMemberRemove(String reason) {
    return 'Kunde inte spara borttagningen av en medlem: $reason';
  }

  @override
  String rejectedOther(String reason) {
    return 'Kunde inte spara en ändring: $reason';
  }

  @override
  String get reasonReceiptLimit => 'en utgift kan ha högst 10 kvitton';

  @override
  String get reasonSeriesLimit =>
      'en grupp kan ha högst 100 återkommande utgifter';

  @override
  String get reasonNotUploaded => 'bilden laddades inte upp';

  @override
  String get reasonSumMismatch => 'uppdelningen går inte ihop';

  @override
  String get reasonPayersSumMismatch => 'betalarna går inte ihop';

  @override
  String get reasonNegativeAmount => 'ett belopp är under noll';

  @override
  String get reasonUnknownMember =>
      'det gäller någon som inte är med i gruppen';

  @override
  String get reasonUnknownCurrency => 'valutan stöds inte';

  @override
  String get reasonMemberTaken => 'den medlemmen är redan vald';

  @override
  String get reasonGroupFull => 'gruppen är full';

  @override
  String get reasonForbidden => 'du får inte göra den ändringen';

  @override
  String get reasonRefused => 'servern nekade det';

  @override
  String leaveOwe(String amount) {
    return 'Du är skyldig $amount · gör upp först';
  }

  @override
  String leaveOweIn(String amount, String currency) {
    return 'Du är skyldig $amount · gör upp först i $currency';
  }

  @override
  String leaveOwed(String amount) {
    return 'Du ska få $amount · gör upp först';
  }

  @override
  String leaveOwedIn(String amount, String currency) {
    return 'Du ska få $amount · gör upp först i $currency';
  }

  @override
  String leaveSeries(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Du är fortfarande med i $count återkommande utgifter ($names) · redigera den senaste eller stoppa dem först',
      one:
          'Du är fortfarande med i 1 återkommande utgift ($names) · redigera den senaste eller stoppa den först',
    );
    return '$_temp0';
  }

  @override
  String seriesNamesMore(String names, int count) {
    return '$names och $count till';
  }

  @override
  String get seriesUnnamed => 'en utgift';

  @override
  String get listJoiner => ', ';

  @override
  String get repeatNever => 'Aldrig';

  @override
  String get repeatWeekly => 'Varje vecka';

  @override
  String get repeatBiweekly => 'Varannan vecka';

  @override
  String get repeatMonthly => 'Varje månad';

  @override
  String get repeatYearly => 'Varje år';

  @override
  String summaryNotConverted(String currency) {
    return 'Inte omräknat · $currency';
  }

  @override
  String summaryTotalSpent(String amount) {
    return 'Totalt spenderat: $amount';
  }

  @override
  String summaryPaidShare(String paid, String share) {
    return 'Du betalade: $paid · Din andel: $share';
  }

  @override
  String summaryPayments(String made, String received) {
    return 'Betalningar gjorda: $made · mottagna: $received';
  }

  @override
  String summaryTopCategories(String list) {
    return 'Toppkategorier: $list';
  }

  @override
  String get summaryBalancesToday => 'Saldon i dag';

  @override
  String summaryGetsBack(String name, String amount) {
    return '$name får tillbaka $amount';
  }

  @override
  String summaryOwes(String name, String amount) {
    return '$name är skyldig $amount';
  }

  @override
  String get summaryFooter => 'Delat från Evensies';

  @override
  String get koreanBank => 'Koreanskt bankkonto';

  @override
  String requestText(String amount, String group) {
    return 'Du är skyldig mig $amount för $group på Evensies.';
  }

  @override
  String requestTextWays(String amount, String group, String ways) {
    return 'Du är skyldig mig $amount för $group på Evensies. Betala med: $ways';
  }

  @override
  String get requestNoGroup => 'våra gemensamma utgifter';

  @override
  String get leaveSyncing => 'Synkar fortfarande. Försök igen om en stund.';

  @override
  String get leaveOffline => 'Du måste vara online för att lämna';

  @override
  String get moveOffline =>
      'Kunde inte flytta den. Försök igen när du är online';

  @override
  String moveFailed(String reason) {
    return 'Kunde inte flytta den: $reason';
  }

  @override
  String get photoNoAccess =>
      'Evensies har ingen åtkomst. Tillåt det i appen Inställningar.';

  @override
  String get photoNoCamera => 'Kunde inte öppna kameran.';

  @override
  String get photoNoLibrary => 'Kunde inte öppna bildbiblioteket.';

  @override
  String get photoUnusable => 'Bilden kunde inte användas. Prova en annan.';

  @override
  String get methodErrorUsername => 'Endast bokstäver, siffror, . _ - (max 40)';

  @override
  String methodErrorLinkPrefix(String prefix) {
    return 'Måste börja med $prefix';
  }

  @override
  String get methodErrorTooLong => 'Max 200 tecken';

  @override
  String get methodErrorIban => 'Inte ett giltigt IBAN';

  @override
  String get methodErrorHolder => 'Kontoinnehavarens namn (1–70 tecken)';

  @override
  String get methodErrorBic => 'BIC har 8 eller 11 tecken';

  @override
  String get methodErrorKrAccount => 'Siffror och bindestreck, 8–20 siffror';

  @override
  String get methodErrorBank => 'Bankens namn (1–30 tecken)';

  @override
  String get methodErrorUnknownType => 'Okänd typ';

  @override
  String get methodErrorTooMany =>
      'Högst 8 sätt att få betalt, och 3 av varje banktyp';

  @override
  String get bannerDismiss => 'Stäng';

  @override
  String get bannerView => 'Visa';

  @override
  String get loginTagline =>
      'Dela utgifter med vänner. Inga annonser, inga merförsäljningar.';

  @override
  String get loginApple => 'Fortsätt med Apple';

  @override
  String get loginGoogle => 'Fortsätt med Google';

  @override
  String get loginWebUnavailable =>
      'Den här servern har ingen inloggning i webbläsaren ännu.';

  @override
  String get welcomeTitle => 'Välkommen';

  @override
  String get yourNameTitle => 'Ditt namn';

  @override
  String get nameQuestion => 'Vad ska dina vänner kalla dig?';

  @override
  String get nameExplain => 'Det här är namnet andra medlemmar ser.';

  @override
  String get nameHelp =>
      'Det visas för personer i dina grupper. Du kan ändra det senare i Inställningar.';

  @override
  String get nameLabel => 'Namn';

  @override
  String get lockReason => 'Lås upp Evensies';

  @override
  String get lockTitle => 'Evensies är låst';

  @override
  String get lockSubtitle =>
      'Lås upp med Face ID, Touch ID, ditt fingeravtryck eller enhetens lösenkod.';

  @override
  String get lockUnlock => 'Lås upp';

  @override
  String get lockSignOutConfirm =>
      'Logga ut och radera data på den här enheten? Dina grupper finns kvar på servern.';

  @override
  String get signOut => 'Logga ut';

  @override
  String get widgetOwed => 'Du ska få';

  @override
  String get widgetOwe => 'Du är skyldig';

  @override
  String get widgetSignedOut => 'Logga in för att se ditt saldo';

  @override
  String get widgetSettled => 'Allt är uppgjort';

  @override
  String widgetUpdated(String time) {
    return 'Uppdaterad $time';
  }

  @override
  String get receiptAdd => 'Lägg till ett kvitto';

  @override
  String get photoTake => 'Ta bild';

  @override
  String get photoChoose => 'Välj från biblioteket';

  @override
  String get photoChooseFile => 'Välj en fil';

  @override
  String get availableWhenOnline => 'Tillgänglig när du är online';

  @override
  String get receiptPhoto => 'Kvittobild';

  @override
  String get receiptAvailableOnline => 'Bilden är tillgänglig när du är online';

  @override
  String get receiptRemoveTitle => 'Ta bort kvittot?';

  @override
  String get receiptRemoveMessage => 'Det tas bort för alla i gruppen.';

  @override
  String get receiptTitle => 'Kvitto';

  @override
  String receiptTitleOf(int index, int count) {
    return 'Kvitto $index av $count';
  }

  @override
  String get shareOrSave => 'Dela eller spara';

  @override
  String get share => 'Dela';

  @override
  String get copiedToClipboard => 'Kopierat till urklipp';

  @override
  String get settingsTitle => 'Inställningar';

  @override
  String get photoRemove => 'Ta bort bild';

  @override
  String get photoNeedsConnection =>
      'Du behöver en anslutning för att byta bild.';

  @override
  String get photoTooMany => 'För många bildbyten. Försök igen om en timme.';

  @override
  String get notifSaveFailed =>
      'Kunde inte spara aviseringsinställningarna. Kontrollera din anslutning.';

  @override
  String get homeCurrencyNeedsConnection =>
      'Du behöver en anslutning för att byta hemvaluta.';

  @override
  String get changePhoto => 'Byt profilbild';

  @override
  String get yourNameTapToChange => 'Ditt namn · tryck för att ändra';

  @override
  String get waysToGetPaid => 'Sätt att få betalt';

  @override
  String get waysToGetPaidHint => 'PayPal, Wise, IBAN, bankkonto…';

  @override
  String get homeCurrency => 'Hemvaluta';

  @override
  String get homeCurrencyFromRegion =>
      'Från din region · saldon visas också ≈ i den';

  @override
  String get homeCurrencyPicked => 'Saldon visas också ≈ i den';

  @override
  String get notifications => 'Aviseringar';

  @override
  String get notifExpenses => 'Utgifter och betalningar';

  @override
  String get notifComments => 'Kommentarer';

  @override
  String get notifMembers => 'Medlemmar och gruppändringar';

  @override
  String get notifReminders => 'Påminnelser från vänner';

  @override
  String get notifNeedConnection =>
      'Aviseringsinställningar kräver en anslutning';

  @override
  String get notifOthersOnly => 'Bara ändringar som andra gör ger aviseringar.';

  @override
  String get notifWebNote =>
      'Aviseringar går till din telefon; webbläsaren uppdateras varje minut medan den är öppen.';

  @override
  String get exportImport => 'Exportera och importera';

  @override
  String get noGroupsToExport => 'Inga grupper att exportera.';

  @override
  String get nonGroup => 'Utanför grupp';

  @override
  String nonGroupWith(String name) {
    return 'Utanför grupp · $name';
  }

  @override
  String get exportJson => 'Exportera JSON';

  @override
  String get exportCsv => 'Exportera CSV';

  @override
  String get exportZip => 'ZIP med kvitton';

  @override
  String get importSplitwise => 'Importera Splitwise-CSV';

  @override
  String importedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count utgifter importerade',
      one: '1 utgift importerad',
    );
    return '$_temp0';
  }

  @override
  String get server => 'Server';

  @override
  String get serverUrl => 'Server-URL';

  @override
  String serverDefault(String url) {
    return 'Standard: $url';
  }

  @override
  String get serverSaved => 'Server-URL sparad';

  @override
  String get account => 'Konto';

  @override
  String get licenses => 'Licenser';

  @override
  String get deleteAccount => 'Radera konto';

  @override
  String get signOutTitle => 'Logga ut?';

  @override
  String get signOutMessage =>
      'Lokal data på den här enheten raderas. Ändringar som inte har synkats går förlorade.';

  @override
  String get deleteAccountTitle => 'Radera kontot?';

  @override
  String get deleteAccountMessage =>
      'Dina medlemskap blir platshållare. Gruppdata stannar hos de andra medlemmarna. Det går inte att ångra.';

  @override
  String get language => 'Språk';

  @override
  String languageSystem(String language) {
    return 'System ($language)';
  }

  @override
  String get appearance => 'Utseende';

  @override
  String get appearanceSystem => 'System';

  @override
  String get appearanceLight => 'Ljust';

  @override
  String get appearanceDark => 'Mörkt';

  @override
  String get security => 'Säkerhet';

  @override
  String get appLock => 'Applås';

  @override
  String get appLockHint =>
      'Face ID, Touch ID eller fingeravtryck, med enhetens lösenkod som reserv. Låses efter en minut borta.';

  @override
  String methodRemoveTitle(String method) {
    return 'Ta bort $method?';
  }

  @override
  String get methodsOffline =>
      'Anslut till internet för att redigera dina sätt att få betalt.';

  @override
  String get methodsLoadFailed => 'Kunde inte läsa in dina sätt att få betalt.';

  @override
  String get methodsIntro =>
      'Gruppmedlemmar ser dem när de är skyldiga dig pengar, så att de kan betala med ett tryck. Evensies flyttar aldrig pengar själv.';

  @override
  String get methodsEmpty => 'Inga sätt att få betalt ännu.';

  @override
  String get blurbPaypal => 'PayPal.me-länk, belopp ifyllt';

  @override
  String get blurbWise => 'Wise Quick Pay-länk, belopp ifyllt';

  @override
  String get blurbVenmo => 'Venmo-användarnamn (USA)';

  @override
  String get blurbRevolut => 'Revolut.me-användarnamn';

  @override
  String get blurbKakaopay => 'KakaoPay 송금코드-länk';

  @override
  String get blurbIban => 'Banköverföring (SEPA-QR för EUR)';

  @override
  String get blurbKrBank => 'Koreanskt bankkonto (Toss, bankappar)';

  @override
  String get fieldPaypal => 'PayPal.me-användarnamn';

  @override
  String get fieldPaypalHint => 'Ditt PayPal.me-användarnamn, t.ex. anna';

  @override
  String get fieldRevolut => 'Revolut.me-användarnamn';

  @override
  String get fieldRevolutHint => 'Ditt Revolut.me-användarnamn, t.ex. anna';

  @override
  String get fieldVenmo => 'Venmo-användarnamn';

  @override
  String get fieldVenmoHint => 'Utan @, t.ex. anna-rossi';

  @override
  String get fieldWise => 'Wise Quick Pay-länk';

  @override
  String get fieldWiseHint =>
      'I Wise: Betalningar → Quick Pay → kopiera länk (https://wise.com/pay/…)';

  @override
  String get fieldKakaopay => 'KakaoPay 송금코드-länk';

  @override
  String get fieldKakaopayHint =>
      'I KakaoPay: 송금 → 송금코드 → kopiera länk (https://qr.kakaopay.com/…)';

  @override
  String get fieldHolder => 'Kontoinnehavare';

  @override
  String get fieldHolderHint => 'Namnet exakt som på kontot';

  @override
  String get fieldIban => 'IBAN';

  @override
  String get fieldIbanHint => 't.ex. SE45 5000 0000 0583 9825 7466';

  @override
  String get fieldBic => 'BIC (valfritt)';

  @override
  String get fieldBicHint => '8 eller 11 tecken';

  @override
  String get fieldBank => 'Bank';

  @override
  String get fieldBankHint => 't.ex. 신한은행, Toss Bank';

  @override
  String get fieldAccountNumber => 'Kontonummer';

  @override
  String get fieldAccountNumberHint => 'Siffror, bindestreck valfria';

  @override
  String amountCopied(String amount) {
    return 'Belopp kopierat: $amount';
  }

  @override
  String couldNotOpen(String link) {
    return 'Kunde inte öppna $link';
  }

  @override
  String get payOffline => 'Offline: betalsätt är inte tillgängliga';

  @override
  String get payLoading => 'Läser in betalsätt…';

  @override
  String payAskToAdd(String name) {
    return 'Be $name att lägga till ett sätt att få betalt';
  }

  @override
  String payTitle(String name, String amount) {
    return 'Betala $amount till $name';
  }

  @override
  String get payScanQr => 'Skanna med din bankapp (SEPA-QR)';

  @override
  String get payQrEurOnly => 'QR-koden finns bara för överföringar i EUR.';

  @override
  String get bankLabel => 'Bank';

  @override
  String get ibanLabel => 'IBAN';

  @override
  String get accountLabel => 'Konto';

  @override
  String get bicLabel => 'BIC';

  @override
  String get holderLabel => 'Innehavare';

  @override
  String get amountLabel => 'Belopp';

  @override
  String get copyIban => 'Kopiera IBAN';

  @override
  String get copyAccount => 'Kopiera konto';

  @override
  String get copyAmount => 'Kopiera belopp';

  @override
  String get ibanCopied => 'IBAN kopierat';

  @override
  String get accountCopied => 'Konto kopierat';

  @override
  String get paymentUpdated => 'Betalningen uppdaterad';

  @override
  String paymentRecordedPending(String amount, String name) {
    return 'Registrerade $amount. $name bekräftar.';
  }

  @override
  String paymentRecordedPendingUnnamed(String amount) {
    return 'Registrerade $amount. Den andra personen bekräftar.';
  }

  @override
  String paymentRecorded(String amount) {
    return 'Betalning på $amount registrerad';
  }

  @override
  String youSuffix(String name) {
    return '$name (du)';
  }

  @override
  String get recordPayment => 'Registrera en betalning';

  @override
  String get editPayment => 'Redigera betalning';

  @override
  String get fromLabel => 'Från';

  @override
  String get toLabel => 'Till';

  @override
  String get swap => 'Byt plats';

  @override
  String get pickTwoPeople => 'Välj två olika personer';

  @override
  String get commentsStayOld => 'Kommentarer stannar på den gamla betalningen';

  @override
  String get recordPaymentButton => 'Registrera betalning';

  @override
  String get paymentNotHere => 'Den här betalningen finns inte på enheten';

  @override
  String get notSyncedOrLeft =>
      'Den har inte synkats än, eller så har du lämnat gruppen.';

  @override
  String get someone => 'Någon';

  @override
  String get paymentEdited => 'Redigerad betalning';

  @override
  String get paymentDeleted => 'Raderad betalning';

  @override
  String get payment => 'Betalning';

  @override
  String get paymentWasEdited => 'Den här betalningen redigerades';

  @override
  String get paymentWasEditedNote =>
      'Den redigerade betalningen räknas i stället. Kommentarerna stannar här.';

  @override
  String get paymentWasDeleted => 'Den här betalningen raderades';

  @override
  String get paymentNotCounted => 'Den räknas inte i saldona.';

  @override
  String get restore => 'Återställ';

  @override
  String youPaidName(String name) {
    return 'Du betalade $name';
  }

  @override
  String namePaidYou(String name) {
    return '$name betalade dig';
  }

  @override
  String namePaidName(String from, String to) {
    return '$from betalade $to';
  }

  @override
  String paymentSaysSent(String name) {
    return '$name säger att det här skickades till dig. Har det kommit fram?';
  }

  @override
  String waitingForConfirm(String name) {
    return 'Väntar på bekräftelse från $name';
  }

  @override
  String get notReceived => 'Inte mottagen';

  @override
  String get confirmReceived => 'Bekräfta mottagen';

  @override
  String get deletePaymentTitle => 'Radera betalningen?';

  @override
  String get deletePaymentMessage => 'Skulden den gjorde upp kommer tillbaka.';

  @override
  String get paymentDeletedSnack => 'Betalningen raderad';

  @override
  String get notReceivedTitle => 'Inte mottagen?';

  @override
  String notReceivedMessage(String name) {
    return 'Betalningen från $name tas bort och skulden kommer tillbaka.';
  }

  @override
  String get paymentRemovedSnack => 'Betalningen borttagen';

  @override
  String get recordAPayment => 'Registrera en betalning';

  @override
  String get nothingToSettle => 'Inget att göra upp';

  @override
  String get everyoneEven => 'Alla är kvitt.';

  @override
  String get waitingForConfirmation => 'Väntar på bekräftelse';

  @override
  String get debtsAsRecorded =>
      'Skulder som de registrerades · förenkla skulder är av';

  @override
  String transfersSettleEverything(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count överföringar gör upp allt',
      one: '1 överföring gör upp allt',
    );
    return '$_temp0';
  }

  @override
  String transfersSettleBalance(int count, String currency) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count överföringar gör upp saldot i $currency',
      one: '1 överföring gör upp saldot i $currency',
    );
    return '$_temp0';
  }

  @override
  String notConvertedSettlesIn(String currency) {
    return 'Inte omräknat · $currency · görs upp i $currency';
  }

  @override
  String get convert => 'Räkna om';

  @override
  String get settleUp => 'Gör upp';

  @override
  String saysTheySent(String name, String amount) {
    return '$name säger att du fått $amount';
  }

  @override
  String waitingToConfirmAmount(String name, String amount) {
    return 'Väntar på att $name bekräftar $amount';
  }

  @override
  String get you => 'Du';

  @override
  String get request => 'Begär';

  @override
  String get iveSentIt => 'Jag har skickat';

  @override
  String get markAsPaid => 'Markera som betald';

  @override
  String markedAsSent(String name) {
    return 'Markerad som skickad. $name bekräftar.';
  }

  @override
  String approx(String amount) {
    return '≈ $amount';
  }

  @override
  String friendOwesYou(String name, String amount) {
    return '$name är skyldig dig $amount';
  }

  @override
  String friendYouOwe(String name, String amount) {
    return 'Du är skyldig $name $amount';
  }

  @override
  String friendYouOweLine(String name, String amount) {
    return 'du är skyldig $name $amount';
  }

  @override
  String noSharedGroup(String name) {
    return 'Du delar inte längre någon grupp med $name. Skicka din vänlänk för att lägga till utgifter.';
  }

  @override
  String get shareFriendLink => 'Dela vänlänk';

  @override
  String firstExpenseNeedsConnection(String name) {
    return 'Den första utgiften med $name kräver en anslutning.';
  }

  @override
  String reminderSent(String name) {
    return 'Påminnelse skickad till $name';
  }

  @override
  String remindTomorrow(String name) {
    return 'Du kan påminna $name igen i morgon';
  }

  @override
  String remindNothingOwed(String name) {
    return '$name är inte skyldig dig något';
  }

  @override
  String get remindNeedsConnection =>
      'Du behöver en anslutning för att skicka en påminnelse.';

  @override
  String amountsAnd(String a, String b) {
    return '$a och $b';
  }

  @override
  String inviteFriendText(String link) {
    return 'Jag har lagt till dig på Evensies så att vi kan dela utgifter. Häng med: $link';
  }

  @override
  String get personNotHere => 'Den här personen finns inte på enheten';

  @override
  String get personNotHereNote =>
      'Den har inte synkats än, eller så delar ni inte längre någon grupp.';

  @override
  String get more => 'Mer';

  @override
  String get exportNonGroupCsv => 'Exportera utgifter utanför grupp (CSV)';

  @override
  String get exportNonGroupJson => 'Exportera utgifter utanför grupp (JSON)';

  @override
  String get exportNonGroupZip =>
      'Exportera utgifter utanför grupp (ZIP med kvitton)';

  @override
  String get notOnEvensies => 'Inte på Evensies än';

  @override
  String get allSettledUp => 'Allt är uppgjort';

  @override
  String get remind => 'Påminn';

  @override
  String get invite => 'Bjud in';

  @override
  String get balances => 'Saldon';

  @override
  String get expensesAndPayments => 'Utgifter och betalningar';

  @override
  String get nothingTogetherYet =>
      'Inget gemensamt än. Lägg till en utgift nedan.';

  @override
  String get addExpense => 'Lägg till utgift';

  @override
  String personOwesYou(String amount) {
    return 'är skyldig dig $amount';
  }

  @override
  String personYouOwe(String amount) {
    return 'du är skyldig $amount';
  }

  @override
  String get personSettledUp => 'uppgjort';

  @override
  String recordedInGroups(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Registrerat i $count grupper',
      one: 'Registrerat i 1 grupp',
    );
    return '$_temp0';
  }

  @override
  String get markAsReceived => 'Markera som mottagen';

  @override
  String get clearBothSides => 'Nolla båda sidor';

  @override
  String evenIn(String currency) {
    return 'Kvitt i $currency';
  }

  @override
  String linePayThem(String group, String name, String amount) {
    return '$group: du betalar $name $amount';
  }

  @override
  String lineTheyPay(String group, String name, String amount) {
    return '$group: $name betalar dig $amount';
  }

  @override
  String get noMoneyMoves =>
      'Inga pengar flyttas: båda sidor registreras som uppgjorda.';

  @override
  String convertIn(String group) {
    return 'Räkna om i $group';
  }

  @override
  String settleUpWith(String name) {
    return 'Gör upp med $name';
  }

  @override
  String nothingToSettleWith(String name) {
    return 'Inget att göra upp med $name';
  }

  @override
  String settleWithIntro(String name) {
    return 'Allt mellan dig och $name, per valuta. Registreringen lägger till en betalning i varje grupp.';
  }

  @override
  String get searchFriendsGroups => 'Sök vänner och grupper';

  @override
  String get friends => 'Vänner';

  @override
  String get groups => 'Grupper';

  @override
  String get noFriendsOrGroups => 'Inga vänner eller grupper än.';

  @override
  String nothingMatches(String query) {
    return 'Inget matchar ”$query”.';
  }

  @override
  String get addExpenseWithWhom => 'Lägg till utgift · med vem?';

  @override
  String friendLinkShare(String link, String code) {
    return 'Lägg till mig på Evensies för att dela utgifter: $link\nEller skriv in min kod $code';
  }

  @override
  String get friendLinkNeedsConnection =>
      'Du behöver en anslutning för att dela din vänlänk.';

  @override
  String get selfFriend => 'Det är din egen kod';

  @override
  String get noOneForCode => 'Ingen hittades med den här koden';

  @override
  String get addFriendNeedsConnection =>
      'Du behöver en anslutning för att lägga till en vän.';

  @override
  String get newFriendCodeTitle => 'Skapa en ny vänkod?';

  @override
  String get newFriendCodeMessage =>
      'Din nuvarande länk och kod slutar fungera. Vänner du redan har finns kvar.';

  @override
  String get newCode => 'Ny kod';

  @override
  String get addAFriend => 'Lägg till en vän';

  @override
  String get friendLinkOffline => 'Din vänlänk kräver en anslutning';

  @override
  String get yourFriendCode => 'Din vänkod';

  @override
  String get friendQrLabel => 'QR-kod för din vänlänk';

  @override
  String get friendCodeHelp =>
      'Vänner skannar den, öppnar länken eller skriver in koden.';

  @override
  String get shareLink => 'Dela länk';

  @override
  String get codeCopied => 'Koden kopierad';

  @override
  String get copyCode => 'Kopiera kod';

  @override
  String get haveFriendCode => 'Har du en väns kod?';

  @override
  String get onEvensies => 'på Evensies';

  @override
  String get notOnEvensiesSection => 'Någon som inte är på Evensies än';

  @override
  String get notOnEvensiesHelp =>
      'Lägg till utgifter med personen direkt och bjud in hen senare.';

  @override
  String atMostChars(int max) {
    return 'Högst $max tecken';
  }

  @override
  String addName(String name) {
    return 'Lägg till $name';
  }

  @override
  String get search => 'Sök';

  @override
  String get activity => 'Aktivitet';

  @override
  String get newGroup => 'Ny grupp';

  @override
  String get joinWithCode => 'Gå med med en kod';

  @override
  String get filterAll => 'Alla';

  @override
  String get filterOwesMe => 'Skyldig mig';

  @override
  String get filterIOwe => 'Jag är skyldig';

  @override
  String settledUpCount(int count) {
    return 'Uppgjort ($count)';
  }

  @override
  String get nobodyOwesYou => 'Ingen är skyldig dig något';

  @override
  String get youOweNothing => 'Du är inte skyldig något';

  @override
  String get nothingHereYet => 'Inget här än';

  @override
  String get noFriendsYet => 'Inga vänner än';

  @override
  String get noFriendsHelp =>
      'Lägg till en vän för att dela utgifter utanför en grupp. Personer du delar en grupp med visas också här.';

  @override
  String get allSettledUpYou => 'Du är kvitt med alla';

  @override
  String youAreOwedList(String amounts) {
    return 'Du ska få $amounts';
  }

  @override
  String youOweList(String amounts) {
    return 'Du är skyldig $amounts';
  }

  @override
  String get notOnEvensiesLower => 'inte på Evensies än';

  @override
  String get noGroupsYet => 'Inga grupper än';

  @override
  String get noGroupsHelp =>
      'Skapa en för en resa eller ett boende, eller gå med i en väns grupp med inbjudningskoden.';

  @override
  String get createGroup => 'Skapa grupp';

  @override
  String get settledUp => 'Uppgjort';

  @override
  String netApprox(String amount) {
    return 'Netto ≈ $amount';
  }

  @override
  String memberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count medlemmar',
      one: '1 medlem',
    );
    return '$_temp0';
  }

  @override
  String youOweAmount(String amount) {
    return 'Du är skyldig $amount';
  }

  @override
  String youAreOwedAmount(String amount) {
    return 'Du ska få $amount';
  }

  @override
  String youOweAmountLine(String amount) {
    return 'du är skyldig $amount';
  }

  @override
  String youAreOwedAmountLine(String amount) {
    return 'du ska få $amount';
  }

  @override
  String get createGroupNeedsConnection =>
      'Du behöver en anslutning för att skapa en grupp.';

  @override
  String get groupName => 'Gruppnamn';

  @override
  String get yourNameInGroup => 'Ditt namn i den här gruppen';

  @override
  String get defaultCurrency => 'Standardvaluta';

  @override
  String get create => 'Skapa';

  @override
  String get noGroupOrFriendForCode =>
      'Ingen grupp eller vän hittades med den här koden';

  @override
  String get joinNeedsConnection =>
      'Du behöver en anslutning för att gå med i en grupp.';

  @override
  String get enterACode => 'Ange en kod';

  @override
  String get enterCodeHelp =>
      'En gruppkod finns i gruppen → Medlemmar. En vänkod finns under fliken Vänner → Lägg till en vän.';

  @override
  String get pastedFromClipboard => 'Inklistrat från urklipp';

  @override
  String nameOnEvensies(String name) {
    return '$name · på Evensies';
  }

  @override
  String addAsFriend(String name) {
    return 'Lägg till $name som vän';
  }

  @override
  String addedYouAsFriend(String name) {
    return '$name lade till dig som vän';
  }

  @override
  String get someoneAddedYouAsFriend => 'Någon lade till dig som vän';

  @override
  String groupPreview(String name, String members) {
    return '$name · $members';
  }

  @override
  String get continueButton => 'Fortsätt';

  @override
  String wantsToSplit(String name) {
    return '$name vill dela utgifter med dig';
  }

  @override
  String get joinGroup => 'Gå med i gruppen';

  @override
  String get inviteInvalid => 'Den här inbjudningslänken gäller inte längre';

  @override
  String inviteFailed(String reason) {
    return 'Kunde inte öppna inbjudan: $reason';
  }

  @override
  String get friendInviteUsed => 'Den här väninbjudan har redan använts';

  @override
  String get joinToSeeShared =>
      'Gå med för att se och lägga till era gemensamma utgifter.';

  @override
  String imName(String name) {
    return 'Jag är $name';
  }

  @override
  String get join => 'Gå med';

  @override
  String get whoAreYou => 'Vem är du?';

  @override
  String get newMemberName => 'Ny medlems namn';

  @override
  String get insights => 'Statistik';

  @override
  String get membersInvite => 'Medlemmar och inbjudan';

  @override
  String get groupSettings => 'Gruppinställningar';

  @override
  String get expenses => 'Utgifter';

  @override
  String get expenseFab => 'Utgift';

  @override
  String get groupNotHere => 'Den här gruppen finns inte på enheten';

  @override
  String get groupNotHereNote =>
      'Du har lämnat den, någon har tagit bort dig, eller så har den inte synkats än.';

  @override
  String get backToGroups => 'Tillbaka till grupper';

  @override
  String get noExpensesYet => 'Inga utgifter än';

  @override
  String get tapExpenseToAdd =>
      'Tryck på ”Utgift” för att lägga till den första.';

  @override
  String tilePaidYou(String amount) {
    return 'du betalade $amount';
  }

  @override
  String tilePaidName(String name, String amount) {
    return '$name betalade $amount';
  }

  @override
  String tilePaidPeople(int count, String amount) {
    return '$count personer betalade $amount';
  }

  @override
  String get tileRefundYou => 'återbetalning till dig';

  @override
  String tileRefundName(String name) {
    return 'återbetalning till $name';
  }

  @override
  String tileRefundPeople(int count) {
    return 'återbetalning till $count personer';
  }

  @override
  String get notInvolved => 'inte med';

  @override
  String get allYours => 'allt ditt';

  @override
  String get paidForYourself => 'du betalade för dig själv';

  @override
  String youGetBack(String amount) {
    return 'du får tillbaka $amount';
  }

  @override
  String youLent(String amount) {
    return 'du lånade ut $amount';
  }

  @override
  String youBorrowed(String amount) {
    return 'du lånade $amount';
  }

  @override
  String get repeatsLabel => 'Upprepas';

  @override
  String hasReceipt(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Har $count kvitton',
      one: 'Har ett kvitto',
    );
    return '$_temp0';
  }

  @override
  String get refund => 'Återbetalning';

  @override
  String get notConverted => 'Inte omräknad';

  @override
  String get pending => 'väntar';

  @override
  String approxTotalOwe(String amount) {
    return 'Du är skyldig ≈ $amount totalt';
  }

  @override
  String approxTotalOwed(String amount) {
    return 'Du ska få ≈ $amount totalt';
  }

  @override
  String get approxTotalNote => 'I din hemvaluta, efter de senaste kurserna';

  @override
  String nothingOwedIn(String currency) {
    return 'Inget skyldigt i $currency';
  }

  @override
  String get allSettled => 'Allt uppgjort';

  @override
  String get otherCurrenciesBelow => 'Utgifter i andra valutor finns nedan.';

  @override
  String get nobodyOwes => 'Ingen är skyldig något.';

  @override
  String youPayNext(String amount) {
    return 'Du borde betala nästa gång (du är skyldig $amount, mest)';
  }

  @override
  String namePaysNext(String name, String amount) {
    return '$name borde betala nästa gång (är skyldig $amount, mest)';
  }

  @override
  String settleUpWaiting(int count) {
    return 'Gör upp · $count väntar';
  }

  @override
  String memberRemoved(String name) {
    return '$name (borttagen)';
  }

  @override
  String expensesWithoutRate(int count, String currency) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count utgifter utan kurs till $currency',
      one: '1 utgift utan kurs till $currency',
    );
    return '$_temp0';
  }

  @override
  String expensesBadRate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count utgifter med en kurs som inte kan räknas om',
      one: '1 utgift med en kurs som inte kan räknas om',
    );
    return '$_temp0';
  }

  @override
  String paymentsIn(String currency) {
    return 'Betalningar i $currency';
  }

  @override
  String everyoneEvenIn(String currency) {
    return 'alla är kvitt i $currency';
  }

  @override
  String convertTo(String currency) {
    return 'Räkna om till $currency';
  }

  @override
  String get balanceSettled => 'uppgjort';

  @override
  String get balanceGetsBack => 'får tillbaka';

  @override
  String get balanceOwes => 'är skyldig';

  @override
  String convertedCount(int count, String currency) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count utgifter omräknade till $currency',
      one: '1 utgift omräknad till $currency',
    );
    return '$_temp0';
  }

  @override
  String get noAutoRate => 'Ingen automatisk kurs. Ange en.';

  @override
  String rateOf(String date) {
    return 'kurs från $date';
  }

  @override
  String rateOfOffline(String date) {
    return 'offline · kurs från $date';
  }

  @override
  String amountCountExpenses(String amount, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count utgifter',
      one: '1 utgift',
    );
    return '$amount · $_temp0';
  }

  @override
  String paymentsStayIn(String currency) {
    return 'Betalningar i $currency stannar i $currency';
  }

  @override
  String rateLabel(String from, String to) {
    return 'Kurs: 1 $from i $to';
  }

  @override
  String get nothingLeftToConvert => 'Inget kvar att räkna om';

  @override
  String get lookingUpRate => 'Hämtar kursen…';

  @override
  String get enterRateAbove0 => 'Ange en kurs över 0';

  @override
  String convertExplain(String currency) {
    return 'Fyller i den här kursen på varje utgift som saknar en, så att den räknas i saldona i $currency. Du kan fortfarande ändra kursen på varje utgift.';
  }

  @override
  String get nameField => 'Namn';

  @override
  String get cantChangeCurrency =>
      'Kan inte ändras efter den första utgiften eller betalningen';

  @override
  String get currencyUsedFor => 'Saldon och betalningar använder den';

  @override
  String get splitting => 'Uppdelning';

  @override
  String get simplifyDebts => 'Förenkla skulder';

  @override
  String get simplifyDebtsHelp =>
      'Slår ihop skulder så att gruppen behöver färre betalningar. Ingens totalsumma ändras, bara vem som betalar vem.';

  @override
  String get defaultSplit => 'Standarduppdelning';

  @override
  String get splitStale => 'Går inte ihop längre · tryck för att rätta';

  @override
  String get membership => 'Medlemskap';

  @override
  String get leaveGroup => 'Lämna gruppen';

  @override
  String get balanceSettledNote => 'Ditt saldo är uppgjort';

  @override
  String get renameGroup => 'Byt namn på gruppen';

  @override
  String leaveTitle(String name) {
    return 'Lämna ”$name”?';
  }

  @override
  String get leaveMessage =>
      'Du ser inte den här gruppen längre. Dina tidigare utgifter stannar hos de andra medlemmarna. Be om inbjudningskoden för att komma tillbaka.';

  @override
  String get leave => 'Lämna';

  @override
  String youLeft(String name) {
    return 'Du lämnade ”$name”';
  }

  @override
  String get splitEqualEveryone => 'Lika · alla';

  @override
  String splitPercentList(String list) {
    return 'Procent · $list';
  }

  @override
  String splitSharesList(String list) {
    return 'Andelar · $list';
  }

  @override
  String percentValue(String value) {
    return '$value %';
  }

  @override
  String get defaultSplitHelp =>
      'Nya utgifter börjar med den här uppdelningen. Du kan fortfarande ändra den på varje utgift.';

  @override
  String get useEqual => 'Använd lika';

  @override
  String get inviteCode => 'Inbjudningskod';

  @override
  String get inviteQrLabel => 'QR-kod för inbjudningslänken';

  @override
  String get inviteCodeHelp =>
      'Alla med den här koden kan gå med och välja sitt namn.';

  @override
  String inviteShareText(String group, String link, String code) {
    return 'Gå med i min grupp ”$group” på Evensies: $link\nEller öppna appen och ange koden $code';
  }

  @override
  String get rotateCode => 'Byt kod';

  @override
  String get members => 'Medlemmar';

  @override
  String get notJoinedYet => 'inte med än — dela inbjudningskoden';

  @override
  String get linked => 'länkad';

  @override
  String get addPlaceholder => 'Lägg till platshållarmedlem';

  @override
  String removeMemberTitle(String name) {
    return 'Ta bort $name?';
  }

  @override
  String get removeMemberMessage =>
      'Tidigare utgifter och saldot stannar i gruppen.';

  @override
  String removeMemberSeries(int count, String name, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$name är fortfarande med i $count återkommande utgifter ($names); andelen för $name finns kvar tills du redigerar den senaste.',
      one:
          '$name är fortfarande med i 1 återkommande utgift ($names); andelen för $name finns kvar tills du redigerar den senaste.',
    );
    return '$_temp0';
  }

  @override
  String get addMember => 'Lägg till medlem';

  @override
  String get rotateInviteTitle => 'Byta inbjudningskod?';

  @override
  String get rotateInviteMessage =>
      'Den nuvarande koden och länken slutar fungera. De som redan gått med påverkas inte.';

  @override
  String get rotate => 'Byt';

  @override
  String get newInviteReady => 'Ny inbjudningskod klar';

  @override
  String get activityNeedsConnection => 'Aktivitet kräver en anslutning';

  @override
  String get activityOfflineNote =>
      'Senaste ändringar visas här när du är online igen.';

  @override
  String get noActivityYet => 'Ingen aktivitet än';

  @override
  String get activityAllGroups => 'Ändringar i dina grupper visas här.';

  @override
  String get activityThisGroup => 'Ändringar i den här gruppen visas här.';

  @override
  String get showingSaved => 'Sparad aktivitet. Dra för att uppdatera.';

  @override
  String get loadMore => 'Läs in fler';

  @override
  String get earlier => 'Tidigare';

  @override
  String get today => 'I dag';

  @override
  String get yesterday => 'I går';

  @override
  String forDate(String date) {
    return 'för $date';
  }

  @override
  String get youCommented => 'Du kommenterade';

  @override
  String nameCommented(String name) {
    return '$name kommenterade';
  }

  @override
  String restoredName(String name) {
    return '”$name” återställd';
  }

  @override
  String get paymentRestored => 'Betalningen återställd';

  @override
  String get expenseNotHere => 'Den här utgiften finns inte på enheten';

  @override
  String get deletedExpense => 'Raderad utgift';

  @override
  String get expense => 'Utgift';

  @override
  String seriesRepeats(String frequency) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Upprepas varje vecka',
      'biweekly': 'Upprepas varannan vecka',
      'monthly': 'Upprepas varje månad',
      'yearly': 'Upprepas varje år',
      'other': 'Upprepas',
    });
    return '$_temp0';
  }

  @override
  String seriesRepeatsNext(String frequency, String date) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Upprepas varje vecka · nästa $date',
      'biweekly': 'Upprepas varannan vecka · nästa $date',
      'monthly': 'Upprepas varje månad · nästa $date',
      'yearly': 'Upprepas varje år · nästa $date',
      'other': 'Upprepas · nästa $date',
    });
    return '$_temp0';
  }

  @override
  String seriesRepeatsNextAmount(String frequency, String amount, String date) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Upprepas varje vecka · nästa $amount den $date',
      'biweekly': 'Upprepas varannan vecka · nästa $amount den $date',
      'monthly': 'Upprepas varje månad · nästa $amount den $date',
      'yearly': 'Upprepas varje år · nästa $amount den $date',
      'other': 'Upprepas · nästa $amount den $date',
    });
    return '$_temp0';
  }

  @override
  String rateLine(String from, String rate, String to) {
    return 'Kurs: 1 $from = $rate $to';
  }

  @override
  String notConvertedTo(String currency) {
    return 'Inte omräknad till $currency';
  }

  @override
  String get receivedSplitBack => 'Mottaget och uppdelat tillbaka';

  @override
  String get whoPaidOwes => 'Vem betalade och vem är skyldig';

  @override
  String get items => 'Poster';

  @override
  String get notes => 'Anteckningar';

  @override
  String get receipts => 'Kvitton';

  @override
  String get history => 'Historik';

  @override
  String get deleteExpenseTitle => 'Radera utgiften?';

  @override
  String get deleteExpenseMessage =>
      'Den tas bort för alla i gruppen. Du kan återställa den från Aktivitet.';

  @override
  String get deleteRepeatingTitle => 'Radera den återkommande utgiften?';

  @override
  String get deleteRepeatingMessage =>
      'Den tas bort för alla i gruppen. Du kan återställa den från Aktivitet, men en stoppad serie kan inte startas igen. Upprepningar som redan lagts till finns kvar.';

  @override
  String get deleteThisOne => 'Radera bara denna';

  @override
  String get deleteAndStop => 'Radera och sluta upprepa';

  @override
  String deletedAndStopped(String name) {
    return '”$name” raderad och upprepas inte längre';
  }

  @override
  String deletedName(String name) {
    return '”$name” raderad';
  }

  @override
  String get movedToOtherGroup => 'Flyttad till en annan grupp';

  @override
  String get movedNote =>
      'Den räknas där nu. Kommentarer och historik stannar här.';

  @override
  String get expenseWasDeleted => 'Den här utgiften raderades';

  @override
  String get restoreToCount =>
      'Återställ den så att den räknas i saldona igen.';

  @override
  String get tax => 'Skatt';

  @override
  String get tipService => 'Dricks eller service';

  @override
  String get discount => 'Rabatt';

  @override
  String youPaidOwe(String paid, String owe) {
    return 'Du betalade $paid och är skyldig $owe';
  }

  @override
  String youPaid(String amount) {
    return 'Du betalade $amount';
  }

  @override
  String youOwe(String amount) {
    return 'Du är skyldig $amount';
  }

  @override
  String namePaidOwes(String name, String paid, String owe) {
    return '$name betalade $paid och är skyldig $owe';
  }

  @override
  String namePaid(String name, String amount) {
    return '$name betalade $amount';
  }

  @override
  String nameOwes(String name, String amount) {
    return '$name är skyldig $amount';
  }

  @override
  String youReceivedGetBack(String received, String back) {
    return 'Du tog emot $received och får tillbaka $back';
  }

  @override
  String youReceived(String amount) {
    return 'Du tog emot $amount';
  }

  @override
  String youGetBackLine(String amount) {
    return 'Du får tillbaka $amount';
  }

  @override
  String nameReceivedGetsBack(String name, String received, String back) {
    return '$name tog emot $received och får tillbaka $back';
  }

  @override
  String nameReceived(String name, String amount) {
    return '$name tog emot $amount';
  }

  @override
  String nameGetsBack(String name, String amount) {
    return '$name får tillbaka $amount';
  }

  @override
  String get noHistoryYet => 'Ingen historik än.';

  @override
  String get historyOffline => 'Historiken visas här när du är online.';

  @override
  String get showingSavedHistory => 'Sparad historik.';

  @override
  String get showMore => 'Visa mer';

  @override
  String get deleteCommentTitle => 'Radera kommentaren?';

  @override
  String get comments => 'Kommentarer';

  @override
  String get noCommentsYet => 'Inga kommentarer än.';

  @override
  String get deleteComment => 'Radera kommentar';

  @override
  String get addComment => 'Skriv en kommentar';

  @override
  String get send => 'Skicka';

  @override
  String get filterByCategory => 'Filtrera efter kategori';

  @override
  String get category => 'Kategori';

  @override
  String get categoryAll => 'Alla';

  @override
  String get month => 'Månad';

  @override
  String get searchUnavailable => 'Sökning är inte tillgänglig';

  @override
  String get searchExpenses => 'Sök utgifter';

  @override
  String get searchHelp =>
      'Beskrivningar, anteckningar, kommentarer, kategorier och belopp: ”taxi”, ”flygplats”, ”12,50”.';

  @override
  String get noMatches => 'Inga träffar';

  @override
  String get noMatchesHelp => 'Prova ett annat ord eller ta bort ett filter.';

  @override
  String expenseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count utgifter',
      one: '1 utgift',
    );
    return '$_temp0';
  }

  @override
  String get searchAllGroups => 'Sök i alla grupper';

  @override
  String searchGroup(String name) {
    return 'Sök i $name';
  }

  @override
  String get searchThisGroup => 'Sök i den här gruppen';

  @override
  String get clear => 'Rensa';

  @override
  String get thisGroup => 'Den här gruppen';

  @override
  String insightsError(String reason) {
    return 'Statistiken kan inte visas: $reason';
  }

  @override
  String get nothingToShow => 'Inget att visa än';

  @override
  String get insightsEmptyHelp =>
      'Summor och diagram visas när gruppen har utgifter.';

  @override
  String get allTime => 'All tid';

  @override
  String get shareSummary => 'Dela sammanfattning';

  @override
  String get printSummary => 'Skriv ut sammanfattning';

  @override
  String get previousMonth => 'Föregående månad';

  @override
  String get nextMonth => 'Nästa månad';

  @override
  String get byMonth => 'Per månad';

  @override
  String get groupSegment => 'Grupp';

  @override
  String get mineSegment => 'Mina';

  @override
  String get byCategory => 'Per kategori';

  @override
  String get noExpensesPeriod => 'Inga utgifter under den här perioden.';

  @override
  String get byPerson => 'Per person';

  @override
  String get nobodyPaidPeriod =>
      'Ingen betalade eller var skyldig något under den här perioden.';

  @override
  String keptUntilConverted(String currency, String group) {
    return 'Stannar i $currency tills det räknas om till $group.';
  }

  @override
  String get totalSpent => 'Totalt spenderat';

  @override
  String get yourShare => 'Din andel';

  @override
  String get paymentsMade => 'Betalningar gjorda';

  @override
  String get paymentsReceived => 'Betalningar mottagna';

  @override
  String get youPaidRow => 'Du betalade';

  @override
  String get balanceChange => 'Förändring av ditt saldo';

  @override
  String get paidLegend => 'Betalat';

  @override
  String get shareLegend => 'Andel';

  @override
  String paidShareLine(String paid, String share) {
    return 'betalade $paid · andel $share';
  }

  @override
  String get itemsGiveEveryone => 'Ge varje post en person';

  @override
  String get itemsAddPrices => 'Fyll i priserna före skatt eller dricks';

  @override
  String get itemsDiscountTooBig => 'Rabatten är större än notan';

  @override
  String get itemsDontAddUp => 'Posterna går inte ihop';

  @override
  String get adjustmentsDontFit => 'Justeringarna ryms inte i summan';

  @override
  String get giveSomeoneShare => 'Ge någon en andel';

  @override
  String get checkNumbers => 'Kontrollera siffrorna';

  @override
  String get splitDoesntAddUp => 'Uppdelningen går inte ihop';

  @override
  String get addTheItems => 'Lägg till posterna';

  @override
  String get pickOnePerson => 'Välj minst en person';

  @override
  String splitEquallyBetween(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delas lika på $count personer',
      one: 'Delas lika på 1 person',
    );
    return '$_temp0';
  }

  @override
  String get allForOnePerson => 'Allt för 1 person';

  @override
  String splitEquallyEach(int count, String amount) {
    return 'Delas lika på $count personer · $amount var';
  }

  @override
  String get checkAmounts => 'Kontrollera beloppen';

  @override
  String get enterTotalFirst => 'Ange summan först';

  @override
  String remaining(String amount) {
    return 'kvar: $amount';
  }

  @override
  String overBy(String amount) {
    return 'över med: $amount';
  }

  @override
  String get addsUp => 'Går ihop';

  @override
  String sharesInTotal(String count) {
    return '$count andelar totalt';
  }

  @override
  String get oneShareInTotal => '1 andel totalt';

  @override
  String get restSplitEqually => 'Resten delas lika';

  @override
  String get byPercent => 'Efter procent';

  @override
  String get byShares => 'Efter andelar';

  @override
  String get byAdjustment => 'Justera: mer eller mindre för någon, resten lika';

  @override
  String get modeEqual => 'Lika';

  @override
  String get modeExact => 'Exakt';

  @override
  String get modeShares => 'Andelar';

  @override
  String get byItem => 'Per post, från ett kvitto';

  @override
  String get adjustmentHelp =>
      'Lägg till eller dra av ett belopp för någon; resten delas lika.';

  @override
  String get noMembers => 'Inga medlemmar';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count poster',
      one: '1 post',
    );
    return '$_temp0';
  }

  @override
  String get addAnItem => 'Lägg till en post';

  @override
  String atMostItems(int max) {
    return 'Högst $max poster';
  }

  @override
  String get giveItemName => 'Ge varje post ett namn';

  @override
  String get itemNameTooLong => 'Ett postnamn är för långt';

  @override
  String get addItem => 'Lägg till post';

  @override
  String get giveRestToEveryone => 'Ge resten till alla';

  @override
  String get subtotal => 'Delsumma';

  @override
  String get total => 'Summa';

  @override
  String receiptSays(String printed, String difference) {
    return 'Kvittot säger $printed · posterna skiljer sig med $difference';
  }

  @override
  String get eachPerson => 'Per person';

  @override
  String itemsWithoutPerson(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count poster utan person',
      one: '1 post utan person',
    );
    return '$_temp0';
  }

  @override
  String get itemHint => 'Post';

  @override
  String memberLeft(String name) {
    return '$name (har lämnat)';
  }

  @override
  String get whoHadThis => 'Vem tog det här?';

  @override
  String get defaultSplitStartsEqual =>
      'Gruppens standarduppdelning går inte ihop längre, så den här börjar lika';

  @override
  String leftToAssign(String amount) {
    return '$amount kvar att fördela';
  }

  @override
  String get itemsTotal => 'Summan av posterna';

  @override
  String get newExpense => 'Ny utgift';

  @override
  String get editExpense => 'Redigera utgift';

  @override
  String get scanReceipt => 'Skanna kvitto';

  @override
  String get rateAboveZeroOrEmpty => 'Ange en kurs över 0, eller lämna tomt';

  @override
  String useAutoRate(String rate, String source) {
    return 'Använd automatisk kurs: $rate ($source)';
  }

  @override
  String get description => 'Beskrivning';

  @override
  String get receivedBy => 'Mottaget av';

  @override
  String get paidBy => 'Betalat av';

  @override
  String get severalPeople => 'Flera personer';

  @override
  String get when => 'När';

  @override
  String get refundTooltip =>
      'Pengar som kom tillbaka, t.ex. depositionen från hotellet';

  @override
  String get splitBackTo => 'Uppdelat tillbaka till';

  @override
  String get split => 'Uppdelning';

  @override
  String theyOweFull(String name) {
    return '$name är skyldig hela beloppet';
  }

  @override
  String iOweFull(String name) {
    return 'Jag är skyldig $name hela beloppet';
  }

  @override
  String get repeat => 'Upprepa';

  @override
  String editLatestRepeat(String date) {
    return 'Redigera den senaste ($date) för att ändra kommande upprepningar';
  }

  @override
  String get stopsRepeating =>
      'Slutar upprepas. Upprepningar som redan lagts till finns kvar.';

  @override
  String nextRepeat(String date) {
    return 'Nästa: $date';
  }

  @override
  String get alsoChangeFuture => 'Ändra även kommande upprepningar';

  @override
  String get futureFields =>
      'Belopp, uppdelning, betalare, beskrivning, kategori och anteckningar';

  @override
  String get onlyThisOne => 'Bara denna ändras';

  @override
  String get addPhoto => 'Lägg till bild';

  @override
  String maxReceiptsNote(int max) {
    return '$max kvitton är max för en utgift';
  }

  @override
  String get scanAReceipt => 'Skanna ett kvitto';

  @override
  String receiptLooksLike(String currency) {
    return 'Det här kvittot ser ut att vara i $currency';
  }

  @override
  String switchToCurrencyQuestion(String currency) {
    return 'Byta utgiften till $currency för att läsa posterna?';
  }

  @override
  String switchTo(String currency) {
    return 'Byt till $currency';
  }

  @override
  String get couldntReadItems => 'Kunde inte läsa posterna. Skriv in dem.';

  @override
  String withName(String name) {
    return 'Med $name';
  }

  @override
  String movesTo(String name) {
    return 'Flyttas till $name när du sparar';
  }

  @override
  String fromName(String name) {
    return 'Från $name';
  }

  @override
  String get dontMove => 'Flytta inte';

  @override
  String get onlyLinkedMove =>
      'Bara personer på Evensies som finns i båda kan flyttas';

  @override
  String get auto => 'auto';

  @override
  String get noAutoRateForm =>
      'Ingen automatisk kurs. Ange en, eller lämna tomt för att ha kvar den under ”Inte omräknat”.';

  @override
  String get emptyNotConverted => 'Tomt: den stannar under ”Inte omräknat”';

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
  String get yourRate => 'din kurs';

  @override
  String get loginEmail => 'Fortsätt med e-post';

  @override
  String get emailLoginTitle => 'Logga in med e-post';

  @override
  String get emailLoginIntro =>
      'Vi mejlar dig en sexsiffrig kod. Inget lösenord behövs.';

  @override
  String get emailLabel => 'E-post';

  @override
  String get emailInvalid => 'Ange en giltig e-postadress';

  @override
  String get sendCode => 'Skicka kod';

  @override
  String codeSentTo(String email) {
    return 'Ange den sexsiffriga koden vi skickade till $email. Den gäller i 10 minuter.';
  }

  @override
  String get codeLabel => 'Sexsiffrig kod';

  @override
  String get verifyCode => 'Fortsätt';

  @override
  String get resendCode => 'Skicka koden igen';

  @override
  String resendCodeIn(int seconds) {
    return 'Skicka igen om $seconds s';
  }

  @override
  String get codeResent => 'Vi har skickat en ny kod.';

  @override
  String get useDifferentEmail => 'Använd en annan e-postadress';

  @override
  String get codeCheckSpam => 'Kom inget? Titta i skräpposten.';

  @override
  String get errorCodeInvalid => 'Koden är fel eller har gått ut. Be om en ny.';

  @override
  String get errorEmailNotConfigured => 'Den här servern skickar inte e-post.';

  @override
  String get errorEmailRejected =>
      'Den adressen kan inte ta emot e-post. Kolla att den är rätt stavad.';

  @override
  String get errorEmailTaken =>
      'Ett annat konto använder redan den här adressen.';

  @override
  String get errorEmailRequired =>
      'E-posten är ditt enda sätt att logga in, så den kan inte tas bort.';

  @override
  String get errorEmailUnavailable =>
      'E-post fungerar inte just nu. Försök igen senare.';

  @override
  String get emailSaved => 'E-post sparad';

  @override
  String removeEmailTitle(String email) {
    return 'Ta bort $email?';
  }

  @override
  String get removeEmailMessage =>
      'Du får inga sammanfattningar eller påminnelser via e-post längre och kan inte logga in med den.';

  @override
  String get emailRemoved => 'E-post borttagen';

  @override
  String get emailNeedsConnection =>
      'Du behöver en anslutning för att byta e-post.';

  @override
  String get emailBouncedNote =>
      'E-post till den här adressen studsar — byt den eller verifiera den igen';

  @override
  String get emailVerifiedNote => 'Verifierad · andra medlemmar ser den aldrig';

  @override
  String get changeEmail => 'Byt e-post';

  @override
  String get emailAccountHelp =>
      'För inloggning och sammanfattningar via e-post. Vi skickar en kod för att kontrollera att den är din. Andra medlemmar ser den aldrig.';

  @override
  String get removeEmail => 'Ta bort e-post';

  @override
  String get addEmail => 'Lägg till e-post';

  @override
  String get addEmailHint =>
      'Logga in med den och få sammanfattningar via e-post';

  @override
  String unblockedName(String name) {
    return '$name är inte längre blockerad';
  }

  @override
  String get blockNeedsConnection =>
      'Du behöver en anslutning för att blockera.';

  @override
  String get blockedEmpty => 'Du har inte blockerat någon.';

  @override
  String get blockedNeedsConnection =>
      'Blockerade personer kräver en anslutning';

  @override
  String get unblock => 'Avblockera';

  @override
  String get blockedPeople => 'Blockerade personer';

  @override
  String get blockedHelp =>
      'Blockerade personer kan inte lägga till dig som vän eller skicka påminnelser, och deras ändringar ger dig inga aviseringar eller mejl. Gemensamma grupper och saldon är kvar som de är.';

  @override
  String get deletedGroupsEmpty => 'Inga raderade grupper';

  @override
  String get deletedGroupsHelp =>
      'En återställd grupp kommer tillbaka för alla, med allt innehåll.';

  @override
  String get deletedGroups => 'Raderade grupper';

  @override
  String deletedGroupsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count grupper kan återställas',
      one: '1 grupp kan återställas',
    );
    return '$_temp0';
  }

  @override
  String get exportNeedsConnection =>
      'Du behöver en anslutning för att exportera.';

  @override
  String get exportEverything => 'Exportera allt (JSON)';

  @override
  String get exportEverythingHint =>
      'Din profil, sätt att få betalt, inställningar och alla grupper, även raderade';

  @override
  String get emailSummary => 'Sammanfattning via e-post';

  @override
  String digestChoice(String choice) {
    String _temp0 = intl.Intl.selectLogic(choice, {
      'auto': 'Automatisk',
      'daily': 'Varje dag',
      'weekly': 'Varje vecka',
      'monthly': 'Varje månad',
      'off': 'Av',
      'other': 'Automatisk',
    });
    return '$_temp0';
  }

  @override
  String get digestAutoHelp =>
      'Varje dag om dina enheter inte kan visa aviseringar, annars varje månad';

  @override
  String get digestAutoDaily =>
      'Automatisk — varje dag, eftersom aviseringar är avstängda';

  @override
  String get digestAutoMonthly =>
      'Automatisk — varje månad, eftersom dina enheter får aviseringar';

  @override
  String get digestNoEmail =>
      'Lägg till e-post under Konto för att få sammanfattningar';

  @override
  String get helpReportProblem => 'Rapportera ett problem eller föreslå något';

  @override
  String get helpReportProblemHint => 'På GitHub, där alla kan se det';

  @override
  String get helpContact => 'Mejla supporten';

  @override
  String get privacyPolicy => 'Integritetspolicy';

  @override
  String get helpFeedback => 'Hjälp och feedback';

  @override
  String get signOutEverywhere => 'Logga ut på alla enheter';

  @override
  String get signOutEverywhereTitle => 'Logga ut på alla enheter?';

  @override
  String get signOutEverywhereMessage =>
      'Alla telefoner och webbläsare med ditt konto loggas ut, även den här. Dina grupper finns kvar på servern.';

  @override
  String get signOutEverywhereOffline =>
      'Du behöver en anslutning för att logga ut på alla enheter.';

  @override
  String get deleteAccountExportTip => 'Tips: Exportera allt först.';

  @override
  String get coverPhoto => 'Omslagsbild';

  @override
  String get coverPhotoHint =>
      'Visas överst i gruppen och i listan. Bara medlemmar ser den.';

  @override
  String get removeCover => 'Ta bort omslag';

  @override
  String get coverNeedsConnection =>
      'Du behöver en anslutning för att byta omslag.';

  @override
  String get coverTooMany =>
      'Det är många omslagsbyten. Försök igen om en timme.';

  @override
  String get deleteGroup => 'Radera gruppen';

  @override
  String get deleteGroupHint =>
      'För alla · vilken medlem som helst kan återställa den';

  @override
  String deleteGroupTitle(String name) {
    return 'Radera ”$name”?';
  }

  @override
  String get deleteGroupMessage =>
      'Raderas för alla. Vilken medlem som helst kan återställa den under Inställningar → Raderade grupper.';

  @override
  String groupDeletedName(String name) {
    return '”$name” raderad';
  }

  @override
  String get groupDeletedBanner => 'Den här gruppen är raderad';

  @override
  String get groupRestored => 'Gruppen återställd';

  @override
  String get deleteFriend => 'Radera vän';

  @override
  String deleteFriendTitle(String name) {
    return 'Radera $name?';
  }

  @override
  String deleteFriendMessage(String name) {
    return 'Era utgifter utan grupp med $name raderas för er båda. Gemensamma grupper finns kvar. Du kan återställa dem under Inställningar → Raderade grupper, eller genom att lägga till $name igen.';
  }

  @override
  String friendDeleted(String name) {
    return '$name raderad';
  }

  @override
  String get block => 'Blockera';

  @override
  String blockTitle(String name) {
    return 'Blockera $name?';
  }

  @override
  String blockMessage(String name) {
    return '$name kan inte lägga till dig som vän eller skicka påminnelser, och ändringar från $name ger dig inga aviseringar eller mejl. Gemensamma grupper och saldon finns kvar.';
  }

  @override
  String blockedName(String name) {
    return '$name blockerad';
  }

  @override
  String get report => 'Anmäl…';

  @override
  String get reportSubject => 'Anmälan i Evensies';

  @override
  String reportBody(String userId) {
    return 'Användar-ID: $userId\n\nVad som hände:\n';
  }

  @override
  String get inviteByEmail => 'Bjud in via e-post…';

  @override
  String get inviteEmailField => 'E-post (valfritt)';

  @override
  String get inviteEmailHelp =>
      'Vi mejlar en inbjudningslänk. Används bara för den här inbjudan.';

  @override
  String inviteByEmailTitle(String name) {
    return 'Bjud in $name via e-post';
  }

  @override
  String inviteEmailSent(String email) {
    return 'Inbjudan skickad till $email';
  }

  @override
  String get inviteEmailOfflineAdded =>
      'Medlem tillagd. Att bjuda in via e-post kräver en anslutning — försök igen från medlemslistan.';

  @override
  String get inviteEmailOffline =>
      'Du behöver en anslutning för att bjuda in via e-post.';

  @override
  String get inviteEmailLimit =>
      'Dagens gräns för e-post är nådd — dela länken i stället.';

  @override
  String emailReminder(String choice) {
    return 'Påminnelse via e-post: $choice';
  }

  @override
  String get remindNever => 'Aldrig';

  @override
  String remindDaysBefore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dagar innan',
      one: '1 dag innan',
    );
    return '$_temp0';
  }

  @override
  String get blurbUpi =>
      'Indien: Paytm, PhonePe, Google Pay och andra UPI-appar';

  @override
  String get fieldUpi => 'UPI-ID';

  @override
  String get fieldUpiHint => 'Till exempel namn@okicici';

  @override
  String get fieldUpiName => 'Namn (valfritt)';

  @override
  String get fieldUpiNameHint => 'Visas för den som betalar dig';

  @override
  String get methodErrorUpi => 'Ange ett UPI-ID som namn@bank';

  @override
  String get noUpiApp =>
      'Ingen UPI-app hittades. Kopiera UPI-ID och belopp i stället.';

  @override
  String get upiIdLabel => 'UPI-ID';

  @override
  String get copyUpiId => 'Kopiera UPI-ID';

  @override
  String get upiIdCopied => 'UPI-ID kopierat';

  @override
  String get dashboard => 'Översikt';

  @override
  String get allExpenses => 'Alla utgifter';

  @override
  String get groupBalances => 'Gruppens saldon';

  @override
  String get yourBalance => 'Ditt saldo';

  @override
  String get dashboardOwesYou => 'Är skyldiga dig';

  @override
  String get dashboardYouOwe => 'Du är skyldig';

  @override
  String get historyAndComments => 'Historik och kommentarer';

  @override
  String get showEarlier => 'Visa tidigare';

  @override
  String get settleUpFirst => 'Gör upp först';

  @override
  String deleteFriendSettleFirst(String name) {
    return 'Du kan radera $name som vän när era utgifter utanför grupper är uppgjorda.';
  }

  @override
  String get noMailApp =>
      'Ingen e-postapp hittades. Kopiera uppgifterna nedan och skriv från valfri e-postapp.';

  @override
  String get copyAddress => 'Kopiera adress';

  @override
  String get copyMessage => 'Kopiera meddelande';

  @override
  String get browserNoStorage =>
      'Den här webbläsaren kan inte spara Evensies data. Prova en annan webbläsare eller ett fönster som inte är privat.';

  @override
  String get browserOtherTab =>
      'Evensies är redan öppet i en annan flik i den här webbläsaren. Använd den fliken, eller stäng den och ladda om den här.';

  @override
  String get loginReview => 'Demoinloggning';

  @override
  String get loginReviewUsername => 'Användarnamn';

  @override
  String get loginReviewPassword => 'Lösenord';

  @override
  String get loginReviewSubmit => 'Logga in';

  @override
  String get loginReviewWrong => 'Fel användarnamn eller lösenord';
}
