import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/admin_product.dart';
import '../cubit/admin_product_cubit.dart';
import 'admin_product_styles.dart';

/// Thẻ hiển thị một sản phẩm với thông tin, trạng thái và thao tác sửa/xoá.
class AdminProductCard extends StatelessWidget {
  final AdminProduct product;
  final bool editing;
  final bool deleting;
  final VoidCallback onEdit;

  const AdminProductCard({
    super.key,
    required this.product,
    required this.editing,
    required this.deleting,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final statusStyle = _statusStyle(product.status);
    return DecoratedBox(
      key: Key('adminProductCard_${product.id}'),
      decoration: adminProductCardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProductThumb(product: product),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.category?.name ?? product.slug,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                _StatusPill(
                  label: statusStyle.label,
                  textColor: statusStyle.textColor,
                  backgroundColor: statusStyle.backgroundColor,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetaLine(
                    icon: Icons.sell_outlined,
                    text:
                        '${MoneyFormatter.format(product.basePrice)}/${product.unit}',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetaLine(
                    icon: Icons.inventory_outlined,
                    text:
                        '${product.stockQuantity} ${product.unit} - tối thiểu ${product.minOrderQuantity}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (product.isFeatured)
                  const _SmallBadge(
                    key: Key('adminProductFeaturedBadge'),
                    label: 'Nổi bật',
                    icon: Icons.star_outline,
                  ),
                const Spacer(),
                IconButton(
                  key: Key('adminProductEditButton_${product.id}'),
                  tooltip: 'Sửa sản phẩm',
                  onPressed: editing ? null : onEdit,
                  icon: editing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  key: Key('adminProductDeleteButton_${product.id}'),
                  tooltip: 'Xoá sản phẩm',
                  color: AppColors.error,
                  onPressed: deleting
                      ? null
                      : () => context.read<AdminProductCubit>().deleteProduct(
                          product.id,
                        ),
                  icon: deleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Ảnh thu nhỏ của sản phẩm, hỗ trợ ảnh mạng, ảnh asset và ảnh mặc định.
class ProductThumb extends StatelessWidget {
  final AdminProduct product;

  const ProductThumb({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 58,
        height: 58,
        child: imageUrl == null || imageUrl.isEmpty
            ? const ColoredBox(
                color: AppColors.surfaceSky,
                child: Icon(Icons.image_outlined, color: AppColors.primary),
              )
            : imageUrl.startsWith('http')
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: AppColors.surfaceSky,
                  child: Icon(Icons.image_outlined, color: AppColors.primary),
                ),
              )
            : Image.asset(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: AppColors.surfaceSky,
                  child: Icon(Icons.image_outlined, color: AppColors.primary),
                ),
              ),
      ),
    );
  }
}

/// Dòng thông tin phụ có biểu tượng đứng trước, cắt bớt khi quá dài.
class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

/// Huy hiệu nhỏ bo tròn hiển thị nhãn kèm biểu tượng.
class _SmallBadge extends StatelessWidget {
  final String label;
  final IconData icon;

  const _SmallBadge({super.key, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceSky,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nhãn trạng thái bo tròn với màu chữ và nền tuỳ theo trạng thái sản phẩm.
class _StatusPill extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color backgroundColor;

  const _StatusPill({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

({String label, Color textColor, Color backgroundColor}) _statusStyle(
  AdminProductStatus status,
) {
  return switch (status) {
    AdminProductStatus.active => (
      label: 'Đang bán',
      textColor: AppColors.success,
      backgroundColor: const Color(0xFFE8F8EF),
    ),
    AdminProductStatus.outOfStock => (
      label: 'Hết hàng',
      textColor: AppColors.warning,
      backgroundColor: const Color(0xFFFFF7E6),
    ),
    AdminProductStatus.disabled => (
      label: 'Tạm ẩn',
      textColor: AppColors.error,
      backgroundColor: const Color(0xFFFFEFEF),
    ),
  };
}
