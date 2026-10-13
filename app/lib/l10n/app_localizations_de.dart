// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Evensies';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String get remove => 'Entfernen';

  @override
  String get save => 'Speichern';

  @override
  String get done => 'Fertig';

  @override
  String get undo => 'Rückgängig';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get ok => 'OK';

  @override
  String get close => 'Schließen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get add => 'Hinzufügen';

  @override
  String get offlineBanner =>
      'Offline – Änderungen werden später synchronisiert';

  @override
  String get tooLong => 'Zu lang';

  @override
  String get allCurrencies => 'Alle Währungen';

  @override
  String get errorUnexpected =>
      'Etwas ist schiefgelaufen. Versuch es noch einmal.';

  @override
  String get errorNetwork => 'Du bist offline. Versuch es später noch einmal.';

  @override
  String get errorRateLimited =>
      'Zu viele Versuche. Warte eine Minute und versuch es noch einmal.';

  @override
  String get errorNotFound => 'Das gibt es nicht mehr.';

  @override
  String get errorForbidden => 'Das darfst du nicht.';

  @override
  String get errorValidation => 'Der Server hat es abgelehnt.';

  @override
  String get errorSumMismatch => 'Die Aufteilung geht nicht auf.';

  @override
  String get errorPayersSumMismatch => 'Die Zahlenden gehen nicht auf.';

  @override
  String get errorNegativeAmount => 'Ein Betrag ist kleiner als null.';

  @override
  String get errorNegativeShare => 'Ein Anteil wäre kleiner als null.';

  @override
  String get errorNegativeTotal => 'Die Summe wäre kleiner als null.';

  @override
  String get errorZeroSubtotal =>
      'Gib die Preise der Posten vor Steuer, Trinkgeld oder Rabatt ein.';

  @override
  String get errorUnassignedItem =>
      'Jeder Posten braucht mindestens eine Person.';

  @override
  String get errorNoMembers => 'Wähle mindestens eine Person zum Aufteilen.';

  @override
  String get errorInvalidInput => 'Prüfe die Zahlen.';

  @override
  String get errorBadRate => 'Der Wechselkurs muss über null liegen.';

  @override
  String get errorUnknownMember =>
      'Es geht um jemanden, der nicht in der Gruppe ist.';

  @override
  String get errorUnknownCurrency => 'Die Währung wird nicht unterstützt.';

  @override
  String get errorMemberTaken => 'Dieses Mitglied ist schon vergeben.';

  @override
  String get errorLimitExceeded => 'Das Limit ist erreicht.';

  @override
  String get errorTooLarge => 'Das Foto ist zu groß.';

  @override
  String get errorNotJpeg => 'Wähle ein JPEG-Foto';

  @override
  String get errorFxUnavailable => 'Wechselkurse sind gerade nicht verfügbar.';

  @override
  String get errorImportFailed => 'Diese Datei konnte nicht importiert werden.';

  @override
  String get errorAuthNotConfigured =>
      'Dieser Server kann dich so nicht anmelden.';

  @override
  String get errorDuplicate => 'Das gibt es schon.';

  @override
  String errorGeneric(String code) {
    return 'Etwas ist schiefgelaufen ($code).';
  }

  @override
  String rejectedReceipt(String name, String reason) {
    return 'Der Beleg zu „$name“ konnte nicht gespeichert werden: $reason';
  }

  @override
  String rejectedReceiptUnnamed(String reason) {
    return 'Der Beleg zu einer Ausgabe konnte nicht gespeichert werden: $reason';
  }

  @override
  String rejectedReceiptRemove(String name, String reason) {
    return 'Das Entfernen eines Belegs von „$name“ konnte nicht gespeichert werden: $reason';
  }

  @override
  String rejectedReceiptRemoveUnnamed(String reason) {
    return 'Das Entfernen eines Belegs von einer Ausgabe konnte nicht gespeichert werden: $reason';
  }

  @override
  String rejectedRepeating(String name, String reason) {
    return 'Die Wiederholung von „$name“ konnte nicht gespeichert werden: $reason';
  }

  @override
  String rejectedRepeatingUnnamed(String reason) {
    return 'Eine wiederkehrende Ausgabe konnte nicht gespeichert werden: $reason';
  }

  @override
  String rejectedSeriesChange(String name, String reason) {
    return 'Eine Änderung an künftigen „$name“ konnte nicht gespeichert werden: $reason';
  }

  @override
  String rejectedSeriesChangeUnnamed(String reason) {
    return 'Eine Änderung an einer wiederkehrenden Ausgabe konnte nicht gespeichert werden: $reason';
  }

  @override
  String rejectedSeriesStop(String name, String reason) {
    return 'Das Beenden der Wiederholung von „$name“ konnte nicht gespeichert werden: $reason';
  }

  @override
  String rejectedSeriesStopUnnamed(String reason) {
    return 'Das Beenden einer wiederkehrenden Ausgabe konnte nicht gespeichert werden: $reason';
  }

  @override
  String rejectedSavedNoRepeat(String name, String reason) {
    return '„$name“ wurde gespeichert, wiederholt sich aber nicht: $reason';
  }

  @override
  String rejectedPaymentRestore(String reason) {
    return 'Das Wiederherstellen einer Zahlung konnte nicht gespeichert werden: $reason';
  }

  @override
  String rejectedNewExpense(String name, String reason) {
    return 'Die neue Ausgabe „$name“ konnte nicht gespeichert werden: $reason';
  }

  @override
  String rejectedNewExpenseUnnamed(String reason) {
    return 'Eine neue Ausgabe konnte nicht gespeichert werden: $reason';
  }

  @override
  String rejectedExpenseChange(String name, String reason) {
    return 'Eine Änderung an „$name“ konnte nicht gespeichert werden: $reason';
  }

  @override
  String rejectedExpenseChangeUnnamed(String reason) {
    return 'Eine Änderung an einer Ausgabe konnte nicht gespeichert werden: $reason';
  }

  @override
  String rejectedExpenseDelete(String name, String reason) {
    return 'Das Löschen von „$name“ konnte nicht gespeichert werden: $reason';
  }

  @override
  String rejectedExpenseDeleteUnnamed(String reason) {
    return 'Das Löschen einer Ausgabe konnte nicht gespeichert werden: $reason';
  }

  @override
  String rejectedExpenseRestore(String name, String reason) {
    return 'Das Wiederherstellen von „$name“ konnte nicht gespeichert werden: $reason';
  }

  @override
  String rejectedExpenseRestoreUnnamed(String reason) {
    return 'Das Wiederherstellen einer Ausgabe konnte nicht gespeichert werden: $reason';
  }

  @override
  String rejectedComment(String name, String reason) {
    return 'Ein Kommentar zu „$name“ konnte nicht gespeichert werden: $reason';
  }

  @override
  String rejectedCommentUnnamed(String reason) {
    return 'Ein Kommentar zu einer Ausgabe konnte nicht gespeichert werden: $reason';
  }

  @override
  String rejectedPaymentComment(String reason) {
    return 'Ein Kommentar zu einer Zahlung konnte nicht gespeichert werden: $reason';
  }

  @override
  String rejectedCommentDelete(String reason) {
    return 'Das Löschen eines Kommentars konnte nicht gespeichert werden: $reason';
  }

  @override
  String rejectedPayment(String reason) {
    return 'Eine Zahlung konnte nicht gespeichert werden: $reason';
  }

  @override
  String rejectedPaymentDelete(String reason) {
    return 'Das Löschen einer Zahlung konnte nicht gespeichert werden: $reason';
  }

  @override
  String rejectedPaymentConfirm(String reason) {
    return 'Das Bestätigen einer Zahlung konnte nicht gespeichert werden: $reason';
  }

  @override
  String rejectedGroupSettings(String reason) {
    return 'Eine Änderung der Gruppeneinstellungen konnte nicht gespeichert werden: $reason';
  }

  @override
  String rejectedMemberAdd(String name, String reason) {
    return '$name konnte nicht hinzugefügt werden: $reason';
  }

  @override
  String rejectedMemberAddUnnamed(String reason) {
    return 'Ein Mitglied konnte nicht hinzugefügt werden: $reason';
  }

  @override
  String rejectedMemberRemove(String reason) {
    return 'Das Entfernen eines Mitglieds konnte nicht gespeichert werden: $reason';
  }

  @override
  String rejectedOther(String reason) {
    return 'Eine Änderung konnte nicht gespeichert werden: $reason';
  }

  @override
  String get reasonReceiptLimit =>
      'eine Ausgabe kann höchstens 10 Belege haben';

  @override
  String get reasonSeriesLimit =>
      'eine Gruppe kann höchstens 100 wiederkehrende Ausgaben haben';

  @override
  String get reasonNotUploaded => 'das Foto wurde nicht hochgeladen';

  @override
  String get reasonSumMismatch => 'die Aufteilung geht nicht auf';

  @override
  String get reasonPayersSumMismatch => 'die Zahlenden gehen nicht auf';

  @override
  String get reasonNegativeAmount => 'ein Betrag ist kleiner als null';

  @override
  String get reasonUnknownMember =>
      'es geht um jemanden, der nicht in der Gruppe ist';

  @override
  String get reasonUnknownCurrency => 'die Währung wird nicht unterstützt';

  @override
  String get reasonMemberTaken => 'dieses Mitglied ist schon vergeben';

  @override
  String get reasonGroupFull => 'die Gruppe ist voll';

  @override
  String get reasonForbidden => 'du darfst das nicht ändern';

  @override
  String get reasonRefused => 'der Server hat es abgelehnt';

  @override
  String leaveOwe(String amount) {
    return 'Du schuldest $amount · begleiche das zuerst';
  }

  @override
  String leaveOweIn(String amount, String currency) {
    return 'Du schuldest $amount · begleiche das zuerst in $currency';
  }

  @override
  String leaveOwed(String amount) {
    return 'Du bekommst noch $amount · begleiche das zuerst';
  }

  @override
  String leaveOwedIn(String amount, String currency) {
    return 'Du bekommst noch $amount · begleiche das zuerst in $currency';
  }

  @override
  String leaveSeries(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Du bist noch in $count wiederkehrenden Ausgaben ($names) · bearbeite die neueste oder beende sie zuerst',
      one:
          'Du bist noch in 1 wiederkehrenden Ausgabe ($names) · bearbeite die neueste oder beende sie zuerst',
    );
    return '$_temp0';
  }

  @override
  String seriesNamesMore(String names, int count) {
    return '$names und $count weitere';
  }

  @override
  String get seriesUnnamed => 'eine Ausgabe';

  @override
  String get listJoiner => ', ';

  @override
  String get repeatNever => 'Nie';

  @override
  String get repeatWeekly => 'Jede Woche';

  @override
  String get repeatBiweekly => 'Alle 2 Wochen';

  @override
  String get repeatMonthly => 'Jeden Monat';

  @override
  String get repeatYearly => 'Jedes Jahr';

  @override
  String summaryNotConverted(String currency) {
    return 'Nicht umgerechnet · $currency';
  }

  @override
  String summaryTotalSpent(String amount) {
    return 'Gesamt ausgegeben: $amount';
  }

  @override
  String summaryPaidShare(String paid, String share) {
    return 'Du hast bezahlt: $paid · Dein Anteil: $share';
  }

  @override
  String summaryPayments(String made, String received) {
    return 'Gezahlt: $made · erhalten: $received';
  }

  @override
  String summaryTopCategories(String list) {
    return 'Top-Kategorien: $list';
  }

  @override
  String get summaryBalancesToday => 'Salden heute';

  @override
  String summaryGetsBack(String name, String amount) {
    return '$name bekommt $amount zurück';
  }

  @override
  String summaryOwes(String name, String amount) {
    return '$name schuldet $amount';
  }

  @override
  String get summaryFooter => 'Geteilt aus Evensies';

  @override
  String get koreanBank => 'Koreanisches Bankkonto';

  @override
  String requestText(String amount, String group) {
    return 'Du schuldest mir $amount für $group auf Evensies.';
  }

  @override
  String requestTextWays(String amount, String group, String ways) {
    return 'Du schuldest mir $amount für $group auf Evensies. Zahlen mit: $ways';
  }

  @override
  String get requestNoGroup => 'unsere gemeinsamen Ausgaben';

  @override
  String get leaveSyncing =>
      'Wird noch synchronisiert. Versuch es gleich noch einmal.';

  @override
  String get leaveOffline => 'Zum Verlassen musst du online sein';

  @override
  String get moveOffline =>
      'Verschieben fehlgeschlagen. Versuch es, wenn du online bist';

  @override
  String moveFailed(String reason) {
    return 'Verschieben fehlgeschlagen: $reason';
  }

  @override
  String get photoNoAccess =>
      'Evensies hat keinen Zugriff. Erlaube ihn in der Einstellungen-App.';

  @override
  String get photoNoCamera => 'Die Kamera ließ sich nicht öffnen.';

  @override
  String get photoNoLibrary => 'Die Fotomediathek ließ sich nicht öffnen.';

  @override
  String get photoUnusable =>
      'Dieses Foto ließ sich nicht verwenden. Versuch ein anderes.';

  @override
  String get methodErrorUsername => 'Nur Buchstaben, Ziffern, . _ - (max. 40)';

  @override
  String methodErrorLinkPrefix(String prefix) {
    return 'Muss mit $prefix beginnen';
  }

  @override
  String get methodErrorTooLong => 'Max. 200 Zeichen';

  @override
  String get methodErrorIban => 'Keine gültige IBAN';

  @override
  String get methodErrorHolder => 'Name des Kontoinhabers (1–70 Zeichen)';

  @override
  String get methodErrorBic => 'Die BIC hat 8 oder 11 Zeichen';

  @override
  String get methodErrorKrAccount => 'Ziffern und Bindestriche, 8–20 Ziffern';

  @override
  String get methodErrorBank => 'Name der Bank (1–30 Zeichen)';

  @override
  String get methodErrorUnknownType => 'Unbekannte Art';

  @override
  String get methodErrorTooMany =>
      'Höchstens 8 Zahlungswege und 3 von jeder Bankart';

  @override
  String get bannerDismiss => 'Schließen';

  @override
  String get bannerView => 'Ansehen';

  @override
  String get loginTagline =>
      'Ausgaben mit Freunden teilen. Keine Werbung, kein Upselling.';

  @override
  String get loginApple => 'Weiter mit Apple';

  @override
  String get loginGoogle => 'Weiter mit Google';

  @override
  String get loginWebUnavailable =>
      'Dieser Server bietet noch keine Anmeldung im Browser an.';

  @override
  String get welcomeTitle => 'Willkommen';

  @override
  String get yourNameTitle => 'Dein Name';

  @override
  String get nameQuestion => 'Wie sollen deine Freunde dich nennen?';

  @override
  String get nameExplain => 'Diesen Namen sehen die anderen Mitglieder.';

  @override
  String get nameHelp =>
      'Er wird Leuten in deinen Gruppen angezeigt. Du kannst ihn später in den Einstellungen ändern.';

  @override
  String get nameLabel => 'Name';

  @override
  String get lockReason => 'Evensies entsperren';

  @override
  String get lockTitle => 'Evensies ist gesperrt';

  @override
  String get lockSubtitle =>
      'Entsperre mit Face ID, Touch ID, deinem Fingerabdruck oder dem Gerätecode.';

  @override
  String get lockUnlock => 'Entsperren';

  @override
  String get lockSignOutConfirm =>
      'Abmelden und die Daten auf diesem Gerät entfernen? Deine Gruppen bleiben auf dem Server.';

  @override
  String get signOut => 'Abmelden';

  @override
  String get widgetOwed => 'Du bekommst';

  @override
  String get widgetOwe => 'Du schuldest';

  @override
  String get widgetSignedOut => 'Melde dich an, um deinen Saldo zu sehen';

  @override
  String get widgetSettled => 'Alles ausgeglichen';

  @override
  String widgetUpdated(String time) {
    return 'Aktualisiert $time';
  }

  @override
  String get receiptAdd => 'Beleg hinzufügen';

  @override
  String get photoTake => 'Foto aufnehmen';

  @override
  String get photoChoose => 'Aus Mediathek wählen';

  @override
  String get photoChooseFile => 'Datei wählen';

  @override
  String get availableWhenOnline => 'Online verfügbar';

  @override
  String get receiptPhoto => 'Belegfoto';

  @override
  String get receiptAvailableOnline => 'Das Foto ist online verfügbar';

  @override
  String get receiptRemoveTitle => 'Beleg entfernen?';

  @override
  String get receiptRemoveMessage => 'Er wird für alle in der Gruppe entfernt.';

  @override
  String get receiptTitle => 'Beleg';

  @override
  String receiptTitleOf(int index, int count) {
    return 'Beleg $index von $count';
  }

  @override
  String get shareOrSave => 'Teilen oder sichern';

  @override
  String get share => 'Teilen';

  @override
  String get copiedToClipboard => 'In die Zwischenablage kopiert';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get photoRemove => 'Foto entfernen';

  @override
  String get photoNeedsConnection =>
      'Zum Ändern deines Fotos brauchst du eine Verbindung.';

  @override
  String get photoTooMany =>
      'Zu viele Fotoänderungen. Versuch es in einer Stunde noch einmal.';

  @override
  String get notifSaveFailed =>
      'Die Benachrichtigungseinstellungen konnten nicht gespeichert werden. Prüfe deine Verbindung.';

  @override
  String get homeCurrencyNeedsConnection =>
      'Zum Ändern deiner Heimatwährung brauchst du eine Verbindung.';

  @override
  String get changePhoto => 'Profilfoto ändern';

  @override
  String get yourNameTapToChange => 'Dein Name · zum Ändern tippen';

  @override
  String get waysToGetPaid => 'Zahlungswege';

  @override
  String get waysToGetPaidHint => 'PayPal, Wise, IBAN, Bankkonto…';

  @override
  String get homeCurrency => 'Heimatwährung';

  @override
  String get homeCurrencyFromRegion =>
      'Aus deiner Region · Salden zeigen auch ≈ darin';

  @override
  String get homeCurrencyPicked => 'Salden zeigen auch ≈ darin';

  @override
  String get notifications => 'Benachrichtigungen';

  @override
  String get notifExpenses => 'Ausgaben und Zahlungen';

  @override
  String get notifComments => 'Kommentare';

  @override
  String get notifMembers => 'Mitglieder und Gruppenänderungen';

  @override
  String get notifReminders => 'Erinnerungen von Freunden';

  @override
  String get notifNeedConnection =>
      'Benachrichtigungseinstellungen brauchen eine Verbindung';

  @override
  String get notifOthersOnly =>
      'Nur Änderungen anderer Leute benachrichtigen dich.';

  @override
  String get notifWebNote =>
      'Benachrichtigungen gehen an dein Handy; der Browser aktualisiert sich jede Minute, solange er offen ist.';

  @override
  String get exportImport => 'Export & Import';

  @override
  String get noGroupsToExport => 'Keine Gruppen zum Exportieren.';

  @override
  String get nonGroup => 'Ohne Gruppe';

  @override
  String nonGroupWith(String name) {
    return 'Ohne Gruppe · $name';
  }

  @override
  String get exportJson => 'JSON exportieren';

  @override
  String get exportCsv => 'CSV exportieren';

  @override
  String get exportZip => 'ZIP mit Belegen';

  @override
  String get importSplitwise => 'Splitwise-CSV importieren';

  @override
  String importedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Ausgaben importiert',
      one: '1 Ausgabe importiert',
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
  String get serverSaved => 'Server-URL gespeichert';

  @override
  String get account => 'Konto';

  @override
  String get licenses => 'Lizenzen';

  @override
  String get deleteAccount => 'Konto löschen';

  @override
  String get signOutTitle => 'Abmelden?';

  @override
  String get signOutMessage =>
      'Die lokalen Daten auf diesem Gerät werden entfernt. Noch nicht synchronisierte Änderungen gehen verloren.';

  @override
  String get deleteAccountTitle => 'Konto löschen?';

  @override
  String get deleteAccountMessage =>
      'Deine Mitgliedschaften werden zu Platzhaltern. Die Gruppendaten bleiben bei den anderen Mitgliedern. Das lässt sich nicht rückgängig machen.';

  @override
  String get language => 'Sprache';

  @override
  String languageSystem(String language) {
    return 'System ($language)';
  }

  @override
  String get appearance => 'Darstellung';

  @override
  String get appearanceSystem => 'System';

  @override
  String get appearanceLight => 'Hell';

  @override
  String get appearanceDark => 'Dunkel';

  @override
  String get security => 'Sicherheit';

  @override
  String get appLock => 'App-Sperre';

  @override
  String get appLockHint =>
      'Face ID, Touch ID oder Fingerabdruck, mit dem Gerätecode als Ersatz. Sperrt nach einer Minute Abwesenheit.';

  @override
  String methodRemoveTitle(String method) {
    return '$method entfernen?';
  }

  @override
  String get methodsOffline =>
      'Verbinde dich mit dem Internet, um deine Zahlungswege zu bearbeiten.';

  @override
  String get methodsLoadFailed =>
      'Deine Zahlungswege konnten nicht geladen werden.';

  @override
  String get methodsIntro =>
      'Gruppenmitglieder sehen sie, wenn sie dir Geld schulden, damit sie dich mit einem Tipp bezahlen können. Evensies bewegt selbst nie Geld.';

  @override
  String get methodsEmpty => 'Noch keine Zahlungswege.';

  @override
  String get blurbPaypal => 'PayPal.me-Link, Betrag ausgefüllt';

  @override
  String get blurbWise => 'Wise-Quick-Pay-Link, Betrag ausgefüllt';

  @override
  String get blurbVenmo => 'Venmo-Benutzername (USA)';

  @override
  String get blurbRevolut => 'Revolut.me-Benutzername';

  @override
  String get blurbKakaopay => 'KakaoPay-송금코드-Link';

  @override
  String get blurbIban => 'Überweisung (SEPA-QR für EUR)';

  @override
  String get blurbKrBank => 'Koreanisches Bankkonto (Toss, Bank-Apps)';

  @override
  String get fieldPaypal => 'PayPal.me-Benutzername';

  @override
  String get fieldPaypalHint => 'Dein PayPal.me-Benutzername, z. B. anna';

  @override
  String get fieldRevolut => 'Revolut.me-Benutzername';

  @override
  String get fieldRevolutHint => 'Dein Revolut.me-Benutzername, z. B. anna';

  @override
  String get fieldVenmo => 'Venmo-Benutzername';

  @override
  String get fieldVenmoHint => 'Ohne das @, z. B. anna-rossi';

  @override
  String get fieldWise => 'Wise-Quick-Pay-Link';

  @override
  String get fieldWiseHint =>
      'In Wise: Zahlungen → Quick Pay → Link kopieren (https://wise.com/pay/…)';

  @override
  String get fieldKakaopay => 'KakaoPay-송금코드-Link';

  @override
  String get fieldKakaopayHint =>
      'In KakaoPay: 송금 → 송금코드 → Link kopieren (https://qr.kakaopay.com/…)';

  @override
  String get fieldHolder => 'Kontoinhaber';

  @override
  String get fieldHolderHint => 'Name genau wie auf dem Konto';

  @override
  String get fieldIban => 'IBAN';

  @override
  String get fieldIbanHint => 'z. B. DE89 3704 0044 0532 0130 00';

  @override
  String get fieldBic => 'BIC (optional)';

  @override
  String get fieldBicHint => '8 oder 11 Zeichen';

  @override
  String get fieldBank => 'Bank';

  @override
  String get fieldBankHint => 'z. B. 신한은행, Toss Bank';

  @override
  String get fieldAccountNumber => 'Kontonummer';

  @override
  String get fieldAccountNumberHint => 'Ziffern, Bindestriche optional';

  @override
  String amountCopied(String amount) {
    return 'Betrag kopiert: $amount';
  }

  @override
  String couldNotOpen(String link) {
    return '$link ließ sich nicht öffnen';
  }

  @override
  String get payOffline => 'Offline: Zahlungswege sind nicht verfügbar';

  @override
  String get payLoading => 'Zahlungswege werden geladen…';

  @override
  String payAskToAdd(String name) {
    return 'Bitte $name, einen Zahlungsweg hinzuzufügen';
  }

  @override
  String payTitle(String name, String amount) {
    return '$amount an $name zahlen';
  }

  @override
  String get payScanQr => 'Mit deiner Banking-App scannen (SEPA-QR)';

  @override
  String get payQrEurOnly =>
      'Der QR-Code ist nur für Überweisungen in EUR verfügbar.';

  @override
  String get bankLabel => 'Bank';

  @override
  String get ibanLabel => 'IBAN';

  @override
  String get accountLabel => 'Konto';

  @override
  String get bicLabel => 'BIC';

  @override
  String get holderLabel => 'Inhaber';

  @override
  String get amountLabel => 'Betrag';

  @override
  String get copyIban => 'IBAN kopieren';

  @override
  String get copyAccount => 'Konto kopieren';

  @override
  String get copyAmount => 'Betrag kopieren';

  @override
  String get ibanCopied => 'IBAN kopiert';

  @override
  String get accountCopied => 'Konto kopiert';

  @override
  String get paymentUpdated => 'Zahlung aktualisiert';

  @override
  String paymentRecordedPending(String amount, String name) {
    return '$amount erfasst. $name bestätigt es.';
  }

  @override
  String paymentRecordedPendingUnnamed(String amount) {
    return '$amount erfasst. Die andere Person bestätigt es.';
  }

  @override
  String paymentRecorded(String amount) {
    return 'Zahlung von $amount erfasst';
  }

  @override
  String youSuffix(String name) {
    return '$name (du)';
  }

  @override
  String get recordPayment => 'Zahlung erfassen';

  @override
  String get editPayment => 'Zahlung bearbeiten';

  @override
  String get fromLabel => 'Von';

  @override
  String get toLabel => 'An';

  @override
  String get swap => 'Tauschen';

  @override
  String get pickTwoPeople => 'Wähle zwei verschiedene Personen';

  @override
  String get commentsStayOld => 'Kommentare bleiben bei der alten Zahlung';

  @override
  String get recordPaymentButton => 'Zahlung erfassen';

  @override
  String get paymentNotHere => 'Diese Zahlung ist nicht auf diesem Gerät';

  @override
  String get notSyncedOrLeft =>
      'Sie wurde noch nicht synchronisiert, oder ihre Gruppe wurde verlassen.';

  @override
  String get someone => 'Jemand';

  @override
  String get paymentEdited => 'Bearbeitete Zahlung';

  @override
  String get paymentDeleted => 'Gelöschte Zahlung';

  @override
  String get payment => 'Zahlung';

  @override
  String get paymentWasEdited => 'Diese Zahlung wurde bearbeitet';

  @override
  String get paymentWasEditedNote =>
      'Stattdessen zählt die bearbeitete Zahlung. Ihre Kommentare bleiben hier.';

  @override
  String get paymentWasDeleted => 'Diese Zahlung wurde gelöscht';

  @override
  String get paymentNotCounted => 'Sie zählt nicht in den Salden.';

  @override
  String get restore => 'Wiederherstellen';

  @override
  String youPaidName(String name) {
    return 'Du hast $name bezahlt';
  }

  @override
  String namePaidYou(String name) {
    return '$name hat dich bezahlt';
  }

  @override
  String namePaidName(String from, String to) {
    return '$from hat $to bezahlt';
  }

  @override
  String paymentSaysSent(String name) {
    return '$name sagt, dass das an dich geschickt wurde. Ist es angekommen?';
  }

  @override
  String waitingForConfirm(String name) {
    return 'Wartet auf Bestätigung von $name';
  }

  @override
  String get notReceived => 'Nicht erhalten';

  @override
  String get confirmReceived => 'Erhalt bestätigen';

  @override
  String get deletePaymentTitle => 'Zahlung löschen?';

  @override
  String get deletePaymentMessage =>
      'Die Schuld, die sie beglichen hat, ist wieder da.';

  @override
  String get paymentDeletedSnack => 'Zahlung gelöscht';

  @override
  String get notReceivedTitle => 'Nicht erhalten?';

  @override
  String notReceivedMessage(String name) {
    return 'Die Zahlung von $name wird entfernt und die Schuld ist wieder da.';
  }

  @override
  String get paymentRemovedSnack => 'Zahlung entfernt';

  @override
  String get recordAPayment => 'Zahlung erfassen';

  @override
  String get nothingToSettle => 'Nichts zu begleichen';

  @override
  String get everyoneEven => 'Alle sind quitt.';

  @override
  String get waitingForConfirmation => 'Wartet auf Bestätigung';

  @override
  String get debtsAsRecorded =>
      'Schulden wie erfasst · Schulden vereinfachen ist aus';

  @override
  String transfersSettleEverything(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Überweisungen gleichen alles aus',
      one: '1 Überweisung gleicht alles aus',
    );
    return '$_temp0';
  }

  @override
  String transfersSettleBalance(int count, String currency) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Überweisungen gleichen den $currency-Saldo aus',
      one: '1 Überweisung gleicht den $currency-Saldo aus',
    );
    return '$_temp0';
  }

  @override
  String notConvertedSettlesIn(String currency) {
    return 'Nicht umgerechnet · $currency · wird in $currency beglichen';
  }

  @override
  String get convert => 'Umrechnen';

  @override
  String get settleUp => 'Begleichen';

  @override
  String saysTheySent(String name, String amount) {
    return '$name sagt, dir $amount geschickt zu haben';
  }

  @override
  String waitingToConfirmAmount(String name, String amount) {
    return 'Wartet, bis $name $amount bestätigt';
  }

  @override
  String get you => 'Du';

  @override
  String get request => 'Anfordern';

  @override
  String get iveSentIt => 'Ich habe es geschickt';

  @override
  String get markAsPaid => 'Als bezahlt markieren';

  @override
  String markedAsSent(String name) {
    return 'Als gesendet markiert. $name bestätigt es.';
  }

  @override
  String approx(String amount) {
    return '≈ $amount';
  }

  @override
  String friendOwesYou(String name, String amount) {
    return '$name schuldet dir $amount';
  }

  @override
  String friendYouOwe(String name, String amount) {
    return 'Du schuldest $name $amount';
  }

  @override
  String friendYouOweLine(String name, String amount) {
    return 'du schuldest $name $amount';
  }

  @override
  String noSharedGroup(String name) {
    return 'Du teilst keine Gruppe mehr mit $name. Schick deinen Freundeslink, um Ausgaben hinzuzufügen.';
  }

  @override
  String get shareFriendLink => 'Freundeslink teilen';

  @override
  String firstExpenseNeedsConnection(String name) {
    return 'Die erste Ausgabe mit $name braucht eine Verbindung.';
  }

  @override
  String reminderSent(String name) {
    return 'Erinnerung an $name geschickt';
  }

  @override
  String remindTomorrow(String name) {
    return 'Du kannst $name morgen wieder erinnern';
  }

  @override
  String remindNothingOwed(String name) {
    return '$name schuldet dir nichts';
  }

  @override
  String get remindNeedsConnection =>
      'Zum Erinnern brauchst du eine Verbindung.';

  @override
  String amountsAnd(String a, String b) {
    return '$a und $b';
  }

  @override
  String inviteFriendText(String link) {
    return 'Ich habe dich auf Evensies hinzugefügt, damit wir Ausgaben teilen können. Mach mit: $link';
  }

  @override
  String get personNotHere => 'Diese Person ist nicht auf diesem Gerät';

  @override
  String get personNotHereNote =>
      'Sie wurde noch nicht synchronisiert, oder ihr teilt keine Gruppe mehr.';

  @override
  String get more => 'Mehr';

  @override
  String get exportNonGroupCsv => 'Ausgaben ohne Gruppe exportieren (CSV)';

  @override
  String get exportNonGroupJson => 'Ausgaben ohne Gruppe exportieren (JSON)';

  @override
  String get exportNonGroupZip =>
      'Ausgaben ohne Gruppe exportieren (ZIP mit Belegen)';

  @override
  String get notOnEvensies => 'Noch nicht auf Evensies';

  @override
  String get allSettledUp => 'Alles ausgeglichen';

  @override
  String get remind => 'Erinnern';

  @override
  String get invite => 'Einladen';

  @override
  String get balances => 'Salden';

  @override
  String get expensesAndPayments => 'Ausgaben und Zahlungen';

  @override
  String get nothingTogetherYet =>
      'Noch nichts zusammen. Füge unten eine Ausgabe hinzu.';

  @override
  String get addExpense => 'Ausgabe hinzufügen';

  @override
  String personOwesYou(String amount) {
    return 'schuldet dir $amount';
  }

  @override
  String personYouOwe(String amount) {
    return 'du schuldest $amount';
  }

  @override
  String get personSettledUp => 'ausgeglichen';

  @override
  String recordedInGroups(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'In $count Gruppen erfasst',
      one: 'In 1 Gruppe erfasst',
    );
    return '$_temp0';
  }

  @override
  String get markAsReceived => 'Als erhalten markieren';

  @override
  String get clearBothSides => 'Beide Seiten ausgleichen';

  @override
  String evenIn(String currency) {
    return 'Quitt in $currency';
  }

  @override
  String linePayThem(String group, String name, String amount) {
    return '$group: du zahlst $name $amount';
  }

  @override
  String lineTheyPay(String group, String name, String amount) {
    return '$group: $name zahlt dir $amount';
  }

  @override
  String get noMoneyMoves =>
      'Es fließt kein Geld: Beide Seiten werden als beglichen erfasst.';

  @override
  String convertIn(String group) {
    return 'In $group umrechnen';
  }

  @override
  String settleUpWith(String name) {
    return 'Mit $name begleichen';
  }

  @override
  String nothingToSettleWith(String name) {
    return 'Nichts mit $name zu begleichen';
  }

  @override
  String settleWithIntro(String name) {
    return 'Alles zwischen dir und $name, pro Währung. Beim Erfassen kommt in jeder Gruppe eine Zahlung hinzu.';
  }

  @override
  String get searchFriendsGroups => 'Freunde und Gruppen suchen';

  @override
  String get friends => 'Freunde';

  @override
  String get groups => 'Gruppen';

  @override
  String get noFriendsOrGroups => 'Noch keine Freunde oder Gruppen.';

  @override
  String nothingMatches(String query) {
    return 'Nichts passt zu „$query“.';
  }

  @override
  String get addExpenseWithWhom => 'Ausgabe hinzufügen · mit wem?';

  @override
  String friendLinkShare(String link, String code) {
    return 'Füg mich auf Evensies hinzu, um Ausgaben zu teilen: $link\nOder gib meinen Code $code ein';
  }

  @override
  String get friendLinkNeedsConnection =>
      'Zum Teilen deines Freundeslinks brauchst du eine Verbindung.';

  @override
  String get selfFriend => 'Das ist dein eigener Code';

  @override
  String get noOneForCode => 'Niemand mit diesem Code gefunden';

  @override
  String get addFriendNeedsConnection =>
      'Zum Hinzufügen eines Freundes brauchst du eine Verbindung.';

  @override
  String get newFriendCodeTitle => 'Neuen Freundescode erstellen?';

  @override
  String get newFriendCodeMessage =>
      'Dein aktueller Link und Code funktionieren dann nicht mehr. Bestehende Freunde bleiben.';

  @override
  String get newCode => 'Neuer Code';

  @override
  String get addAFriend => 'Freund hinzufügen';

  @override
  String get friendLinkOffline => 'Dein Freundeslink braucht eine Verbindung';

  @override
  String get yourFriendCode => 'Dein Freundescode';

  @override
  String get friendQrLabel => 'QR-Code deines Freundeslinks';

  @override
  String get friendCodeHelp =>
      'Freunde scannen ihn, öffnen den Link oder tippen den Code ein.';

  @override
  String get shareLink => 'Link teilen';

  @override
  String get codeCopied => 'Code kopiert';

  @override
  String get copyCode => 'Code kopieren';

  @override
  String get haveFriendCode => 'Hast du den Code eines Freundes?';

  @override
  String get onEvensies => 'auf Evensies';

  @override
  String get notOnEvensiesSection => 'Jemand, der noch nicht auf Evensies ist';

  @override
  String get notOnEvensiesHelp =>
      'Füge gleich Ausgaben mit dieser Person hinzu und lade sie später ein.';

  @override
  String atMostChars(int max) {
    return 'Höchstens $max Zeichen';
  }

  @override
  String addName(String name) {
    return '$name hinzufügen';
  }

  @override
  String get search => 'Suchen';

  @override
  String get activity => 'Aktivität';

  @override
  String get newGroup => 'Neue Gruppe';

  @override
  String get joinWithCode => 'Mit Code beitreten';

  @override
  String get filterAll => 'Alle';

  @override
  String get filterOwesMe => 'Schuldet mir';

  @override
  String get filterIOwe => 'Ich schulde';

  @override
  String settledUpCount(int count) {
    return 'Ausgeglichen ($count)';
  }

  @override
  String get nobodyOwesYou => 'Niemand schuldet dir etwas';

  @override
  String get youOweNothing => 'Du schuldest nichts';

  @override
  String get nothingHereYet => 'Hier ist noch nichts';

  @override
  String get noFriendsYet => 'Noch keine Freunde';

  @override
  String get noFriendsHelp =>
      'Füge einen Freund hinzu, um Ausgaben außerhalb einer Gruppe zu teilen. Leute, mit denen du eine Gruppe teilst, erscheinen auch hier.';

  @override
  String get allSettledUpYou => 'Bei dir ist alles ausgeglichen';

  @override
  String youAreOwedList(String amounts) {
    return 'Du bekommst $amounts';
  }

  @override
  String youOweList(String amounts) {
    return 'Du schuldest $amounts';
  }

  @override
  String get notOnEvensiesLower => 'noch nicht auf Evensies';

  @override
  String get noGroupsYet => 'Noch keine Gruppen';

  @override
  String get noGroupsHelp =>
      'Erstelle eine für eine Reise oder eine WG, oder tritt mit dem Einladungscode der Gruppe eines Freundes bei.';

  @override
  String get createGroup => 'Gruppe erstellen';

  @override
  String get settledUp => 'Ausgeglichen';

  @override
  String netApprox(String amount) {
    return 'Netto ≈ $amount';
  }

  @override
  String memberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Mitglieder',
      one: '1 Mitglied',
    );
    return '$_temp0';
  }

  @override
  String youOweAmount(String amount) {
    return 'Du schuldest $amount';
  }

  @override
  String youAreOwedAmount(String amount) {
    return 'Du bekommst $amount';
  }

  @override
  String youOweAmountLine(String amount) {
    return 'du schuldest $amount';
  }

  @override
  String youAreOwedAmountLine(String amount) {
    return 'du bekommst $amount';
  }

  @override
  String get createGroupNeedsConnection =>
      'Zum Erstellen einer Gruppe brauchst du eine Verbindung.';

  @override
  String get groupName => 'Gruppenname';

  @override
  String get yourNameInGroup => 'Dein Name in dieser Gruppe';

  @override
  String get defaultCurrency => 'Standardwährung';

  @override
  String get create => 'Erstellen';

  @override
  String get noGroupOrFriendForCode =>
      'Keine Gruppe und kein Freund mit diesem Code gefunden';

  @override
  String get joinNeedsConnection =>
      'Zum Beitreten brauchst du eine Verbindung.';

  @override
  String get enterACode => 'Code eingeben';

  @override
  String get enterCodeHelp =>
      'Ein Gruppencode steht in der Gruppe → Mitglieder. Ein Freundescode steht im Freunde-Tab → Freund hinzufügen.';

  @override
  String get pastedFromClipboard => 'Aus der Zwischenablage eingefügt';

  @override
  String nameOnEvensies(String name) {
    return '$name · auf Evensies';
  }

  @override
  String addAsFriend(String name) {
    return '$name als Freund hinzufügen';
  }

  @override
  String addedYouAsFriend(String name) {
    return '$name hat dich als Freund hinzugefügt';
  }

  @override
  String get someoneAddedYouAsFriend =>
      'Jemand hat dich als Freund hinzugefügt';

  @override
  String groupPreview(String name, String members) {
    return '$name · $members';
  }

  @override
  String get continueButton => 'Weiter';

  @override
  String wantsToSplit(String name) {
    return '$name möchte Ausgaben mit dir teilen';
  }

  @override
  String get joinGroup => 'Gruppe beitreten';

  @override
  String get inviteInvalid => 'Dieser Einladungslink ist nicht mehr gültig';

  @override
  String inviteFailed(String reason) {
    return 'Diese Einladung ließ sich nicht öffnen: $reason';
  }

  @override
  String get friendInviteUsed =>
      'Diese Freundeseinladung wurde schon verwendet';

  @override
  String get joinToSeeShared =>
      'Tritt bei, um eure gemeinsamen Ausgaben zu sehen und hinzuzufügen.';

  @override
  String imName(String name) {
    return 'Ich bin $name';
  }

  @override
  String get join => 'Beitreten';

  @override
  String get whoAreYou => 'Wer bist du?';

  @override
  String get newMemberName => 'Name des neuen Mitglieds';

  @override
  String get insights => 'Statistik';

  @override
  String get membersInvite => 'Mitglieder & Einladung';

  @override
  String get groupSettings => 'Gruppeneinstellungen';

  @override
  String get expenses => 'Ausgaben';

  @override
  String get expenseFab => 'Ausgabe';

  @override
  String get groupNotHere => 'Diese Gruppe ist nicht auf diesem Gerät';

  @override
  String get groupNotHereNote =>
      'Du hast sie verlassen, wurdest entfernt, oder sie wurde noch nicht synchronisiert.';

  @override
  String get backToGroups => 'Zurück zu den Gruppen';

  @override
  String get noExpensesYet => 'Noch keine Ausgaben';

  @override
  String get tapExpenseToAdd =>
      'Tippe auf „Ausgabe“, um die erste hinzuzufügen.';

  @override
  String tilePaidYou(String amount) {
    return 'du hast $amount bezahlt';
  }

  @override
  String tilePaidName(String name, String amount) {
    return '$name hat $amount bezahlt';
  }

  @override
  String tilePaidPeople(int count, String amount) {
    return '$count Personen haben $amount bezahlt';
  }

  @override
  String get tileRefundYou => 'Erstattung an dich';

  @override
  String tileRefundName(String name) {
    return 'Erstattung an $name';
  }

  @override
  String tileRefundPeople(int count) {
    return 'Erstattung an $count Personen';
  }

  @override
  String get notInvolved => 'nicht beteiligt';

  @override
  String get allYours => 'alles deins';

  @override
  String get paidForYourself => 'du hast für dich selbst bezahlt';

  @override
  String youGetBack(String amount) {
    return 'du bekommst $amount zurück';
  }

  @override
  String youLent(String amount) {
    return 'du hast $amount ausgelegt';
  }

  @override
  String youBorrowed(String amount) {
    return 'du hast $amount geliehen';
  }

  @override
  String get repeatsLabel => 'Wiederholt sich';

  @override
  String hasReceipt(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Hat $count Belege',
      one: 'Hat einen Beleg',
    );
    return '$_temp0';
  }

  @override
  String get refund => 'Erstattung';

  @override
  String get notConverted => 'Nicht umgerechnet';

  @override
  String get pending => 'offen';

  @override
  String approxTotalOwe(String amount) {
    return 'Du schuldest insgesamt ≈ $amount';
  }

  @override
  String approxTotalOwed(String amount) {
    return 'Du bekommst insgesamt ≈ $amount';
  }

  @override
  String get approxTotalNote =>
      'In deiner Heimatwährung, zu den neuesten Kursen';

  @override
  String nothingOwedIn(String currency) {
    return 'Nichts geschuldet in $currency';
  }

  @override
  String get allSettled => 'Alles ausgeglichen';

  @override
  String get otherCurrenciesBelow =>
      'Ausgaben in anderen Währungen stehen unten.';

  @override
  String get nobodyOwes => 'Niemand schuldet etwas.';

  @override
  String youPayNext(String amount) {
    return 'Du solltest als Nächstes zahlen (du schuldest $amount, am meisten)';
  }

  @override
  String namePaysNext(String name, String amount) {
    return '$name sollte als Nächstes zahlen (schuldet $amount, am meisten)';
  }

  @override
  String settleUpWaiting(int count) {
    return 'Begleichen · $count warten';
  }

  @override
  String memberRemoved(String name) {
    return '$name (entfernt)';
  }

  @override
  String expensesWithoutRate(int count, String currency) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Ausgaben ohne Kurs zu $currency',
      one: '1 Ausgabe ohne Kurs zu $currency',
    );
    return '$_temp0';
  }

  @override
  String expensesBadRate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count Ausgaben mit einem Kurs, der nicht umgerechnet werden kann',
      one: '1 Ausgabe mit einem Kurs, der nicht umgerechnet werden kann',
    );
    return '$_temp0';
  }

  @override
  String paymentsIn(String currency) {
    return 'Zahlungen in $currency';
  }

  @override
  String everyoneEvenIn(String currency) {
    return 'alle sind quitt in $currency';
  }

  @override
  String convertTo(String currency) {
    return 'In $currency umrechnen';
  }

  @override
  String get balanceSettled => 'ausgeglichen';

  @override
  String get balanceGetsBack => 'bekommt';

  @override
  String get balanceOwes => 'schuldet';

  @override
  String convertedCount(int count, String currency) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Ausgaben in $currency umgerechnet',
      one: '1 Ausgabe in $currency umgerechnet',
    );
    return '$_temp0';
  }

  @override
  String get noAutoRate => 'Kein automatischer Kurs. Gib einen ein.';

  @override
  String rateOf(String date) {
    return 'Kurs vom $date';
  }

  @override
  String rateOfOffline(String date) {
    return 'offline · Kurs vom $date';
  }

  @override
  String amountCountExpenses(String amount, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Ausgaben',
      one: '1 Ausgabe',
    );
    return '$amount · $_temp0';
  }

  @override
  String paymentsStayIn(String currency) {
    return 'Zahlungen in $currency bleiben in $currency';
  }

  @override
  String rateLabel(String from, String to) {
    return 'Kurs: 1 $from in $to';
  }

  @override
  String get nothingLeftToConvert => 'Nichts mehr umzurechnen';

  @override
  String get lookingUpRate => 'Kurs wird gesucht…';

  @override
  String get enterRateAbove0 => 'Gib einen Kurs über 0 ein';

  @override
  String convertExplain(String currency) {
    return 'Trägt diesen Kurs bei jeder Ausgabe ohne Kurs ein, damit sie in den $currency-Salden zählt. Du kannst den Kurs bei jeder Ausgabe noch ändern.';
  }

  @override
  String get nameField => 'Name';

  @override
  String get cantChangeCurrency =>
      'Nach der ersten Ausgabe oder Zahlung nicht mehr änderbar';

  @override
  String get currencyUsedFor => 'Salden und Zahlungen verwenden sie';

  @override
  String get splitting => 'Aufteilen';

  @override
  String get simplifyDebts => 'Schulden vereinfachen';

  @override
  String get simplifyDebtsHelp =>
      'Fasst Schulden zusammen, damit die Gruppe weniger Zahlungen braucht. Niemandes Gesamtbetrag ändert sich, nur wer wem zahlt.';

  @override
  String get defaultSplit => 'Standardaufteilung';

  @override
  String get splitStale => 'Geht nicht mehr auf · zum Korrigieren tippen';

  @override
  String get membership => 'Mitgliedschaft';

  @override
  String get leaveGroup => 'Gruppe verlassen';

  @override
  String get balanceSettledNote => 'Dein Saldo ist ausgeglichen';

  @override
  String get renameGroup => 'Gruppe umbenennen';

  @override
  String leaveTitle(String name) {
    return '„$name“ verlassen?';
  }

  @override
  String get leaveMessage =>
      'Du siehst diese Gruppe dann nicht mehr. Deine bisherigen Ausgaben bleiben bei den anderen Mitgliedern. Um zurückzukommen, frag nach dem Einladungscode.';

  @override
  String get leave => 'Verlassen';

  @override
  String youLeft(String name) {
    return 'Du hast „$name“ verlassen';
  }

  @override
  String get splitEqualEveryone => 'Gleich · alle';

  @override
  String splitPercentList(String list) {
    return 'Prozent · $list';
  }

  @override
  String splitSharesList(String list) {
    return 'Anteile · $list';
  }

  @override
  String percentValue(String value) {
    return '$value %';
  }

  @override
  String get defaultSplitHelp =>
      'Neue Ausgaben beginnen mit dieser Aufteilung. Du kannst sie bei jeder Ausgabe noch ändern.';

  @override
  String get useEqual => 'Gleich verwenden';

  @override
  String get inviteCode => 'Einladungscode';

  @override
  String get inviteQrLabel => 'QR-Code des Einladungslinks';

  @override
  String get inviteCodeHelp =>
      'Wer diesen Code hat, kann beitreten und seinen Namen wählen.';

  @override
  String inviteShareText(String group, String link, String code) {
    return 'Tritt meiner Gruppe „$group“ auf Evensies bei: $link\nOder öffne die App und gib den Code $code ein';
  }

  @override
  String get rotateCode => 'Code erneuern';

  @override
  String get members => 'Mitglieder';

  @override
  String get notJoinedYet =>
      'noch nicht beigetreten – teile den Einladungscode';

  @override
  String get linked => 'verknüpft';

  @override
  String get addPlaceholder => 'Platzhalter-Mitglied hinzufügen';

  @override
  String removeMemberTitle(String name) {
    return '$name entfernen?';
  }

  @override
  String get removeMemberMessage =>
      'Die bisherigen Ausgaben und der Saldo bleiben in der Gruppe.';

  @override
  String removeMemberSeries(int count, String name, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$name ist noch in $count wiederkehrenden Ausgaben ($names); der Anteil von $name bleibt, bis du die neueste bearbeitest.',
      one:
          '$name ist noch in 1 wiederkehrenden Ausgabe ($names); der Anteil von $name bleibt, bis du die neueste bearbeitest.',
    );
    return '$_temp0';
  }

  @override
  String get addMember => 'Mitglied hinzufügen';

  @override
  String get rotateInviteTitle => 'Einladungscode erneuern?';

  @override
  String get rotateInviteMessage =>
      'Der aktuelle Code und Link funktionieren dann nicht mehr. Wer schon beigetreten ist, ist nicht betroffen.';

  @override
  String get rotate => 'Erneuern';

  @override
  String get newInviteReady => 'Neuer Einladungscode bereit';

  @override
  String get activityNeedsConnection => 'Aktivität braucht eine Verbindung';

  @override
  String get activityOfflineNote =>
      'Neue Änderungen erscheinen hier, sobald du wieder online bist.';

  @override
  String get noActivityYet => 'Noch keine Aktivität';

  @override
  String get activityAllGroups =>
      'Änderungen in deinen Gruppen erscheinen hier.';

  @override
  String get activityThisGroup =>
      'Änderungen in dieser Gruppe erscheinen hier.';

  @override
  String get showingSaved =>
      'Gespeicherte Aktivität. Zum Aktualisieren ziehen.';

  @override
  String get loadMore => 'Mehr laden';

  @override
  String get earlier => 'Früher';

  @override
  String get today => 'Heute';

  @override
  String get yesterday => 'Gestern';

  @override
  String forDate(String date) {
    return 'für $date';
  }

  @override
  String get youCommented => 'Du hast kommentiert';

  @override
  String nameCommented(String name) {
    return '$name hat kommentiert';
  }

  @override
  String restoredName(String name) {
    return '„$name“ wiederhergestellt';
  }

  @override
  String get paymentRestored => 'Zahlung wiederhergestellt';

  @override
  String get expenseNotHere => 'Diese Ausgabe ist nicht auf diesem Gerät';

  @override
  String get deletedExpense => 'Gelöschte Ausgabe';

  @override
  String get expense => 'Ausgabe';

  @override
  String seriesRepeats(String frequency) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Wiederholt sich jede Woche',
      'biweekly': 'Wiederholt sich alle 2 Wochen',
      'monthly': 'Wiederholt sich jeden Monat',
      'yearly': 'Wiederholt sich jedes Jahr',
      'other': 'Wiederholt sich',
    });
    return '$_temp0';
  }

  @override
  String seriesRepeatsNext(String frequency, String date) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Wiederholt sich jede Woche · nächste am $date',
      'biweekly': 'Wiederholt sich alle 2 Wochen · nächste am $date',
      'monthly': 'Wiederholt sich jeden Monat · nächste am $date',
      'yearly': 'Wiederholt sich jedes Jahr · nächste am $date',
      'other': 'Wiederholt sich · nächste am $date',
    });
    return '$_temp0';
  }

  @override
  String seriesRepeatsNextAmount(String frequency, String amount, String date) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Wiederholt sich jede Woche · nächste $amount am $date',
      'biweekly': 'Wiederholt sich alle 2 Wochen · nächste $amount am $date',
      'monthly': 'Wiederholt sich jeden Monat · nächste $amount am $date',
      'yearly': 'Wiederholt sich jedes Jahr · nächste $amount am $date',
      'other': 'Wiederholt sich · nächste $amount am $date',
    });
    return '$_temp0';
  }

  @override
  String rateLine(String from, String rate, String to) {
    return 'Kurs: 1 $from = $rate $to';
  }

  @override
  String notConvertedTo(String currency) {
    return 'Nicht in $currency umgerechnet';
  }

  @override
  String get receivedSplitBack => 'Erhalten und zurückverteilt';

  @override
  String get whoPaidOwes => 'Wer hat bezahlt und wer schuldet';

  @override
  String get items => 'Posten';

  @override
  String get notes => 'Notizen';

  @override
  String get receipts => 'Belege';

  @override
  String get history => 'Verlauf';

  @override
  String get deleteExpenseTitle => 'Ausgabe löschen?';

  @override
  String get deleteExpenseMessage =>
      'Sie wird für alle in der Gruppe entfernt. Du kannst sie über die Aktivität wiederherstellen.';

  @override
  String get deleteRepeatingTitle => 'Wiederkehrende Ausgabe löschen?';

  @override
  String get deleteRepeatingMessage =>
      'Sie wird für alle in der Gruppe entfernt. Du kannst sie über die Aktivität wiederherstellen, aber eine beendete Wiederholung lässt sich nicht neu starten. Bereits hinzugefügte Wiederholungen bleiben.';

  @override
  String get deleteThisOne => 'Nur diese löschen';

  @override
  String get deleteAndStop => 'Löschen und Wiederholung beenden';

  @override
  String deletedAndStopped(String name) {
    return '„$name“ gelöscht und Wiederholung beendet';
  }

  @override
  String deletedName(String name) {
    return '„$name“ gelöscht';
  }

  @override
  String get movedToOtherGroup => 'In eine andere Gruppe verschoben';

  @override
  String get movedNote =>
      'Sie zählt jetzt dort. Kommentare und Verlauf bleiben hier.';

  @override
  String get expenseWasDeleted => 'Diese Ausgabe wurde gelöscht';

  @override
  String get restoreToCount =>
      'Stell sie wieder her, damit sie wieder in den Salden zählt.';

  @override
  String get tax => 'Steuer';

  @override
  String get tipService => 'Trinkgeld oder Service';

  @override
  String get discount => 'Rabatt';

  @override
  String youPaidOwe(String paid, String owe) {
    return 'Du hast $paid bezahlt und schuldest $owe';
  }

  @override
  String youPaid(String amount) {
    return 'Du hast $amount bezahlt';
  }

  @override
  String youOwe(String amount) {
    return 'Du schuldest $amount';
  }

  @override
  String namePaidOwes(String name, String paid, String owe) {
    return '$name hat $paid bezahlt und schuldet $owe';
  }

  @override
  String namePaid(String name, String amount) {
    return '$name hat $amount bezahlt';
  }

  @override
  String nameOwes(String name, String amount) {
    return '$name schuldet $amount';
  }

  @override
  String youReceivedGetBack(String received, String back) {
    return 'Du hast $received erhalten und bekommst $back zurück';
  }

  @override
  String youReceived(String amount) {
    return 'Du hast $amount erhalten';
  }

  @override
  String youGetBackLine(String amount) {
    return 'Du bekommst $amount zurück';
  }

  @override
  String nameReceivedGetsBack(String name, String received, String back) {
    return '$name hat $received erhalten und bekommt $back zurück';
  }

  @override
  String nameReceived(String name, String amount) {
    return '$name hat $amount erhalten';
  }

  @override
  String nameGetsBack(String name, String amount) {
    return '$name bekommt $amount zurück';
  }

  @override
  String get noHistoryYet => 'Noch kein Verlauf.';

  @override
  String get historyOffline =>
      'Der Verlauf erscheint hier, sobald du online bist.';

  @override
  String get showingSavedHistory => 'Gespeicherter Verlauf.';

  @override
  String get showMore => 'Mehr anzeigen';

  @override
  String get deleteCommentTitle => 'Kommentar löschen?';

  @override
  String get comments => 'Kommentare';

  @override
  String get noCommentsYet => 'Noch keine Kommentare.';

  @override
  String get deleteComment => 'Kommentar löschen';

  @override
  String get addComment => 'Kommentar hinzufügen';

  @override
  String get send => 'Senden';

  @override
  String get filterByCategory => 'Nach Kategorie filtern';

  @override
  String get category => 'Kategorie';

  @override
  String get categoryAll => 'Alle';

  @override
  String get month => 'Monat';

  @override
  String get searchUnavailable => 'Suche ist nicht verfügbar';

  @override
  String get searchExpenses => 'Ausgaben suchen';

  @override
  String get searchHelp =>
      'Beschreibungen, Notizen, Kommentare, Kategorien und Beträge: „Taxi“, „Flughafen“, „12,50“.';

  @override
  String get noMatches => 'Keine Treffer';

  @override
  String get noMatchesHelp =>
      'Versuch ein anderes Wort oder entferne einen Filter.';

  @override
  String expenseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Ausgaben',
      one: '1 Ausgabe',
    );
    return '$_temp0';
  }

  @override
  String get searchAllGroups => 'Alle Gruppen durchsuchen';

  @override
  String searchGroup(String name) {
    return '$name durchsuchen';
  }

  @override
  String get searchThisGroup => 'Diese Gruppe durchsuchen';

  @override
  String get clear => 'Leeren';

  @override
  String get thisGroup => 'Diese Gruppe';

  @override
  String insightsError(String reason) {
    return 'Die Statistik kann nicht angezeigt werden: $reason';
  }

  @override
  String get nothingToShow => 'Noch nichts anzuzeigen';

  @override
  String get insightsEmptyHelp =>
      'Summen und Diagramme erscheinen, sobald die Gruppe Ausgaben hat.';

  @override
  String get allTime => 'Gesamter Zeitraum';

  @override
  String get shareSummary => 'Zusammenfassung teilen';

  @override
  String get printSummary => 'Zusammenfassung drucken';

  @override
  String get previousMonth => 'Vorheriger Monat';

  @override
  String get nextMonth => 'Nächster Monat';

  @override
  String get byMonth => 'Nach Monat';

  @override
  String get groupSegment => 'Gruppe';

  @override
  String get mineSegment => 'Meins';

  @override
  String get byCategory => 'Nach Kategorie';

  @override
  String get noExpensesPeriod => 'Keine Ausgaben in diesem Zeitraum.';

  @override
  String get byPerson => 'Nach Person';

  @override
  String get nobodyPaidPeriod =>
      'In diesem Zeitraum hat niemand etwas bezahlt oder geschuldet.';

  @override
  String keptUntilConverted(String currency, String group) {
    return 'Bleibt in $currency, bis es in $group umgerechnet ist.';
  }

  @override
  String get totalSpent => 'Gesamt ausgegeben';

  @override
  String get yourShare => 'Dein Anteil';

  @override
  String get paymentsMade => 'Gezahlt';

  @override
  String get paymentsReceived => 'Erhalten';

  @override
  String get youPaidRow => 'Du hast bezahlt';

  @override
  String get balanceChange => 'Änderung deines Saldos';

  @override
  String get paidLegend => 'Bezahlt';

  @override
  String get shareLegend => 'Anteil';

  @override
  String paidShareLine(String paid, String share) {
    return 'bezahlt $paid · Anteil $share';
  }

  @override
  String get itemsGiveEveryone => 'Gib jedem Posten eine Person';

  @override
  String get itemsAddPrices =>
      'Gib die Preise der Posten vor Steuer oder Trinkgeld ein';

  @override
  String get itemsDiscountTooBig => 'Der Rabatt ist größer als die Rechnung';

  @override
  String get itemsDontAddUp => 'Die Posten gehen nicht auf';

  @override
  String get adjustmentsDontFit => 'Die Anpassungen passen nicht zur Summe';

  @override
  String get giveSomeoneShare => 'Gib jemandem einen Anteil';

  @override
  String get checkNumbers => 'Prüfe die Zahlen';

  @override
  String get splitDoesntAddUp => 'Die Aufteilung geht nicht auf';

  @override
  String get addTheItems => 'Füge die Posten hinzu';

  @override
  String get pickOnePerson => 'Wähle mindestens eine Person';

  @override
  String splitEquallyBetween(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Gleich aufgeteilt auf $count Personen',
      one: 'Gleich aufgeteilt auf 1 Person',
    );
    return '$_temp0';
  }

  @override
  String get allForOnePerson => 'Alles für 1 Person';

  @override
  String splitEquallyEach(int count, String amount) {
    return 'Gleich aufgeteilt auf $count Personen · je $amount';
  }

  @override
  String get checkAmounts => 'Prüfe die Beträge';

  @override
  String get enterTotalFirst => 'Gib zuerst die Summe ein';

  @override
  String remaining(String amount) {
    return 'offen: $amount';
  }

  @override
  String overBy(String amount) {
    return 'zu viel: $amount';
  }

  @override
  String get addsUp => 'Geht auf';

  @override
  String sharesInTotal(String count) {
    return '$count Anteile insgesamt';
  }

  @override
  String get oneShareInTotal => '1 Anteil insgesamt';

  @override
  String get restSplitEqually => 'Der Rest wird gleich aufgeteilt';

  @override
  String get byPercent => 'Nach Prozent';

  @override
  String get byShares => 'Nach Anteilen';

  @override
  String get byAdjustment =>
      'Anpassen: mehr oder weniger für jemanden, der Rest gleich';

  @override
  String get modeEqual => 'Gleich';

  @override
  String get modeExact => 'Genau';

  @override
  String get modeShares => 'Anteile';

  @override
  String get byItem => 'Nach Posten, vom Beleg';

  @override
  String get adjustmentHelp =>
      'Füge für jemanden einen Betrag hinzu oder zieh ihn ab; der Rest wird gleich aufgeteilt.';

  @override
  String get noMembers => 'Keine Mitglieder';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Posten',
      one: '1 Posten',
    );
    return '$_temp0';
  }

  @override
  String get addAnItem => 'Füge einen Posten hinzu';

  @override
  String atMostItems(int max) {
    return 'Höchstens $max Posten';
  }

  @override
  String get giveItemName => 'Gib jedem Posten einen Namen';

  @override
  String get itemNameTooLong => 'Ein Postenname ist zu lang';

  @override
  String get addItem => 'Posten hinzufügen';

  @override
  String get giveRestToEveryone => 'Den Rest allen geben';

  @override
  String get subtotal => 'Zwischensumme';

  @override
  String get total => 'Summe';

  @override
  String receiptSays(String printed, String difference) {
    return 'Beleg sagt $printed · Posten weichen um $difference ab';
  }

  @override
  String get eachPerson => 'Pro Person';

  @override
  String itemsWithoutPerson(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Posten ohne Person',
      one: '1 Posten ohne Person',
    );
    return '$_temp0';
  }

  @override
  String get itemHint => 'Posten';

  @override
  String memberLeft(String name) {
    return '$name (ausgetreten)';
  }

  @override
  String get whoHadThis => 'Wer hatte das?';

  @override
  String get defaultSplitStartsEqual =>
      'Die Standardaufteilung der Gruppe geht nicht mehr auf, deshalb beginnt diese gleich';

  @override
  String leftToAssign(String amount) {
    return 'Noch $amount zu verteilen';
  }

  @override
  String get itemsTotal => 'Die Summe der Posten';

  @override
  String get newExpense => 'Neue Ausgabe';

  @override
  String get editExpense => 'Ausgabe bearbeiten';

  @override
  String get scanReceipt => 'Beleg scannen';

  @override
  String get rateAboveZeroOrEmpty =>
      'Gib einen Kurs über 0 ein oder lass das Feld leer';

  @override
  String useAutoRate(String rate, String source) {
    return 'Automatischen Kurs verwenden: $rate ($source)';
  }

  @override
  String get description => 'Beschreibung';

  @override
  String get receivedBy => 'Erhalten von';

  @override
  String get paidBy => 'Bezahlt von';

  @override
  String get severalPeople => 'Mehrere Personen';

  @override
  String get when => 'Wann';

  @override
  String get refundTooltip =>
      'Geld, das zurückkam, z. B. die Kaution vom Hotel';

  @override
  String get splitBackTo => 'Zurückverteilt an';

  @override
  String get split => 'Aufteilung';

  @override
  String theyOweFull(String name) {
    return '$name schuldet den vollen Betrag';
  }

  @override
  String iOweFull(String name) {
    return 'Ich schulde $name den vollen Betrag';
  }

  @override
  String get repeat => 'Wiederholen';

  @override
  String editLatestRepeat(String date) {
    return 'Um künftige Wiederholungen zu ändern, bearbeite die neueste ($date)';
  }

  @override
  String get stopsRepeating =>
      'Beendet die Wiederholung. Bereits hinzugefügte Wiederholungen bleiben.';

  @override
  String nextRepeat(String date) {
    return 'Nächste: $date';
  }

  @override
  String get alsoChangeFuture => 'Auch künftige Wiederholungen ändern';

  @override
  String get futureFields =>
      'Betrag, Aufteilung, Zahlende, Beschreibung, Kategorie und Notizen';

  @override
  String get onlyThisOne => 'Nur diese ändert sich';

  @override
  String get addPhoto => 'Foto hinzufügen';

  @override
  String maxReceiptsNote(int max) {
    return '$max Belege sind das Maximum für eine Ausgabe';
  }

  @override
  String get scanAReceipt => 'Einen Beleg scannen';

  @override
  String receiptLooksLike(String currency) {
    return 'Dieser Beleg sieht nach $currency aus';
  }

  @override
  String switchToCurrencyQuestion(String currency) {
    return 'Die Ausgabe auf $currency umstellen, um die Posten zu lesen?';
  }

  @override
  String switchTo(String currency) {
    return 'Auf $currency umstellen';
  }

  @override
  String get couldntReadItems =>
      'Die Posten konnten nicht gelesen werden. Gib sie ein.';

  @override
  String withName(String name) {
    return 'Mit $name';
  }

  @override
  String movesTo(String name) {
    return 'Wird beim Speichern nach $name verschoben';
  }

  @override
  String fromName(String name) {
    return 'Aus $name';
  }

  @override
  String get dontMove => 'Nicht verschieben';

  @override
  String get onlyLinkedMove =>
      'Nur Leute auf Evensies, die in beiden sind, können verschoben werden';

  @override
  String get auto => 'auto';

  @override
  String get noAutoRateForm =>
      'Kein automatischer Kurs. Gib einen ein oder lass das Feld leer, damit es unter „Nicht umgerechnet“ bleibt.';

  @override
  String get emptyNotConverted => 'Leer: das bleibt unter „Nicht umgerechnet“';

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
  String get yourRate => 'dein Kurs';

  @override
  String get loginEmail => 'Weiter mit E-Mail';

  @override
  String get emailLoginTitle => 'Mit E-Mail anmelden';

  @override
  String get emailLoginIntro =>
      'Wir schicken dir einen 6-stelligen Code per E-Mail. Ein Passwort brauchst du nicht.';

  @override
  String get emailLabel => 'E-Mail';

  @override
  String get emailInvalid => 'Gib eine gültige E-Mail-Adresse ein';

  @override
  String get sendCode => 'Code senden';

  @override
  String codeSentTo(String email) {
    return 'Gib den 6-stelligen Code ein, den wir an $email geschickt haben. Er gilt 10 Minuten.';
  }

  @override
  String get codeLabel => '6-stelliger Code';

  @override
  String get verifyCode => 'Weiter';

  @override
  String get resendCode => 'Code erneut senden';

  @override
  String resendCodeIn(int seconds) {
    return 'Code erneut senden in $seconds s';
  }

  @override
  String get codeResent => 'Wir haben einen neuen Code geschickt.';

  @override
  String get useDifferentEmail => 'Andere E-Mail verwenden';

  @override
  String get codeCheckSpam => 'Nichts angekommen? Schau in deinen Spam-Ordner.';

  @override
  String get errorCodeInvalid =>
      'Der Code ist falsch oder abgelaufen. Fordere einen neuen an.';

  @override
  String get errorEmailNotConfigured =>
      'Dieser Server verschickt keine E-Mails.';

  @override
  String get errorEmailRejected =>
      'An diese Adresse kann keine E-Mail zugestellt werden. Prüfe sie auf Tippfehler.';

  @override
  String get errorEmailTaken => 'Ein anderes Konto nutzt diese Adresse schon.';

  @override
  String get errorEmailRequired =>
      'Mit deiner E-Mail meldest du dich an, deshalb kann sie nicht entfernt werden.';

  @override
  String get errorEmailUnavailable =>
      'E-Mail funktioniert gerade nicht. Versuch es später noch einmal.';

  @override
  String get emailSaved => 'E-Mail gespeichert';

  @override
  String removeEmailTitle(String email) {
    return '$email entfernen?';
  }

  @override
  String get removeEmailMessage =>
      'Du bekommst keine E-Mail-Zusammenfassungen oder Erinnerungen mehr und kannst dich nicht mehr damit anmelden.';

  @override
  String get emailRemoved => 'E-Mail entfernt';

  @override
  String get emailNeedsConnection =>
      'Zum Ändern deiner E-Mail brauchst du eine Verbindung.';

  @override
  String get emailBouncedNote =>
      'E-Mails an diese Adresse kommen zurück – ändere sie oder bestätige sie erneut';

  @override
  String get emailVerifiedNote => 'Bestätigt · andere Mitglieder sehen sie nie';

  @override
  String get changeEmail => 'E-Mail ändern';

  @override
  String get emailAccountHelp =>
      'Für die Anmeldung und E-Mail-Zusammenfassungen. Wir schicken einen Code, um zu prüfen, dass sie dir gehört. Andere Mitglieder sehen sie nie.';

  @override
  String get removeEmail => 'E-Mail entfernen';

  @override
  String get addEmail => 'E-Mail hinzufügen';

  @override
  String get addEmailHint =>
      'Damit anmelden und Zusammenfassungen per E-Mail bekommen';

  @override
  String unblockedName(String name) {
    return '$name nicht mehr blockiert';
  }

  @override
  String get blockNeedsConnection =>
      'Zum Blockieren brauchst du eine Verbindung.';

  @override
  String get blockedEmpty => 'Du hast niemanden blockiert.';

  @override
  String get blockedNeedsConnection =>
      'Für blockierte Personen brauchst du eine Verbindung';

  @override
  String get unblock => 'Nicht mehr blockieren';

  @override
  String get blockedPeople => 'Blockierte Personen';

  @override
  String get blockedHelp =>
      'Blockierte Personen können dich nicht als Freund hinzufügen oder dir Erinnerungen schicken, und ihre Änderungen benachrichtigen oder mailen dich nicht. Gemeinsame Gruppen und Salden bleiben, wie sie sind.';

  @override
  String get deletedGroupsEmpty => 'Keine gelöschten Gruppen';

  @override
  String get deletedGroupsHelp =>
      'Beim Wiederherstellen kommt eine Gruppe für alle zurück, mit allem, was drin ist.';

  @override
  String get deletedGroups => 'Gelöschte Gruppen';

  @override
  String deletedGroupsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Gruppen können wiederhergestellt werden',
      one: '1 Gruppe kann wiederhergestellt werden',
    );
    return '$_temp0';
  }

  @override
  String get exportNeedsConnection =>
      'Zum Exportieren brauchst du eine Verbindung.';

  @override
  String get exportEverything => 'Alles exportieren (JSON)';

  @override
  String get exportEverythingHint =>
      'Dein Profil, deine Zahlungswege, Einstellungen und jede Gruppe, auch gelöschte';

  @override
  String get emailSummary => 'E-Mail-Zusammenfassung';

  @override
  String digestChoice(String choice) {
    String _temp0 = intl.Intl.selectLogic(choice, {
      'auto': 'Automatisch',
      'daily': 'Täglich',
      'weekly': 'Wöchentlich',
      'monthly': 'Monatlich',
      'off': 'Aus',
      'other': 'Automatisch',
    });
    return '$_temp0';
  }

  @override
  String get digestAutoHelp =>
      'Täglich, wenn deine Geräte keine Benachrichtigungen zeigen können, sonst monatlich';

  @override
  String get digestAutoDaily =>
      'Automatisch – täglich, weil Benachrichtigungen aus sind';

  @override
  String get digestAutoMonthly =>
      'Automatisch – monatlich, weil deine Geräte Benachrichtigungen bekommen';

  @override
  String get digestNoEmail =>
      'Füge unter Konto eine E-Mail hinzu, um Zusammenfassungen zu bekommen';

  @override
  String get helpReportProblem => 'Problem melden oder Funktion vorschlagen';

  @override
  String get helpReportProblemHint => 'Auf GitHub, für alle sichtbar';

  @override
  String get helpContact => 'Support per E-Mail';

  @override
  String get privacyPolicy => 'Datenschutzerklärung';

  @override
  String get helpFeedback => 'Hilfe & Feedback';

  @override
  String get signOutEverywhere => 'Auf allen Geräten abmelden';

  @override
  String get signOutEverywhereTitle => 'Auf allen Geräten abmelden?';

  @override
  String get signOutEverywhereMessage =>
      'Jedes Handy und jeder Browser mit deinem Konto wird abgemeldet, auch dieses Gerät. Deine Gruppen bleiben auf dem Server.';

  @override
  String get signOutEverywhereOffline =>
      'Zum Abmelden auf allen Geräten brauchst du eine Verbindung.';

  @override
  String get deleteAccountExportTip => 'Tipp: Exportiere vorher alles.';

  @override
  String get coverPhoto => 'Titelbild';

  @override
  String get coverPhotoHint =>
      'Erscheint oben in der Gruppe und in der Liste. Nur Mitglieder sehen es.';

  @override
  String get removeCover => 'Titelbild entfernen';

  @override
  String get coverNeedsConnection =>
      'Zum Ändern des Titelbilds brauchst du eine Verbindung.';

  @override
  String get coverTooMany =>
      'Das sind viele Titelbilder. Versuch es in einer Stunde noch einmal.';

  @override
  String get deleteGroup => 'Gruppe löschen';

  @override
  String get deleteGroupHint =>
      'Für alle · jedes Mitglied kann sie wiederherstellen';

  @override
  String deleteGroupTitle(String name) {
    return '„$name“ löschen?';
  }

  @override
  String get deleteGroupMessage =>
      'Für alle gelöscht. Jedes Mitglied kann sie unter Einstellungen → Gelöschte Gruppen wiederherstellen.';

  @override
  String groupDeletedName(String name) {
    return '„$name“ gelöscht';
  }

  @override
  String get groupDeletedBanner => 'Diese Gruppe ist gelöscht';

  @override
  String get groupRestored => 'Gruppe wiederhergestellt';

  @override
  String get deleteFriend => 'Freund löschen';

  @override
  String deleteFriendTitle(String name) {
    return '$name löschen?';
  }

  @override
  String deleteFriendMessage(String name) {
    return 'Eure Ausgaben ohne Gruppe mit $name werden für euch beide gelöscht. Gemeinsame Gruppen bleiben. Du kannst sie unter Einstellungen → Gelöschte Gruppen wiederherstellen oder indem du $name wieder hinzufügst.';
  }

  @override
  String friendDeleted(String name) {
    return '$name gelöscht';
  }

  @override
  String get block => 'Blockieren';

  @override
  String blockTitle(String name) {
    return '$name blockieren?';
  }

  @override
  String blockMessage(String name) {
    return '$name kann dich dann nicht als Freund hinzufügen oder dir Erinnerungen schicken, und Änderungen von $name benachrichtigen oder mailen dich nicht. Gemeinsame Gruppen und Salden bleiben.';
  }

  @override
  String blockedName(String name) {
    return '$name blockiert';
  }

  @override
  String get report => 'Melden…';

  @override
  String get reportSubject => 'Evensies-Meldung';

  @override
  String reportBody(String userId) {
    return 'Nutzer-ID: $userId\n\nWas ist passiert:\n';
  }

  @override
  String get inviteByEmail => 'Per E-Mail einladen…';

  @override
  String get inviteEmailField => 'E-Mail (optional)';

  @override
  String get inviteEmailHelp =>
      'Wir schicken einen Einladungslink per E-Mail. Nur für diese Einladung.';

  @override
  String inviteByEmailTitle(String name) {
    return '$name per E-Mail einladen';
  }

  @override
  String inviteEmailSent(String email) {
    return 'Einladung an $email geschickt';
  }

  @override
  String get inviteEmailOfflineAdded =>
      'Mitglied hinzugefügt. Für die Einladung per E-Mail brauchst du eine Verbindung – versuch es in der Mitgliederliste noch einmal.';

  @override
  String get inviteEmailOffline =>
      'Zum Einladen per E-Mail brauchst du eine Verbindung.';

  @override
  String get inviteEmailLimit =>
      'Das E-Mail-Limit für heute ist erreicht – teile stattdessen den Link.';

  @override
  String emailReminder(String choice) {
    return 'Erinnerung per E-Mail: $choice';
  }

  @override
  String get remindNever => 'Nie';

  @override
  String remindDaysBefore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage vorher',
      one: '1 Tag vorher',
    );
    return '$_temp0';
  }

  @override
  String get blurbUpi =>
      'Indien: Paytm, PhonePe, Google Pay und andere UPI-Apps';

  @override
  String get fieldUpi => 'UPI-ID';

  @override
  String get fieldUpiHint => 'Etwa name@okicici';

  @override
  String get fieldUpiName => 'Name (optional)';

  @override
  String get fieldUpiNameHint => 'Wird der Person angezeigt, die dich bezahlt';

  @override
  String get methodErrorUpi => 'Gib eine UPI-ID wie name@bank ein';

  @override
  String get noUpiApp =>
      'Keine UPI-App gefunden. Kopiere stattdessen UPI-ID und Betrag.';

  @override
  String get upiIdLabel => 'UPI-ID';

  @override
  String get copyUpiId => 'UPI-ID kopieren';

  @override
  String get upiIdCopied => 'UPI-ID kopiert';

  @override
  String get dashboard => 'Übersicht';

  @override
  String get allExpenses => 'Alle Ausgaben';

  @override
  String get groupBalances => 'Salden der Gruppe';

  @override
  String get yourBalance => 'Dein Saldo';

  @override
  String get dashboardOwesYou => 'Schuldet dir';

  @override
  String get dashboardYouOwe => 'Du schuldest';

  @override
  String get historyAndComments => 'Verlauf und Kommentare';

  @override
  String get showEarlier => 'Früheres anzeigen';

  @override
  String get settleUpFirst => 'Erst begleichen';

  @override
  String deleteFriendSettleFirst(String name) {
    return 'Du kannst $name als Freund löschen, sobald eure Ausgaben außerhalb von Gruppen beglichen sind.';
  }

  @override
  String get noMailApp =>
      'Keine E-Mail-App gefunden. Kopiere die Angaben unten und schreib aus einer beliebigen E-Mail-App.';

  @override
  String get copyAddress => 'Adresse kopieren';

  @override
  String get copyMessage => 'Nachricht kopieren';

  @override
  String get browserNoStorage =>
      'Dieser Browser kann die Daten von Evensies nicht speichern. Versuch es mit einem anderen Browser oder einem Fenster, das nicht privat ist.';

  @override
  String get browserOtherTab =>
      'Evensies ist in diesem Browser schon in einem anderen Tab geöffnet. Nutze diesen Tab, oder schließ ihn und lade diesen neu.';

  @override
  String get loginReview => 'Demo-Anmeldung';

  @override
  String get loginReviewUsername => 'Benutzername';

  @override
  String get loginReviewPassword => 'Passwort';

  @override
  String get loginReviewSubmit => 'Anmelden';

  @override
  String get loginReviewWrong => 'Falscher Benutzername oder falsches Passwort';
}
