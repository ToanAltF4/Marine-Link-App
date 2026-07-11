import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:marinelink/core/constants/app_strings.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/order.dart';

/// Bảng tổng hợp thanh toán: tạm tính, phí vận chuyển, giảm giá và tổng cộng.
class OrderPaymentSummary extends StatelessWidget {
  final OrderDetail order;

  const OrderPaymentSummary({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OrderSummaryRow(
          label: AppStrings.subtotalLabel,
          value: _currency(order.subtotalAmount),
        ),
        OrderSummaryRow(
          label: AppStrings.shippingFeeLabel,
          value: _currency(order.shippingFee),
        ),
        OrderSummaryRow(
          label: AppStrings.discountLabel,
          value: '-${_currency(order.discountAmount)}',
          valueColor: AppColors.success,
        ),
        const Divider(height: 24),
        OrderSummaryRow(
          label: AppStrings.totalLabel,
          value: _currency(order.totalAmount),
          emphasized: true,
        ),
      ],
    );
  }
}

/// Một dòng nhãn - giá trị trong bảng tổng hợp thanh toán.
class OrderSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool emphasized;

  const OrderSummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.emphasized = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: emphasized ? FontWeight.w900 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? AppColors.primary,
              fontWeight: emphasized ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

String _currency(double value) {
  return NumberFormat.currency(
    locale: 'vi_VN',
    symbol: AppStrings.currencySymbol,
    decimalDigits: 0,
  ).format(value);
}
