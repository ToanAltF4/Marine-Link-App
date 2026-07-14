import 'package:intl/intl.dart';

/// Định dạng thời gian theo **giờ Việt Nam (GMT+7)**, độc lập với múi giờ của
/// thiết bị.
///
/// Backend gửi mốc thời gian dạng UTC (ISO-8601 có `Z`). Nếu format trực tiếp
/// sẽ hiển thị giờ UTC (lệch 7 tiếng). Các hàm dưới luôn quy về UTC rồi cộng
/// +7 giờ trước khi format nên kết quả luôn đúng giờ Việt Nam.
abstract class DateTimeFormatter {
  static const Duration _vnOffset = Duration(hours: 7);

  static DateTime toVietnam(DateTime dt) => dt.toUtc().add(_vnOffset);

  /// `dd/MM/yyyy HH:mm`
  static String fullDateTime(DateTime dt) =>
      DateFormat('dd/MM/yyyy HH:mm').format(toVietnam(dt));

  /// `dd/MM/yyyy - hh:mm a`
  static String dateTime12h(DateTime dt) =>
      DateFormat('dd/MM/yyyy - hh:mm a').format(toVietnam(dt));

  /// `dd/MM HH:mm`
  static String shortDateTime(DateTime dt) =>
      DateFormat('dd/MM HH:mm').format(toVietnam(dt));

  /// `HH:mm dd/MM`
  static String timeThenDate(DateTime dt) =>
      DateFormat('HH:mm dd/MM').format(toVietnam(dt));
}
