import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../domain/product.dart';
import 'product_visuals.dart';
import 'package:marinelink/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:marinelink/features/auth/presentation/bloc/auth_state.dart';

/// Thẻ sản phẩm trong danh sách, hiển thị ảnh, tên, xuất xứ, giá và nút mở chi tiết.
class ProductListCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductListCard({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageProvider = productImageProvider(product);
    final fallbackVisual = productVisualStyle(product);

    final authState = context.watch<AuthBloc>().state;
    final isPending = authState is AuthAuthenticated &&
        authState.user.status == 'PENDING_APPROVAL';

    return InkWell(
      key: Key('productCard-${product.id}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12052449),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(18),
              ),
              child: Container(
                height: 168,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      fallbackVisual.startColor.withValues(alpha: 0.92),
                      fallbackVisual.endColor.withValues(alpha: 0.88),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  image: imageProvider != null
                      ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                      : null,
                ),
                child: Stack(
                  children: [
                    if (imageProvider == null)
                      Align(
                        alignment: Alignment.center,
                        child: Icon(
                          fallbackVisual.icon,
                          color: Colors.white,
                          size: 54,
                        ),
                      ),
                    Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        margin: const EdgeInsets.all(12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: productStockBgColor(product),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          productStockQuantityLabel(product),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: productStockTextColor(product),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayProductName(product),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (product.shortDescription?.trim().isNotEmpty ?? false)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        product.shortDescription!.trim(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.3,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          displayOrigin(product.origin),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isPending
                        ? 'Giá sản phẩm: Đang xét duyệt'
                        : 'Giá từ (MOQ ${product.minOrderQuantity}${product.unit})',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isPending
                          ? Colors.orange.shade800
                          : AppColors.textPrimary,
                      fontWeight: isPending ? FontWeight.w700 : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (!isPending)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: AppColors.textPrimary,
                              ),
                              children: [
                                TextSpan(
                                  text:
                                      MoneyFormatter.format(product.basePrice),
                                  style:
                                      theme.textTheme.headlineSmall?.copyWith(
                                    color: AppColors.primaryDark,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                TextSpan(
                                  text: ' đ/${product.unit}',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: onTap,
                          borderRadius: BorderRadius.circular(999),
                          child: Ink(
                            width: 42,
                            height: 42,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.shopping_cart_checkout_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
