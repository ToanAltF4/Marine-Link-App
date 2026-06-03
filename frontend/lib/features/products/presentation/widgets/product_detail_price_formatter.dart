import 'package:intl/intl.dart';

final _vndNumberFormatter = NumberFormat.decimalPattern('vi_VN');

String productDetailUnitPrice(num amount, String unit) {
  return '${productDetailVnd(amount)}/$unit';
}

String productDetailVnd(num amount) {
  return '${_vndNumberFormatter.format(amount.round())}\u0111';
}
