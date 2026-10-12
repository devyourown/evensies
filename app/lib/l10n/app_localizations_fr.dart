// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Evensies';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get remove => 'Retirer';

  @override
  String get save => 'Enregistrer';

  @override
  String get done => 'Terminé';

  @override
  String get undo => 'Annuler';

  @override
  String get retry => 'Réessayer';

  @override
  String get ok => 'OK';

  @override
  String get close => 'Fermer';

  @override
  String get edit => 'Modifier';

  @override
  String get add => 'Ajouter';

  @override
  String get offlineBanner =>
      'Hors ligne — les modifications seront synchronisées plus tard';

  @override
  String get tooLong => 'Trop long';

  @override
  String get allCurrencies => 'Toutes les devises';

  @override
  String get errorUnexpected => 'Un problème est survenu. Réessayez.';

  @override
  String get errorNetwork => 'Vous êtes hors ligne. Réessayez plus tard.';

  @override
  String get errorRateLimited =>
      'Trop de tentatives. Attendez une minute et réessayez.';

  @override
  String get errorNotFound => 'Cela n\'existe plus.';

  @override
  String get errorForbidden => 'Vous n\'avez pas le droit de faire cela.';

  @override
  String get errorValidation => 'Le serveur l\'a refusé.';

  @override
  String get errorSumMismatch => 'La répartition ne tombe pas juste.';

  @override
  String get errorPayersSumMismatch => 'Les payeurs ne tombent pas juste.';

  @override
  String get errorNegativeAmount => 'Un montant est inférieur à zéro.';

  @override
  String get errorNegativeShare =>
      'La part de quelqu\'un serait inférieure à zéro.';

  @override
  String get errorNegativeTotal => 'Le total serait inférieur à zéro.';

  @override
  String get errorZeroSubtotal =>
      'Saisissez les prix des articles avant taxes, pourboire ou remise.';

  @override
  String get errorUnassignedItem =>
      'Chaque article doit avoir au moins une personne.';

  @override
  String get errorNoMembers =>
      'Choisissez au moins une personne avec qui partager.';

  @override
  String get errorInvalidInput => 'Vérifiez les nombres.';

  @override
  String get errorBadRate => 'Le taux de change doit être supérieur à zéro.';

  @override
  String get errorUnknownMember =>
      'Cela concerne quelqu\'un qui n\'est pas dans le groupe.';

  @override
  String get errorUnknownCurrency => 'Cette devise n\'est pas prise en charge.';

  @override
  String get errorMemberTaken => 'Ce membre est déjà pris.';

  @override
  String get errorLimitExceeded => 'La limite est atteinte.';

  @override
  String get errorTooLarge => 'La photo est trop grande.';

  @override
  String get errorNotJpeg => 'Choisissez une photo JPEG';

  @override
  String get errorFxUnavailable =>
      'Les taux de change ne sont pas disponibles pour le moment.';

  @override
  String get errorImportFailed => 'Ce fichier n\'a pas pu être importé.';

  @override
  String get errorAuthNotConfigured =>
      'Ce serveur ne peut pas vous connecter de cette façon.';

  @override
  String get errorDuplicate => 'Cela existe déjà.';

  @override
  String errorGeneric(String code) {
    return 'Un problème est survenu ($code).';
  }

  @override
  String rejectedReceipt(String name, String reason) {
    return 'Impossible d\'enregistrer le reçu de « $name » : $reason';
  }

  @override
  String rejectedReceiptUnnamed(String reason) {
    return 'Impossible d\'enregistrer le reçu d\'une dépense : $reason';
  }

  @override
  String rejectedReceiptRemove(String name, String reason) {
    return 'Impossible d\'enregistrer le retrait d\'un reçu de « $name » : $reason';
  }

  @override
  String rejectedReceiptRemoveUnnamed(String reason) {
    return 'Impossible d\'enregistrer le retrait d\'un reçu d\'une dépense : $reason';
  }

  @override
  String rejectedRepeating(String name, String reason) {
    return 'Impossible d\'enregistrer la récurrence de « $name » : $reason';
  }

  @override
  String rejectedRepeatingUnnamed(String reason) {
    return 'Impossible d\'enregistrer une dépense récurrente : $reason';
  }

  @override
  String rejectedSeriesChange(String name, String reason) {
    return 'Impossible d\'enregistrer une modification des prochaines « $name » : $reason';
  }

  @override
  String rejectedSeriesChangeUnnamed(String reason) {
    return 'Impossible d\'enregistrer une modification d\'une dépense récurrente : $reason';
  }

  @override
  String rejectedSeriesStop(String name, String reason) {
    return 'Impossible d\'enregistrer l\'arrêt de « $name » : $reason';
  }

  @override
  String rejectedSeriesStopUnnamed(String reason) {
    return 'Impossible d\'enregistrer l\'arrêt d\'une dépense récurrente : $reason';
  }

  @override
  String rejectedSavedNoRepeat(String name, String reason) {
    return '« $name » a été enregistrée mais ne se répétera pas : $reason';
  }

  @override
  String rejectedPaymentRestore(String reason) {
    return 'Impossible d\'enregistrer la restauration d\'un paiement : $reason';
  }

  @override
  String rejectedNewExpense(String name, String reason) {
    return 'Impossible d\'enregistrer la nouvelle dépense « $name » : $reason';
  }

  @override
  String rejectedNewExpenseUnnamed(String reason) {
    return 'Impossible d\'enregistrer une nouvelle dépense : $reason';
  }

  @override
  String rejectedExpenseChange(String name, String reason) {
    return 'Impossible d\'enregistrer une modification de « $name » : $reason';
  }

  @override
  String rejectedExpenseChangeUnnamed(String reason) {
    return 'Impossible d\'enregistrer une modification d\'une dépense : $reason';
  }

  @override
  String rejectedExpenseDelete(String name, String reason) {
    return 'Impossible d\'enregistrer la suppression de « $name » : $reason';
  }

  @override
  String rejectedExpenseDeleteUnnamed(String reason) {
    return 'Impossible d\'enregistrer la suppression d\'une dépense : $reason';
  }

  @override
  String rejectedExpenseRestore(String name, String reason) {
    return 'Impossible d\'enregistrer la restauration de « $name » : $reason';
  }

  @override
  String rejectedExpenseRestoreUnnamed(String reason) {
    return 'Impossible d\'enregistrer la restauration d\'une dépense : $reason';
  }

  @override
  String rejectedComment(String name, String reason) {
    return 'Impossible d\'enregistrer un commentaire sur « $name » : $reason';
  }

  @override
  String rejectedCommentUnnamed(String reason) {
    return 'Impossible d\'enregistrer un commentaire sur une dépense : $reason';
  }

  @override
  String rejectedPaymentComment(String reason) {
    return 'Impossible d\'enregistrer un commentaire sur un paiement : $reason';
  }

  @override
  String rejectedCommentDelete(String reason) {
    return 'Impossible d\'enregistrer la suppression d\'un commentaire : $reason';
  }

  @override
  String rejectedPayment(String reason) {
    return 'Impossible d\'enregistrer un paiement : $reason';
  }

  @override
  String rejectedPaymentDelete(String reason) {
    return 'Impossible d\'enregistrer la suppression d\'un paiement : $reason';
  }

  @override
  String rejectedPaymentConfirm(String reason) {
    return 'Impossible d\'enregistrer la confirmation d\'un paiement : $reason';
  }

  @override
  String rejectedGroupSettings(String reason) {
    return 'Impossible d\'enregistrer une modification des paramètres du groupe : $reason';
  }

  @override
  String rejectedMemberAdd(String name, String reason) {
    return 'Impossible d\'enregistrer l\'ajout de $name : $reason';
  }

  @override
  String rejectedMemberAddUnnamed(String reason) {
    return 'Impossible d\'enregistrer l\'ajout d\'un membre : $reason';
  }

  @override
  String rejectedMemberRemove(String reason) {
    return 'Impossible d\'enregistrer le retrait d\'un membre : $reason';
  }

  @override
  String rejectedOther(String reason) {
    return 'Impossible d\'enregistrer une modification : $reason';
  }

  @override
  String get reasonReceiptLimit => 'une dépense peut avoir au plus 10 reçus';

  @override
  String get reasonSeriesLimit =>
      'un groupe peut avoir au plus 100 dépenses récurrentes';

  @override
  String get reasonNotUploaded => 'la photo n\'a pas été envoyée';

  @override
  String get reasonSumMismatch => 'la répartition ne tombe pas juste';

  @override
  String get reasonPayersSumMismatch => 'les payeurs ne tombent pas juste';

  @override
  String get reasonNegativeAmount => 'un montant est inférieur à zéro';

  @override
  String get reasonUnknownMember =>
      'cela concerne quelqu\'un qui n\'est pas dans le groupe';

  @override
  String get reasonUnknownCurrency => 'cette devise n\'est pas prise en charge';

  @override
  String get reasonMemberTaken => 'ce membre est déjà pris';

  @override
  String get reasonGroupFull => 'le groupe est complet';

  @override
  String get reasonForbidden =>
      'vous n\'avez pas le droit de faire cette modification';

  @override
  String get reasonRefused => 'le serveur l\'a refusée';

  @override
  String leaveOwe(String amount) {
    return 'Vous devez $amount · réglez d\'abord';
  }

  @override
  String leaveOweIn(String amount, String currency) {
    return 'Vous devez $amount · réglez d\'abord en $currency';
  }

  @override
  String leaveOwed(String amount) {
    return 'On vous doit $amount · réglez d\'abord';
  }

  @override
  String leaveOwedIn(String amount, String currency) {
    return 'On vous doit $amount · réglez d\'abord en $currency';
  }

  @override
  String leaveSeries(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Vous êtes encore dans $count dépenses récurrentes ($names) · modifiez la plus récente ou arrêtez-les d\'abord',
      one:
          'Vous êtes encore dans 1 dépense récurrente ($names) · modifiez la plus récente ou arrêtez-la d\'abord',
    );
    return '$_temp0';
  }

  @override
  String seriesNamesMore(String names, int count) {
    return '$names et $count autres';
  }

  @override
  String get seriesUnnamed => 'une dépense';

  @override
  String get listJoiner => ', ';

  @override
  String get repeatNever => 'Jamais';

  @override
  String get repeatWeekly => 'Chaque semaine';

  @override
  String get repeatBiweekly => 'Toutes les 2 semaines';

  @override
  String get repeatMonthly => 'Chaque mois';

  @override
  String get repeatYearly => 'Chaque année';

  @override
  String summaryNotConverted(String currency) {
    return 'Non converti · $currency';
  }

  @override
  String summaryTotalSpent(String amount) {
    return 'Total dépensé : $amount';
  }

  @override
  String summaryPaidShare(String paid, String share) {
    return 'Vous avez payé : $paid · Votre part : $share';
  }

  @override
  String summaryPayments(String made, String received) {
    return 'Paiements envoyés : $made · reçus : $received';
  }

  @override
  String summaryTopCategories(String list) {
    return 'Principales catégories : $list';
  }

  @override
  String get summaryBalancesToday => 'Soldes aujourd\'hui';

  @override
  String summaryGetsBack(String name, String amount) {
    return '$name récupère $amount';
  }

  @override
  String summaryOwes(String name, String amount) {
    return '$name doit $amount';
  }

  @override
  String get summaryFooter => 'Partagé depuis Evensies';

  @override
  String get koreanBank => 'Compte bancaire coréen';

  @override
  String requestText(String amount, String group) {
    return 'Vous me devez $amount pour $group sur Evensies.';
  }

  @override
  String requestTextWays(String amount, String group, String ways) {
    return 'Vous me devez $amount pour $group sur Evensies. Payer avec : $ways';
  }

  @override
  String get requestNoGroup => 'nos dépenses communes';

  @override
  String get leaveSyncing =>
      'Synchronisation en cours. Réessayez dans un instant.';

  @override
  String get leaveOffline => 'Vous devez être en ligne pour quitter';

  @override
  String get moveOffline =>
      'Impossible de la déplacer. Réessayez une fois en ligne';

  @override
  String moveFailed(String reason) {
    return 'Impossible de la déplacer : $reason';
  }

  @override
  String get photoNoAccess =>
      'Evensies n\'a pas l\'accès. Autorisez-le dans l\'app Réglages.';

  @override
  String get photoNoCamera => 'Impossible d\'ouvrir l\'appareil photo.';

  @override
  String get photoNoLibrary => 'Impossible d\'ouvrir la photothèque.';

  @override
  String get photoUnusable =>
      'Cette photo n\'a pas pu être utilisée. Essayez-en une autre.';

  @override
  String get methodErrorUsername =>
      'Lettres, chiffres, . _ - uniquement (max. 40)';

  @override
  String methodErrorLinkPrefix(String prefix) {
    return 'Doit commencer par $prefix';
  }

  @override
  String get methodErrorTooLong => '200 caractères max.';

  @override
  String get methodErrorIban => 'IBAN non valide';

  @override
  String get methodErrorHolder => 'Nom du titulaire (1 à 70 caractères)';

  @override
  String get methodErrorBic => 'Le BIC compte 8 ou 11 caractères';

  @override
  String get methodErrorKrAccount => 'Chiffres et tirets, 8 à 20 chiffres';

  @override
  String get methodErrorBank => 'Nom de la banque (1 à 30 caractères)';

  @override
  String get methodErrorUnknownType => 'Type inconnu';

  @override
  String get methodErrorTooMany =>
      '8 moyens d\'être payé au plus, et 3 par type de compte bancaire';

  @override
  String get bannerDismiss => 'Fermer';

  @override
  String get bannerView => 'Voir';

  @override
  String get loginTagline =>
      'Partagez vos dépenses entre amis. Sans pub, sans vente forcée.';

  @override
  String get loginApple => 'Continuer avec Apple';

  @override
  String get loginGoogle => 'Continuer avec Google';

  @override
  String get loginWebUnavailable =>
      'Ce serveur ne propose pas encore de connexion dans le navigateur.';

  @override
  String get welcomeTitle => 'Bienvenue';

  @override
  String get yourNameTitle => 'Votre nom';

  @override
  String get nameQuestion => 'Comment vos amis doivent-ils vous appeler ?';

  @override
  String get nameExplain => 'C\'est le nom que voient les autres membres.';

  @override
  String get nameHelp =>
      'Il est visible des personnes de vos groupes. Vous pourrez le changer plus tard dans les Réglages.';

  @override
  String get nameLabel => 'Nom';

  @override
  String get lockReason => 'Déverrouiller Evensies';

  @override
  String get lockTitle => 'Evensies est verrouillée';

  @override
  String get lockSubtitle =>
      'Déverrouillez avec Face ID, Touch ID, votre empreinte ou le code de l\'appareil.';

  @override
  String get lockUnlock => 'Déverrouiller';

  @override
  String get lockSignOutConfirm =>
      'Vous déconnecter et effacer les données de cet appareil ? Vos groupes restent sur le serveur.';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get widgetOwed => 'On vous doit';

  @override
  String get widgetOwe => 'Vous devez';

  @override
  String get widgetSignedOut => 'Connectez-vous pour voir votre solde';

  @override
  String get widgetSettled => 'Tout est réglé';

  @override
  String widgetUpdated(String time) {
    return 'Mis à jour $time';
  }

  @override
  String get receiptAdd => 'Ajouter un reçu';

  @override
  String get photoTake => 'Prendre une photo';

  @override
  String get photoChoose => 'Choisir dans la photothèque';

  @override
  String get photoChooseFile => 'Choisir un fichier';

  @override
  String get availableWhenOnline => 'Disponible en ligne';

  @override
  String get receiptPhoto => 'Photo du reçu';

  @override
  String get receiptAvailableOnline => 'La photo est disponible en ligne';

  @override
  String get receiptRemoveTitle => 'Retirer le reçu ?';

  @override
  String get receiptRemoveMessage =>
      'Il est retiré pour tout le monde dans le groupe.';

  @override
  String get receiptTitle => 'Reçu';

  @override
  String receiptTitleOf(int index, int count) {
    return 'Reçu $index sur $count';
  }

  @override
  String get shareOrSave => 'Partager ou enregistrer';

  @override
  String get share => 'Partager';

  @override
  String get copiedToClipboard => 'Copié dans le presse-papiers';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get photoRemove => 'Retirer la photo';

  @override
  String get photoNeedsConnection =>
      'Changer votre photo nécessite une connexion.';

  @override
  String get photoTooMany =>
      'Trop de changements de photo. Réessayez dans une heure.';

  @override
  String get notifSaveFailed =>
      'Impossible d\'enregistrer les réglages de notification. Vérifiez votre connexion.';

  @override
  String get homeCurrencyNeedsConnection =>
      'Changer votre devise principale nécessite une connexion.';

  @override
  String get changePhoto => 'Changer la photo de profil';

  @override
  String get yourNameTapToChange => 'Votre nom · touchez pour le changer';

  @override
  String get waysToGetPaid => 'Moyens d\'être payé';

  @override
  String get waysToGetPaidHint => 'PayPal, Wise, IBAN, compte bancaire…';

  @override
  String get homeCurrency => 'Devise principale';

  @override
  String get homeCurrencyFromRegion =>
      'Selon votre région · les soldes s\'affichent aussi en ≈ dans cette devise';

  @override
  String get homeCurrencyPicked =>
      'Les soldes s\'affichent aussi en ≈ dans cette devise';

  @override
  String get notifications => 'Notifications';

  @override
  String get notifExpenses => 'Dépenses et paiements';

  @override
  String get notifComments => 'Commentaires';

  @override
  String get notifMembers => 'Membres et modifications du groupe';

  @override
  String get notifReminders => 'Rappels de vos amis';

  @override
  String get notifNeedConnection =>
      'Les réglages de notification nécessitent une connexion';

  @override
  String get notifOthersOnly =>
      'Seules les modifications des autres vous sont notifiées.';

  @override
  String get notifWebNote =>
      'Les notifications arrivent sur votre téléphone ; le navigateur se met à jour chaque minute tant qu\'il est ouvert.';

  @override
  String get exportImport => 'Export et import';

  @override
  String get noGroupsToExport => 'Aucun groupe à exporter.';

  @override
  String get nonGroup => 'Hors groupe';

  @override
  String nonGroupWith(String name) {
    return 'Hors groupe · $name';
  }

  @override
  String get exportJson => 'Exporter en JSON';

  @override
  String get exportCsv => 'Exporter en CSV';

  @override
  String get exportZip => 'ZIP avec reçus';

  @override
  String get importSplitwise => 'Importer un CSV Splitwise';

  @override
  String importedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dépenses importées',
      one: '1 dépense importée',
    );
    return '$_temp0';
  }

  @override
  String get server => 'Serveur';

  @override
  String get serverUrl => 'URL du serveur';

  @override
  String serverDefault(String url) {
    return 'Par défaut : $url';
  }

  @override
  String get serverSaved => 'URL du serveur enregistrée';

  @override
  String get account => 'Compte';

  @override
  String get licenses => 'Licences';

  @override
  String get deleteAccount => 'Supprimer le compte';

  @override
  String get signOutTitle => 'Se déconnecter ?';

  @override
  String get signOutMessage =>
      'Les données locales de cet appareil sont effacées. Les modifications pas encore synchronisées seront perdues.';

  @override
  String get deleteAccountTitle => 'Supprimer le compte ?';

  @override
  String get deleteAccountMessage =>
      'Vos participations deviennent des emplacements. Les données des groupes restent chez les autres membres. Cette action est irréversible.';

  @override
  String get language => 'Langue';

  @override
  String languageSystem(String language) {
    return 'Système ($language)';
  }

  @override
  String get appearance => 'Apparence';

  @override
  String get appearanceSystem => 'Système';

  @override
  String get appearanceLight => 'Clair';

  @override
  String get appearanceDark => 'Sombre';

  @override
  String get security => 'Sécurité';

  @override
  String get appLock => 'Verrouillage de l\'app';

  @override
  String get appLockHint =>
      'Face ID, Touch ID ou empreinte, avec le code de l\'appareil en secours. Se verrouille après une minute d\'absence.';

  @override
  String methodRemoveTitle(String method) {
    return 'Retirer $method ?';
  }

  @override
  String get methodsOffline =>
      'Connectez-vous à Internet pour modifier vos moyens d\'être payé.';

  @override
  String get methodsLoadFailed =>
      'Impossible de charger vos moyens d\'être payé.';

  @override
  String get methodsIntro =>
      'Les membres du groupe les voient quand ils vous doivent de l\'argent, pour vous payer en un geste. Evensies ne déplace jamais d\'argent.';

  @override
  String get methodsEmpty => 'Aucun moyen d\'être payé pour l\'instant.';

  @override
  String get blurbPaypal => 'Lien PayPal.me, montant prérempli';

  @override
  String get blurbWise => 'Lien Wise Quick Pay, montant prérempli';

  @override
  String get blurbVenmo => 'Nom d\'utilisateur Venmo (États-Unis)';

  @override
  String get blurbRevolut => 'Nom d\'utilisateur Revolut.me';

  @override
  String get blurbKakaopay => 'Lien 송금코드 KakaoPay';

  @override
  String get blurbIban => 'Virement (QR SEPA pour l\'EUR)';

  @override
  String get blurbKrBank => 'Compte bancaire coréen (Toss, apps bancaires)';

  @override
  String get fieldPaypal => 'Nom d\'utilisateur PayPal.me';

  @override
  String get fieldPaypalHint => 'Votre nom d\'utilisateur PayPal.me, ex. anna';

  @override
  String get fieldRevolut => 'Nom d\'utilisateur Revolut.me';

  @override
  String get fieldRevolutHint =>
      'Votre nom d\'utilisateur Revolut.me, ex. anna';

  @override
  String get fieldVenmo => 'Nom d\'utilisateur Venmo';

  @override
  String get fieldVenmoHint => 'Sans le @, ex. anna-rossi';

  @override
  String get fieldWise => 'Lien Wise Quick Pay';

  @override
  String get fieldWiseHint =>
      'Dans Wise : Paiements → Quick Pay → copier le lien (https://wise.com/pay/…)';

  @override
  String get fieldKakaopay => 'Lien 송금코드 KakaoPay';

  @override
  String get fieldKakaopayHint =>
      'Dans KakaoPay : 송금 → 송금코드 → copier le lien (https://qr.kakaopay.com/…)';

  @override
  String get fieldHolder => 'Titulaire du compte';

  @override
  String get fieldHolderHint => 'Le nom exactement comme sur le compte';

  @override
  String get fieldIban => 'IBAN';

  @override
  String get fieldIbanHint => 'ex. FR76 3000 6000 0112 3456 7890 189';

  @override
  String get fieldBic => 'BIC (facultatif)';

  @override
  String get fieldBicHint => '8 ou 11 caractères';

  @override
  String get fieldBank => 'Banque';

  @override
  String get fieldBankHint => 'ex. 신한은행, Toss Bank';

  @override
  String get fieldAccountNumber => 'Numéro de compte';

  @override
  String get fieldAccountNumberHint => 'Chiffres, tirets facultatifs';

  @override
  String amountCopied(String amount) {
    return 'Montant copié : $amount';
  }

  @override
  String couldNotOpen(String link) {
    return 'Impossible d\'ouvrir $link';
  }

  @override
  String get payOffline =>
      'Hors ligne : les moyens de paiement ne sont pas disponibles';

  @override
  String get payLoading => 'Chargement des moyens de paiement…';

  @override
  String payAskToAdd(String name) {
    return 'Demandez à $name d\'ajouter un moyen d\'être payé';
  }

  @override
  String payTitle(String name, String amount) {
    return 'Payer $amount à $name';
  }

  @override
  String get payScanQr => 'Scannez avec votre app bancaire (QR SEPA)';

  @override
  String get payQrEurOnly =>
      'Le QR code n\'est disponible que pour les virements en EUR.';

  @override
  String get bankLabel => 'Banque';

  @override
  String get ibanLabel => 'IBAN';

  @override
  String get accountLabel => 'Compte';

  @override
  String get bicLabel => 'BIC';

  @override
  String get holderLabel => 'Titulaire';

  @override
  String get amountLabel => 'Montant';

  @override
  String get copyIban => 'Copier l\'IBAN';

  @override
  String get copyAccount => 'Copier le compte';

  @override
  String get copyAmount => 'Copier le montant';

  @override
  String get ibanCopied => 'IBAN copié';

  @override
  String get accountCopied => 'Compte copié';

  @override
  String get paymentUpdated => 'Paiement mis à jour';

  @override
  String paymentRecordedPending(String amount, String name) {
    return '$amount enregistré. $name confirmera.';
  }

  @override
  String paymentRecordedPendingUnnamed(String amount) {
    return '$amount enregistré. L\'autre personne confirmera.';
  }

  @override
  String paymentRecorded(String amount) {
    return 'Paiement de $amount enregistré';
  }

  @override
  String youSuffix(String name) {
    return '$name (vous)';
  }

  @override
  String get recordPayment => 'Enregistrer un paiement';

  @override
  String get editPayment => 'Modifier le paiement';

  @override
  String get fromLabel => 'De';

  @override
  String get toLabel => 'À';

  @override
  String get swap => 'Inverser';

  @override
  String get pickTwoPeople => 'Choisissez deux personnes différentes';

  @override
  String get commentsStayOld =>
      'Les commentaires restent sur l\'ancien paiement';

  @override
  String get recordPaymentButton => 'Enregistrer le paiement';

  @override
  String get paymentNotHere => 'Ce paiement n\'est pas sur cet appareil';

  @override
  String get notSyncedOrLeft =>
      'Il n\'est pas encore synchronisé, ou vous avez quitté son groupe.';

  @override
  String get someone => 'Quelqu\'un';

  @override
  String get paymentEdited => 'Paiement modifié';

  @override
  String get paymentDeleted => 'Paiement supprimé';

  @override
  String get payment => 'Paiement';

  @override
  String get paymentWasEdited => 'Ce paiement a été modifié';

  @override
  String get paymentWasEditedNote =>
      'C\'est le paiement modifié qui compte. Ses commentaires restent ici.';

  @override
  String get paymentWasDeleted => 'Ce paiement a été supprimé';

  @override
  String get paymentNotCounted => 'Il ne compte pas dans les soldes.';

  @override
  String get restore => 'Restaurer';

  @override
  String youPaidName(String name) {
    return 'Vous avez payé $name';
  }

  @override
  String namePaidYou(String name) {
    return '$name vous a payé';
  }

  @override
  String namePaidName(String from, String to) {
    return '$from a payé $to';
  }

  @override
  String paymentSaysSent(String name) {
    return '$name dit vous l\'avoir envoyé. L\'avez-vous reçu ?';
  }

  @override
  String waitingForConfirm(String name) {
    return 'En attente de la confirmation de $name';
  }

  @override
  String get notReceived => 'Pas reçu';

  @override
  String get confirmReceived => 'Confirmer la réception';

  @override
  String get deletePaymentTitle => 'Supprimer le paiement ?';

  @override
  String get deletePaymentMessage => 'La dette qu\'il réglait revient.';

  @override
  String get paymentDeletedSnack => 'Paiement supprimé';

  @override
  String get notReceivedTitle => 'Pas reçu ?';

  @override
  String notReceivedMessage(String name) {
    return 'Le paiement de $name est retiré et la dette revient.';
  }

  @override
  String get paymentRemovedSnack => 'Paiement retiré';

  @override
  String get recordAPayment => 'Enregistrer un paiement';

  @override
  String get nothingToSettle => 'Rien à régler';

  @override
  String get everyoneEven => 'Tout le monde est quitte.';

  @override
  String get waitingForConfirmation => 'En attente de confirmation';

  @override
  String get debtsAsRecorded =>
      'Dettes telles qu\'enregistrées · simplifier les dettes est désactivé';

  @override
  String transfersSettleEverything(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count virements règlent tout',
      one: '1 virement règle tout',
    );
    return '$_temp0';
  }

  @override
  String transfersSettleBalance(int count, String currency) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count virements règlent le solde en $currency',
      one: '1 virement règle le solde en $currency',
    );
    return '$_temp0';
  }

  @override
  String notConvertedSettlesIn(String currency) {
    return 'Non converti · $currency · se règle en $currency';
  }

  @override
  String get convert => 'Convertir';

  @override
  String get settleUp => 'Régler';

  @override
  String saysTheySent(String name, String amount) {
    return '$name dit vous avoir envoyé $amount';
  }

  @override
  String waitingToConfirmAmount(String name, String amount) {
    return 'En attente que $name confirme $amount';
  }

  @override
  String get you => 'Vous';

  @override
  String get request => 'Demander';

  @override
  String get iveSentIt => 'Je l\'ai envoyé';

  @override
  String get markAsPaid => 'Marquer comme payé';

  @override
  String markedAsSent(String name) {
    return 'Marqué comme envoyé. $name confirmera.';
  }

  @override
  String approx(String amount) {
    return '≈ $amount';
  }

  @override
  String friendOwesYou(String name, String amount) {
    return '$name vous doit $amount';
  }

  @override
  String friendYouOwe(String name, String amount) {
    return 'Vous devez $amount à $name';
  }

  @override
  String friendYouOweLine(String name, String amount) {
    return 'vous devez $amount à $name';
  }

  @override
  String noSharedGroup(String name) {
    return 'Vous ne partagez plus de groupe avec $name. Envoyez-lui votre lien d\'ami pour ajouter des dépenses.';
  }

  @override
  String get shareFriendLink => 'Partager le lien d\'ami';

  @override
  String firstExpenseNeedsConnection(String name) {
    return 'La première dépense avec $name nécessite une connexion.';
  }

  @override
  String reminderSent(String name) {
    return 'Rappel envoyé à $name';
  }

  @override
  String remindTomorrow(String name) {
    return 'Vous pourrez relancer $name demain';
  }

  @override
  String remindNothingOwed(String name) {
    return '$name ne vous doit rien';
  }

  @override
  String get remindNeedsConnection =>
      'Envoyer un rappel nécessite une connexion.';

  @override
  String amountsAnd(String a, String b) {
    return '$a et $b';
  }

  @override
  String inviteFriendText(String link) {
    return 'Je vous ai ajouté sur Evensies pour partager nos dépenses. Rejoignez-moi : $link';
  }

  @override
  String get personNotHere => 'Cette personne n\'est pas sur cet appareil';

  @override
  String get personNotHereNote =>
      'Elle n\'est pas encore synchronisée, ou vous ne partagez plus de groupe.';

  @override
  String get more => 'Plus';

  @override
  String get exportNonGroupCsv => 'Exporter les dépenses hors groupe (CSV)';

  @override
  String get exportNonGroupJson => 'Exporter les dépenses hors groupe (JSON)';

  @override
  String get exportNonGroupZip =>
      'Exporter les dépenses hors groupe (ZIP avec reçus)';

  @override
  String get notOnEvensies => 'Pas encore sur Evensies';

  @override
  String get allSettledUp => 'Tout est réglé';

  @override
  String get remind => 'Relancer';

  @override
  String get invite => 'Inviter';

  @override
  String get balances => 'Soldes';

  @override
  String get expensesAndPayments => 'Dépenses et paiements';

  @override
  String get nothingTogetherYet =>
      'Rien ensemble pour l\'instant. Ajoutez une dépense ci-dessous.';

  @override
  String get addExpense => 'Ajouter une dépense';

  @override
  String personOwesYou(String amount) {
    return 'vous doit $amount';
  }

  @override
  String personYouOwe(String amount) {
    return 'vous devez $amount';
  }

  @override
  String get personSettledUp => 'quitte';

  @override
  String recordedInGroups(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Enregistré dans $count groupes',
      one: 'Enregistré dans 1 groupe',
    );
    return '$_temp0';
  }

  @override
  String get markAsReceived => 'Marquer comme reçu';

  @override
  String get clearBothSides => 'Solder les deux côtés';

  @override
  String evenIn(String currency) {
    return 'Quitte en $currency';
  }

  @override
  String linePayThem(String group, String name, String amount) {
    return '$group : vous payez $amount à $name';
  }

  @override
  String lineTheyPay(String group, String name, String amount) {
    return '$group : $name vous paie $amount';
  }

  @override
  String get noMoneyMoves =>
      'Aucun argent ne circule : cela enregistre les deux côtés comme réglés.';

  @override
  String convertIn(String group) {
    return 'Convertir dans $group';
  }

  @override
  String settleUpWith(String name) {
    return 'Régler avec $name';
  }

  @override
  String nothingToSettleWith(String name) {
    return 'Rien à régler avec $name';
  }

  @override
  String settleWithIntro(String name) {
    return 'Tout ce qu\'il y a entre vous et $name, par devise. L\'enregistrement ajoute un paiement dans chaque groupe.';
  }

  @override
  String get searchFriendsGroups => 'Rechercher des amis et des groupes';

  @override
  String get friends => 'Amis';

  @override
  String get groups => 'Groupes';

  @override
  String get noFriendsOrGroups => 'Aucun ami ni groupe pour l\'instant.';

  @override
  String nothingMatches(String query) {
    return 'Aucun résultat pour « $query ».';
  }

  @override
  String get addExpenseWithWhom => 'Ajouter une dépense · avec qui ?';

  @override
  String friendLinkShare(String link, String code) {
    return 'Ajoutez-moi sur Evensies pour partager nos dépenses : $link\nOu saisissez mon code $code';
  }

  @override
  String get friendLinkNeedsConnection =>
      'Partager votre lien d\'ami nécessite une connexion.';

  @override
  String get selfFriend => 'C\'est votre propre code';

  @override
  String get noOneForCode => 'Personne trouvé avec ce code';

  @override
  String get addFriendNeedsConnection =>
      'Ajouter un ami nécessite une connexion.';

  @override
  String get newFriendCodeTitle => 'Obtenir un nouveau code d\'ami ?';

  @override
  String get newFriendCodeMessage =>
      'Votre lien et votre code actuels ne fonctionneront plus. Vos amis actuels restent.';

  @override
  String get newCode => 'Nouveau code';

  @override
  String get addAFriend => 'Ajouter un ami';

  @override
  String get friendLinkOffline => 'Votre lien d\'ami nécessite une connexion';

  @override
  String get yourFriendCode => 'Votre code d\'ami';

  @override
  String get friendQrLabel => 'QR code de votre lien d\'ami';

  @override
  String get friendCodeHelp =>
      'Vos amis le scannent, ouvrent le lien ou tapent le code.';

  @override
  String get shareLink => 'Partager le lien';

  @override
  String get codeCopied => 'Code copié';

  @override
  String get copyCode => 'Copier le code';

  @override
  String get haveFriendCode => 'Vous avez le code d\'un ami ?';

  @override
  String get onEvensies => 'sur Evensies';

  @override
  String get notOnEvensiesSection =>
      'Quelqu\'un qui n\'est pas encore sur Evensies';

  @override
  String get notOnEvensiesHelp =>
      'Ajoutez des dépenses avec cette personne tout de suite, et invitez-la plus tard.';

  @override
  String atMostChars(int max) {
    return '$max caractères au plus';
  }

  @override
  String addName(String name) {
    return 'Ajouter $name';
  }

  @override
  String get search => 'Rechercher';

  @override
  String get activity => 'Activité';

  @override
  String get newGroup => 'Nouveau groupe';

  @override
  String get joinWithCode => 'Rejoindre avec un code';

  @override
  String get filterAll => 'Tous';

  @override
  String get filterOwesMe => 'Me doit';

  @override
  String get filterIOwe => 'Je dois';

  @override
  String settledUpCount(int count) {
    return 'Réglé ($count)';
  }

  @override
  String get nobodyOwesYou => 'Personne ne vous doit rien';

  @override
  String get youOweNothing => 'Vous ne devez rien';

  @override
  String get nothingHereYet => 'Rien ici pour l\'instant';

  @override
  String get noFriendsYet => 'Aucun ami pour l\'instant';

  @override
  String get noFriendsHelp =>
      'Ajoutez un ami pour partager des dépenses hors groupe. Les personnes avec qui vous partagez un groupe apparaissent aussi ici.';

  @override
  String get allSettledUpYou => 'Vous êtes quitte avec tout le monde';

  @override
  String youAreOwedList(String amounts) {
    return 'On vous doit $amounts';
  }

  @override
  String youOweList(String amounts) {
    return 'Vous devez $amounts';
  }

  @override
  String get notOnEvensiesLower => 'pas encore sur Evensies';

  @override
  String get noGroupsYet => 'Aucun groupe pour l\'instant';

  @override
  String get noGroupsHelp =>
      'Créez-en un pour un voyage ou une colocation, ou rejoignez le groupe d\'un ami avec son code d\'invitation.';

  @override
  String get createGroup => 'Créer un groupe';

  @override
  String get settledUp => 'Réglé';

  @override
  String netApprox(String amount) {
    return 'Net ≈ $amount';
  }

  @override
  String memberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membres',
      one: '1 membre',
    );
    return '$_temp0';
  }

  @override
  String youOweAmount(String amount) {
    return 'Vous devez $amount';
  }

  @override
  String youAreOwedAmount(String amount) {
    return 'On vous doit $amount';
  }

  @override
  String youOweAmountLine(String amount) {
    return 'vous devez $amount';
  }

  @override
  String youAreOwedAmountLine(String amount) {
    return 'on vous doit $amount';
  }

  @override
  String get createGroupNeedsConnection =>
      'Créer un groupe nécessite une connexion.';

  @override
  String get groupName => 'Nom du groupe';

  @override
  String get yourNameInGroup => 'Votre nom dans ce groupe';

  @override
  String get defaultCurrency => 'Devise par défaut';

  @override
  String get create => 'Créer';

  @override
  String get noGroupOrFriendForCode =>
      'Aucun groupe ni ami trouvé avec ce code';

  @override
  String get joinNeedsConnection =>
      'Rejoindre un groupe nécessite une connexion.';

  @override
  String get enterACode => 'Saisir un code';

  @override
  String get enterCodeHelp =>
      'Le code d\'un groupe se trouve dans le groupe → Membres. Le code d\'un ami est dans son onglet Amis → Ajouter un ami.';

  @override
  String get pastedFromClipboard => 'Collé depuis le presse-papiers';

  @override
  String nameOnEvensies(String name) {
    return '$name · sur Evensies';
  }

  @override
  String addAsFriend(String name) {
    return 'Ajouter $name comme ami';
  }

  @override
  String addedYouAsFriend(String name) {
    return '$name vous a ajouté comme ami';
  }

  @override
  String get someoneAddedYouAsFriend => 'Quelqu\'un vous a ajouté comme ami';

  @override
  String groupPreview(String name, String members) {
    return '$name · $members';
  }

  @override
  String get continueButton => 'Continuer';

  @override
  String wantsToSplit(String name) {
    return '$name veut partager des dépenses avec vous';
  }

  @override
  String get joinGroup => 'Rejoindre le groupe';

  @override
  String get inviteInvalid => 'Ce lien d\'invitation n\'est plus valide';

  @override
  String inviteFailed(String reason) {
    return 'Impossible d\'ouvrir cette invitation : $reason';
  }

  @override
  String get friendInviteUsed => 'Cette invitation d\'ami a déjà été utilisée';

  @override
  String get joinToSeeShared =>
      'Rejoignez pour voir et ajouter vos dépenses communes.';

  @override
  String imName(String name) {
    return 'Je suis $name';
  }

  @override
  String get join => 'Rejoindre';

  @override
  String get whoAreYou => 'Qui êtes-vous ?';

  @override
  String get newMemberName => 'Nom du nouveau membre';

  @override
  String get insights => 'Statistiques';

  @override
  String get membersInvite => 'Membres et invitation';

  @override
  String get groupSettings => 'Paramètres du groupe';

  @override
  String get expenses => 'Dépenses';

  @override
  String get expenseFab => 'Dépense';

  @override
  String get groupNotHere => 'Ce groupe n\'est pas sur cet appareil';

  @override
  String get groupNotHereNote =>
      'Vous l\'avez quitté, quelqu\'un vous a retiré, ou il n\'est pas encore synchronisé.';

  @override
  String get backToGroups => 'Retour aux groupes';

  @override
  String get noExpensesYet => 'Aucune dépense pour l\'instant';

  @override
  String get tapExpenseToAdd => 'Touchez « Dépense » pour ajouter la première.';

  @override
  String tilePaidYou(String amount) {
    return 'vous avez payé $amount';
  }

  @override
  String tilePaidName(String name, String amount) {
    return '$name a payé $amount';
  }

  @override
  String tilePaidPeople(int count, String amount) {
    return '$count personnes ont payé $amount';
  }

  @override
  String get tileRefundYou => 'remboursement à vous';

  @override
  String tileRefundName(String name) {
    return 'remboursement à $name';
  }

  @override
  String tileRefundPeople(int count) {
    return 'remboursement à $count personnes';
  }

  @override
  String get notInvolved => 'non concerné';

  @override
  String get allYours => 'tout pour vous';

  @override
  String get paidForYourself => 'vous avez payé pour vous';

  @override
  String youGetBack(String amount) {
    return 'vous récupérez $amount';
  }

  @override
  String youLent(String amount) {
    return 'vous avez avancé $amount';
  }

  @override
  String youBorrowed(String amount) {
    return 'vous avez emprunté $amount';
  }

  @override
  String get repeatsLabel => 'Récurrente';

  @override
  String hasReceipt(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'A $count reçus',
      one: 'A un reçu',
    );
    return '$_temp0';
  }

  @override
  String get refund => 'Remboursement';

  @override
  String get notConverted => 'Non converti';

  @override
  String get pending => 'en attente';

  @override
  String approxTotalOwe(String amount) {
    return 'Vous devez ≈ $amount au total';
  }

  @override
  String approxTotalOwed(String amount) {
    return 'On vous doit ≈ $amount au total';
  }

  @override
  String get approxTotalNote =>
      'Dans votre devise principale, aux derniers taux';

  @override
  String nothingOwedIn(String currency) {
    return 'Rien à devoir en $currency';
  }

  @override
  String get allSettled => 'Tout est réglé';

  @override
  String get otherCurrenciesBelow =>
      'Les dépenses dans d\'autres devises sont plus bas.';

  @override
  String get nobodyOwes => 'Personne ne doit rien.';

  @override
  String youPayNext(String amount) {
    return 'Vous devriez payer la prochaine fois (vous devez $amount, le plus)';
  }

  @override
  String namePaysNext(String name, String amount) {
    return '$name devrait payer la prochaine fois (doit $amount, le plus)';
  }

  @override
  String settleUpWaiting(int count) {
    return 'Régler · $count en attente';
  }

  @override
  String memberRemoved(String name) {
    return '$name (retiré)';
  }

  @override
  String expensesWithoutRate(int count, String currency) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dépenses sans taux vers $currency',
      one: '1 dépense sans taux vers $currency',
    );
    return '$_temp0';
  }

  @override
  String expensesBadRate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dépenses avec un taux non convertible',
      one: '1 dépense avec un taux non convertible',
    );
    return '$_temp0';
  }

  @override
  String paymentsIn(String currency) {
    return 'Paiements en $currency';
  }

  @override
  String everyoneEvenIn(String currency) {
    return 'tout le monde est quitte en $currency';
  }

  @override
  String convertTo(String currency) {
    return 'Convertir en $currency';
  }

  @override
  String get balanceSettled => 'quitte';

  @override
  String get balanceGetsBack => 'récupère';

  @override
  String get balanceOwes => 'doit';

  @override
  String convertedCount(int count, String currency) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dépenses converties en $currency',
      one: '1 dépense convertie en $currency',
    );
    return '$_temp0';
  }

  @override
  String get noAutoRate => 'Pas de taux automatique. Saisissez-en un.';

  @override
  String rateOf(String date) {
    return 'taux du $date';
  }

  @override
  String rateOfOffline(String date) {
    return 'hors ligne · taux du $date';
  }

  @override
  String amountCountExpenses(String amount, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dépenses',
      one: '1 dépense',
    );
    return '$amount · $_temp0';
  }

  @override
  String paymentsStayIn(String currency) {
    return 'Les paiements en $currency restent en $currency';
  }

  @override
  String rateLabel(String from, String to) {
    return 'Taux : 1 $from en $to';
  }

  @override
  String get nothingLeftToConvert => 'Plus rien à convertir';

  @override
  String get lookingUpRate => 'Recherche du taux…';

  @override
  String get enterRateAbove0 => 'Saisissez un taux supérieur à 0';

  @override
  String convertExplain(String currency) {
    return 'Applique ce taux à chaque dépense qui n\'en a pas, pour qu\'elle compte dans les soldes en $currency. Vous pouvez toujours changer le taux de chaque dépense.';
  }

  @override
  String get nameField => 'Nom';

  @override
  String get cantChangeCurrency =>
      'Impossible de la changer après la première dépense ou le premier paiement';

  @override
  String get currencyUsedFor => 'Utilisée pour les soldes et les paiements';

  @override
  String get splitting => 'Répartition';

  @override
  String get simplifyDebts => 'Simplifier les dettes';

  @override
  String get simplifyDebtsHelp =>
      'Regroupe les dettes pour que le groupe ait besoin de moins de paiements. Le total de chacun ne change pas, seulement qui paie qui.';

  @override
  String get defaultSplit => 'Répartition par défaut';

  @override
  String get splitStale => 'Ne tombe plus juste · touchez pour corriger';

  @override
  String get membership => 'Adhésion';

  @override
  String get leaveGroup => 'Quitter le groupe';

  @override
  String get balanceSettledNote => 'Votre solde est réglé';

  @override
  String get renameGroup => 'Renommer le groupe';

  @override
  String leaveTitle(String name) {
    return 'Quitter « $name » ?';
  }

  @override
  String get leaveMessage =>
      'Vous ne verrez plus ce groupe. Vos dépenses passées restent chez les autres membres. Pour revenir, demandez le code d\'invitation.';

  @override
  String get leave => 'Quitter';

  @override
  String youLeft(String name) {
    return 'Vous avez quitté « $name »';
  }

  @override
  String get splitEqualEveryone => 'Égale · tout le monde';

  @override
  String splitPercentList(String list) {
    return 'Pourcentage · $list';
  }

  @override
  String splitSharesList(String list) {
    return 'Parts · $list';
  }

  @override
  String percentValue(String value) {
    return '$value %';
  }

  @override
  String get defaultSplitHelp =>
      'Les nouvelles dépenses commencent avec cette répartition. Vous pouvez toujours la changer pour chaque dépense.';

  @override
  String get useEqual => 'Utiliser parts égales';

  @override
  String get inviteCode => 'Code d\'invitation';

  @override
  String get inviteQrLabel => 'QR code du lien d\'invitation';

  @override
  String get inviteCodeHelp =>
      'Toute personne qui a ce code peut rejoindre et choisir son nom.';

  @override
  String inviteShareText(String group, String link, String code) {
    return 'Rejoignez mon groupe « $group » sur Evensies : $link\nOu ouvrez l\'app et saisissez le code $code';
  }

  @override
  String get rotateCode => 'Changer le code';

  @override
  String get members => 'Membres';

  @override
  String get notJoinedYet =>
      'pas encore rejoint — partagez le code d\'invitation';

  @override
  String get linked => 'associé';

  @override
  String get addPlaceholder => 'Ajouter un membre provisoire';

  @override
  String removeMemberTitle(String name) {
    return 'Retirer $name ?';
  }

  @override
  String get removeMemberMessage =>
      'Ses dépenses passées et son solde restent dans le groupe.';

  @override
  String removeMemberSeries(int count, String name, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$name est encore dans $count dépenses récurrentes ($names) ; la part de $name reste jusqu\'à ce que vous modifiiez la plus récente.',
      one:
          '$name est encore dans 1 dépense récurrente ($names) ; la part de $name reste jusqu\'à ce que vous modifiiez la plus récente.',
    );
    return '$_temp0';
  }

  @override
  String get addMember => 'Ajouter un membre';

  @override
  String get rotateInviteTitle => 'Changer le code d\'invitation ?';

  @override
  String get rotateInviteMessage =>
      'Le code et le lien actuels ne fonctionneront plus. Les personnes déjà inscrites ne sont pas concernées.';

  @override
  String get rotate => 'Changer';

  @override
  String get newInviteReady => 'Nouveau code d\'invitation prêt';

  @override
  String get activityNeedsConnection => 'L\'activité nécessite une connexion';

  @override
  String get activityOfflineNote =>
      'Les modifications récentes apparaîtront ici dès que vous serez de nouveau en ligne.';

  @override
  String get noActivityYet => 'Aucune activité pour l\'instant';

  @override
  String get activityAllGroups =>
      'Les modifications de vos groupes apparaissent ici.';

  @override
  String get activityThisGroup =>
      'Les modifications de ce groupe apparaissent ici.';

  @override
  String get showingSaved => 'Activité enregistrée. Tirez pour actualiser.';

  @override
  String get loadMore => 'Charger plus';

  @override
  String get earlier => 'Plus tôt';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get yesterday => 'Hier';

  @override
  String forDate(String date) {
    return 'pour le $date';
  }

  @override
  String get youCommented => 'Vous avez commenté';

  @override
  String nameCommented(String name) {
    return '$name a commenté';
  }

  @override
  String restoredName(String name) {
    return '« $name » restaurée';
  }

  @override
  String get paymentRestored => 'Paiement restauré';

  @override
  String get expenseNotHere => 'Cette dépense n\'est pas sur cet appareil';

  @override
  String get deletedExpense => 'Dépense supprimée';

  @override
  String get expense => 'Dépense';

  @override
  String seriesRepeats(String frequency) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Se répète chaque semaine',
      'biweekly': 'Se répète toutes les 2 semaines',
      'monthly': 'Se répète chaque mois',
      'yearly': 'Se répète chaque année',
      'other': 'Se répète',
    });
    return '$_temp0';
  }

  @override
  String seriesRepeatsNext(String frequency, String date) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Se répète chaque semaine · prochaine le $date',
      'biweekly': 'Se répète toutes les 2 semaines · prochaine le $date',
      'monthly': 'Se répète chaque mois · prochaine le $date',
      'yearly': 'Se répète chaque année · prochaine le $date',
      'other': 'Se répète · prochaine le $date',
    });
    return '$_temp0';
  }

  @override
  String seriesRepeatsNextAmount(String frequency, String amount, String date) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Se répète chaque semaine · prochaine de $amount le $date',
      'biweekly':
          'Se répète toutes les 2 semaines · prochaine de $amount le $date',
      'monthly': 'Se répète chaque mois · prochaine de $amount le $date',
      'yearly': 'Se répète chaque année · prochaine de $amount le $date',
      'other': 'Se répète · prochaine de $amount le $date',
    });
    return '$_temp0';
  }

  @override
  String rateLine(String from, String rate, String to) {
    return 'Taux : 1 $from = $rate $to';
  }

  @override
  String notConvertedTo(String currency) {
    return 'Non convertie en $currency';
  }

  @override
  String get receivedSplitBack => 'Reçu et réparti en retour';

  @override
  String get whoPaidOwes => 'Qui a payé et qui doit';

  @override
  String get items => 'Articles';

  @override
  String get notes => 'Notes';

  @override
  String get receipts => 'Reçus';

  @override
  String get history => 'Historique';

  @override
  String get deleteExpenseTitle => 'Supprimer la dépense ?';

  @override
  String get deleteExpenseMessage =>
      'Elle est supprimée pour tout le monde dans le groupe. Vous pouvez la restaurer depuis l\'Activité.';

  @override
  String get deleteRepeatingTitle => 'Supprimer la dépense récurrente ?';

  @override
  String get deleteRepeatingMessage =>
      'Elle est supprimée pour tout le monde dans le groupe. Vous pouvez la restaurer depuis l\'Activité, mais une série arrêtée ne peut pas reprendre. Les répétitions déjà ajoutées restent.';

  @override
  String get deleteThisOne => 'Supprimer celle-ci';

  @override
  String get deleteAndStop => 'Supprimer et arrêter la récurrence';

  @override
  String deletedAndStopped(String name) {
    return '« $name » supprimée et récurrence arrêtée';
  }

  @override
  String deletedName(String name) {
    return '« $name » supprimée';
  }

  @override
  String get movedToOtherGroup => 'Déplacée vers un autre groupe';

  @override
  String get movedNote =>
      'Elle compte là-bas maintenant. Ses commentaires et son historique restent ici.';

  @override
  String get expenseWasDeleted => 'Cette dépense a été supprimée';

  @override
  String get restoreToCount =>
      'Restaurez-la pour qu\'elle compte de nouveau dans les soldes.';

  @override
  String get tax => 'Taxes';

  @override
  String get tipService => 'Pourboire ou service';

  @override
  String get discount => 'Remise';

  @override
  String youPaidOwe(String paid, String owe) {
    return 'Vous avez payé $paid et devez $owe';
  }

  @override
  String youPaid(String amount) {
    return 'Vous avez payé $amount';
  }

  @override
  String youOwe(String amount) {
    return 'Vous devez $amount';
  }

  @override
  String namePaidOwes(String name, String paid, String owe) {
    return '$name a payé $paid et doit $owe';
  }

  @override
  String namePaid(String name, String amount) {
    return '$name a payé $amount';
  }

  @override
  String nameOwes(String name, String amount) {
    return '$name doit $amount';
  }

  @override
  String youReceivedGetBack(String received, String back) {
    return 'Vous avez reçu $received et récupérez $back';
  }

  @override
  String youReceived(String amount) {
    return 'Vous avez reçu $amount';
  }

  @override
  String youGetBackLine(String amount) {
    return 'Vous récupérez $amount';
  }

  @override
  String nameReceivedGetsBack(String name, String received, String back) {
    return '$name a reçu $received et récupère $back';
  }

  @override
  String nameReceived(String name, String amount) {
    return '$name a reçu $amount';
  }

  @override
  String nameGetsBack(String name, String amount) {
    return '$name récupère $amount';
  }

  @override
  String get noHistoryYet => 'Pas encore d\'historique.';

  @override
  String get historyOffline =>
      'L\'historique apparaîtra ici une fois en ligne.';

  @override
  String get showingSavedHistory => 'Historique enregistré.';

  @override
  String get showMore => 'Afficher plus';

  @override
  String get deleteCommentTitle => 'Supprimer le commentaire ?';

  @override
  String get comments => 'Commentaires';

  @override
  String get noCommentsYet => 'Aucun commentaire pour l\'instant.';

  @override
  String get deleteComment => 'Supprimer le commentaire';

  @override
  String get addComment => 'Ajouter un commentaire';

  @override
  String get send => 'Envoyer';

  @override
  String get filterByCategory => 'Filtrer par catégorie';

  @override
  String get category => 'Catégorie';

  @override
  String get categoryAll => 'Tout';

  @override
  String get month => 'Mois';

  @override
  String get searchUnavailable => 'La recherche n\'est pas disponible';

  @override
  String get searchExpenses => 'Rechercher des dépenses';

  @override
  String get searchHelp =>
      'Descriptions, notes, commentaires, catégories et montants : « taxi », « aéroport », « 12,50 ».';

  @override
  String get noMatches => 'Aucun résultat';

  @override
  String get noMatchesHelp => 'Essayez un autre mot, ou retirez un filtre.';

  @override
  String expenseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dépenses',
      one: '1 dépense',
    );
    return '$_temp0';
  }

  @override
  String get searchAllGroups => 'Rechercher dans tous les groupes';

  @override
  String searchGroup(String name) {
    return 'Rechercher dans $name';
  }

  @override
  String get searchThisGroup => 'Rechercher dans ce groupe';

  @override
  String get clear => 'Effacer';

  @override
  String get thisGroup => 'Ce groupe';

  @override
  String insightsError(String reason) {
    return 'Impossible d\'afficher les statistiques : $reason';
  }

  @override
  String get nothingToShow => 'Rien à afficher pour l\'instant';

  @override
  String get insightsEmptyHelp =>
      'Les totaux et graphiques apparaissent dès que le groupe a des dépenses.';

  @override
  String get allTime => 'Depuis le début';

  @override
  String get shareSummary => 'Partager le résumé';

  @override
  String get printSummary => 'Imprimer le résumé';

  @override
  String get previousMonth => 'Mois précédent';

  @override
  String get nextMonth => 'Mois suivant';

  @override
  String get byMonth => 'Par mois';

  @override
  String get groupSegment => 'Groupe';

  @override
  String get mineSegment => 'Moi';

  @override
  String get byCategory => 'Par catégorie';

  @override
  String get noExpensesPeriod => 'Aucune dépense sur cette période.';

  @override
  String get byPerson => 'Par personne';

  @override
  String get nobodyPaidPeriod =>
      'Personne n\'a payé ni dû quoi que ce soit sur cette période.';

  @override
  String keptUntilConverted(String currency, String group) {
    return 'Reste en $currency jusqu\'à sa conversion en $group.';
  }

  @override
  String get totalSpent => 'Total dépensé';

  @override
  String get yourShare => 'Votre part';

  @override
  String get paymentsMade => 'Paiements envoyés';

  @override
  String get paymentsReceived => 'Paiements reçus';

  @override
  String get youPaidRow => 'Vous avez payé';

  @override
  String get balanceChange => 'Évolution de votre solde';

  @override
  String get paidLegend => 'Payé';

  @override
  String get shareLegend => 'Part';

  @override
  String paidShareLine(String paid, String share) {
    return 'payé $paid · part $share';
  }

  @override
  String get itemsGiveEveryone => 'Attribuez une personne à chaque article';

  @override
  String get itemsAddPrices =>
      'Saisissez les prix des articles avant taxes ou pourboire';

  @override
  String get itemsDiscountTooBig => 'La remise dépasse l\'addition';

  @override
  String get itemsDontAddUp => 'Les articles ne tombent pas juste';

  @override
  String get adjustmentsDontFit =>
      'Les ajustements ne rentrent pas dans le total';

  @override
  String get giveSomeoneShare => 'Donnez une part à quelqu\'un';

  @override
  String get checkNumbers => 'Vérifiez les nombres';

  @override
  String get splitDoesntAddUp => 'La répartition ne tombe pas juste';

  @override
  String get addTheItems => 'Ajoutez les articles';

  @override
  String get pickOnePerson => 'Choisissez au moins une personne';

  @override
  String splitEquallyBetween(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Partagé à parts égales entre $count personnes',
      one: 'Partagé à parts égales entre 1 personne',
    );
    return '$_temp0';
  }

  @override
  String get allForOnePerson => 'Tout pour 1 personne';

  @override
  String splitEquallyEach(int count, String amount) {
    return 'Partagé à parts égales entre $count personnes · $amount chacun';
  }

  @override
  String get checkAmounts => 'Vérifiez les montants';

  @override
  String get enterTotalFirst => 'Saisissez d\'abord le total';

  @override
  String remaining(String amount) {
    return 'reste : $amount';
  }

  @override
  String overBy(String amount) {
    return 'dépassement : $amount';
  }

  @override
  String get addsUp => 'Ça tombe juste';

  @override
  String sharesInTotal(String count) {
    return '$count parts au total';
  }

  @override
  String get oneShareInTotal => '1 part au total';

  @override
  String get restSplitEqually => 'Le reste est partagé à parts égales';

  @override
  String get byPercent => 'Par pourcentage';

  @override
  String get byShares => 'Par parts';

  @override
  String get byAdjustment =>
      'Ajuster : plus ou moins pour quelqu\'un, le reste à parts égales';

  @override
  String get modeEqual => 'Égal';

  @override
  String get modeExact => 'Exact';

  @override
  String get modeShares => 'Parts';

  @override
  String get byItem => 'Par article, d\'après un reçu';

  @override
  String get adjustmentHelp =>
      'Ajoutez ou retirez un montant pour quelqu\'un ; le reste est partagé à parts égales.';

  @override
  String get noMembers => 'Aucun membre';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count articles',
      one: '1 article',
    );
    return '$_temp0';
  }

  @override
  String get addAnItem => 'Ajoutez un article';

  @override
  String atMostItems(int max) {
    return '$max articles au plus';
  }

  @override
  String get giveItemName => 'Donnez un nom à chaque article';

  @override
  String get itemNameTooLong => 'Un nom d\'article est trop long';

  @override
  String get addItem => 'Ajouter un article';

  @override
  String get giveRestToEveryone => 'Donner le reste à tout le monde';

  @override
  String get subtotal => 'Sous-total';

  @override
  String get total => 'Total';

  @override
  String receiptSays(String printed, String difference) {
    return 'Le reçu indique $printed · les articles diffèrent de $difference';
  }

  @override
  String get eachPerson => 'Par personne';

  @override
  String itemsWithoutPerson(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count articles sans personne',
      one: '1 article sans personne',
    );
    return '$_temp0';
  }

  @override
  String get itemHint => 'Article';

  @override
  String memberLeft(String name) {
    return '$name (parti)';
  }

  @override
  String get whoHadThis => 'Qui a pris ça ?';

  @override
  String get defaultSplitStartsEqual =>
      'La répartition par défaut du groupe ne tombe plus juste, celle-ci commence donc à parts égales';

  @override
  String leftToAssign(String amount) {
    return 'Reste $amount à attribuer';
  }

  @override
  String get itemsTotal => 'Le total des articles';

  @override
  String get newExpense => 'Nouvelle dépense';

  @override
  String get editExpense => 'Modifier la dépense';

  @override
  String get scanReceipt => 'Scanner un reçu';

  @override
  String get rateAboveZeroOrEmpty =>
      'Saisissez un taux supérieur à 0, ou laissez vide';

  @override
  String useAutoRate(String rate, String source) {
    return 'Utiliser le taux automatique : $rate ($source)';
  }

  @override
  String get description => 'Description';

  @override
  String get receivedBy => 'Reçu par';

  @override
  String get paidBy => 'Payé par';

  @override
  String get severalPeople => 'Plusieurs personnes';

  @override
  String get when => 'Quand';

  @override
  String get refundTooltip =>
      'De l\'argent qui est revenu, ex. la caution rendue par l\'hôtel';

  @override
  String get splitBackTo => 'Réparti en retour entre';

  @override
  String get split => 'Répartition';

  @override
  String theyOweFull(String name) {
    return '$name doit la totalité';
  }

  @override
  String iOweFull(String name) {
    return 'Je dois la totalité à $name';
  }

  @override
  String get repeat => 'Répéter';

  @override
  String editLatestRepeat(String date) {
    return 'Pour changer les prochaines répétitions, modifiez la plus récente ($date)';
  }

  @override
  String get stopsRepeating =>
      'Arrête la récurrence. Les répétitions déjà ajoutées restent.';

  @override
  String nextRepeat(String date) {
    return 'Prochaine : $date';
  }

  @override
  String get alsoChangeFuture => 'Modifier aussi les prochaines répétitions';

  @override
  String get futureFields =>
      'Montant, répartition, payeurs, description, catégorie et notes';

  @override
  String get onlyThisOne => 'Seule celle-ci change';

  @override
  String get addPhoto => 'Ajouter une photo';

  @override
  String maxReceiptsNote(int max) {
    return '$max reçus au maximum par dépense';
  }

  @override
  String get scanAReceipt => 'Scanner un reçu';

  @override
  String receiptLooksLike(String currency) {
    return 'Ce reçu semble être en $currency';
  }

  @override
  String switchToCurrencyQuestion(String currency) {
    return 'Passer la dépense en $currency pour lire ses articles ?';
  }

  @override
  String switchTo(String currency) {
    return 'Passer en $currency';
  }

  @override
  String get couldntReadItems =>
      'Impossible de lire les articles. Saisissez-les.';

  @override
  String withName(String name) {
    return 'Avec $name';
  }

  @override
  String movesTo(String name) {
    return 'Sera déplacée vers $name à l\'enregistrement';
  }

  @override
  String fromName(String name) {
    return 'Depuis $name';
  }

  @override
  String get dontMove => 'Ne pas déplacer';

  @override
  String get onlyLinkedMove =>
      'Seules les personnes sur Evensies présentes dans les deux peuvent être déplacées';

  @override
  String get auto => 'auto';

  @override
  String get noAutoRateForm =>
      'Pas de taux automatique. Saisissez-en un, ou laissez vide pour la garder dans « Non converti ».';

  @override
  String get emptyNotConverted => 'Vide : elle reste dans « Non converti »';

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
  String get yourRate => 'votre taux';
}
