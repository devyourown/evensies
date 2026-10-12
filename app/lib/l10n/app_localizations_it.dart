// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'Evensies';

  @override
  String get cancel => 'Annulla';

  @override
  String get delete => 'Elimina';

  @override
  String get remove => 'Rimuovi';

  @override
  String get save => 'Salva';

  @override
  String get done => 'Fatto';

  @override
  String get undo => 'Annulla';

  @override
  String get retry => 'Riprova';

  @override
  String get ok => 'OK';

  @override
  String get close => 'Chiudi';

  @override
  String get edit => 'Modifica';

  @override
  String get add => 'Aggiungi';

  @override
  String get offlineBanner =>
      'Offline — le modifiche verranno sincronizzate più tardi';

  @override
  String get tooLong => 'Troppo lungo';

  @override
  String get allCurrencies => 'Tutte le valute';

  @override
  String get errorUnexpected => 'Qualcosa è andato storto. Riprova.';

  @override
  String get errorNetwork => 'Sei offline. Riprova più tardi.';

  @override
  String get errorRateLimited =>
      'Troppi tentativi. Aspetta un minuto e riprova.';

  @override
  String get errorNotFound => 'Non esiste più.';

  @override
  String get errorForbidden => 'Non puoi farlo.';

  @override
  String get errorValidation => 'Il server l\'ha rifiutato.';

  @override
  String get errorSumMismatch => 'La divisione non torna.';

  @override
  String get errorPayersSumMismatch => 'I pagamenti non tornano.';

  @override
  String get errorNegativeAmount => 'Un importo è sotto zero.';

  @override
  String get errorNegativeShare => 'La quota di qualcuno sarebbe sotto zero.';

  @override
  String get errorNegativeTotal => 'Il totale sarebbe sotto zero.';

  @override
  String get errorZeroSubtotal =>
      'Inserisci i prezzi delle voci prima di tasse, mance o sconti.';

  @override
  String get errorUnassignedItem =>
      'Ogni voce ha bisogno di almeno una persona.';

  @override
  String get errorNoMembers => 'Scegli almeno una persona con cui dividere.';

  @override
  String get errorInvalidInput => 'Controlla i numeri.';

  @override
  String get errorBadRate => 'Il tasso di cambio deve essere sopra zero.';

  @override
  String get errorUnknownMember => 'Riguarda qualcuno che non è nel gruppo.';

  @override
  String get errorUnknownCurrency => 'La valuta non è supportata.';

  @override
  String get errorMemberTaken => 'Questo membro è già stato scelto.';

  @override
  String get errorLimitExceeded => 'Hai raggiunto il limite.';

  @override
  String get errorTooLarge => 'La foto è troppo grande.';

  @override
  String get errorNotJpeg => 'Scegli una foto JPEG';

  @override
  String get errorFxUnavailable =>
      'I tassi di cambio non sono disponibili al momento.';

  @override
  String get errorImportFailed =>
      'Non è stato possibile importare questo file.';

  @override
  String get errorAuthNotConfigured =>
      'Questo server non può farti accedere in questo modo.';

  @override
  String get errorDuplicate => 'Esiste già.';

  @override
  String errorGeneric(String code) {
    return 'Qualcosa è andato storto ($code).';
  }

  @override
  String rejectedReceipt(String name, String reason) {
    return 'Impossibile salvare lo scontrino di “$name”: $reason';
  }

  @override
  String rejectedReceiptUnnamed(String reason) {
    return 'Impossibile salvare lo scontrino di una spesa: $reason';
  }

  @override
  String rejectedReceiptRemove(String name, String reason) {
    return 'Impossibile salvare la rimozione di uno scontrino da “$name”: $reason';
  }

  @override
  String rejectedReceiptRemoveUnnamed(String reason) {
    return 'Impossibile salvare la rimozione di uno scontrino da una spesa: $reason';
  }

  @override
  String rejectedRepeating(String name, String reason) {
    return 'Impossibile salvare la ripetizione di “$name”: $reason';
  }

  @override
  String rejectedRepeatingUnnamed(String reason) {
    return 'Impossibile salvare una spesa ricorrente: $reason';
  }

  @override
  String rejectedSeriesChange(String name, String reason) {
    return 'Impossibile salvare una modifica ai prossimi “$name”: $reason';
  }

  @override
  String rejectedSeriesChangeUnnamed(String reason) {
    return 'Impossibile salvare una modifica a una spesa ricorrente: $reason';
  }

  @override
  String rejectedSeriesStop(String name, String reason) {
    return 'Impossibile salvare l\'interruzione di “$name”: $reason';
  }

  @override
  String rejectedSeriesStopUnnamed(String reason) {
    return 'Impossibile salvare l\'interruzione di una spesa ricorrente: $reason';
  }

  @override
  String rejectedSavedNoRepeat(String name, String reason) {
    return '“$name” è stata salvata ma non si ripeterà: $reason';
  }

  @override
  String rejectedPaymentRestore(String reason) {
    return 'Impossibile salvare il ripristino di un pagamento: $reason';
  }

  @override
  String rejectedNewExpense(String name, String reason) {
    return 'Impossibile salvare la nuova spesa “$name”: $reason';
  }

  @override
  String rejectedNewExpenseUnnamed(String reason) {
    return 'Impossibile salvare una nuova spesa: $reason';
  }

  @override
  String rejectedExpenseChange(String name, String reason) {
    return 'Impossibile salvare una modifica a “$name”: $reason';
  }

  @override
  String rejectedExpenseChangeUnnamed(String reason) {
    return 'Impossibile salvare una modifica a una spesa: $reason';
  }

  @override
  String rejectedExpenseDelete(String name, String reason) {
    return 'Impossibile salvare l\'eliminazione di “$name”: $reason';
  }

  @override
  String rejectedExpenseDeleteUnnamed(String reason) {
    return 'Impossibile salvare l\'eliminazione di una spesa: $reason';
  }

  @override
  String rejectedExpenseRestore(String name, String reason) {
    return 'Impossibile salvare il ripristino di “$name”: $reason';
  }

  @override
  String rejectedExpenseRestoreUnnamed(String reason) {
    return 'Impossibile salvare il ripristino di una spesa: $reason';
  }

  @override
  String rejectedComment(String name, String reason) {
    return 'Impossibile salvare un commento su “$name”: $reason';
  }

  @override
  String rejectedCommentUnnamed(String reason) {
    return 'Impossibile salvare un commento su una spesa: $reason';
  }

  @override
  String rejectedPaymentComment(String reason) {
    return 'Impossibile salvare un commento su un pagamento: $reason';
  }

  @override
  String rejectedCommentDelete(String reason) {
    return 'Impossibile salvare l\'eliminazione di un commento: $reason';
  }

  @override
  String rejectedPayment(String reason) {
    return 'Impossibile salvare un pagamento: $reason';
  }

  @override
  String rejectedPaymentDelete(String reason) {
    return 'Impossibile salvare l\'eliminazione di un pagamento: $reason';
  }

  @override
  String rejectedPaymentConfirm(String reason) {
    return 'Impossibile salvare la conferma di un pagamento: $reason';
  }

  @override
  String rejectedGroupSettings(String reason) {
    return 'Impossibile salvare una modifica alle impostazioni del gruppo: $reason';
  }

  @override
  String rejectedMemberAdd(String name, String reason) {
    return 'Impossibile salvare l\'aggiunta di $name: $reason';
  }

  @override
  String rejectedMemberAddUnnamed(String reason) {
    return 'Impossibile salvare l\'aggiunta di un membro: $reason';
  }

  @override
  String rejectedMemberRemove(String reason) {
    return 'Impossibile salvare la rimozione di un membro: $reason';
  }

  @override
  String rejectedOther(String reason) {
    return 'Impossibile salvare una modifica: $reason';
  }

  @override
  String get reasonReceiptLimit =>
      'una spesa può avere al massimo 10 scontrini';

  @override
  String get reasonSeriesLimit =>
      'un gruppo può avere al massimo 100 spese ricorrenti';

  @override
  String get reasonNotUploaded => 'la foto non è stata caricata';

  @override
  String get reasonSumMismatch => 'la divisione non torna';

  @override
  String get reasonPayersSumMismatch => 'i pagamenti non tornano';

  @override
  String get reasonNegativeAmount => 'un importo è sotto zero';

  @override
  String get reasonUnknownMember => 'riguarda qualcuno che non è nel gruppo';

  @override
  String get reasonUnknownCurrency => 'la valuta non è supportata';

  @override
  String get reasonMemberTaken => 'questo membro è già stato scelto';

  @override
  String get reasonGroupFull => 'il gruppo è pieno';

  @override
  String get reasonForbidden => 'non puoi fare questa modifica';

  @override
  String get reasonRefused => 'il server l\'ha rifiutata';

  @override
  String leaveOwe(String amount) {
    return 'Devi $amount · salda prima';
  }

  @override
  String leaveOweIn(String amount, String currency) {
    return 'Devi $amount · salda prima in $currency';
  }

  @override
  String leaveOwed(String amount) {
    return 'Ti devono $amount · salda prima';
  }

  @override
  String leaveOwedIn(String amount, String currency) {
    return 'Ti devono $amount · salda prima in $currency';
  }

  @override
  String leaveSeries(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Sei ancora in $count spese ricorrenti ($names) · modifica l\'ultima o interrompile prima',
      one:
          'Sei ancora in 1 spesa ricorrente ($names) · modifica l\'ultima o interrompila prima',
    );
    return '$_temp0';
  }

  @override
  String seriesNamesMore(String names, int count) {
    return '$names e altre $count';
  }

  @override
  String get seriesUnnamed => 'una spesa';

  @override
  String get listJoiner => ', ';

  @override
  String get repeatNever => 'Mai';

  @override
  String get repeatWeekly => 'Ogni settimana';

  @override
  String get repeatBiweekly => 'Ogni 2 settimane';

  @override
  String get repeatMonthly => 'Ogni mese';

  @override
  String get repeatYearly => 'Ogni anno';

  @override
  String summaryNotConverted(String currency) {
    return 'Non convertito · $currency';
  }

  @override
  String summaryTotalSpent(String amount) {
    return 'Spesa totale: $amount';
  }

  @override
  String summaryPaidShare(String paid, String share) {
    return 'Hai pagato: $paid · La tua quota: $share';
  }

  @override
  String summaryPayments(String made, String received) {
    return 'Pagamenti fatti: $made · ricevuti: $received';
  }

  @override
  String summaryTopCategories(String list) {
    return 'Categorie principali: $list';
  }

  @override
  String get summaryBalancesToday => 'Saldi di oggi';

  @override
  String summaryGetsBack(String name, String amount) {
    return '$name riceve $amount';
  }

  @override
  String summaryOwes(String name, String amount) {
    return '$name deve $amount';
  }

  @override
  String get summaryFooter => 'Condiviso da Evensies';

  @override
  String get koreanBank => 'Conto bancario coreano';

  @override
  String requestText(String amount, String group) {
    return 'Mi devi $amount per $group su Evensies.';
  }

  @override
  String requestTextWays(String amount, String group, String ways) {
    return 'Mi devi $amount per $group su Evensies. Paga con: $ways';
  }

  @override
  String get requestNoGroup => 'le nostre spese condivise';

  @override
  String get leaveSyncing =>
      'Sincronizzazione in corso. Riprova tra un attimo.';

  @override
  String get leaveOffline => 'Devi essere online per uscire';

  @override
  String get moveOffline => 'Impossibile spostarla. Riprova quando sei online';

  @override
  String moveFailed(String reason) {
    return 'Impossibile spostarla: $reason';
  }

  @override
  String get photoNoAccess =>
      'Evensies non ha accesso. Consentilo nell\'app Impostazioni.';

  @override
  String get photoNoCamera => 'Impossibile aprire la fotocamera.';

  @override
  String get photoNoLibrary => 'Impossibile aprire la libreria foto.';

  @override
  String get photoUnusable =>
      'Non è stato possibile usare questa foto. Provane un\'altra.';

  @override
  String get methodErrorUsername => 'Solo lettere, cifre, . _ - (max 40)';

  @override
  String methodErrorLinkPrefix(String prefix) {
    return 'Deve iniziare con $prefix';
  }

  @override
  String get methodErrorTooLong => 'Max 200 caratteri';

  @override
  String get methodErrorIban => 'IBAN non valido';

  @override
  String get methodErrorHolder => 'Nome dell\'intestatario (1–70 caratteri)';

  @override
  String get methodErrorBic => 'Il BIC ha 8 o 11 caratteri';

  @override
  String get methodErrorKrAccount => 'Cifre e trattini, 8–20 cifre';

  @override
  String get methodErrorBank => 'Nome della banca (1–30 caratteri)';

  @override
  String get methodErrorUnknownType => 'Tipo sconosciuto';

  @override
  String get methodErrorTooMany =>
      'Al massimo 8 modi per farti pagare, e 3 per ogni tipo di conto';

  @override
  String get bannerDismiss => 'Chiudi';

  @override
  String get bannerView => 'Vedi';

  @override
  String get loginTagline =>
      'Dividi le spese con gli amici. Niente pubblicità, niente upsell.';

  @override
  String get loginApple => 'Continua con Apple';

  @override
  String get loginGoogle => 'Continua con Google';

  @override
  String get loginWebUnavailable =>
      'Questo server non ha ancora l\'accesso dal browser.';

  @override
  String get welcomeTitle => 'Benvenuto';

  @override
  String get yourNameTitle => 'Il tuo nome';

  @override
  String get nameQuestion => 'Come devono chiamarti i tuoi amici?';

  @override
  String get nameExplain => 'Questo è il nome che vedono gli altri membri.';

  @override
  String get nameHelp =>
      'È visibile alle persone dei tuoi gruppi. Puoi cambiarlo più tardi nelle Impostazioni.';

  @override
  String get nameLabel => 'Nome';

  @override
  String get lockReason => 'Sblocca Evensies';

  @override
  String get lockTitle => 'Evensies è bloccata';

  @override
  String get lockSubtitle =>
      'Sblocca con Face ID, Touch ID, l\'impronta o il codice del dispositivo.';

  @override
  String get lockUnlock => 'Sblocca';

  @override
  String get lockSignOutConfirm =>
      'Uscire e rimuovere i dati da questo dispositivo? I tuoi gruppi restano sul server.';

  @override
  String get signOut => 'Esci';

  @override
  String get widgetOwed => 'Ti devono';

  @override
  String get widgetOwe => 'Devi';

  @override
  String get widgetSignedOut => 'Accedi per vedere il tuo saldo';

  @override
  String get widgetSettled => 'Tutto in pari';

  @override
  String widgetUpdated(String time) {
    return 'Aggiornato $time';
  }

  @override
  String get receiptAdd => 'Aggiungi uno scontrino';

  @override
  String get photoTake => 'Scatta una foto';

  @override
  String get photoChoose => 'Scegli dalla libreria';

  @override
  String get photoChooseFile => 'Scegli un file';

  @override
  String get availableWhenOnline => 'Disponibile online';

  @override
  String get receiptPhoto => 'Foto dello scontrino';

  @override
  String get receiptAvailableOnline => 'La foto è disponibile online';

  @override
  String get receiptRemoveTitle => 'Rimuovere lo scontrino?';

  @override
  String get receiptRemoveMessage => 'Viene rimosso per tutti nel gruppo.';

  @override
  String get receiptTitle => 'Scontrino';

  @override
  String receiptTitleOf(int index, int count) {
    return 'Scontrino $index di $count';
  }

  @override
  String get shareOrSave => 'Condividi o salva';

  @override
  String get share => 'Condividi';

  @override
  String get copiedToClipboard => 'Copiato negli appunti';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get photoRemove => 'Rimuovi foto';

  @override
  String get photoNeedsConnection =>
      'Per cambiare la foto serve una connessione.';

  @override
  String get photoTooMany => 'Troppi cambi di foto. Riprova tra un\'ora.';

  @override
  String get notifSaveFailed =>
      'Impossibile salvare le impostazioni delle notifiche. Controlla la connessione.';

  @override
  String get homeCurrencyNeedsConnection =>
      'Per cambiare la valuta di casa serve una connessione.';

  @override
  String get changePhoto => 'Cambia foto profilo';

  @override
  String get yourNameTapToChange => 'Il tuo nome · tocca per cambiarlo';

  @override
  String get waysToGetPaid => 'Modi per farti pagare';

  @override
  String get waysToGetPaidHint => 'PayPal, Wise, IBAN, conto bancario…';

  @override
  String get homeCurrency => 'Valuta di casa';

  @override
  String get homeCurrencyFromRegion =>
      'Dalla tua regione · i saldi mostrano anche ≈ in questa valuta';

  @override
  String get homeCurrencyPicked => 'I saldi mostrano anche ≈ in questa valuta';

  @override
  String get notifications => 'Notifiche';

  @override
  String get notifExpenses => 'Spese e pagamenti';

  @override
  String get notifComments => 'Commenti';

  @override
  String get notifMembers => 'Membri e modifiche al gruppo';

  @override
  String get notifReminders => 'Promemoria dagli amici';

  @override
  String get notifNeedConnection =>
      'Le impostazioni delle notifiche richiedono una connessione';

  @override
  String get notifOthersOnly =>
      'Ricevi notifiche solo per le modifiche degli altri.';

  @override
  String get notifWebNote =>
      'Le notifiche arrivano sul telefono; il browser si aggiorna ogni minuto mentre è aperto.';

  @override
  String get exportImport => 'Esporta e importa';

  @override
  String get noGroupsToExport => 'Nessun gruppo da esportare.';

  @override
  String get nonGroup => 'Fuori dai gruppi';

  @override
  String nonGroupWith(String name) {
    return 'Fuori dai gruppi · $name';
  }

  @override
  String get exportJson => 'Esporta JSON';

  @override
  String get exportCsv => 'Esporta CSV';

  @override
  String get exportZip => 'ZIP con scontrini';

  @override
  String get importSplitwise => 'Importa CSV di Splitwise';

  @override
  String importedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count spese importate',
      one: '1 spesa importata',
    );
    return '$_temp0';
  }

  @override
  String get server => 'Server';

  @override
  String get serverUrl => 'URL del server';

  @override
  String serverDefault(String url) {
    return 'Predefinito: $url';
  }

  @override
  String get serverSaved => 'URL del server salvato';

  @override
  String get account => 'Account';

  @override
  String get licenses => 'Licenze';

  @override
  String get deleteAccount => 'Elimina account';

  @override
  String get signOutTitle => 'Uscire?';

  @override
  String get signOutMessage =>
      'I dati locali su questo dispositivo vengono rimossi. Le modifiche non ancora sincronizzate andranno perse.';

  @override
  String get deleteAccountTitle => 'Eliminare l\'account?';

  @override
  String get deleteAccountMessage =>
      'Le tue iscrizioni diventano segnaposto. I dati dei gruppi restano agli altri membri. Non si può annullare.';

  @override
  String get language => 'Lingua';

  @override
  String languageSystem(String language) {
    return 'Sistema ($language)';
  }

  @override
  String get appearance => 'Aspetto';

  @override
  String get appearanceSystem => 'Sistema';

  @override
  String get appearanceLight => 'Chiaro';

  @override
  String get appearanceDark => 'Scuro';

  @override
  String get security => 'Sicurezza';

  @override
  String get appLock => 'Blocco app';

  @override
  String get appLockHint =>
      'Face ID, Touch ID o impronta, con il codice del dispositivo come riserva. Si blocca dopo un minuto di assenza.';

  @override
  String methodRemoveTitle(String method) {
    return 'Rimuovere $method?';
  }

  @override
  String get methodsOffline =>
      'Connettiti a internet per modificare i modi per farti pagare.';

  @override
  String get methodsLoadFailed =>
      'Impossibile caricare i modi per farti pagare.';

  @override
  String get methodsIntro =>
      'I membri del gruppo li vedono quando ti devono soldi, così possono pagarti con un tocco. Evensies non sposta mai denaro.';

  @override
  String get methodsEmpty => 'Nessun modo per farti pagare.';

  @override
  String get blurbPaypal => 'Link PayPal.me, importo già inserito';

  @override
  String get blurbWise => 'Link Wise Quick Pay, importo già inserito';

  @override
  String get blurbVenmo => 'Nome utente Venmo (USA)';

  @override
  String get blurbRevolut => 'Nome utente Revolut.me';

  @override
  String get blurbKakaopay => 'Link 송금코드 di KakaoPay';

  @override
  String get blurbIban => 'Bonifico (QR SEPA per EUR)';

  @override
  String get blurbKrBank => 'Conto bancario coreano (Toss, app bancarie)';

  @override
  String get fieldPaypal => 'Nome utente PayPal.me';

  @override
  String get fieldPaypalHint => 'Il tuo nome utente PayPal.me, es. anna';

  @override
  String get fieldRevolut => 'Nome utente Revolut.me';

  @override
  String get fieldRevolutHint => 'Il tuo nome utente Revolut.me, es. anna';

  @override
  String get fieldVenmo => 'Nome utente Venmo';

  @override
  String get fieldVenmoHint => 'Senza la @, es. anna-rossi';

  @override
  String get fieldWise => 'Link Wise Quick Pay';

  @override
  String get fieldWiseHint =>
      'In Wise: Pagamenti → Quick Pay → copia link (https://wise.com/pay/…)';

  @override
  String get fieldKakaopay => 'Link 송금코드 di KakaoPay';

  @override
  String get fieldKakaopayHint =>
      'In KakaoPay: 송금 → 송금코드 → copia link (https://qr.kakaopay.com/…)';

  @override
  String get fieldHolder => 'Intestatario';

  @override
  String get fieldHolderHint => 'Il nome esattamente come sul conto';

  @override
  String get fieldIban => 'IBAN';

  @override
  String get fieldIbanHint => 'es. IT60 X054 2811 1010 0000 0123 456';

  @override
  String get fieldBic => 'BIC (facoltativo)';

  @override
  String get fieldBicHint => '8 o 11 caratteri';

  @override
  String get fieldBank => 'Banca';

  @override
  String get fieldBankHint => 'es. 신한은행, Toss Bank';

  @override
  String get fieldAccountNumber => 'Numero di conto';

  @override
  String get fieldAccountNumberHint => 'Cifre, trattini facoltativi';

  @override
  String amountCopied(String amount) {
    return 'Importo copiato: $amount';
  }

  @override
  String couldNotOpen(String link) {
    return 'Impossibile aprire $link';
  }

  @override
  String get payOffline => 'Offline: i modi per pagare non sono disponibili';

  @override
  String get payLoading => 'Caricamento dei modi per pagare…';

  @override
  String payAskToAdd(String name) {
    return 'Chiedi a $name di aggiungere un modo per farsi pagare';
  }

  @override
  String payTitle(String name, String amount) {
    return 'Paga $amount a $name';
  }

  @override
  String get payScanQr => 'Scansiona con l\'app della tua banca (QR SEPA)';

  @override
  String get payQrEurOnly =>
      'Il codice QR è disponibile solo per bonifici in EUR.';

  @override
  String get bankLabel => 'Banca';

  @override
  String get ibanLabel => 'IBAN';

  @override
  String get accountLabel => 'Conto';

  @override
  String get bicLabel => 'BIC';

  @override
  String get holderLabel => 'Intestatario';

  @override
  String get amountLabel => 'Importo';

  @override
  String get copyIban => 'Copia IBAN';

  @override
  String get copyAccount => 'Copia conto';

  @override
  String get copyAmount => 'Copia importo';

  @override
  String get ibanCopied => 'IBAN copiato';

  @override
  String get accountCopied => 'Conto copiato';

  @override
  String get paymentUpdated => 'Pagamento aggiornato';

  @override
  String paymentRecordedPending(String amount, String name) {
    return 'Registrati $amount. $name confermerà.';
  }

  @override
  String paymentRecordedPendingUnnamed(String amount) {
    return 'Registrati $amount. L\'altra persona confermerà.';
  }

  @override
  String paymentRecorded(String amount) {
    return 'Pagamento di $amount registrato';
  }

  @override
  String youSuffix(String name) {
    return '$name (tu)';
  }

  @override
  String get recordPayment => 'Registra un pagamento';

  @override
  String get editPayment => 'Modifica pagamento';

  @override
  String get fromLabel => 'Da';

  @override
  String get toLabel => 'A';

  @override
  String get swap => 'Inverti';

  @override
  String get pickTwoPeople => 'Scegli due persone diverse';

  @override
  String get commentsStayOld => 'I commenti restano sul vecchio pagamento';

  @override
  String get recordPaymentButton => 'Registra pagamento';

  @override
  String get paymentNotHere => 'Questo pagamento non è su questo dispositivo';

  @override
  String get notSyncedOrLeft =>
      'Non è ancora sincronizzato, oppure sei uscito dal suo gruppo.';

  @override
  String get someone => 'Qualcuno';

  @override
  String get paymentEdited => 'Pagamento modificato';

  @override
  String get paymentDeleted => 'Pagamento eliminato';

  @override
  String get payment => 'Pagamento';

  @override
  String get paymentWasEdited => 'Questo pagamento è stato modificato';

  @override
  String get paymentWasEditedNote =>
      'Al suo posto conta il pagamento modificato. I suoi commenti restano qui.';

  @override
  String get paymentWasDeleted => 'Questo pagamento è stato eliminato';

  @override
  String get paymentNotCounted => 'Non conta nei saldi.';

  @override
  String get restore => 'Ripristina';

  @override
  String youPaidName(String name) {
    return 'Hai pagato $name';
  }

  @override
  String namePaidYou(String name) {
    return '$name ti ha pagato';
  }

  @override
  String namePaidName(String from, String to) {
    return '$from ha pagato $to';
  }

  @override
  String paymentSaysSent(String name) {
    return '$name dice di avertelo inviato. È arrivato?';
  }

  @override
  String waitingForConfirm(String name) {
    return 'In attesa della conferma di $name';
  }

  @override
  String get notReceived => 'Non ricevuto';

  @override
  String get confirmReceived => 'Conferma ricezione';

  @override
  String get deletePaymentTitle => 'Eliminare il pagamento?';

  @override
  String get deletePaymentMessage => 'Il debito che aveva saldato torna.';

  @override
  String get paymentDeletedSnack => 'Pagamento eliminato';

  @override
  String get notReceivedTitle => 'Non ricevuto?';

  @override
  String notReceivedMessage(String name) {
    return 'Il pagamento di $name viene rimosso e il debito torna.';
  }

  @override
  String get paymentRemovedSnack => 'Pagamento rimosso';

  @override
  String get recordAPayment => 'Registra un pagamento';

  @override
  String get nothingToSettle => 'Niente da saldare';

  @override
  String get everyoneEven => 'Siete tutti in pari.';

  @override
  String get waitingForConfirmation => 'In attesa di conferma';

  @override
  String get debtsAsRecorded =>
      'Debiti come registrati · semplifica debiti è disattivato';

  @override
  String transfersSettleEverything(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trasferimenti saldano tutto',
      one: '1 trasferimento salda tutto',
    );
    return '$_temp0';
  }

  @override
  String transfersSettleBalance(int count, String currency) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trasferimenti saldano il saldo in $currency',
      one: '1 trasferimento salda il saldo in $currency',
    );
    return '$_temp0';
  }

  @override
  String notConvertedSettlesIn(String currency) {
    return 'Non convertito · $currency · si salda in $currency';
  }

  @override
  String get convert => 'Converti';

  @override
  String get settleUp => 'Salda';

  @override
  String saysTheySent(String name, String amount) {
    return '$name dice di averti inviato $amount';
  }

  @override
  String waitingToConfirmAmount(String name, String amount) {
    return 'In attesa che $name confermi $amount';
  }

  @override
  String get you => 'Tu';

  @override
  String get request => 'Richiedi';

  @override
  String get iveSentIt => 'L\'ho inviato';

  @override
  String get markAsPaid => 'Segna come pagato';

  @override
  String markedAsSent(String name) {
    return 'Segnato come inviato. $name confermerà.';
  }

  @override
  String approx(String amount) {
    return '≈ $amount';
  }

  @override
  String friendOwesYou(String name, String amount) {
    return '$name ti deve $amount';
  }

  @override
  String friendYouOwe(String name, String amount) {
    return 'Devi $amount a $name';
  }

  @override
  String friendYouOweLine(String name, String amount) {
    return 'devi $amount a $name';
  }

  @override
  String noSharedGroup(String name) {
    return 'Non condividi più un gruppo con $name. Mandagli il tuo link amico per aggiungere spese.';
  }

  @override
  String get shareFriendLink => 'Condividi link amico';

  @override
  String firstExpenseNeedsConnection(String name) {
    return 'La prima spesa con $name richiede una connessione.';
  }

  @override
  String reminderSent(String name) {
    return 'Promemoria inviato a $name';
  }

  @override
  String remindTomorrow(String name) {
    return 'Potrai ricordarlo a $name di nuovo domani';
  }

  @override
  String remindNothingOwed(String name) {
    return '$name non ti deve niente';
  }

  @override
  String get remindNeedsConnection =>
      'Per inviare un promemoria serve una connessione.';

  @override
  String amountsAnd(String a, String b) {
    return '$a e $b';
  }

  @override
  String inviteFriendText(String link) {
    return 'Ti ho aggiunto su Evensies per dividere le spese. Unisciti: $link';
  }

  @override
  String get personNotHere => 'Questa persona non è su questo dispositivo';

  @override
  String get personNotHereNote =>
      'Non è ancora sincronizzata, oppure non condividete più un gruppo.';

  @override
  String get more => 'Altro';

  @override
  String get exportNonGroupCsv => 'Esporta spese fuori dai gruppi (CSV)';

  @override
  String get exportNonGroupJson => 'Esporta spese fuori dai gruppi (JSON)';

  @override
  String get exportNonGroupZip =>
      'Esporta spese fuori dai gruppi (ZIP con scontrini)';

  @override
  String get notOnEvensies => 'Non ancora su Evensies';

  @override
  String get allSettledUp => 'Tutto in pari';

  @override
  String get remind => 'Ricorda';

  @override
  String get invite => 'Invita';

  @override
  String get balances => 'Saldi';

  @override
  String get expensesAndPayments => 'Spese e pagamenti';

  @override
  String get nothingTogetherYet =>
      'Ancora niente insieme. Aggiungi una spesa qui sotto.';

  @override
  String get addExpense => 'Aggiungi spesa';

  @override
  String personOwesYou(String amount) {
    return 'ti deve $amount';
  }

  @override
  String personYouOwe(String amount) {
    return 'devi $amount';
  }

  @override
  String get personSettledUp => 'in pari';

  @override
  String recordedInGroups(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Registrato in $count gruppi',
      one: 'Registrato in 1 gruppo',
    );
    return '$_temp0';
  }

  @override
  String get markAsReceived => 'Segna come ricevuto';

  @override
  String get clearBothSides => 'Pareggia entrambi i lati';

  @override
  String evenIn(String currency) {
    return 'In pari in $currency';
  }

  @override
  String linePayThem(String group, String name, String amount) {
    return '$group: paghi $amount a $name';
  }

  @override
  String lineTheyPay(String group, String name, String amount) {
    return '$group: $name ti paga $amount';
  }

  @override
  String get noMoneyMoves =>
      'Non si muove denaro: registra entrambi i lati come saldati.';

  @override
  String convertIn(String group) {
    return 'Converti in $group';
  }

  @override
  String settleUpWith(String name) {
    return 'Salda con $name';
  }

  @override
  String nothingToSettleWith(String name) {
    return 'Niente da saldare con $name';
  }

  @override
  String settleWithIntro(String name) {
    return 'Tutto tra te e $name, per valuta. Registrando si aggiunge un pagamento in ogni gruppo.';
  }

  @override
  String get searchFriendsGroups => 'Cerca amici e gruppi';

  @override
  String get friends => 'Amici';

  @override
  String get groups => 'Gruppi';

  @override
  String get noFriendsOrGroups => 'Ancora nessun amico o gruppo.';

  @override
  String nothingMatches(String query) {
    return 'Niente corrisponde a “$query”.';
  }

  @override
  String get addExpenseWithWhom => 'Aggiungi spesa · con chi?';

  @override
  String friendLinkShare(String link, String code) {
    return 'Aggiungimi su Evensies per dividere le spese: $link\nOppure inserisci il mio codice $code';
  }

  @override
  String get friendLinkNeedsConnection =>
      'Per condividere il tuo link amico serve una connessione.';

  @override
  String get selfFriend => 'È il tuo codice';

  @override
  String get noOneForCode => 'Nessuno trovato con questo codice';

  @override
  String get addFriendNeedsConnection =>
      'Per aggiungere un amico serve una connessione.';

  @override
  String get newFriendCodeTitle => 'Creare un nuovo codice amico?';

  @override
  String get newFriendCodeMessage =>
      'Il link e il codice attuali smettono di funzionare. Gli amici che hai già restano.';

  @override
  String get newCode => 'Nuovo codice';

  @override
  String get addAFriend => 'Aggiungi un amico';

  @override
  String get friendLinkOffline => 'Il tuo link amico richiede una connessione';

  @override
  String get yourFriendCode => 'Il tuo codice amico';

  @override
  String get friendQrLabel => 'Codice QR del tuo link amico';

  @override
  String get friendCodeHelp =>
      'Gli amici lo scansionano, aprono il link o digitano il codice.';

  @override
  String get shareLink => 'Condividi link';

  @override
  String get codeCopied => 'Codice copiato';

  @override
  String get copyCode => 'Copia codice';

  @override
  String get haveFriendCode => 'Hai il codice di un amico?';

  @override
  String get onEvensies => 'su Evensies';

  @override
  String get notOnEvensiesSection => 'Qualcuno non ancora su Evensies';

  @override
  String get notOnEvensiesHelp =>
      'Aggiungi subito spese con questa persona e invitala più tardi.';

  @override
  String atMostChars(int max) {
    return 'Al massimo $max caratteri';
  }

  @override
  String addName(String name) {
    return 'Aggiungi $name';
  }

  @override
  String get search => 'Cerca';

  @override
  String get activity => 'Attività';

  @override
  String get newGroup => 'Nuovo gruppo';

  @override
  String get joinWithCode => 'Entra con un codice';

  @override
  String get filterAll => 'Tutti';

  @override
  String get filterOwesMe => 'Mi deve';

  @override
  String get filterIOwe => 'Devo';

  @override
  String settledUpCount(int count) {
    return 'In pari ($count)';
  }

  @override
  String get nobodyOwesYou => 'Nessuno ti deve niente';

  @override
  String get youOweNothing => 'Non devi niente';

  @override
  String get nothingHereYet => 'Ancora niente qui';

  @override
  String get noFriendsYet => 'Ancora nessun amico';

  @override
  String get noFriendsHelp =>
      'Aggiungi un amico per dividere spese fuori da un gruppo. Qui compaiono anche le persone con cui condividi un gruppo.';

  @override
  String get allSettledUpYou => 'Sei in pari con tutti';

  @override
  String youAreOwedList(String amounts) {
    return 'Ti devono $amounts';
  }

  @override
  String youOweList(String amounts) {
    return 'Devi $amounts';
  }

  @override
  String get notOnEvensiesLower => 'non ancora su Evensies';

  @override
  String get noGroupsYet => 'Ancora nessun gruppo';

  @override
  String get noGroupsHelp =>
      'Creane uno per un viaggio o una casa, oppure entra nel gruppo di un amico con il suo codice di invito.';

  @override
  String get createGroup => 'Crea gruppo';

  @override
  String get settledUp => 'In pari';

  @override
  String netApprox(String amount) {
    return 'Netto ≈ $amount';
  }

  @override
  String memberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membri',
      one: '1 membro',
    );
    return '$_temp0';
  }

  @override
  String youOweAmount(String amount) {
    return 'Devi $amount';
  }

  @override
  String youAreOwedAmount(String amount) {
    return 'Ti devono $amount';
  }

  @override
  String youOweAmountLine(String amount) {
    return 'devi $amount';
  }

  @override
  String youAreOwedAmountLine(String amount) {
    return 'ti devono $amount';
  }

  @override
  String get createGroupNeedsConnection =>
      'Per creare un gruppo serve una connessione.';

  @override
  String get groupName => 'Nome del gruppo';

  @override
  String get yourNameInGroup => 'Il tuo nome in questo gruppo';

  @override
  String get defaultCurrency => 'Valuta predefinita';

  @override
  String get create => 'Crea';

  @override
  String get noGroupOrFriendForCode =>
      'Nessun gruppo o amico trovato con questo codice';

  @override
  String get joinNeedsConnection =>
      'Per entrare in un gruppo serve una connessione.';

  @override
  String get enterACode => 'Inserisci un codice';

  @override
  String get enterCodeHelp =>
      'Il codice di un gruppo è in Gruppo → Membri. Il codice di un amico è nella sua scheda Amici → Aggiungi un amico.';

  @override
  String get pastedFromClipboard => 'Incollato dagli appunti';

  @override
  String nameOnEvensies(String name) {
    return '$name · su Evensies';
  }

  @override
  String addAsFriend(String name) {
    return 'Aggiungi $name agli amici';
  }

  @override
  String addedYouAsFriend(String name) {
    return '$name ti ha aggiunto agli amici';
  }

  @override
  String get someoneAddedYouAsFriend => 'Qualcuno ti ha aggiunto agli amici';

  @override
  String groupPreview(String name, String members) {
    return '$name · $members';
  }

  @override
  String get continueButton => 'Continua';

  @override
  String wantsToSplit(String name) {
    return '$name vuole dividere le spese con te';
  }

  @override
  String get joinGroup => 'Entra nel gruppo';

  @override
  String get inviteInvalid => 'Questo link di invito non è più valido';

  @override
  String inviteFailed(String reason) {
    return 'Impossibile aprire questo invito: $reason';
  }

  @override
  String get friendInviteUsed => 'Questo invito amico è già stato usato';

  @override
  String get joinToSeeShared =>
      'Entra per vedere e aggiungere le vostre spese condivise.';

  @override
  String imName(String name) {
    return 'Sono $name';
  }

  @override
  String get join => 'Entra';

  @override
  String get whoAreYou => 'Chi sei?';

  @override
  String get newMemberName => 'Nome del nuovo membro';

  @override
  String get insights => 'Statistiche';

  @override
  String get membersInvite => 'Membri e invito';

  @override
  String get groupSettings => 'Impostazioni del gruppo';

  @override
  String get expenses => 'Spese';

  @override
  String get expenseFab => 'Spesa';

  @override
  String get groupNotHere => 'Questo gruppo non è su questo dispositivo';

  @override
  String get groupNotHereNote =>
      'Ne sei uscito, qualcuno ti ha rimosso, o non è ancora sincronizzato.';

  @override
  String get backToGroups => 'Torna ai gruppi';

  @override
  String get noExpensesYet => 'Ancora nessuna spesa';

  @override
  String get tapExpenseToAdd => 'Tocca “Spesa” per aggiungere la prima.';

  @override
  String tilePaidYou(String amount) {
    return 'hai pagato $amount';
  }

  @override
  String tilePaidName(String name, String amount) {
    return '$name ha pagato $amount';
  }

  @override
  String tilePaidPeople(int count, String amount) {
    return '$count persone hanno pagato $amount';
  }

  @override
  String get tileRefundYou => 'rimborso a te';

  @override
  String tileRefundName(String name) {
    return 'rimborso a $name';
  }

  @override
  String tileRefundPeople(int count) {
    return 'rimborso a $count persone';
  }

  @override
  String get notInvolved => 'non coinvolto';

  @override
  String get allYours => 'tutto tuo';

  @override
  String get paidForYourself => 'hai pagato per te';

  @override
  String youGetBack(String amount) {
    return 'ti tornano $amount';
  }

  @override
  String youLent(String amount) {
    return 'hai prestato $amount';
  }

  @override
  String youBorrowed(String amount) {
    return 'hai preso in prestito $amount';
  }

  @override
  String get repeatsLabel => 'Si ripete';

  @override
  String hasReceipt(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ha $count scontrini',
      one: 'Ha uno scontrino',
    );
    return '$_temp0';
  }

  @override
  String get refund => 'Rimborso';

  @override
  String get notConverted => 'Non convertito';

  @override
  String get pending => 'in attesa';

  @override
  String approxTotalOwe(String amount) {
    return 'Devi ≈ $amount in totale';
  }

  @override
  String approxTotalOwed(String amount) {
    return 'Ti devono ≈ $amount in totale';
  }

  @override
  String get approxTotalNote =>
      'Nella tua valuta di casa, ai tassi più recenti';

  @override
  String nothingOwedIn(String currency) {
    return 'Nessun debito in $currency';
  }

  @override
  String get allSettled => 'Tutto saldato';

  @override
  String get otherCurrenciesBelow => 'Le spese in altre valute sono qui sotto.';

  @override
  String get nobodyOwes => 'Nessuno deve niente.';

  @override
  String youPayNext(String amount) {
    return 'Dovresti pagare tu la prossima volta (devi $amount, il più alto)';
  }

  @override
  String namePaysNext(String name, String amount) {
    return '$name dovrebbe pagare la prossima volta (deve $amount, il più alto)';
  }

  @override
  String settleUpWaiting(int count) {
    return 'Salda · $count in attesa';
  }

  @override
  String memberRemoved(String name) {
    return '$name (rimosso)';
  }

  @override
  String expensesWithoutRate(int count, String currency) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count spese senza tasso verso $currency',
      one: '1 spesa senza tasso verso $currency',
    );
    return '$_temp0';
  }

  @override
  String expensesBadRate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count spese con un tasso non convertibile',
      one: '1 spesa con un tasso non convertibile',
    );
    return '$_temp0';
  }

  @override
  String paymentsIn(String currency) {
    return 'Pagamenti in $currency';
  }

  @override
  String everyoneEvenIn(String currency) {
    return 'tutti in pari in $currency';
  }

  @override
  String convertTo(String currency) {
    return 'Converti in $currency';
  }

  @override
  String get balanceSettled => 'in pari';

  @override
  String get balanceGetsBack => 'riceve';

  @override
  String get balanceOwes => 'deve';

  @override
  String convertedCount(int count, String currency) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count spese convertite in $currency',
      one: '1 spesa convertita in $currency',
    );
    return '$_temp0';
  }

  @override
  String get noAutoRate => 'Nessun tasso automatico. Inseriscine uno.';

  @override
  String rateOf(String date) {
    return 'tasso del $date';
  }

  @override
  String rateOfOffline(String date) {
    return 'offline · tasso del $date';
  }

  @override
  String amountCountExpenses(String amount, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count spese',
      one: '1 spesa',
    );
    return '$amount · $_temp0';
  }

  @override
  String paymentsStayIn(String currency) {
    return 'I pagamenti in $currency restano in $currency';
  }

  @override
  String rateLabel(String from, String to) {
    return 'Tasso: 1 $from in $to';
  }

  @override
  String get nothingLeftToConvert => 'Niente da convertire';

  @override
  String get lookingUpRate => 'Ricerca del tasso…';

  @override
  String get enterRateAbove0 => 'Inserisci un tasso sopra 0';

  @override
  String convertExplain(String currency) {
    return 'Inserisce questo tasso in ogni spesa che non ne ha uno, così conta nei saldi in $currency. Puoi ancora cambiare il tasso di ogni spesa.';
  }

  @override
  String get nameField => 'Nome';

  @override
  String get cantChangeCurrency =>
      'Non si può cambiare dopo la prima spesa o il primo pagamento';

  @override
  String get currencyUsedFor => 'La usano saldi e pagamenti';

  @override
  String get splitting => 'Divisione';

  @override
  String get simplifyDebts => 'Semplifica debiti';

  @override
  String get simplifyDebtsHelp =>
      'Unisce i debiti così il gruppo ha bisogno di meno pagamenti. Il totale di nessuno cambia, solo chi paga chi.';

  @override
  String get defaultSplit => 'Divisione predefinita';

  @override
  String get splitStale => 'Non torna più · tocca per correggere';

  @override
  String get membership => 'Iscrizione';

  @override
  String get leaveGroup => 'Esci dal gruppo';

  @override
  String get balanceSettledNote => 'Il tuo saldo è in pari';

  @override
  String get renameGroup => 'Rinomina gruppo';

  @override
  String leaveTitle(String name) {
    return 'Uscire da “$name”?';
  }

  @override
  String get leaveMessage =>
      'Non vedrai più questo gruppo. Le tue spese passate restano agli altri membri. Per tornare, chiedi il codice di invito.';

  @override
  String get leave => 'Esci';

  @override
  String youLeft(String name) {
    return 'Sei uscito da “$name”';
  }

  @override
  String get splitEqualEveryone => 'In parti uguali · tutti';

  @override
  String splitPercentList(String list) {
    return 'Percentuale · $list';
  }

  @override
  String splitSharesList(String list) {
    return 'Quote · $list';
  }

  @override
  String percentValue(String value) {
    return '$value%';
  }

  @override
  String get defaultSplitHelp =>
      'Le nuove spese partono con questa divisione. Puoi ancora cambiarla per ogni spesa.';

  @override
  String get useEqual => 'Usa parti uguali';

  @override
  String get inviteCode => 'Codice di invito';

  @override
  String get inviteQrLabel => 'Codice QR del link di invito';

  @override
  String get inviteCodeHelp =>
      'Chiunque abbia questo codice può entrare e scegliere il proprio nome.';

  @override
  String inviteShareText(String group, String link, String code) {
    return 'Entra nel mio gruppo “$group” su Evensies: $link\nOppure apri l\'app e inserisci il codice $code';
  }

  @override
  String get rotateCode => 'Cambia codice';

  @override
  String get members => 'Membri';

  @override
  String get notJoinedYet =>
      'non ancora entrato — condividi il codice di invito';

  @override
  String get linked => 'collegato';

  @override
  String get addPlaceholder => 'Aggiungi membro segnaposto';

  @override
  String removeMemberTitle(String name) {
    return 'Rimuovere $name?';
  }

  @override
  String get removeMemberMessage =>
      'Le sue spese passate e il saldo restano nel gruppo.';

  @override
  String removeMemberSeries(int count, String name, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$name è ancora in $count spese ricorrenti ($names); la quota di $name resta finché non modifichi l\'ultima.',
      one:
          '$name è ancora in 1 spesa ricorrente ($names); la quota di $name resta finché non modifichi l\'ultima.',
    );
    return '$_temp0';
  }

  @override
  String get addMember => 'Aggiungi membro';

  @override
  String get rotateInviteTitle => 'Cambiare il codice di invito?';

  @override
  String get rotateInviteMessage =>
      'Il codice e il link attuali smettono di funzionare. Chi è già entrato non è interessato.';

  @override
  String get rotate => 'Cambia';

  @override
  String get newInviteReady => 'Nuovo codice di invito pronto';

  @override
  String get activityNeedsConnection => 'L\'attività richiede una connessione';

  @override
  String get activityOfflineNote =>
      'Le modifiche recenti compaiono qui appena torni online.';

  @override
  String get noActivityYet => 'Ancora nessuna attività';

  @override
  String get activityAllGroups => 'Qui compaiono le modifiche nei tuoi gruppi.';

  @override
  String get activityThisGroup =>
      'Qui compaiono le modifiche di questo gruppo.';

  @override
  String get showingSaved => 'Attività salvata. Trascina per aggiornare.';

  @override
  String get loadMore => 'Carica altro';

  @override
  String get earlier => 'Prima';

  @override
  String get today => 'Oggi';

  @override
  String get yesterday => 'Ieri';

  @override
  String forDate(String date) {
    return 'per $date';
  }

  @override
  String get youCommented => 'Hai commentato';

  @override
  String nameCommented(String name) {
    return '$name ha commentato';
  }

  @override
  String restoredName(String name) {
    return '“$name” ripristinata';
  }

  @override
  String get paymentRestored => 'Pagamento ripristinato';

  @override
  String get expenseNotHere => 'Questa spesa non è su questo dispositivo';

  @override
  String get deletedExpense => 'Spesa eliminata';

  @override
  String get expense => 'Spesa';

  @override
  String seriesRepeats(String frequency) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Si ripete ogni settimana',
      'biweekly': 'Si ripete ogni 2 settimane',
      'monthly': 'Si ripete ogni mese',
      'yearly': 'Si ripete ogni anno',
      'other': 'Si ripete',
    });
    return '$_temp0';
  }

  @override
  String seriesRepeatsNext(String frequency, String date) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Si ripete ogni settimana · prossima il $date',
      'biweekly': 'Si ripete ogni 2 settimane · prossima il $date',
      'monthly': 'Si ripete ogni mese · prossima il $date',
      'yearly': 'Si ripete ogni anno · prossima il $date',
      'other': 'Si ripete · prossima il $date',
    });
    return '$_temp0';
  }

  @override
  String seriesRepeatsNextAmount(String frequency, String amount, String date) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Si ripete ogni settimana · prossima $amount il $date',
      'biweekly': 'Si ripete ogni 2 settimane · prossima $amount il $date',
      'monthly': 'Si ripete ogni mese · prossima $amount il $date',
      'yearly': 'Si ripete ogni anno · prossima $amount il $date',
      'other': 'Si ripete · prossima $amount il $date',
    });
    return '$_temp0';
  }

  @override
  String rateLine(String from, String rate, String to) {
    return 'Tasso: 1 $from = $rate $to';
  }

  @override
  String notConvertedTo(String currency) {
    return 'Non convertita in $currency';
  }

  @override
  String get receivedSplitBack => 'Ricevuto e ridiviso';

  @override
  String get whoPaidOwes => 'Chi ha pagato e chi deve';

  @override
  String get items => 'Voci';

  @override
  String get notes => 'Note';

  @override
  String get receipts => 'Scontrini';

  @override
  String get history => 'Cronologia';

  @override
  String get deleteExpenseTitle => 'Eliminare la spesa?';

  @override
  String get deleteExpenseMessage =>
      'Viene rimossa per tutti nel gruppo. Puoi ripristinarla dall\'Attività.';

  @override
  String get deleteRepeatingTitle => 'Eliminare la spesa ricorrente?';

  @override
  String get deleteRepeatingMessage =>
      'Viene rimossa per tutti nel gruppo. Puoi ripristinarla dall\'Attività, ma una serie interrotta non può ripartire. Le ripetizioni già aggiunte restano.';

  @override
  String get deleteThisOne => 'Elimina solo questa';

  @override
  String get deleteAndStop => 'Elimina e interrompi';

  @override
  String deletedAndStopped(String name) {
    return '“$name” eliminata e interrotta';
  }

  @override
  String deletedName(String name) {
    return '“$name” eliminata';
  }

  @override
  String get movedToOtherGroup => 'Spostata in un altro gruppo';

  @override
  String get movedNote => 'Ora conta lì. Commenti e cronologia restano qui.';

  @override
  String get expenseWasDeleted => 'Questa spesa è stata eliminata';

  @override
  String get restoreToCount =>
      'Ripristinala per farla contare di nuovo nei saldi.';

  @override
  String get tax => 'Tasse';

  @override
  String get tipService => 'Mancia o servizio';

  @override
  String get discount => 'Sconto';

  @override
  String youPaidOwe(String paid, String owe) {
    return 'Hai pagato $paid e devi $owe';
  }

  @override
  String youPaid(String amount) {
    return 'Hai pagato $amount';
  }

  @override
  String youOwe(String amount) {
    return 'Devi $amount';
  }

  @override
  String namePaidOwes(String name, String paid, String owe) {
    return '$name ha pagato $paid e deve $owe';
  }

  @override
  String namePaid(String name, String amount) {
    return '$name ha pagato $amount';
  }

  @override
  String nameOwes(String name, String amount) {
    return '$name deve $amount';
  }

  @override
  String youReceivedGetBack(String received, String back) {
    return 'Hai ricevuto $received e ti tornano $back';
  }

  @override
  String youReceived(String amount) {
    return 'Hai ricevuto $amount';
  }

  @override
  String youGetBackLine(String amount) {
    return 'Ti tornano $amount';
  }

  @override
  String nameReceivedGetsBack(String name, String received, String back) {
    return '$name ha ricevuto $received e riceve $back';
  }

  @override
  String nameReceived(String name, String amount) {
    return '$name ha ricevuto $amount';
  }

  @override
  String nameGetsBack(String name, String amount) {
    return '$name riceve $amount';
  }

  @override
  String get noHistoryYet => 'Ancora nessuna cronologia.';

  @override
  String get historyOffline => 'La cronologia compare qui quando sei online.';

  @override
  String get showingSavedHistory => 'Cronologia salvata.';

  @override
  String get showMore => 'Mostra altro';

  @override
  String get deleteCommentTitle => 'Eliminare il commento?';

  @override
  String get comments => 'Commenti';

  @override
  String get noCommentsYet => 'Ancora nessun commento.';

  @override
  String get deleteComment => 'Elimina commento';

  @override
  String get addComment => 'Aggiungi un commento';

  @override
  String get send => 'Invia';

  @override
  String get filterByCategory => 'Filtra per categoria';

  @override
  String get category => 'Categoria';

  @override
  String get categoryAll => 'Tutte';

  @override
  String get month => 'Mese';

  @override
  String get searchUnavailable => 'La ricerca non è disponibile';

  @override
  String get searchExpenses => 'Cerca spese';

  @override
  String get searchHelp =>
      'Descrizioni, note, commenti, categorie e importi: “taxi”, “aeroporto”, “12,50”.';

  @override
  String get noMatches => 'Nessun risultato';

  @override
  String get noMatchesHelp => 'Prova un\'altra parola o rimuovi un filtro.';

  @override
  String expenseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count spese',
      one: '1 spesa',
    );
    return '$_temp0';
  }

  @override
  String get searchAllGroups => 'Cerca in tutti i gruppi';

  @override
  String searchGroup(String name) {
    return 'Cerca in $name';
  }

  @override
  String get searchThisGroup => 'Cerca in questo gruppo';

  @override
  String get clear => 'Cancella';

  @override
  String get thisGroup => 'Questo gruppo';

  @override
  String insightsError(String reason) {
    return 'Impossibile mostrare le statistiche: $reason';
  }

  @override
  String get nothingToShow => 'Ancora niente da mostrare';

  @override
  String get insightsEmptyHelp =>
      'Totali e grafici compaiono quando il gruppo ha delle spese.';

  @override
  String get allTime => 'Sempre';

  @override
  String get shareSummary => 'Condividi riepilogo';

  @override
  String get printSummary => 'Stampa riepilogo';

  @override
  String get previousMonth => 'Mese precedente';

  @override
  String get nextMonth => 'Mese successivo';

  @override
  String get byMonth => 'Per mese';

  @override
  String get groupSegment => 'Gruppo';

  @override
  String get mineSegment => 'Mie';

  @override
  String get byCategory => 'Per categoria';

  @override
  String get noExpensesPeriod => 'Nessuna spesa in questo periodo.';

  @override
  String get byPerson => 'Per persona';

  @override
  String get nobodyPaidPeriod =>
      'Nessuno ha pagato o dovuto niente in questo periodo.';

  @override
  String keptUntilConverted(String currency, String group) {
    return 'Resta in $currency finché non viene convertito in $group.';
  }

  @override
  String get totalSpent => 'Spesa totale';

  @override
  String get yourShare => 'La tua quota';

  @override
  String get paymentsMade => 'Pagamenti fatti';

  @override
  String get paymentsReceived => 'Pagamenti ricevuti';

  @override
  String get youPaidRow => 'Hai pagato';

  @override
  String get balanceChange => 'Variazione del tuo saldo';

  @override
  String get paidLegend => 'Pagato';

  @override
  String get shareLegend => 'Quota';

  @override
  String paidShareLine(String paid, String share) {
    return 'pagato $paid · quota $share';
  }

  @override
  String get itemsGiveEveryone => 'Assegna una persona a ogni voce';

  @override
  String get itemsAddPrices =>
      'Inserisci i prezzi delle voci prima di tasse o mancia';

  @override
  String get itemsDiscountTooBig => 'Lo sconto supera il conto';

  @override
  String get itemsDontAddUp => 'Le voci non tornano';

  @override
  String get adjustmentsDontFit => 'Le rettifiche non rientrano nel totale';

  @override
  String get giveSomeoneShare => 'Dai una quota a qualcuno';

  @override
  String get checkNumbers => 'Controlla i numeri';

  @override
  String get splitDoesntAddUp => 'La divisione non torna';

  @override
  String get addTheItems => 'Aggiungi le voci';

  @override
  String get pickOnePerson => 'Scegli almeno una persona';

  @override
  String splitEquallyBetween(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Diviso in parti uguali tra $count persone',
      one: 'Diviso in parti uguali tra 1 persona',
    );
    return '$_temp0';
  }

  @override
  String get allForOnePerson => 'Tutto per 1 persona';

  @override
  String splitEquallyEach(int count, String amount) {
    return 'Diviso in parti uguali tra $count persone · $amount a testa';
  }

  @override
  String get checkAmounts => 'Controlla gli importi';

  @override
  String get enterTotalFirst => 'Inserisci prima il totale';

  @override
  String remaining(String amount) {
    return 'mancano: $amount';
  }

  @override
  String overBy(String amount) {
    return 'in eccesso: $amount';
  }

  @override
  String get addsUp => 'Torna';

  @override
  String sharesInTotal(String count) {
    return '$count quote in totale';
  }

  @override
  String get oneShareInTotal => '1 quota in totale';

  @override
  String get restSplitEqually => 'Il resto è diviso in parti uguali';

  @override
  String get byPercent => 'Per percentuale';

  @override
  String get byShares => 'Per quote';

  @override
  String get byAdjustment =>
      'Rettifica: di più o di meno per qualcuno, il resto in parti uguali';

  @override
  String get modeEqual => 'Uguale';

  @override
  String get modeExact => 'Esatto';

  @override
  String get modeShares => 'Quote';

  @override
  String get byItem => 'Per voce, da uno scontrino';

  @override
  String get adjustmentHelp =>
      'Aggiungi o togli un importo a qualcuno; il resto è diviso in parti uguali.';

  @override
  String get noMembers => 'Nessun membro';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count voci',
      one: '1 voce',
    );
    return '$_temp0';
  }

  @override
  String get addAnItem => 'Aggiungi una voce';

  @override
  String atMostItems(int max) {
    return 'Al massimo $max voci';
  }

  @override
  String get giveItemName => 'Dai un nome a ogni voce';

  @override
  String get itemNameTooLong => 'Il nome di una voce è troppo lungo';

  @override
  String get addItem => 'Aggiungi voce';

  @override
  String get giveRestToEveryone => 'Dai il resto a tutti';

  @override
  String get subtotal => 'Subtotale';

  @override
  String get total => 'Totale';

  @override
  String receiptSays(String printed, String difference) {
    return 'Lo scontrino dice $printed · le voci differiscono di $difference';
  }

  @override
  String get eachPerson => 'Per persona';

  @override
  String itemsWithoutPerson(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count voci senza persona',
      one: '1 voce senza persona',
    );
    return '$_temp0';
  }

  @override
  String get itemHint => 'Voce';

  @override
  String memberLeft(String name) {
    return '$name (uscito)';
  }

  @override
  String get whoHadThis => 'Chi l\'ha preso?';

  @override
  String get defaultSplitStartsEqual =>
      'La divisione predefinita del gruppo non torna più, quindi si parte in parti uguali';

  @override
  String leftToAssign(String amount) {
    return 'Mancano $amount da assegnare';
  }

  @override
  String get itemsTotal => 'Il totale delle voci';

  @override
  String get newExpense => 'Nuova spesa';

  @override
  String get editExpense => 'Modifica spesa';

  @override
  String get scanReceipt => 'Scansiona scontrino';

  @override
  String get rateAboveZeroOrEmpty =>
      'Inserisci un tasso sopra 0 o lascia vuoto';

  @override
  String useAutoRate(String rate, String source) {
    return 'Usa tasso automatico: $rate ($source)';
  }

  @override
  String get description => 'Descrizione';

  @override
  String get receivedBy => 'Ricevuto da';

  @override
  String get paidBy => 'Pagato da';

  @override
  String get severalPeople => 'Più persone';

  @override
  String get when => 'Quando';

  @override
  String get refundTooltip =>
      'Soldi tornati indietro, es. l\'hotel ha restituito la cauzione';

  @override
  String get splitBackTo => 'Ridiviso tra';

  @override
  String get split => 'Divisione';

  @override
  String theyOweFull(String name) {
    return '$name deve l\'intero importo';
  }

  @override
  String iOweFull(String name) {
    return 'Devo l\'intero importo a $name';
  }

  @override
  String get repeat => 'Ripeti';

  @override
  String editLatestRepeat(String date) {
    return 'Per cambiare le prossime ripetizioni, modifica l\'ultima ($date)';
  }

  @override
  String get stopsRepeating =>
      'Smette di ripetersi. Le ripetizioni già aggiunte restano.';

  @override
  String nextRepeat(String date) {
    return 'Prossima: $date';
  }

  @override
  String get alsoChangeFuture => 'Cambia anche le prossime ripetizioni';

  @override
  String get futureFields =>
      'Importo, divisione, chi paga, descrizione, categoria e note';

  @override
  String get onlyThisOne => 'Cambia solo questa';

  @override
  String get addPhoto => 'Aggiungi foto';

  @override
  String maxReceiptsNote(int max) {
    return '$max scontrini è il massimo per una spesa';
  }

  @override
  String get scanAReceipt => 'Scansiona uno scontrino';

  @override
  String receiptLooksLike(String currency) {
    return 'Questo scontrino sembra in $currency';
  }

  @override
  String switchToCurrencyQuestion(String currency) {
    return 'Passare la spesa a $currency per leggerne le voci?';
  }

  @override
  String switchTo(String currency) {
    return 'Passa a $currency';
  }

  @override
  String get couldntReadItems =>
      'Impossibile leggere le voci. Inseriscile a mano.';

  @override
  String withName(String name) {
    return 'Con $name';
  }

  @override
  String movesTo(String name) {
    return 'Si sposta in $name al salvataggio';
  }

  @override
  String fromName(String name) {
    return 'Da $name';
  }

  @override
  String get dontMove => 'Non spostare';

  @override
  String get onlyLinkedMove =>
      'Si possono spostare solo persone su Evensies presenti in entrambi';

  @override
  String get auto => 'auto';

  @override
  String get noAutoRateForm =>
      'Nessun tasso automatico. Inseriscine uno, o lascia vuoto per tenerla in “Non convertito”.';

  @override
  String get emptyNotConverted => 'Vuoto: resta in “Non convertito”';

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
  String get yourRate => 'il tuo tasso';
}
