// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'Evensies';

  @override
  String get cancel => 'Annuleren';

  @override
  String get delete => 'Verwijderen';

  @override
  String get remove => 'Weghalen';

  @override
  String get save => 'Opslaan';

  @override
  String get done => 'Klaar';

  @override
  String get undo => 'Ongedaan maken';

  @override
  String get retry => 'Opnieuw proberen';

  @override
  String get ok => 'OK';

  @override
  String get close => 'Sluiten';

  @override
  String get edit => 'Bewerken';

  @override
  String get add => 'Toevoegen';

  @override
  String get offlineBanner =>
      'Offline — wijzigingen worden later gesynchroniseerd';

  @override
  String get tooLong => 'Te lang';

  @override
  String get allCurrencies => 'Alle valuta';

  @override
  String get errorUnexpected => 'Er ging iets mis. Probeer het opnieuw.';

  @override
  String get errorNetwork => 'Je bent offline. Probeer het later opnieuw.';

  @override
  String get errorRateLimited =>
      'Te veel pogingen. Wacht een minuut en probeer het opnieuw.';

  @override
  String get errorNotFound => 'Dat bestaat niet meer.';

  @override
  String get errorForbidden => 'Dat mag je niet doen.';

  @override
  String get errorValidation => 'De server heeft het geweigerd.';

  @override
  String get errorSumMismatch => 'De verdeling klopt niet.';

  @override
  String get errorPayersSumMismatch => 'De betalers kloppen niet.';

  @override
  String get errorNegativeAmount => 'Een bedrag is lager dan nul.';

  @override
  String get errorNegativeShare => 'Iemands deel zou lager dan nul worden.';

  @override
  String get errorNegativeTotal => 'Het totaal zou lager dan nul worden.';

  @override
  String get errorZeroSubtotal =>
      'Vul de prijzen van de items in vóór btw, fooi of korting.';

  @override
  String get errorUnassignedItem =>
      'Elk item heeft minstens één persoon nodig.';

  @override
  String get errorNoMembers => 'Kies minstens één persoon om mee te delen.';

  @override
  String get errorInvalidInput => 'Controleer de getallen.';

  @override
  String get errorBadRate => 'De wisselkoers moet boven nul liggen.';

  @override
  String get errorUnknownMember =>
      'Het gaat om iemand die niet in de groep zit.';

  @override
  String get errorUnknownCurrency => 'Deze valuta wordt niet ondersteund.';

  @override
  String get errorMemberTaken => 'Dat lid is al gekozen.';

  @override
  String get errorLimitExceeded => 'De limiet is bereikt.';

  @override
  String get errorTooLarge => 'De foto is te groot.';

  @override
  String get errorNotJpeg => 'Kies een JPEG-foto';

  @override
  String get errorFxUnavailable => 'Wisselkoersen zijn nu niet beschikbaar.';

  @override
  String get errorImportFailed => 'Dat bestand kon niet worden geïmporteerd.';

  @override
  String get errorAuthNotConfigured =>
      'Deze server kan je niet op die manier aanmelden.';

  @override
  String get errorDuplicate => 'Dat bestaat al.';

  @override
  String errorGeneric(String code) {
    return 'Er ging iets mis ($code).';
  }

  @override
  String rejectedReceipt(String name, String reason) {
    return 'Kon de bon bij “$name” niet opslaan: $reason';
  }

  @override
  String rejectedReceiptUnnamed(String reason) {
    return 'Kon de bon bij een uitgave niet opslaan: $reason';
  }

  @override
  String rejectedReceiptRemove(String name, String reason) {
    return 'Kon het weghalen van een bon bij “$name” niet opslaan: $reason';
  }

  @override
  String rejectedReceiptRemoveUnnamed(String reason) {
    return 'Kon het weghalen van een bon bij een uitgave niet opslaan: $reason';
  }

  @override
  String rejectedRepeating(String name, String reason) {
    return 'Kon het herhalen van “$name” niet opslaan: $reason';
  }

  @override
  String rejectedRepeatingUnnamed(String reason) {
    return 'Kon een terugkerende uitgave niet opslaan: $reason';
  }

  @override
  String rejectedSeriesChange(String name, String reason) {
    return 'Kon een wijziging aan toekomstige “$name” niet opslaan: $reason';
  }

  @override
  String rejectedSeriesChangeUnnamed(String reason) {
    return 'Kon een wijziging aan een terugkerende uitgave niet opslaan: $reason';
  }

  @override
  String rejectedSeriesStop(String name, String reason) {
    return 'Kon het stoppen van “$name” niet opslaan: $reason';
  }

  @override
  String rejectedSeriesStopUnnamed(String reason) {
    return 'Kon het stoppen van een terugkerende uitgave niet opslaan: $reason';
  }

  @override
  String rejectedSavedNoRepeat(String name, String reason) {
    return '“$name” is opgeslagen maar herhaalt niet: $reason';
  }

  @override
  String rejectedPaymentRestore(String reason) {
    return 'Kon het herstellen van een betaling niet opslaan: $reason';
  }

  @override
  String rejectedNewExpense(String name, String reason) {
    return 'Kon de nieuwe uitgave “$name” niet opslaan: $reason';
  }

  @override
  String rejectedNewExpenseUnnamed(String reason) {
    return 'Kon een nieuwe uitgave niet opslaan: $reason';
  }

  @override
  String rejectedExpenseChange(String name, String reason) {
    return 'Kon een wijziging aan “$name” niet opslaan: $reason';
  }

  @override
  String rejectedExpenseChangeUnnamed(String reason) {
    return 'Kon een wijziging aan een uitgave niet opslaan: $reason';
  }

  @override
  String rejectedExpenseDelete(String name, String reason) {
    return 'Kon het verwijderen van “$name” niet opslaan: $reason';
  }

  @override
  String rejectedExpenseDeleteUnnamed(String reason) {
    return 'Kon het verwijderen van een uitgave niet opslaan: $reason';
  }

  @override
  String rejectedExpenseRestore(String name, String reason) {
    return 'Kon het herstellen van “$name” niet opslaan: $reason';
  }

  @override
  String rejectedExpenseRestoreUnnamed(String reason) {
    return 'Kon het herstellen van een uitgave niet opslaan: $reason';
  }

  @override
  String rejectedComment(String name, String reason) {
    return 'Kon een reactie op “$name” niet opslaan: $reason';
  }

  @override
  String rejectedCommentUnnamed(String reason) {
    return 'Kon een reactie op een uitgave niet opslaan: $reason';
  }

  @override
  String rejectedPaymentComment(String reason) {
    return 'Kon een reactie op een betaling niet opslaan: $reason';
  }

  @override
  String rejectedCommentDelete(String reason) {
    return 'Kon het verwijderen van een reactie niet opslaan: $reason';
  }

  @override
  String rejectedPayment(String reason) {
    return 'Kon een betaling niet opslaan: $reason';
  }

  @override
  String rejectedPaymentDelete(String reason) {
    return 'Kon het verwijderen van een betaling niet opslaan: $reason';
  }

  @override
  String rejectedPaymentConfirm(String reason) {
    return 'Kon het bevestigen van een betaling niet opslaan: $reason';
  }

  @override
  String rejectedGroupSettings(String reason) {
    return 'Kon een wijziging van de groepsinstellingen niet opslaan: $reason';
  }

  @override
  String rejectedMemberAdd(String name, String reason) {
    return 'Kon het toevoegen van $name niet opslaan: $reason';
  }

  @override
  String rejectedMemberAddUnnamed(String reason) {
    return 'Kon het toevoegen van een lid niet opslaan: $reason';
  }

  @override
  String rejectedMemberRemove(String reason) {
    return 'Kon het weghalen van een lid niet opslaan: $reason';
  }

  @override
  String rejectedOther(String reason) {
    return 'Kon een wijziging niet opslaan: $reason';
  }

  @override
  String get reasonReceiptLimit => 'een uitgave kan hoogstens 10 bonnen hebben';

  @override
  String get reasonSeriesLimit =>
      'een groep kan hoogstens 100 terugkerende uitgaven hebben';

  @override
  String get reasonNotUploaded => 'de foto is niet geüpload';

  @override
  String get reasonSumMismatch => 'de verdeling klopt niet';

  @override
  String get reasonPayersSumMismatch => 'de betalers kloppen niet';

  @override
  String get reasonNegativeAmount => 'een bedrag is lager dan nul';

  @override
  String get reasonUnknownMember =>
      'het gaat om iemand die niet in de groep zit';

  @override
  String get reasonUnknownCurrency => 'deze valuta wordt niet ondersteund';

  @override
  String get reasonMemberTaken => 'dat lid is al gekozen';

  @override
  String get reasonGroupFull => 'de groep is vol';

  @override
  String get reasonForbidden => 'je mag die wijziging niet maken';

  @override
  String get reasonRefused => 'de server heeft het geweigerd';

  @override
  String leaveOwe(String amount) {
    return 'Je bent $amount schuldig · reken eerst af';
  }

  @override
  String leaveOweIn(String amount, String currency) {
    return 'Je bent $amount schuldig · reken eerst af in $currency';
  }

  @override
  String leaveOwed(String amount) {
    return 'Je krijgt nog $amount · reken eerst af';
  }

  @override
  String leaveOwedIn(String amount, String currency) {
    return 'Je krijgt nog $amount · reken eerst af in $currency';
  }

  @override
  String leaveSeries(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Je zit nog in $count terugkerende uitgaven ($names) · bewerk de nieuwste of stop ze eerst',
      one:
          'Je zit nog in 1 terugkerende uitgave ($names) · bewerk de nieuwste of stop hem eerst',
    );
    return '$_temp0';
  }

  @override
  String seriesNamesMore(String names, int count) {
    return '$names en nog $count';
  }

  @override
  String get seriesUnnamed => 'een uitgave';

  @override
  String get listJoiner => ', ';

  @override
  String get repeatNever => 'Nooit';

  @override
  String get repeatWeekly => 'Elke week';

  @override
  String get repeatBiweekly => 'Elke 2 weken';

  @override
  String get repeatMonthly => 'Elke maand';

  @override
  String get repeatYearly => 'Elk jaar';

  @override
  String summaryNotConverted(String currency) {
    return 'Niet omgerekend · $currency';
  }

  @override
  String summaryTotalSpent(String amount) {
    return 'Totaal uitgegeven: $amount';
  }

  @override
  String summaryPaidShare(String paid, String share) {
    return 'Jij betaalde: $paid · Jouw deel: $share';
  }

  @override
  String summaryPayments(String made, String received) {
    return 'Betalingen gedaan: $made · ontvangen: $received';
  }

  @override
  String summaryTopCategories(String list) {
    return 'Topcategorieën: $list';
  }

  @override
  String get summaryBalancesToday => 'Saldi vandaag';

  @override
  String summaryGetsBack(String name, String amount) {
    return '$name krijgt $amount terug';
  }

  @override
  String summaryOwes(String name, String amount) {
    return '$name is $amount schuldig';
  }

  @override
  String get summaryFooter => 'Gedeeld vanuit Evensies';

  @override
  String get koreanBank => 'Koreaanse bankrekening';

  @override
  String requestText(String amount, String group) {
    return 'Je bent me $amount schuldig voor $group op Evensies.';
  }

  @override
  String requestTextWays(String amount, String group, String ways) {
    return 'Je bent me $amount schuldig voor $group op Evensies. Betaal met: $ways';
  }

  @override
  String get requestNoGroup => 'onze gedeelde uitgaven';

  @override
  String get leaveSyncing =>
      'Nog aan het synchroniseren. Probeer het zo opnieuw.';

  @override
  String get leaveOffline => 'Je moet online zijn om te vertrekken';

  @override
  String get moveOffline =>
      'Verplaatsen mislukt. Probeer het opnieuw als je online bent';

  @override
  String moveFailed(String reason) {
    return 'Verplaatsen mislukt: $reason';
  }

  @override
  String get photoNoAccess =>
      'Evensies heeft geen toegang. Sta het toe in de app Instellingen.';

  @override
  String get photoNoCamera => 'Kon de camera niet openen.';

  @override
  String get photoNoLibrary => 'Kon de fotobibliotheek niet openen.';

  @override
  String get photoUnusable =>
      'Die foto kon niet worden gebruikt. Probeer een andere.';

  @override
  String get methodErrorUsername => 'Alleen letters, cijfers, . _ - (max. 40)';

  @override
  String methodErrorLinkPrefix(String prefix) {
    return 'Moet beginnen met $prefix';
  }

  @override
  String get methodErrorTooLong => 'Max. 200 tekens';

  @override
  String get methodErrorIban => 'Geen geldige IBAN';

  @override
  String get methodErrorHolder => 'Naam rekeninghouder (1–70 tekens)';

  @override
  String get methodErrorBic => 'BIC heeft 8 of 11 tekens';

  @override
  String get methodErrorKrAccount => 'Cijfers en streepjes, 8–20 cijfers';

  @override
  String get methodErrorBank => 'Naam van de bank (1–30 tekens)';

  @override
  String get methodErrorUnknownType => 'Onbekend type';

  @override
  String get methodErrorTooMany =>
      'Hoogstens 8 manieren om betaald te worden, en 3 van elk banktype';

  @override
  String get bannerDismiss => 'Sluiten';

  @override
  String get bannerView => 'Bekijken';

  @override
  String get loginTagline =>
      'Deel uitgaven met vrienden. Geen advertenties, geen upsells.';

  @override
  String get loginApple => 'Doorgaan met Apple';

  @override
  String get loginGoogle => 'Doorgaan met Google';

  @override
  String get loginWebUnavailable =>
      'Deze server heeft nog geen aanmelding in de browser.';

  @override
  String get welcomeTitle => 'Welkom';

  @override
  String get yourNameTitle => 'Je naam';

  @override
  String get nameQuestion => 'Hoe moeten je vrienden je noemen?';

  @override
  String get nameExplain => 'Dit is de naam die andere leden zien.';

  @override
  String get nameHelp =>
      'Mensen in je groepen zien hem. Je kunt hem later wijzigen in Instellingen.';

  @override
  String get nameLabel => 'Naam';

  @override
  String get lockReason => 'Evensies ontgrendelen';

  @override
  String get lockTitle => 'Evensies is vergrendeld';

  @override
  String get lockSubtitle =>
      'Ontgrendel met Face ID, Touch ID, je vingerafdruk of de toegangscode.';

  @override
  String get lockUnlock => 'Ontgrendelen';

  @override
  String get lockSignOutConfirm =>
      'Afmelden en de gegevens op dit apparaat wissen? Je groepen blijven op de server.';

  @override
  String get signOut => 'Afmelden';

  @override
  String get widgetOwed => 'Je krijgt';

  @override
  String get widgetOwe => 'Je bent schuldig';

  @override
  String get widgetSignedOut => 'Meld je aan om je saldo te zien';

  @override
  String get widgetSettled => 'Alles verrekend';

  @override
  String widgetUpdated(String time) {
    return 'Bijgewerkt $time';
  }

  @override
  String get receiptAdd => 'Bon toevoegen';

  @override
  String get photoTake => 'Foto maken';

  @override
  String get photoChoose => 'Kies uit bibliotheek';

  @override
  String get photoChooseFile => 'Kies een bestand';

  @override
  String get availableWhenOnline => 'Beschikbaar als je online bent';

  @override
  String get receiptPhoto => 'Foto van de bon';

  @override
  String get receiptAvailableOnline =>
      'De foto is beschikbaar als je online bent';

  @override
  String get receiptRemoveTitle => 'Bon weghalen?';

  @override
  String get receiptRemoveMessage =>
      'Hij wordt voor iedereen in de groep weggehaald.';

  @override
  String get receiptTitle => 'Bon';

  @override
  String receiptTitleOf(int index, int count) {
    return 'Bon $index van $count';
  }

  @override
  String get shareOrSave => 'Delen of bewaren';

  @override
  String get share => 'Delen';

  @override
  String get copiedToClipboard => 'Gekopieerd naar het klembord';

  @override
  String get settingsTitle => 'Instellingen';

  @override
  String get photoRemove => 'Foto weghalen';

  @override
  String get photoNeedsConnection =>
      'Je foto wijzigen kan alleen met een verbinding.';

  @override
  String get photoTooMany =>
      'Te vaak een andere foto gekozen. Probeer het over een uur opnieuw.';

  @override
  String get notifSaveFailed =>
      'Kon de meldingsinstellingen niet opslaan. Controleer je verbinding.';

  @override
  String get homeCurrencyNeedsConnection =>
      'Je thuisvaluta wijzigen kan alleen met een verbinding.';

  @override
  String get changePhoto => 'Profielfoto wijzigen';

  @override
  String get yourNameTapToChange => 'Je naam · tik om te wijzigen';

  @override
  String get waysToGetPaid => 'Manieren om betaald te worden';

  @override
  String get waysToGetPaidHint => 'PayPal, Wise, IBAN, bankrekening…';

  @override
  String get homeCurrency => 'Thuisvaluta';

  @override
  String get homeCurrencyFromRegion =>
      'Uit je regio · saldi tonen ook ≈ hierin';

  @override
  String get homeCurrencyPicked => 'Saldi tonen ook ≈ hierin';

  @override
  String get notifications => 'Meldingen';

  @override
  String get notifExpenses => 'Uitgaven en betalingen';

  @override
  String get notifComments => 'Reacties';

  @override
  String get notifMembers => 'Leden en groepswijzigingen';

  @override
  String get notifReminders => 'Herinneringen van vrienden';

  @override
  String get notifNeedConnection =>
      'Meldingsinstellingen hebben een verbinding nodig';

  @override
  String get notifOthersOnly =>
      'Je krijgt alleen meldingen van wijzigingen door anderen.';

  @override
  String get notifWebNote =>
      'Meldingen gaan naar je telefoon; de browser ververst elke minuut zolang hij open is.';

  @override
  String get exportImport => 'Exporteren en importeren';

  @override
  String get noGroupsToExport => 'Geen groepen om te exporteren.';

  @override
  String get nonGroup => 'Buiten groepen';

  @override
  String nonGroupWith(String name) {
    return 'Buiten groepen · $name';
  }

  @override
  String get exportJson => 'JSON exporteren';

  @override
  String get exportCsv => 'CSV exporteren';

  @override
  String get exportZip => 'ZIP met bonnen';

  @override
  String get importSplitwise => 'Splitwise-CSV importeren';

  @override
  String importedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uitgaven geïmporteerd',
      one: '1 uitgave geïmporteerd',
    );
    return '$_temp0';
  }

  @override
  String get server => 'Server';

  @override
  String get serverUrl => 'Server-URL';

  @override
  String serverDefault(String url) {
    return 'Standaard: $url';
  }

  @override
  String get serverSaved => 'Server-URL opgeslagen';

  @override
  String get account => 'Account';

  @override
  String get licenses => 'Licenties';

  @override
  String get deleteAccount => 'Account verwijderen';

  @override
  String get signOutTitle => 'Afmelden?';

  @override
  String get signOutMessage =>
      'De lokale gegevens op dit apparaat worden gewist. Wijzigingen die nog niet zijn gesynchroniseerd gaan verloren.';

  @override
  String get deleteAccountTitle => 'Account verwijderen?';

  @override
  String get deleteAccountMessage =>
      'Je lidmaatschappen worden tijdelijke leden. De groepsgegevens blijven bij de andere leden. Dit kan niet ongedaan worden gemaakt.';

  @override
  String get language => 'Taal';

  @override
  String languageSystem(String language) {
    return 'Systeem ($language)';
  }

  @override
  String get appearance => 'Weergave';

  @override
  String get appearanceSystem => 'Systeem';

  @override
  String get appearanceLight => 'Licht';

  @override
  String get appearanceDark => 'Donker';

  @override
  String get security => 'Beveiliging';

  @override
  String get appLock => 'App-vergrendeling';

  @override
  String get appLockHint =>
      'Face ID, Touch ID of vingerafdruk, met de toegangscode als reserve. Vergrendelt na een minuut weg.';

  @override
  String methodRemoveTitle(String method) {
    return '$method weghalen?';
  }

  @override
  String get methodsOffline =>
      'Maak verbinding met internet om je manieren om betaald te worden te bewerken.';

  @override
  String get methodsLoadFailed =>
      'Kon je manieren om betaald te worden niet laden.';

  @override
  String get methodsIntro =>
      'Groepsleden zien deze als ze je geld schuldig zijn, zodat ze je met één tik kunnen betalen. Evensies verplaatst zelf nooit geld.';

  @override
  String get methodsEmpty => 'Nog geen manieren om betaald te worden.';

  @override
  String get blurbPaypal => 'PayPal.me-link, bedrag ingevuld';

  @override
  String get blurbWise => 'Wise Quick Pay-link, bedrag ingevuld';

  @override
  String get blurbVenmo => 'Venmo-gebruikersnaam (VS)';

  @override
  String get blurbRevolut => 'Revolut.me-gebruikersnaam';

  @override
  String get blurbKakaopay => 'KakaoPay 송금코드-link';

  @override
  String get blurbIban => 'Overschrijving (SEPA-QR voor EUR)';

  @override
  String get blurbKrBank => 'Koreaanse bankrekening (Toss, bank-apps)';

  @override
  String get fieldPaypal => 'PayPal.me-gebruikersnaam';

  @override
  String get fieldPaypalHint => 'Je PayPal.me-gebruikersnaam, bijv. anna';

  @override
  String get fieldRevolut => 'Revolut.me-gebruikersnaam';

  @override
  String get fieldRevolutHint => 'Je Revolut.me-gebruikersnaam, bijv. anna';

  @override
  String get fieldVenmo => 'Venmo-gebruikersnaam';

  @override
  String get fieldVenmoHint => 'Zonder de @, bijv. anna-rossi';

  @override
  String get fieldWise => 'Wise Quick Pay-link';

  @override
  String get fieldWiseHint =>
      'In Wise: Betalingen → Quick Pay → link kopiëren (https://wise.com/pay/…)';

  @override
  String get fieldKakaopay => 'KakaoPay 송금코드-link';

  @override
  String get fieldKakaopayHint =>
      'In KakaoPay: 송금 → 송금코드 → link kopiëren (https://qr.kakaopay.com/…)';

  @override
  String get fieldHolder => 'Rekeninghouder';

  @override
  String get fieldHolderHint => 'Naam precies zoals op de rekening';

  @override
  String get fieldIban => 'IBAN';

  @override
  String get fieldIbanHint => 'bijv. NL91 ABNA 0417 1643 00';

  @override
  String get fieldBic => 'BIC (optioneel)';

  @override
  String get fieldBicHint => '8 of 11 tekens';

  @override
  String get fieldBank => 'Bank';

  @override
  String get fieldBankHint => 'bijv. 신한은행, Toss Bank';

  @override
  String get fieldAccountNumber => 'Rekeningnummer';

  @override
  String get fieldAccountNumberHint => 'Cijfers, streepjes optioneel';

  @override
  String amountCopied(String amount) {
    return 'Bedrag gekopieerd: $amount';
  }

  @override
  String couldNotOpen(String link) {
    return 'Kon $link niet openen';
  }

  @override
  String get payOffline => 'Offline: betaalmanieren zijn niet beschikbaar';

  @override
  String get payLoading => 'Betaalmanieren laden…';

  @override
  String payAskToAdd(String name) {
    return 'Vraag $name een manier om betaald te worden toe te voegen';
  }

  @override
  String payTitle(String name, String amount) {
    return '$amount betalen aan $name';
  }

  @override
  String get payScanQr => 'Scan met je bank-app (SEPA-QR)';

  @override
  String get payQrEurOnly =>
      'De QR-code is alleen beschikbaar voor overschrijvingen in EUR.';

  @override
  String get bankLabel => 'Bank';

  @override
  String get ibanLabel => 'IBAN';

  @override
  String get accountLabel => 'Rekening';

  @override
  String get bicLabel => 'BIC';

  @override
  String get holderLabel => 'Houder';

  @override
  String get amountLabel => 'Bedrag';

  @override
  String get copyIban => 'IBAN kopiëren';

  @override
  String get copyAccount => 'Rekening kopiëren';

  @override
  String get copyAmount => 'Bedrag kopiëren';

  @override
  String get ibanCopied => 'IBAN gekopieerd';

  @override
  String get accountCopied => 'Rekening gekopieerd';

  @override
  String get paymentUpdated => 'Betaling bijgewerkt';

  @override
  String paymentRecordedPending(String amount, String name) {
    return '$amount vastgelegd. $name bevestigt het.';
  }

  @override
  String paymentRecordedPendingUnnamed(String amount) {
    return '$amount vastgelegd. De ander bevestigt het.';
  }

  @override
  String paymentRecorded(String amount) {
    return 'Betaling van $amount vastgelegd';
  }

  @override
  String youSuffix(String name) {
    return '$name (jij)';
  }

  @override
  String get recordPayment => 'Betaling vastleggen';

  @override
  String get editPayment => 'Betaling bewerken';

  @override
  String get fromLabel => 'Van';

  @override
  String get toLabel => 'Aan';

  @override
  String get swap => 'Omwisselen';

  @override
  String get pickTwoPeople => 'Kies twee verschillende personen';

  @override
  String get commentsStayOld => 'Reacties blijven bij de oude betaling';

  @override
  String get recordPaymentButton => 'Betaling vastleggen';

  @override
  String get paymentNotHere => 'Deze betaling staat niet op dit apparaat';

  @override
  String get notSyncedOrLeft =>
      'Ze is nog niet gesynchroniseerd, of je hebt de groep verlaten.';

  @override
  String get someone => 'Iemand';

  @override
  String get paymentEdited => 'Bewerkte betaling';

  @override
  String get paymentDeleted => 'Verwijderde betaling';

  @override
  String get payment => 'Betaling';

  @override
  String get paymentWasEdited => 'Deze betaling is bewerkt';

  @override
  String get paymentWasEditedNote =>
      'De bewerkte betaling telt in plaats daarvan. De reacties blijven hier.';

  @override
  String get paymentWasDeleted => 'Deze betaling is verwijderd';

  @override
  String get paymentNotCounted => 'Ze telt niet mee in de saldi.';

  @override
  String get restore => 'Herstellen';

  @override
  String youPaidName(String name) {
    return 'Jij betaalde $name';
  }

  @override
  String namePaidYou(String name) {
    return '$name betaalde jou';
  }

  @override
  String namePaidName(String from, String to) {
    return '$from betaalde $to';
  }

  @override
  String paymentSaysSent(String name) {
    return '$name zegt dat dit naar je is gestuurd. Is het aangekomen?';
  }

  @override
  String waitingForConfirm(String name) {
    return 'Wacht op bevestiging van $name';
  }

  @override
  String get notReceived => 'Niet ontvangen';

  @override
  String get confirmReceived => 'Ontvangst bevestigen';

  @override
  String get deletePaymentTitle => 'Betaling verwijderen?';

  @override
  String get deletePaymentMessage => 'De schuld die ze vereffende komt terug.';

  @override
  String get paymentDeletedSnack => 'Betaling verwijderd';

  @override
  String get notReceivedTitle => 'Niet ontvangen?';

  @override
  String notReceivedMessage(String name) {
    return 'De betaling van $name wordt weggehaald en de schuld komt terug.';
  }

  @override
  String get paymentRemovedSnack => 'Betaling weggehaald';

  @override
  String get recordAPayment => 'Betaling vastleggen';

  @override
  String get nothingToSettle => 'Niets af te rekenen';

  @override
  String get everyoneEven => 'Iedereen staat quitte.';

  @override
  String get waitingForConfirmation => 'Wacht op bevestiging';

  @override
  String get debtsAsRecorded =>
      'Schulden zoals vastgelegd · schulden vereenvoudigen staat uit';

  @override
  String transfersSettleEverything(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count overboekingen rekenen alles af',
      one: '1 overboeking rekent alles af',
    );
    return '$_temp0';
  }

  @override
  String transfersSettleBalance(int count, String currency) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count overboekingen rekenen het $currency-saldo af',
      one: '1 overboeking rekent het $currency-saldo af',
    );
    return '$_temp0';
  }

  @override
  String notConvertedSettlesIn(String currency) {
    return 'Niet omgerekend · $currency · wordt afgerekend in $currency';
  }

  @override
  String get convert => 'Omrekenen';

  @override
  String get settleUp => 'Afrekenen';

  @override
  String saysTheySent(String name, String amount) {
    return '$name zegt je $amount te hebben gestuurd';
  }

  @override
  String waitingToConfirmAmount(String name, String amount) {
    return 'Wacht tot $name $amount bevestigt';
  }

  @override
  String get you => 'Jij';

  @override
  String get request => 'Vragen';

  @override
  String get iveSentIt => 'Ik heb het gestuurd';

  @override
  String get markAsPaid => 'Markeren als betaald';

  @override
  String markedAsSent(String name) {
    return 'Gemarkeerd als verstuurd. $name bevestigt het.';
  }

  @override
  String approx(String amount) {
    return '≈ $amount';
  }

  @override
  String friendOwesYou(String name, String amount) {
    return '$name is je $amount schuldig';
  }

  @override
  String friendYouOwe(String name, String amount) {
    return 'Je bent $name $amount schuldig';
  }

  @override
  String friendYouOweLine(String name, String amount) {
    return 'je bent $name $amount schuldig';
  }

  @override
  String noSharedGroup(String name) {
    return 'Je deelt geen groep meer met $name. Stuur je vriendenlink om uitgaven toe te voegen.';
  }

  @override
  String get shareFriendLink => 'Vriendenlink delen';

  @override
  String firstExpenseNeedsConnection(String name) {
    return 'De eerste uitgave met $name heeft een verbinding nodig.';
  }

  @override
  String reminderSent(String name) {
    return 'Herinnering gestuurd naar $name';
  }

  @override
  String remindTomorrow(String name) {
    return 'Je kunt $name morgen weer herinneren';
  }

  @override
  String remindNothingOwed(String name) {
    return '$name is je niets schuldig';
  }

  @override
  String get remindNeedsConnection =>
      'Een herinnering sturen kan alleen met een verbinding.';

  @override
  String amountsAnd(String a, String b) {
    return '$a en $b';
  }

  @override
  String inviteFriendText(String link) {
    return 'Ik heb je toegevoegd op Evensies zodat we uitgaven kunnen delen. Doe mee: $link';
  }

  @override
  String get personNotHere => 'Deze persoon staat niet op dit apparaat';

  @override
  String get personNotHereNote =>
      'Nog niet gesynchroniseerd, of jullie delen geen groep meer.';

  @override
  String get more => 'Meer';

  @override
  String get exportNonGroupCsv => 'Uitgaven buiten groepen exporteren (CSV)';

  @override
  String get exportNonGroupJson => 'Uitgaven buiten groepen exporteren (JSON)';

  @override
  String get exportNonGroupZip =>
      'Uitgaven buiten groepen exporteren (ZIP met bonnen)';

  @override
  String get notOnEvensies => 'Nog niet op Evensies';

  @override
  String get allSettledUp => 'Alles verrekend';

  @override
  String get remind => 'Herinneren';

  @override
  String get invite => 'Uitnodigen';

  @override
  String get balances => 'Saldi';

  @override
  String get expensesAndPayments => 'Uitgaven en betalingen';

  @override
  String get nothingTogetherYet =>
      'Nog niets samen. Voeg hieronder een uitgave toe.';

  @override
  String get addExpense => 'Uitgave toevoegen';

  @override
  String personOwesYou(String amount) {
    return 'is je $amount schuldig';
  }

  @override
  String personYouOwe(String amount) {
    return 'je bent $amount schuldig';
  }

  @override
  String get personSettledUp => 'verrekend';

  @override
  String recordedInGroups(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Vastgelegd in $count groepen',
      one: 'Vastgelegd in 1 groep',
    );
    return '$_temp0';
  }

  @override
  String get markAsReceived => 'Markeren als ontvangen';

  @override
  String get clearBothSides => 'Beide kanten wegstrepen';

  @override
  String evenIn(String currency) {
    return 'Quitte in $currency';
  }

  @override
  String linePayThem(String group, String name, String amount) {
    return '$group: jij betaalt $name $amount';
  }

  @override
  String lineTheyPay(String group, String name, String amount) {
    return '$group: $name betaalt jou $amount';
  }

  @override
  String get noMoneyMoves =>
      'Er gaat geen geld over: beide kanten worden als afgerekend vastgelegd.';

  @override
  String convertIn(String group) {
    return 'Omrekenen in $group';
  }

  @override
  String settleUpWith(String name) {
    return 'Afrekenen met $name';
  }

  @override
  String nothingToSettleWith(String name) {
    return 'Niets af te rekenen met $name';
  }

  @override
  String settleWithIntro(String name) {
    return 'Alles tussen jou en $name, per valuta. Vastleggen voegt in elke groep een betaling toe.';
  }

  @override
  String get searchFriendsGroups => 'Vrienden en groepen zoeken';

  @override
  String get friends => 'Vrienden';

  @override
  String get groups => 'Groepen';

  @override
  String get noFriendsOrGroups => 'Nog geen vrienden of groepen.';

  @override
  String nothingMatches(String query) {
    return 'Niets komt overeen met “$query”.';
  }

  @override
  String get addExpenseWithWhom => 'Uitgave toevoegen · met wie?';

  @override
  String friendLinkShare(String link, String code) {
    return 'Voeg me toe op Evensies om uitgaven te delen: $link\nOf vul mijn code $code in';
  }

  @override
  String get friendLinkNeedsConnection =>
      'Je vriendenlink delen kan alleen met een verbinding.';

  @override
  String get selfFriend => 'Dat is je eigen code';

  @override
  String get noOneForCode => 'Niemand gevonden met deze code';

  @override
  String get addFriendNeedsConnection =>
      'Een vriend toevoegen kan alleen met een verbinding.';

  @override
  String get newFriendCodeTitle => 'Nieuwe vriendencode maken?';

  @override
  String get newFriendCodeMessage =>
      'Je huidige link en code werken dan niet meer. Vrienden die je al hebt blijven.';

  @override
  String get newCode => 'Nieuwe code';

  @override
  String get addAFriend => 'Vriend toevoegen';

  @override
  String get friendLinkOffline => 'Je vriendenlink heeft een verbinding nodig';

  @override
  String get yourFriendCode => 'Je vriendencode';

  @override
  String get friendQrLabel => 'QR-code van je vriendenlink';

  @override
  String get friendCodeHelp =>
      'Vrienden scannen hem, openen de link of typen de code.';

  @override
  String get shareLink => 'Link delen';

  @override
  String get codeCopied => 'Code gekopieerd';

  @override
  String get copyCode => 'Code kopiëren';

  @override
  String get haveFriendCode => 'Heb je de code van een vriend?';

  @override
  String get onEvensies => 'op Evensies';

  @override
  String get notOnEvensiesSection => 'Iemand die nog niet op Evensies zit';

  @override
  String get notOnEvensiesHelp =>
      'Voeg meteen uitgaven toe met deze persoon en nodig hem of haar later uit.';

  @override
  String atMostChars(int max) {
    return 'Hoogstens $max tekens';
  }

  @override
  String addName(String name) {
    return '$name toevoegen';
  }

  @override
  String get search => 'Zoeken';

  @override
  String get activity => 'Activiteit';

  @override
  String get newGroup => 'Nieuwe groep';

  @override
  String get joinWithCode => 'Lid worden met een code';

  @override
  String get filterAll => 'Alle';

  @override
  String get filterOwesMe => 'Is mij schuldig';

  @override
  String get filterIOwe => 'Ik ben schuldig';

  @override
  String settledUpCount(int count) {
    return 'Verrekend ($count)';
  }

  @override
  String get nobodyOwesYou => 'Niemand is je iets schuldig';

  @override
  String get youOweNothing => 'Je bent niets schuldig';

  @override
  String get nothingHereYet => 'Hier staat nog niets';

  @override
  String get noFriendsYet => 'Nog geen vrienden';

  @override
  String get noFriendsHelp =>
      'Voeg een vriend toe om uitgaven buiten een groep te delen. Mensen met wie je een groep deelt staan hier ook.';

  @override
  String get allSettledUpYou => 'Bij jou is alles verrekend';

  @override
  String youAreOwedList(String amounts) {
    return 'Je krijgt $amounts';
  }

  @override
  String youOweList(String amounts) {
    return 'Je bent $amounts schuldig';
  }

  @override
  String get notOnEvensiesLower => 'nog niet op Evensies';

  @override
  String get noGroupsYet => 'Nog geen groepen';

  @override
  String get noGroupsHelp =>
      'Maak er een voor een reis of een huis, of word lid van de groep van een vriend met de uitnodigingscode.';

  @override
  String get createGroup => 'Groep maken';

  @override
  String get settledUp => 'Verrekend';

  @override
  String netApprox(String amount) {
    return 'Netto ≈ $amount';
  }

  @override
  String memberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count leden',
      one: '1 lid',
    );
    return '$_temp0';
  }

  @override
  String youOweAmount(String amount) {
    return 'Je bent $amount schuldig';
  }

  @override
  String youAreOwedAmount(String amount) {
    return 'Je krijgt $amount';
  }

  @override
  String youOweAmountLine(String amount) {
    return 'je bent $amount schuldig';
  }

  @override
  String youAreOwedAmountLine(String amount) {
    return 'je krijgt $amount';
  }

  @override
  String get createGroupNeedsConnection =>
      'Een groep maken kan alleen met een verbinding.';

  @override
  String get groupName => 'Groepsnaam';

  @override
  String get yourNameInGroup => 'Je naam in deze groep';

  @override
  String get defaultCurrency => 'Standaardvaluta';

  @override
  String get create => 'Maken';

  @override
  String get noGroupOrFriendForCode =>
      'Geen groep of vriend gevonden met deze code';

  @override
  String get joinNeedsConnection =>
      'Lid worden van een groep kan alleen met een verbinding.';

  @override
  String get enterACode => 'Code invoeren';

  @override
  String get enterCodeHelp =>
      'Een groepscode staat in de groep → Leden. Een vriendencode staat op het tabblad Vrienden → Vriend toevoegen.';

  @override
  String get pastedFromClipboard => 'Geplakt van het klembord';

  @override
  String nameOnEvensies(String name) {
    return '$name · op Evensies';
  }

  @override
  String addAsFriend(String name) {
    return '$name toevoegen als vriend';
  }

  @override
  String addedYouAsFriend(String name) {
    return '$name heeft je toegevoegd als vriend';
  }

  @override
  String get someoneAddedYouAsFriend => 'Iemand heeft je toegevoegd als vriend';

  @override
  String groupPreview(String name, String members) {
    return '$name · $members';
  }

  @override
  String get continueButton => 'Doorgaan';

  @override
  String wantsToSplit(String name) {
    return '$name wil uitgaven met je delen';
  }

  @override
  String get joinGroup => 'Lid worden van groep';

  @override
  String get inviteInvalid => 'Deze uitnodigingslink is niet meer geldig';

  @override
  String inviteFailed(String reason) {
    return 'Kon deze uitnodiging niet openen: $reason';
  }

  @override
  String get friendInviteUsed => 'Deze vriendenuitnodiging is al gebruikt';

  @override
  String get joinToSeeShared =>
      'Word lid om jullie gedeelde uitgaven te zien en toe te voegen.';

  @override
  String imName(String name) {
    return 'Ik ben $name';
  }

  @override
  String get join => 'Lid worden';

  @override
  String get whoAreYou => 'Wie ben jij?';

  @override
  String get newMemberName => 'Naam nieuw lid';

  @override
  String get insights => 'Inzichten';

  @override
  String get membersInvite => 'Leden en uitnodiging';

  @override
  String get groupSettings => 'Groepsinstellingen';

  @override
  String get expenses => 'Uitgaven';

  @override
  String get expenseFab => 'Uitgave';

  @override
  String get groupNotHere => 'Deze groep staat niet op dit apparaat';

  @override
  String get groupNotHereNote =>
      'Je hebt hem verlaten, iemand heeft je weggehaald, of hij is nog niet gesynchroniseerd.';

  @override
  String get backToGroups => 'Terug naar groepen';

  @override
  String get noExpensesYet => 'Nog geen uitgaven';

  @override
  String get tapExpenseToAdd => 'Tik op “Uitgave” om de eerste toe te voegen.';

  @override
  String tilePaidYou(String amount) {
    return 'jij betaalde $amount';
  }

  @override
  String tilePaidName(String name, String amount) {
    return '$name betaalde $amount';
  }

  @override
  String tilePaidPeople(int count, String amount) {
    return '$count personen betaalden $amount';
  }

  @override
  String get tileRefundYou => 'terugbetaling aan jou';

  @override
  String tileRefundName(String name) {
    return 'terugbetaling aan $name';
  }

  @override
  String tileRefundPeople(int count) {
    return 'terugbetaling aan $count personen';
  }

  @override
  String get notInvolved => 'niet betrokken';

  @override
  String get allYours => 'helemaal van jou';

  @override
  String get paidForYourself => 'je betaalde voor jezelf';

  @override
  String youGetBack(String amount) {
    return 'je krijgt $amount terug';
  }

  @override
  String youLent(String amount) {
    return 'je leende $amount uit';
  }

  @override
  String youBorrowed(String amount) {
    return 'je leende $amount';
  }

  @override
  String get repeatsLabel => 'Herhaalt';

  @override
  String hasReceipt(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Heeft $count bonnen',
      one: 'Heeft een bon',
    );
    return '$_temp0';
  }

  @override
  String get refund => 'Terugbetaling';

  @override
  String get notConverted => 'Niet omgerekend';

  @override
  String get pending => 'in afwachting';

  @override
  String approxTotalOwe(String amount) {
    return 'Je bent in totaal ≈ $amount schuldig';
  }

  @override
  String approxTotalOwed(String amount) {
    return 'Je krijgt in totaal ≈ $amount';
  }

  @override
  String get approxTotalNote => 'In je thuisvaluta, tegen de laatste koersen';

  @override
  String nothingOwedIn(String currency) {
    return 'Niets schuldig in $currency';
  }

  @override
  String get allSettled => 'Alles verrekend';

  @override
  String get otherCurrenciesBelow =>
      'Uitgaven in andere valuta staan hieronder.';

  @override
  String get nobodyOwes => 'Niemand is iets schuldig.';

  @override
  String youPayNext(String amount) {
    return 'Jij moet de volgende keer betalen (je bent $amount schuldig, het meest)';
  }

  @override
  String namePaysNext(String name, String amount) {
    return '$name moet de volgende keer betalen (is $amount schuldig, het meest)';
  }

  @override
  String settleUpWaiting(int count) {
    return 'Afrekenen · $count wachten';
  }

  @override
  String memberRemoved(String name) {
    return '$name (weggehaald)';
  }

  @override
  String expensesWithoutRate(int count, String currency) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uitgaven zonder koers naar $currency',
      one: '1 uitgave zonder koers naar $currency',
    );
    return '$_temp0';
  }

  @override
  String expensesBadRate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uitgaven met een koers die niet kan worden omgerekend',
      one: '1 uitgave met een koers die niet kan worden omgerekend',
    );
    return '$_temp0';
  }

  @override
  String paymentsIn(String currency) {
    return 'Betalingen in $currency';
  }

  @override
  String everyoneEvenIn(String currency) {
    return 'iedereen quitte in $currency';
  }

  @override
  String convertTo(String currency) {
    return 'Omrekenen naar $currency';
  }

  @override
  String get balanceSettled => 'verrekend';

  @override
  String get balanceGetsBack => 'krijgt terug';

  @override
  String get balanceOwes => 'is schuldig';

  @override
  String convertedCount(int count, String currency) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uitgaven omgerekend naar $currency',
      one: '1 uitgave omgerekend naar $currency',
    );
    return '$_temp0';
  }

  @override
  String get noAutoRate => 'Geen automatische koers. Vul er een in.';

  @override
  String rateOf(String date) {
    return 'koers van $date';
  }

  @override
  String rateOfOffline(String date) {
    return 'offline · koers van $date';
  }

  @override
  String amountCountExpenses(String amount, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uitgaven',
      one: '1 uitgave',
    );
    return '$amount · $_temp0';
  }

  @override
  String paymentsStayIn(String currency) {
    return 'Betalingen in $currency blijven in $currency';
  }

  @override
  String rateLabel(String from, String to) {
    return 'Koers: 1 $from in $to';
  }

  @override
  String get nothingLeftToConvert => 'Niets meer om te rekenen';

  @override
  String get lookingUpRate => 'Koers opzoeken…';

  @override
  String get enterRateAbove0 => 'Vul een koers boven 0 in';

  @override
  String convertExplain(String currency) {
    return 'Vult deze koers in bij elke uitgave zonder koers, zodat die meetelt in de $currency-saldi. Je kunt de koers per uitgave nog wijzigen.';
  }

  @override
  String get nameField => 'Naam';

  @override
  String get cantChangeCurrency =>
      'Niet meer te wijzigen na de eerste uitgave of betaling';

  @override
  String get currencyUsedFor => 'Saldi en betalingen gebruiken deze';

  @override
  String get splitting => 'Verdelen';

  @override
  String get simplifyDebts => 'Schulden vereenvoudigen';

  @override
  String get simplifyDebtsHelp =>
      'Voegt schulden samen zodat de groep minder betalingen nodig heeft. Niemands totaal verandert, alleen wie wie betaalt.';

  @override
  String get defaultSplit => 'Standaardverdeling';

  @override
  String get splitStale => 'Klopt niet meer · tik om te herstellen';

  @override
  String get membership => 'Lidmaatschap';

  @override
  String get leaveGroup => 'Groep verlaten';

  @override
  String get balanceSettledNote => 'Je saldo is verrekend';

  @override
  String get renameGroup => 'Groep hernoemen';

  @override
  String leaveTitle(String name) {
    return '“$name” verlaten?';
  }

  @override
  String get leaveMessage =>
      'Je ziet deze groep dan niet meer. Je eerdere uitgaven blijven bij de andere leden. Vraag om de uitnodigingscode om terug te komen.';

  @override
  String get leave => 'Verlaten';

  @override
  String youLeft(String name) {
    return 'Je hebt “$name” verlaten';
  }

  @override
  String get splitEqualEveryone => 'Gelijk · iedereen';

  @override
  String splitPercentList(String list) {
    return 'Procent · $list';
  }

  @override
  String splitSharesList(String list) {
    return 'Delen · $list';
  }

  @override
  String percentValue(String value) {
    return '$value%';
  }

  @override
  String get defaultSplitHelp =>
      'Nieuwe uitgaven beginnen met deze verdeling. Je kunt hem per uitgave nog wijzigen.';

  @override
  String get useEqual => 'Gelijk gebruiken';

  @override
  String get inviteCode => 'Uitnodigingscode';

  @override
  String get inviteQrLabel => 'QR-code van de uitnodigingslink';

  @override
  String get inviteCodeHelp =>
      'Iedereen met deze code kan lid worden en een naam kiezen.';

  @override
  String inviteShareText(String group, String link, String code) {
    return 'Word lid van mijn groep “$group” op Evensies: $link\nOf open de app en vul code $code in';
  }

  @override
  String get rotateCode => 'Code vernieuwen';

  @override
  String get members => 'Leden';

  @override
  String get notJoinedYet => 'nog geen lid — deel de uitnodigingscode';

  @override
  String get linked => 'gekoppeld';

  @override
  String get addPlaceholder => 'Tijdelijk lid toevoegen';

  @override
  String removeMemberTitle(String name) {
    return '$name weghalen?';
  }

  @override
  String get removeMemberMessage =>
      'Eerdere uitgaven en het saldo blijven in de groep.';

  @override
  String removeMemberSeries(int count, String name, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$name zit nog in $count terugkerende uitgaven ($names); het deel van $name blijft tot je de nieuwste bewerkt.',
      one:
          '$name zit nog in 1 terugkerende uitgave ($names); het deel van $name blijft tot je de nieuwste bewerkt.',
    );
    return '$_temp0';
  }

  @override
  String get addMember => 'Lid toevoegen';

  @override
  String get rotateInviteTitle => 'Uitnodigingscode vernieuwen?';

  @override
  String get rotateInviteMessage =>
      'De huidige code en link werken dan niet meer. Wie al lid is, merkt er niets van.';

  @override
  String get rotate => 'Vernieuwen';

  @override
  String get newInviteReady => 'Nieuwe uitnodigingscode klaar';

  @override
  String get activityNeedsConnection => 'Activiteit heeft een verbinding nodig';

  @override
  String get activityOfflineNote =>
      'Recente wijzigingen verschijnen hier zodra je weer online bent.';

  @override
  String get noActivityYet => 'Nog geen activiteit';

  @override
  String get activityAllGroups => 'Wijzigingen in je groepen verschijnen hier.';

  @override
  String get activityThisGroup => 'Wijzigingen in deze groep verschijnen hier.';

  @override
  String get showingSaved =>
      'Opgeslagen activiteit. Trek omlaag om te verversen.';

  @override
  String get loadMore => 'Meer laden';

  @override
  String get earlier => 'Eerder';

  @override
  String get today => 'Vandaag';

  @override
  String get yesterday => 'Gisteren';

  @override
  String forDate(String date) {
    return 'voor $date';
  }

  @override
  String get youCommented => 'Je hebt gereageerd';

  @override
  String nameCommented(String name) {
    return '$name heeft gereageerd';
  }

  @override
  String restoredName(String name) {
    return '“$name” hersteld';
  }

  @override
  String get paymentRestored => 'Betaling hersteld';

  @override
  String get expenseNotHere => 'Deze uitgave staat niet op dit apparaat';

  @override
  String get deletedExpense => 'Verwijderde uitgave';

  @override
  String get expense => 'Uitgave';

  @override
  String seriesRepeats(String frequency) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Herhaalt elke week',
      'biweekly': 'Herhaalt elke 2 weken',
      'monthly': 'Herhaalt elke maand',
      'yearly': 'Herhaalt elk jaar',
      'other': 'Herhaalt',
    });
    return '$_temp0';
  }

  @override
  String seriesRepeatsNext(String frequency, String date) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Herhaalt elke week · volgende op $date',
      'biweekly': 'Herhaalt elke 2 weken · volgende op $date',
      'monthly': 'Herhaalt elke maand · volgende op $date',
      'yearly': 'Herhaalt elk jaar · volgende op $date',
      'other': 'Herhaalt · volgende op $date',
    });
    return '$_temp0';
  }

  @override
  String seriesRepeatsNextAmount(String frequency, String amount, String date) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Herhaalt elke week · volgende $amount op $date',
      'biweekly': 'Herhaalt elke 2 weken · volgende $amount op $date',
      'monthly': 'Herhaalt elke maand · volgende $amount op $date',
      'yearly': 'Herhaalt elk jaar · volgende $amount op $date',
      'other': 'Herhaalt · volgende $amount op $date',
    });
    return '$_temp0';
  }

  @override
  String rateLine(String from, String rate, String to) {
    return 'Koers: 1 $from = $rate $to';
  }

  @override
  String notConvertedTo(String currency) {
    return 'Niet omgerekend naar $currency';
  }

  @override
  String get receivedSplitBack => 'Ontvangen en teruggedeeld';

  @override
  String get whoPaidOwes => 'Wie betaalde en wie is schuldig';

  @override
  String get items => 'Items';

  @override
  String get notes => 'Notities';

  @override
  String get receipts => 'Bonnen';

  @override
  String get history => 'Geschiedenis';

  @override
  String get deleteExpenseTitle => 'Uitgave verwijderen?';

  @override
  String get deleteExpenseMessage =>
      'Ze wordt voor iedereen in de groep verwijderd. Je kunt haar herstellen via Activiteit.';

  @override
  String get deleteRepeatingTitle => 'Terugkerende uitgave verwijderen?';

  @override
  String get deleteRepeatingMessage =>
      'Ze wordt voor iedereen in de groep verwijderd. Je kunt haar herstellen via Activiteit, maar een gestopte reeks kan niet opnieuw starten. Al toegevoegde herhalingen blijven.';

  @override
  String get deleteThisOne => 'Alleen deze verwijderen';

  @override
  String get deleteAndStop => 'Verwijderen en herhalen stoppen';

  @override
  String deletedAndStopped(String name) {
    return '“$name” verwijderd en herhalen gestopt';
  }

  @override
  String deletedName(String name) {
    return '“$name” verwijderd';
  }

  @override
  String get movedToOtherGroup => 'Verplaatst naar een andere groep';

  @override
  String get movedNote =>
      'Ze telt nu daar. Reacties en geschiedenis blijven hier.';

  @override
  String get expenseWasDeleted => 'Deze uitgave is verwijderd';

  @override
  String get restoreToCount =>
      'Herstel haar om weer mee te tellen in de saldi.';

  @override
  String get tax => 'Btw';

  @override
  String get tipService => 'Fooi of service';

  @override
  String get discount => 'Korting';

  @override
  String youPaidOwe(String paid, String owe) {
    return 'Jij betaalde $paid en bent $owe schuldig';
  }

  @override
  String youPaid(String amount) {
    return 'Jij betaalde $amount';
  }

  @override
  String youOwe(String amount) {
    return 'Je bent $amount schuldig';
  }

  @override
  String namePaidOwes(String name, String paid, String owe) {
    return '$name betaalde $paid en is $owe schuldig';
  }

  @override
  String namePaid(String name, String amount) {
    return '$name betaalde $amount';
  }

  @override
  String nameOwes(String name, String amount) {
    return '$name is $amount schuldig';
  }

  @override
  String youReceivedGetBack(String received, String back) {
    return 'Jij ontving $received en krijgt $back terug';
  }

  @override
  String youReceived(String amount) {
    return 'Jij ontving $amount';
  }

  @override
  String youGetBackLine(String amount) {
    return 'Je krijgt $amount terug';
  }

  @override
  String nameReceivedGetsBack(String name, String received, String back) {
    return '$name ontving $received en krijgt $back terug';
  }

  @override
  String nameReceived(String name, String amount) {
    return '$name ontving $amount';
  }

  @override
  String nameGetsBack(String name, String amount) {
    return '$name krijgt $amount terug';
  }

  @override
  String get noHistoryYet => 'Nog geen geschiedenis.';

  @override
  String get historyOffline =>
      'De geschiedenis verschijnt hier zodra je online bent.';

  @override
  String get showingSavedHistory => 'Opgeslagen geschiedenis.';

  @override
  String get showMore => 'Meer tonen';

  @override
  String get deleteCommentTitle => 'Reactie verwijderen?';

  @override
  String get comments => 'Reacties';

  @override
  String get noCommentsYet => 'Nog geen reacties.';

  @override
  String get deleteComment => 'Reactie verwijderen';

  @override
  String get addComment => 'Reageren';

  @override
  String get send => 'Versturen';

  @override
  String get filterByCategory => 'Filteren op categorie';

  @override
  String get category => 'Categorie';

  @override
  String get categoryAll => 'Alle';

  @override
  String get month => 'Maand';

  @override
  String get searchUnavailable => 'Zoeken is niet beschikbaar';

  @override
  String get searchExpenses => 'Uitgaven zoeken';

  @override
  String get searchHelp =>
      'Omschrijvingen, notities, reacties, categorieën en bedragen: “taxi”, “vliegveld”, “12,50”.';

  @override
  String get noMatches => 'Geen resultaten';

  @override
  String get noMatchesHelp => 'Probeer een ander woord of haal een filter weg.';

  @override
  String expenseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uitgaven',
      one: '1 uitgave',
    );
    return '$_temp0';
  }

  @override
  String get searchAllGroups => 'Alle groepen doorzoeken';

  @override
  String searchGroup(String name) {
    return '$name doorzoeken';
  }

  @override
  String get searchThisGroup => 'Deze groep doorzoeken';

  @override
  String get clear => 'Wissen';

  @override
  String get thisGroup => 'Deze groep';

  @override
  String insightsError(String reason) {
    return 'Inzichten kunnen niet worden getoond: $reason';
  }

  @override
  String get nothingToShow => 'Nog niets om te tonen';

  @override
  String get insightsEmptyHelp =>
      'Totalen en grafieken verschijnen zodra de groep uitgaven heeft.';

  @override
  String get allTime => 'Altijd';

  @override
  String get shareSummary => 'Overzicht delen';

  @override
  String get printSummary => 'Overzicht afdrukken';

  @override
  String get previousMonth => 'Vorige maand';

  @override
  String get nextMonth => 'Volgende maand';

  @override
  String get byMonth => 'Per maand';

  @override
  String get groupSegment => 'Groep';

  @override
  String get mineSegment => 'Van mij';

  @override
  String get byCategory => 'Per categorie';

  @override
  String get noExpensesPeriod => 'Geen uitgaven in deze periode.';

  @override
  String get byPerson => 'Per persoon';

  @override
  String get nobodyPaidPeriod =>
      'Niemand betaalde of was iets schuldig in deze periode.';

  @override
  String keptUntilConverted(String currency, String group) {
    return 'Blijft in $currency tot het is omgerekend naar $group.';
  }

  @override
  String get totalSpent => 'Totaal uitgegeven';

  @override
  String get yourShare => 'Jouw deel';

  @override
  String get paymentsMade => 'Betalingen gedaan';

  @override
  String get paymentsReceived => 'Betalingen ontvangen';

  @override
  String get youPaidRow => 'Jij betaalde';

  @override
  String get balanceChange => 'Verandering van je saldo';

  @override
  String get paidLegend => 'Betaald';

  @override
  String get shareLegend => 'Deel';

  @override
  String paidShareLine(String paid, String share) {
    return 'betaald $paid · deel $share';
  }

  @override
  String get itemsGiveEveryone => 'Geef elk item een persoon';

  @override
  String get itemsAddPrices => 'Vul de prijzen in vóór btw of fooi';

  @override
  String get itemsDiscountTooBig => 'De korting is hoger dan de rekening';

  @override
  String get itemsDontAddUp => 'De items kloppen niet';

  @override
  String get adjustmentsDontFit => 'De aanpassingen passen niet in het totaal';

  @override
  String get giveSomeoneShare => 'Geef iemand een deel';

  @override
  String get checkNumbers => 'Controleer de getallen';

  @override
  String get splitDoesntAddUp => 'De verdeling klopt niet';

  @override
  String get addTheItems => 'Voeg de items toe';

  @override
  String get pickOnePerson => 'Kies minstens één persoon';

  @override
  String splitEquallyBetween(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Gelijk verdeeld over $count personen',
      one: 'Gelijk verdeeld over 1 persoon',
    );
    return '$_temp0';
  }

  @override
  String get allForOnePerson => 'Alles voor 1 persoon';

  @override
  String splitEquallyEach(int count, String amount) {
    return 'Gelijk verdeeld over $count personen · $amount per persoon';
  }

  @override
  String get checkAmounts => 'Controleer de bedragen';

  @override
  String get enterTotalFirst => 'Vul eerst het totaal in';

  @override
  String remaining(String amount) {
    return 'nog over: $amount';
  }

  @override
  String overBy(String amount) {
    return 'te veel: $amount';
  }

  @override
  String get addsUp => 'Klopt';

  @override
  String sharesInTotal(String count) {
    return '$count delen in totaal';
  }

  @override
  String get oneShareInTotal => '1 deel in totaal';

  @override
  String get restSplitEqually => 'De rest wordt gelijk verdeeld';

  @override
  String get byPercent => 'Per percentage';

  @override
  String get byShares => 'Per deel';

  @override
  String get byAdjustment =>
      'Aanpassen: meer of minder voor iemand, de rest gelijk';

  @override
  String get modeEqual => 'Gelijk';

  @override
  String get modeExact => 'Exact';

  @override
  String get modeShares => 'Delen';

  @override
  String get byItem => 'Per item, van een bon';

  @override
  String get adjustmentHelp =>
      'Tel een bedrag op of trek het af voor iemand; de rest wordt gelijk verdeeld.';

  @override
  String get noMembers => 'Geen leden';

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
  String get addAnItem => 'Voeg een item toe';

  @override
  String atMostItems(int max) {
    return 'Hoogstens $max items';
  }

  @override
  String get giveItemName => 'Geef elk item een naam';

  @override
  String get itemNameTooLong => 'Een itemnaam is te lang';

  @override
  String get addItem => 'Item toevoegen';

  @override
  String get giveRestToEveryone => 'De rest aan iedereen geven';

  @override
  String get subtotal => 'Subtotaal';

  @override
  String get total => 'Totaal';

  @override
  String receiptSays(String printed, String difference) {
    return 'De bon zegt $printed · items wijken $difference af';
  }

  @override
  String get eachPerson => 'Per persoon';

  @override
  String itemsWithoutPerson(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items zonder persoon',
      one: '1 item zonder persoon',
    );
    return '$_temp0';
  }

  @override
  String get itemHint => 'Item';

  @override
  String memberLeft(String name) {
    return '$name (vertrokken)';
  }

  @override
  String get whoHadThis => 'Wie had dit?';

  @override
  String get defaultSplitStartsEqual =>
      'De standaardverdeling van de groep klopt niet meer, dus deze begint gelijk';

  @override
  String leftToAssign(String amount) {
    return 'Nog $amount te verdelen';
  }

  @override
  String get itemsTotal => 'Het totaal van de items';

  @override
  String get newExpense => 'Nieuwe uitgave';

  @override
  String get editExpense => 'Uitgave bewerken';

  @override
  String get scanReceipt => 'Bon scannen';

  @override
  String get rateAboveZeroOrEmpty =>
      'Vul een koers boven 0 in, of laat het leeg';

  @override
  String useAutoRate(String rate, String source) {
    return 'Automatische koers gebruiken: $rate ($source)';
  }

  @override
  String get description => 'Omschrijving';

  @override
  String get receivedBy => 'Ontvangen door';

  @override
  String get paidBy => 'Betaald door';

  @override
  String get severalPeople => 'Meerdere personen';

  @override
  String get when => 'Wanneer';

  @override
  String get refundTooltip =>
      'Geld dat terugkwam, bijv. de borg die het hotel teruggaf';

  @override
  String get splitBackTo => 'Teruggedeeld met';

  @override
  String get split => 'Verdeling';

  @override
  String theyOweFull(String name) {
    return '$name is het hele bedrag schuldig';
  }

  @override
  String iOweFull(String name) {
    return 'Ik ben $name het hele bedrag schuldig';
  }

  @override
  String get repeat => 'Herhalen';

  @override
  String editLatestRepeat(String date) {
    return 'Bewerk de nieuwste ($date) om toekomstige herhalingen te wijzigen';
  }

  @override
  String get stopsRepeating =>
      'Stopt met herhalen. Al toegevoegde herhalingen blijven.';

  @override
  String nextRepeat(String date) {
    return 'Volgende: $date';
  }

  @override
  String get alsoChangeFuture => 'Ook toekomstige herhalingen wijzigen';

  @override
  String get futureFields =>
      'Bedrag, verdeling, betalers, omschrijving, categorie en notities';

  @override
  String get onlyThisOne => 'Alleen deze verandert';

  @override
  String get addPhoto => 'Foto toevoegen';

  @override
  String maxReceiptsNote(int max) {
    return '$max bonnen is het maximum voor één uitgave';
  }

  @override
  String get scanAReceipt => 'Een bon scannen';

  @override
  String receiptLooksLike(String currency) {
    return 'Deze bon lijkt in $currency te zijn';
  }

  @override
  String switchToCurrencyQuestion(String currency) {
    return 'De uitgave omzetten naar $currency om de items te lezen?';
  }

  @override
  String switchTo(String currency) {
    return 'Omzetten naar $currency';
  }

  @override
  String get couldntReadItems =>
      'De items konden niet worden gelezen. Typ ze in.';

  @override
  String withName(String name) {
    return 'Met $name';
  }

  @override
  String movesTo(String name) {
    return 'Wordt bij opslaan verplaatst naar $name';
  }

  @override
  String fromName(String name) {
    return 'Uit $name';
  }

  @override
  String get dontMove => 'Niet verplaatsen';

  @override
  String get onlyLinkedMove =>
      'Alleen mensen op Evensies die in beide zitten kunnen worden verplaatst';

  @override
  String get auto => 'auto';

  @override
  String get noAutoRateForm =>
      'Geen automatische koers. Vul er een in, of laat het leeg om het onder “Niet omgerekend” te houden.';

  @override
  String get emptyNotConverted => 'Leeg: dit blijft onder “Niet omgerekend”';

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
  String get yourRate => 'jouw koers';
}
