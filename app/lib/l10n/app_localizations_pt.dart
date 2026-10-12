// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Evensies';

  @override
  String get cancel => 'Cancelar';

  @override
  String get delete => 'Excluir';

  @override
  String get remove => 'Remover';

  @override
  String get save => 'Salvar';

  @override
  String get done => 'Concluir';

  @override
  String get undo => 'Desfazer';

  @override
  String get retry => 'Tentar de novo';

  @override
  String get ok => 'OK';

  @override
  String get close => 'Fechar';

  @override
  String get edit => 'Editar';

  @override
  String get add => 'Adicionar';

  @override
  String get offlineBanner =>
      'Offline — as mudanças serão sincronizadas depois';

  @override
  String get tooLong => 'Longo demais';

  @override
  String get allCurrencies => 'Todas as moedas';

  @override
  String get errorUnexpected => 'Algo deu errado. Tente de novo.';

  @override
  String get errorNetwork => 'Você está offline. Tente mais tarde.';

  @override
  String get errorRateLimited =>
      'Tentativas demais. Espere um minuto e tente de novo.';

  @override
  String get errorNotFound => 'Isso não existe mais.';

  @override
  String get errorForbidden => 'Você não pode fazer isso.';

  @override
  String get errorValidation => 'O servidor recusou.';

  @override
  String get errorSumMismatch => 'A divisão não fecha.';

  @override
  String get errorPayersSumMismatch => 'Os pagantes não fecham.';

  @override
  String get errorNegativeAmount => 'Um valor está abaixo de zero.';

  @override
  String get errorNegativeShare => 'A parte de alguém ficaria abaixo de zero.';

  @override
  String get errorNegativeTotal => 'O total ficaria abaixo de zero.';

  @override
  String get errorZeroSubtotal =>
      'Informe os preços dos itens antes de impostos, gorjeta ou desconto.';

  @override
  String get errorUnassignedItem =>
      'Cada item precisa de pelo menos uma pessoa.';

  @override
  String get errorNoMembers => 'Escolha pelo menos uma pessoa para dividir.';

  @override
  String get errorInvalidInput => 'Confira os números.';

  @override
  String get errorBadRate => 'A taxa de câmbio precisa ser maior que zero.';

  @override
  String get errorUnknownMember => 'Envolve alguém que não está no grupo.';

  @override
  String get errorUnknownCurrency => 'A moeda não é suportada.';

  @override
  String get errorMemberTaken => 'Esse membro já foi escolhido.';

  @override
  String get errorLimitExceeded => 'O limite foi atingido.';

  @override
  String get errorTooLarge => 'A foto é grande demais.';

  @override
  String get errorNotJpeg => 'Escolha uma foto JPEG';

  @override
  String get errorFxUnavailable =>
      'As taxas de câmbio não estão disponíveis agora.';

  @override
  String get errorImportFailed => 'Não foi possível importar esse arquivo.';

  @override
  String get errorAuthNotConfigured =>
      'Este servidor não consegue fazer seu login desse jeito.';

  @override
  String get errorDuplicate => 'Isso já existe.';

  @override
  String errorGeneric(String code) {
    return 'Algo deu errado ($code).';
  }

  @override
  String rejectedReceipt(String name, String reason) {
    return 'Não foi possível salvar o recibo de “$name”: $reason';
  }

  @override
  String rejectedReceiptUnnamed(String reason) {
    return 'Não foi possível salvar o recibo de uma despesa: $reason';
  }

  @override
  String rejectedReceiptRemove(String name, String reason) {
    return 'Não foi possível salvar a remoção de um recibo de “$name”: $reason';
  }

  @override
  String rejectedReceiptRemoveUnnamed(String reason) {
    return 'Não foi possível salvar a remoção de um recibo de uma despesa: $reason';
  }

  @override
  String rejectedRepeating(String name, String reason) {
    return 'Não foi possível salvar a repetição de “$name”: $reason';
  }

  @override
  String rejectedRepeatingUnnamed(String reason) {
    return 'Não foi possível salvar uma despesa recorrente: $reason';
  }

  @override
  String rejectedSeriesChange(String name, String reason) {
    return 'Não foi possível salvar uma mudança nas próximas “$name”: $reason';
  }

  @override
  String rejectedSeriesChangeUnnamed(String reason) {
    return 'Não foi possível salvar uma mudança em uma despesa recorrente: $reason';
  }

  @override
  String rejectedSeriesStop(String name, String reason) {
    return 'Não foi possível salvar o fim da repetição de “$name”: $reason';
  }

  @override
  String rejectedSeriesStopUnnamed(String reason) {
    return 'Não foi possível salvar o fim de uma despesa recorrente: $reason';
  }

  @override
  String rejectedSavedNoRepeat(String name, String reason) {
    return '“$name” foi salva, mas não vai se repetir: $reason';
  }

  @override
  String rejectedPaymentRestore(String reason) {
    return 'Não foi possível salvar a restauração de um pagamento: $reason';
  }

  @override
  String rejectedNewExpense(String name, String reason) {
    return 'Não foi possível salvar a nova despesa “$name”: $reason';
  }

  @override
  String rejectedNewExpenseUnnamed(String reason) {
    return 'Não foi possível salvar uma nova despesa: $reason';
  }

  @override
  String rejectedExpenseChange(String name, String reason) {
    return 'Não foi possível salvar uma mudança em “$name”: $reason';
  }

  @override
  String rejectedExpenseChangeUnnamed(String reason) {
    return 'Não foi possível salvar uma mudança em uma despesa: $reason';
  }

  @override
  String rejectedExpenseDelete(String name, String reason) {
    return 'Não foi possível salvar a exclusão de “$name”: $reason';
  }

  @override
  String rejectedExpenseDeleteUnnamed(String reason) {
    return 'Não foi possível salvar a exclusão de uma despesa: $reason';
  }

  @override
  String rejectedExpenseRestore(String name, String reason) {
    return 'Não foi possível salvar a restauração de “$name”: $reason';
  }

  @override
  String rejectedExpenseRestoreUnnamed(String reason) {
    return 'Não foi possível salvar a restauração de uma despesa: $reason';
  }

  @override
  String rejectedComment(String name, String reason) {
    return 'Não foi possível salvar um comentário em “$name”: $reason';
  }

  @override
  String rejectedCommentUnnamed(String reason) {
    return 'Não foi possível salvar um comentário em uma despesa: $reason';
  }

  @override
  String rejectedPaymentComment(String reason) {
    return 'Não foi possível salvar um comentário em um pagamento: $reason';
  }

  @override
  String rejectedCommentDelete(String reason) {
    return 'Não foi possível salvar a exclusão de um comentário: $reason';
  }

  @override
  String rejectedPayment(String reason) {
    return 'Não foi possível salvar um pagamento: $reason';
  }

  @override
  String rejectedPaymentDelete(String reason) {
    return 'Não foi possível salvar a exclusão de um pagamento: $reason';
  }

  @override
  String rejectedPaymentConfirm(String reason) {
    return 'Não foi possível salvar a confirmação de um pagamento: $reason';
  }

  @override
  String rejectedGroupSettings(String reason) {
    return 'Não foi possível salvar uma mudança nas configurações do grupo: $reason';
  }

  @override
  String rejectedMemberAdd(String name, String reason) {
    return 'Não foi possível salvar a inclusão de $name: $reason';
  }

  @override
  String rejectedMemberAddUnnamed(String reason) {
    return 'Não foi possível salvar a inclusão de um membro: $reason';
  }

  @override
  String rejectedMemberRemove(String reason) {
    return 'Não foi possível salvar a remoção de um membro: $reason';
  }

  @override
  String rejectedOther(String reason) {
    return 'Não foi possível salvar uma mudança: $reason';
  }

  @override
  String get reasonReceiptLimit => 'uma despesa pode ter no máximo 10 recibos';

  @override
  String get reasonSeriesLimit =>
      'um grupo pode ter no máximo 100 despesas recorrentes';

  @override
  String get reasonNotUploaded => 'a foto não foi enviada';

  @override
  String get reasonSumMismatch => 'a divisão não fecha';

  @override
  String get reasonPayersSumMismatch => 'os pagantes não fecham';

  @override
  String get reasonNegativeAmount => 'um valor está abaixo de zero';

  @override
  String get reasonUnknownMember => 'envolve alguém que não está no grupo';

  @override
  String get reasonUnknownCurrency => 'a moeda não é suportada';

  @override
  String get reasonMemberTaken => 'esse membro já foi escolhido';

  @override
  String get reasonGroupFull => 'o grupo está cheio';

  @override
  String get reasonForbidden => 'você não pode fazer essa mudança';

  @override
  String get reasonRefused => 'o servidor recusou';

  @override
  String leaveOwe(String amount) {
    return 'Você deve $amount · acerte antes';
  }

  @override
  String leaveOweIn(String amount, String currency) {
    return 'Você deve $amount · acerte antes em $currency';
  }

  @override
  String leaveOwed(String amount) {
    return 'Te devem $amount · acerte antes';
  }

  @override
  String leaveOwedIn(String amount, String currency) {
    return 'Te devem $amount · acerte antes em $currency';
  }

  @override
  String leaveSeries(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Você ainda está em $count despesas recorrentes ($names) · edite a mais recente ou pare-as antes',
      one:
          'Você ainda está em 1 despesa recorrente ($names) · edite a mais recente ou pare-a antes',
    );
    return '$_temp0';
  }

  @override
  String seriesNamesMore(String names, int count) {
    return '$names e mais $count';
  }

  @override
  String get seriesUnnamed => 'uma despesa';

  @override
  String get listJoiner => ', ';

  @override
  String get repeatNever => 'Nunca';

  @override
  String get repeatWeekly => 'Toda semana';

  @override
  String get repeatBiweekly => 'A cada 2 semanas';

  @override
  String get repeatMonthly => 'Todo mês';

  @override
  String get repeatYearly => 'Todo ano';

  @override
  String summaryNotConverted(String currency) {
    return 'Não convertido · $currency';
  }

  @override
  String summaryTotalSpent(String amount) {
    return 'Total gasto: $amount';
  }

  @override
  String summaryPaidShare(String paid, String share) {
    return 'Você pagou: $paid · Sua parte: $share';
  }

  @override
  String summaryPayments(String made, String received) {
    return 'Pagamentos feitos: $made · recebidos: $received';
  }

  @override
  String summaryTopCategories(String list) {
    return 'Principais categorias: $list';
  }

  @override
  String get summaryBalancesToday => 'Saldos de hoje';

  @override
  String summaryGetsBack(String name, String amount) {
    return '$name recebe $amount';
  }

  @override
  String summaryOwes(String name, String amount) {
    return '$name deve $amount';
  }

  @override
  String get summaryFooter => 'Compartilhado pelo Evensies';

  @override
  String get koreanBank => 'Conta bancária coreana';

  @override
  String requestText(String amount, String group) {
    return 'Você me deve $amount por $group no Evensies.';
  }

  @override
  String requestTextWays(String amount, String group, String ways) {
    return 'Você me deve $amount por $group no Evensies. Pague com: $ways';
  }

  @override
  String get requestNoGroup => 'nossas despesas em comum';

  @override
  String get leaveSyncing => 'Ainda sincronizando. Tente de novo em instantes.';

  @override
  String get leaveOffline => 'Você precisa estar online para sair';

  @override
  String get moveOffline =>
      'Não foi possível mover. Tente quando estiver online';

  @override
  String moveFailed(String reason) {
    return 'Não foi possível mover: $reason';
  }

  @override
  String get photoNoAccess =>
      'O Evensies não tem acesso. Permita no app Ajustes.';

  @override
  String get photoNoCamera => 'Não foi possível abrir a câmera.';

  @override
  String get photoNoLibrary => 'Não foi possível abrir a fototeca.';

  @override
  String get photoUnusable => 'Essa foto não pôde ser usada. Tente outra.';

  @override
  String get methodErrorUsername => 'Só letras, números, . _ - (máx. 40)';

  @override
  String methodErrorLinkPrefix(String prefix) {
    return 'Precisa começar com $prefix';
  }

  @override
  String get methodErrorTooLong => 'Máx. 200 caracteres';

  @override
  String get methodErrorIban => 'IBAN inválido';

  @override
  String get methodErrorHolder => 'Nome do titular (1–70 caracteres)';

  @override
  String get methodErrorBic => 'O BIC tem 8 ou 11 caracteres';

  @override
  String get methodErrorKrAccount => 'Números e hífens, 8–20 dígitos';

  @override
  String get methodErrorBank => 'Nome do banco (1–30 caracteres)';

  @override
  String get methodErrorUnknownType => 'Tipo desconhecido';

  @override
  String get methodErrorTooMany =>
      'No máximo 8 formas de receber, e 3 de cada tipo bancário';

  @override
  String get bannerDismiss => 'Dispensar';

  @override
  String get bannerView => 'Ver';

  @override
  String get loginTagline =>
      'Divida despesas com amigos. Sem anúncios, sem empurrar planos.';

  @override
  String get loginApple => 'Continuar com a Apple';

  @override
  String get loginGoogle => 'Continuar com o Google';

  @override
  String get loginWebUnavailable =>
      'Este servidor ainda não tem login pelo navegador.';

  @override
  String get welcomeTitle => 'Boas-vindas';

  @override
  String get yourNameTitle => 'Seu nome';

  @override
  String get nameQuestion => 'Como seus amigos devem te chamar?';

  @override
  String get nameExplain => 'Este é o nome que os outros membros veem.';

  @override
  String get nameHelp =>
      'Ele aparece para as pessoas dos seus grupos. Você pode mudá-lo depois nos Ajustes.';

  @override
  String get nameLabel => 'Nome';

  @override
  String get lockReason => 'Desbloquear o Evensies';

  @override
  String get lockTitle => 'O Evensies está bloqueado';

  @override
  String get lockSubtitle =>
      'Desbloqueie com Face ID, Touch ID, sua digital ou o código do aparelho.';

  @override
  String get lockUnlock => 'Desbloquear';

  @override
  String get lockSignOutConfirm =>
      'Sair e apagar os dados deste aparelho? Seus grupos continuam no servidor.';

  @override
  String get signOut => 'Sair';

  @override
  String get widgetOwed => 'Te devem';

  @override
  String get widgetOwe => 'Você deve';

  @override
  String get widgetSignedOut => 'Entre para ver seu saldo';

  @override
  String get widgetSettled => 'Tudo acertado';

  @override
  String widgetUpdated(String time) {
    return 'Atualizado $time';
  }

  @override
  String get receiptAdd => 'Adicionar um recibo';

  @override
  String get photoTake => 'Tirar foto';

  @override
  String get photoChoose => 'Escolher da fototeca';

  @override
  String get photoChooseFile => 'Escolher um arquivo';

  @override
  String get availableWhenOnline => 'Disponível quando online';

  @override
  String get receiptPhoto => 'Foto do recibo';

  @override
  String get receiptAvailableOnline => 'A foto está disponível quando online';

  @override
  String get receiptRemoveTitle => 'Remover o recibo?';

  @override
  String get receiptRemoveMessage => 'Ele é removido para todos do grupo.';

  @override
  String get receiptTitle => 'Recibo';

  @override
  String receiptTitleOf(int index, int count) {
    return 'Recibo $index de $count';
  }

  @override
  String get shareOrSave => 'Compartilhar ou salvar';

  @override
  String get share => 'Compartilhar';

  @override
  String get copiedToClipboard => 'Copiado para a área de transferência';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get photoRemove => 'Remover foto';

  @override
  String get photoNeedsConnection => 'Mudar sua foto precisa de conexão.';

  @override
  String get photoTooMany =>
      'Mudanças de foto demais. Tente de novo em uma hora.';

  @override
  String get notifSaveFailed =>
      'Não foi possível salvar os ajustes de notificação. Confira sua conexão.';

  @override
  String get homeCurrencyNeedsConnection =>
      'Mudar sua moeda principal precisa de conexão.';

  @override
  String get changePhoto => 'Mudar foto de perfil';

  @override
  String get yourNameTapToChange => 'Seu nome · toque para mudar';

  @override
  String get waysToGetPaid => 'Formas de receber';

  @override
  String get waysToGetPaidHint => 'PayPal, Wise, IBAN, conta bancária…';

  @override
  String get homeCurrency => 'Moeda principal';

  @override
  String get homeCurrencyFromRegion =>
      'Da sua região · os saldos também mostram ≈ nela';

  @override
  String get homeCurrencyPicked => 'Os saldos também mostram ≈ nela';

  @override
  String get notifications => 'Notificações';

  @override
  String get notifExpenses => 'Despesas e pagamentos';

  @override
  String get notifComments => 'Comentários';

  @override
  String get notifMembers => 'Membros e mudanças no grupo';

  @override
  String get notifReminders => 'Lembretes de amigos';

  @override
  String get notifNeedConnection =>
      'Os ajustes de notificação precisam de conexão';

  @override
  String get notifOthersOnly =>
      'Só as mudanças feitas por outras pessoas geram notificação.';

  @override
  String get notifWebNote =>
      'As notificações vão para o seu celular; o navegador se atualiza a cada minuto enquanto está aberto.';

  @override
  String get exportImport => 'Exportar e importar';

  @override
  String get noGroupsToExport => 'Nenhum grupo para exportar.';

  @override
  String get nonGroup => 'Fora de grupo';

  @override
  String nonGroupWith(String name) {
    return 'Fora de grupo · $name';
  }

  @override
  String get exportJson => 'Exportar JSON';

  @override
  String get exportCsv => 'Exportar CSV';

  @override
  String get exportZip => 'ZIP com recibos';

  @override
  String get importSplitwise => 'Importar CSV do Splitwise';

  @override
  String importedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count despesas importadas',
      one: '1 despesa importada',
    );
    return '$_temp0';
  }

  @override
  String get server => 'Servidor';

  @override
  String get serverUrl => 'URL do servidor';

  @override
  String serverDefault(String url) {
    return 'Padrão: $url';
  }

  @override
  String get serverSaved => 'URL do servidor salva';

  @override
  String get account => 'Conta';

  @override
  String get licenses => 'Licenças';

  @override
  String get deleteAccount => 'Excluir conta';

  @override
  String get signOutTitle => 'Sair?';

  @override
  String get signOutMessage =>
      'Os dados locais deste aparelho são apagados. Mudanças ainda não sincronizadas serão perdidas.';

  @override
  String get deleteAccountTitle => 'Excluir a conta?';

  @override
  String get deleteAccountMessage =>
      'Suas participações viram marcadores. Os dados dos grupos ficam com os outros membros. Não dá para desfazer.';

  @override
  String get language => 'Idioma';

  @override
  String languageSystem(String language) {
    return 'Sistema ($language)';
  }

  @override
  String get appearance => 'Aparência';

  @override
  String get appearanceSystem => 'Sistema';

  @override
  String get appearanceLight => 'Claro';

  @override
  String get appearanceDark => 'Escuro';

  @override
  String get security => 'Segurança';

  @override
  String get appLock => 'Bloqueio do app';

  @override
  String get appLockHint =>
      'Face ID, Touch ID ou digital, com o código do aparelho como alternativa. Bloqueia depois de um minuto fora.';

  @override
  String methodRemoveTitle(String method) {
    return 'Remover $method?';
  }

  @override
  String get methodsOffline =>
      'Conecte-se à internet para editar suas formas de receber.';

  @override
  String get methodsLoadFailed =>
      'Não foi possível carregar suas formas de receber.';

  @override
  String get methodsIntro =>
      'Os membros do grupo veem isso quando te devem dinheiro, para te pagar com um toque. O Evensies nunca movimenta dinheiro.';

  @override
  String get methodsEmpty => 'Nenhuma forma de receber ainda.';

  @override
  String get blurbPaypal => 'Link do PayPal.me, valor preenchido';

  @override
  String get blurbWise => 'Link do Wise Quick Pay, valor preenchido';

  @override
  String get blurbVenmo => 'Usuário do Venmo (EUA)';

  @override
  String get blurbRevolut => 'Usuário do Revolut.me';

  @override
  String get blurbKakaopay => 'Link 송금코드 do KakaoPay';

  @override
  String get blurbIban => 'Transferência bancária (QR SEPA para EUR)';

  @override
  String get blurbKrBank => 'Conta bancária coreana (Toss, apps de banco)';

  @override
  String get fieldPaypal => 'Usuário do PayPal.me';

  @override
  String get fieldPaypalHint => 'Seu usuário do PayPal.me, ex.: anna';

  @override
  String get fieldRevolut => 'Usuário do Revolut.me';

  @override
  String get fieldRevolutHint => 'Seu usuário do Revolut.me, ex.: anna';

  @override
  String get fieldVenmo => 'Usuário do Venmo';

  @override
  String get fieldVenmoHint => 'Sem o @, ex.: anna-rossi';

  @override
  String get fieldWise => 'Link do Wise Quick Pay';

  @override
  String get fieldWiseHint =>
      'No Wise: Pagamentos → Quick Pay → copiar link (https://wise.com/pay/…)';

  @override
  String get fieldKakaopay => 'Link 송금코드 do KakaoPay';

  @override
  String get fieldKakaopayHint =>
      'No KakaoPay: 송금 → 송금코드 → copiar link (https://qr.kakaopay.com/…)';

  @override
  String get fieldHolder => 'Titular da conta';

  @override
  String get fieldHolderHint => 'O nome exatamente como na conta';

  @override
  String get fieldIban => 'IBAN';

  @override
  String get fieldIbanHint => 'ex.: PT50 0002 0123 1234 5678 9015 4';

  @override
  String get fieldBic => 'BIC (opcional)';

  @override
  String get fieldBicHint => '8 ou 11 caracteres';

  @override
  String get fieldBank => 'Banco';

  @override
  String get fieldBankHint => 'ex.: 신한은행, Toss Bank';

  @override
  String get fieldAccountNumber => 'Número da conta';

  @override
  String get fieldAccountNumberHint => 'Números, hífens opcionais';

  @override
  String amountCopied(String amount) {
    return 'Valor copiado: $amount';
  }

  @override
  String couldNotOpen(String link) {
    return 'Não foi possível abrir $link';
  }

  @override
  String get payOffline => 'Offline: as formas de pagar não estão disponíveis';

  @override
  String get payLoading => 'Carregando formas de pagar…';

  @override
  String payAskToAdd(String name) {
    return 'Peça para $name adicionar uma forma de receber';
  }

  @override
  String payTitle(String name, String amount) {
    return 'Pagar $amount para $name';
  }

  @override
  String get payScanQr => 'Escaneie com o app do seu banco (QR SEPA)';

  @override
  String get payQrEurOnly =>
      'O QR code só está disponível para transferências em EUR.';

  @override
  String get bankLabel => 'Banco';

  @override
  String get ibanLabel => 'IBAN';

  @override
  String get accountLabel => 'Conta';

  @override
  String get bicLabel => 'BIC';

  @override
  String get holderLabel => 'Titular';

  @override
  String get amountLabel => 'Valor';

  @override
  String get copyIban => 'Copiar IBAN';

  @override
  String get copyAccount => 'Copiar conta';

  @override
  String get copyAmount => 'Copiar valor';

  @override
  String get ibanCopied => 'IBAN copiado';

  @override
  String get accountCopied => 'Conta copiada';

  @override
  String get paymentUpdated => 'Pagamento atualizado';

  @override
  String paymentRecordedPending(String amount, String name) {
    return '$amount registrado. $name vai confirmar.';
  }

  @override
  String paymentRecordedPendingUnnamed(String amount) {
    return '$amount registrado. A outra pessoa vai confirmar.';
  }

  @override
  String paymentRecorded(String amount) {
    return 'Pagamento de $amount registrado';
  }

  @override
  String youSuffix(String name) {
    return '$name (você)';
  }

  @override
  String get recordPayment => 'Registrar um pagamento';

  @override
  String get editPayment => 'Editar pagamento';

  @override
  String get fromLabel => 'De';

  @override
  String get toLabel => 'Para';

  @override
  String get swap => 'Inverter';

  @override
  String get pickTwoPeople => 'Escolha duas pessoas diferentes';

  @override
  String get commentsStayOld => 'Os comentários ficam no pagamento antigo';

  @override
  String get recordPaymentButton => 'Registrar pagamento';

  @override
  String get paymentNotHere => 'Este pagamento não está neste aparelho';

  @override
  String get notSyncedOrLeft =>
      'Ainda não foi sincronizado, ou você saiu do grupo dele.';

  @override
  String get someone => 'Alguém';

  @override
  String get paymentEdited => 'Pagamento editado';

  @override
  String get paymentDeleted => 'Pagamento excluído';

  @override
  String get payment => 'Pagamento';

  @override
  String get paymentWasEdited => 'Este pagamento foi editado';

  @override
  String get paymentWasEditedNote =>
      'No lugar dele, conta o pagamento editado. Os comentários ficam aqui.';

  @override
  String get paymentWasDeleted => 'Este pagamento foi excluído';

  @override
  String get paymentNotCounted => 'Ele não conta nos saldos.';

  @override
  String get restore => 'Restaurar';

  @override
  String youPaidName(String name) {
    return 'Você pagou $name';
  }

  @override
  String namePaidYou(String name) {
    return '$name te pagou';
  }

  @override
  String namePaidName(String from, String to) {
    return '$from pagou $to';
  }

  @override
  String paymentSaysSent(String name) {
    return '$name diz que te enviou. Chegou?';
  }

  @override
  String waitingForConfirm(String name) {
    return 'Aguardando confirmação de $name';
  }

  @override
  String get notReceived => 'Não recebido';

  @override
  String get confirmReceived => 'Confirmar recebimento';

  @override
  String get deletePaymentTitle => 'Excluir o pagamento?';

  @override
  String get deletePaymentMessage => 'A dívida que ele acertava volta.';

  @override
  String get paymentDeletedSnack => 'Pagamento excluído';

  @override
  String get notReceivedTitle => 'Não recebeu?';

  @override
  String notReceivedMessage(String name) {
    return 'O pagamento de $name é removido e a dívida volta.';
  }

  @override
  String get paymentRemovedSnack => 'Pagamento removido';

  @override
  String get recordAPayment => 'Registrar um pagamento';

  @override
  String get nothingToSettle => 'Nada para acertar';

  @override
  String get everyoneEven => 'Todo mundo está quite.';

  @override
  String get waitingForConfirmation => 'Aguardando confirmação';

  @override
  String get debtsAsRecorded =>
      'Dívidas como registradas · simplificar dívidas está desativado';

  @override
  String transfersSettleEverything(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transferências acertam tudo',
      one: '1 transferência acerta tudo',
    );
    return '$_temp0';
  }

  @override
  String transfersSettleBalance(int count, String currency) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transferências acertam o saldo em $currency',
      one: '1 transferência acerta o saldo em $currency',
    );
    return '$_temp0';
  }

  @override
  String notConvertedSettlesIn(String currency) {
    return 'Não convertido · $currency · acerta em $currency';
  }

  @override
  String get convert => 'Converter';

  @override
  String get settleUp => 'Acertar';

  @override
  String saysTheySent(String name, String amount) {
    return '$name diz que te enviou $amount';
  }

  @override
  String waitingToConfirmAmount(String name, String amount) {
    return 'Aguardando $name confirmar $amount';
  }

  @override
  String get you => 'Você';

  @override
  String get request => 'Cobrar';

  @override
  String get iveSentIt => 'Já enviei';

  @override
  String get markAsPaid => 'Marcar como pago';

  @override
  String markedAsSent(String name) {
    return 'Marcado como enviado. $name vai confirmar.';
  }

  @override
  String approx(String amount) {
    return '≈ $amount';
  }

  @override
  String friendOwesYou(String name, String amount) {
    return '$name te deve $amount';
  }

  @override
  String friendYouOwe(String name, String amount) {
    return 'Você deve $amount para $name';
  }

  @override
  String friendYouOweLine(String name, String amount) {
    return 'você deve $amount para $name';
  }

  @override
  String noSharedGroup(String name) {
    return 'Você não está mais em um grupo com $name. Envie seu link de amizade para adicionar despesas.';
  }

  @override
  String get shareFriendLink => 'Compartilhar link de amizade';

  @override
  String firstExpenseNeedsConnection(String name) {
    return 'A primeira despesa com $name precisa de conexão.';
  }

  @override
  String reminderSent(String name) {
    return 'Lembrete enviado para $name';
  }

  @override
  String remindTomorrow(String name) {
    return 'Você pode lembrar $name de novo amanhã';
  }

  @override
  String remindNothingOwed(String name) {
    return '$name não te deve nada';
  }

  @override
  String get remindNeedsConnection => 'Enviar um lembrete precisa de conexão.';

  @override
  String amountsAnd(String a, String b) {
    return '$a e $b';
  }

  @override
  String inviteFriendText(String link) {
    return 'Te adicionei no Evensies para dividirmos despesas. Entre: $link';
  }

  @override
  String get personNotHere => 'Esta pessoa não está neste aparelho';

  @override
  String get personNotHereNote =>
      'Ainda não foi sincronizada, ou vocês não estão mais em um grupo juntos.';

  @override
  String get more => 'Mais';

  @override
  String get exportNonGroupCsv => 'Exportar despesas fora de grupo (CSV)';

  @override
  String get exportNonGroupJson => 'Exportar despesas fora de grupo (JSON)';

  @override
  String get exportNonGroupZip =>
      'Exportar despesas fora de grupo (ZIP com recibos)';

  @override
  String get notOnEvensies => 'Ainda não está no Evensies';

  @override
  String get allSettledUp => 'Tudo acertado';

  @override
  String get remind => 'Lembrar';

  @override
  String get invite => 'Convidar';

  @override
  String get balances => 'Saldos';

  @override
  String get expensesAndPayments => 'Despesas e pagamentos';

  @override
  String get nothingTogetherYet =>
      'Nada em comum ainda. Adicione uma despesa abaixo.';

  @override
  String get addExpense => 'Adicionar despesa';

  @override
  String personOwesYou(String amount) {
    return 'te deve $amount';
  }

  @override
  String personYouOwe(String amount) {
    return 'você deve $amount';
  }

  @override
  String get personSettledUp => 'quite';

  @override
  String recordedInGroups(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Registrado em $count grupos',
      one: 'Registrado em 1 grupo',
    );
    return '$_temp0';
  }

  @override
  String get markAsReceived => 'Marcar como recebido';

  @override
  String get clearBothSides => 'Zerar os dois lados';

  @override
  String evenIn(String currency) {
    return 'Quite em $currency';
  }

  @override
  String linePayThem(String group, String name, String amount) {
    return '$group: você paga $amount para $name';
  }

  @override
  String lineTheyPay(String group, String name, String amount) {
    return '$group: $name te paga $amount';
  }

  @override
  String get noMoneyMoves =>
      'Nenhum dinheiro muda de mãos: isso registra os dois lados como acertados.';

  @override
  String convertIn(String group) {
    return 'Converter em $group';
  }

  @override
  String settleUpWith(String name) {
    return 'Acertar com $name';
  }

  @override
  String nothingToSettleWith(String name) {
    return 'Nada para acertar com $name';
  }

  @override
  String settleWithIntro(String name) {
    return 'Tudo entre você e $name, por moeda. Registrar adiciona um pagamento em cada grupo.';
  }

  @override
  String get searchFriendsGroups => 'Buscar amigos e grupos';

  @override
  String get friends => 'Amigos';

  @override
  String get groups => 'Grupos';

  @override
  String get noFriendsOrGroups => 'Nenhum amigo ou grupo ainda.';

  @override
  String nothingMatches(String query) {
    return 'Nada corresponde a “$query”.';
  }

  @override
  String get addExpenseWithWhom => 'Adicionar despesa · com quem?';

  @override
  String friendLinkShare(String link, String code) {
    return 'Me adicione no Evensies para dividir despesas: $link\nOu digite meu código $code';
  }

  @override
  String get friendLinkNeedsConnection =>
      'Compartilhar seu link de amizade precisa de conexão.';

  @override
  String get selfFriend => 'Esse é o seu próprio código';

  @override
  String get noOneForCode => 'Ninguém encontrado com este código';

  @override
  String get addFriendNeedsConnection =>
      'Adicionar um amigo precisa de conexão.';

  @override
  String get newFriendCodeTitle => 'Gerar um novo código de amizade?';

  @override
  String get newFriendCodeMessage =>
      'Seu link e código atuais deixam de funcionar. Os amigos que você já tem continuam.';

  @override
  String get newCode => 'Novo código';

  @override
  String get addAFriend => 'Adicionar um amigo';

  @override
  String get friendLinkOffline => 'Seu link de amizade precisa de conexão';

  @override
  String get yourFriendCode => 'Seu código de amizade';

  @override
  String get friendQrLabel => 'QR code do seu link de amizade';

  @override
  String get friendCodeHelp =>
      'Seus amigos escaneiam, abrem o link ou digitam o código.';

  @override
  String get shareLink => 'Compartilhar link';

  @override
  String get codeCopied => 'Código copiado';

  @override
  String get copyCode => 'Copiar código';

  @override
  String get haveFriendCode => 'Tem o código de um amigo?';

  @override
  String get onEvensies => 'no Evensies';

  @override
  String get notOnEvensiesSection => 'Alguém que ainda não está no Evensies';

  @override
  String get notOnEvensiesHelp =>
      'Adicione despesas com a pessoa agora e convide depois.';

  @override
  String atMostChars(int max) {
    return 'No máximo $max caracteres';
  }

  @override
  String addName(String name) {
    return 'Adicionar $name';
  }

  @override
  String get search => 'Buscar';

  @override
  String get activity => 'Atividade';

  @override
  String get newGroup => 'Novo grupo';

  @override
  String get joinWithCode => 'Entrar com um código';

  @override
  String get filterAll => 'Todos';

  @override
  String get filterOwesMe => 'Me deve';

  @override
  String get filterIOwe => 'Eu devo';

  @override
  String settledUpCount(int count) {
    return 'Acertado ($count)';
  }

  @override
  String get nobodyOwesYou => 'Ninguém te deve nada';

  @override
  String get youOweNothing => 'Você não deve nada';

  @override
  String get nothingHereYet => 'Nada aqui ainda';

  @override
  String get noFriendsYet => 'Nenhum amigo ainda';

  @override
  String get noFriendsHelp =>
      'Adicione um amigo para dividir despesas fora de um grupo. Quem está em um grupo com você também aparece aqui.';

  @override
  String get allSettledUpYou => 'Você está quite com todo mundo';

  @override
  String youAreOwedList(String amounts) {
    return 'Te devem $amounts';
  }

  @override
  String youOweList(String amounts) {
    return 'Você deve $amounts';
  }

  @override
  String get notOnEvensiesLower => 'ainda não está no Evensies';

  @override
  String get noGroupsYet => 'Nenhum grupo ainda';

  @override
  String get noGroupsHelp =>
      'Crie um para uma viagem ou uma casa, ou entre no grupo de um amigo com o código de convite.';

  @override
  String get createGroup => 'Criar grupo';

  @override
  String get settledUp => 'Acertado';

  @override
  String netApprox(String amount) {
    return 'Líquido ≈ $amount';
  }

  @override
  String memberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membros',
      one: '1 membro',
    );
    return '$_temp0';
  }

  @override
  String youOweAmount(String amount) {
    return 'Você deve $amount';
  }

  @override
  String youAreOwedAmount(String amount) {
    return 'Te devem $amount';
  }

  @override
  String youOweAmountLine(String amount) {
    return 'você deve $amount';
  }

  @override
  String youAreOwedAmountLine(String amount) {
    return 'te devem $amount';
  }

  @override
  String get createGroupNeedsConnection => 'Criar um grupo precisa de conexão.';

  @override
  String get groupName => 'Nome do grupo';

  @override
  String get yourNameInGroup => 'Seu nome neste grupo';

  @override
  String get defaultCurrency => 'Moeda padrão';

  @override
  String get create => 'Criar';

  @override
  String get noGroupOrFriendForCode =>
      'Nenhum grupo ou amigo encontrado com este código';

  @override
  String get joinNeedsConnection => 'Entrar em um grupo precisa de conexão.';

  @override
  String get enterACode => 'Digite um código';

  @override
  String get enterCodeHelp =>
      'O código de um grupo está no grupo → Membros. O código de um amigo está na aba Amigos dele → Adicionar um amigo.';

  @override
  String get pastedFromClipboard => 'Colado da área de transferência';

  @override
  String nameOnEvensies(String name) {
    return '$name · no Evensies';
  }

  @override
  String addAsFriend(String name) {
    return 'Adicionar $name como amigo';
  }

  @override
  String addedYouAsFriend(String name) {
    return '$name te adicionou como amigo';
  }

  @override
  String get someoneAddedYouAsFriend => 'Alguém te adicionou como amigo';

  @override
  String groupPreview(String name, String members) {
    return '$name · $members';
  }

  @override
  String get continueButton => 'Continuar';

  @override
  String wantsToSplit(String name) {
    return '$name quer dividir despesas com você';
  }

  @override
  String get joinGroup => 'Entrar no grupo';

  @override
  String get inviteInvalid => 'Este link de convite não é mais válido';

  @override
  String inviteFailed(String reason) {
    return 'Não foi possível abrir este convite: $reason';
  }

  @override
  String get friendInviteUsed => 'Este convite de amizade já foi usado';

  @override
  String get joinToSeeShared =>
      'Entre para ver e adicionar as despesas em comum.';

  @override
  String imName(String name) {
    return 'Eu sou $name';
  }

  @override
  String get join => 'Entrar';

  @override
  String get whoAreYou => 'Quem é você?';

  @override
  String get newMemberName => 'Nome do novo membro';

  @override
  String get insights => 'Estatísticas';

  @override
  String get membersInvite => 'Membros e convite';

  @override
  String get groupSettings => 'Ajustes do grupo';

  @override
  String get expenses => 'Despesas';

  @override
  String get expenseFab => 'Despesa';

  @override
  String get groupNotHere => 'Este grupo não está neste aparelho';

  @override
  String get groupNotHereNote =>
      'Você saiu, alguém te removeu, ou ele ainda não foi sincronizado.';

  @override
  String get backToGroups => 'Voltar aos grupos';

  @override
  String get noExpensesYet => 'Nenhuma despesa ainda';

  @override
  String get tapExpenseToAdd => 'Toque em “Despesa” para adicionar a primeira.';

  @override
  String tilePaidYou(String amount) {
    return 'você pagou $amount';
  }

  @override
  String tilePaidName(String name, String amount) {
    return '$name pagou $amount';
  }

  @override
  String tilePaidPeople(int count, String amount) {
    return '$count pessoas pagaram $amount';
  }

  @override
  String get tileRefundYou => 'reembolso para você';

  @override
  String tileRefundName(String name) {
    return 'reembolso para $name';
  }

  @override
  String tileRefundPeople(int count) {
    return 'reembolso para $count pessoas';
  }

  @override
  String get notInvolved => 'não participa';

  @override
  String get allYours => 'tudo seu';

  @override
  String get paidForYourself => 'você pagou a sua parte';

  @override
  String youGetBack(String amount) {
    return 'você recebe $amount de volta';
  }

  @override
  String youLent(String amount) {
    return 'você emprestou $amount';
  }

  @override
  String youBorrowed(String amount) {
    return 'você pegou $amount emprestado';
  }

  @override
  String get repeatsLabel => 'Repete';

  @override
  String hasReceipt(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tem $count recibos',
      one: 'Tem um recibo',
    );
    return '$_temp0';
  }

  @override
  String get refund => 'Reembolso';

  @override
  String get notConverted => 'Não convertido';

  @override
  String get pending => 'pendente';

  @override
  String approxTotalOwe(String amount) {
    return 'Você deve ≈ $amount no total';
  }

  @override
  String approxTotalOwed(String amount) {
    return 'Te devem ≈ $amount no total';
  }

  @override
  String get approxTotalNote =>
      'Na sua moeda principal, pelas taxas mais recentes';

  @override
  String nothingOwedIn(String currency) {
    return 'Nada devido em $currency';
  }

  @override
  String get allSettled => 'Tudo acertado';

  @override
  String get otherCurrenciesBelow =>
      'As despesas em outras moedas estão abaixo.';

  @override
  String get nobodyOwes => 'Ninguém deve nada.';

  @override
  String youPayNext(String amount) {
    return 'Você deveria pagar da próxima vez (você deve $amount, o maior valor)';
  }

  @override
  String namePaysNext(String name, String amount) {
    return '$name deveria pagar da próxima vez (deve $amount, o maior valor)';
  }

  @override
  String settleUpWaiting(int count) {
    return 'Acertar · $count aguardando';
  }

  @override
  String memberRemoved(String name) {
    return '$name (removido)';
  }

  @override
  String expensesWithoutRate(int count, String currency) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count despesas sem taxa para $currency',
      one: '1 despesa sem taxa para $currency',
    );
    return '$_temp0';
  }

  @override
  String expensesBadRate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count despesas com uma taxa que não pode ser convertida',
      one: '1 despesa com uma taxa que não pode ser convertida',
    );
    return '$_temp0';
  }

  @override
  String paymentsIn(String currency) {
    return 'Pagamentos em $currency';
  }

  @override
  String everyoneEvenIn(String currency) {
    return 'todo mundo quite em $currency';
  }

  @override
  String convertTo(String currency) {
    return 'Converter para $currency';
  }

  @override
  String get balanceSettled => 'quite';

  @override
  String get balanceGetsBack => 'recebe';

  @override
  String get balanceOwes => 'deve';

  @override
  String convertedCount(int count, String currency) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count despesas convertidas para $currency',
      one: '1 despesa convertida para $currency',
    );
    return '$_temp0';
  }

  @override
  String get noAutoRate => 'Sem taxa automática. Informe uma.';

  @override
  String rateOf(String date) {
    return 'taxa de $date';
  }

  @override
  String rateOfOffline(String date) {
    return 'offline · taxa de $date';
  }

  @override
  String amountCountExpenses(String amount, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count despesas',
      one: '1 despesa',
    );
    return '$amount · $_temp0';
  }

  @override
  String paymentsStayIn(String currency) {
    return 'Os pagamentos em $currency continuam em $currency';
  }

  @override
  String rateLabel(String from, String to) {
    return 'Taxa: 1 $from em $to';
  }

  @override
  String get nothingLeftToConvert => 'Nada mais para converter';

  @override
  String get lookingUpRate => 'Buscando a taxa…';

  @override
  String get enterRateAbove0 => 'Informe uma taxa maior que 0';

  @override
  String convertExplain(String currency) {
    return 'Coloca esta taxa em cada despesa sem taxa, para que conte nos saldos em $currency. Você ainda pode mudar a taxa de cada despesa.';
  }

  @override
  String get nameField => 'Nome';

  @override
  String get cantChangeCurrency =>
      'Não pode ser mudada depois da primeira despesa ou pagamento';

  @override
  String get currencyUsedFor => 'Os saldos e pagamentos usam essa moeda';

  @override
  String get splitting => 'Divisão';

  @override
  String get simplifyDebts => 'Simplificar dívidas';

  @override
  String get simplifyDebtsHelp =>
      'Junta as dívidas para o grupo precisar de menos pagamentos. O total de ninguém muda, só quem paga quem.';

  @override
  String get defaultSplit => 'Divisão padrão';

  @override
  String get splitStale => 'Não fecha mais · toque para corrigir';

  @override
  String get membership => 'Participação';

  @override
  String get leaveGroup => 'Sair do grupo';

  @override
  String get balanceSettledNote => 'Seu saldo está acertado';

  @override
  String get renameGroup => 'Renomear grupo';

  @override
  String leaveTitle(String name) {
    return 'Sair de “$name”?';
  }

  @override
  String get leaveMessage =>
      'Você não vai mais ver este grupo. Suas despesas anteriores ficam com os outros membros. Para voltar, peça o código de convite.';

  @override
  String get leave => 'Sair';

  @override
  String youLeft(String name) {
    return 'Você saiu de “$name”';
  }

  @override
  String get splitEqualEveryone => 'Igual · todos';

  @override
  String splitPercentList(String list) {
    return 'Porcentagem · $list';
  }

  @override
  String splitSharesList(String list) {
    return 'Partes · $list';
  }

  @override
  String percentValue(String value) {
    return '$value%';
  }

  @override
  String get defaultSplitHelp =>
      'Novas despesas começam com esta divisão. Você ainda pode mudá-la em cada despesa.';

  @override
  String get useEqual => 'Usar partes iguais';

  @override
  String get inviteCode => 'Código de convite';

  @override
  String get inviteQrLabel => 'QR code do link de convite';

  @override
  String get inviteCodeHelp =>
      'Qualquer pessoa com este código pode entrar e escolher o próprio nome.';

  @override
  String inviteShareText(String group, String link, String code) {
    return 'Entre no meu grupo “$group” no Evensies: $link\nOu abra o app e digite o código $code';
  }

  @override
  String get rotateCode => 'Trocar código';

  @override
  String get members => 'Membros';

  @override
  String get notJoinedYet =>
      'ainda não entrou — compartilhe o código de convite';

  @override
  String get linked => 'vinculado';

  @override
  String get addPlaceholder => 'Adicionar membro provisório';

  @override
  String removeMemberTitle(String name) {
    return 'Remover $name?';
  }

  @override
  String get removeMemberMessage =>
      'As despesas anteriores e o saldo continuam no grupo.';

  @override
  String removeMemberSeries(int count, String name, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$name ainda está em $count despesas recorrentes ($names); a parte de $name continua até você editar a mais recente.',
      one:
          '$name ainda está em 1 despesa recorrente ($names); a parte de $name continua até você editar a mais recente.',
    );
    return '$_temp0';
  }

  @override
  String get addMember => 'Adicionar membro';

  @override
  String get rotateInviteTitle => 'Trocar o código de convite?';

  @override
  String get rotateInviteMessage =>
      'O código e o link atuais deixam de funcionar. Quem já entrou não é afetado.';

  @override
  String get rotate => 'Trocar';

  @override
  String get newInviteReady => 'Novo código de convite pronto';

  @override
  String get activityNeedsConnection => 'A atividade precisa de conexão';

  @override
  String get activityOfflineNote =>
      'As mudanças recentes aparecem aqui quando você estiver online de novo.';

  @override
  String get noActivityYet => 'Nenhuma atividade ainda';

  @override
  String get activityAllGroups => 'As mudanças nos seus grupos aparecem aqui.';

  @override
  String get activityThisGroup => 'As mudanças neste grupo aparecem aqui.';

  @override
  String get showingSaved => 'Atividade salva. Puxe para atualizar.';

  @override
  String get loadMore => 'Carregar mais';

  @override
  String get earlier => 'Antes';

  @override
  String get today => 'Hoje';

  @override
  String get yesterday => 'Ontem';

  @override
  String forDate(String date) {
    return 'referente a $date';
  }

  @override
  String get youCommented => 'Você comentou';

  @override
  String nameCommented(String name) {
    return '$name comentou';
  }

  @override
  String restoredName(String name) {
    return '“$name” restaurada';
  }

  @override
  String get paymentRestored => 'Pagamento restaurado';

  @override
  String get expenseNotHere => 'Esta despesa não está neste aparelho';

  @override
  String get deletedExpense => 'Despesa excluída';

  @override
  String get expense => 'Despesa';

  @override
  String seriesRepeats(String frequency) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Repete toda semana',
      'biweekly': 'Repete a cada 2 semanas',
      'monthly': 'Repete todo mês',
      'yearly': 'Repete todo ano',
      'other': 'Repete',
    });
    return '$_temp0';
  }

  @override
  String seriesRepeatsNext(String frequency, String date) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Repete toda semana · próxima em $date',
      'biweekly': 'Repete a cada 2 semanas · próxima em $date',
      'monthly': 'Repete todo mês · próxima em $date',
      'yearly': 'Repete todo ano · próxima em $date',
      'other': 'Repete · próxima em $date',
    });
    return '$_temp0';
  }

  @override
  String seriesRepeatsNextAmount(String frequency, String amount, String date) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Repete toda semana · próxima de $amount em $date',
      'biweekly': 'Repete a cada 2 semanas · próxima de $amount em $date',
      'monthly': 'Repete todo mês · próxima de $amount em $date',
      'yearly': 'Repete todo ano · próxima de $amount em $date',
      'other': 'Repete · próxima de $amount em $date',
    });
    return '$_temp0';
  }

  @override
  String rateLine(String from, String rate, String to) {
    return 'Taxa: 1 $from = $rate $to';
  }

  @override
  String notConvertedTo(String currency) {
    return 'Não convertida para $currency';
  }

  @override
  String get receivedSplitBack => 'Recebido e dividido de volta';

  @override
  String get whoPaidOwes => 'Quem pagou e quem deve';

  @override
  String get items => 'Itens';

  @override
  String get notes => 'Notas';

  @override
  String get receipts => 'Recibos';

  @override
  String get history => 'Histórico';

  @override
  String get deleteExpenseTitle => 'Excluir a despesa?';

  @override
  String get deleteExpenseMessage =>
      'Ela é removida para todos do grupo. Você pode restaurá-la pela Atividade.';

  @override
  String get deleteRepeatingTitle => 'Excluir a despesa recorrente?';

  @override
  String get deleteRepeatingMessage =>
      'Ela é removida para todos do grupo. Você pode restaurá-la pela Atividade, mas uma série parada não pode recomeçar. As repetições já adicionadas continuam.';

  @override
  String get deleteThisOne => 'Excluir só esta';

  @override
  String get deleteAndStop => 'Excluir e parar de repetir';

  @override
  String deletedAndStopped(String name) {
    return '“$name” excluída e parou de repetir';
  }

  @override
  String deletedName(String name) {
    return '“$name” excluída';
  }

  @override
  String get movedToOtherGroup => 'Movida para outro grupo';

  @override
  String get movedNote =>
      'Agora ela conta lá. Comentários e histórico ficam aqui.';

  @override
  String get expenseWasDeleted => 'Esta despesa foi excluída';

  @override
  String get restoreToCount => 'Restaure-a para contar nos saldos de novo.';

  @override
  String get tax => 'Impostos';

  @override
  String get tipService => 'Gorjeta ou serviço';

  @override
  String get discount => 'Desconto';

  @override
  String youPaidOwe(String paid, String owe) {
    return 'Você pagou $paid e deve $owe';
  }

  @override
  String youPaid(String amount) {
    return 'Você pagou $amount';
  }

  @override
  String youOwe(String amount) {
    return 'Você deve $amount';
  }

  @override
  String namePaidOwes(String name, String paid, String owe) {
    return '$name pagou $paid e deve $owe';
  }

  @override
  String namePaid(String name, String amount) {
    return '$name pagou $amount';
  }

  @override
  String nameOwes(String name, String amount) {
    return '$name deve $amount';
  }

  @override
  String youReceivedGetBack(String received, String back) {
    return 'Você recebeu $received e recebe $back de volta';
  }

  @override
  String youReceived(String amount) {
    return 'Você recebeu $amount';
  }

  @override
  String youGetBackLine(String amount) {
    return 'Você recebe $amount de volta';
  }

  @override
  String nameReceivedGetsBack(String name, String received, String back) {
    return '$name recebeu $received e recebe $back de volta';
  }

  @override
  String nameReceived(String name, String amount) {
    return '$name recebeu $amount';
  }

  @override
  String nameGetsBack(String name, String amount) {
    return '$name recebe $amount de volta';
  }

  @override
  String get noHistoryYet => 'Nenhum histórico ainda.';

  @override
  String get historyOffline =>
      'O histórico aparece aqui quando você estiver online.';

  @override
  String get showingSavedHistory => 'Histórico salvo.';

  @override
  String get showMore => 'Ver mais';

  @override
  String get deleteCommentTitle => 'Excluir o comentário?';

  @override
  String get comments => 'Comentários';

  @override
  String get noCommentsYet => 'Nenhum comentário ainda.';

  @override
  String get deleteComment => 'Excluir comentário';

  @override
  String get addComment => 'Adicionar um comentário';

  @override
  String get send => 'Enviar';

  @override
  String get filterByCategory => 'Filtrar por categoria';

  @override
  String get category => 'Categoria';

  @override
  String get categoryAll => 'Todas';

  @override
  String get month => 'Mês';

  @override
  String get searchUnavailable => 'A busca não está disponível';

  @override
  String get searchExpenses => 'Buscar despesas';

  @override
  String get searchHelp =>
      'Descrições, notas, comentários, categorias e valores: “táxi”, “aeroporto”, “12,50”.';

  @override
  String get noMatches => 'Nenhum resultado';

  @override
  String get noMatchesHelp => 'Tente outra palavra ou remova um filtro.';

  @override
  String expenseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count despesas',
      one: '1 despesa',
    );
    return '$_temp0';
  }

  @override
  String get searchAllGroups => 'Buscar em todos os grupos';

  @override
  String searchGroup(String name) {
    return 'Buscar em $name';
  }

  @override
  String get searchThisGroup => 'Buscar neste grupo';

  @override
  String get clear => 'Limpar';

  @override
  String get thisGroup => 'Este grupo';

  @override
  String insightsError(String reason) {
    return 'Não foi possível mostrar as estatísticas: $reason';
  }

  @override
  String get nothingToShow => 'Nada para mostrar ainda';

  @override
  String get insightsEmptyHelp =>
      'Totais e gráficos aparecem quando o grupo tiver despesas.';

  @override
  String get allTime => 'Todo o período';

  @override
  String get shareSummary => 'Compartilhar resumo';

  @override
  String get printSummary => 'Imprimir resumo';

  @override
  String get previousMonth => 'Mês anterior';

  @override
  String get nextMonth => 'Próximo mês';

  @override
  String get byMonth => 'Por mês';

  @override
  String get groupSegment => 'Grupo';

  @override
  String get mineSegment => 'Minhas';

  @override
  String get byCategory => 'Por categoria';

  @override
  String get noExpensesPeriod => 'Nenhuma despesa neste período.';

  @override
  String get byPerson => 'Por pessoa';

  @override
  String get nobodyPaidPeriod => 'Ninguém pagou nem deveu nada neste período.';

  @override
  String keptUntilConverted(String currency, String group) {
    return 'Fica em $currency até ser convertido para $group.';
  }

  @override
  String get totalSpent => 'Total gasto';

  @override
  String get yourShare => 'Sua parte';

  @override
  String get paymentsMade => 'Pagamentos feitos';

  @override
  String get paymentsReceived => 'Pagamentos recebidos';

  @override
  String get youPaidRow => 'Você pagou';

  @override
  String get balanceChange => 'Mudança no seu saldo';

  @override
  String get paidLegend => 'Pago';

  @override
  String get shareLegend => 'Parte';

  @override
  String paidShareLine(String paid, String share) {
    return 'pagou $paid · parte $share';
  }

  @override
  String get itemsGiveEveryone => 'Dê uma pessoa para cada item';

  @override
  String get itemsAddPrices =>
      'Informe os preços dos itens antes de impostos ou gorjeta';

  @override
  String get itemsDiscountTooBig => 'O desconto é maior que a conta';

  @override
  String get itemsDontAddUp => 'Os itens não fecham';

  @override
  String get adjustmentsDontFit => 'Os ajustes não cabem no total';

  @override
  String get giveSomeoneShare => 'Dê uma parte para alguém';

  @override
  String get checkNumbers => 'Confira os números';

  @override
  String get splitDoesntAddUp => 'A divisão não fecha';

  @override
  String get addTheItems => 'Adicione os itens';

  @override
  String get pickOnePerson => 'Escolha pelo menos uma pessoa';

  @override
  String splitEquallyBetween(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dividido igualmente entre $count pessoas',
      one: 'Dividido igualmente entre 1 pessoa',
    );
    return '$_temp0';
  }

  @override
  String get allForOnePerson => 'Tudo para 1 pessoa';

  @override
  String splitEquallyEach(int count, String amount) {
    return 'Dividido igualmente entre $count pessoas · $amount cada';
  }

  @override
  String get checkAmounts => 'Confira os valores';

  @override
  String get enterTotalFirst => 'Informe o total primeiro';

  @override
  String remaining(String amount) {
    return 'falta: $amount';
  }

  @override
  String overBy(String amount) {
    return 'passou: $amount';
  }

  @override
  String get addsUp => 'Fecha';

  @override
  String sharesInTotal(String count) {
    return '$count partes no total';
  }

  @override
  String get oneShareInTotal => '1 parte no total';

  @override
  String get restSplitEqually => 'O resto é dividido igualmente';

  @override
  String get byPercent => 'Por porcentagem';

  @override
  String get byShares => 'Por partes';

  @override
  String get byAdjustment =>
      'Ajustar: a mais ou a menos para alguém, o resto igual';

  @override
  String get modeEqual => 'Igual';

  @override
  String get modeExact => 'Exato';

  @override
  String get modeShares => 'Partes';

  @override
  String get byItem => 'Por item, de um recibo';

  @override
  String get adjustmentHelp =>
      'Some ou tire um valor de alguém; o resto é dividido igualmente.';

  @override
  String get noMembers => 'Nenhum membro';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count itens',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get addAnItem => 'Adicione um item';

  @override
  String atMostItems(int max) {
    return 'No máximo $max itens';
  }

  @override
  String get giveItemName => 'Dê um nome a cada item';

  @override
  String get itemNameTooLong => 'O nome de um item é longo demais';

  @override
  String get addItem => 'Adicionar item';

  @override
  String get giveRestToEveryone => 'Dar o resto para todos';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get total => 'Total';

  @override
  String receiptSays(String printed, String difference) {
    return 'O recibo diz $printed · os itens diferem em $difference';
  }

  @override
  String get eachPerson => 'Por pessoa';

  @override
  String itemsWithoutPerson(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count itens sem pessoa',
      one: '1 item sem pessoa',
    );
    return '$_temp0';
  }

  @override
  String get itemHint => 'Item';

  @override
  String memberLeft(String name) {
    return '$name (saiu)';
  }

  @override
  String get whoHadThis => 'Quem consumiu isso?';

  @override
  String get defaultSplitStartsEqual =>
      'A divisão padrão do grupo não fecha mais, então esta começa igual';

  @override
  String leftToAssign(String amount) {
    return 'Faltam $amount para distribuir';
  }

  @override
  String get itemsTotal => 'O total dos itens';

  @override
  String get newExpense => 'Nova despesa';

  @override
  String get editExpense => 'Editar despesa';

  @override
  String get scanReceipt => 'Escanear recibo';

  @override
  String get rateAboveZeroOrEmpty =>
      'Informe uma taxa maior que 0, ou deixe vazio';

  @override
  String useAutoRate(String rate, String source) {
    return 'Usar taxa automática: $rate ($source)';
  }

  @override
  String get description => 'Descrição';

  @override
  String get receivedBy => 'Recebido por';

  @override
  String get paidBy => 'Pago por';

  @override
  String get severalPeople => 'Várias pessoas';

  @override
  String get when => 'Quando';

  @override
  String get refundTooltip =>
      'Dinheiro que voltou, ex.: o hotel devolveu o depósito';

  @override
  String get splitBackTo => 'Dividido de volta para';

  @override
  String get split => 'Divisão';

  @override
  String theyOweFull(String name) {
    return '$name deve o valor total';
  }

  @override
  String iOweFull(String name) {
    return 'Eu devo o valor total para $name';
  }

  @override
  String get repeat => 'Repetir';

  @override
  String editLatestRepeat(String date) {
    return 'Para mudar as próximas repetições, edite a mais recente ($date)';
  }

  @override
  String get stopsRepeating =>
      'Para de repetir. As repetições já adicionadas continuam.';

  @override
  String nextRepeat(String date) {
    return 'Próxima: $date';
  }

  @override
  String get alsoChangeFuture => 'Mudar também as próximas repetições';

  @override
  String get futureFields =>
      'Valor, divisão, pagantes, descrição, categoria e notas';

  @override
  String get onlyThisOne => 'Só esta muda';

  @override
  String get addPhoto => 'Adicionar foto';

  @override
  String maxReceiptsNote(int max) {
    return '$max recibos é o máximo para uma despesa';
  }

  @override
  String get scanAReceipt => 'Escanear um recibo';

  @override
  String receiptLooksLike(String currency) {
    return 'Este recibo parece estar em $currency';
  }

  @override
  String switchToCurrencyQuestion(String currency) {
    return 'Mudar a despesa para $currency para ler os itens?';
  }

  @override
  String switchTo(String currency) {
    return 'Mudar para $currency';
  }

  @override
  String get couldntReadItems => 'Não foi possível ler os itens. Digite-os.';

  @override
  String withName(String name) {
    return 'Com $name';
  }

  @override
  String movesTo(String name) {
    return 'Vai para $name ao salvar';
  }

  @override
  String fromName(String name) {
    return 'De $name';
  }

  @override
  String get dontMove => 'Não mover';

  @override
  String get onlyLinkedMove =>
      'Só pessoas do Evensies que estão nos dois podem ser movidas';

  @override
  String get auto => 'auto';

  @override
  String get noAutoRateForm =>
      'Sem taxa automática. Informe uma, ou deixe vazio para manter em “Não convertido”.';

  @override
  String get emptyNotConverted => 'Vazio: fica em “Não convertido”';

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
  String get yourRate => 'sua taxa';
}
