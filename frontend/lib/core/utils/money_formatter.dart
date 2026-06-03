import 'package:intl/intl.dart';

/// Money / number formatting for VND prices.
abstract class MoneyFormatter {
  static final _vndFormatter = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  static final _compactFormatter = NumberFormat.compactCurrency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  /// Format as full VND: e.g. 450,000₫
  static String format(num amount) => _vndFormatter.format(amount);

  /// Format compact: e.g. 450K₫, 4,2M₫
  static String compact(num amount) => _compactFormatter.format(amount);

  /// Format price tier label: "2–9 kg: 450,000₫/kg"
  static String tierLabel({
    required num unitPrice,
    required int minQty,
    int? maxQty,
    String unit = 'kg',
  }) {
    final priceStr = format(unitPrice);
    final rangeStr = maxQty != null ? '$minQty–$maxQty' : 'Từ $minQty';
    return '$rangeStr $unit: $priceStr/$unit';
  }
}
