// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Evensies';

  @override
  String get cancel => 'Batal';

  @override
  String get delete => 'Hapus';

  @override
  String get remove => 'Lepas';

  @override
  String get save => 'Simpan';

  @override
  String get done => 'Selesai';

  @override
  String get undo => 'Urungkan';

  @override
  String get retry => 'Coba lagi';

  @override
  String get ok => 'OK';

  @override
  String get close => 'Tutup';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Tambah';

  @override
  String get offlineBanner => 'Offline — perubahan akan disinkronkan nanti';

  @override
  String get tooLong => 'Terlalu panjang';

  @override
  String get allCurrencies => 'Semua mata uang';

  @override
  String get errorUnexpected => 'Terjadi kesalahan. Coba lagi.';

  @override
  String get errorNetwork => 'Anda sedang offline. Coba lagi nanti.';

  @override
  String get errorRateLimited =>
      'Terlalu banyak percobaan. Tunggu semenit lalu coba lagi.';

  @override
  String get errorNotFound => 'Itu sudah tidak ada.';

  @override
  String get errorForbidden => 'Anda tidak boleh melakukan itu.';

  @override
  String get errorValidation => 'Server menolaknya.';

  @override
  String get errorSumMismatch => 'Pembagiannya tidak pas.';

  @override
  String get errorPayersSumMismatch => 'Jumlah pembayar tidak pas.';

  @override
  String get errorNegativeAmount => 'Ada jumlah di bawah nol.';

  @override
  String get errorNegativeShare => 'Bagian seseorang akan di bawah nol.';

  @override
  String get errorNegativeTotal => 'Totalnya akan di bawah nol.';

  @override
  String get errorZeroSubtotal =>
      'Isi harga item sebelum pajak, tip, atau diskon.';

  @override
  String get errorUnassignedItem => 'Setiap item butuh setidaknya satu orang.';

  @override
  String get errorNoMembers => 'Pilih setidaknya satu orang untuk berbagi.';

  @override
  String get errorInvalidInput => 'Periksa angkanya.';

  @override
  String get errorBadRate => 'Kurs harus di atas nol.';

  @override
  String get errorUnknownMember =>
      'Ini menyangkut seseorang yang tidak ada di grup.';

  @override
  String get errorUnknownCurrency => 'Mata uang ini tidak didukung.';

  @override
  String get errorMemberTaken => 'Anggota itu sudah dipilih.';

  @override
  String get errorLimitExceeded => 'Batasnya sudah tercapai.';

  @override
  String get errorTooLarge => 'Fotonya terlalu besar.';

  @override
  String get errorNotJpeg => 'Pilih foto JPEG';

  @override
  String get errorFxUnavailable => 'Kurs sedang tidak tersedia.';

  @override
  String get errorImportFailed => 'File itu tidak bisa diimpor.';

  @override
  String get errorAuthNotConfigured =>
      'Server ini tidak bisa memasukkan Anda dengan cara itu.';

  @override
  String get errorDuplicate => 'Itu sudah ada.';

  @override
  String errorGeneric(String code) {
    return 'Terjadi kesalahan ($code).';
  }

  @override
  String rejectedReceipt(String name, String reason) {
    return 'Tidak bisa menyimpan struk untuk “$name”: $reason';
  }

  @override
  String rejectedReceiptUnnamed(String reason) {
    return 'Tidak bisa menyimpan struk untuk sebuah pengeluaran: $reason';
  }

  @override
  String rejectedReceiptRemove(String name, String reason) {
    return 'Tidak bisa menyimpan pelepasan struk dari “$name”: $reason';
  }

  @override
  String rejectedReceiptRemoveUnnamed(String reason) {
    return 'Tidak bisa menyimpan pelepasan struk dari sebuah pengeluaran: $reason';
  }

  @override
  String rejectedRepeating(String name, String reason) {
    return 'Tidak bisa menyimpan pengulangan “$name”: $reason';
  }

  @override
  String rejectedRepeatingUnnamed(String reason) {
    return 'Tidak bisa menyimpan pengeluaran berulang: $reason';
  }

  @override
  String rejectedSeriesChange(String name, String reason) {
    return 'Tidak bisa menyimpan perubahan untuk “$name” berikutnya: $reason';
  }

  @override
  String rejectedSeriesChangeUnnamed(String reason) {
    return 'Tidak bisa menyimpan perubahan pengeluaran berulang: $reason';
  }

  @override
  String rejectedSeriesStop(String name, String reason) {
    return 'Tidak bisa menyimpan penghentian “$name”: $reason';
  }

  @override
  String rejectedSeriesStopUnnamed(String reason) {
    return 'Tidak bisa menyimpan penghentian pengeluaran berulang: $reason';
  }

  @override
  String rejectedSavedNoRepeat(String name, String reason) {
    return '“$name” tersimpan tapi tidak akan berulang: $reason';
  }

  @override
  String rejectedPaymentRestore(String reason) {
    return 'Tidak bisa menyimpan pemulihan pembayaran: $reason';
  }

  @override
  String rejectedNewExpense(String name, String reason) {
    return 'Tidak bisa menyimpan pengeluaran baru “$name”: $reason';
  }

  @override
  String rejectedNewExpenseUnnamed(String reason) {
    return 'Tidak bisa menyimpan pengeluaran baru: $reason';
  }

  @override
  String rejectedExpenseChange(String name, String reason) {
    return 'Tidak bisa menyimpan perubahan pada “$name”: $reason';
  }

  @override
  String rejectedExpenseChangeUnnamed(String reason) {
    return 'Tidak bisa menyimpan perubahan pada sebuah pengeluaran: $reason';
  }

  @override
  String rejectedExpenseDelete(String name, String reason) {
    return 'Tidak bisa menyimpan penghapusan “$name”: $reason';
  }

  @override
  String rejectedExpenseDeleteUnnamed(String reason) {
    return 'Tidak bisa menyimpan penghapusan sebuah pengeluaran: $reason';
  }

  @override
  String rejectedExpenseRestore(String name, String reason) {
    return 'Tidak bisa menyimpan pemulihan “$name”: $reason';
  }

  @override
  String rejectedExpenseRestoreUnnamed(String reason) {
    return 'Tidak bisa menyimpan pemulihan sebuah pengeluaran: $reason';
  }

  @override
  String rejectedComment(String name, String reason) {
    return 'Tidak bisa menyimpan komentar di “$name”: $reason';
  }

  @override
  String rejectedCommentUnnamed(String reason) {
    return 'Tidak bisa menyimpan komentar di sebuah pengeluaran: $reason';
  }

  @override
  String rejectedPaymentComment(String reason) {
    return 'Tidak bisa menyimpan komentar di sebuah pembayaran: $reason';
  }

  @override
  String rejectedCommentDelete(String reason) {
    return 'Tidak bisa menyimpan penghapusan komentar: $reason';
  }

  @override
  String rejectedPayment(String reason) {
    return 'Tidak bisa menyimpan pembayaran: $reason';
  }

  @override
  String rejectedPaymentDelete(String reason) {
    return 'Tidak bisa menyimpan penghapusan pembayaran: $reason';
  }

  @override
  String rejectedPaymentConfirm(String reason) {
    return 'Tidak bisa menyimpan konfirmasi pembayaran: $reason';
  }

  @override
  String rejectedGroupSettings(String reason) {
    return 'Tidak bisa menyimpan perubahan pengaturan grup: $reason';
  }

  @override
  String rejectedMemberAdd(String name, String reason) {
    return 'Tidak bisa menyimpan penambahan $name: $reason';
  }

  @override
  String rejectedMemberAddUnnamed(String reason) {
    return 'Tidak bisa menyimpan penambahan anggota: $reason';
  }

  @override
  String rejectedMemberRemove(String reason) {
    return 'Tidak bisa menyimpan pengeluaran anggota dari grup: $reason';
  }

  @override
  String rejectedOther(String reason) {
    return 'Tidak bisa menyimpan perubahan: $reason';
  }

  @override
  String get reasonReceiptLimit => 'satu pengeluaran maksimal punya 10 struk';

  @override
  String get reasonSeriesLimit =>
      'satu grup maksimal punya 100 pengeluaran berulang';

  @override
  String get reasonNotUploaded => 'fotonya tidak terunggah';

  @override
  String get reasonSumMismatch => 'pembagiannya tidak pas';

  @override
  String get reasonPayersSumMismatch => 'jumlah pembayar tidak pas';

  @override
  String get reasonNegativeAmount => 'ada jumlah di bawah nol';

  @override
  String get reasonUnknownMember =>
      'ini menyangkut seseorang yang tidak ada di grup';

  @override
  String get reasonUnknownCurrency => 'mata uang ini tidak didukung';

  @override
  String get reasonMemberTaken => 'anggota itu sudah dipilih';

  @override
  String get reasonGroupFull => 'grupnya sudah penuh';

  @override
  String get reasonForbidden => 'Anda tidak boleh membuat perubahan itu';

  @override
  String get reasonRefused => 'server menolaknya';

  @override
  String leaveOwe(String amount) {
    return 'Anda berutang $amount · lunasi dulu';
  }

  @override
  String leaveOweIn(String amount, String currency) {
    return 'Anda berutang $amount · lunasi dulu dalam $currency';
  }

  @override
  String leaveOwed(String amount) {
    return 'Anda masih dapat $amount · selesaikan dulu';
  }

  @override
  String leaveOwedIn(String amount, String currency) {
    return 'Anda masih dapat $amount · selesaikan dulu dalam $currency';
  }

  @override
  String leaveSeries(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Anda masih ada di $count pengeluaran berulang ($names) · edit yang terbaru atau hentikan dulu',
    );
    return '$_temp0';
  }

  @override
  String seriesNamesMore(String names, int count) {
    return '$names dan $count lainnya';
  }

  @override
  String get seriesUnnamed => 'sebuah pengeluaran';

  @override
  String get listJoiner => ', ';

  @override
  String get repeatNever => 'Tidak pernah';

  @override
  String get repeatWeekly => 'Setiap minggu';

  @override
  String get repeatBiweekly => 'Setiap 2 minggu';

  @override
  String get repeatMonthly => 'Setiap bulan';

  @override
  String get repeatYearly => 'Setiap tahun';

  @override
  String summaryNotConverted(String currency) {
    return 'Belum dikonversi · $currency';
  }

  @override
  String summaryTotalSpent(String amount) {
    return 'Total dibelanjakan: $amount';
  }

  @override
  String summaryPaidShare(String paid, String share) {
    return 'Anda bayar: $paid · Bagian Anda: $share';
  }

  @override
  String summaryPayments(String made, String received) {
    return 'Pembayaran dikirim: $made · diterima: $received';
  }

  @override
  String summaryTopCategories(String list) {
    return 'Kategori teratas: $list';
  }

  @override
  String get summaryBalancesToday => 'Saldo hari ini';

  @override
  String summaryGetsBack(String name, String amount) {
    return '$name dapat kembali $amount';
  }

  @override
  String summaryOwes(String name, String amount) {
    return '$name berutang $amount';
  }

  @override
  String get summaryFooter => 'Dibagikan dari Evensies';

  @override
  String get koreanBank => 'Rekening bank Korea';

  @override
  String requestText(String amount, String group) {
    return 'Anda berutang $amount kepada saya untuk $group di Evensies.';
  }

  @override
  String requestTextWays(String amount, String group, String ways) {
    return 'Anda berutang $amount kepada saya untuk $group di Evensies. Bayar lewat: $ways';
  }

  @override
  String get requestNoGroup => 'pengeluaran bersama kita';

  @override
  String get leaveSyncing => 'Masih menyinkronkan. Coba lagi sebentar lagi.';

  @override
  String get leaveOffline => 'Anda harus online untuk keluar';

  @override
  String get moveOffline => 'Tidak bisa memindahkan. Coba lagi saat online';

  @override
  String moveFailed(String reason) {
    return 'Tidak bisa memindahkan: $reason';
  }

  @override
  String get photoNoAccess =>
      'Evensies tidak punya akses. Izinkan di aplikasi Pengaturan.';

  @override
  String get photoNoCamera => 'Tidak bisa membuka kamera.';

  @override
  String get photoNoLibrary => 'Tidak bisa membuka galeri foto.';

  @override
  String get photoUnusable => 'Foto itu tidak bisa dipakai. Coba foto lain.';

  @override
  String get methodErrorUsername => 'Hanya huruf, angka, . _ - (maks. 40)';

  @override
  String methodErrorLinkPrefix(String prefix) {
    return 'Harus diawali $prefix';
  }

  @override
  String get methodErrorTooLong => 'Maks. 200 karakter';

  @override
  String get methodErrorIban => 'IBAN tidak valid';

  @override
  String get methodErrorHolder => 'Nama pemilik rekening (1–70 karakter)';

  @override
  String get methodErrorBic => 'BIC terdiri dari 8 atau 11 karakter';

  @override
  String get methodErrorKrAccount => 'Angka dan tanda hubung, 8–20 digit';

  @override
  String get methodErrorBank => 'Nama bank (1–30 karakter)';

  @override
  String get methodErrorUnknownType => 'Jenis tidak dikenal';

  @override
  String get methodErrorTooMany =>
      'Maksimal 8 cara menerima uang, dan 3 untuk setiap jenis bank';

  @override
  String get bannerDismiss => 'Tutup';

  @override
  String get bannerView => 'Lihat';

  @override
  String get loginTagline =>
      'Bagi pengeluaran dengan teman. Tanpa iklan, tanpa jualan tambahan.';

  @override
  String get loginApple => 'Lanjutkan dengan Apple';

  @override
  String get loginGoogle => 'Lanjutkan dengan Google';

  @override
  String get loginWebUnavailable =>
      'Server ini belum punya login lewat browser.';

  @override
  String get welcomeTitle => 'Selamat datang';

  @override
  String get yourNameTitle => 'Nama Anda';

  @override
  String get nameQuestion => 'Teman-teman Anda harus memanggil Anda apa?';

  @override
  String get nameExplain => 'Ini nama yang dilihat anggota lain.';

  @override
  String get nameHelp =>
      'Nama ini terlihat oleh orang di grup Anda. Anda bisa mengubahnya nanti di Pengaturan.';

  @override
  String get nameLabel => 'Nama';

  @override
  String get lockReason => 'Buka kunci Evensies';

  @override
  String get lockTitle => 'Evensies terkunci';

  @override
  String get lockSubtitle =>
      'Buka dengan Face ID, Touch ID, sidik jari, atau kode sandi perangkat.';

  @override
  String get lockUnlock => 'Buka kunci';

  @override
  String get lockSignOutConfirm =>
      'Keluar dan hapus data di perangkat ini? Grup Anda tetap ada di server.';

  @override
  String get signOut => 'Keluar';

  @override
  String get widgetOwed => 'Anda dapat';

  @override
  String get widgetOwe => 'Anda berutang';

  @override
  String get widgetSignedOut => 'Masuk untuk melihat saldo Anda';

  @override
  String get widgetSettled => 'Semua sudah lunas';

  @override
  String widgetUpdated(String time) {
    return 'Diperbarui $time';
  }

  @override
  String get receiptAdd => 'Tambah struk';

  @override
  String get photoTake => 'Ambil foto';

  @override
  String get photoChoose => 'Pilih dari galeri';

  @override
  String get photoChooseFile => 'Pilih file';

  @override
  String get availableWhenOnline => 'Tersedia saat online';

  @override
  String get receiptPhoto => 'Foto struk';

  @override
  String get receiptAvailableOnline => 'Foto tersedia saat online';

  @override
  String get receiptRemoveTitle => 'Lepas struk?';

  @override
  String get receiptRemoveMessage => 'Struk dilepas untuk semua orang di grup.';

  @override
  String get receiptTitle => 'Struk';

  @override
  String receiptTitleOf(int index, int count) {
    return 'Struk $index dari $count';
  }

  @override
  String get shareOrSave => 'Bagikan atau simpan';

  @override
  String get share => 'Bagikan';

  @override
  String get copiedToClipboard => 'Disalin ke papan klip';

  @override
  String get settingsTitle => 'Pengaturan';

  @override
  String get photoRemove => 'Hapus foto';

  @override
  String get photoNeedsConnection => 'Mengganti foto butuh koneksi.';

  @override
  String get photoTooMany => 'Terlalu sering ganti foto. Coba lagi sejam lagi.';

  @override
  String get notifSaveFailed =>
      'Tidak bisa menyimpan pengaturan notifikasi. Periksa koneksi Anda.';

  @override
  String get homeCurrencyNeedsConnection =>
      'Mengganti mata uang utama butuh koneksi.';

  @override
  String get changePhoto => 'Ganti foto profil';

  @override
  String get yourNameTapToChange => 'Nama Anda · ketuk untuk mengganti';

  @override
  String get waysToGetPaid => 'Cara menerima uang';

  @override
  String get waysToGetPaidHint => 'PayPal, Wise, IBAN, rekening bank…';

  @override
  String get homeCurrency => 'Mata uang utama';

  @override
  String get homeCurrencyFromRegion =>
      'Dari wilayah Anda · saldo juga ditampilkan ≈ dalam mata uang ini';

  @override
  String get homeCurrencyPicked =>
      'Saldo juga ditampilkan ≈ dalam mata uang ini';

  @override
  String get notifications => 'Notifikasi';

  @override
  String get notifExpenses => 'Pengeluaran dan pembayaran';

  @override
  String get notifComments => 'Komentar';

  @override
  String get notifMembers => 'Anggota dan perubahan grup';

  @override
  String get notifReminders => 'Pengingat dari teman';

  @override
  String get notifNeedConnection => 'Pengaturan notifikasi butuh koneksi';

  @override
  String get notifOthersOnly =>
      'Anda hanya diberi tahu tentang perubahan dari orang lain.';

  @override
  String get notifWebNote =>
      'Notifikasi dikirim ke ponsel Anda; browser memperbarui setiap menit selama terbuka.';

  @override
  String get exportImport => 'Ekspor & impor';

  @override
  String get noGroupsToExport => 'Tidak ada grup untuk diekspor.';

  @override
  String get nonGroup => 'Di luar grup';

  @override
  String nonGroupWith(String name) {
    return 'Di luar grup · $name';
  }

  @override
  String get exportJson => 'Ekspor JSON';

  @override
  String get exportCsv => 'Ekspor CSV';

  @override
  String get exportZip => 'ZIP beserta struk';

  @override
  String get importSplitwise => 'Impor CSV Splitwise';

  @override
  String importedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pengeluaran diimpor',
    );
    return '$_temp0';
  }

  @override
  String get server => 'Server';

  @override
  String get serverUrl => 'URL server';

  @override
  String serverDefault(String url) {
    return 'Bawaan: $url';
  }

  @override
  String get serverSaved => 'URL server disimpan';

  @override
  String get account => 'Akun';

  @override
  String get licenses => 'Lisensi';

  @override
  String get deleteAccount => 'Hapus akun';

  @override
  String get signOutTitle => 'Keluar?';

  @override
  String get signOutMessage =>
      'Data lokal di perangkat ini dihapus. Perubahan yang belum tersinkron akan hilang.';

  @override
  String get deleteAccountTitle => 'Hapus akun?';

  @override
  String get deleteAccountMessage =>
      'Keanggotaan Anda menjadi anggota sementara. Data grup tetap ada pada anggota lain. Ini tidak bisa dibatalkan.';

  @override
  String get language => 'Bahasa';

  @override
  String languageSystem(String language) {
    return 'Sistem ($language)';
  }

  @override
  String get appearance => 'Tampilan';

  @override
  String get appearanceSystem => 'Sistem';

  @override
  String get appearanceLight => 'Terang';

  @override
  String get appearanceDark => 'Gelap';

  @override
  String get security => 'Keamanan';

  @override
  String get appLock => 'Kunci aplikasi';

  @override
  String get appLockHint =>
      'Face ID, Touch ID, atau sidik jari, dengan kode sandi perangkat sebagai cadangan. Terkunci setelah semenit ditinggal.';

  @override
  String methodRemoveTitle(String method) {
    return 'Hapus $method?';
  }

  @override
  String get methodsOffline =>
      'Sambungkan ke internet untuk mengedit cara menerima uang.';

  @override
  String get methodsLoadFailed => 'Tidak bisa memuat cara menerima uang.';

  @override
  String get methodsIntro =>
      'Anggota grup melihatnya saat mereka berutang kepada Anda, jadi mereka bisa membayar dengan sekali ketuk. Evensies sendiri tidak pernah memindahkan uang.';

  @override
  String get methodsEmpty => 'Belum ada cara menerima uang.';

  @override
  String get blurbPaypal => 'Tautan PayPal.me, jumlah terisi';

  @override
  String get blurbWise => 'Tautan Wise Quick Pay, jumlah terisi';

  @override
  String get blurbVenmo => 'Nama pengguna Venmo (AS)';

  @override
  String get blurbRevolut => 'Nama pengguna Revolut.me';

  @override
  String get blurbKakaopay => 'Tautan 송금코드 KakaoPay';

  @override
  String get blurbIban => 'Transfer bank (QR SEPA untuk EUR)';

  @override
  String get blurbKrBank => 'Rekening bank Korea (Toss, aplikasi bank)';

  @override
  String get fieldPaypal => 'Nama pengguna PayPal.me';

  @override
  String get fieldPaypalHint => 'Nama pengguna PayPal.me Anda, mis. anna';

  @override
  String get fieldRevolut => 'Nama pengguna Revolut.me';

  @override
  String get fieldRevolutHint => 'Nama pengguna Revolut.me Anda, mis. anna';

  @override
  String get fieldVenmo => 'Nama pengguna Venmo';

  @override
  String get fieldVenmoHint => 'Tanpa @, mis. anna-rossi';

  @override
  String get fieldWise => 'Tautan Wise Quick Pay';

  @override
  String get fieldWiseHint =>
      'Di Wise: Payments → Quick Pay → salin tautan (https://wise.com/pay/…)';

  @override
  String get fieldKakaopay => 'Tautan 송금코드 KakaoPay';

  @override
  String get fieldKakaopayHint =>
      'Di KakaoPay: 송금 → 송금코드 → salin tautan (https://qr.kakaopay.com/…)';

  @override
  String get fieldHolder => 'Pemilik rekening';

  @override
  String get fieldHolderHint => 'Nama persis seperti di rekening';

  @override
  String get fieldIban => 'IBAN';

  @override
  String get fieldIbanHint => 'mis. DE89 3704 0044 0532 0130 00';

  @override
  String get fieldBic => 'BIC (opsional)';

  @override
  String get fieldBicHint => '8 atau 11 karakter';

  @override
  String get fieldBank => 'Bank';

  @override
  String get fieldBankHint => 'mis. 신한은행, Toss Bank';

  @override
  String get fieldAccountNumber => 'Nomor rekening';

  @override
  String get fieldAccountNumberHint => 'Angka, tanda hubung opsional';

  @override
  String amountCopied(String amount) {
    return 'Jumlah disalin: $amount';
  }

  @override
  String couldNotOpen(String link) {
    return 'Tidak bisa membuka $link';
  }

  @override
  String get payOffline => 'Offline: cara bayar tidak tersedia';

  @override
  String get payLoading => 'Memuat cara bayar…';

  @override
  String payAskToAdd(String name) {
    return 'Minta $name menambahkan cara menerima uang';
  }

  @override
  String payTitle(String name, String amount) {
    return 'Bayar $amount ke $name';
  }

  @override
  String get payScanQr => 'Pindai dengan aplikasi bank Anda (QR SEPA)';

  @override
  String get payQrEurOnly => 'Kode QR hanya tersedia untuk transfer dalam EUR.';

  @override
  String get bankLabel => 'Bank';

  @override
  String get ibanLabel => 'IBAN';

  @override
  String get accountLabel => 'Rekening';

  @override
  String get bicLabel => 'BIC';

  @override
  String get holderLabel => 'Pemilik';

  @override
  String get amountLabel => 'Jumlah';

  @override
  String get copyIban => 'Salin IBAN';

  @override
  String get copyAccount => 'Salin rekening';

  @override
  String get copyAmount => 'Salin jumlah';

  @override
  String get ibanCopied => 'IBAN disalin';

  @override
  String get accountCopied => 'Rekening disalin';

  @override
  String get paymentUpdated => 'Pembayaran diperbarui';

  @override
  String paymentRecordedPending(String amount, String name) {
    return '$amount dicatat. $name akan mengonfirmasi.';
  }

  @override
  String paymentRecordedPendingUnnamed(String amount) {
    return '$amount dicatat. Orang tersebut akan mengonfirmasi.';
  }

  @override
  String paymentRecorded(String amount) {
    return 'Pembayaran $amount dicatat';
  }

  @override
  String youSuffix(String name) {
    return '$name (Anda)';
  }

  @override
  String get recordPayment => 'Catat pembayaran';

  @override
  String get editPayment => 'Edit pembayaran';

  @override
  String get fromLabel => 'Dari';

  @override
  String get toLabel => 'Ke';

  @override
  String get swap => 'Tukar';

  @override
  String get pickTwoPeople => 'Pilih dua orang yang berbeda';

  @override
  String get commentsStayOld => 'Komentar tetap di pembayaran lama';

  @override
  String get recordPaymentButton => 'Catat pembayaran';

  @override
  String get paymentNotHere => 'Pembayaran ini tidak ada di perangkat ini';

  @override
  String get notSyncedOrLeft =>
      'Belum tersinkron, atau Anda sudah keluar dari grupnya.';

  @override
  String get someone => 'Seseorang';

  @override
  String get paymentEdited => 'Pembayaran yang diedit';

  @override
  String get paymentDeleted => 'Pembayaran yang dihapus';

  @override
  String get payment => 'Pembayaran';

  @override
  String get paymentWasEdited => 'Pembayaran ini sudah diedit';

  @override
  String get paymentWasEditedNote =>
      'Yang dihitung adalah pembayaran hasil edit. Komentarnya tetap di sini.';

  @override
  String get paymentWasDeleted => 'Pembayaran ini sudah dihapus';

  @override
  String get paymentNotCounted => 'Tidak dihitung dalam saldo.';

  @override
  String get restore => 'Pulihkan';

  @override
  String youPaidName(String name) {
    return 'Anda membayar $name';
  }

  @override
  String namePaidYou(String name) {
    return '$name membayar Anda';
  }

  @override
  String namePaidName(String from, String to) {
    return '$from membayar $to';
  }

  @override
  String paymentSaysSent(String name) {
    return '$name bilang sudah mengirim ini. Sudah sampai?';
  }

  @override
  String waitingForConfirm(String name) {
    return 'Menunggu konfirmasi dari $name';
  }

  @override
  String get notReceived => 'Tidak diterima';

  @override
  String get confirmReceived => 'Konfirmasi diterima';

  @override
  String get deletePaymentTitle => 'Hapus pembayaran?';

  @override
  String get deletePaymentMessage => 'Utang yang dilunasinya kembali lagi.';

  @override
  String get paymentDeletedSnack => 'Pembayaran dihapus';

  @override
  String get notReceivedTitle => 'Tidak diterima?';

  @override
  String notReceivedMessage(String name) {
    return 'Pembayaran dari $name dihapus dan utangnya kembali lagi.';
  }

  @override
  String get paymentRemovedSnack => 'Pembayaran dihapus';

  @override
  String get recordAPayment => 'Catat pembayaran';

  @override
  String get nothingToSettle => 'Tidak ada yang perlu dilunasi';

  @override
  String get everyoneEven => 'Semua sudah impas.';

  @override
  String get waitingForConfirmation => 'Menunggu konfirmasi';

  @override
  String get debtsAsRecorded =>
      'Utang sesuai catatan · sederhanakan utang nonaktif';

  @override
  String transfersSettleEverything(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transfer melunasi semuanya',
    );
    return '$_temp0';
  }

  @override
  String transfersSettleBalance(int count, String currency) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transfer melunasi saldo $currency',
    );
    return '$_temp0';
  }

  @override
  String notConvertedSettlesIn(String currency) {
    return 'Belum dikonversi · $currency · dilunasi dalam $currency';
  }

  @override
  String get convert => 'Konversi';

  @override
  String get settleUp => 'Lunasi';

  @override
  String saysTheySent(String name, String amount) {
    return '$name bilang sudah mengirim $amount';
  }

  @override
  String waitingToConfirmAmount(String name, String amount) {
    return 'Menunggu $name mengonfirmasi $amount';
  }

  @override
  String get you => 'Anda';

  @override
  String get request => 'Tagih';

  @override
  String get iveSentIt => 'Sudah saya kirim';

  @override
  String get markAsPaid => 'Tandai sudah dibayar';

  @override
  String markedAsSent(String name) {
    return 'Ditandai terkirim. $name akan mengonfirmasi.';
  }

  @override
  String approx(String amount) {
    return '≈ $amount';
  }

  @override
  String friendOwesYou(String name, String amount) {
    return '$name berutang $amount kepada Anda';
  }

  @override
  String friendYouOwe(String name, String amount) {
    return 'Anda berutang $amount pada $name';
  }

  @override
  String friendYouOweLine(String name, String amount) {
    return 'Anda berutang $amount pada $name';
  }

  @override
  String noSharedGroup(String name) {
    return 'Anda tidak lagi satu grup dengan $name. Kirim tautan pertemanan Anda untuk menambah pengeluaran.';
  }

  @override
  String get shareFriendLink => 'Bagikan tautan pertemanan';

  @override
  String firstExpenseNeedsConnection(String name) {
    return 'Pengeluaran pertama dengan $name butuh koneksi.';
  }

  @override
  String reminderSent(String name) {
    return 'Pengingat dikirim ke $name';
  }

  @override
  String remindTomorrow(String name) {
    return 'Anda bisa mengingatkan $name lagi besok';
  }

  @override
  String remindNothingOwed(String name) {
    return '$name tidak berutang apa pun kepada Anda';
  }

  @override
  String get remindNeedsConnection => 'Mengirim pengingat butuh koneksi.';

  @override
  String amountsAnd(String a, String b) {
    return '$a dan $b';
  }

  @override
  String inviteFriendText(String link) {
    return 'Saya menambahkan Anda di Evensies supaya kita bisa berbagi pengeluaran. Gabung: $link';
  }

  @override
  String get personNotHere => 'Orang ini tidak ada di perangkat ini';

  @override
  String get personNotHereNote =>
      'Belum tersinkron, atau kalian sudah tidak satu grup lagi.';

  @override
  String get more => 'Lainnya';

  @override
  String get exportNonGroupCsv => 'Ekspor pengeluaran di luar grup (CSV)';

  @override
  String get exportNonGroupJson => 'Ekspor pengeluaran di luar grup (JSON)';

  @override
  String get exportNonGroupZip =>
      'Ekspor pengeluaran di luar grup (ZIP beserta struk)';

  @override
  String get notOnEvensies => 'Belum di Evensies';

  @override
  String get allSettledUp => 'Semua sudah lunas';

  @override
  String get remind => 'Ingatkan';

  @override
  String get invite => 'Undang';

  @override
  String get balances => 'Saldo';

  @override
  String get expensesAndPayments => 'Pengeluaran dan pembayaran';

  @override
  String get nothingTogetherYet =>
      'Belum ada apa-apa bersama. Tambahkan pengeluaran di bawah.';

  @override
  String get addExpense => 'Tambah pengeluaran';

  @override
  String personOwesYou(String amount) {
    return 'berutang $amount kepada Anda';
  }

  @override
  String personYouOwe(String amount) {
    return 'Anda berutang $amount';
  }

  @override
  String get personSettledUp => 'lunas';

  @override
  String recordedInGroups(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dicatat di $count grup',
    );
    return '$_temp0';
  }

  @override
  String get markAsReceived => 'Tandai sudah diterima';

  @override
  String get clearBothSides => 'Impaskan kedua sisi';

  @override
  String evenIn(String currency) {
    return 'Impas dalam $currency';
  }

  @override
  String linePayThem(String group, String name, String amount) {
    return '$group: Anda bayar $name $amount';
  }

  @override
  String lineTheyPay(String group, String name, String amount) {
    return '$group: $name bayar Anda $amount';
  }

  @override
  String get noMoneyMoves =>
      'Tidak ada uang yang berpindah: kedua sisi dicatat sebagai lunas.';

  @override
  String convertIn(String group) {
    return 'Konversi di $group';
  }

  @override
  String settleUpWith(String name) {
    return 'Lunasi dengan $name';
  }

  @override
  String nothingToSettleWith(String name) {
    return 'Tidak ada yang perlu dilunasi dengan $name';
  }

  @override
  String settleWithIntro(String name) {
    return 'Semua antara Anda dan $name, per mata uang. Mencatat menambahkan satu pembayaran di setiap grup.';
  }

  @override
  String get searchFriendsGroups => 'Cari teman dan grup';

  @override
  String get friends => 'Teman';

  @override
  String get groups => 'Grup';

  @override
  String get noFriendsOrGroups => 'Belum ada teman atau grup.';

  @override
  String nothingMatches(String query) {
    return 'Tidak ada yang cocok dengan “$query”.';
  }

  @override
  String get addExpenseWithWhom => 'Tambah pengeluaran · dengan siapa?';

  @override
  String friendLinkShare(String link, String code) {
    return 'Tambahkan saya di Evensies untuk berbagi pengeluaran: $link\nAtau masukkan kode saya $code';
  }

  @override
  String get friendLinkNeedsConnection =>
      'Membagikan tautan pertemanan butuh koneksi.';

  @override
  String get selfFriend => 'Itu kode Anda sendiri';

  @override
  String get noOneForCode => 'Tidak ada yang ditemukan dengan kode ini';

  @override
  String get addFriendNeedsConnection => 'Menambah teman butuh koneksi.';

  @override
  String get newFriendCodeTitle => 'Buat kode pertemanan baru?';

  @override
  String get newFriendCodeMessage =>
      'Tautan dan kode Anda yang sekarang tidak akan berlaku lagi. Teman yang sudah ada tetap.';

  @override
  String get newCode => 'Kode baru';

  @override
  String get addAFriend => 'Tambah teman';

  @override
  String get friendLinkOffline => 'Tautan pertemanan Anda butuh koneksi';

  @override
  String get yourFriendCode => 'Kode pertemanan Anda';

  @override
  String get friendQrLabel => 'Kode QR tautan pertemanan Anda';

  @override
  String get friendCodeHelp =>
      'Teman memindainya, membuka tautan, atau mengetik kodenya.';

  @override
  String get shareLink => 'Bagikan tautan';

  @override
  String get codeCopied => 'Kode disalin';

  @override
  String get copyCode => 'Salin kode';

  @override
  String get haveFriendCode => 'Punya kode teman?';

  @override
  String get onEvensies => 'di Evensies';

  @override
  String get notOnEvensiesSection => 'Seseorang yang belum di Evensies';

  @override
  String get notOnEvensiesHelp =>
      'Tambahkan pengeluaran dengannya sekarang, dan undang nanti.';

  @override
  String atMostChars(int max) {
    return 'Maksimal $max karakter';
  }

  @override
  String addName(String name) {
    return 'Tambah $name';
  }

  @override
  String get search => 'Cari';

  @override
  String get activity => 'Aktivitas';

  @override
  String get newGroup => 'Grup baru';

  @override
  String get joinWithCode => 'Gabung dengan kode';

  @override
  String get filterAll => 'Semua';

  @override
  String get filterOwesMe => 'Berutang kepada saya';

  @override
  String get filterIOwe => 'Saya berutang';

  @override
  String settledUpCount(int count) {
    return 'Lunas ($count)';
  }

  @override
  String get nobodyOwesYou => 'Tidak ada yang berutang kepada Anda';

  @override
  String get youOweNothing => 'Anda tidak berutang apa pun';

  @override
  String get nothingHereYet => 'Belum ada apa-apa di sini';

  @override
  String get noFriendsYet => 'Belum ada teman';

  @override
  String get noFriendsHelp =>
      'Tambahkan teman untuk berbagi pengeluaran di luar grup. Orang yang satu grup dengan Anda juga muncul di sini.';

  @override
  String get allSettledUpYou => 'Semua urusan Anda sudah lunas';

  @override
  String youAreOwedList(String amounts) {
    return 'Anda dapat $amounts';
  }

  @override
  String youOweList(String amounts) {
    return 'Anda berutang $amounts';
  }

  @override
  String get notOnEvensiesLower => 'belum di Evensies';

  @override
  String get noGroupsYet => 'Belum ada grup';

  @override
  String get noGroupsHelp =>
      'Buat grup untuk perjalanan atau rumah bersama, atau gabung ke grup teman dengan kode undangannya.';

  @override
  String get createGroup => 'Buat grup';

  @override
  String get settledUp => 'Lunas';

  @override
  String netApprox(String amount) {
    return 'Bersih ≈ $amount';
  }

  @override
  String memberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count anggota',
    );
    return '$_temp0';
  }

  @override
  String youOweAmount(String amount) {
    return 'Anda berutang $amount';
  }

  @override
  String youAreOwedAmount(String amount) {
    return 'Anda dapat $amount';
  }

  @override
  String youOweAmountLine(String amount) {
    return 'Anda berutang $amount';
  }

  @override
  String youAreOwedAmountLine(String amount) {
    return 'Anda dapat $amount';
  }

  @override
  String get createGroupNeedsConnection => 'Membuat grup butuh koneksi.';

  @override
  String get groupName => 'Nama grup';

  @override
  String get yourNameInGroup => 'Nama Anda di grup ini';

  @override
  String get defaultCurrency => 'Mata uang bawaan';

  @override
  String get create => 'Buat';

  @override
  String get noGroupOrFriendForCode =>
      'Tidak ada grup atau teman dengan kode ini';

  @override
  String get joinNeedsConnection => 'Bergabung ke grup butuh koneksi.';

  @override
  String get enterACode => 'Masukkan kode';

  @override
  String get enterCodeHelp =>
      'Kode grup ada di grup → Anggota. Kode teman ada di tab Teman miliknya → Tambah teman.';

  @override
  String get pastedFromClipboard => 'Ditempel dari papan klip';

  @override
  String nameOnEvensies(String name) {
    return '$name · di Evensies';
  }

  @override
  String addAsFriend(String name) {
    return 'Tambahkan $name sebagai teman';
  }

  @override
  String addedYouAsFriend(String name) {
    return '$name menambahkan Anda sebagai teman';
  }

  @override
  String get someoneAddedYouAsFriend =>
      'Seseorang menambahkan Anda sebagai teman';

  @override
  String groupPreview(String name, String members) {
    return '$name · $members';
  }

  @override
  String get continueButton => 'Lanjutkan';

  @override
  String wantsToSplit(String name) {
    return '$name ingin berbagi pengeluaran dengan Anda';
  }

  @override
  String get joinGroup => 'Gabung ke grup';

  @override
  String get inviteInvalid => 'Tautan undangan ini sudah tidak berlaku';

  @override
  String inviteFailed(String reason) {
    return 'Tidak bisa membuka undangan ini: $reason';
  }

  @override
  String get friendInviteUsed => 'Undangan pertemanan ini sudah dipakai';

  @override
  String get joinToSeeShared =>
      'Gabung untuk melihat dan menambah pengeluaran bersama.';

  @override
  String imName(String name) {
    return 'Saya $name';
  }

  @override
  String get join => 'Gabung';

  @override
  String get whoAreYou => 'Anda siapa?';

  @override
  String get newMemberName => 'Nama anggota baru';

  @override
  String get insights => 'Statistik';

  @override
  String get membersInvite => 'Anggota & undangan';

  @override
  String get groupSettings => 'Pengaturan grup';

  @override
  String get expenses => 'Pengeluaran';

  @override
  String get expenseFab => 'Pengeluaran';

  @override
  String get groupNotHere => 'Grup ini tidak ada di perangkat ini';

  @override
  String get groupNotHereNote =>
      'Anda sudah keluar, seseorang mengeluarkan Anda, atau belum tersinkron.';

  @override
  String get backToGroups => 'Kembali ke grup';

  @override
  String get noExpensesYet => 'Belum ada pengeluaran';

  @override
  String get tapExpenseToAdd =>
      'Ketuk “Pengeluaran” untuk menambah yang pertama.';

  @override
  String tilePaidYou(String amount) {
    return 'Anda bayar $amount';
  }

  @override
  String tilePaidName(String name, String amount) {
    return '$name bayar $amount';
  }

  @override
  String tilePaidPeople(int count, String amount) {
    return '$count orang bayar $amount';
  }

  @override
  String get tileRefundYou => 'pengembalian untuk Anda';

  @override
  String tileRefundName(String name) {
    return 'pengembalian untuk $name';
  }

  @override
  String tileRefundPeople(int count) {
    return 'pengembalian untuk $count orang';
  }

  @override
  String get notInvolved => 'tidak terlibat';

  @override
  String get allYours => 'semuanya milik Anda';

  @override
  String get paidForYourself => 'Anda bayar untuk diri Anda sendiri';

  @override
  String youGetBack(String amount) {
    return 'Anda dapat kembali $amount';
  }

  @override
  String youLent(String amount) {
    return 'Anda meminjamkan $amount';
  }

  @override
  String youBorrowed(String amount) {
    return 'Anda meminjam $amount';
  }

  @override
  String get repeatsLabel => 'Berulang';

  @override
  String hasReceipt(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ada $count struk',
    );
    return '$_temp0';
  }

  @override
  String get refund => 'Pengembalian dana';

  @override
  String get notConverted => 'Belum dikonversi';

  @override
  String get pending => 'tertunda';

  @override
  String approxTotalOwe(String amount) {
    return 'Total Anda berutang ≈ $amount';
  }

  @override
  String approxTotalOwed(String amount) {
    return 'Total Anda dapat ≈ $amount';
  }

  @override
  String get approxTotalNote =>
      'Dalam mata uang utama Anda, dengan kurs terbaru';

  @override
  String nothingOwedIn(String currency) {
    return 'Tidak ada utang dalam $currency';
  }

  @override
  String get allSettled => 'Semua lunas';

  @override
  String get otherCurrenciesBelow =>
      'Pengeluaran dalam mata uang lain ada di bawah.';

  @override
  String get nobodyOwes => 'Tidak ada yang berutang.';

  @override
  String youPayNext(String amount) {
    return 'Anda sebaiknya bayar berikutnya (Anda berutang $amount, paling besar)';
  }

  @override
  String namePaysNext(String name, String amount) {
    return '$name sebaiknya bayar berikutnya (berutang $amount, paling besar)';
  }

  @override
  String settleUpWaiting(int count) {
    return 'Lunasi · $count menunggu';
  }

  @override
  String memberRemoved(String name) {
    return '$name (dikeluarkan)';
  }

  @override
  String expensesWithoutRate(int count, String currency) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pengeluaran tanpa kurs ke $currency',
    );
    return '$_temp0';
  }

  @override
  String expensesBadRate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pengeluaran dengan kurs yang tidak bisa dikonversi',
    );
    return '$_temp0';
  }

  @override
  String paymentsIn(String currency) {
    return 'Pembayaran dalam $currency';
  }

  @override
  String everyoneEvenIn(String currency) {
    return 'semua impas dalam $currency';
  }

  @override
  String convertTo(String currency) {
    return 'Konversi ke $currency';
  }

  @override
  String get balanceSettled => 'lunas';

  @override
  String get balanceGetsBack => 'dapat kembali';

  @override
  String get balanceOwes => 'berutang';

  @override
  String convertedCount(int count, String currency) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pengeluaran dikonversi ke $currency',
    );
    return '$_temp0';
  }

  @override
  String get noAutoRate => 'Tidak ada kurs otomatis. Masukkan satu.';

  @override
  String rateOf(String date) {
    return 'kurs $date';
  }

  @override
  String rateOfOffline(String date) {
    return 'offline · kurs $date';
  }

  @override
  String amountCountExpenses(String amount, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pengeluaran',
    );
    return '$amount · $_temp0';
  }

  @override
  String paymentsStayIn(String currency) {
    return 'Pembayaran dalam $currency tetap dalam $currency';
  }

  @override
  String rateLabel(String from, String to) {
    return 'Kurs: 1 $from dalam $to';
  }

  @override
  String get nothingLeftToConvert => 'Tidak ada lagi yang perlu dikonversi';

  @override
  String get lookingUpRate => 'Mencari kurs…';

  @override
  String get enterRateAbove0 => 'Masukkan kurs di atas 0';

  @override
  String convertExplain(String currency) {
    return 'Mengisi kurs ini di setiap pengeluaran yang belum punya, supaya dihitung dalam saldo $currency. Anda masih bisa mengubah kurs di setiap pengeluaran.';
  }

  @override
  String get nameField => 'Nama';

  @override
  String get cantChangeCurrency =>
      'Tidak bisa diubah setelah pengeluaran atau pembayaran pertama';

  @override
  String get currencyUsedFor => 'Dipakai untuk saldo dan pembayaran';

  @override
  String get splitting => 'Pembagian';

  @override
  String get simplifyDebts => 'Sederhanakan utang';

  @override
  String get simplifyDebtsHelp =>
      'Menggabungkan utang supaya grup butuh lebih sedikit pembayaran. Total tiap orang tidak berubah, hanya siapa membayar siapa.';

  @override
  String get defaultSplit => 'Pembagian bawaan';

  @override
  String get splitStale => 'Sudah tidak pas · ketuk untuk memperbaiki';

  @override
  String get membership => 'Keanggotaan';

  @override
  String get leaveGroup => 'Keluar dari grup';

  @override
  String get balanceSettledNote => 'Saldo Anda sudah lunas';

  @override
  String get renameGroup => 'Ganti nama grup';

  @override
  String leaveTitle(String name) {
    return 'Keluar dari “$name”?';
  }

  @override
  String get leaveMessage =>
      'Anda tidak akan melihat grup ini lagi. Pengeluaran Anda sebelumnya tetap ada pada anggota lain. Untuk kembali, minta kode undangan.';

  @override
  String get leave => 'Keluar';

  @override
  String youLeft(String name) {
    return 'Anda keluar dari “$name”';
  }

  @override
  String get splitEqualEveryone => 'Sama rata · semua orang';

  @override
  String splitPercentList(String list) {
    return 'Persen · $list';
  }

  @override
  String splitSharesList(String list) {
    return 'Bagian · $list';
  }

  @override
  String percentValue(String value) {
    return '$value%';
  }

  @override
  String get defaultSplitHelp =>
      'Pengeluaran baru dimulai dengan pembagian ini. Anda masih bisa mengubahnya di setiap pengeluaran.';

  @override
  String get useEqual => 'Pakai sama rata';

  @override
  String get inviteCode => 'Kode undangan';

  @override
  String get inviteQrLabel => 'Kode QR tautan undangan';

  @override
  String get inviteCodeHelp =>
      'Siapa pun yang punya kode ini bisa bergabung dan memilih namanya.';

  @override
  String inviteShareText(String group, String link, String code) {
    return 'Gabung ke grup saya “$group” di Evensies: $link\nAtau buka aplikasinya dan masukkan kode $code';
  }

  @override
  String get rotateCode => 'Ganti kode';

  @override
  String get members => 'Anggota';

  @override
  String get notJoinedYet => 'belum bergabung — bagikan kode undangan';

  @override
  String get linked => 'tertaut';

  @override
  String get addPlaceholder => 'Tambah anggota sementara';

  @override
  String removeMemberTitle(String name) {
    return 'Keluarkan $name?';
  }

  @override
  String get removeMemberMessage =>
      'Pengeluaran sebelumnya dan saldonya tetap di grup.';

  @override
  String removeMemberSeries(int count, String name, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$name masih ada di $count pengeluaran berulang ($names); bagian $name tetap sampai Anda mengedit yang terbaru.',
    );
    return '$_temp0';
  }

  @override
  String get addMember => 'Tambah anggota';

  @override
  String get rotateInviteTitle => 'Ganti kode undangan?';

  @override
  String get rotateInviteMessage =>
      'Kode dan tautan yang sekarang tidak berlaku lagi. Orang yang sudah bergabung tidak terpengaruh.';

  @override
  String get rotate => 'Ganti';

  @override
  String get newInviteReady => 'Kode undangan baru siap';

  @override
  String get activityNeedsConnection => 'Aktivitas butuh koneksi';

  @override
  String get activityOfflineNote =>
      'Perubahan terbaru muncul di sini saat Anda online lagi.';

  @override
  String get noActivityYet => 'Belum ada aktivitas';

  @override
  String get activityAllGroups => 'Perubahan di grup Anda muncul di sini.';

  @override
  String get activityThisGroup => 'Perubahan di grup ini muncul di sini.';

  @override
  String get showingSaved =>
      'Menampilkan aktivitas tersimpan. Tarik untuk memuat ulang.';

  @override
  String get loadMore => 'Muat lebih banyak';

  @override
  String get earlier => 'Sebelumnya';

  @override
  String get today => 'Hari ini';

  @override
  String get yesterday => 'Kemarin';

  @override
  String forDate(String date) {
    return 'untuk $date';
  }

  @override
  String get youCommented => 'Anda berkomentar';

  @override
  String nameCommented(String name) {
    return '$name berkomentar';
  }

  @override
  String restoredName(String name) {
    return '“$name” dipulihkan';
  }

  @override
  String get paymentRestored => 'Pembayaran dipulihkan';

  @override
  String get expenseNotHere => 'Pengeluaran ini tidak ada di perangkat ini';

  @override
  String get deletedExpense => 'Pengeluaran yang dihapus';

  @override
  String get expense => 'Pengeluaran';

  @override
  String seriesRepeats(String frequency) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Berulang setiap minggu',
      'biweekly': 'Berulang setiap 2 minggu',
      'monthly': 'Berulang setiap bulan',
      'yearly': 'Berulang setiap tahun',
      'other': 'Berulang',
    });
    return '$_temp0';
  }

  @override
  String seriesRepeatsNext(String frequency, String date) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Berulang setiap minggu · berikutnya $date',
      'biweekly': 'Berulang setiap 2 minggu · berikutnya $date',
      'monthly': 'Berulang setiap bulan · berikutnya $date',
      'yearly': 'Berulang setiap tahun · berikutnya $date',
      'other': 'Berulang · berikutnya $date',
    });
    return '$_temp0';
  }

  @override
  String seriesRepeatsNextAmount(String frequency, String amount, String date) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'Berulang setiap minggu · berikutnya $amount pada $date',
      'biweekly': 'Berulang setiap 2 minggu · berikutnya $amount pada $date',
      'monthly': 'Berulang setiap bulan · berikutnya $amount pada $date',
      'yearly': 'Berulang setiap tahun · berikutnya $amount pada $date',
      'other': 'Berulang · berikutnya $amount pada $date',
    });
    return '$_temp0';
  }

  @override
  String rateLine(String from, String rate, String to) {
    return 'Kurs: 1 $from = $rate $to';
  }

  @override
  String notConvertedTo(String currency) {
    return 'Belum dikonversi ke $currency';
  }

  @override
  String get receivedSplitBack => 'Diterima dan dibagi kembali';

  @override
  String get whoPaidOwes => 'Siapa yang bayar dan siapa yang berutang';

  @override
  String get items => 'Item';

  @override
  String get notes => 'Catatan';

  @override
  String get receipts => 'Struk';

  @override
  String get history => 'Riwayat';

  @override
  String get deleteExpenseTitle => 'Hapus pengeluaran?';

  @override
  String get deleteExpenseMessage =>
      'Pengeluaran dihapus untuk semua orang di grup. Anda bisa memulihkannya dari Aktivitas.';

  @override
  String get deleteRepeatingTitle => 'Hapus pengeluaran berulang?';

  @override
  String get deleteRepeatingMessage =>
      'Pengeluaran dihapus untuk semua orang di grup. Anda bisa memulihkannya dari Aktivitas, tapi seri yang sudah berhenti tidak bisa dimulai lagi. Pengulangan yang sudah ditambahkan tetap ada.';

  @override
  String get deleteThisOne => 'Hapus yang ini saja';

  @override
  String get deleteAndStop => 'Hapus dan hentikan pengulangan';

  @override
  String deletedAndStopped(String name) {
    return '“$name” dihapus dan tidak berulang lagi';
  }

  @override
  String deletedName(String name) {
    return '“$name” dihapus';
  }

  @override
  String get movedToOtherGroup => 'Dipindahkan ke grup lain';

  @override
  String get movedNote =>
      'Sekarang dihitung di sana. Komentar dan riwayatnya tetap di sini.';

  @override
  String get expenseWasDeleted => 'Pengeluaran ini sudah dihapus';

  @override
  String get restoreToCount => 'Pulihkan supaya dihitung lagi dalam saldo.';

  @override
  String get tax => 'Pajak';

  @override
  String get tipService => 'Tip atau layanan';

  @override
  String get discount => 'Diskon';

  @override
  String youPaidOwe(String paid, String owe) {
    return 'Anda bayar $paid dan berutang $owe';
  }

  @override
  String youPaid(String amount) {
    return 'Anda bayar $amount';
  }

  @override
  String youOwe(String amount) {
    return 'Anda berutang $amount';
  }

  @override
  String namePaidOwes(String name, String paid, String owe) {
    return '$name bayar $paid dan berutang $owe';
  }

  @override
  String namePaid(String name, String amount) {
    return '$name bayar $amount';
  }

  @override
  String nameOwes(String name, String amount) {
    return '$name berutang $amount';
  }

  @override
  String youReceivedGetBack(String received, String back) {
    return 'Anda menerima $received dan dapat kembali $back';
  }

  @override
  String youReceived(String amount) {
    return 'Anda menerima $amount';
  }

  @override
  String youGetBackLine(String amount) {
    return 'Anda dapat kembali $amount';
  }

  @override
  String nameReceivedGetsBack(String name, String received, String back) {
    return '$name menerima $received dan dapat kembali $back';
  }

  @override
  String nameReceived(String name, String amount) {
    return '$name menerima $amount';
  }

  @override
  String nameGetsBack(String name, String amount) {
    return '$name dapat kembali $amount';
  }

  @override
  String get noHistoryYet => 'Belum ada riwayat.';

  @override
  String get historyOffline => 'Riwayat muncul di sini saat Anda online.';

  @override
  String get showingSavedHistory => 'Menampilkan riwayat tersimpan.';

  @override
  String get showMore => 'Tampilkan lebih banyak';

  @override
  String get deleteCommentTitle => 'Hapus komentar?';

  @override
  String get comments => 'Komentar';

  @override
  String get noCommentsYet => 'Belum ada komentar.';

  @override
  String get deleteComment => 'Hapus komentar';

  @override
  String get addComment => 'Tulis komentar';

  @override
  String get send => 'Kirim';

  @override
  String get filterByCategory => 'Saring menurut kategori';

  @override
  String get category => 'Kategori';

  @override
  String get categoryAll => 'Semua';

  @override
  String get month => 'Bulan';

  @override
  String get searchUnavailable => 'Pencarian tidak tersedia';

  @override
  String get searchExpenses => 'Cari pengeluaran';

  @override
  String get searchHelp =>
      'Deskripsi, catatan, komentar, kategori, dan jumlah: “taksi”, “bandara”, “12,50”.';

  @override
  String get noMatches => 'Tidak ada hasil';

  @override
  String get noMatchesHelp => 'Coba kata lain, atau hapus saringan.';

  @override
  String expenseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pengeluaran',
    );
    return '$_temp0';
  }

  @override
  String get searchAllGroups => 'Cari di semua grup';

  @override
  String searchGroup(String name) {
    return 'Cari di $name';
  }

  @override
  String get searchThisGroup => 'Cari di grup ini';

  @override
  String get clear => 'Hapus';

  @override
  String get thisGroup => 'Grup ini';

  @override
  String insightsError(String reason) {
    return 'Statistik tidak bisa ditampilkan: $reason';
  }

  @override
  String get nothingToShow => 'Belum ada yang bisa ditampilkan';

  @override
  String get insightsEmptyHelp =>
      'Total dan grafik muncul setelah grup punya pengeluaran.';

  @override
  String get allTime => 'Sepanjang waktu';

  @override
  String get shareSummary => 'Bagikan ringkasan';

  @override
  String get printSummary => 'Cetak ringkasan';

  @override
  String get previousMonth => 'Bulan sebelumnya';

  @override
  String get nextMonth => 'Bulan berikutnya';

  @override
  String get byMonth => 'Per bulan';

  @override
  String get groupSegment => 'Grup';

  @override
  String get mineSegment => 'Milik saya';

  @override
  String get byCategory => 'Per kategori';

  @override
  String get noExpensesPeriod => 'Tidak ada pengeluaran pada periode ini.';

  @override
  String get byPerson => 'Per orang';

  @override
  String get nobodyPaidPeriod =>
      'Tidak ada yang membayar atau berutang pada periode ini.';

  @override
  String keptUntilConverted(String currency, String group) {
    return 'Tetap dalam $currency sampai dikonversi ke $group.';
  }

  @override
  String get totalSpent => 'Total dibelanjakan';

  @override
  String get yourShare => 'Bagian Anda';

  @override
  String get paymentsMade => 'Pembayaran dikirim';

  @override
  String get paymentsReceived => 'Pembayaran diterima';

  @override
  String get youPaidRow => 'Anda bayar';

  @override
  String get balanceChange => 'Perubahan saldo Anda';

  @override
  String get paidLegend => 'Dibayar';

  @override
  String get shareLegend => 'Bagian';

  @override
  String paidShareLine(String paid, String share) {
    return 'bayar $paid · bagian $share';
  }

  @override
  String get itemsGiveEveryone => 'Tetapkan orang untuk setiap item';

  @override
  String get itemsAddPrices => 'Isi harga item sebelum pajak atau tip';

  @override
  String get itemsDiscountTooBig => 'Diskonnya lebih besar dari tagihan';

  @override
  String get itemsDontAddUp => 'Item-itemnya tidak pas';

  @override
  String get adjustmentsDontFit => 'Penyesuaiannya tidak muat dalam total';

  @override
  String get giveSomeoneShare => 'Beri seseorang bagian';

  @override
  String get checkNumbers => 'Periksa angkanya';

  @override
  String get splitDoesntAddUp => 'Pembagiannya tidak pas';

  @override
  String get addTheItems => 'Tambahkan item-itemnya';

  @override
  String get pickOnePerson => 'Pilih setidaknya satu orang';

  @override
  String splitEquallyBetween(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dibagi rata untuk $count orang',
    );
    return '$_temp0';
  }

  @override
  String get allForOnePerson => 'Semua untuk 1 orang';

  @override
  String splitEquallyEach(int count, String amount) {
    return 'Dibagi rata untuk $count orang · masing-masing $amount';
  }

  @override
  String get checkAmounts => 'Periksa jumlahnya';

  @override
  String get enterTotalFirst => 'Masukkan totalnya dulu';

  @override
  String remaining(String amount) {
    return 'sisa: $amount';
  }

  @override
  String overBy(String amount) {
    return 'lebih: $amount';
  }

  @override
  String get addsUp => 'Sudah pas';

  @override
  String sharesInTotal(String count) {
    return 'Total $count bagian';
  }

  @override
  String get oneShareInTotal => 'Total 1 bagian';

  @override
  String get restSplitEqually => 'Sisanya dibagi rata';

  @override
  String get byPercent => 'Menurut persen';

  @override
  String get byShares => 'Menurut bagian';

  @override
  String get byAdjustment =>
      'Sesuaikan: lebih atau kurang untuk seseorang, sisanya rata';

  @override
  String get modeEqual => 'Rata';

  @override
  String get modeExact => 'Pas';

  @override
  String get modeShares => 'Bagian';

  @override
  String get byItem => 'Per item, dari struk';

  @override
  String get adjustmentHelp =>
      'Tambah atau kurangi jumlah untuk seseorang; sisanya dibagi rata.';

  @override
  String get noMembers => 'Tidak ada anggota';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count item',
    );
    return '$_temp0';
  }

  @override
  String get addAnItem => 'Tambahkan item';

  @override
  String atMostItems(int max) {
    return 'Maksimal $max item';
  }

  @override
  String get giveItemName => 'Beri nama setiap item';

  @override
  String get itemNameTooLong => 'Nama item terlalu panjang';

  @override
  String get addItem => 'Tambah item';

  @override
  String get giveRestToEveryone => 'Beri sisanya ke semua orang';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get total => 'Total';

  @override
  String receiptSays(String printed, String difference) {
    return 'Struk menunjukkan $printed · item berbeda $difference';
  }

  @override
  String get eachPerson => 'Per orang';

  @override
  String itemsWithoutPerson(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count item tanpa orang',
    );
    return '$_temp0';
  }

  @override
  String get itemHint => 'Item';

  @override
  String memberLeft(String name) {
    return '$name (keluar)';
  }

  @override
  String get whoHadThis => 'Siapa yang pesan ini?';

  @override
  String get defaultSplitStartsEqual =>
      'Pembagian bawaan grup sudah tidak pas, jadi ini dimulai sama rata';

  @override
  String leftToAssign(String amount) {
    return 'Sisa $amount untuk dibagikan';
  }

  @override
  String get itemsTotal => 'Total item';

  @override
  String get newExpense => 'Pengeluaran baru';

  @override
  String get editExpense => 'Edit pengeluaran';

  @override
  String get scanReceipt => 'Pindai struk';

  @override
  String get rateAboveZeroOrEmpty =>
      'Masukkan kurs di atas 0, atau biarkan kosong';

  @override
  String useAutoRate(String rate, String source) {
    return 'Pakai kurs otomatis: $rate ($source)';
  }

  @override
  String get description => 'Deskripsi';

  @override
  String get receivedBy => 'Diterima oleh';

  @override
  String get paidBy => 'Dibayar oleh';

  @override
  String get severalPeople => 'Beberapa orang';

  @override
  String get when => 'Kapan';

  @override
  String get refundTooltip =>
      'Uang yang kembali, mis. deposit yang dikembalikan hotel';

  @override
  String get splitBackTo => 'Dibagi kembali ke';

  @override
  String get split => 'Pembagian';

  @override
  String theyOweFull(String name) {
    return '$name berutang seluruhnya';
  }

  @override
  String iOweFull(String name) {
    return 'Saya berutang seluruhnya pada $name';
  }

  @override
  String get repeat => 'Ulangi';

  @override
  String editLatestRepeat(String date) {
    return 'Untuk mengubah pengulangan berikutnya, edit yang terbaru ($date)';
  }

  @override
  String get stopsRepeating =>
      'Berhenti berulang. Pengulangan yang sudah ditambahkan tetap ada.';

  @override
  String nextRepeat(String date) {
    return 'Berikutnya: $date';
  }

  @override
  String get alsoChangeFuture => 'Ubah juga pengulangan berikutnya';

  @override
  String get futureFields =>
      'Jumlah, pembagian, pembayar, deskripsi, kategori, dan catatan';

  @override
  String get onlyThisOne => 'Hanya yang ini yang berubah';

  @override
  String get addPhoto => 'Tambah foto';

  @override
  String maxReceiptsNote(int max) {
    return 'Maksimal $max struk untuk satu pengeluaran';
  }

  @override
  String get scanAReceipt => 'Pindai struk';

  @override
  String receiptLooksLike(String currency) {
    return 'Struk ini sepertinya dalam $currency';
  }

  @override
  String switchToCurrencyQuestion(String currency) {
    return 'Ganti pengeluaran ke $currency untuk membaca item-itemnya?';
  }

  @override
  String switchTo(String currency) {
    return 'Ganti ke $currency';
  }

  @override
  String get couldntReadItems => 'Item tidak terbaca. Ketik secara manual.';

  @override
  String withName(String name) {
    return 'Dengan $name';
  }

  @override
  String movesTo(String name) {
    return 'Pindah ke $name saat disimpan';
  }

  @override
  String fromName(String name) {
    return 'Dari $name';
  }

  @override
  String get dontMove => 'Jangan pindahkan';

  @override
  String get onlyLinkedMove =>
      'Hanya orang di Evensies yang ada di keduanya yang bisa dipindahkan';

  @override
  String get auto => 'otomatis';

  @override
  String get noAutoRateForm =>
      'Tidak ada kurs otomatis. Masukkan satu, atau biarkan kosong agar tetap di “Belum dikonversi”.';

  @override
  String get emptyNotConverted => 'Kosong: tetap di “Belum dikonversi”';

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
  String get yourRate => 'kurs Anda';

  @override
  String get loginEmail => 'Lanjutkan dengan email';

  @override
  String get emailLoginTitle => 'Masuk dengan email';

  @override
  String get emailLoginIntro =>
      'Kami kirim kode 6 digit lewat email. Tanpa kata sandi.';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailInvalid => 'Masukkan alamat email yang valid';

  @override
  String get sendCode => 'Kirim kode';

  @override
  String codeSentTo(String email) {
    return 'Masukkan kode 6 digit yang kami kirim ke $email. Kode berlaku 10 menit.';
  }

  @override
  String get codeLabel => 'Kode 6 digit';

  @override
  String get verifyCode => 'Lanjutkan';

  @override
  String get resendCode => 'Kirim ulang kode';

  @override
  String resendCodeIn(int seconds) {
    return 'Kirim ulang dalam $seconds dtk';
  }

  @override
  String get codeResent => 'Kami sudah mengirim kode baru.';

  @override
  String get useDifferentEmail => 'Pakai email lain';

  @override
  String get codeCheckSpam => 'Belum masuk? Cek folder spam.';

  @override
  String get errorCodeInvalid =>
      'Kode salah atau sudah kedaluwarsa. Minta kode baru.';

  @override
  String get errorEmailNotConfigured => 'Server ini tidak mengirim email.';

  @override
  String get errorEmailRejected =>
      'Alamat itu tidak bisa menerima email. Periksa apakah ada salah ketik.';

  @override
  String get errorEmailTaken => 'Akun lain sudah memakai alamat ini.';

  @override
  String get errorEmailRequired =>
      'Email adalah satu-satunya cara Anda masuk, jadi tidak bisa dihapus.';

  @override
  String get errorEmailUnavailable =>
      'Email sedang tidak berfungsi. Coba lagi nanti.';

  @override
  String get emailSaved => 'Email disimpan';

  @override
  String removeEmailTitle(String email) {
    return 'Hapus $email?';
  }

  @override
  String get removeEmailMessage =>
      'Anda tidak akan menerima ringkasan atau pengingat lewat email lagi, dan tidak bisa masuk dengan alamat ini.';

  @override
  String get emailRemoved => 'Email dihapus';

  @override
  String get emailNeedsConnection => 'Mengganti email butuh koneksi.';

  @override
  String get emailBouncedNote =>
      'Email ke alamat ini terpental — ganti atau verifikasi lagi';

  @override
  String get emailVerifiedNote =>
      'Terverifikasi · anggota lain tidak pernah melihatnya';

  @override
  String get changeEmail => 'Ganti email';

  @override
  String get emailAccountHelp =>
      'Untuk masuk dan ringkasan lewat email. Kami kirim kode untuk memastikan alamat ini milik Anda. Anggota lain tidak pernah melihatnya.';

  @override
  String get removeEmail => 'Hapus email';

  @override
  String get addEmail => 'Tambah email';

  @override
  String get addEmailHint =>
      'Masuk dengannya dan dapatkan ringkasan lewat email';

  @override
  String unblockedName(String name) {
    return '$name tidak diblokir lagi';
  }

  @override
  String get blockNeedsConnection => 'Memblokir butuh koneksi.';

  @override
  String get blockedEmpty => 'Anda belum memblokir siapa pun.';

  @override
  String get blockedNeedsConnection => 'Daftar yang diblokir butuh koneksi';

  @override
  String get unblock => 'Buka blokir';

  @override
  String get blockedPeople => 'Orang yang diblokir';

  @override
  String get blockedHelp =>
      'Orang yang diblokir tidak bisa menambahkan Anda sebagai teman atau mengirim pengingat, dan perubahan mereka tidak memberi Anda notifikasi atau email. Grup bersama dan saldo tetap seperti semula.';

  @override
  String get deletedGroupsEmpty => 'Tidak ada grup yang dihapus';

  @override
  String get deletedGroupsHelp =>
      'Memulihkan grup mengembalikannya untuk semua orang, lengkap dengan isinya.';

  @override
  String get deletedGroups => 'Grup yang dihapus';

  @override
  String deletedGroupsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count grup bisa dipulihkan',
    );
    return '$_temp0';
  }

  @override
  String get exportNeedsConnection => 'Mengekspor butuh koneksi.';

  @override
  String get exportEverything => 'Ekspor semuanya (JSON)';

  @override
  String get exportEverythingHint =>
      'Profil, cara menerima pembayaran, pengaturan, dan semua grup, termasuk yang dihapus';

  @override
  String get emailSummary => 'Ringkasan email';

  @override
  String digestChoice(String choice) {
    String _temp0 = intl.Intl.selectLogic(choice, {
      'auto': 'Otomatis',
      'daily': 'Harian',
      'weekly': 'Mingguan',
      'monthly': 'Bulanan',
      'off': 'Mati',
      'other': 'Otomatis',
    });
    return '$_temp0';
  }

  @override
  String get digestAutoHelp =>
      'Harian jika perangkat Anda tidak bisa menampilkan notifikasi, selain itu bulanan';

  @override
  String get digestAutoDaily => 'Otomatis — harian, karena notifikasi mati';

  @override
  String get digestAutoMonthly =>
      'Otomatis — bulanan, karena perangkat Anda menerima notifikasi';

  @override
  String get digestNoEmail =>
      'Tambahkan email di Akun untuk menerima ringkasan';

  @override
  String get helpReportProblem => 'Laporkan masalah atau usulkan fitur';

  @override
  String get helpReportProblemHint => 'Di GitHub, bisa dilihat semua orang';

  @override
  String get helpContact => 'Email dukungan';

  @override
  String get privacyPolicy => 'Kebijakan privasi';

  @override
  String get helpFeedback => 'Bantuan & masukan';

  @override
  String get signOutEverywhere => 'Keluar di semua perangkat';

  @override
  String get signOutEverywhereTitle => 'Keluar di semua perangkat?';

  @override
  String get signOutEverywhereMessage =>
      'Semua ponsel dan browser yang masuk ke akun Anda akan keluar, termasuk yang ini. Grup Anda tetap ada di server.';

  @override
  String get signOutEverywhereOffline =>
      'Keluar di semua perangkat butuh koneksi.';

  @override
  String get deleteAccountExportTip => 'Tips: Ekspor semuanya dulu.';

  @override
  String get coverPhoto => 'Foto sampul';

  @override
  String get coverPhotoHint =>
      'Tampil di bagian atas grup dan di daftar. Hanya anggota yang bisa melihatnya.';

  @override
  String get removeCover => 'Hapus sampul';

  @override
  String get coverNeedsConnection => 'Mengganti sampul butuh koneksi.';

  @override
  String get coverTooMany =>
      'Terlalu sering mengganti sampul. Coba lagi dalam satu jam.';

  @override
  String get deleteGroup => 'Hapus grup';

  @override
  String get deleteGroupHint =>
      'Untuk semua orang · anggota mana pun bisa memulihkannya';

  @override
  String deleteGroupTitle(String name) {
    return 'Hapus “$name”?';
  }

  @override
  String get deleteGroupMessage =>
      'Dihapus untuk semua orang. Anggota mana pun bisa memulihkannya dari Pengaturan → Grup yang dihapus.';

  @override
  String groupDeletedName(String name) {
    return '“$name” dihapus';
  }

  @override
  String get groupDeletedBanner => 'Grup ini sudah dihapus';

  @override
  String get groupRestored => 'Grup dipulihkan';

  @override
  String get deleteFriend => 'Hapus teman';

  @override
  String deleteFriendTitle(String name) {
    return 'Hapus $name?';
  }

  @override
  String deleteFriendMessage(String name) {
    return 'Pengeluaran di luar grup Anda dengan $name dihapus untuk kalian berdua. Grup bersama tetap ada. Anda bisa memulihkannya dari Pengaturan → Grup yang dihapus, atau dengan menambahkan $name lagi.';
  }

  @override
  String friendDeleted(String name) {
    return '$name dihapus';
  }

  @override
  String get block => 'Blokir';

  @override
  String blockTitle(String name) {
    return 'Blokir $name?';
  }

  @override
  String blockMessage(String name) {
    return '$name tidak akan bisa menambahkan Anda sebagai teman atau mengirim pengingat, dan perubahannya tidak akan memberi Anda notifikasi atau email. Grup bersama dan saldo tetap ada.';
  }

  @override
  String blockedName(String name) {
    return '$name diblokir';
  }

  @override
  String get report => 'Laporkan…';

  @override
  String get reportSubject => 'Laporan Evensies';

  @override
  String reportBody(String userId) {
    return 'ID pengguna: $userId\n\nApa yang terjadi:\n';
  }

  @override
  String get inviteByEmail => 'Undang lewat email…';

  @override
  String get inviteEmailField => 'Email (opsional)';

  @override
  String get inviteEmailHelp =>
      'Kami kirim tautan undangan lewat email. Hanya dipakai untuk undangan ini.';

  @override
  String inviteByEmailTitle(String name) {
    return 'Undang $name lewat email';
  }

  @override
  String inviteEmailSent(String email) {
    return 'Undangan dikirim ke $email';
  }

  @override
  String get inviteEmailOfflineAdded =>
      'Anggota ditambahkan. Mengundang lewat email butuh koneksi — coba lagi dari daftar anggota.';

  @override
  String get inviteEmailOffline => 'Mengundang lewat email butuh koneksi.';

  @override
  String get inviteEmailLimit =>
      'Batas email hari ini tercapai — bagikan tautannya saja.';

  @override
  String emailReminder(String choice) {
    return 'Pengingat email: $choice';
  }

  @override
  String get remindNever => 'Tidak pernah';

  @override
  String remindDaysBefore(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count hari sebelumnya',
    );
    return '$_temp0';
  }

  @override
  String get blurbUpi =>
      'India: Paytm, PhonePe, Google Pay, dan aplikasi UPI lainnya';

  @override
  String get fieldUpi => 'ID UPI';

  @override
  String get fieldUpiHint => 'Seperti nama@okicici';

  @override
  String get fieldUpiName => 'Nama (opsional)';

  @override
  String get fieldUpiNameHint => 'Ditampilkan kepada orang yang membayar Anda';

  @override
  String get methodErrorUpi => 'Masukkan ID UPI seperti nama@bank';

  @override
  String get noUpiApp =>
      'Aplikasi UPI tidak ditemukan. Salin ID UPI dan jumlahnya saja.';

  @override
  String get upiIdLabel => 'ID UPI';

  @override
  String get copyUpiId => 'Salin ID UPI';

  @override
  String get upiIdCopied => 'ID UPI disalin';

  @override
  String get dashboard => 'Dasbor';

  @override
  String get allExpenses => 'Semua pengeluaran';

  @override
  String get groupBalances => 'Saldo grup';

  @override
  String get yourBalance => 'Saldo Anda';

  @override
  String get dashboardOwesYou => 'Berutang kepada Anda';

  @override
  String get dashboardYouOwe => 'Anda berutang';

  @override
  String get historyAndComments => 'Riwayat dan komentar';

  @override
  String get showEarlier => 'Tampilkan sebelumnya';

  @override
  String get settleUpFirst => 'Lunasi dulu';

  @override
  String deleteFriendSettleFirst(String name) {
    return 'Kamu bisa menghapus $name dari teman setelah pengeluaran di luar grup kalian lunas.';
  }

  @override
  String get noMailApp =>
      'Aplikasi email tidak ditemukan. Salin detail di bawah dan kirim dari aplikasi email apa pun.';

  @override
  String get copyAddress => 'Salin alamat';

  @override
  String get copyMessage => 'Salin pesan';

  @override
  String get browserNoStorage =>
      'Browser ini tidak bisa menyimpan data Evensies. Coba browser lain, atau jendela yang bukan mode pribadi.';

  @override
  String get browserOtherTab =>
      'Evensies sudah terbuka di tab lain di browser ini. Gunakan tab itu, atau tutup lalu muat ulang tab ini.';
}
