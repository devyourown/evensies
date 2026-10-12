// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'Evensies';

  @override
  String get cancel => 'Anuluj';

  @override
  String get delete => 'Usuń';

  @override
  String get remove => 'Usuń';

  @override
  String get save => 'Zapisz';

  @override
  String get done => 'Gotowe';

  @override
  String get undo => 'Cofnij';

  @override
  String get retry => 'Spróbuj ponownie';

  @override
  String get ok => 'OK';

  @override
  String get close => 'Zamknij';

  @override
  String get edit => 'Edytuj';

  @override
  String get add => 'Dodaj';

  @override
  String get offlineBanner => 'Offline — zmiany zsynchronizują się później';

  @override
  String get tooLong => 'Za długie';

  @override
  String get allCurrencies => 'Wszystkie waluty';

  @override
  String get errorUnexpected => 'Coś poszło nie tak. Spróbuj ponownie.';

  @override
  String get errorNetwork => 'Jesteś offline. Spróbuj później.';

  @override
  String get errorRateLimited =>
      'Za dużo prób. Poczekaj minutę i spróbuj ponownie.';

  @override
  String get errorNotFound => 'To już nie istnieje.';

  @override
  String get errorForbidden => 'Nie możesz tego zrobić.';

  @override
  String get errorValidation => 'Serwer to odrzucił.';

  @override
  String get errorSumMismatch => 'Podział się nie zgadza.';

  @override
  String get errorPayersSumMismatch => 'Płacący się nie zgadzają.';

  @override
  String get errorNegativeAmount => 'Jakaś kwota jest poniżej zera.';

  @override
  String get errorNegativeShare => 'Czyjś udział byłby poniżej zera.';

  @override
  String get errorNegativeTotal => 'Suma byłaby poniżej zera.';

  @override
  String get errorZeroSubtotal =>
      'Wpisz ceny pozycji przed podatkiem, napiwkiem lub rabatem.';

  @override
  String get errorUnassignedItem =>
      'Każda pozycja potrzebuje co najmniej jednej osoby.';

  @override
  String get errorNoMembers => 'Wybierz co najmniej jedną osobę do podziału.';

  @override
  String get errorInvalidInput => 'Sprawdź liczby.';

  @override
  String get errorBadRate => 'Kurs wymiany musi być większy od zera.';

  @override
  String get errorUnknownMember => 'Dotyczy osoby, której nie ma w grupie.';

  @override
  String get errorUnknownCurrency => 'Ta waluta nie jest obsługiwana.';

  @override
  String get errorMemberTaken => 'Ten członek jest już zajęty.';

  @override
  String get errorLimitExceeded => 'Osiągnięto limit.';

  @override
  String get errorTooLarge => 'Zdjęcie jest za duże.';

  @override
  String get errorNotJpeg => 'Wybierz zdjęcie JPEG';

  @override
  String get errorFxUnavailable => 'Kursy wymiany są teraz niedostępne.';

  @override
  String get errorImportFailed => 'Nie udało się zaimportować tego pliku.';

  @override
  String get errorAuthNotConfigured =>
      'Ten serwer nie może cię zalogować w ten sposób.';

  @override
  String get errorDuplicate => 'To już istnieje.';

  @override
  String errorGeneric(String code) {
    return 'Coś poszło nie tak ($code).';
  }

  @override
  String rejectedReceipt(String name, String reason) {
    return 'Nie udało się zapisać paragonu do „$name”: $reason';
  }

  @override
  String rejectedReceiptUnnamed(String reason) {
    return 'Nie udało się zapisać paragonu do wydatku: $reason';
  }

  @override
  String rejectedReceiptRemove(String name, String reason) {
    return 'Nie udało się zapisać usunięcia paragonu z „$name”: $reason';
  }

  @override
  String rejectedReceiptRemoveUnnamed(String reason) {
    return 'Nie udało się zapisać usunięcia paragonu z wydatku: $reason';
  }

  @override
  String rejectedRepeating(String name, String reason) {
    return 'Nie udało się zapisać powtarzania „$name”: $reason';
  }

  @override
  String rejectedRepeatingUnnamed(String reason) {
    return 'Nie udało się zapisać wydatku cyklicznego: $reason';
  }

  @override
  String rejectedSeriesChange(String name, String reason) {
    return 'Nie udało się zapisać zmiany przyszłych „$name”: $reason';
  }

  @override
  String rejectedSeriesChangeUnnamed(String reason) {
    return 'Nie udało się zapisać zmiany wydatku cyklicznego: $reason';
  }

  @override
  String rejectedSeriesStop(String name, String reason) {
    return 'Nie udało się zapisać zatrzymania „$name”: $reason';
  }

  @override
  String rejectedSeriesStopUnnamed(String reason) {
    return 'Nie udało się zapisać zatrzymania wydatku cyklicznego: $reason';
  }

  @override
  String rejectedSavedNoRepeat(String name, String reason) {
    return '„$name” zapisano, ale nie będzie się powtarzać: $reason';
  }

  @override
  String rejectedPaymentRestore(String reason) {
    return 'Nie udało się zapisać przywrócenia płatności: $reason';
  }

  @override
  String rejectedNewExpense(String name, String reason) {
    return 'Nie udało się zapisać nowego wydatku „$name”: $reason';
  }

  @override
  String rejectedNewExpenseUnnamed(String reason) {
    return 'Nie udało się zapisać nowego wydatku: $reason';
  }

  @override
  String rejectedExpenseChange(String name, String reason) {
    return 'Nie udało się zapisać zmiany „$name”: $reason';
  }

  @override
  String rejectedExpenseChangeUnnamed(String reason) {
    return 'Nie udało się zapisać zmiany wydatku: $reason';
  }

  @override
  String rejectedExpenseDelete(String name, String reason) {
    return 'Nie udało się zapisać usunięcia „$name”: $reason';
  }

  @override
  String rejectedExpenseDeleteUnnamed(String reason) {
    return 'Nie udało się zapisać usunięcia wydatku: $reason';
  }

  @override
  String rejectedExpenseRestore(String name, String reason) {
    return 'Nie udało się zapisać przywrócenia „$name”: $reason';
  }

  @override
  String rejectedExpenseRestoreUnnamed(String reason) {
    return 'Nie udało się zapisać przywrócenia wydatku: $reason';
  }

  @override
  String rejectedComment(String name, String reason) {
    return 'Nie udało się zapisać komentarza do „$name”: $reason';
  }

  @override
  String rejectedCommentUnnamed(String reason) {
    return 'Nie udało się zapisać komentarza do wydatku: $reason';
  }

  @override
  String rejectedPaymentComment(String reason) {
    return 'Nie udało się zapisać komentarza do płatności: $reason';
  }

  @override
  String rejectedCommentDelete(String reason) {
    return 'Nie udało się zapisać usunięcia komentarza: $reason';
  }

  @override
  String rejectedPayment(String reason) {
    return 'Nie udało się zapisać płatności: $reason';
  }

  @override
  String rejectedPaymentDelete(String reason) {
    return 'Nie udało się zapisać usunięcia płatności: $reason';
  }

  @override
  String rejectedPaymentConfirm(String reason) {
    return 'Nie udało się zapisać potwierdzenia płatności: $reason';
  }

  @override
  String rejectedGroupSettings(String reason) {
    return 'Nie udało się zapisać zmiany ustawień grupy: $reason';
  }

  @override
  String rejectedMemberAdd(String name, String reason) {
    return 'Nie udało się zapisać dodania: $name: $reason';
  }

  @override
  String rejectedMemberAddUnnamed(String reason) {
    return 'Nie udało się zapisać dodania członka: $reason';
  }

  @override
  String rejectedMemberRemove(String reason) {
    return 'Nie udało się zapisać usunięcia członka: $reason';
  }

  @override
  String rejectedOther(String reason) {
    return 'Nie udało się zapisać zmiany: $reason';
  }

  @override
  String get reasonReceiptLimit => 'wydatek może mieć najwyżej 10 paragonów';

  @override
  String get reasonSeriesLimit =>
      'grupa może mieć najwyżej 100 wydatków cyklicznych';

  @override
  String get reasonNotUploaded => 'zdjęcie nie zostało wysłane';

  @override
  String get reasonSumMismatch => 'podział się nie zgadza';

  @override
  String get reasonPayersSumMismatch => 'płacący się nie zgadzają';

  @override
  String get reasonNegativeAmount => 'jakaś kwota jest poniżej zera';

  @override
  String get reasonUnknownMember => 'dotyczy osoby, której nie ma w grupie';

  @override
  String get reasonUnknownCurrency => 'ta waluta nie jest obsługiwana';

  @override
  String get reasonMemberTaken => 'ten członek jest już zajęty';

  @override
  String get reasonGroupFull => 'grupa jest pełna';

  @override
  String get reasonForbidden => 'nie możesz wprowadzić tej zmiany';

  @override
  String get reasonRefused => 'serwer to odrzucił';

  @override
  String leaveOwe(String amount) {
    return 'Jesteś winien $amount · najpierw się rozlicz';
  }

  @override
  String leaveOweIn(String amount, String currency) {
    return 'Jesteś winien $amount · najpierw rozlicz się w $currency';
  }

  @override
  String leaveOwed(String amount) {
    return 'Należy ci się $amount · najpierw się rozlicz';
  }

  @override
  String leaveOwedIn(String amount, String currency) {
    return 'Należy ci się $amount · najpierw rozlicz się w $currency';
  }

  @override
  String leaveSeries(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Wciąż jesteś w $count wydatkach cyklicznych ($names) · najpierw edytuj najnowszy albo je zatrzymaj',
      many:
          'Wciąż jesteś w $count wydatkach cyklicznych ($names) · najpierw edytuj najnowszy albo je zatrzymaj',
      few:
          'Wciąż jesteś w $count wydatkach cyklicznych ($names) · najpierw edytuj najnowszy albo je zatrzymaj',
      one:
          'Wciąż jesteś w 1 wydatku cyklicznym ($names) · najpierw edytuj najnowszy albo go zatrzymaj',
    );
    return '$_temp0';
  }

  @override
  String seriesNamesMore(String names, int count) {
    return '$names i jeszcze $count';
  }

  @override
  String get seriesUnnamed => 'wydatek';

  @override
  String get listJoiner => ', ';

  @override
  String get repeatNever => 'Nigdy';

  @override
  String get repeatWeekly => 'Co tydzień';

  @override
  String get repeatBiweekly => 'Co 2 tygodnie';

  @override
  String get repeatMonthly => 'Co miesiąc';

  @override
  String get repeatYearly => 'Co rok';

  @override
  String summaryNotConverted(String currency) {
    return 'Nieprzeliczone · $currency';
  }

  @override
  String summaryTotalSpent(String amount) {
    return 'Wydano łącznie: $amount';
  }

  @override
  String summaryPaidShare(String paid, String share) {
    return 'Zapłaciłeś: $paid · Twój udział: $share';
  }

  @override
  String summaryPayments(String made, String received) {
    return 'Wysłane płatności: $made · otrzymane: $received';
  }

  @override
  String summaryTopCategories(String list) {
    return 'Główne kategorie: $list';
  }

  @override
  String get summaryBalancesToday => 'Salda na dziś';

  @override
  String summaryGetsBack(String name, String amount) {
    return '$name odzyskuje $amount';
  }

  @override
  String summaryOwes(String name, String amount) {
    return '$name jest winien $amount';
  }

  @override
  String get summaryFooter => 'Udostępniono z Evensies';

  @override
  String get koreanBank => 'Koreańskie konto bankowe';

  @override
  String requestText(String amount, String group) {
    return 'Jesteś mi winien $amount za $group w Evensies.';
  }

  @override
  String requestTextWays(String amount, String group, String ways) {
    return 'Jesteś mi winien $amount za $group w Evensies. Zapłać przez: $ways';
  }

  @override
  String get requestNoGroup => 'nasze wspólne wydatki';

  @override
  String get leaveSyncing => 'Trwa synchronizacja. Spróbuj za chwilę.';

  @override
  String get leaveOffline => 'Musisz być online, żeby wyjść';

  @override
  String get moveOffline =>
      'Nie udało się przenieść. Spróbuj, gdy będziesz online';

  @override
  String moveFailed(String reason) {
    return 'Nie udało się przenieść: $reason';
  }

  @override
  String get photoNoAccess =>
      'Evensies nie ma dostępu. Zezwól na niego w aplikacji Ustawienia.';

  @override
  String get photoNoCamera => 'Nie udało się otworzyć aparatu.';

  @override
  String get photoNoLibrary => 'Nie udało się otworzyć biblioteki zdjęć.';

  @override
  String get photoUnusable =>
      'Nie udało się użyć tego zdjęcia. Spróbuj innego.';

  @override
  String get methodErrorUsername => 'Tylko litery, cyfry, . _ - (maks. 40)';

  @override
  String methodErrorLinkPrefix(String prefix) {
    return 'Musi zaczynać się od $prefix';
  }

  @override
  String get methodErrorTooLong => 'Maks. 200 znaków';

  @override
  String get methodErrorIban => 'Nieprawidłowy IBAN';

  @override
  String get methodErrorHolder => 'Imię i nazwisko właściciela (1–70 znaków)';

  @override
  String get methodErrorBic => 'BIC ma 8 lub 11 znaków';

  @override
  String get methodErrorKrAccount => 'Cyfry i myślniki, 8–20 cyfr';

  @override
  String get methodErrorBank => 'Nazwa banku (1–30 znaków)';

  @override
  String get methodErrorUnknownType => 'Nieznany typ';

  @override
  String get methodErrorTooMany =>
      'Najwyżej 8 sposobów otrzymania pieniędzy i 3 każdego typu bankowego';

  @override
  String get bannerDismiss => 'Zamknij';

  @override
  String get bannerView => 'Pokaż';

  @override
  String get loginTagline =>
      'Dziel wydatki ze znajomymi. Bez reklam i bez naciągania.';

  @override
  String get loginApple => 'Kontynuuj z Apple';

  @override
  String get loginGoogle => 'Kontynuuj z Google';

  @override
  String get loginWebUnavailable =>
      'Ten serwer nie ma jeszcze logowania w przeglądarce.';

  @override
  String get welcomeTitle => 'Witaj';

  @override
  String get yourNameTitle => 'Twoje imię';

  @override
  String get nameQuestion => 'Jak mają cię nazywać znajomi?';

  @override
  String get nameExplain => 'To imię widzą inni członkowie.';

  @override
  String get nameHelp =>
      'Widzą je osoby w twoich grupach. Możesz je później zmienić w Ustawieniach.';

  @override
  String get nameLabel => 'Imię';

  @override
  String get lockReason => 'Odblokuj Evensies';

  @override
  String get lockTitle => 'Evensies jest zablokowane';

  @override
  String get lockSubtitle =>
      'Odblokuj za pomocą Face ID, Touch ID, odcisku palca lub kodu urządzenia.';

  @override
  String get lockUnlock => 'Odblokuj';

  @override
  String get lockSignOutConfirm =>
      'Wylogować się i usunąć dane z tego urządzenia? Twoje grupy zostaną na serwerze.';

  @override
  String get signOut => 'Wyloguj się';

  @override
  String get widgetOwed => 'Należy ci się';

  @override
  String get widgetOwe => 'Jesteś winien';

  @override
  String get widgetSignedOut => 'Zaloguj się, żeby zobaczyć saldo';

  @override
  String get widgetSettled => 'Wszystko rozliczone';

  @override
  String widgetUpdated(String time) {
    return 'Zaktualizowano $time';
  }

  @override
  String get receiptAdd => 'Dodaj paragon';

  @override
  String get photoTake => 'Zrób zdjęcie';

  @override
  String get photoChoose => 'Wybierz z biblioteki';

  @override
  String get photoChooseFile => 'Wybierz plik';

  @override
  String get availableWhenOnline => 'Dostępne online';

  @override
  String get receiptPhoto => 'Zdjęcie paragonu';

  @override
  String get receiptAvailableOnline => 'Zdjęcie jest dostępne online';

  @override
  String get receiptRemoveTitle => 'Usunąć paragon?';

  @override
  String get receiptRemoveMessage =>
      'Zostanie usunięty dla wszystkich w grupie.';

  @override
  String get receiptTitle => 'Paragon';

  @override
  String receiptTitleOf(int index, int count) {
    return 'Paragon $index z $count';
  }

  @override
  String get shareOrSave => 'Udostępnij lub zapisz';

  @override
  String get share => 'Udostępnij';

  @override
  String get copiedToClipboard => 'Skopiowano do schowka';

  @override
  String get settingsTitle => 'Ustawienia';

  @override
  String get photoRemove => 'Usuń zdjęcie';

  @override
  String get photoNeedsConnection => 'Zmiana zdjęcia wymaga połączenia.';

  @override
  String get photoTooMany => 'Za dużo zmian zdjęcia. Spróbuj za godzinę.';

  @override
  String get notifSaveFailed =>
      'Nie udało się zapisać ustawień powiadomień. Sprawdź połączenie.';

  @override
  String get homeCurrencyNeedsConnection =>
      'Zmiana waluty głównej wymaga połączenia.';

  @override
  String get changePhoto => 'Zmień zdjęcie profilowe';

  @override
  String get yourNameTapToChange => 'Twoje imię · dotknij, aby zmienić';

  @override
  String get waysToGetPaid => 'Sposoby otrzymania pieniędzy';

  @override
  String get waysToGetPaidHint => 'PayPal, Wise, IBAN, konto bankowe…';

  @override
  String get homeCurrency => 'Waluta główna';

  @override
  String get homeCurrencyFromRegion =>
      'Z twojego regionu · salda pokazują też ≈ w tej walucie';

  @override
  String get homeCurrencyPicked => 'Salda pokazują też ≈ w tej walucie';

  @override
  String get notifications => 'Powiadomienia';

  @override
  String get notifExpenses => 'Wydatki i płatności';

  @override
  String get notifComments => 'Komentarze';

  @override
  String get notifMembers => 'Członkowie i zmiany w grupie';

  @override
  String get notifReminders => 'Przypomnienia od znajomych';

  @override
  String get notifNeedConnection =>
      'Ustawienia powiadomień wymagają połączenia';

  @override
  String get notifOthersOnly => 'Powiadamiamy tylko o zmianach innych osób.';

  @override
  String get notifWebNote =>
      'Powiadomienia trafiają na telefon; przeglądarka odświeża się co minutę, gdy jest otwarta.';

  @override
  String get exportImport => 'Eksport i import';

  @override
  String get noGroupsToExport => 'Brak grup do eksportu.';

  @override
  String get nonGroup => 'Poza grupą';

  @override
  String nonGroupWith(String name) {
    return 'Poza grupą · $name';
  }

  @override
  String get exportJson => 'Eksportuj JSON';

  @override
  String get exportCsv => 'Eksportuj CSV';

  @override
  String get exportZip => 'ZIP z paragonami';

  @override
  String get importSplitwise => 'Importuj CSV ze Splitwise';

  @override
  String importedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zaimportowano $count wydatku',
      many: 'Zaimportowano $count wydatków',
      few: 'Zaimportowano $count wydatki',
      one: 'Zaimportowano 1 wydatek',
    );
    return '$_temp0';
  }

  @override
  String get server => 'Serwer';

  @override
  String get serverUrl => 'Adres serwera';

  @override
  String serverDefault(String url) {
    return 'Domyślnie: $url';
  }

  @override
  String get serverSaved => 'Adres serwera zapisany';

  @override
  String get account => 'Konto';

  @override
  String get licenses => 'Licencje';

  @override
  String get deleteAccount => 'Usuń konto';

  @override
  String get signOutTitle => 'Wylogować się?';

  @override
  String get signOutMessage =>
      'Dane lokalne na tym urządzeniu zostaną usunięte. Niezsynchronizowane zmiany przepadną.';

  @override
  String get deleteAccountTitle => 'Usunąć konto?';

  @override
  String get deleteAccountMessage =>
      'Twoje członkostwa zmienią się w miejsca zastępcze. Dane grup zostaną u pozostałych członków. Tego nie da się cofnąć.';

  @override
  String get language => 'Język';

  @override
  String languageSystem(String language) {
    return 'Systemowy ($language)';
  }

  @override
  String get appearance => 'Wygląd';

  @override
  String get appearanceSystem => 'Systemowy';

  @override
  String get appearanceLight => 'Jasny';

  @override
  String get appearanceDark => 'Ciemny';

  @override
  String get security => 'Bezpieczeństwo';

  @override
  String get appLock => 'Blokada aplikacji';

  @override
  String get appLockHint =>
      'Face ID, Touch ID lub odcisk palca, a w razie potrzeby kod urządzenia. Blokuje się po minucie nieobecności.';

  @override
  String methodRemoveTitle(String method) {
    return 'Usunąć $method?';
  }

  @override
  String get methodsOffline =>
      'Połącz się z internetem, żeby edytować sposoby otrzymania pieniędzy.';

  @override
  String get methodsLoadFailed =>
      'Nie udało się wczytać sposobów otrzymania pieniędzy.';

  @override
  String get methodsIntro =>
      'Członkowie grupy widzą je, gdy są ci winni pieniądze, więc mogą zapłacić jednym dotknięciem. Evensies nigdy sam nie przesyła pieniędzy.';

  @override
  String get methodsEmpty => 'Brak sposobów otrzymania pieniędzy.';

  @override
  String get blurbPaypal => 'Link PayPal.me, z kwotą';

  @override
  String get blurbWise => 'Link Wise Quick Pay, z kwotą';

  @override
  String get blurbVenmo => 'Nazwa użytkownika Venmo (USA)';

  @override
  String get blurbRevolut => 'Nazwa użytkownika Revolut.me';

  @override
  String get blurbKakaopay => 'Link 송금코드 KakaoPay';

  @override
  String get blurbIban => 'Przelew (kod QR SEPA dla EUR)';

  @override
  String get blurbKrBank => 'Koreańskie konto bankowe (Toss, aplikacje banków)';

  @override
  String get fieldPaypal => 'Nazwa użytkownika PayPal.me';

  @override
  String get fieldPaypalHint => 'Twoja nazwa użytkownika PayPal.me, np. anna';

  @override
  String get fieldRevolut => 'Nazwa użytkownika Revolut.me';

  @override
  String get fieldRevolutHint => 'Twoja nazwa użytkownika Revolut.me, np. anna';

  @override
  String get fieldVenmo => 'Nazwa użytkownika Venmo';

  @override
  String get fieldVenmoHint => 'Bez @, np. anna-rossi';

  @override
  String get fieldWise => 'Link Wise Quick Pay';

  @override
  String get fieldWiseHint =>
      'W Wise: Płatności → Quick Pay → kopiuj link (https://wise.com/pay/…)';

  @override
  String get fieldKakaopay => 'Link 송금코드 KakaoPay';

  @override
  String get fieldKakaopayHint =>
      'W KakaoPay: 송금 → 송금코드 → kopiuj link (https://qr.kakaopay.com/…)';

  @override
  String get fieldHolder => 'Właściciel konta';

  @override
  String get fieldHolderHint => 'Imię i nazwisko dokładnie jak na koncie';

  @override
  String get fieldIban => 'IBAN';

  @override
  String get fieldIbanHint => 'np. PL61 1090 1014 0000 0712 1981 2874';

  @override
  String get fieldBic => 'BIC (opcjonalnie)';

  @override
  String get fieldBicHint => '8 lub 11 znaków';

  @override
  String get fieldBank => 'Bank';

  @override
  String get fieldBankHint => 'np. 신한은행, Toss Bank';

  @override
  String get fieldAccountNumber => 'Numer konta';

  @override
  String get fieldAccountNumberHint => 'Cyfry, myślniki opcjonalne';

  @override
  String amountCopied(String amount) {
    return 'Skopiowano kwotę: $amount';
  }

  @override
  String couldNotOpen(String link) {
    return 'Nie udało się otworzyć $link';
  }

  @override
  String get payOffline => 'Offline: sposoby płatności są niedostępne';

  @override
  String get payLoading => 'Wczytywanie sposobów płatności…';

  @override
  String payAskToAdd(String name) {
    return 'Poproś osobę $name o dodanie sposobu otrzymania pieniędzy';
  }

  @override
  String payTitle(String name, String amount) {
    return 'Zapłać $amount: $name';
  }

  @override
  String get payScanQr => 'Zeskanuj aplikacją banku (kod QR SEPA)';

  @override
  String get payQrEurOnly => 'Kod QR jest dostępny tylko dla przelewów w EUR.';

  @override
  String get bankLabel => 'Bank';

  @override
  String get ibanLabel => 'IBAN';

  @override
  String get accountLabel => 'Konto';

  @override
  String get bicLabel => 'BIC';

  @override
  String get holderLabel => 'Właściciel';

  @override
  String get amountLabel => 'Kwota';

  @override
  String get copyIban => 'Kopiuj IBAN';

  @override
  String get copyAccount => 'Kopiuj konto';

  @override
  String get copyAmount => 'Kopiuj kwotę';

  @override
  String get ibanCopied => 'Skopiowano IBAN';

  @override
  String get accountCopied => 'Skopiowano konto';

  @override
  String get paymentUpdated => 'Zaktualizowano płatność';

  @override
  String paymentRecordedPending(String amount, String name) {
    return 'Zapisano $amount. $name potwierdzi.';
  }

  @override
  String paymentRecordedPendingUnnamed(String amount) {
    return 'Zapisano $amount. Druga osoba potwierdzi.';
  }

  @override
  String paymentRecorded(String amount) {
    return 'Zapisano płatność $amount';
  }

  @override
  String youSuffix(String name) {
    return '$name (ty)';
  }

  @override
  String get recordPayment => 'Zapisz płatność';

  @override
  String get editPayment => 'Edytuj płatność';

  @override
  String get fromLabel => 'Od';

  @override
  String get toLabel => 'Do';

  @override
  String get swap => 'Zamień';

  @override
  String get pickTwoPeople => 'Wybierz dwie różne osoby';

  @override
  String get commentsStayOld => 'Komentarze zostają przy starej płatności';

  @override
  String get recordPaymentButton => 'Zapisz płatność';

  @override
  String get paymentNotHere => 'Tej płatności nie ma na tym urządzeniu';

  @override
  String get notSyncedOrLeft =>
      'Nie została jeszcze zsynchronizowana albo opuszczono jej grupę.';

  @override
  String get someone => 'Ktoś';

  @override
  String get paymentEdited => 'Edytowana płatność';

  @override
  String get paymentDeleted => 'Usunięta płatność';

  @override
  String get payment => 'Płatność';

  @override
  String get paymentWasEdited => 'Ta płatność została edytowana';

  @override
  String get paymentWasEditedNote =>
      'Zamiast niej liczy się edytowana płatność. Komentarze zostają tutaj.';

  @override
  String get paymentWasDeleted => 'Ta płatność została usunięta';

  @override
  String get paymentNotCounted => 'Nie liczy się do sald.';

  @override
  String get restore => 'Przywróć';

  @override
  String youPaidName(String name) {
    return 'Zapłacono: ty → $name';
  }

  @override
  String namePaidYou(String name) {
    return 'Zapłacono: $name → ty';
  }

  @override
  String namePaidName(String from, String to) {
    return 'Zapłacono: $from → $to';
  }

  @override
  String paymentSaysSent(String name) {
    return '$name twierdzi, że to wysłał(a). Dotarło?';
  }

  @override
  String waitingForConfirm(String name) {
    return 'Czeka na potwierdzenie: $name';
  }

  @override
  String get notReceived => 'Nie dotarło';

  @override
  String get confirmReceived => 'Potwierdź odbiór';

  @override
  String get deletePaymentTitle => 'Usunąć płatność?';

  @override
  String get deletePaymentMessage => 'Dług, który rozliczała, wróci.';

  @override
  String get paymentDeletedSnack => 'Usunięto płatność';

  @override
  String get notReceivedTitle => 'Nie dotarło?';

  @override
  String notReceivedMessage(String name) {
    return 'Płatność od $name zostanie usunięta, a dług wróci.';
  }

  @override
  String get paymentRemovedSnack => 'Usunięto płatność';

  @override
  String get recordAPayment => 'Zapisz płatność';

  @override
  String get nothingToSettle => 'Nie ma czego rozliczać';

  @override
  String get everyoneEven => 'Wszyscy są rozliczeni.';

  @override
  String get waitingForConfirmation => 'Czeka na potwierdzenie';

  @override
  String get debtsAsRecorded =>
      'Długi tak, jak zapisano · upraszczanie długów wyłączone';

  @override
  String transfersSettleEverything(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count przelewu rozlicza wszystko',
      many: '$count przelewów rozlicza wszystko',
      few: '$count przelewy rozliczają wszystko',
      one: '1 przelew rozlicza wszystko',
    );
    return '$_temp0';
  }

  @override
  String transfersSettleBalance(int count, String currency) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count przelewu rozlicza saldo w $currency',
      many: '$count przelewów rozlicza saldo w $currency',
      few: '$count przelewy rozliczają saldo w $currency',
      one: '1 przelew rozlicza saldo w $currency',
    );
    return '$_temp0';
  }

  @override
  String notConvertedSettlesIn(String currency) {
    return 'Nieprzeliczone · $currency · rozliczane w $currency';
  }

  @override
  String get convert => 'Przelicz';

  @override
  String get settleUp => 'Rozlicz się';

  @override
  String saysTheySent(String name, String amount) {
    return '$name twierdzi, że wysłał(a) ci $amount';
  }

  @override
  String waitingToConfirmAmount(String name, String amount) {
    return 'Czeka, aż $name potwierdzi $amount';
  }

  @override
  String get you => 'Ty';

  @override
  String get request => 'Poproś';

  @override
  String get iveSentIt => 'Wysłałem';

  @override
  String get markAsPaid => 'Oznacz jako zapłacone';

  @override
  String markedAsSent(String name) {
    return 'Oznaczono jako wysłane. $name potwierdzi.';
  }

  @override
  String approx(String amount) {
    return '≈ $amount';
  }

  @override
  String friendOwesYou(String name, String amount) {
    return '$name: należy ci się $amount';
  }

  @override
  String friendYouOwe(String name, String amount) {
    return '$name: jesteś winien $amount';
  }

  @override
  String friendYouOweLine(String name, String amount) {
    return '$name: jesteś winien $amount';
  }

  @override
  String noSharedGroup(String name) {
    return 'Nie masz już wspólnej grupy z: $name. Wyślij swój link znajomego, żeby dodawać wydatki.';
  }

  @override
  String get shareFriendLink => 'Udostępnij link znajomego';

  @override
  String firstExpenseNeedsConnection(String name) {
    return 'Pierwszy wydatek z $name wymaga połączenia.';
  }

  @override
  String reminderSent(String name) {
    return 'Wysłano przypomnienie: $name';
  }

  @override
  String remindTomorrow(String name) {
    return 'Możesz przypomnieć ($name) ponownie jutro';
  }

  @override
  String remindNothingOwed(String name) {
    return '$name nie jest ci nic winien';
  }

  @override
  String get remindNeedsConnection =>
      'Wysłanie przypomnienia wymaga połączenia.';

  @override
  String amountsAnd(String a, String b) {
    return '$a i $b';
  }

  @override
  String inviteFriendText(String link) {
    return 'Dodałem cię w Evensies, żebyśmy mogli dzielić wydatki. Dołącz: $link';
  }

  @override
  String get personNotHere => 'Tej osoby nie ma na tym urządzeniu';

  @override
  String get personNotHereNote =>
      'Nie została jeszcze zsynchronizowana albo nie macie już wspólnej grupy.';

  @override
  String get more => 'Więcej';

  @override
  String get exportNonGroupCsv => 'Eksportuj wydatki poza grupą (CSV)';

  @override
  String get exportNonGroupJson => 'Eksportuj wydatki poza grupą (JSON)';

  @override
  String get exportNonGroupZip =>
      'Eksportuj wydatki poza grupą (ZIP z paragonami)';

  @override
  String get notOnEvensies => 'Jeszcze nie w Evensies';

  @override
  String get allSettledUp => 'Wszystko rozliczone';

  @override
  String get remind => 'Przypomnij';

  @override
  String get invite => 'Zaproś';

  @override
  String get balances => 'Salda';

  @override
  String get expensesAndPayments => 'Wydatki i płatności';

  @override
  String get nothingTogetherYet =>
      'Jeszcze nic wspólnego. Dodaj wydatek poniżej.';

  @override
  String get addExpense => 'Dodaj wydatek';

  @override
  String personOwesYou(String amount) {
    return 'należy ci się $amount';
  }

  @override
  String personYouOwe(String amount) {
    return 'jesteś winien $amount';
  }

  @override
  String get personSettledUp => 'rozliczone';

  @override
  String recordedInGroups(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Zapisano w $count grupy',
      many: 'Zapisano w $count grupach',
      few: 'Zapisano w $count grupach',
      one: 'Zapisano w 1 grupie',
    );
    return '$_temp0';
  }

  @override
  String get markAsReceived => 'Oznacz jako otrzymane';

  @override
  String get clearBothSides => 'Wyzeruj obie strony';

  @override
  String evenIn(String currency) {
    return 'Rozliczone w $currency';
  }

  @override
  String linePayThem(String group, String name, String amount) {
    return '$group: płacisz ($name) $amount';
  }

  @override
  String lineTheyPay(String group, String name, String amount) {
    return '$group: $name płaci ci $amount';
  }

  @override
  String get noMoneyMoves =>
      'Pieniądze nie są przesyłane: obie strony zostaną zapisane jako rozliczone.';

  @override
  String convertIn(String group) {
    return 'Przelicz w $group';
  }

  @override
  String settleUpWith(String name) {
    return 'Rozlicz się: $name';
  }

  @override
  String nothingToSettleWith(String name) {
    return 'Nie ma czego rozliczać: $name';
  }

  @override
  String settleWithIntro(String name) {
    return 'Wszystko między tobą a $name, według waluty. Zapisanie dodaje płatność w każdej grupie.';
  }

  @override
  String get searchFriendsGroups => 'Szukaj znajomych i grup';

  @override
  String get friends => 'Znajomi';

  @override
  String get groups => 'Grupy';

  @override
  String get noFriendsOrGroups => 'Brak znajomych i grup.';

  @override
  String nothingMatches(String query) {
    return 'Nic nie pasuje do „$query”.';
  }

  @override
  String get addExpenseWithWhom => 'Dodaj wydatek · z kim?';

  @override
  String friendLinkShare(String link, String code) {
    return 'Dodaj mnie w Evensies, żebyśmy dzielili wydatki: $link\nAlbo wpisz mój kod $code';
  }

  @override
  String get friendLinkNeedsConnection =>
      'Udostępnienie linku znajomego wymaga połączenia.';

  @override
  String get selfFriend => 'To twój własny kod';

  @override
  String get noOneForCode => 'Nie znaleziono nikogo z tym kodem';

  @override
  String get addFriendNeedsConnection => 'Dodanie znajomego wymaga połączenia.';

  @override
  String get newFriendCodeTitle => 'Utworzyć nowy kod znajomego?';

  @override
  String get newFriendCodeMessage =>
      'Obecny link i kod przestaną działać. Znajomi, których już masz, zostaną.';

  @override
  String get newCode => 'Nowy kod';

  @override
  String get addAFriend => 'Dodaj znajomego';

  @override
  String get friendLinkOffline => 'Twój link znajomego wymaga połączenia';

  @override
  String get yourFriendCode => 'Twój kod znajomego';

  @override
  String get friendQrLabel => 'Kod QR twojego linku znajomego';

  @override
  String get friendCodeHelp =>
      'Znajomi skanują go, otwierają link albo wpisują kod.';

  @override
  String get shareLink => 'Udostępnij link';

  @override
  String get codeCopied => 'Skopiowano kod';

  @override
  String get copyCode => 'Kopiuj kod';

  @override
  String get haveFriendCode => 'Masz kod znajomego?';

  @override
  String get onEvensies => 'w Evensies';

  @override
  String get notOnEvensiesSection => 'Ktoś, kogo jeszcze nie ma w Evensies';

  @override
  String get notOnEvensiesHelp =>
      'Dodawaj z tą osobą wydatki od razu, a zaproś ją później.';

  @override
  String atMostChars(int max) {
    return 'Najwyżej $max znaków';
  }

  @override
  String addName(String name) {
    return 'Dodaj: $name';
  }

  @override
  String get search => 'Szukaj';

  @override
  String get activity => 'Aktywność';

  @override
  String get newGroup => 'Nowa grupa';

  @override
  String get joinWithCode => 'Dołącz z kodem';

  @override
  String get filterAll => 'Wszystkie';

  @override
  String get filterOwesMe => 'Winni mi';

  @override
  String get filterIOwe => 'Jestem winien';

  @override
  String settledUpCount(int count) {
    return 'Rozliczone ($count)';
  }

  @override
  String get nobodyOwesYou => 'Nikt nie jest ci nic winien';

  @override
  String get youOweNothing => 'Nie jesteś nic winien';

  @override
  String get nothingHereYet => 'Na razie nic tu nie ma';

  @override
  String get noFriendsYet => 'Brak znajomych';

  @override
  String get noFriendsHelp =>
      'Dodaj znajomego, żeby dzielić wydatki poza grupą. Osoby, z którymi masz wspólną grupę, też się tu pojawiają.';

  @override
  String get allSettledUpYou => 'Wszystko masz rozliczone';

  @override
  String youAreOwedList(String amounts) {
    return 'Należy ci się $amounts';
  }

  @override
  String youOweList(String amounts) {
    return 'Jesteś winien $amounts';
  }

  @override
  String get notOnEvensiesLower => 'jeszcze nie w Evensies';

  @override
  String get noGroupsYet => 'Brak grup';

  @override
  String get noGroupsHelp =>
      'Utwórz grupę na wyjazd lub do wspólnego mieszkania albo dołącz do grupy znajomego jego kodem zaproszenia.';

  @override
  String get createGroup => 'Utwórz grupę';

  @override
  String get settledUp => 'Rozliczone';

  @override
  String netApprox(String amount) {
    return 'Netto ≈ $amount';
  }

  @override
  String memberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count członka',
      many: '$count członków',
      few: '$count członków',
      one: '1 członek',
    );
    return '$_temp0';
  }

  @override
  String youOweAmount(String amount) {
    return 'Jesteś winien $amount';
  }

  @override
  String youAreOwedAmount(String amount) {
    return 'Należy ci się $amount';
  }

  @override
  String youOweAmountLine(String amount) {
    return 'jesteś winien $amount';
  }

  @override
  String youAreOwedAmountLine(String amount) {
    return 'należy ci się $amount';
  }

  @override
  String get createGroupNeedsConnection =>
      'Utworzenie grupy wymaga połączenia.';

  @override
  String get groupName => 'Nazwa grupy';

  @override
  String get yourNameInGroup => 'Twoje imię w tej grupie';

  @override
  String get defaultCurrency => 'Waluta domyślna';

  @override
  String get create => 'Utwórz';

  @override
  String get noGroupOrFriendForCode =>
      'Nie znaleziono grupy ani znajomego z tym kodem';

  @override
  String get joinNeedsConnection => 'Dołączenie do grupy wymaga połączenia.';

  @override
  String get enterACode => 'Wpisz kod';

  @override
  String get enterCodeHelp =>
      'Kod grupy jest w grupie → Członkowie. Kod znajomego jest w jego karcie Znajomi → Dodaj znajomego.';

  @override
  String get pastedFromClipboard => 'Wklejono ze schowka';

  @override
  String nameOnEvensies(String name) {
    return '$name · w Evensies';
  }

  @override
  String addAsFriend(String name) {
    return 'Dodaj do znajomych: $name';
  }

  @override
  String addedYouAsFriend(String name) {
    return '$name dodał(a) cię do znajomych';
  }

  @override
  String get someoneAddedYouAsFriend => 'Ktoś dodał cię do znajomych';

  @override
  String groupPreview(String name, String members) {
    return '$name · $members';
  }

  @override
  String get continueButton => 'Dalej';

  @override
  String wantsToSplit(String name) {
    return '$name chce dzielić z tobą wydatki';
  }

  @override
  String get joinGroup => 'Dołącz do grupy';

  @override
  String get inviteInvalid => 'Ten link zaproszenia jest już nieważny';

  @override
  String inviteFailed(String reason) {
    return 'Nie udało się otworzyć zaproszenia: $reason';
  }

  @override
  String get friendInviteUsed => 'To zaproszenie zostało już użyte';

  @override
  String get joinToSeeShared =>
      'Dołącz, żeby widzieć i dodawać wspólne wydatki.';

  @override
  String imName(String name) {
    return 'To ja: $name';
  }

  @override
  String get join => 'Dołącz';

  @override
  String get whoAreYou => 'Kim jesteś?';

  @override
  String get newMemberName => 'Imię nowego członka';

  @override
  String get insights => 'Statystyki';

  @override
  String get membersInvite => 'Członkowie i zaproszenie';

  @override
  String get groupSettings => 'Ustawienia grupy';

  @override
  String get expenses => 'Wydatki';

  @override
  String get expenseFab => 'Wydatek';

  @override
  String get groupNotHere => 'Tej grupy nie ma na tym urządzeniu';

  @override
  String get groupNotHereNote =>
      'Opuściłeś ją, ktoś cię usunął albo nie została jeszcze zsynchronizowana.';

  @override
  String get backToGroups => 'Wróć do grup';

  @override
  String get noExpensesYet => 'Brak wydatków';

  @override
  String get tapExpenseToAdd => 'Dotknij „Wydatek”, żeby dodać pierwszy.';

  @override
  String tilePaidYou(String amount) {
    return 'zapłaciłeś $amount';
  }

  @override
  String tilePaidName(String name, String amount) {
    return '$name zapłacił(a) $amount';
  }

  @override
  String tilePaidPeople(int count, String amount) {
    return 'zapłaciło $count osób, $amount';
  }

  @override
  String get tileRefundYou => 'zwrot dla ciebie';

  @override
  String tileRefundName(String name) {
    return 'zwrot dla: $name';
  }

  @override
  String tileRefundPeople(int count) {
    return 'zwrot dla $count osób';
  }

  @override
  String get notInvolved => 'nie dotyczy cię';

  @override
  String get allYours => 'całość twoja';

  @override
  String get paidForYourself => 'zapłaciłeś za siebie';

  @override
  String youGetBack(String amount) {
    return 'odzyskujesz $amount';
  }

  @override
  String youLent(String amount) {
    return 'pożyczyłeś $amount';
  }

  @override
  String youBorrowed(String amount) {
    return 'pożyczono ci $amount';
  }

  @override
  String get repeatsLabel => 'Powtarza się';

  @override
  String hasReceipt(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ma $count paragonu',
      many: 'Ma $count paragonów',
      few: 'Ma $count paragony',
      one: 'Ma paragon',
    );
    return '$_temp0';
  }

  @override
  String get refund => 'Zwrot';

  @override
  String get notConverted => 'Nieprzeliczone';

  @override
  String get pending => 'oczekuje';

  @override
  String approxTotalOwe(String amount) {
    return 'Jesteś winien łącznie ≈ $amount';
  }

  @override
  String approxTotalOwed(String amount) {
    return 'Należy ci się łącznie ≈ $amount';
  }

  @override
  String get approxTotalNote =>
      'W twojej walucie głównej, po najnowszych kursach';

  @override
  String nothingOwedIn(String currency) {
    return 'Brak długów w $currency';
  }

  @override
  String get allSettled => 'Wszystko rozliczone';

  @override
  String get otherCurrenciesBelow => 'Wydatki w innych walutach są niżej.';

  @override
  String get nobodyOwes => 'Nikt nic nie jest winien.';

  @override
  String youPayNext(String amount) {
    return 'Następnym razem płacisz ty (jesteś winien $amount, najwięcej)';
  }

  @override
  String namePaysNext(String name, String amount) {
    return 'Następnym razem płaci $name (winien $amount, najwięcej)';
  }

  @override
  String settleUpWaiting(int count) {
    return 'Rozlicz się · oczekuje: $count';
  }

  @override
  String memberRemoved(String name) {
    return '$name (usunięty)';
  }

  @override
  String expensesWithoutRate(int count, String currency) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wydatku bez kursu do $currency',
      many: '$count wydatków bez kursu do $currency',
      few: '$count wydatki bez kursu do $currency',
      one: '1 wydatek bez kursu do $currency',
    );
    return '$_temp0';
  }

  @override
  String expensesBadRate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wydatku z kursem, którego nie da się przeliczyć',
      many: '$count wydatków z kursem, którego nie da się przeliczyć',
      few: '$count wydatki z kursem, którego nie da się przeliczyć',
      one: '1 wydatek z kursem, którego nie da się przeliczyć',
    );
    return '$_temp0';
  }

  @override
  String paymentsIn(String currency) {
    return 'Płatności w $currency';
  }

  @override
  String everyoneEvenIn(String currency) {
    return 'wszyscy rozliczeni w $currency';
  }

  @override
  String convertTo(String currency) {
    return 'Przelicz na $currency';
  }

  @override
  String get balanceSettled => 'rozliczone';

  @override
  String get balanceGetsBack => 'odzyskuje';

  @override
  String get balanceOwes => 'jest winien';

  @override
  String convertedCount(int count, String currency) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Przeliczono $count wydatku na $currency',
      many: 'Przeliczono $count wydatków na $currency',
      few: 'Przeliczono $count wydatki na $currency',
      one: 'Przeliczono 1 wydatek na $currency',
    );
    return '$_temp0';
  }

  @override
  String get noAutoRate => 'Brak automatycznego kursu. Wpisz go.';

  @override
  String rateOf(String date) {
    return 'kurs z $date';
  }

  @override
  String rateOfOffline(String date) {
    return 'offline · kurs z $date';
  }

  @override
  String amountCountExpenses(String amount, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wydatku',
      many: '$count wydatków',
      few: '$count wydatki',
      one: '1 wydatek',
    );
    return '$amount · $_temp0';
  }

  @override
  String paymentsStayIn(String currency) {
    return 'Płatności w $currency zostają w $currency';
  }

  @override
  String rateLabel(String from, String to) {
    return 'Kurs: 1 $from w $to';
  }

  @override
  String get nothingLeftToConvert => 'Nie ma nic do przeliczenia';

  @override
  String get lookingUpRate => 'Szukanie kursu…';

  @override
  String get enterRateAbove0 => 'Wpisz kurs większy od 0';

  @override
  String convertExplain(String currency) {
    return 'Wpisuje ten kurs do każdego wydatku bez kursu, żeby liczył się do sald w $currency. Kurs każdego wydatku możesz nadal zmienić.';
  }

  @override
  String get nameField => 'Nazwa';

  @override
  String get cantChangeCurrency =>
      'Nie można zmienić po pierwszym wydatku lub płatności';

  @override
  String get currencyUsedFor => 'Używana w saldach i płatnościach';

  @override
  String get splitting => 'Podział';

  @override
  String get simplifyDebts => 'Upraszczaj długi';

  @override
  String get simplifyDebtsHelp =>
      'Łączy długi, żeby grupa potrzebowała mniej płatności. Niczyja suma się nie zmienia, tylko kto komu płaci.';

  @override
  String get defaultSplit => 'Domyślny podział';

  @override
  String get splitStale => 'Już się nie zgadza · dotknij, by poprawić';

  @override
  String get membership => 'Członkostwo';

  @override
  String get leaveGroup => 'Opuść grupę';

  @override
  String get balanceSettledNote => 'Twoje saldo jest rozliczone';

  @override
  String get renameGroup => 'Zmień nazwę grupy';

  @override
  String leaveTitle(String name) {
    return 'Opuścić „$name”?';
  }

  @override
  String get leaveMessage =>
      'Nie zobaczysz już tej grupy. Twoje wcześniejsze wydatki zostaną u pozostałych członków. Żeby wrócić, poproś o kod zaproszenia.';

  @override
  String get leave => 'Opuść';

  @override
  String youLeft(String name) {
    return 'Opuszczono „$name”';
  }

  @override
  String get splitEqualEveryone => 'Po równo · wszyscy';

  @override
  String splitPercentList(String list) {
    return 'Procentowo · $list';
  }

  @override
  String splitSharesList(String list) {
    return 'Udziały · $list';
  }

  @override
  String percentValue(String value) {
    return '$value%';
  }

  @override
  String get defaultSplitHelp =>
      'Nowe wydatki zaczynają od tego podziału. Możesz go nadal zmienić w każdym wydatku.';

  @override
  String get useEqual => 'Użyj podziału po równo';

  @override
  String get inviteCode => 'Kod zaproszenia';

  @override
  String get inviteQrLabel => 'Kod QR linku zaproszenia';

  @override
  String get inviteCodeHelp =>
      'Każdy z tym kodem może dołączyć i wybrać swoje imię.';

  @override
  String inviteShareText(String group, String link, String code) {
    return 'Dołącz do mojej grupy „$group” w Evensies: $link\nAlbo otwórz aplikację i wpisz kod $code';
  }

  @override
  String get rotateCode => 'Zmień kod';

  @override
  String get members => 'Członkowie';

  @override
  String get notJoinedYet =>
      'jeszcze nie dołączył(a) — udostępnij kod zaproszenia';

  @override
  String get linked => 'połączony';

  @override
  String get addPlaceholder => 'Dodaj członka zastępczego';

  @override
  String removeMemberTitle(String name) {
    return 'Usunąć: $name?';
  }

  @override
  String get removeMemberMessage =>
      'Wcześniejsze wydatki i saldo zostaną w grupie.';

  @override
  String removeMemberSeries(int count, String name, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$name wciąż jest w $count wydatkach cyklicznych ($names); udział ($name) zostaje, dopóki nie edytujesz najnowszego.',
      many:
          '$name wciąż jest w $count wydatkach cyklicznych ($names); udział ($name) zostaje, dopóki nie edytujesz najnowszego.',
      few:
          '$name wciąż jest w $count wydatkach cyklicznych ($names); udział ($name) zostaje, dopóki nie edytujesz najnowszego.',
      one:
          '$name wciąż jest w 1 wydatku cyklicznym ($names); udział ($name) zostaje, dopóki nie edytujesz najnowszego.',
    );
    return '$_temp0';
  }

  @override
  String get addMember => 'Dodaj członka';

  @override
  String get rotateInviteTitle => 'Zmienić kod zaproszenia?';

  @override
  String get rotateInviteMessage =>
      'Obecny kod i link przestaną działać. Osoby, które już dołączyły, nie są objęte zmianą.';

  @override
  String get rotate => 'Zmień';

  @override
  String get newInviteReady => 'Nowy kod zaproszenia gotowy';

  @override
  String get activityNeedsConnection => 'Aktywność wymaga połączenia';

  @override
  String get activityOfflineNote =>
      'Ostatnie zmiany pojawią się tu, gdy wrócisz do sieci.';

  @override
  String get noActivityYet => 'Brak aktywności';

  @override
  String get activityAllGroups => 'Tu pojawiają się zmiany w twoich grupach.';

  @override
  String get activityThisGroup => 'Tu pojawiają się zmiany w tej grupie.';

  @override
  String get showingSaved => 'Zapisana aktywność. Pociągnij, żeby odświeżyć.';

  @override
  String get loadMore => 'Wczytaj więcej';

  @override
  String get earlier => 'Wcześniej';

  @override
  String get today => 'Dziś';

  @override
  String get yesterday => 'Wczoraj';

  @override
  String forDate(String date) {
    return 'za $date';
  }

  @override
  String get youCommented => 'Skomentowałeś';

  @override
  String nameCommented(String name) {
    return '$name skomentował(a)';
  }

  @override
  String restoredName(String name) {
    return 'Przywrócono „$name”';
  }

  @override
  String get paymentRestored => 'Przywrócono płatność';

  @override
  String get expenseNotHere => 'Tego wydatku nie ma na tym urządzeniu';

  @override
  String get deletedExpense => 'Usunięty wydatek';

  @override
  String get expense => 'Wydatek';

  @override
  String seriesRepeats(String frequency) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Powtarza się co tydzień',
      'biweekly': 'Powtarza się co 2 tygodnie',
      'monthly': 'Powtarza się co miesiąc',
      'yearly': 'Powtarza się co rok',
      'other': 'Powtarza się',
    });
    return '$_temp0';
  }

  @override
  String seriesRepeatsNext(String frequency, String date) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Powtarza się co tydzień · następny $date',
      'biweekly': 'Powtarza się co 2 tygodnie · następny $date',
      'monthly': 'Powtarza się co miesiąc · następny $date',
      'yearly': 'Powtarza się co rok · następny $date',
      'other': 'Powtarza się · następny $date',
    });
    return '$_temp0';
  }

  @override
  String seriesRepeatsNextAmount(String frequency, String amount, String date) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Powtarza się co tydzień · następny $amount, $date',
      'biweekly': 'Powtarza się co 2 tygodnie · następny $amount, $date',
      'monthly': 'Powtarza się co miesiąc · następny $amount, $date',
      'yearly': 'Powtarza się co rok · następny $amount, $date',
      'other': 'Powtarza się · następny $amount, $date',
    });
    return '$_temp0';
  }

  @override
  String rateLine(String from, String rate, String to) {
    return 'Kurs: 1 $from = $rate $to';
  }

  @override
  String notConvertedTo(String currency) {
    return 'Nieprzeliczone na $currency';
  }

  @override
  String get receivedSplitBack => 'Otrzymane i podzielone z powrotem';

  @override
  String get whoPaidOwes => 'Kto zapłacił i kto jest winien';

  @override
  String get items => 'Pozycje';

  @override
  String get notes => 'Notatki';

  @override
  String get receipts => 'Paragony';

  @override
  String get history => 'Historia';

  @override
  String get deleteExpenseTitle => 'Usunąć wydatek?';

  @override
  String get deleteExpenseMessage =>
      'Zostanie usunięty dla wszystkich w grupie. Możesz go przywrócić z Aktywności.';

  @override
  String get deleteRepeatingTitle => 'Usunąć wydatek cykliczny?';

  @override
  String get deleteRepeatingMessage =>
      'Zostanie usunięty dla wszystkich w grupie. Możesz go przywrócić z Aktywności, ale zatrzymanej serii nie da się wznowić. Dodane już powtórzenia zostają.';

  @override
  String get deleteThisOne => 'Usuń tylko ten';

  @override
  String get deleteAndStop => 'Usuń i przestań powtarzać';

  @override
  String deletedAndStopped(String name) {
    return 'Usunięto „$name” i zatrzymano powtarzanie';
  }

  @override
  String deletedName(String name) {
    return 'Usunięto „$name”';
  }

  @override
  String get movedToOtherGroup => 'Przeniesiono do innej grupy';

  @override
  String get movedNote =>
      'Teraz liczy się tam. Komentarze i historia zostają tutaj.';

  @override
  String get expenseWasDeleted => 'Ten wydatek został usunięty';

  @override
  String get restoreToCount => 'Przywróć go, żeby znów liczył się do sald.';

  @override
  String get tax => 'Podatek';

  @override
  String get tipService => 'Napiwek lub obsługa';

  @override
  String get discount => 'Rabat';

  @override
  String youPaidOwe(String paid, String owe) {
    return 'Zapłaciłeś $paid i jesteś winien $owe';
  }

  @override
  String youPaid(String amount) {
    return 'Zapłaciłeś $amount';
  }

  @override
  String youOwe(String amount) {
    return 'Jesteś winien $amount';
  }

  @override
  String namePaidOwes(String name, String paid, String owe) {
    return '$name: zapłacone $paid, winien $owe';
  }

  @override
  String namePaid(String name, String amount) {
    return '$name: zapłacone $amount';
  }

  @override
  String nameOwes(String name, String amount) {
    return '$name: winien $amount';
  }

  @override
  String youReceivedGetBack(String received, String back) {
    return 'Otrzymałeś $received i odzyskujesz $back';
  }

  @override
  String youReceived(String amount) {
    return 'Otrzymałeś $amount';
  }

  @override
  String youGetBackLine(String amount) {
    return 'Odzyskujesz $amount';
  }

  @override
  String nameReceivedGetsBack(String name, String received, String back) {
    return '$name: otrzymane $received, odzyskuje $back';
  }

  @override
  String nameReceived(String name, String amount) {
    return '$name: otrzymane $amount';
  }

  @override
  String nameGetsBack(String name, String amount) {
    return '$name: odzyskuje $amount';
  }

  @override
  String get noHistoryYet => 'Brak historii.';

  @override
  String get historyOffline => 'Historia pojawi się tu, gdy będziesz online.';

  @override
  String get showingSavedHistory => 'Zapisana historia.';

  @override
  String get showMore => 'Pokaż więcej';

  @override
  String get deleteCommentTitle => 'Usunąć komentarz?';

  @override
  String get comments => 'Komentarze';

  @override
  String get noCommentsYet => 'Brak komentarzy.';

  @override
  String get deleteComment => 'Usuń komentarz';

  @override
  String get addComment => 'Dodaj komentarz';

  @override
  String get send => 'Wyślij';

  @override
  String get filterByCategory => 'Filtruj według kategorii';

  @override
  String get category => 'Kategoria';

  @override
  String get categoryAll => 'Wszystkie';

  @override
  String get month => 'Miesiąc';

  @override
  String get searchUnavailable => 'Wyszukiwanie jest niedostępne';

  @override
  String get searchExpenses => 'Szukaj wydatków';

  @override
  String get searchHelp =>
      'Opisy, notatki, komentarze, kategorie i kwoty: „taksówka”, „lotnisko”, „12,50”.';

  @override
  String get noMatches => 'Brak wyników';

  @override
  String get noMatchesHelp => 'Spróbuj innego słowa albo usuń filtr.';

  @override
  String expenseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wydatku',
      many: '$count wydatków',
      few: '$count wydatki',
      one: '1 wydatek',
    );
    return '$_temp0';
  }

  @override
  String get searchAllGroups => 'Szukaj we wszystkich grupach';

  @override
  String searchGroup(String name) {
    return 'Szukaj w: $name';
  }

  @override
  String get searchThisGroup => 'Szukaj w tej grupie';

  @override
  String get clear => 'Wyczyść';

  @override
  String get thisGroup => 'Ta grupa';

  @override
  String insightsError(String reason) {
    return 'Nie można pokazać statystyk: $reason';
  }

  @override
  String get nothingToShow => 'Na razie nic do pokazania';

  @override
  String get insightsEmptyHelp =>
      'Sumy i wykresy pojawią się, gdy grupa będzie mieć wydatki.';

  @override
  String get allTime => 'Cały okres';

  @override
  String get shareSummary => 'Udostępnij podsumowanie';

  @override
  String get printSummary => 'Drukuj podsumowanie';

  @override
  String get previousMonth => 'Poprzedni miesiąc';

  @override
  String get nextMonth => 'Następny miesiąc';

  @override
  String get byMonth => 'Według miesięcy';

  @override
  String get groupSegment => 'Grupa';

  @override
  String get mineSegment => 'Moje';

  @override
  String get byCategory => 'Według kategorii';

  @override
  String get noExpensesPeriod => 'Brak wydatków w tym okresie.';

  @override
  String get byPerson => 'Według osób';

  @override
  String get nobodyPaidPeriod =>
      'W tym okresie nikt nic nie zapłacił ani nie był winien.';

  @override
  String keptUntilConverted(String currency, String group) {
    return 'Pozostaje w $currency, dopóki nie zostanie przeliczone na $group.';
  }

  @override
  String get totalSpent => 'Wydano łącznie';

  @override
  String get yourShare => 'Twój udział';

  @override
  String get paymentsMade => 'Wysłane płatności';

  @override
  String get paymentsReceived => 'Otrzymane płatności';

  @override
  String get youPaidRow => 'Zapłaciłeś';

  @override
  String get balanceChange => 'Zmiana twojego salda';

  @override
  String get paidLegend => 'Zapłacone';

  @override
  String get shareLegend => 'Udział';

  @override
  String paidShareLine(String paid, String share) {
    return 'zapłacone $paid · udział $share';
  }

  @override
  String get itemsGiveEveryone => 'Przypisz osobę do każdej pozycji';

  @override
  String get itemsAddPrices =>
      'Wpisz ceny pozycji przed podatkiem lub napiwkiem';

  @override
  String get itemsDiscountTooBig => 'Rabat jest większy niż rachunek';

  @override
  String get itemsDontAddUp => 'Pozycje się nie zgadzają';

  @override
  String get adjustmentsDontFit => 'Korekty nie mieszczą się w sumie';

  @override
  String get giveSomeoneShare => 'Daj komuś udział';

  @override
  String get checkNumbers => 'Sprawdź liczby';

  @override
  String get splitDoesntAddUp => 'Podział się nie zgadza';

  @override
  String get addTheItems => 'Dodaj pozycje';

  @override
  String get pickOnePerson => 'Wybierz co najmniej jedną osobę';

  @override
  String splitEquallyBetween(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Po równo na $count osoby',
      many: 'Po równo na $count osób',
      few: 'Po równo na $count osoby',
      one: 'Po równo na 1 osobę',
    );
    return '$_temp0';
  }

  @override
  String get allForOnePerson => 'Wszystko dla 1 osoby';

  @override
  String splitEquallyEach(int count, String amount) {
    return 'Po równo, osób: $count · $amount na osobę';
  }

  @override
  String get checkAmounts => 'Sprawdź kwoty';

  @override
  String get enterTotalFirst => 'Najpierw wpisz sumę';

  @override
  String remaining(String amount) {
    return 'zostało: $amount';
  }

  @override
  String overBy(String amount) {
    return 'za dużo o: $amount';
  }

  @override
  String get addsUp => 'Zgadza się';

  @override
  String sharesInTotal(String count) {
    return 'Udziały łącznie: $count';
  }

  @override
  String get oneShareInTotal => '1 udział łącznie';

  @override
  String get restSplitEqually => 'Reszta jest dzielona po równo';

  @override
  String get byPercent => 'Procentowo';

  @override
  String get byShares => 'Według udziałów';

  @override
  String get byAdjustment =>
      'Korekta: więcej lub mniej dla kogoś, reszta po równo';

  @override
  String get modeEqual => 'Po równo';

  @override
  String get modeExact => 'Dokładnie';

  @override
  String get modeShares => 'Udziały';

  @override
  String get byItem => 'Według pozycji z paragonu';

  @override
  String get adjustmentHelp =>
      'Dodaj lub odejmij komuś kwotę; reszta jest dzielona po równo.';

  @override
  String get noMembers => 'Brak członków';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pozycji',
      many: '$count pozycji',
      few: '$count pozycje',
      one: '1 pozycja',
    );
    return '$_temp0';
  }

  @override
  String get addAnItem => 'Dodaj pozycję';

  @override
  String atMostItems(int max) {
    return 'Najwyżej $max pozycji';
  }

  @override
  String get giveItemName => 'Nazwij każdą pozycję';

  @override
  String get itemNameTooLong => 'Nazwa pozycji jest za długa';

  @override
  String get addItem => 'Dodaj pozycję';

  @override
  String get giveRestToEveryone => 'Resztę daj wszystkim';

  @override
  String get subtotal => 'Suma częściowa';

  @override
  String get total => 'Suma';

  @override
  String receiptSays(String printed, String difference) {
    return 'Paragon mówi $printed · pozycje różnią się o $difference';
  }

  @override
  String get eachPerson => 'Na osobę';

  @override
  String itemsWithoutPerson(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pozycji bez osoby',
      many: '$count pozycji bez osoby',
      few: '$count pozycje bez osoby',
      one: '1 pozycja bez osoby',
    );
    return '$_temp0';
  }

  @override
  String get itemHint => 'Pozycja';

  @override
  String memberLeft(String name) {
    return '$name (odszedł)';
  }

  @override
  String get whoHadThis => 'Kto to miał?';

  @override
  String get defaultSplitStartsEqual =>
      'Domyślny podział grupy już się nie zgadza, więc ten zaczyna się po równo';

  @override
  String leftToAssign(String amount) {
    return 'Do przypisania zostało $amount';
  }

  @override
  String get itemsTotal => 'Suma pozycji';

  @override
  String get newExpense => 'Nowy wydatek';

  @override
  String get editExpense => 'Edytuj wydatek';

  @override
  String get scanReceipt => 'Skanuj paragon';

  @override
  String get rateAboveZeroOrEmpty =>
      'Wpisz kurs większy od 0 albo zostaw puste';

  @override
  String useAutoRate(String rate, String source) {
    return 'Użyj kursu automatycznego: $rate ($source)';
  }

  @override
  String get description => 'Opis';

  @override
  String get receivedBy => 'Otrzymał(a)';

  @override
  String get paidBy => 'Zapłacił(a)';

  @override
  String get severalPeople => 'Kilka osób';

  @override
  String get when => 'Kiedy';

  @override
  String get refundTooltip =>
      'Pieniądze, które wróciły, np. kaucja zwrócona przez hotel';

  @override
  String get splitBackTo => 'Podzielone z powrotem na';

  @override
  String get split => 'Podział';

  @override
  String theyOweFull(String name) {
    return '$name jest winien całą kwotę';
  }

  @override
  String iOweFull(String name) {
    return 'Jestem winien całą kwotę: $name';
  }

  @override
  String get repeat => 'Powtarzaj';

  @override
  String editLatestRepeat(String date) {
    return 'Żeby zmienić przyszłe powtórzenia, edytuj najnowsze ($date)';
  }

  @override
  String get stopsRepeating =>
      'Przestaje się powtarzać. Dodane już powtórzenia zostają.';

  @override
  String nextRepeat(String date) {
    return 'Następny: $date';
  }

  @override
  String get alsoChangeFuture => 'Zmień też przyszłe powtórzenia';

  @override
  String get futureFields =>
      'Kwota, podział, płacący, opis, kategoria i notatki';

  @override
  String get onlyThisOne => 'Zmienia się tylko ten';

  @override
  String get addPhoto => 'Dodaj zdjęcie';

  @override
  String maxReceiptsNote(int max) {
    return 'Najwyżej $max paragonów na wydatek';
  }

  @override
  String get scanAReceipt => 'Skanuj paragon';

  @override
  String receiptLooksLike(String currency) {
    return 'Ten paragon wygląda na walutę $currency';
  }

  @override
  String switchToCurrencyQuestion(String currency) {
    return 'Zmienić walutę wydatku na $currency, żeby odczytać pozycje?';
  }

  @override
  String switchTo(String currency) {
    return 'Zmień na $currency';
  }

  @override
  String get couldntReadItems => 'Nie udało się odczytać pozycji. Wpisz je.';

  @override
  String withName(String name) {
    return 'Z: $name';
  }

  @override
  String movesTo(String name) {
    return 'Po zapisaniu trafi do: $name';
  }

  @override
  String fromName(String name) {
    return 'Z: $name';
  }

  @override
  String get dontMove => 'Nie przenoś';

  @override
  String get onlyLinkedMove =>
      'Przenieść można tylko osoby z Evensies obecne w obu miejscach';

  @override
  String get auto => 'auto';

  @override
  String get noAutoRateForm =>
      'Brak automatycznego kursu. Wpisz go albo zostaw puste, żeby został w „Nieprzeliczone”.';

  @override
  String get emptyNotConverted => 'Puste: zostaje w „Nieprzeliczone”';

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
  String get yourRate => 'twój kurs';

  @override
  String get loginEmail => 'Kontynuuj przez e-mail';

  @override
  String get emailLoginTitle => 'Zaloguj się e-mailem';

  @override
  String get emailLoginIntro => 'Wyślemy ci e-mailem 6-cyfrowy kod. Bez hasła.';

  @override
  String get emailLabel => 'E-mail';

  @override
  String get emailInvalid => 'Wpisz poprawny adres e-mail';

  @override
  String get sendCode => 'Wyślij kod';

  @override
  String codeSentTo(String email) {
    return 'Wpisz 6-cyfrowy kod wysłany na $email. Wygaśnie za 10 minut.';
  }

  @override
  String get codeLabel => '6-cyfrowy kod';

  @override
  String get verifyCode => 'Dalej';

  @override
  String get resendCode => 'Wyślij kod ponownie';

  @override
  String resendCodeIn(int seconds) {
    return 'Wyślij ponownie za $seconds s';
  }

  @override
  String get codeResent => 'Wysłaliśmy nowy kod.';

  @override
  String get useDifferentEmail => 'Użyj innego adresu';

  @override
  String get codeCheckSpam => 'Nic nie przyszło? Sprawdź folder spam.';

  @override
  String get errorCodeInvalid => 'Kod jest błędny albo wygasł. Poproś o nowy.';

  @override
  String get errorEmailNotConfigured => 'Ten serwer nie wysyła e-maili.';

  @override
  String get errorEmailRejected =>
      'Ten adres nie może odbierać e-maili. Sprawdź, czy nie ma literówki.';

  @override
  String get errorEmailTaken => 'Inne konto już używa tego adresu.';

  @override
  String get errorEmailRequired =>
      'E-mail to twój jedyny sposób logowania, więc nie można go usunąć.';

  @override
  String get errorEmailUnavailable =>
      'E-mail teraz nie działa. Spróbuj później.';

  @override
  String get emailSaved => 'E-mail zapisany';

  @override
  String removeEmailTitle(String email) {
    return 'Usunąć $email?';
  }

  @override
  String get removeEmailMessage =>
      'Nie dostaniesz już podsumowań ani przypomnień e-mailem i nie zalogujesz się tym adresem.';

  @override
  String get emailRemoved => 'E-mail usunięty';

  @override
  String get emailNeedsConnection => 'Zmiana e-maila wymaga połączenia.';

  @override
  String get emailBouncedNote =>
      'E-maile na ten adres wracają — zmień go albo potwierdź ponownie';

  @override
  String get emailVerifiedNote =>
      'Potwierdzony · inni członkowie nigdy go nie widzą';

  @override
  String get changeEmail => 'Zmień e-mail';

  @override
  String get emailAccountHelp =>
      'Do logowania i podsumowań e-mailem. Wysyłamy kod, żeby sprawdzić, że to twój adres. Inni członkowie nigdy go nie widzą.';

  @override
  String get removeEmail => 'Usuń e-mail';

  @override
  String get addEmail => 'Dodaj e-mail';

  @override
  String get addEmailHint => 'Loguj się nim i dostawaj podsumowania e-mailem';

  @override
  String unblockedName(String name) {
    return 'Odblokowano: $name';
  }

  @override
  String get blockNeedsConnection => 'Blokowanie wymaga połączenia.';

  @override
  String get blockedEmpty => 'Nikogo nie blokujesz.';

  @override
  String get blockedNeedsConnection => 'Lista zablokowanych wymaga połączenia';

  @override
  String get unblock => 'Odblokuj';

  @override
  String get blockedPeople => 'Zablokowane osoby';

  @override
  String get blockedHelp =>
      'Zablokowane osoby nie mogą dodać cię do znajomych ani wysyłać przypomnień, a ich zmiany nie dają ci powiadomień ani e-maili. Wspólne grupy i salda zostają bez zmian.';

  @override
  String get deletedGroupsEmpty => 'Brak usuniętych grup';

  @override
  String get deletedGroupsHelp =>
      'Przywrócenie oddaje grupę wszystkim, z całą zawartością.';

  @override
  String get deletedGroups => 'Usunięte grupy';

  @override
  String deletedGroupsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count grupy można przywrócić',
      many: '$count grup można przywrócić',
      few: '$count grupy można przywrócić',
      one: '1 grupę można przywrócić',
    );
    return '$_temp0';
  }

  @override
  String get exportNeedsConnection => 'Eksport wymaga połączenia.';

  @override
  String get exportEverything => 'Eksportuj wszystko (JSON)';

  @override
  String get exportEverythingHint =>
      'Twój profil, sposoby otrzymywania płatności, ustawienia i każda grupa, także usunięte';

  @override
  String get emailSummary => 'Podsumowanie e-mailem';

  @override
  String digestChoice(String choice) {
    String _temp0 = intl.Intl.selectLogic(choice, {
      'auto': 'Automatycznie',
      'daily': 'Codziennie',
      'weekly': 'Co tydzień',
      'monthly': 'Co miesiąc',
      'off': 'Wyłączone',
      'other': 'Automatycznie',
    });
    return '$_temp0';
  }

  @override
  String get digestAutoHelp =>
      'Codziennie, gdy twoje urządzenia nie mogą pokazywać powiadomień, w przeciwnym razie co miesiąc';

  @override
  String get digestAutoDaily =>
      'Automatycznie — codziennie, bo powiadomienia są wyłączone';

  @override
  String get digestAutoMonthly =>
      'Automatycznie — co miesiąc, bo twoje urządzenia dostają powiadomienia';

  @override
  String get digestNoEmail =>
      'Dodaj e-mail w sekcji Konto, żeby dostawać podsumowania';

  @override
  String get helpReportProblem => 'Zgłoś problem albo zaproponuj funkcję';

  @override
  String get helpReportProblemHint =>
      'Na GitHubie, gdzie każdy może to zobaczyć';

  @override
  String get helpContact => 'Napisz do pomocy';

  @override
  String get privacyPolicy => 'Polityka prywatności';

  @override
  String get helpFeedback => 'Pomoc i opinie';

  @override
  String get signOutEverywhere => 'Wyloguj na wszystkich urządzeniach';

  @override
  String get signOutEverywhereTitle => 'Wylogować na wszystkich urządzeniach?';

  @override
  String get signOutEverywhereMessage =>
      'Każdy telefon i przeglądarka z twoim kontem zostanie wylogowany, to urządzenie też. Twoje grupy zostają na serwerze.';

  @override
  String get signOutEverywhereOffline =>
      'Wylogowanie na wszystkich urządzeniach wymaga połączenia.';

  @override
  String get deleteAccountExportTip =>
      'Wskazówka: najpierw wyeksportuj wszystko.';

  @override
  String get coverPhoto => 'Zdjęcie w tle';

  @override
  String get coverPhotoHint =>
      'Widoczne u góry grupy i na liście. Widzą je tylko członkowie.';

  @override
  String get removeCover => 'Usuń zdjęcie w tle';

  @override
  String get coverNeedsConnection => 'Zmiana zdjęcia w tle wymaga połączenia.';

  @override
  String get coverTooMany => 'To dużo zmian zdjęcia w tle. Spróbuj za godzinę.';

  @override
  String get deleteGroup => 'Usuń grupę';

  @override
  String get deleteGroupHint =>
      'Dla wszystkich · każdy członek może ją przywrócić';

  @override
  String deleteGroupTitle(String name) {
    return 'Usunąć „$name”?';
  }

  @override
  String get deleteGroupMessage =>
      'Usunięta dla wszystkich. Każdy członek może ją przywrócić w Ustawienia → Usunięte grupy.';

  @override
  String groupDeletedName(String name) {
    return 'Usunięto „$name”';
  }

  @override
  String get groupDeletedBanner => 'Ta grupa jest usunięta';

  @override
  String get groupRestored => 'Grupa przywrócona';

  @override
  String get deleteFriend => 'Usuń znajomego';

  @override
  String deleteFriendTitle(String name) {
    return 'Usunąć: $name?';
  }

  @override
  String deleteFriendMessage(String name) {
    return 'Twoje wydatki poza grupą z osobą $name zostaną usunięte dla was obojga. Wspólne grupy zostają. Możesz je przywrócić w Ustawienia → Usunięte grupy albo dodając znowu: $name.';
  }

  @override
  String friendDeleted(String name) {
    return 'Usunięto: $name';
  }

  @override
  String get block => 'Zablokuj';

  @override
  String blockTitle(String name) {
    return 'Zablokować: $name?';
  }

  @override
  String blockMessage(String name) {
    return '$name nie będzie mógł dodać cię do znajomych ani wysyłać przypomnień, a jego zmiany nie dadzą ci powiadomień ani e-maili. Wspólne grupy i salda zostają.';
  }

  @override
  String blockedName(String name) {
    return 'Zablokowano: $name';
  }

  @override
  String get report => 'Zgłoś…';

  @override
  String get reportSubject => 'Zgłoszenie w Evensies';

  @override
  String reportBody(String userId) {
    return 'ID użytkownika: $userId\n\nCo się stało:\n';
  }

  @override
  String get inviteByEmail => 'Zaproś e-mailem…';

  @override
  String get inviteEmailField => 'E-mail (opcjonalnie)';

  @override
  String get inviteEmailHelp =>
      'Wyślemy e-mailem link z zaproszeniem. Użyty tylko do tego zaproszenia.';

  @override
  String inviteByEmailTitle(String name) {
    return 'Zaproś e-mailem: $name';
  }

  @override
  String inviteEmailSent(String email) {
    return 'Wysłano zaproszenie na $email';
  }

  @override
  String get inviteEmailOfflineAdded =>
      'Dodano członka. Zaproszenie e-mailem wymaga połączenia — spróbuj ponownie z listy członków.';

  @override
  String get inviteEmailOffline => 'Zaproszenie e-mailem wymaga połączenia.';

  @override
  String get inviteEmailLimit =>
      'Osiągnięto dzisiejszy limit e-maili — udostępnij link zamiast tego.';

  @override
  String emailReminder(String choice) {
    return 'Przypomnienie e-mailem: $choice';
  }

  @override
  String get remindNever => 'Nigdy';

  @override
  String remindDaysBefore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dni wcześniej',
      one: '1 dzień wcześniej',
    );
    return '$_temp0';
  }

  @override
  String get blurbUpi =>
      'Indie: Paytm, PhonePe, Google Pay i inne aplikacje UPI';

  @override
  String get fieldUpi => 'Identyfikator UPI';

  @override
  String get fieldUpiHint => 'Na przykład imie@okicici';

  @override
  String get fieldUpiName => 'Imię (opcjonalnie)';

  @override
  String get fieldUpiNameHint => 'Widzi je osoba, która ci płaci';

  @override
  String get methodErrorUpi => 'Wpisz identyfikator UPI, np. imie@bank';

  @override
  String get noUpiApp =>
      'Nie znaleziono aplikacji UPI. Skopiuj zamiast tego identyfikator UPI i kwotę.';

  @override
  String get upiIdLabel => 'Identyfikator UPI';

  @override
  String get copyUpiId => 'Kopiuj identyfikator UPI';

  @override
  String get upiIdCopied => 'Skopiowano identyfikator UPI';

  @override
  String get dashboard => 'Pulpit';

  @override
  String get allExpenses => 'Wszystkie wydatki';

  @override
  String get groupBalances => 'Salda grupy';

  @override
  String get yourBalance => 'Twoje saldo';

  @override
  String get dashboardOwesYou => 'Winni tobie';

  @override
  String get dashboardYouOwe => 'Jesteś winien';

  @override
  String get historyAndComments => 'Historia i komentarze';

  @override
  String get showEarlier => 'Pokaż wcześniejsze';

  @override
  String get settleUpFirst => 'Najpierw się rozlicz';

  @override
  String deleteFriendSettleFirst(String name) {
    return 'Możesz usunąć znajomego ($name), gdy wydatki poza grupami będą rozliczone.';
  }

  @override
  String get noMailApp =>
      'Nie znaleziono aplikacji pocztowej. Skopiuj poniższe dane i napisz z dowolnej aplikacji pocztowej.';

  @override
  String get copyAddress => 'Kopiuj adres';

  @override
  String get copyMessage => 'Kopiuj wiadomość';

  @override
  String get browserNoStorage =>
      'Ta przeglądarka nie może przechowywać danych Evensies. Spróbuj innej przeglądarki lub okna, które nie jest prywatne.';

  @override
  String get browserOtherTab =>
      'Aplikacja Evensies jest już otwarta w innej karcie tej przeglądarki. Użyj tamtej karty albo zamknij ją i odśwież tę.';
}
