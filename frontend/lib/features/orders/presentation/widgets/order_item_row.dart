import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/order.dart';

/// Một dòng sản phẩm trong đơn: ảnh, tên, đơn giá, số lượng và thành tiền.
class OrderItemRow extends StatelessWidget {
  final OrderItem item;

  const OrderItemRow({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF8FB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: OrderItemImage(imageUrl: item.productImageUrl),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productNameSnapshot,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  'Đơn giá: ${_currency(item.unitPrice)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  'x ${item.quantity} ${item.productUnitSnapshot}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _currency(item.lineTotal),
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ảnh sản phẩm của dòng đơn, tự thay thế bằng icon khi thiếu ảnh hoặc lỗi tải.
class OrderItemImage extends StatelessWidget {
  final String? imageUrl;

  const OrderItemImage({super.key, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    if (url == null || url.isEmpty) {
      return const Icon(Icons.set_meal_outlined, color: AppColors.primary);
    }
    return Image.network(
      url,
      key: const Key('orderItemProductImage'),
      width: 54,
      height: 54,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) =>
          const Icon(Icons.set_meal_outlined, color: AppColors.primary),
    );
  }
}

String _currency(double value) {
  return NumberFormat.currency(
    locale: 'vi_VN',
    symbol: 'đ',
    decimalDigits: 0,
  ).format(value);
}
