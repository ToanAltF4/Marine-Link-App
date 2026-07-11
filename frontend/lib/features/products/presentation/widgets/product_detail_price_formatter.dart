import 'package:intl/intl.dart';
import 'package:marinelink/core/constants/app_strings.dart';

final _vndNumberFormatter = NumberFormat.decimalPattern('vi_VN');

String productDetailUnitPrice(num amount, String unit) {
  return '${productDetailVnd(amount)}/$unit';
}

String productDetailVnd(num amount) {
  return '${_vndNumberFormatter.format(amount.round())}${AppStrings.currencySymbol}';
}
