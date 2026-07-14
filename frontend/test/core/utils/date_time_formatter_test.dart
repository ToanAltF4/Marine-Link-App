import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/core/utils/date_time_formatter.dart';

void main() {
  group('DateTimeFormatter (giờ Việt Nam +7)', () {
    test('quy đổi mốc UTC sang giờ VN đúng định dạng', () {
      // 03:00 UTC ngày 11/07/2026 = 10:00 giờ Việt Nam.
      final utc = DateTime.utc(2026, 7, 11, 3, 0);
      expect(DateTimeFormatter.fullDateTime(utc), '11/07/2026 10:00');
      expect(DateTimeFormatter.shortDateTime(utc), '11/07 10:00');
      expect(DateTimeFormatter.timeThenDate(utc), '10:00 11/07');
    });

    test('vượt sang ngày hôm sau khi +7 giờ', () {
      // 20:30 UTC = 03:30 hôm sau giờ VN.
      final utc = DateTime.utc(2026, 7, 11, 20, 30);
      expect(DateTimeFormatter.fullDateTime(utc), '12/07/2026 03:30');
    });
  });
}
