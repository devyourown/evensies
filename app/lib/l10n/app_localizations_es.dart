// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Evensies';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Eliminar';

  @override
  String get remove => 'Quitar';

  @override
  String get save => 'Guardar';

  @override
  String get done => 'Listo';

  @override
  String get undo => 'Deshacer';

  @override
  String get retry => 'Reintentar';

  @override
  String get ok => 'OK';

  @override
  String get close => 'Cerrar';

  @override
  String get edit => 'Editar';

  @override
  String get add => 'Añadir';

  @override
  String get offlineBanner =>
      'Sin conexión — los cambios se sincronizarán más tarde';

  @override
  String get tooLong => 'Demasiado largo';

  @override
  String get allCurrencies => 'Todas las monedas';

  @override
  String get errorUnexpected => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String get errorNetwork => 'No tienes conexión. Inténtalo más tarde.';

  @override
  String get errorRateLimited =>
      'Demasiados intentos. Espera un minuto e inténtalo de nuevo.';

  @override
  String get errorNotFound => 'Eso ya no existe.';

  @override
  String get errorForbidden => 'No puedes hacer eso.';

  @override
  String get errorValidation => 'El servidor lo rechazó.';

  @override
  String get errorSumMismatch => 'El reparto no cuadra.';

  @override
  String get errorPayersSumMismatch => 'Los pagadores no cuadran.';

  @override
  String get errorNegativeAmount => 'Un importe es menor que cero.';

  @override
  String get errorNegativeShare =>
      'La parte de alguien quedaría por debajo de cero.';

  @override
  String get errorNegativeTotal => 'El total quedaría por debajo de cero.';

  @override
  String get errorZeroSubtotal =>
      'Añade los precios de los artículos antes de impuestos, propina o descuento.';

  @override
  String get errorUnassignedItem =>
      'Cada artículo necesita al menos una persona.';

  @override
  String get errorNoMembers => 'Elige al menos una persona con quien repartir.';

  @override
  String get errorInvalidInput => 'Revisa los números.';

  @override
  String get errorBadRate => 'El tipo de cambio debe ser mayor que cero.';

  @override
  String get errorUnknownMember =>
      'Se refiere a alguien que no está en el grupo.';

  @override
  String get errorUnknownCurrency => 'La moneda no es compatible.';

  @override
  String get errorMemberTaken => 'Ese miembro ya está ocupado.';

  @override
  String get errorLimitExceeded => 'Se alcanzó el límite.';

  @override
  String get errorTooLarge => 'La foto es demasiado grande.';

  @override
  String get errorNotJpeg => 'Elige una foto JPEG';

  @override
  String get errorFxUnavailable =>
      'Los tipos de cambio no están disponibles ahora mismo.';

  @override
  String get errorImportFailed => 'No se pudo importar ese archivo.';

  @override
  String get errorAuthNotConfigured =>
      'Este servidor no puede iniciar tu sesión de esa forma.';

  @override
  String get errorDuplicate => 'Eso ya existe.';

  @override
  String errorGeneric(String code) {
    return 'Algo salió mal ($code).';
  }

  @override
  String rejectedReceipt(String name, String reason) {
    return 'No se pudo guardar el recibo de “$name”: $reason';
  }

  @override
  String rejectedReceiptUnnamed(String reason) {
    return 'No se pudo guardar el recibo de un gasto: $reason';
  }

  @override
  String rejectedReceiptRemove(String name, String reason) {
    return 'No se pudo guardar la eliminación de un recibo de “$name”: $reason';
  }

  @override
  String rejectedReceiptRemoveUnnamed(String reason) {
    return 'No se pudo guardar la eliminación de un recibo de un gasto: $reason';
  }

  @override
  String rejectedRepeating(String name, String reason) {
    return 'No se pudo guardar la repetición de “$name”: $reason';
  }

  @override
  String rejectedRepeatingUnnamed(String reason) {
    return 'No se pudo guardar un gasto recurrente: $reason';
  }

  @override
  String rejectedSeriesChange(String name, String reason) {
    return 'No se pudo guardar un cambio en los próximos “$name”: $reason';
  }

  @override
  String rejectedSeriesChangeUnnamed(String reason) {
    return 'No se pudo guardar un cambio en un gasto recurrente: $reason';
  }

  @override
  String rejectedSeriesStop(String name, String reason) {
    return 'No se pudo guardar que “$name” deje de repetirse: $reason';
  }

  @override
  String rejectedSeriesStopUnnamed(String reason) {
    return 'No se pudo guardar que un gasto recurrente deje de repetirse: $reason';
  }

  @override
  String rejectedSavedNoRepeat(String name, String reason) {
    return '“$name” se guardó pero no se repetirá: $reason';
  }

  @override
  String rejectedPaymentRestore(String reason) {
    return 'No se pudo guardar la restauración de un pago: $reason';
  }

  @override
  String rejectedNewExpense(String name, String reason) {
    return 'No se pudo guardar el nuevo gasto “$name”: $reason';
  }

  @override
  String rejectedNewExpenseUnnamed(String reason) {
    return 'No se pudo guardar un gasto nuevo: $reason';
  }

  @override
  String rejectedExpenseChange(String name, String reason) {
    return 'No se pudo guardar un cambio en “$name”: $reason';
  }

  @override
  String rejectedExpenseChangeUnnamed(String reason) {
    return 'No se pudo guardar un cambio en un gasto: $reason';
  }

  @override
  String rejectedExpenseDelete(String name, String reason) {
    return 'No se pudo guardar la eliminación de “$name”: $reason';
  }

  @override
  String rejectedExpenseDeleteUnnamed(String reason) {
    return 'No se pudo guardar la eliminación de un gasto: $reason';
  }

  @override
  String rejectedExpenseRestore(String name, String reason) {
    return 'No se pudo guardar la restauración de “$name”: $reason';
  }

  @override
  String rejectedExpenseRestoreUnnamed(String reason) {
    return 'No se pudo guardar la restauración de un gasto: $reason';
  }

  @override
  String rejectedComment(String name, String reason) {
    return 'No se pudo guardar un comentario en “$name”: $reason';
  }

  @override
  String rejectedCommentUnnamed(String reason) {
    return 'No se pudo guardar un comentario en un gasto: $reason';
  }

  @override
  String rejectedPaymentComment(String reason) {
    return 'No se pudo guardar un comentario en un pago: $reason';
  }

  @override
  String rejectedCommentDelete(String reason) {
    return 'No se pudo guardar la eliminación de un comentario: $reason';
  }

  @override
  String rejectedPayment(String reason) {
    return 'No se pudo guardar un pago: $reason';
  }

  @override
  String rejectedPaymentDelete(String reason) {
    return 'No se pudo guardar la eliminación de un pago: $reason';
  }

  @override
  String rejectedPaymentConfirm(String reason) {
    return 'No se pudo guardar la confirmación de un pago: $reason';
  }

  @override
  String rejectedGroupSettings(String reason) {
    return 'No se pudo guardar un cambio en los ajustes del grupo: $reason';
  }

  @override
  String rejectedMemberAdd(String name, String reason) {
    return 'No se pudo guardar la incorporación de $name: $reason';
  }

  @override
  String rejectedMemberAddUnnamed(String reason) {
    return 'No se pudo guardar la incorporación de un miembro: $reason';
  }

  @override
  String rejectedMemberRemove(String reason) {
    return 'No se pudo guardar la eliminación de un miembro: $reason';
  }

  @override
  String rejectedOther(String reason) {
    return 'No se pudo guardar un cambio: $reason';
  }

  @override
  String get reasonReceiptLimit =>
      'un gasto puede tener como máximo 10 recibos';

  @override
  String get reasonSeriesLimit =>
      'un grupo puede tener como máximo 100 gastos recurrentes';

  @override
  String get reasonNotUploaded => 'la foto no se subió';

  @override
  String get reasonSumMismatch => 'el reparto no cuadra';

  @override
  String get reasonPayersSumMismatch => 'los pagadores no cuadran';

  @override
  String get reasonNegativeAmount => 'un importe es menor que cero';

  @override
  String get reasonUnknownMember =>
      'se refiere a alguien que no está en el grupo';

  @override
  String get reasonUnknownCurrency => 'la moneda no es compatible';

  @override
  String get reasonMemberTaken => 'ese miembro ya está ocupado';

  @override
  String get reasonGroupFull => 'el grupo está lleno';

  @override
  String get reasonForbidden => 'no puedes hacer ese cambio';

  @override
  String get reasonRefused => 'el servidor lo rechazó';

  @override
  String leaveOwe(String amount) {
    return 'Debes $amount · salda primero';
  }

  @override
  String leaveOweIn(String amount, String currency) {
    return 'Debes $amount · salda primero en $currency';
  }

  @override
  String leaveOwed(String amount) {
    return 'Te deben $amount · salda primero';
  }

  @override
  String leaveOwedIn(String amount, String currency) {
    return 'Te deben $amount · salda primero en $currency';
  }

  @override
  String leaveSeries(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Sigues en $count gastos recurrentes ($names) · edita el último o detenlos primero',
      one:
          'Sigues en 1 gasto recurrente ($names) · edita el último o detenlo primero',
    );
    return '$_temp0';
  }

  @override
  String seriesNamesMore(String names, int count) {
    return '$names y $count más';
  }

  @override
  String get seriesUnnamed => 'un gasto';

  @override
  String get listJoiner => ', ';

  @override
  String get repeatNever => 'Nunca';

  @override
  String get repeatWeekly => 'Cada semana';

  @override
  String get repeatBiweekly => 'Cada 2 semanas';

  @override
  String get repeatMonthly => 'Cada mes';

  @override
  String get repeatYearly => 'Cada año';

  @override
  String summaryNotConverted(String currency) {
    return 'Sin convertir · $currency';
  }

  @override
  String summaryTotalSpent(String amount) {
    return 'Total gastado: $amount';
  }

  @override
  String summaryPaidShare(String paid, String share) {
    return 'Pagaste: $paid · Tu parte: $share';
  }

  @override
  String summaryPayments(String made, String received) {
    return 'Pagos hechos: $made · recibidos: $received';
  }

  @override
  String summaryTopCategories(String list) {
    return 'Categorías principales: $list';
  }

  @override
  String get summaryBalancesToday => 'Saldos de hoy';

  @override
  String summaryGetsBack(String name, String amount) {
    return '$name recupera $amount';
  }

  @override
  String summaryOwes(String name, String amount) {
    return '$name debe $amount';
  }

  @override
  String get summaryFooter => 'Compartido desde Evensies';

  @override
  String get koreanBank => 'Cuenta bancaria coreana';

  @override
  String requestText(String amount, String group) {
    return 'Me debes $amount por $group en Evensies.';
  }

  @override
  String requestTextWays(String amount, String group, String ways) {
    return 'Me debes $amount por $group en Evensies. Paga con: $ways';
  }

  @override
  String get requestNoGroup => 'nuestros gastos compartidos';

  @override
  String get leaveSyncing =>
      'Aún se está sincronizando. Inténtalo en un momento.';

  @override
  String get leaveOffline => 'Necesitas conexión para salir';

  @override
  String get moveOffline =>
      'No se pudo mover. Inténtalo cuando tengas conexión';

  @override
  String moveFailed(String reason) {
    return 'No se pudo mover: $reason';
  }

  @override
  String get photoNoAccess =>
      'Evensies no tiene acceso. Permítelo en la app Ajustes.';

  @override
  String get photoNoCamera => 'No se pudo abrir la cámara.';

  @override
  String get photoNoLibrary => 'No se pudo abrir la fototeca.';

  @override
  String get photoUnusable => 'No se pudo usar esa foto. Prueba con otra.';

  @override
  String get methodErrorUsername => 'Solo letras, números, . _ - (máx. 40)';

  @override
  String methodErrorLinkPrefix(String prefix) {
    return 'Debe empezar por $prefix';
  }

  @override
  String get methodErrorTooLong => 'Máx. 200 caracteres';

  @override
  String get methodErrorIban => 'IBAN no válido';

  @override
  String get methodErrorHolder => 'Nombre del titular (1–70 caracteres)';

  @override
  String get methodErrorBic => 'El BIC tiene 8 u 11 caracteres';

  @override
  String get methodErrorKrAccount => 'Números y guiones, 8–20 dígitos';

  @override
  String get methodErrorBank => 'Nombre del banco (1–30 caracteres)';

  @override
  String get methodErrorUnknownType => 'Tipo desconocido';

  @override
  String get methodErrorTooMany =>
      'Como máximo 8 formas de cobrar, y 3 de cada tipo bancario';

  @override
  String get bannerDismiss => 'Descartar';

  @override
  String get bannerView => 'Ver';

  @override
  String get loginTagline =>
      'Reparte gastos con tus amigos. Sin anuncios ni ventas forzadas.';

  @override
  String get loginApple => 'Continuar con Apple';

  @override
  String get loginGoogle => 'Continuar con Google';

  @override
  String get loginWebUnavailable =>
      'Este servidor aún no permite iniciar sesión desde el navegador.';

  @override
  String get welcomeTitle => 'Te damos la bienvenida';

  @override
  String get yourNameTitle => 'Tu nombre';

  @override
  String get nameQuestion => '¿Cómo deberían llamarte tus amigos?';

  @override
  String get nameExplain => 'Este es el nombre que ven los demás miembros.';

  @override
  String get nameHelp =>
      'Lo ven las personas de tus grupos. Puedes cambiarlo más tarde en Ajustes.';

  @override
  String get nameLabel => 'Nombre';

  @override
  String get lockReason => 'Desbloquear Evensies';

  @override
  String get lockTitle => 'Evensies está bloqueada';

  @override
  String get lockSubtitle =>
      'Desbloquea con Face ID, Touch ID, tu huella o el código del dispositivo.';

  @override
  String get lockUnlock => 'Desbloquear';

  @override
  String get lockSignOutConfirm =>
      '¿Cerrar sesión y borrar los datos de este dispositivo? Tus grupos siguen en el servidor.';

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get widgetOwed => 'Te deben';

  @override
  String get widgetOwe => 'Debes';

  @override
  String get widgetSignedOut => 'Inicia sesión para ver tu saldo';

  @override
  String get widgetSettled => 'Todo saldado';

  @override
  String widgetUpdated(String time) {
    return 'Actualizado $time';
  }

  @override
  String get receiptAdd => 'Añadir un recibo';

  @override
  String get photoTake => 'Hacer foto';

  @override
  String get photoChoose => 'Elegir de la fototeca';

  @override
  String get photoChooseFile => 'Elegir un archivo';

  @override
  String get availableWhenOnline => 'Disponible con conexión';

  @override
  String get receiptPhoto => 'Foto del recibo';

  @override
  String get receiptAvailableOnline => 'La foto está disponible con conexión';

  @override
  String get receiptRemoveTitle => '¿Quitar el recibo?';

  @override
  String get receiptRemoveMessage => 'Se quita para todos en el grupo.';

  @override
  String get receiptTitle => 'Recibo';

  @override
  String receiptTitleOf(int index, int count) {
    return 'Recibo $index de $count';
  }

  @override
  String get shareOrSave => 'Compartir o guardar';

  @override
  String get share => 'Compartir';

  @override
  String get copiedToClipboard => 'Copiado al portapapeles';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get photoRemove => 'Quitar foto';

  @override
  String get photoNeedsConnection => 'Cambiar tu foto requiere conexión.';

  @override
  String get photoTooMany =>
      'Demasiados cambios de foto. Inténtalo dentro de una hora.';

  @override
  String get notifSaveFailed =>
      'No se pudieron guardar los ajustes de notificaciones. Revisa tu conexión.';

  @override
  String get homeCurrencyNeedsConnection =>
      'Cambiar tu moneda principal requiere conexión.';

  @override
  String get changePhoto => 'Cambiar foto de perfil';

  @override
  String get yourNameTapToChange => 'Tu nombre · toca para cambiarlo';

  @override
  String get waysToGetPaid => 'Formas de cobrar';

  @override
  String get waysToGetPaidHint => 'PayPal, Wise, IBAN, cuenta bancaria…';

  @override
  String get homeCurrency => 'Moneda principal';

  @override
  String get homeCurrencyFromRegion =>
      'Según tu región · los saldos también muestran ≈ en ella';

  @override
  String get homeCurrencyPicked => 'Los saldos también muestran ≈ en ella';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get notifExpenses => 'Gastos y pagos';

  @override
  String get notifComments => 'Comentarios';

  @override
  String get notifMembers => 'Miembros y cambios del grupo';

  @override
  String get notifReminders => 'Recordatorios de amigos';

  @override
  String get notifNeedConnection =>
      'Los ajustes de notificaciones necesitan conexión';

  @override
  String get notifOthersOnly =>
      'Solo te avisamos de los cambios que hacen otras personas.';

  @override
  String get notifWebNote =>
      'Las notificaciones van a tu teléfono; el navegador se actualiza cada minuto mientras está abierto.';

  @override
  String get exportImport => 'Exportar e importar';

  @override
  String get noGroupsToExport => 'No hay grupos para exportar.';

  @override
  String get nonGroup => 'Sin grupo';

  @override
  String nonGroupWith(String name) {
    return 'Sin grupo · $name';
  }

  @override
  String get exportJson => 'Exportar JSON';

  @override
  String get exportCsv => 'Exportar CSV';

  @override
  String get exportZip => 'ZIP con recibos';

  @override
  String get importSplitwise => 'Importar CSV de Splitwise';

  @override
  String importedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gastos importados',
      one: '1 gasto importado',
    );
    return '$_temp0';
  }

  @override
  String get server => 'Servidor';

  @override
  String get serverUrl => 'URL del servidor';

  @override
  String serverDefault(String url) {
    return 'Predeterminado: $url';
  }

  @override
  String get serverSaved => 'URL del servidor guardada';

  @override
  String get account => 'Cuenta';

  @override
  String get licenses => 'Licencias';

  @override
  String get deleteAccount => 'Eliminar cuenta';

  @override
  String get signOutTitle => '¿Cerrar sesión?';

  @override
  String get signOutMessage =>
      'Se borran los datos locales de este dispositivo. Los cambios aún sin sincronizar se perderán.';

  @override
  String get deleteAccountTitle => '¿Eliminar la cuenta?';

  @override
  String get deleteAccountMessage =>
      'Tus membresías pasan a ser marcadores. Los datos de los grupos se quedan con los demás miembros. No se puede deshacer.';

  @override
  String get language => 'Idioma';

  @override
  String languageSystem(String language) {
    return 'Sistema ($language)';
  }

  @override
  String get appearance => 'Apariencia';

  @override
  String get appearanceSystem => 'Sistema';

  @override
  String get appearanceLight => 'Claro';

  @override
  String get appearanceDark => 'Oscuro';

  @override
  String get security => 'Seguridad';

  @override
  String get appLock => 'Bloqueo de la app';

  @override
  String get appLockHint =>
      'Face ID, Touch ID o huella, con el código del dispositivo como alternativa. Se bloquea tras un minuto fuera.';

  @override
  String methodRemoveTitle(String method) {
    return '¿Quitar $method?';
  }

  @override
  String get methodsOffline =>
      'Conéctate a internet para editar tus formas de cobrar.';

  @override
  String get methodsLoadFailed => 'No se pudieron cargar tus formas de cobrar.';

  @override
  String get methodsIntro =>
      'Los miembros del grupo las ven cuando te deben dinero, para pagarte con un toque. Evensies nunca mueve dinero.';

  @override
  String get methodsEmpty => 'Aún no hay formas de cobrar.';

  @override
  String get blurbPaypal => 'Enlace de PayPal.me, con el importe';

  @override
  String get blurbWise => 'Enlace de Wise Quick Pay, con el importe';

  @override
  String get blurbVenmo => 'Usuario de Venmo (EE. UU.)';

  @override
  String get blurbRevolut => 'Usuario de Revolut.me';

  @override
  String get blurbKakaopay => 'Enlace 송금코드 de KakaoPay';

  @override
  String get blurbIban => 'Transferencia (QR SEPA para EUR)';

  @override
  String get blurbKrBank => 'Cuenta bancaria coreana (Toss, apps bancarias)';

  @override
  String get fieldPaypal => 'Usuario de PayPal.me';

  @override
  String get fieldPaypalHint => 'Tu usuario de PayPal.me, p. ej. anna';

  @override
  String get fieldRevolut => 'Usuario de Revolut.me';

  @override
  String get fieldRevolutHint => 'Tu usuario de Revolut.me, p. ej. anna';

  @override
  String get fieldVenmo => 'Usuario de Venmo';

  @override
  String get fieldVenmoHint => 'Sin la @, p. ej. anna-rossi';

  @override
  String get fieldWise => 'Enlace de Wise Quick Pay';

  @override
  String get fieldWiseHint =>
      'En Wise: Pagos → Quick Pay → copiar enlace (https://wise.com/pay/…)';

  @override
  String get fieldKakaopay => 'Enlace 송금코드 de KakaoPay';

  @override
  String get fieldKakaopayHint =>
      'En KakaoPay: 송금 → 송금코드 → copiar enlace (https://qr.kakaopay.com/…)';

  @override
  String get fieldHolder => 'Titular de la cuenta';

  @override
  String get fieldHolderHint => 'El nombre tal como figura en la cuenta';

  @override
  String get fieldIban => 'IBAN';

  @override
  String get fieldIbanHint => 'p. ej. ES91 2100 0418 4502 0005 1332';

  @override
  String get fieldBic => 'BIC (opcional)';

  @override
  String get fieldBicHint => '8 u 11 caracteres';

  @override
  String get fieldBank => 'Banco';

  @override
  String get fieldBankHint => 'p. ej. 신한은행, Toss Bank';

  @override
  String get fieldAccountNumber => 'Número de cuenta';

  @override
  String get fieldAccountNumberHint => 'Números, guiones opcionales';

  @override
  String amountCopied(String amount) {
    return 'Importe copiado: $amount';
  }

  @override
  String couldNotOpen(String link) {
    return 'No se pudo abrir $link';
  }

  @override
  String get payOffline =>
      'Sin conexión: las formas de pago no están disponibles';

  @override
  String get payLoading => 'Cargando formas de pago…';

  @override
  String payAskToAdd(String name) {
    return 'Pide a $name que añada una forma de cobrar';
  }

  @override
  String payTitle(String name, String amount) {
    return 'Pagar $amount a $name';
  }

  @override
  String get payScanQr => 'Escanéalo con la app de tu banco (QR SEPA)';

  @override
  String get payQrEurOnly =>
      'El código QR solo está disponible para transferencias en EUR.';

  @override
  String get bankLabel => 'Banco';

  @override
  String get ibanLabel => 'IBAN';

  @override
  String get accountLabel => 'Cuenta';

  @override
  String get bicLabel => 'BIC';

  @override
  String get holderLabel => 'Titular';

  @override
  String get amountLabel => 'Importe';

  @override
  String get copyIban => 'Copiar IBAN';

  @override
  String get copyAccount => 'Copiar cuenta';

  @override
  String get copyAmount => 'Copiar importe';

  @override
  String get ibanCopied => 'IBAN copiado';

  @override
  String get accountCopied => 'Cuenta copiada';

  @override
  String get paymentUpdated => 'Pago actualizado';

  @override
  String paymentRecordedPending(String amount, String name) {
    return 'Se registró $amount. $name lo confirmará.';
  }

  @override
  String paymentRecordedPendingUnnamed(String amount) {
    return 'Se registró $amount. La otra persona lo confirmará.';
  }

  @override
  String paymentRecorded(String amount) {
    return 'Pago de $amount registrado';
  }

  @override
  String youSuffix(String name) {
    return '$name (tú)';
  }

  @override
  String get recordPayment => 'Registrar un pago';

  @override
  String get editPayment => 'Editar pago';

  @override
  String get fromLabel => 'De';

  @override
  String get toLabel => 'Para';

  @override
  String get swap => 'Intercambiar';

  @override
  String get pickTwoPeople => 'Elige dos personas distintas';

  @override
  String get commentsStayOld => 'Los comentarios se quedan en el pago anterior';

  @override
  String get recordPaymentButton => 'Registrar pago';

  @override
  String get paymentNotHere => 'Este pago no está en este dispositivo';

  @override
  String get notSyncedOrLeft =>
      'Aún no se ha sincronizado, o saliste de su grupo.';

  @override
  String get someone => 'Alguien';

  @override
  String get paymentEdited => 'Pago editado';

  @override
  String get paymentDeleted => 'Pago eliminado';

  @override
  String get payment => 'Pago';

  @override
  String get paymentWasEdited => 'Este pago se editó';

  @override
  String get paymentWasEditedNote =>
      'Ahora cuenta el pago editado. Sus comentarios se quedan aquí.';

  @override
  String get paymentWasDeleted => 'Este pago se eliminó';

  @override
  String get paymentNotCounted => 'No cuenta en los saldos.';

  @override
  String get restore => 'Restaurar';

  @override
  String youPaidName(String name) {
    return 'Le pagaste a $name';
  }

  @override
  String namePaidYou(String name) {
    return '$name te pagó';
  }

  @override
  String namePaidName(String from, String to) {
    return '$from le pagó a $to';
  }

  @override
  String paymentSaysSent(String name) {
    return '$name dice que te lo envió. ¿Te llegó?';
  }

  @override
  String waitingForConfirm(String name) {
    return 'Esperando la confirmación de $name';
  }

  @override
  String get notReceived => 'No recibido';

  @override
  String get confirmReceived => 'Confirmar recibido';

  @override
  String get deletePaymentTitle => '¿Eliminar el pago?';

  @override
  String get deletePaymentMessage => 'La deuda que saldaba vuelve.';

  @override
  String get paymentDeletedSnack => 'Pago eliminado';

  @override
  String get notReceivedTitle => '¿No lo recibiste?';

  @override
  String notReceivedMessage(String name) {
    return 'Se quita el pago de $name y la deuda vuelve.';
  }

  @override
  String get paymentRemovedSnack => 'Pago quitado';

  @override
  String get recordAPayment => 'Registrar un pago';

  @override
  String get nothingToSettle => 'Nada que saldar';

  @override
  String get everyoneEven => 'Todos están en paz.';

  @override
  String get waitingForConfirmation => 'Esperando confirmación';

  @override
  String get debtsAsRecorded =>
      'Deudas tal como se registraron · simplificar deudas está desactivado';

  @override
  String transfersSettleEverything(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transferencias lo saldan todo',
      one: '1 transferencia lo salda todo',
    );
    return '$_temp0';
  }

  @override
  String transfersSettleBalance(int count, String currency) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transferencias saldan el saldo en $currency',
      one: '1 transferencia salda el saldo en $currency',
    );
    return '$_temp0';
  }

  @override
  String notConvertedSettlesIn(String currency) {
    return 'Sin convertir · $currency · se salda en $currency';
  }

  @override
  String get convert => 'Convertir';

  @override
  String get settleUp => 'Saldar';

  @override
  String saysTheySent(String name, String amount) {
    return '$name dice que te envió $amount';
  }

  @override
  String waitingToConfirmAmount(String name, String amount) {
    return 'Esperando a que $name confirme $amount';
  }

  @override
  String get you => 'Tú';

  @override
  String get request => 'Pedir';

  @override
  String get iveSentIt => 'Ya lo envié';

  @override
  String get markAsPaid => 'Marcar como pagado';

  @override
  String markedAsSent(String name) {
    return 'Marcado como enviado. $name lo confirmará.';
  }

  @override
  String approx(String amount) {
    return '≈ $amount';
  }

  @override
  String friendOwesYou(String name, String amount) {
    return '$name te debe $amount';
  }

  @override
  String friendYouOwe(String name, String amount) {
    return 'Le debes $amount a $name';
  }

  @override
  String friendYouOweLine(String name, String amount) {
    return 'le debes $amount a $name';
  }

  @override
  String noSharedGroup(String name) {
    return 'Ya no compartes un grupo con $name. Envíale tu enlace de amistad para añadir gastos.';
  }

  @override
  String get shareFriendLink => 'Compartir enlace de amistad';

  @override
  String firstExpenseNeedsConnection(String name) {
    return 'El primer gasto con $name necesita conexión.';
  }

  @override
  String reminderSent(String name) {
    return 'Recordatorio enviado a $name';
  }

  @override
  String remindTomorrow(String name) {
    return 'Podrás recordárselo a $name de nuevo mañana';
  }

  @override
  String remindNothingOwed(String name) {
    return '$name no te debe nada';
  }

  @override
  String get remindNeedsConnection =>
      'Enviar un recordatorio necesita conexión.';

  @override
  String amountsAnd(String a, String b) {
    return '$a y $b';
  }

  @override
  String inviteFriendText(String link) {
    return 'Te añadí en Evensies para que repartamos gastos. Únete: $link';
  }

  @override
  String get personNotHere => 'Esta persona no está en este dispositivo';

  @override
  String get personNotHereNote =>
      'Aún no se ha sincronizado, o ya no compartís un grupo.';

  @override
  String get more => 'Más';

  @override
  String get exportNonGroupCsv => 'Exportar gastos sin grupo (CSV)';

  @override
  String get exportNonGroupJson => 'Exportar gastos sin grupo (JSON)';

  @override
  String get exportNonGroupZip => 'Exportar gastos sin grupo (ZIP con recibos)';

  @override
  String get notOnEvensies => 'Aún no está en Evensies';

  @override
  String get allSettledUp => 'Todo saldado';

  @override
  String get remind => 'Recordar';

  @override
  String get invite => 'Invitar';

  @override
  String get balances => 'Saldos';

  @override
  String get expensesAndPayments => 'Gastos y pagos';

  @override
  String get nothingTogetherYet => 'Aún nada en común. Añade un gasto abajo.';

  @override
  String get addExpense => 'Añadir gasto';

  @override
  String personOwesYou(String amount) {
    return 'te debe $amount';
  }

  @override
  String personYouOwe(String amount) {
    return 'le debes $amount';
  }

  @override
  String get personSettledUp => 'en paz';

  @override
  String recordedInGroups(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Registrado en $count grupos',
      one: 'Registrado en 1 grupo',
    );
    return '$_temp0';
  }

  @override
  String get markAsReceived => 'Marcar como recibido';

  @override
  String get clearBothSides => 'Saldar ambos lados';

  @override
  String evenIn(String currency) {
    return 'En paz en $currency';
  }

  @override
  String linePayThem(String group, String name, String amount) {
    return '$group: le pagas $amount a $name';
  }

  @override
  String lineTheyPay(String group, String name, String amount) {
    return '$group: $name te paga $amount';
  }

  @override
  String get noMoneyMoves =>
      'No se mueve dinero: se registran ambos lados como saldados.';

  @override
  String convertIn(String group) {
    return 'Convertir en $group';
  }

  @override
  String settleUpWith(String name) {
    return 'Saldar con $name';
  }

  @override
  String nothingToSettleWith(String name) {
    return 'Nada que saldar con $name';
  }

  @override
  String settleWithIntro(String name) {
    return 'Todo entre tú y $name, por moneda. Al registrar se añade un pago en cada grupo.';
  }

  @override
  String get searchFriendsGroups => 'Buscar amigos y grupos';

  @override
  String get friends => 'Amigos';

  @override
  String get groups => 'Grupos';

  @override
  String get noFriendsOrGroups => 'Aún no hay amigos ni grupos.';

  @override
  String nothingMatches(String query) {
    return 'Nada coincide con “$query”.';
  }

  @override
  String get addExpenseWithWhom => 'Añadir gasto · ¿con quién?';

  @override
  String friendLinkShare(String link, String code) {
    return 'Añádeme en Evensies para repartir gastos: $link\nO introduce mi código $code';
  }

  @override
  String get friendLinkNeedsConnection =>
      'Compartir tu enlace de amistad necesita conexión.';

  @override
  String get selfFriend => 'Es tu propio código';

  @override
  String get noOneForCode => 'No se encontró a nadie con este código';

  @override
  String get addFriendNeedsConnection => 'Añadir un amigo necesita conexión.';

  @override
  String get newFriendCodeTitle => '¿Crear un nuevo código de amistad?';

  @override
  String get newFriendCodeMessage =>
      'Tu enlace y código actuales dejarán de funcionar. Los amigos que ya tienes se quedan.';

  @override
  String get newCode => 'Nuevo código';

  @override
  String get addAFriend => 'Añadir un amigo';

  @override
  String get friendLinkOffline => 'Tu enlace de amistad necesita conexión';

  @override
  String get yourFriendCode => 'Tu código de amistad';

  @override
  String get friendQrLabel => 'Código QR de tu enlace de amistad';

  @override
  String get friendCodeHelp =>
      'Tus amigos lo escanean, abren el enlace o escriben el código.';

  @override
  String get shareLink => 'Compartir enlace';

  @override
  String get codeCopied => 'Código copiado';

  @override
  String get copyCode => 'Copiar código';

  @override
  String get haveFriendCode => '¿Tienes el código de un amigo?';

  @override
  String get onEvensies => 'en Evensies';

  @override
  String get notOnEvensiesSection => 'Alguien que aún no está en Evensies';

  @override
  String get notOnEvensiesHelp =>
      'Añade gastos con esa persona ya, e invítala más tarde.';

  @override
  String atMostChars(int max) {
    return 'Como máximo $max caracteres';
  }

  @override
  String addName(String name) {
    return 'Añadir a $name';
  }

  @override
  String get search => 'Buscar';

  @override
  String get activity => 'Actividad';

  @override
  String get newGroup => 'Nuevo grupo';

  @override
  String get joinWithCode => 'Unirse con un código';

  @override
  String get filterAll => 'Todos';

  @override
  String get filterOwesMe => 'Me deben';

  @override
  String get filterIOwe => 'Debo';

  @override
  String settledUpCount(int count) {
    return 'Saldado ($count)';
  }

  @override
  String get nobodyOwesYou => 'Nadie te debe nada';

  @override
  String get youOweNothing => 'No debes nada';

  @override
  String get nothingHereYet => 'Aún no hay nada aquí';

  @override
  String get noFriendsYet => 'Aún no tienes amigos';

  @override
  String get noFriendsHelp =>
      'Añade un amigo para repartir gastos fuera de un grupo. Aquí también aparecen las personas con las que compartes un grupo.';

  @override
  String get allSettledUpYou => 'Estás en paz con todos';

  @override
  String youAreOwedList(String amounts) {
    return 'Te deben $amounts';
  }

  @override
  String youOweList(String amounts) {
    return 'Debes $amounts';
  }

  @override
  String get notOnEvensiesLower => 'aún no está en Evensies';

  @override
  String get noGroupsYet => 'Aún no hay grupos';

  @override
  String get noGroupsHelp =>
      'Crea uno para un viaje o un piso compartido, o únete al grupo de un amigo con su código de invitación.';

  @override
  String get createGroup => 'Crear grupo';

  @override
  String get settledUp => 'Saldado';

  @override
  String netApprox(String amount) {
    return 'Neto ≈ $amount';
  }

  @override
  String memberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count miembros',
      one: '1 miembro',
    );
    return '$_temp0';
  }

  @override
  String youOweAmount(String amount) {
    return 'Debes $amount';
  }

  @override
  String youAreOwedAmount(String amount) {
    return 'Te deben $amount';
  }

  @override
  String youOweAmountLine(String amount) {
    return 'debes $amount';
  }

  @override
  String youAreOwedAmountLine(String amount) {
    return 'te deben $amount';
  }

  @override
  String get createGroupNeedsConnection => 'Crear un grupo necesita conexión.';

  @override
  String get groupName => 'Nombre del grupo';

  @override
  String get yourNameInGroup => 'Tu nombre en este grupo';

  @override
  String get defaultCurrency => 'Moneda predeterminada';

  @override
  String get create => 'Crear';

  @override
  String get noGroupOrFriendForCode =>
      'No se encontró ningún grupo ni amigo con este código';

  @override
  String get joinNeedsConnection => 'Unirse a un grupo necesita conexión.';

  @override
  String get enterACode => 'Introduce un código';

  @override
  String get enterCodeHelp =>
      'El código de un grupo está en el grupo → Miembros. El de un amigo está en su pestaña Amigos → Añadir un amigo.';

  @override
  String get pastedFromClipboard => 'Pegado del portapapeles';

  @override
  String nameOnEvensies(String name) {
    return '$name · en Evensies';
  }

  @override
  String addAsFriend(String name) {
    return 'Añadir a $name como amigo';
  }

  @override
  String addedYouAsFriend(String name) {
    return '$name te añadió como amigo';
  }

  @override
  String get someoneAddedYouAsFriend => 'Alguien te añadió como amigo';

  @override
  String groupPreview(String name, String members) {
    return '$name · $members';
  }

  @override
  String get continueButton => 'Continuar';

  @override
  String wantsToSplit(String name) {
    return '$name quiere repartir gastos contigo';
  }

  @override
  String get joinGroup => 'Unirse al grupo';

  @override
  String get inviteInvalid => 'Este enlace de invitación ya no es válido';

  @override
  String inviteFailed(String reason) {
    return 'No se pudo abrir esta invitación: $reason';
  }

  @override
  String get friendInviteUsed => 'Esta invitación de amistad ya se usó';

  @override
  String get joinToSeeShared =>
      'Únete para ver y añadir vuestros gastos compartidos.';

  @override
  String imName(String name) {
    return 'Soy $name';
  }

  @override
  String get join => 'Unirse';

  @override
  String get whoAreYou => '¿Quién eres?';

  @override
  String get newMemberName => 'Nombre del nuevo miembro';

  @override
  String get insights => 'Estadísticas';

  @override
  String get membersInvite => 'Miembros e invitación';

  @override
  String get groupSettings => 'Ajustes del grupo';

  @override
  String get expenses => 'Gastos';

  @override
  String get expenseFab => 'Gasto';

  @override
  String get groupNotHere => 'Este grupo no está en este dispositivo';

  @override
  String get groupNotHereNote =>
      'Saliste de él, alguien te quitó, o aún no se ha sincronizado.';

  @override
  String get backToGroups => 'Volver a los grupos';

  @override
  String get noExpensesYet => 'Aún no hay gastos';

  @override
  String get tapExpenseToAdd => 'Toca “Gasto” para añadir el primero.';

  @override
  String tilePaidYou(String amount) {
    return 'pagaste $amount';
  }

  @override
  String tilePaidName(String name, String amount) {
    return '$name pagó $amount';
  }

  @override
  String tilePaidPeople(int count, String amount) {
    return '$count personas pagaron $amount';
  }

  @override
  String get tileRefundYou => 'reembolso para ti';

  @override
  String tileRefundName(String name) {
    return 'reembolso para $name';
  }

  @override
  String tileRefundPeople(int count) {
    return 'reembolso para $count personas';
  }

  @override
  String get notInvolved => 'no participas';

  @override
  String get allYours => 'todo tuyo';

  @override
  String get paidForYourself => 'pagaste lo tuyo';

  @override
  String youGetBack(String amount) {
    return 'recuperas $amount';
  }

  @override
  String youLent(String amount) {
    return 'prestaste $amount';
  }

  @override
  String youBorrowed(String amount) {
    return 'te prestaron $amount';
  }

  @override
  String get repeatsLabel => 'Se repite';

  @override
  String hasReceipt(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tiene $count recibos',
      one: 'Tiene un recibo',
    );
    return '$_temp0';
  }

  @override
  String get refund => 'Reembolso';

  @override
  String get notConverted => 'Sin convertir';

  @override
  String get pending => 'pendiente';

  @override
  String approxTotalOwe(String amount) {
    return 'Debes ≈ $amount en total';
  }

  @override
  String approxTotalOwed(String amount) {
    return 'Te deben ≈ $amount en total';
  }

  @override
  String get approxTotalNote =>
      'En tu moneda principal, a los tipos más recientes';

  @override
  String nothingOwedIn(String currency) {
    return 'Nada pendiente en $currency';
  }

  @override
  String get allSettled => 'Todo saldado';

  @override
  String get otherCurrenciesBelow => 'Los gastos en otras monedas están abajo.';

  @override
  String get nobodyOwes => 'Nadie debe nada.';

  @override
  String youPayNext(String amount) {
    return 'Deberías pagar tú la próxima vez (debes $amount, lo más alto)';
  }

  @override
  String namePaysNext(String name, String amount) {
    return '$name debería pagar la próxima vez (debe $amount, lo más alto)';
  }

  @override
  String settleUpWaiting(int count) {
    return 'Saldar · $count pendientes';
  }

  @override
  String memberRemoved(String name) {
    return '$name (quitado)';
  }

  @override
  String expensesWithoutRate(int count, String currency) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gastos sin tipo de cambio a $currency',
      one: '1 gasto sin tipo de cambio a $currency',
    );
    return '$_temp0';
  }

  @override
  String expensesBadRate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gastos con un tipo de cambio que no se puede convertir',
      one: '1 gasto con un tipo de cambio que no se puede convertir',
    );
    return '$_temp0';
  }

  @override
  String paymentsIn(String currency) {
    return 'Pagos en $currency';
  }

  @override
  String everyoneEvenIn(String currency) {
    return 'todos en paz en $currency';
  }

  @override
  String convertTo(String currency) {
    return 'Convertir a $currency';
  }

  @override
  String get balanceSettled => 'en paz';

  @override
  String get balanceGetsBack => 'recupera';

  @override
  String get balanceOwes => 'debe';

  @override
  String convertedCount(int count, String currency) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gastos convertidos a $currency',
      one: '1 gasto convertido a $currency',
    );
    return '$_temp0';
  }

  @override
  String get noAutoRate => 'No hay tipo automático. Introduce uno.';

  @override
  String rateOf(String date) {
    return 'tipo del $date';
  }

  @override
  String rateOfOffline(String date) {
    return 'sin conexión · tipo del $date';
  }

  @override
  String amountCountExpenses(String amount, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gastos',
      one: '1 gasto',
    );
    return '$amount · $_temp0';
  }

  @override
  String paymentsStayIn(String currency) {
    return 'Los pagos en $currency se quedan en $currency';
  }

  @override
  String rateLabel(String from, String to) {
    return 'Tipo: 1 $from en $to';
  }

  @override
  String get nothingLeftToConvert => 'No queda nada por convertir';

  @override
  String get lookingUpRate => 'Buscando el tipo…';

  @override
  String get enterRateAbove0 => 'Introduce un tipo mayor que 0';

  @override
  String convertExplain(String currency) {
    return 'Pone este tipo en cada gasto que no tenga uno, para que cuente en los saldos en $currency. Aún puedes cambiar el tipo de cada gasto.';
  }

  @override
  String get nameField => 'Nombre';

  @override
  String get cantChangeCurrency =>
      'No se puede cambiar tras el primer gasto o pago';

  @override
  String get currencyUsedFor => 'La usan los saldos y los pagos';

  @override
  String get splitting => 'Reparto';

  @override
  String get simplifyDebts => 'Simplificar deudas';

  @override
  String get simplifyDebtsHelp =>
      'Combina deudas para que el grupo necesite menos pagos. El total de nadie cambia, solo quién paga a quién.';

  @override
  String get defaultSplit => 'Reparto predeterminado';

  @override
  String get splitStale => 'Ya no cuadra · toca para corregir';

  @override
  String get membership => 'Membresía';

  @override
  String get leaveGroup => 'Salir del grupo';

  @override
  String get balanceSettledNote => 'Tu saldo está en paz';

  @override
  String get renameGroup => 'Cambiar nombre del grupo';

  @override
  String leaveTitle(String name) {
    return '¿Salir de “$name”?';
  }

  @override
  String get leaveMessage =>
      'Ya no verás este grupo. Tus gastos anteriores se quedan con los demás miembros. Para volver, pide el código de invitación.';

  @override
  String get leave => 'Salir';

  @override
  String youLeft(String name) {
    return 'Saliste de “$name”';
  }

  @override
  String get splitEqualEveryone => 'A partes iguales · todos';

  @override
  String splitPercentList(String list) {
    return 'Porcentaje · $list';
  }

  @override
  String splitSharesList(String list) {
    return 'Partes · $list';
  }

  @override
  String percentValue(String value) {
    return '$value %';
  }

  @override
  String get defaultSplitHelp =>
      'Los gastos nuevos empiezan con este reparto. Aún puedes cambiarlo en cada gasto.';

  @override
  String get useEqual => 'Usar partes iguales';

  @override
  String get inviteCode => 'Código de invitación';

  @override
  String get inviteQrLabel => 'Código QR del enlace de invitación';

  @override
  String get inviteCodeHelp =>
      'Cualquiera con este código puede unirse y elegir su nombre.';

  @override
  String inviteShareText(String group, String link, String code) {
    return 'Únete a mi grupo “$group” en Evensies: $link\nO abre la app e introduce el código $code';
  }

  @override
  String get rotateCode => 'Cambiar código';

  @override
  String get members => 'Miembros';

  @override
  String get notJoinedYet =>
      'aún no se ha unido — comparte el código de invitación';

  @override
  String get linked => 'vinculado';

  @override
  String get addPlaceholder => 'Añadir miembro provisional';

  @override
  String removeMemberTitle(String name) {
    return '¿Quitar a $name?';
  }

  @override
  String get removeMemberMessage =>
      'Sus gastos anteriores y su saldo se quedan en el grupo.';

  @override
  String removeMemberSeries(int count, String name, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$name sigue en $count gastos recurrentes ($names); la parte de $name se mantiene hasta que edites el último.',
      one:
          '$name sigue en 1 gasto recurrente ($names); la parte de $name se mantiene hasta que edites el último.',
    );
    return '$_temp0';
  }

  @override
  String get addMember => 'Añadir miembro';

  @override
  String get rotateInviteTitle => '¿Cambiar el código de invitación?';

  @override
  String get rotateInviteMessage =>
      'El código y el enlace actuales dejarán de funcionar. A quienes ya se unieron no les afecta.';

  @override
  String get rotate => 'Cambiar';

  @override
  String get newInviteReady => 'Nuevo código de invitación listo';

  @override
  String get activityNeedsConnection => 'La actividad necesita conexión';

  @override
  String get activityOfflineNote =>
      'Los cambios recientes aparecerán aquí cuando vuelvas a tener conexión.';

  @override
  String get noActivityYet => 'Aún no hay actividad';

  @override
  String get activityAllGroups => 'Aquí aparecen los cambios en tus grupos.';

  @override
  String get activityThisGroup => 'Aquí aparecen los cambios en este grupo.';

  @override
  String get showingSaved => 'Actividad guardada. Desliza para actualizar.';

  @override
  String get loadMore => 'Cargar más';

  @override
  String get earlier => 'Antes';

  @override
  String get today => 'Hoy';

  @override
  String get yesterday => 'Ayer';

  @override
  String forDate(String date) {
    return 'del $date';
  }

  @override
  String get youCommented => 'Comentaste';

  @override
  String nameCommented(String name) {
    return '$name comentó';
  }

  @override
  String restoredName(String name) {
    return '“$name” restaurado';
  }

  @override
  String get paymentRestored => 'Pago restaurado';

  @override
  String get expenseNotHere => 'Este gasto no está en este dispositivo';

  @override
  String get deletedExpense => 'Gasto eliminado';

  @override
  String get expense => 'Gasto';

  @override
  String seriesRepeats(String frequency) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Se repite cada semana',
      'biweekly': 'Se repite cada 2 semanas',
      'monthly': 'Se repite cada mes',
      'yearly': 'Se repite cada año',
      'other': 'Se repite',
    });
    return '$_temp0';
  }

  @override
  String seriesRepeatsNext(String frequency, String date) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Se repite cada semana · el próximo el $date',
      'biweekly': 'Se repite cada 2 semanas · el próximo el $date',
      'monthly': 'Se repite cada mes · el próximo el $date',
      'yearly': 'Se repite cada año · el próximo el $date',
      'other': 'Se repite · el próximo el $date',
    });
    return '$_temp0';
  }

  @override
  String seriesRepeatsNextAmount(String frequency, String amount, String date) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Se repite cada semana · el próximo de $amount el $date',
      'biweekly': 'Se repite cada 2 semanas · el próximo de $amount el $date',
      'monthly': 'Se repite cada mes · el próximo de $amount el $date',
      'yearly': 'Se repite cada año · el próximo de $amount el $date',
      'other': 'Se repite · el próximo de $amount el $date',
    });
    return '$_temp0';
  }

  @override
  String rateLine(String from, String rate, String to) {
    return 'Tipo: 1 $from = $rate $to';
  }

  @override
  String notConvertedTo(String currency) {
    return 'Sin convertir a $currency';
  }

  @override
  String get receivedSplitBack => 'Recibido y repartido de vuelta';

  @override
  String get whoPaidOwes => 'Quién pagó y quién debe';

  @override
  String get items => 'Artículos';

  @override
  String get notes => 'Notas';

  @override
  String get receipts => 'Recibos';

  @override
  String get history => 'Historial';

  @override
  String get deleteExpenseTitle => '¿Eliminar el gasto?';

  @override
  String get deleteExpenseMessage =>
      'Se elimina para todos en el grupo. Puedes restaurarlo desde Actividad.';

  @override
  String get deleteRepeatingTitle => '¿Eliminar el gasto recurrente?';

  @override
  String get deleteRepeatingMessage =>
      'Se elimina para todos en el grupo. Puedes restaurarlo desde Actividad, pero una serie detenida no se puede reanudar. Las repeticiones ya añadidas se quedan.';

  @override
  String get deleteThisOne => 'Eliminar solo este';

  @override
  String get deleteAndStop => 'Eliminar y dejar de repetir';

  @override
  String deletedAndStopped(String name) {
    return '“$name” eliminado y ya no se repite';
  }

  @override
  String deletedName(String name) {
    return '“$name” eliminado';
  }

  @override
  String get movedToOtherGroup => 'Movido a otro grupo';

  @override
  String get movedNote =>
      'Ahora cuenta allí. Sus comentarios e historial se quedan aquí.';

  @override
  String get expenseWasDeleted => 'Este gasto se eliminó';

  @override
  String get restoreToCount =>
      'Restáuralo para que vuelva a contar en los saldos.';

  @override
  String get tax => 'Impuestos';

  @override
  String get tipService => 'Propina o servicio';

  @override
  String get discount => 'Descuento';

  @override
  String youPaidOwe(String paid, String owe) {
    return 'Pagaste $paid y debes $owe';
  }

  @override
  String youPaid(String amount) {
    return 'Pagaste $amount';
  }

  @override
  String youOwe(String amount) {
    return 'Debes $amount';
  }

  @override
  String namePaidOwes(String name, String paid, String owe) {
    return '$name pagó $paid y debe $owe';
  }

  @override
  String namePaid(String name, String amount) {
    return '$name pagó $amount';
  }

  @override
  String nameOwes(String name, String amount) {
    return '$name debe $amount';
  }

  @override
  String youReceivedGetBack(String received, String back) {
    return 'Recibiste $received y recuperas $back';
  }

  @override
  String youReceived(String amount) {
    return 'Recibiste $amount';
  }

  @override
  String youGetBackLine(String amount) {
    return 'Recuperas $amount';
  }

  @override
  String nameReceivedGetsBack(String name, String received, String back) {
    return '$name recibió $received y recupera $back';
  }

  @override
  String nameReceived(String name, String amount) {
    return '$name recibió $amount';
  }

  @override
  String nameGetsBack(String name, String amount) {
    return '$name recupera $amount';
  }

  @override
  String get noHistoryYet => 'Aún no hay historial.';

  @override
  String get historyOffline =>
      'El historial aparecerá aquí cuando tengas conexión.';

  @override
  String get showingSavedHistory => 'Historial guardado.';

  @override
  String get showMore => 'Ver más';

  @override
  String get deleteCommentTitle => '¿Eliminar el comentario?';

  @override
  String get comments => 'Comentarios';

  @override
  String get noCommentsYet => 'Aún no hay comentarios.';

  @override
  String get deleteComment => 'Eliminar comentario';

  @override
  String get addComment => 'Añadir un comentario';

  @override
  String get send => 'Enviar';

  @override
  String get filterByCategory => 'Filtrar por categoría';

  @override
  String get category => 'Categoría';

  @override
  String get categoryAll => 'Todas';

  @override
  String get month => 'Mes';

  @override
  String get searchUnavailable => 'La búsqueda no está disponible';

  @override
  String get searchExpenses => 'Buscar gastos';

  @override
  String get searchHelp =>
      'Descripciones, notas, comentarios, categorías e importes: “taxi”, “aeropuerto”, “12,50”.';

  @override
  String get noMatches => 'Sin resultados';

  @override
  String get noMatchesHelp => 'Prueba con otra palabra o quita un filtro.';

  @override
  String expenseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gastos',
      one: '1 gasto',
    );
    return '$_temp0';
  }

  @override
  String get searchAllGroups => 'Buscar en todos los grupos';

  @override
  String searchGroup(String name) {
    return 'Buscar en $name';
  }

  @override
  String get searchThisGroup => 'Buscar en este grupo';

  @override
  String get clear => 'Borrar';

  @override
  String get thisGroup => 'Este grupo';

  @override
  String insightsError(String reason) {
    return 'No se pueden mostrar las estadísticas: $reason';
  }

  @override
  String get nothingToShow => 'Aún no hay nada que mostrar';

  @override
  String get insightsEmptyHelp =>
      'Los totales y gráficos aparecen cuando el grupo tiene gastos.';

  @override
  String get allTime => 'Todo el tiempo';

  @override
  String get shareSummary => 'Compartir resumen';

  @override
  String get printSummary => 'Imprimir resumen';

  @override
  String get previousMonth => 'Mes anterior';

  @override
  String get nextMonth => 'Mes siguiente';

  @override
  String get byMonth => 'Por mes';

  @override
  String get groupSegment => 'Grupo';

  @override
  String get mineSegment => 'Míos';

  @override
  String get byCategory => 'Por categoría';

  @override
  String get noExpensesPeriod => 'No hay gastos en este período.';

  @override
  String get byPerson => 'Por persona';

  @override
  String get nobodyPaidPeriod => 'Nadie pagó ni debió nada en este período.';

  @override
  String keptUntilConverted(String currency, String group) {
    return 'Se mantiene en $currency hasta que se convierta a $group.';
  }

  @override
  String get totalSpent => 'Total gastado';

  @override
  String get yourShare => 'Tu parte';

  @override
  String get paymentsMade => 'Pagos hechos';

  @override
  String get paymentsReceived => 'Pagos recibidos';

  @override
  String get youPaidRow => 'Pagaste';

  @override
  String get balanceChange => 'Cambio en tu saldo';

  @override
  String get paidLegend => 'Pagado';

  @override
  String get shareLegend => 'Parte';

  @override
  String paidShareLine(String paid, String share) {
    return 'pagó $paid · parte $share';
  }

  @override
  String get itemsGiveEveryone => 'Asigna una persona a cada artículo';

  @override
  String get itemsAddPrices => 'Añade los precios antes de impuestos o propina';

  @override
  String get itemsDiscountTooBig => 'El descuento es mayor que la cuenta';

  @override
  String get itemsDontAddUp => 'Los artículos no cuadran';

  @override
  String get adjustmentsDontFit => 'Los ajustes no caben en el total';

  @override
  String get giveSomeoneShare => 'Dale una parte a alguien';

  @override
  String get checkNumbers => 'Revisa los números';

  @override
  String get splitDoesntAddUp => 'El reparto no cuadra';

  @override
  String get addTheItems => 'Añade los artículos';

  @override
  String get pickOnePerson => 'Elige al menos una persona';

  @override
  String splitEquallyBetween(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'A partes iguales entre $count personas',
      one: 'A partes iguales entre 1 persona',
    );
    return '$_temp0';
  }

  @override
  String get allForOnePerson => 'Todo para 1 persona';

  @override
  String splitEquallyEach(int count, String amount) {
    return 'A partes iguales entre $count personas · $amount cada una';
  }

  @override
  String get checkAmounts => 'Revisa los importes';

  @override
  String get enterTotalFirst => 'Introduce primero el total';

  @override
  String remaining(String amount) {
    return 'falta: $amount';
  }

  @override
  String overBy(String amount) {
    return 'sobra: $amount';
  }

  @override
  String get addsUp => 'Cuadra';

  @override
  String sharesInTotal(String count) {
    return '$count partes en total';
  }

  @override
  String get oneShareInTotal => '1 parte en total';

  @override
  String get restSplitEqually => 'El resto se reparte a partes iguales';

  @override
  String get byPercent => 'Por porcentaje';

  @override
  String get byShares => 'Por partes';

  @override
  String get byAdjustment =>
      'Ajustar: más o menos para alguien, el resto a partes iguales';

  @override
  String get modeEqual => 'Igual';

  @override
  String get modeExact => 'Exacto';

  @override
  String get modeShares => 'Partes';

  @override
  String get byItem => 'Por artículo, desde un recibo';

  @override
  String get adjustmentHelp =>
      'Suma o resta un importe a alguien; el resto se reparte a partes iguales.';

  @override
  String get noMembers => 'Sin miembros';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count artículos',
      one: '1 artículo',
    );
    return '$_temp0';
  }

  @override
  String get addAnItem => 'Añade un artículo';

  @override
  String atMostItems(int max) {
    return 'Como máximo $max artículos';
  }

  @override
  String get giveItemName => 'Ponle nombre a cada artículo';

  @override
  String get itemNameTooLong => 'Un nombre de artículo es demasiado largo';

  @override
  String get addItem => 'Añadir artículo';

  @override
  String get giveRestToEveryone => 'Dar el resto a todos';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get total => 'Total';

  @override
  String receiptSays(String printed, String difference) {
    return 'El recibo dice $printed · los artículos difieren en $difference';
  }

  @override
  String get eachPerson => 'Por persona';

  @override
  String itemsWithoutPerson(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count artículos sin persona',
      one: '1 artículo sin persona',
    );
    return '$_temp0';
  }

  @override
  String get itemHint => 'Artículo';

  @override
  String memberLeft(String name) {
    return '$name (salió)';
  }

  @override
  String get whoHadThis => '¿Quién lo tomó?';

  @override
  String get defaultSplitStartsEqual =>
      'El reparto predeterminado del grupo ya no cuadra, así que este empieza a partes iguales';

  @override
  String leftToAssign(String amount) {
    return 'Faltan $amount por asignar';
  }

  @override
  String get itemsTotal => 'El total de los artículos';

  @override
  String get newExpense => 'Nuevo gasto';

  @override
  String get editExpense => 'Editar gasto';

  @override
  String get scanReceipt => 'Escanear recibo';

  @override
  String get rateAboveZeroOrEmpty =>
      'Introduce un tipo mayor que 0, o déjalo vacío';

  @override
  String useAutoRate(String rate, String source) {
    return 'Usar tipo automático: $rate ($source)';
  }

  @override
  String get description => 'Descripción';

  @override
  String get receivedBy => 'Recibido por';

  @override
  String get paidBy => 'Pagado por';

  @override
  String get severalPeople => 'Varias personas';

  @override
  String get when => 'Cuándo';

  @override
  String get refundTooltip =>
      'Dinero que volvió, p. ej. el hotel devolvió la fianza';

  @override
  String get splitBackTo => 'Repartido de vuelta a';

  @override
  String get split => 'Reparto';

  @override
  String theyOweFull(String name) {
    return '$name debe el importe completo';
  }

  @override
  String iOweFull(String name) {
    return 'Le debo a $name el importe completo';
  }

  @override
  String get repeat => 'Repetir';

  @override
  String editLatestRepeat(String date) {
    return 'Para cambiar las próximas repeticiones, edita la última ($date)';
  }

  @override
  String get stopsRepeating =>
      'Deja de repetirse. Las repeticiones ya añadidas se quedan.';

  @override
  String nextRepeat(String date) {
    return 'Próximo: $date';
  }

  @override
  String get alsoChangeFuture => 'Cambiar también las próximas repeticiones';

  @override
  String get futureFields =>
      'Importe, reparto, pagadores, descripción, categoría y notas';

  @override
  String get onlyThisOne => 'Solo cambia este';

  @override
  String get addPhoto => 'Añadir foto';

  @override
  String maxReceiptsNote(int max) {
    return '$max recibos es el máximo para un gasto';
  }

  @override
  String get scanAReceipt => 'Escanear un recibo';

  @override
  String receiptLooksLike(String currency) {
    return 'Este recibo parece estar en $currency';
  }

  @override
  String switchToCurrencyQuestion(String currency) {
    return '¿Cambiar el gasto a $currency para leer sus artículos?';
  }

  @override
  String switchTo(String currency) {
    return 'Cambiar a $currency';
  }

  @override
  String get couldntReadItems =>
      'No se pudieron leer los artículos. Escríbelos.';

  @override
  String withName(String name) {
    return 'Con $name';
  }

  @override
  String movesTo(String name) {
    return 'Se moverá a $name al guardar';
  }

  @override
  String fromName(String name) {
    return 'Desde $name';
  }

  @override
  String get dontMove => 'No mover';

  @override
  String get onlyLinkedMove =>
      'Solo se pueden mover personas de Evensies que estén en ambos';

  @override
  String get auto => 'auto';

  @override
  String get noAutoRateForm =>
      'No hay tipo automático. Introduce uno, o déjalo vacío para mantenerlo en “Sin convertir”.';

  @override
  String get emptyNotConverted => 'Vacío: se queda en “Sin convertir”';

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
  String get yourRate => 'tu tipo';
}
