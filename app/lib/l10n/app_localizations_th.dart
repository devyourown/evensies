// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get appTitle => 'Evensies';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get delete => 'ลบ';

  @override
  String get remove => 'นำออก';

  @override
  String get save => 'บันทึก';

  @override
  String get done => 'เสร็จสิ้น';

  @override
  String get undo => 'เลิกทำ';

  @override
  String get retry => 'ลองอีกครั้ง';

  @override
  String get ok => 'ตกลง';

  @override
  String get close => 'ปิด';

  @override
  String get edit => 'แก้ไข';

  @override
  String get add => 'เพิ่ม';

  @override
  String get offlineBanner => 'ออฟไลน์ — การเปลี่ยนแปลงจะซิงค์ภายหลัง';

  @override
  String get tooLong => 'ยาวเกินไป';

  @override
  String get allCurrencies => 'สกุลเงินทั้งหมด';

  @override
  String get errorUnexpected => 'เกิดข้อผิดพลาด โปรดลองอีกครั้ง';

  @override
  String get errorNetwork => 'คุณออฟไลน์อยู่ โปรดลองอีกครั้งภายหลัง';

  @override
  String get errorRateLimited =>
      'ลองหลายครั้งเกินไป โปรดรอหนึ่งนาทีแล้วลองอีกครั้ง';

  @override
  String get errorNotFound => 'สิ่งนี้ไม่มีอยู่แล้ว';

  @override
  String get errorForbidden => 'คุณไม่ได้รับอนุญาตให้ทำสิ่งนั้น';

  @override
  String get errorValidation => 'เซิร์ฟเวอร์ปฏิเสธ';

  @override
  String get errorSumMismatch => 'ยอดการแบ่งไม่ตรงกัน';

  @override
  String get errorPayersSumMismatch => 'ยอดของผู้จ่ายไม่ตรงกัน';

  @override
  String get errorNegativeAmount => 'มียอดเงินที่ต่ำกว่าศูนย์';

  @override
  String get errorNegativeShare => 'ส่วนของบางคนจะต่ำกว่าศูนย์';

  @override
  String get errorNegativeTotal => 'ยอดรวมจะต่ำกว่าศูนย์';

  @override
  String get errorZeroSubtotal => 'ใส่ราคารายการก่อนภาษี ทิป หรือส่วนลด';

  @override
  String get errorUnassignedItem => 'ทุกรายการต้องมีอย่างน้อยหนึ่งคน';

  @override
  String get errorNoMembers => 'เลือกอย่างน้อยหนึ่งคนที่จะหารด้วย';

  @override
  String get errorInvalidInput => 'ตรวจสอบตัวเลข';

  @override
  String get errorBadRate => 'อัตราแลกเปลี่ยนต้องมากกว่าศูนย์';

  @override
  String get errorUnknownMember => 'เกี่ยวข้องกับคนที่ไม่ได้อยู่ในกลุ่ม';

  @override
  String get errorUnknownCurrency => 'ไม่รองรับสกุลเงินนี้';

  @override
  String get errorMemberTaken => 'สมาชิกคนนี้ถูกเลือกไปแล้ว';

  @override
  String get errorLimitExceeded => 'ถึงขีดจำกัดแล้ว';

  @override
  String get errorTooLarge => 'รูปภาพใหญ่เกินไป';

  @override
  String get errorNotJpeg => 'เลือกรูปภาพ JPEG';

  @override
  String get errorFxUnavailable => 'ขณะนี้ไม่มีอัตราแลกเปลี่ยน';

  @override
  String get errorImportFailed => 'นำเข้าไฟล์นี้ไม่ได้';

  @override
  String get errorAuthNotConfigured =>
      'เซิร์ฟเวอร์นี้ไม่สามารถให้คุณลงชื่อเข้าใช้ด้วยวิธีนั้น';

  @override
  String get errorDuplicate => 'มีอยู่แล้ว';

  @override
  String errorGeneric(String code) {
    return 'เกิดข้อผิดพลาด ($code)';
  }

  @override
  String rejectedReceipt(String name, String reason) {
    return 'บันทึกใบเสร็จของ “$name” ไม่ได้: $reason';
  }

  @override
  String rejectedReceiptUnnamed(String reason) {
    return 'บันทึกใบเสร็จของรายจ่ายไม่ได้: $reason';
  }

  @override
  String rejectedReceiptRemove(String name, String reason) {
    return 'บันทึกการนำใบเสร็จออกจาก “$name” ไม่ได้: $reason';
  }

  @override
  String rejectedReceiptRemoveUnnamed(String reason) {
    return 'บันทึกการนำใบเสร็จออกจากรายจ่ายไม่ได้: $reason';
  }

  @override
  String rejectedRepeating(String name, String reason) {
    return 'บันทึกการทำซ้ำของ “$name” ไม่ได้: $reason';
  }

  @override
  String rejectedRepeatingUnnamed(String reason) {
    return 'บันทึกรายจ่ายที่ทำซ้ำไม่ได้: $reason';
  }

  @override
  String rejectedSeriesChange(String name, String reason) {
    return 'บันทึกการเปลี่ยนแปลง “$name” ครั้งต่อไปไม่ได้: $reason';
  }

  @override
  String rejectedSeriesChangeUnnamed(String reason) {
    return 'บันทึกการเปลี่ยนแปลงรายจ่ายที่ทำซ้ำไม่ได้: $reason';
  }

  @override
  String rejectedSeriesStop(String name, String reason) {
    return 'บันทึกการหยุดทำซ้ำ “$name” ไม่ได้: $reason';
  }

  @override
  String rejectedSeriesStopUnnamed(String reason) {
    return 'บันทึกการหยุดรายจ่ายที่ทำซ้ำไม่ได้: $reason';
  }

  @override
  String rejectedSavedNoRepeat(String name, String reason) {
    return 'บันทึก “$name” แล้วแต่จะไม่ทำซ้ำ: $reason';
  }

  @override
  String rejectedPaymentRestore(String reason) {
    return 'บันทึกการกู้คืนการชำระเงินไม่ได้: $reason';
  }

  @override
  String rejectedNewExpense(String name, String reason) {
    return 'บันทึกรายจ่ายใหม่ “$name” ไม่ได้: $reason';
  }

  @override
  String rejectedNewExpenseUnnamed(String reason) {
    return 'บันทึกรายจ่ายใหม่ไม่ได้: $reason';
  }

  @override
  String rejectedExpenseChange(String name, String reason) {
    return 'บันทึกการเปลี่ยนแปลง “$name” ไม่ได้: $reason';
  }

  @override
  String rejectedExpenseChangeUnnamed(String reason) {
    return 'บันทึกการเปลี่ยนแปลงรายจ่ายไม่ได้: $reason';
  }

  @override
  String rejectedExpenseDelete(String name, String reason) {
    return 'บันทึกการลบ “$name” ไม่ได้: $reason';
  }

  @override
  String rejectedExpenseDeleteUnnamed(String reason) {
    return 'บันทึกการลบรายจ่ายไม่ได้: $reason';
  }

  @override
  String rejectedExpenseRestore(String name, String reason) {
    return 'บันทึกการกู้คืน “$name” ไม่ได้: $reason';
  }

  @override
  String rejectedExpenseRestoreUnnamed(String reason) {
    return 'บันทึกการกู้คืนรายจ่ายไม่ได้: $reason';
  }

  @override
  String rejectedComment(String name, String reason) {
    return 'บันทึกความคิดเห็นใน “$name” ไม่ได้: $reason';
  }

  @override
  String rejectedCommentUnnamed(String reason) {
    return 'บันทึกความคิดเห็นในรายจ่ายไม่ได้: $reason';
  }

  @override
  String rejectedPaymentComment(String reason) {
    return 'บันทึกความคิดเห็นในการชำระเงินไม่ได้: $reason';
  }

  @override
  String rejectedCommentDelete(String reason) {
    return 'บันทึกการลบความคิดเห็นไม่ได้: $reason';
  }

  @override
  String rejectedPayment(String reason) {
    return 'บันทึกการชำระเงินไม่ได้: $reason';
  }

  @override
  String rejectedPaymentDelete(String reason) {
    return 'บันทึกการลบการชำระเงินไม่ได้: $reason';
  }

  @override
  String rejectedPaymentConfirm(String reason) {
    return 'บันทึกการยืนยันการชำระเงินไม่ได้: $reason';
  }

  @override
  String rejectedGroupSettings(String reason) {
    return 'บันทึกการเปลี่ยนการตั้งค่ากลุ่มไม่ได้: $reason';
  }

  @override
  String rejectedMemberAdd(String name, String reason) {
    return 'บันทึกการเพิ่ม $name ไม่ได้: $reason';
  }

  @override
  String rejectedMemberAddUnnamed(String reason) {
    return 'บันทึกการเพิ่มสมาชิกไม่ได้: $reason';
  }

  @override
  String rejectedMemberRemove(String reason) {
    return 'บันทึกการนำสมาชิกออกไม่ได้: $reason';
  }

  @override
  String rejectedOther(String reason) {
    return 'บันทึกการเปลี่ยนแปลงไม่ได้: $reason';
  }

  @override
  String get reasonReceiptLimit =>
      'รายจ่ายหนึ่งรายการมีใบเสร็จได้ไม่เกิน 10 ใบ';

  @override
  String get reasonSeriesLimit =>
      'กลุ่มหนึ่งมีรายจ่ายที่ทำซ้ำได้ไม่เกิน 100 รายการ';

  @override
  String get reasonNotUploaded => 'อัปโหลดรูปภาพไม่สำเร็จ';

  @override
  String get reasonSumMismatch => 'ยอดการแบ่งไม่ตรงกัน';

  @override
  String get reasonPayersSumMismatch => 'ยอดของผู้จ่ายไม่ตรงกัน';

  @override
  String get reasonNegativeAmount => 'มียอดเงินที่ต่ำกว่าศูนย์';

  @override
  String get reasonUnknownMember => 'เกี่ยวข้องกับคนที่ไม่ได้อยู่ในกลุ่ม';

  @override
  String get reasonUnknownCurrency => 'ไม่รองรับสกุลเงินนี้';

  @override
  String get reasonMemberTaken => 'สมาชิกคนนี้ถูกเลือกไปแล้ว';

  @override
  String get reasonGroupFull => 'กลุ่มเต็มแล้ว';

  @override
  String get reasonForbidden => 'คุณไม่ได้รับอนุญาตให้เปลี่ยนแปลงสิ่งนี้';

  @override
  String get reasonRefused => 'เซิร์ฟเวอร์ปฏิเสธ';

  @override
  String leaveOwe(String amount) {
    return 'คุณค้างจ่าย $amount · โปรดชำระก่อน';
  }

  @override
  String leaveOweIn(String amount, String currency) {
    return 'คุณค้างจ่าย $amount · โปรดชำระเป็น $currency ก่อน';
  }

  @override
  String leaveOwed(String amount) {
    return 'คุณยังต้องได้รับ $amount · โปรดชำระก่อน';
  }

  @override
  String leaveOwedIn(String amount, String currency) {
    return 'คุณยังต้องได้รับ $amount · โปรดชำระเป็น $currency ก่อน';
  }

  @override
  String leaveSeries(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'คุณยังอยู่ในรายจ่ายที่ทำซ้ำ $count รายการ ($names) · โปรดแก้ไขรายการล่าสุดหรือหยุดทำซ้ำก่อน',
    );
    return '$_temp0';
  }

  @override
  String seriesNamesMore(String names, int count) {
    return '$names และอีก $count รายการ';
  }

  @override
  String get seriesUnnamed => 'รายจ่าย';

  @override
  String get listJoiner => ', ';

  @override
  String get repeatNever => 'ไม่ทำซ้ำ';

  @override
  String get repeatWeekly => 'ทุกสัปดาห์';

  @override
  String get repeatBiweekly => 'ทุก 2 สัปดาห์';

  @override
  String get repeatMonthly => 'ทุกเดือน';

  @override
  String get repeatYearly => 'ทุกปี';

  @override
  String summaryNotConverted(String currency) {
    return 'ยังไม่แปลง · $currency';
  }

  @override
  String summaryTotalSpent(String amount) {
    return 'ใช้จ่ายทั้งหมด: $amount';
  }

  @override
  String summaryPaidShare(String paid, String share) {
    return 'คุณจ่าย: $paid · ส่วนของคุณ: $share';
  }

  @override
  String summaryPayments(String made, String received) {
    return 'ชำระไป: $made · ได้รับ: $received';
  }

  @override
  String summaryTopCategories(String list) {
    return 'หมวดหมู่ยอดนิยม: $list';
  }

  @override
  String get summaryBalancesToday => 'ยอดคงเหลือวันนี้';

  @override
  String summaryGetsBack(String name, String amount) {
    return '$name ได้คืน $amount';
  }

  @override
  String summaryOwes(String name, String amount) {
    return '$name ค้างจ่าย $amount';
  }

  @override
  String get summaryFooter => 'แชร์จาก Evensies';

  @override
  String get koreanBank => 'บัญชีธนาคารเกาหลี';

  @override
  String requestText(String amount, String group) {
    return 'คุณค้างจ่ายฉัน $amount สำหรับ $group ใน Evensies';
  }

  @override
  String requestTextWays(String amount, String group, String ways) {
    return 'คุณค้างจ่ายฉัน $amount สำหรับ $group ใน Evensies ชำระได้ทาง: $ways';
  }

  @override
  String get requestNoGroup => 'รายจ่ายที่เราใช้ร่วมกัน';

  @override
  String get leaveSyncing => 'กำลังซิงค์อยู่ โปรดลองอีกครั้งในอีกสักครู่';

  @override
  String get leaveOffline => 'ต้องออนไลน์จึงจะออกจากกลุ่มได้';

  @override
  String get moveOffline => 'ย้ายไม่ได้ โปรดลองอีกครั้งเมื่อออนไลน์';

  @override
  String moveFailed(String reason) {
    return 'ย้ายไม่ได้: $reason';
  }

  @override
  String get photoNoAccess =>
      'Evensies ไม่มีสิทธิ์เข้าถึง โปรดอนุญาตในแอปการตั้งค่า';

  @override
  String get photoNoCamera => 'เปิดกล้องไม่ได้';

  @override
  String get photoNoLibrary => 'เปิดคลังรูปภาพไม่ได้';

  @override
  String get photoUnusable => 'ใช้รูปภาพนี้ไม่ได้ โปรดลองรูปอื่น';

  @override
  String get methodErrorUsername =>
      'ตัวอักษร ตัวเลข . _ - เท่านั้น (สูงสุด 40)';

  @override
  String methodErrorLinkPrefix(String prefix) {
    return 'ต้องขึ้นต้นด้วย $prefix';
  }

  @override
  String get methodErrorTooLong => 'สูงสุด 200 อักขระ';

  @override
  String get methodErrorIban => 'IBAN ไม่ถูกต้อง';

  @override
  String get methodErrorHolder => 'ชื่อเจ้าของบัญชี (1–70 อักขระ)';

  @override
  String get methodErrorBic => 'BIC มี 8 หรือ 11 อักขระ';

  @override
  String get methodErrorKrAccount => 'ตัวเลขและขีด 8–20 หลัก';

  @override
  String get methodErrorBank => 'ชื่อธนาคาร (1–30 อักขระ)';

  @override
  String get methodErrorUnknownType => 'ประเภทที่ไม่รู้จัก';

  @override
  String get methodErrorTooMany =>
      'มีช่องทางรับเงินได้สูงสุด 8 ช่องทาง และธนาคารแต่ละประเภทได้ 3 ช่องทาง';

  @override
  String get bannerDismiss => 'ปิด';

  @override
  String get bannerView => 'ดู';

  @override
  String get loginTagline =>
      'หารค่าใช้จ่ายกับเพื่อน ไม่มีโฆษณา ไม่มีการขายเพิ่ม';

  @override
  String get loginApple => 'ดำเนินการต่อด้วย Apple';

  @override
  String get loginGoogle => 'ดำเนินการต่อด้วย Google';

  @override
  String get loginWebUnavailable =>
      'เซิร์ฟเวอร์นี้ยังไม่รองรับการลงชื่อเข้าใช้ในเบราว์เซอร์';

  @override
  String get welcomeTitle => 'ยินดีต้อนรับ';

  @override
  String get yourNameTitle => 'ชื่อของคุณ';

  @override
  String get nameQuestion => 'อยากให้เพื่อนเรียกคุณว่าอะไร';

  @override
  String get nameExplain => 'นี่คือชื่อที่สมาชิกคนอื่นเห็น';

  @override
  String get nameHelp =>
      'คนในกลุ่มของคุณจะเห็นชื่อนี้ คุณเปลี่ยนได้ภายหลังในการตั้งค่า';

  @override
  String get nameLabel => 'ชื่อ';

  @override
  String get lockReason => 'ปลดล็อก Evensies';

  @override
  String get lockTitle => 'Evensies ถูกล็อกอยู่';

  @override
  String get lockSubtitle =>
      'ปลดล็อกด้วย Face ID, Touch ID, ลายนิ้วมือ หรือรหัสผ่านของอุปกรณ์';

  @override
  String get lockUnlock => 'ปลดล็อก';

  @override
  String get lockSignOutConfirm =>
      'ออกจากระบบและลบข้อมูลในอุปกรณ์นี้หรือไม่ กลุ่มของคุณยังอยู่บนเซิร์ฟเวอร์';

  @override
  String get signOut => 'ออกจากระบบ';

  @override
  String get widgetOwed => 'คุณจะได้รับ';

  @override
  String get widgetOwe => 'คุณค้างจ่าย';

  @override
  String get widgetSignedOut => 'ลงชื่อเข้าใช้เพื่อดูยอดคงเหลือ';

  @override
  String get widgetSettled => 'ชำระครบแล้ว';

  @override
  String widgetUpdated(String time) {
    return 'อัปเดต $time';
  }

  @override
  String get receiptAdd => 'เพิ่มใบเสร็จ';

  @override
  String get photoTake => 'ถ่ายรูป';

  @override
  String get photoChoose => 'เลือกจากคลังรูปภาพ';

  @override
  String get photoChooseFile => 'เลือกไฟล์';

  @override
  String get availableWhenOnline => 'ดูได้เมื่อออนไลน์';

  @override
  String get receiptPhoto => 'รูปใบเสร็จ';

  @override
  String get receiptAvailableOnline => 'รูปภาพดูได้เมื่อออนไลน์';

  @override
  String get receiptRemoveTitle => 'นำใบเสร็จออกหรือไม่';

  @override
  String get receiptRemoveMessage => 'ใบเสร็จจะถูกนำออกสำหรับทุกคนในกลุ่ม';

  @override
  String get receiptTitle => 'ใบเสร็จ';

  @override
  String receiptTitleOf(int index, int count) {
    return 'ใบเสร็จ $index จาก $count';
  }

  @override
  String get shareOrSave => 'แชร์หรือบันทึก';

  @override
  String get share => 'แชร์';

  @override
  String get copiedToClipboard => 'คัดลอกไปยังคลิปบอร์ดแล้ว';

  @override
  String get settingsTitle => 'การตั้งค่า';

  @override
  String get photoRemove => 'นำรูปออก';

  @override
  String get photoNeedsConnection => 'ต้องเชื่อมต่ออินเทอร์เน็ตเพื่อเปลี่ยนรูป';

  @override
  String get photoTooMany =>
      'เปลี่ยนรูปบ่อยเกินไป โปรดลองอีกครั้งในอีกหนึ่งชั่วโมง';

  @override
  String get notifSaveFailed =>
      'บันทึกการตั้งค่าการแจ้งเตือนไม่ได้ โปรดตรวจสอบการเชื่อมต่อ';

  @override
  String get homeCurrencyNeedsConnection =>
      'ต้องเชื่อมต่ออินเทอร์เน็ตเพื่อเปลี่ยนสกุลเงินหลัก';

  @override
  String get changePhoto => 'เปลี่ยนรูปโปรไฟล์';

  @override
  String get yourNameTapToChange => 'ชื่อของคุณ · แตะเพื่อเปลี่ยน';

  @override
  String get waysToGetPaid => 'ช่องทางรับเงิน';

  @override
  String get waysToGetPaidHint => 'PayPal, Wise, IBAN, บัญชีธนาคาร…';

  @override
  String get homeCurrency => 'สกุลเงินหลัก';

  @override
  String get homeCurrencyFromRegion =>
      'ตามภูมิภาคของคุณ · ยอดคงเหลือแสดง ≈ ในสกุลเงินนี้ด้วย';

  @override
  String get homeCurrencyPicked => 'ยอดคงเหลือแสดง ≈ ในสกุลเงินนี้ด้วย';

  @override
  String get notifications => 'การแจ้งเตือน';

  @override
  String get notifExpenses => 'รายจ่ายและการชำระเงิน';

  @override
  String get notifComments => 'ความคิดเห็น';

  @override
  String get notifMembers => 'สมาชิกและการเปลี่ยนแปลงกลุ่ม';

  @override
  String get notifReminders => 'การเตือนจากเพื่อน';

  @override
  String get notifNeedConnection =>
      'การตั้งค่าการแจ้งเตือนต้องเชื่อมต่ออินเทอร์เน็ต';

  @override
  String get notifOthersOnly => 'แจ้งเตือนเฉพาะการเปลี่ยนแปลงที่คนอื่นทำ';

  @override
  String get notifWebNote =>
      'การแจ้งเตือนจะส่งไปที่โทรศัพท์ของคุณ เบราว์เซอร์จะอัปเดตทุกนาทีขณะเปิดอยู่';

  @override
  String get exportImport => 'ส่งออกและนำเข้า';

  @override
  String get noGroupsToExport => 'ไม่มีกลุ่มให้ส่งออก';

  @override
  String get nonGroup => 'นอกกลุ่ม';

  @override
  String nonGroupWith(String name) {
    return 'นอกกลุ่ม · $name';
  }

  @override
  String get exportJson => 'ส่งออก JSON';

  @override
  String get exportCsv => 'ส่งออก CSV';

  @override
  String get exportZip => 'ZIP พร้อมใบเสร็จ';

  @override
  String get importSplitwise => 'นำเข้า CSV จาก Splitwise';

  @override
  String importedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'นำเข้ารายจ่าย $count รายการแล้ว',
    );
    return '$_temp0';
  }

  @override
  String get server => 'เซิร์ฟเวอร์';

  @override
  String get serverUrl => 'URL ของเซิร์ฟเวอร์';

  @override
  String serverDefault(String url) {
    return 'ค่าเริ่มต้น: $url';
  }

  @override
  String get serverSaved => 'บันทึก URL ของเซิร์ฟเวอร์แล้ว';

  @override
  String get account => 'บัญชี';

  @override
  String get licenses => 'สัญญาอนุญาต';

  @override
  String get deleteAccount => 'ลบบัญชี';

  @override
  String get signOutTitle => 'ออกจากระบบหรือไม่';

  @override
  String get signOutMessage =>
      'ข้อมูลในอุปกรณ์นี้จะถูกลบ การเปลี่ยนแปลงที่ยังไม่ได้ซิงค์จะหายไป';

  @override
  String get deleteAccountTitle => 'ลบบัญชีหรือไม่';

  @override
  String get deleteAccountMessage =>
      'การเป็นสมาชิกของคุณจะกลายเป็นตำแหน่งชั่วคราว ข้อมูลกลุ่มยังอยู่กับสมาชิกคนอื่น ย้อนกลับไม่ได้';

  @override
  String get language => 'ภาษา';

  @override
  String languageSystem(String language) {
    return 'ตามระบบ ($language)';
  }

  @override
  String get appearance => 'ลักษณะที่ปรากฏ';

  @override
  String get appearanceSystem => 'ตามระบบ';

  @override
  String get appearanceLight => 'สว่าง';

  @override
  String get appearanceDark => 'มืด';

  @override
  String get security => 'ความปลอดภัย';

  @override
  String get appLock => 'ล็อกแอป';

  @override
  String get appLockHint =>
      'Face ID, Touch ID หรือลายนิ้วมือ โดยมีรหัสผ่านอุปกรณ์เป็นตัวสำรอง ล็อกหลังจากไม่ได้ใช้หนึ่งนาที';

  @override
  String methodRemoveTitle(String method) {
    return 'นำ $method ออกหรือไม่';
  }

  @override
  String get methodsOffline => 'เชื่อมต่ออินเทอร์เน็ตเพื่อแก้ไขช่องทางรับเงิน';

  @override
  String get methodsLoadFailed => 'โหลดช่องทางรับเงินไม่ได้';

  @override
  String get methodsIntro =>
      'สมาชิกในกลุ่มจะเห็นช่องทางเหล่านี้เมื่อค้างเงินคุณ เพื่อให้จ่ายได้ในแตะเดียว Evensies ไม่เคยโอนเงินเอง';

  @override
  String get methodsEmpty => 'ยังไม่มีช่องทางรับเงิน';

  @override
  String get blurbPaypal => 'ลิงก์ PayPal.me พร้อมกรอกยอดเงิน';

  @override
  String get blurbWise => 'ลิงก์ Wise Quick Pay พร้อมกรอกยอดเงิน';

  @override
  String get blurbVenmo => 'ชื่อผู้ใช้ Venmo (สหรัฐฯ)';

  @override
  String get blurbRevolut => 'ชื่อผู้ใช้ Revolut.me';

  @override
  String get blurbKakaopay => 'ลิงก์ 송금코드 ของ KakaoPay';

  @override
  String get blurbIban => 'โอนผ่านธนาคาร (SEPA QR สำหรับ EUR)';

  @override
  String get blurbKrBank => 'บัญชีธนาคารเกาหลี (Toss, แอปธนาคาร)';

  @override
  String get fieldPaypal => 'ชื่อผู้ใช้ PayPal.me';

  @override
  String get fieldPaypalHint => 'ชื่อผู้ใช้ PayPal.me ของคุณ เช่น anna';

  @override
  String get fieldRevolut => 'ชื่อผู้ใช้ Revolut.me';

  @override
  String get fieldRevolutHint => 'ชื่อผู้ใช้ Revolut.me ของคุณ เช่น anna';

  @override
  String get fieldVenmo => 'ชื่อผู้ใช้ Venmo';

  @override
  String get fieldVenmoHint => 'ไม่ต้องใส่ @ เช่น anna-rossi';

  @override
  String get fieldWise => 'ลิงก์ Wise Quick Pay';

  @override
  String get fieldWiseHint =>
      'ใน Wise: Payments → Quick Pay → คัดลอกลิงก์ (https://wise.com/pay/…)';

  @override
  String get fieldKakaopay => 'ลิงก์ 송금코드 ของ KakaoPay';

  @override
  String get fieldKakaopayHint =>
      'ใน KakaoPay: 송금 → 송금코드 → คัดลอกลิงก์ (https://qr.kakaopay.com/…)';

  @override
  String get fieldHolder => 'เจ้าของบัญชี';

  @override
  String get fieldHolderHint => 'ชื่อให้ตรงกับบัญชี';

  @override
  String get fieldIban => 'IBAN';

  @override
  String get fieldIbanHint => 'เช่น DE89 3704 0044 0532 0130 00';

  @override
  String get fieldBic => 'BIC (ไม่บังคับ)';

  @override
  String get fieldBicHint => '8 หรือ 11 อักขระ';

  @override
  String get fieldBank => 'ธนาคาร';

  @override
  String get fieldBankHint => 'เช่น 신한은행, Toss Bank';

  @override
  String get fieldAccountNumber => 'เลขที่บัญชี';

  @override
  String get fieldAccountNumberHint => 'ตัวเลข ขีดจะใส่หรือไม่ก็ได้';

  @override
  String amountCopied(String amount) {
    return 'คัดลอกยอดเงินแล้ว: $amount';
  }

  @override
  String couldNotOpen(String link) {
    return 'เปิด $link ไม่ได้';
  }

  @override
  String get payOffline => 'ออฟไลน์: ไม่มีช่องทางชำระเงิน';

  @override
  String get payLoading => 'กำลังโหลดช่องทางชำระเงิน…';

  @override
  String payAskToAdd(String name) {
    return 'ขอให้ $name เพิ่มช่องทางรับเงิน';
  }

  @override
  String payTitle(String name, String amount) {
    return 'จ่าย $amount ให้ $name';
  }

  @override
  String get payScanQr => 'สแกนด้วยแอปธนาคาร (SEPA QR)';

  @override
  String get payQrEurOnly => 'คิวอาร์โค้ดใช้ได้เฉพาะการโอนเป็น EUR';

  @override
  String get bankLabel => 'ธนาคาร';

  @override
  String get ibanLabel => 'IBAN';

  @override
  String get accountLabel => 'บัญชี';

  @override
  String get bicLabel => 'BIC';

  @override
  String get holderLabel => 'เจ้าของ';

  @override
  String get amountLabel => 'ยอดเงิน';

  @override
  String get copyIban => 'คัดลอก IBAN';

  @override
  String get copyAccount => 'คัดลอกบัญชี';

  @override
  String get copyAmount => 'คัดลอกยอดเงิน';

  @override
  String get ibanCopied => 'คัดลอก IBAN แล้ว';

  @override
  String get accountCopied => 'คัดลอกบัญชีแล้ว';

  @override
  String get paymentUpdated => 'อัปเดตการชำระเงินแล้ว';

  @override
  String paymentRecordedPending(String amount, String name) {
    return 'บันทึก $amount แล้ว $name จะยืนยัน';
  }

  @override
  String paymentRecordedPendingUnnamed(String amount) {
    return 'บันทึก $amount แล้ว อีกฝ่ายจะยืนยัน';
  }

  @override
  String paymentRecorded(String amount) {
    return 'บันทึกการชำระเงิน $amount แล้ว';
  }

  @override
  String youSuffix(String name) {
    return '$name (คุณ)';
  }

  @override
  String get recordPayment => 'บันทึกการชำระเงิน';

  @override
  String get editPayment => 'แก้ไขการชำระเงิน';

  @override
  String get fromLabel => 'จาก';

  @override
  String get toLabel => 'ถึง';

  @override
  String get swap => 'สลับ';

  @override
  String get pickTwoPeople => 'เลือกสองคนที่ต่างกัน';

  @override
  String get commentsStayOld => 'ความคิดเห็นยังอยู่กับการชำระเงินเดิม';

  @override
  String get recordPaymentButton => 'บันทึกการชำระเงิน';

  @override
  String get paymentNotHere => 'การชำระเงินนี้ไม่อยู่ในอุปกรณ์นี้';

  @override
  String get notSyncedOrLeft => 'ยังไม่ได้ซิงค์ หรือคุณออกจากกลุ่มแล้ว';

  @override
  String get someone => 'สมาชิกที่ไม่รู้จัก';

  @override
  String get paymentEdited => 'การชำระเงินที่แก้ไขแล้ว';

  @override
  String get paymentDeleted => 'การชำระเงินที่ลบแล้ว';

  @override
  String get payment => 'การชำระเงิน';

  @override
  String get paymentWasEdited => 'การชำระเงินนี้ถูกแก้ไขแล้ว';

  @override
  String get paymentWasEditedNote =>
      'ระบบนับการชำระเงินที่แก้ไขแล้วแทน ความคิดเห็นยังอยู่ที่นี่';

  @override
  String get paymentWasDeleted => 'การชำระเงินนี้ถูกลบแล้ว';

  @override
  String get paymentNotCounted => 'ไม่นับรวมในยอดคงเหลือ';

  @override
  String get restore => 'กู้คืน';

  @override
  String youPaidName(String name) {
    return 'คุณจ่ายให้ $name';
  }

  @override
  String namePaidYou(String name) {
    return '$name จ่ายให้คุณ';
  }

  @override
  String namePaidName(String from, String to) {
    return '$from จ่ายให้ $to';
  }

  @override
  String paymentSaysSent(String name) {
    return '$name บอกว่าส่งให้คุณแล้ว ได้รับหรือยัง';
  }

  @override
  String waitingForConfirm(String name) {
    return 'รอ $name ยืนยัน';
  }

  @override
  String get notReceived => 'ไม่ได้รับ';

  @override
  String get confirmReceived => 'ยืนยันว่าได้รับ';

  @override
  String get deletePaymentTitle => 'ลบการชำระเงินหรือไม่';

  @override
  String get deletePaymentMessage => 'หนี้ที่ชำระไปจะกลับมา';

  @override
  String get paymentDeletedSnack => 'ลบการชำระเงินแล้ว';

  @override
  String get notReceivedTitle => 'ไม่ได้รับหรือ';

  @override
  String notReceivedMessage(String name) {
    return 'การชำระเงินจาก $name จะถูกนำออกและหนี้จะกลับมา';
  }

  @override
  String get paymentRemovedSnack => 'นำการชำระเงินออกแล้ว';

  @override
  String get recordAPayment => 'บันทึกการชำระเงิน';

  @override
  String get nothingToSettle => 'ไม่มีอะไรต้องชำระ';

  @override
  String get everyoneEven => 'ทุกคนเคลียร์กันหมดแล้ว';

  @override
  String get waitingForConfirmation => 'รอการยืนยัน';

  @override
  String get debtsAsRecorded => 'หนี้ตามที่บันทึก · ปิดการลดรูปหนี้';

  @override
  String transfersSettleEverything(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'โอน $count ครั้งเพื่อชำระทั้งหมด',
    );
    return '$_temp0';
  }

  @override
  String transfersSettleBalance(int count, String currency) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'โอน $count ครั้งเพื่อชำระยอด $currency',
    );
    return '$_temp0';
  }

  @override
  String notConvertedSettlesIn(String currency) {
    return 'ยังไม่แปลง · $currency · ชำระเป็น $currency';
  }

  @override
  String get convert => 'แปลง';

  @override
  String get settleUp => 'ชำระหนี้';

  @override
  String saysTheySent(String name, String amount) {
    return '$name บอกว่าส่ง $amount ให้คุณแล้ว';
  }

  @override
  String waitingToConfirmAmount(String name, String amount) {
    return 'รอ $name ยืนยัน $amount';
  }

  @override
  String get you => 'คุณ';

  @override
  String get request => 'ขอเงิน';

  @override
  String get iveSentIt => 'ส่งแล้ว';

  @override
  String get markAsPaid => 'ทำเครื่องหมายว่าจ่ายแล้ว';

  @override
  String markedAsSent(String name) {
    return 'ทำเครื่องหมายว่าส่งแล้ว $name จะยืนยัน';
  }

  @override
  String approx(String amount) {
    return '≈ $amount';
  }

  @override
  String friendOwesYou(String name, String amount) {
    return '$name ค้างจ่ายคุณ $amount';
  }

  @override
  String friendYouOwe(String name, String amount) {
    return 'คุณค้างจ่าย $name $amount';
  }

  @override
  String friendYouOweLine(String name, String amount) {
    return 'คุณค้างจ่าย $name $amount';
  }

  @override
  String noSharedGroup(String name) {
    return 'คุณไม่ได้อยู่กลุ่มเดียวกับ $name แล้ว ส่งลิงก์เพื่อนของคุณเพื่อเพิ่มรายจ่าย';
  }

  @override
  String get shareFriendLink => 'แชร์ลิงก์เพื่อน';

  @override
  String firstExpenseNeedsConnection(String name) {
    return 'รายจ่ายแรกกับ $name ต้องเชื่อมต่ออินเทอร์เน็ต';
  }

  @override
  String reminderSent(String name) {
    return 'ส่งการเตือนถึง $name แล้ว';
  }

  @override
  String remindTomorrow(String name) {
    return 'คุณเตือน $name ได้อีกครั้งพรุ่งนี้';
  }

  @override
  String remindNothingOwed(String name) {
    return '$name ไม่ได้ค้างจ่ายคุณ';
  }

  @override
  String get remindNeedsConnection =>
      'ต้องเชื่อมต่ออินเทอร์เน็ตเพื่อส่งการเตือน';

  @override
  String amountsAnd(String a, String b) {
    return '$a และ $b';
  }

  @override
  String inviteFriendText(String link) {
    return 'ฉันเพิ่มคุณใน Evensies เพื่อหารค่าใช้จ่ายกัน มาร่วมด้วยกัน: $link';
  }

  @override
  String get personNotHere => 'คนนี้ไม่อยู่ในอุปกรณ์นี้';

  @override
  String get personNotHereNote =>
      'ยังไม่ได้ซิงค์ หรือคุณไม่ได้อยู่กลุ่มเดียวกันแล้ว';

  @override
  String get more => 'เพิ่มเติม';

  @override
  String get exportNonGroupCsv => 'ส่งออกรายจ่ายนอกกลุ่ม (CSV)';

  @override
  String get exportNonGroupJson => 'ส่งออกรายจ่ายนอกกลุ่ม (JSON)';

  @override
  String get exportNonGroupZip => 'ส่งออกรายจ่ายนอกกลุ่ม (ZIP พร้อมใบเสร็จ)';

  @override
  String get notOnEvensies => 'ยังไม่ได้ใช้ Evensies';

  @override
  String get allSettledUp => 'ชำระครบแล้ว';

  @override
  String get remind => 'เตือน';

  @override
  String get invite => 'เชิญ';

  @override
  String get balances => 'ยอดคงเหลือ';

  @override
  String get expensesAndPayments => 'รายจ่ายและการชำระเงิน';

  @override
  String get nothingTogetherYet => 'ยังไม่มีอะไรร่วมกัน เพิ่มรายจ่ายด้านล่าง';

  @override
  String get addExpense => 'เพิ่มรายจ่าย';

  @override
  String personOwesYou(String amount) {
    return 'ค้างจ่ายคุณ $amount';
  }

  @override
  String personYouOwe(String amount) {
    return 'คุณค้างจ่าย $amount';
  }

  @override
  String get personSettledUp => 'ชำระครบแล้ว';

  @override
  String recordedInGroups(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'บันทึกใน $count กลุ่มแล้ว',
    );
    return '$_temp0';
  }

  @override
  String get markAsReceived => 'ทำเครื่องหมายว่าได้รับแล้ว';

  @override
  String get clearBothSides => 'หักล้างทั้งสองฝ่าย';

  @override
  String evenIn(String currency) {
    return 'เคลียร์แล้วใน $currency';
  }

  @override
  String linePayThem(String group, String name, String amount) {
    return '$group: คุณจ่าย $name $amount';
  }

  @override
  String lineTheyPay(String group, String name, String amount) {
    return '$group: $name จ่ายคุณ $amount';
  }

  @override
  String get noMoneyMoves => 'ไม่มีการโอนเงิน: บันทึกว่าทั้งสองฝ่ายชำระแล้ว';

  @override
  String convertIn(String group) {
    return 'แปลงใน $group';
  }

  @override
  String settleUpWith(String name) {
    return 'ชำระหนี้กับ $name';
  }

  @override
  String nothingToSettleWith(String name) {
    return 'ไม่มีอะไรต้องชำระกับ $name';
  }

  @override
  String settleWithIntro(String name) {
    return 'ทุกอย่างระหว่างคุณกับ $name แยกตามสกุลเงิน การบันทึกจะเพิ่มการชำระเงินในทุกกลุ่ม';
  }

  @override
  String get searchFriendsGroups => 'ค้นหาเพื่อนและกลุ่ม';

  @override
  String get friends => 'เพื่อน';

  @override
  String get groups => 'กลุ่ม';

  @override
  String get noFriendsOrGroups => 'ยังไม่มีเพื่อนหรือกลุ่ม';

  @override
  String nothingMatches(String query) {
    return 'ไม่มีผลลัพธ์สำหรับ “$query”';
  }

  @override
  String get addExpenseWithWhom => 'เพิ่มรายจ่าย · กับใคร';

  @override
  String friendLinkShare(String link, String code) {
    return 'เพิ่มฉันใน Evensies เพื่อหารค่าใช้จ่าย: $link\nหรือใส่รหัสของฉัน $code';
  }

  @override
  String get friendLinkNeedsConnection =>
      'ต้องเชื่อมต่ออินเทอร์เน็ตเพื่อแชร์ลิงก์เพื่อน';

  @override
  String get selfFriend => 'นี่คือรหัสของคุณเอง';

  @override
  String get noOneForCode => 'ไม่พบใครที่ใช้รหัสนี้';

  @override
  String get addFriendNeedsConnection =>
      'ต้องเชื่อมต่ออินเทอร์เน็ตเพื่อเพิ่มเพื่อน';

  @override
  String get newFriendCodeTitle => 'สร้างรหัสเพื่อนใหม่หรือไม่';

  @override
  String get newFriendCodeMessage =>
      'ลิงก์และรหัสปัจจุบันจะใช้ไม่ได้อีก เพื่อนที่มีอยู่แล้วยังอยู่';

  @override
  String get newCode => 'รหัสใหม่';

  @override
  String get addAFriend => 'เพิ่มเพื่อน';

  @override
  String get friendLinkOffline => 'ลิงก์เพื่อนของคุณต้องเชื่อมต่ออินเทอร์เน็ต';

  @override
  String get yourFriendCode => 'รหัสเพื่อนของคุณ';

  @override
  String get friendQrLabel => 'คิวอาร์โค้ดของลิงก์เพื่อน';

  @override
  String get friendCodeHelp => 'ให้เพื่อนสแกน เปิดลิงก์ หรือพิมพ์รหัส';

  @override
  String get shareLink => 'แชร์ลิงก์';

  @override
  String get codeCopied => 'คัดลอกรหัสแล้ว';

  @override
  String get copyCode => 'คัดลอกรหัส';

  @override
  String get haveFriendCode => 'มีรหัสของเพื่อนไหม';

  @override
  String get onEvensies => 'ใช้ Evensies';

  @override
  String get notOnEvensiesSection => 'คนที่ยังไม่ได้ใช้ Evensies';

  @override
  String get notOnEvensiesHelp =>
      'เพิ่มรายจ่ายร่วมกันได้ทันที แล้วค่อยเชิญภายหลัง';

  @override
  String atMostChars(int max) {
    return 'ไม่เกิน $max อักขระ';
  }

  @override
  String addName(String name) {
    return 'เพิ่ม $name';
  }

  @override
  String get search => 'ค้นหา';

  @override
  String get activity => 'กิจกรรม';

  @override
  String get newGroup => 'กลุ่มใหม่';

  @override
  String get joinWithCode => 'เข้าร่วมด้วยรหัส';

  @override
  String get filterAll => 'ทั้งหมด';

  @override
  String get filterOwesMe => 'ค้างจ่ายฉัน';

  @override
  String get filterIOwe => 'ฉันค้างจ่าย';

  @override
  String settledUpCount(int count) {
    return 'ชำระครบแล้ว ($count)';
  }

  @override
  String get nobodyOwesYou => 'ไม่มีใครค้างจ่ายคุณ';

  @override
  String get youOweNothing => 'คุณไม่ได้ค้างจ่ายใคร';

  @override
  String get nothingHereYet => 'ยังไม่มีอะไรที่นี่';

  @override
  String get noFriendsYet => 'ยังไม่มีเพื่อน';

  @override
  String get noFriendsHelp =>
      'เพิ่มเพื่อนเพื่อหารค่าใช้จ่ายนอกกลุ่ม คนที่อยู่กลุ่มเดียวกับคุณจะแสดงที่นี่ด้วย';

  @override
  String get allSettledUpYou => 'คุณเคลียร์กับทุกคนแล้ว';

  @override
  String youAreOwedList(String amounts) {
    return 'คุณจะได้รับ $amounts';
  }

  @override
  String youOweList(String amounts) {
    return 'คุณค้างจ่าย $amounts';
  }

  @override
  String get notOnEvensiesLower => 'ยังไม่ได้ใช้ Evensies';

  @override
  String get noGroupsYet => 'ยังไม่มีกลุ่ม';

  @override
  String get noGroupsHelp =>
      'สร้างกลุ่มสำหรับทริปหรือบ้านที่อยู่ร่วมกัน หรือเข้าร่วมกลุ่มของเพื่อนด้วยรหัสเชิญ';

  @override
  String get createGroup => 'สร้างกลุ่ม';

  @override
  String get settledUp => 'ชำระครบแล้ว';

  @override
  String netApprox(String amount) {
    return 'สุทธิ ≈ $amount';
  }

  @override
  String memberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'สมาชิก $count คน',
    );
    return '$_temp0';
  }

  @override
  String youOweAmount(String amount) {
    return 'คุณค้างจ่าย $amount';
  }

  @override
  String youAreOwedAmount(String amount) {
    return 'คุณจะได้รับ $amount';
  }

  @override
  String youOweAmountLine(String amount) {
    return 'คุณค้างจ่าย $amount';
  }

  @override
  String youAreOwedAmountLine(String amount) {
    return 'คุณจะได้รับ $amount';
  }

  @override
  String get createGroupNeedsConnection =>
      'ต้องเชื่อมต่ออินเทอร์เน็ตเพื่อสร้างกลุ่ม';

  @override
  String get groupName => 'ชื่อกลุ่ม';

  @override
  String get yourNameInGroup => 'ชื่อของคุณในกลุ่มนี้';

  @override
  String get defaultCurrency => 'สกุลเงินเริ่มต้น';

  @override
  String get create => 'สร้าง';

  @override
  String get noGroupOrFriendForCode => 'ไม่พบกลุ่มหรือเพื่อนที่ใช้รหัสนี้';

  @override
  String get joinNeedsConnection =>
      'ต้องเชื่อมต่ออินเทอร์เน็ตเพื่อเข้าร่วมกลุ่ม';

  @override
  String get enterACode => 'ใส่รหัส';

  @override
  String get enterCodeHelp =>
      'รหัสกลุ่มอยู่ในกลุ่ม → สมาชิก รหัสเพื่อนอยู่ในแท็บเพื่อนของเขา → เพิ่มเพื่อน';

  @override
  String get pastedFromClipboard => 'วางจากคลิปบอร์ด';

  @override
  String nameOnEvensies(String name) {
    return '$name · ใช้ Evensies';
  }

  @override
  String addAsFriend(String name) {
    return 'เพิ่ม $name เป็นเพื่อน';
  }

  @override
  String addedYouAsFriend(String name) {
    return '$name เพิ่มคุณเป็นเพื่อน';
  }

  @override
  String get someoneAddedYouAsFriend => 'มีคนเพิ่มคุณเป็นเพื่อน';

  @override
  String groupPreview(String name, String members) {
    return '$name · $members';
  }

  @override
  String get continueButton => 'ดำเนินการต่อ';

  @override
  String wantsToSplit(String name) {
    return '$name อยากหารค่าใช้จ่ายกับคุณ';
  }

  @override
  String get joinGroup => 'เข้าร่วมกลุ่ม';

  @override
  String get inviteInvalid => 'ลิงก์เชิญนี้ใช้ไม่ได้แล้ว';

  @override
  String inviteFailed(String reason) {
    return 'เปิดคำเชิญนี้ไม่ได้: $reason';
  }

  @override
  String get friendInviteUsed => 'คำเชิญเพื่อนนี้ถูกใช้ไปแล้ว';

  @override
  String get joinToSeeShared => 'เข้าร่วมเพื่อดูและเพิ่มรายจ่ายที่ใช้ร่วมกัน';

  @override
  String imName(String name) {
    return 'ฉันคือ $name';
  }

  @override
  String get join => 'เข้าร่วม';

  @override
  String get whoAreYou => 'คุณคือใคร';

  @override
  String get newMemberName => 'ชื่อสมาชิกใหม่';

  @override
  String get insights => 'ข้อมูลเชิงลึก';

  @override
  String get membersInvite => 'สมาชิกและคำเชิญ';

  @override
  String get groupSettings => 'การตั้งค่ากลุ่ม';

  @override
  String get expenses => 'รายจ่าย';

  @override
  String get expenseFab => 'รายจ่าย';

  @override
  String get groupNotHere => 'กลุ่มนี้ไม่อยู่ในอุปกรณ์นี้';

  @override
  String get groupNotHereNote =>
      'คุณออกจากกลุ่มแล้ว มีคนนำคุณออก หรือยังไม่ได้ซิงค์';

  @override
  String get backToGroups => 'กลับไปที่กลุ่ม';

  @override
  String get noExpensesYet => 'ยังไม่มีรายจ่าย';

  @override
  String get tapExpenseToAdd => 'แตะ “รายจ่าย” เพื่อเพิ่มรายการแรก';

  @override
  String tilePaidYou(String amount) {
    return 'คุณจ่าย $amount';
  }

  @override
  String tilePaidName(String name, String amount) {
    return '$name จ่าย $amount';
  }

  @override
  String tilePaidPeople(int count, String amount) {
    return '$count คนจ่าย $amount';
  }

  @override
  String get tileRefundYou => 'เงินคืนให้คุณ';

  @override
  String tileRefundName(String name) {
    return 'เงินคืนให้ $name';
  }

  @override
  String tileRefundPeople(int count) {
    return 'เงินคืนให้ $count คน';
  }

  @override
  String get notInvolved => 'ไม่เกี่ยวข้อง';

  @override
  String get allYours => 'เป็นของคุณทั้งหมด';

  @override
  String get paidForYourself => 'คุณจ่ายส่วนของตัวเอง';

  @override
  String youGetBack(String amount) {
    return 'คุณได้คืน $amount';
  }

  @override
  String youLent(String amount) {
    return 'คุณออกให้ก่อน $amount';
  }

  @override
  String youBorrowed(String amount) {
    return 'มีคนออกให้คุณ $amount';
  }

  @override
  String get repeatsLabel => 'ทำซ้ำ';

  @override
  String hasReceipt(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'มีใบเสร็จ $count ใบ',
    );
    return '$_temp0';
  }

  @override
  String get refund => 'เงินคืน';

  @override
  String get notConverted => 'ยังไม่แปลง';

  @override
  String get pending => 'รอดำเนินการ';

  @override
  String approxTotalOwe(String amount) {
    return 'รวมแล้วคุณค้างจ่าย ≈ $amount';
  }

  @override
  String approxTotalOwed(String amount) {
    return 'รวมแล้วคุณจะได้รับ ≈ $amount';
  }

  @override
  String get approxTotalNote => 'ในสกุลเงินหลักของคุณ ตามอัตราล่าสุด';

  @override
  String nothingOwedIn(String currency) {
    return 'ไม่มีหนี้ใน $currency';
  }

  @override
  String get allSettled => 'ชำระครบแล้ว';

  @override
  String get otherCurrenciesBelow => 'รายจ่ายในสกุลเงินอื่นอยู่ด้านล่าง';

  @override
  String get nobodyOwes => 'ไม่มีใครค้างจ่าย';

  @override
  String youPayNext(String amount) {
    return 'คุณควรจ่ายครั้งถัดไป (คุณค้างจ่าย $amount มากที่สุด)';
  }

  @override
  String namePaysNext(String name, String amount) {
    return '$name ควรจ่ายครั้งถัดไป (ค้างจ่าย $amount มากที่สุด)';
  }

  @override
  String settleUpWaiting(int count) {
    return 'ชำระหนี้ · รอ $count รายการ';
  }

  @override
  String memberRemoved(String name) {
    return '$name (ถูกนำออก)';
  }

  @override
  String expensesWithoutRate(int count, String currency) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'รายจ่าย $count รายการไม่มีอัตราเป็น $currency',
    );
    return '$_temp0';
  }

  @override
  String expensesBadRate(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'รายจ่าย $count รายการมีอัตราที่แปลงไม่ได้',
    );
    return '$_temp0';
  }

  @override
  String paymentsIn(String currency) {
    return 'การชำระเงินใน $currency';
  }

  @override
  String everyoneEvenIn(String currency) {
    return 'ทุกคนเคลียร์แล้วใน $currency';
  }

  @override
  String convertTo(String currency) {
    return 'แปลงเป็น $currency';
  }

  @override
  String get balanceSettled => 'ชำระแล้ว';

  @override
  String get balanceGetsBack => 'ได้คืน';

  @override
  String get balanceOwes => 'ค้างจ่าย';

  @override
  String convertedCount(int count, String currency) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'แปลงรายจ่าย $count รายการเป็น $currency แล้ว',
    );
    return '$_temp0';
  }

  @override
  String get noAutoRate => 'ไม่มีอัตราอัตโนมัติ โปรดใส่เอง';

  @override
  String rateOf(String date) {
    return 'อัตราวันที่ $date';
  }

  @override
  String rateOfOffline(String date) {
    return 'ออฟไลน์ · อัตราวันที่ $date';
  }

  @override
  String amountCountExpenses(String amount, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'รายจ่าย $count รายการ',
    );
    return '$amount · $_temp0';
  }

  @override
  String paymentsStayIn(String currency) {
    return 'การชำระเงินใน $currency ยังคงเป็น $currency';
  }

  @override
  String rateLabel(String from, String to) {
    return 'อัตรา: 1 $from เป็น $to';
  }

  @override
  String get nothingLeftToConvert => 'ไม่มีอะไรเหลือให้แปลง';

  @override
  String get lookingUpRate => 'กำลังหาอัตรา…';

  @override
  String get enterRateAbove0 => 'ใส่อัตราที่มากกว่า 0';

  @override
  String convertExplain(String currency) {
    return 'ใส่อัตรานี้ให้ทุกรายจ่ายที่ยังไม่มี เพื่อให้นับรวมในยอดคงเหลือ $currency คุณยังเปลี่ยนอัตราของแต่ละรายจ่ายได้';
  }

  @override
  String get nameField => 'ชื่อ';

  @override
  String get cantChangeCurrency =>
      'เปลี่ยนไม่ได้หลังจากมีรายจ่ายหรือการชำระเงินแรกแล้ว';

  @override
  String get currencyUsedFor => 'ใช้สำหรับยอดคงเหลือและการชำระเงิน';

  @override
  String get splitting => 'การแบ่ง';

  @override
  String get simplifyDebts => 'ลดรูปหนี้';

  @override
  String get simplifyDebtsHelp =>
      'รวมหนี้เพื่อให้กลุ่มโอนน้อยครั้งลง ยอดรวมของแต่ละคนไม่เปลี่ยน แค่เปลี่ยนว่าใครจ่ายใคร';

  @override
  String get defaultSplit => 'การแบ่งเริ่มต้น';

  @override
  String get splitStale => 'ยอดไม่ตรงแล้ว · แตะเพื่อแก้ไข';

  @override
  String get membership => 'การเป็นสมาชิก';

  @override
  String get leaveGroup => 'ออกจากกลุ่ม';

  @override
  String get balanceSettledNote => 'ยอดของคุณชำระครบแล้ว';

  @override
  String get renameGroup => 'เปลี่ยนชื่อกลุ่ม';

  @override
  String leaveTitle(String name) {
    return 'ออกจาก “$name” หรือไม่';
  }

  @override
  String get leaveMessage =>
      'คุณจะไม่เห็นกลุ่มนี้อีก รายจ่ายที่ผ่านมาของคุณยังอยู่กับสมาชิกคนอื่น หากต้องการกลับมา ให้ขอรหัสเชิญ';

  @override
  String get leave => 'ออก';

  @override
  String youLeft(String name) {
    return 'คุณออกจาก “$name” แล้ว';
  }

  @override
  String get splitEqualEveryone => 'เท่ากัน · ทุกคน';

  @override
  String splitPercentList(String list) {
    return 'เปอร์เซ็นต์ · $list';
  }

  @override
  String splitSharesList(String list) {
    return 'สัดส่วน · $list';
  }

  @override
  String percentValue(String value) {
    return '$value%';
  }

  @override
  String get defaultSplitHelp =>
      'รายจ่ายใหม่จะเริ่มด้วยการแบ่งนี้ คุณยังเปลี่ยนได้ในแต่ละรายจ่าย';

  @override
  String get useEqual => 'ใช้แบบเท่ากัน';

  @override
  String get inviteCode => 'รหัสเชิญ';

  @override
  String get inviteQrLabel => 'คิวอาร์โค้ดของลิงก์เชิญ';

  @override
  String get inviteCodeHelp =>
      'ใครก็ตามที่มีรหัสนี้เข้าร่วมและเลือกชื่อของตัวเองได้';

  @override
  String inviteShareText(String group, String link, String code) {
    return 'เข้าร่วมกลุ่ม “$group” ของฉันใน Evensies: $link\nหรือเปิดแอปแล้วใส่รหัส $code';
  }

  @override
  String get rotateCode => 'เปลี่ยนรหัส';

  @override
  String get members => 'สมาชิก';

  @override
  String get notJoinedYet => 'ยังไม่ได้เข้าร่วม — แชร์รหัสเชิญ';

  @override
  String get linked => 'เชื่อมโยงแล้ว';

  @override
  String get addPlaceholder => 'เพิ่มสมาชิกชั่วคราว';

  @override
  String removeMemberTitle(String name) {
    return 'นำ $name ออกหรือไม่';
  }

  @override
  String get removeMemberMessage =>
      'รายจ่ายที่ผ่านมาและยอดคงเหลือยังอยู่ในกลุ่ม';

  @override
  String removeMemberSeries(int count, String name, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$name ยังอยู่ในรายจ่ายที่ทำซ้ำ $count รายการ ($names) ส่วนของ $name จะยังอยู่จนกว่าคุณจะแก้ไขรายการล่าสุด',
    );
    return '$_temp0';
  }

  @override
  String get addMember => 'เพิ่มสมาชิก';

  @override
  String get rotateInviteTitle => 'เปลี่ยนรหัสเชิญหรือไม่';

  @override
  String get rotateInviteMessage =>
      'รหัสและลิงก์ปัจจุบันจะใช้ไม่ได้อีก คนที่เข้าร่วมแล้วไม่ได้รับผลกระทบ';

  @override
  String get rotate => 'เปลี่ยน';

  @override
  String get newInviteReady => 'รหัสเชิญใหม่พร้อมแล้ว';

  @override
  String get activityNeedsConnection => 'กิจกรรมต้องเชื่อมต่ออินเทอร์เน็ต';

  @override
  String get activityOfflineNote =>
      'การเปลี่ยนแปลงล่าสุดจะแสดงที่นี่เมื่อคุณกลับมาออนไลน์';

  @override
  String get noActivityYet => 'ยังไม่มีกิจกรรม';

  @override
  String get activityAllGroups => 'การเปลี่ยนแปลงในกลุ่มของคุณจะแสดงที่นี่';

  @override
  String get activityThisGroup => 'การเปลี่ยนแปลงในกลุ่มนี้จะแสดงที่นี่';

  @override
  String get showingSaved => 'กิจกรรมที่บันทึกไว้ ดึงลงเพื่อรีเฟรช';

  @override
  String get loadMore => 'โหลดเพิ่ม';

  @override
  String get earlier => 'ก่อนหน้านี้';

  @override
  String get today => 'วันนี้';

  @override
  String get yesterday => 'เมื่อวาน';

  @override
  String forDate(String date) {
    return 'สำหรับ $date';
  }

  @override
  String get youCommented => 'คุณแสดงความคิดเห็น';

  @override
  String nameCommented(String name) {
    return '$name แสดงความคิดเห็น';
  }

  @override
  String restoredName(String name) {
    return 'กู้คืน “$name” แล้ว';
  }

  @override
  String get paymentRestored => 'กู้คืนการชำระเงินแล้ว';

  @override
  String get expenseNotHere => 'รายจ่ายนี้ไม่อยู่ในอุปกรณ์นี้';

  @override
  String get deletedExpense => 'รายจ่ายที่ลบแล้ว';

  @override
  String get expense => 'รายจ่าย';

  @override
  String seriesRepeats(String frequency) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'ทำซ้ำทุกสัปดาห์',
      'biweekly': 'ทำซ้ำทุก 2 สัปดาห์',
      'monthly': 'ทำซ้ำทุกเดือน',
      'yearly': 'ทำซ้ำทุกปี',
      'other': 'ทำซ้ำ',
    });
    return '$_temp0';
  }

  @override
  String seriesRepeatsNext(String frequency, String date) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'ทำซ้ำทุกสัปดาห์ · ครั้งถัดไป $date',
      'biweekly': 'ทำซ้ำทุก 2 สัปดาห์ · ครั้งถัดไป $date',
      'monthly': 'ทำซ้ำทุกเดือน · ครั้งถัดไป $date',
      'yearly': 'ทำซ้ำทุกปี · ครั้งถัดไป $date',
      'other': 'ทำซ้ำ · ครั้งถัดไป $date',
    });
    return '$_temp0';
  }

  @override
  String seriesRepeatsNextAmount(String frequency, String amount, String date) {
    String _temp0 = intl.Intl.selectLogic(frequency, {
      'weekly': 'ทำซ้ำทุกสัปดาห์ · ครั้งถัดไป $amount วันที่ $date',
      'biweekly': 'ทำซ้ำทุก 2 สัปดาห์ · ครั้งถัดไป $amount วันที่ $date',
      'monthly': 'ทำซ้ำทุกเดือน · ครั้งถัดไป $amount วันที่ $date',
      'yearly': 'ทำซ้ำทุกปี · ครั้งถัดไป $amount วันที่ $date',
      'other': 'ทำซ้ำ · ครั้งถัดไป $amount วันที่ $date',
    });
    return '$_temp0';
  }

  @override
  String rateLine(String from, String rate, String to) {
    return 'อัตรา: 1 $from = $rate $to';
  }

  @override
  String notConvertedTo(String currency) {
    return 'ยังไม่แปลงเป็น $currency';
  }

  @override
  String get receivedSplitBack => 'ได้รับและแบ่งคืน';

  @override
  String get whoPaidOwes => 'ใครจ่ายและใครค้างจ่าย';

  @override
  String get items => 'รายการ';

  @override
  String get notes => 'บันทึก';

  @override
  String get receipts => 'ใบเสร็จ';

  @override
  String get history => 'ประวัติ';

  @override
  String get deleteExpenseTitle => 'ลบรายจ่ายหรือไม่';

  @override
  String get deleteExpenseMessage =>
      'รายจ่ายจะถูกลบสำหรับทุกคนในกลุ่ม คุณกู้คืนได้จากกิจกรรม';

  @override
  String get deleteRepeatingTitle => 'ลบรายจ่ายที่ทำซ้ำหรือไม่';

  @override
  String get deleteRepeatingMessage =>
      'รายจ่ายจะถูกลบสำหรับทุกคนในกลุ่ม คุณกู้คืนได้จากกิจกรรม แต่ชุดที่หยุดทำซ้ำแล้วเริ่มใหม่ไม่ได้ รายการที่เพิ่มไปแล้วยังอยู่';

  @override
  String get deleteThisOne => 'ลบเฉพาะรายการนี้';

  @override
  String get deleteAndStop => 'ลบและหยุดทำซ้ำ';

  @override
  String deletedAndStopped(String name) {
    return 'ลบ “$name” และหยุดทำซ้ำแล้ว';
  }

  @override
  String deletedName(String name) {
    return 'ลบ “$name” แล้ว';
  }

  @override
  String get movedToOtherGroup => 'ย้ายไปกลุ่มอื่นแล้ว';

  @override
  String get movedNote =>
      'ตอนนี้นับในกลุ่มนั้น ความคิดเห็นและประวัติยังอยู่ที่นี่';

  @override
  String get expenseWasDeleted => 'รายจ่ายนี้ถูกลบแล้ว';

  @override
  String get restoreToCount => 'กู้คืนเพื่อให้นับในยอดคงเหลืออีกครั้ง';

  @override
  String get tax => 'ภาษี';

  @override
  String get tipService => 'ทิปหรือค่าบริการ';

  @override
  String get discount => 'ส่วนลด';

  @override
  String youPaidOwe(String paid, String owe) {
    return 'คุณจ่าย $paid และค้างจ่าย $owe';
  }

  @override
  String youPaid(String amount) {
    return 'คุณจ่าย $amount';
  }

  @override
  String youOwe(String amount) {
    return 'คุณค้างจ่าย $amount';
  }

  @override
  String namePaidOwes(String name, String paid, String owe) {
    return '$name จ่าย $paid และค้างจ่าย $owe';
  }

  @override
  String namePaid(String name, String amount) {
    return '$name จ่าย $amount';
  }

  @override
  String nameOwes(String name, String amount) {
    return '$name ค้างจ่าย $amount';
  }

  @override
  String youReceivedGetBack(String received, String back) {
    return 'คุณได้รับ $received และได้คืน $back';
  }

  @override
  String youReceived(String amount) {
    return 'คุณได้รับ $amount';
  }

  @override
  String youGetBackLine(String amount) {
    return 'คุณได้คืน $amount';
  }

  @override
  String nameReceivedGetsBack(String name, String received, String back) {
    return '$name ได้รับ $received และได้คืน $back';
  }

  @override
  String nameReceived(String name, String amount) {
    return '$name ได้รับ $amount';
  }

  @override
  String nameGetsBack(String name, String amount) {
    return '$name ได้คืน $amount';
  }

  @override
  String get noHistoryYet => 'ยังไม่มีประวัติ';

  @override
  String get historyOffline => 'ประวัติจะแสดงที่นี่เมื่อคุณออนไลน์';

  @override
  String get showingSavedHistory => 'ประวัติที่บันทึกไว้';

  @override
  String get showMore => 'แสดงเพิ่ม';

  @override
  String get deleteCommentTitle => 'ลบความคิดเห็นหรือไม่';

  @override
  String get comments => 'ความคิดเห็น';

  @override
  String get noCommentsYet => 'ยังไม่มีความคิดเห็น';

  @override
  String get deleteComment => 'ลบความคิดเห็น';

  @override
  String get addComment => 'เพิ่มความคิดเห็น';

  @override
  String get send => 'ส่ง';

  @override
  String get filterByCategory => 'กรองตามหมวดหมู่';

  @override
  String get category => 'หมวดหมู่';

  @override
  String get categoryAll => 'ทั้งหมด';

  @override
  String get month => 'เดือน';

  @override
  String get searchUnavailable => 'ใช้การค้นหาไม่ได้';

  @override
  String get searchExpenses => 'ค้นหารายจ่าย';

  @override
  String get searchHelp =>
      'คำอธิบาย บันทึก ความคิดเห็น หมวดหมู่ และยอดเงิน: “แท็กซี่” “สนามบิน” “12.50”';

  @override
  String get noMatches => 'ไม่พบผลลัพธ์';

  @override
  String get noMatchesHelp => 'ลองคำอื่น หรือนำตัวกรองออก';

  @override
  String expenseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'รายจ่าย $count รายการ',
    );
    return '$_temp0';
  }

  @override
  String get searchAllGroups => 'ค้นหาในทุกกลุ่ม';

  @override
  String searchGroup(String name) {
    return 'ค้นหาใน $name';
  }

  @override
  String get searchThisGroup => 'ค้นหาในกลุ่มนี้';

  @override
  String get clear => 'ล้าง';

  @override
  String get thisGroup => 'กลุ่มนี้';

  @override
  String insightsError(String reason) {
    return 'แสดงข้อมูลเชิงลึกไม่ได้: $reason';
  }

  @override
  String get nothingToShow => 'ยังไม่มีอะไรให้แสดง';

  @override
  String get insightsEmptyHelp => 'ยอดรวมและกราฟจะแสดงเมื่อกลุ่มมีรายจ่าย';

  @override
  String get allTime => 'ตลอดเวลา';

  @override
  String get shareSummary => 'แชร์สรุป';

  @override
  String get printSummary => 'พิมพ์สรุป';

  @override
  String get previousMonth => 'เดือนก่อน';

  @override
  String get nextMonth => 'เดือนถัดไป';

  @override
  String get byMonth => 'ตามเดือน';

  @override
  String get groupSegment => 'กลุ่ม';

  @override
  String get mineSegment => 'ของฉัน';

  @override
  String get byCategory => 'ตามหมวดหมู่';

  @override
  String get noExpensesPeriod => 'ไม่มีรายจ่ายในช่วงนี้';

  @override
  String get byPerson => 'ตามคน';

  @override
  String get nobodyPaidPeriod => 'ไม่มีใครจ่ายหรือค้างจ่ายในช่วงนี้';

  @override
  String keptUntilConverted(String currency, String group) {
    return 'ยังคงเป็น $currency จนกว่าจะแปลงเป็น $group';
  }

  @override
  String get totalSpent => 'ใช้จ่ายทั้งหมด';

  @override
  String get yourShare => 'ส่วนของคุณ';

  @override
  String get paymentsMade => 'การชำระที่จ่ายไป';

  @override
  String get paymentsReceived => 'การชำระที่ได้รับ';

  @override
  String get youPaidRow => 'คุณจ่าย';

  @override
  String get balanceChange => 'การเปลี่ยนแปลงยอดของคุณ';

  @override
  String get paidLegend => 'จ่ายแล้ว';

  @override
  String get shareLegend => 'ส่วนแบ่ง';

  @override
  String paidShareLine(String paid, String share) {
    return 'จ่าย $paid · ส่วนแบ่ง $share';
  }

  @override
  String get itemsGiveEveryone => 'กำหนดคนให้ทุกรายการ';

  @override
  String get itemsAddPrices => 'ใส่ราคารายการก่อนภาษีหรือทิป';

  @override
  String get itemsDiscountTooBig => 'ส่วนลดมากกว่ายอดบิล';

  @override
  String get itemsDontAddUp => 'ยอดรายการไม่ตรงกัน';

  @override
  String get adjustmentsDontFit => 'ยอดปรับไม่พอดีกับยอดรวม';

  @override
  String get giveSomeoneShare => 'ให้ส่วนแบ่งกับใครสักคน';

  @override
  String get checkNumbers => 'ตรวจสอบตัวเลข';

  @override
  String get splitDoesntAddUp => 'ยอดการแบ่งไม่ตรงกัน';

  @override
  String get addTheItems => 'เพิ่มรายการ';

  @override
  String get pickOnePerson => 'เลือกอย่างน้อยหนึ่งคน';

  @override
  String splitEquallyBetween(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'หารเท่ากัน $count คน',
    );
    return '$_temp0';
  }

  @override
  String get allForOnePerson => '1 คนจ่ายทั้งหมด';

  @override
  String splitEquallyEach(int count, String amount) {
    return 'หารเท่ากัน $count คน · คนละ $amount';
  }

  @override
  String get checkAmounts => 'ตรวจสอบยอดเงิน';

  @override
  String get enterTotalFirst => 'ใส่ยอดรวมก่อน';

  @override
  String remaining(String amount) {
    return 'เหลือ: $amount';
  }

  @override
  String overBy(String amount) {
    return 'เกิน: $amount';
  }

  @override
  String get addsUp => 'ยอดตรงกัน';

  @override
  String sharesInTotal(String count) {
    return 'รวม $count ส่วน';
  }

  @override
  String get oneShareInTotal => 'รวม 1 ส่วน';

  @override
  String get restSplitEqually => 'ส่วนที่เหลือหารเท่ากัน';

  @override
  String get byPercent => 'ตามเปอร์เซ็นต์';

  @override
  String get byShares => 'ตามสัดส่วน';

  @override
  String get byAdjustment => 'ปรับ: เพิ่มหรือลดให้บางคน ส่วนที่เหลือเท่ากัน';

  @override
  String get modeEqual => 'เท่ากัน';

  @override
  String get modeExact => 'ระบุยอด';

  @override
  String get modeShares => 'สัดส่วน';

  @override
  String get byItem => 'ตามรายการจากใบเสร็จ';

  @override
  String get adjustmentHelp => 'เพิ่มหรือลดยอดให้บางคน ส่วนที่เหลือหารเท่ากัน';

  @override
  String get noMembers => 'ไม่มีสมาชิก';

  @override
  String itemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count รายการ',
    );
    return '$_temp0';
  }

  @override
  String get addAnItem => 'เพิ่มรายการ';

  @override
  String atMostItems(int max) {
    return 'ไม่เกิน $max รายการ';
  }

  @override
  String get giveItemName => 'ตั้งชื่อให้ทุกรายการ';

  @override
  String get itemNameTooLong => 'ชื่อรายการยาวเกินไป';

  @override
  String get addItem => 'เพิ่มรายการ';

  @override
  String get giveRestToEveryone => 'ให้ส่วนที่เหลือกับทุกคน';

  @override
  String get subtotal => 'ยอดย่อย';

  @override
  String get total => 'ยอดรวม';

  @override
  String receiptSays(String printed, String difference) {
    return 'ใบเสร็จระบุ $printed · รายการต่างกัน $difference';
  }

  @override
  String get eachPerson => 'แต่ละคน';

  @override
  String itemsWithoutPerson(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count รายการยังไม่มีคน',
    );
    return '$_temp0';
  }

  @override
  String get itemHint => 'รายการ';

  @override
  String memberLeft(String name) {
    return '$name (ออกแล้ว)';
  }

  @override
  String get whoHadThis => 'ใครเป็นคนสั่ง';

  @override
  String get defaultSplitStartsEqual =>
      'การแบ่งเริ่มต้นของกลุ่มไม่ตรงแล้ว รายจ่ายนี้จึงเริ่มแบบเท่ากัน';

  @override
  String leftToAssign(String amount) {
    return 'เหลือ $amount ให้แบ่ง';
  }

  @override
  String get itemsTotal => 'ยอดรวมของรายการ';

  @override
  String get newExpense => 'รายจ่ายใหม่';

  @override
  String get editExpense => 'แก้ไขรายจ่าย';

  @override
  String get scanReceipt => 'สแกนใบเสร็จ';

  @override
  String get rateAboveZeroOrEmpty => 'ใส่อัตราที่มากกว่า 0 หรือเว้นว่างไว้';

  @override
  String useAutoRate(String rate, String source) {
    return 'ใช้อัตราอัตโนมัติ: $rate ($source)';
  }

  @override
  String get description => 'คำอธิบาย';

  @override
  String get receivedBy => 'ผู้รับ';

  @override
  String get paidBy => 'ผู้จ่าย';

  @override
  String get severalPeople => 'หลายคน';

  @override
  String get when => 'เมื่อไร';

  @override
  String get refundTooltip => 'เงินที่ได้คืน เช่น เงินมัดจำที่โรงแรมคืนให้';

  @override
  String get splitBackTo => 'แบ่งคืนให้';

  @override
  String get split => 'การแบ่ง';

  @override
  String theyOweFull(String name) {
    return '$name ค้างจ่ายเต็มจำนวน';
  }

  @override
  String iOweFull(String name) {
    return 'ฉันค้างจ่าย $name เต็มจำนวน';
  }

  @override
  String get repeat => 'ทำซ้ำ';

  @override
  String editLatestRepeat(String date) {
    return 'หากต้องการเปลี่ยนการทำซ้ำครั้งต่อไป ให้แก้ไขรายการล่าสุด ($date)';
  }

  @override
  String get stopsRepeating => 'หยุดทำซ้ำ รายการที่เพิ่มไปแล้วยังอยู่';

  @override
  String nextRepeat(String date) {
    return 'ครั้งถัดไป: $date';
  }

  @override
  String get alsoChangeFuture => 'เปลี่ยนการทำซ้ำครั้งต่อไปด้วย';

  @override
  String get futureFields =>
      'ยอดเงิน การแบ่ง ผู้จ่าย คำอธิบาย หมวดหมู่ และบันทึก';

  @override
  String get onlyThisOne => 'เปลี่ยนเฉพาะรายการนี้';

  @override
  String get addPhoto => 'เพิ่มรูปภาพ';

  @override
  String maxReceiptsNote(int max) {
    return 'รายจ่ายหนึ่งรายการมีใบเสร็จได้สูงสุด $max ใบ';
  }

  @override
  String get scanAReceipt => 'สแกนใบเสร็จ';

  @override
  String receiptLooksLike(String currency) {
    return 'ใบเสร็จนี้ดูเหมือนเป็น $currency';
  }

  @override
  String switchToCurrencyQuestion(String currency) {
    return 'เปลี่ยนรายจ่ายเป็น $currency เพื่ออ่านรายการหรือไม่';
  }

  @override
  String switchTo(String currency) {
    return 'เปลี่ยนเป็น $currency';
  }

  @override
  String get couldntReadItems => 'อ่านรายการไม่ได้ โปรดพิมพ์เอง';

  @override
  String withName(String name) {
    return 'กับ $name';
  }

  @override
  String movesTo(String name) {
    return 'จะย้ายไป $name เมื่อบันทึก';
  }

  @override
  String fromName(String name) {
    return 'จาก $name';
  }

  @override
  String get dontMove => 'ไม่ย้าย';

  @override
  String get onlyLinkedMove =>
      'ย้ายได้เฉพาะคนที่ใช้ Evensies และอยู่ทั้งสองที่';

  @override
  String get auto => 'อัตโนมัติ';

  @override
  String get noAutoRateForm =>
      'ไม่มีอัตราอัตโนมัติ ใส่เองหรือเว้นว่างเพื่อให้อยู่ใน “ยังไม่แปลง”';

  @override
  String get emptyNotConverted => 'เว้นว่าง: อยู่ใน “ยังไม่แปลง”';

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
  String get yourRate => 'อัตราที่คุณใส่';
}
