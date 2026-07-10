import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../products/domain/product.dart';
import '../../../products/presentation/widgets/product_visuals.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

/// Thẻ sản phẩm bán chạy trong lưới nổi bật ở trang chủ.
class HotProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const HotProductCard({super.key, required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageProvider = productImageProvider(product);
    final compact = MediaQuery.sizeOf(context).width < 560;
    final imageHeight = compact ? 108.0 : 160.0;
    final contentPadding = compact ? 9.0 : 14.0;

    final authState = context.watch<AuthBloc>().state;
    final isPending = authState is AuthAuthenticated &&
        authState.user.status == 'PENDING_APPROVAL';

    return InkWell(
      key: Key('featuredProductCard-${product.id}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12052449),
              blurRadius: 20,
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
                height: imageHeight,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFD6E7FF),
                  image: imageProvider != null
                      ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
                      : null,
                ),
                child: Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: productStockBgColor(product),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      productStockLabel(product),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: productStockTextColor(product),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  contentPadding,
                  contentPadding,
                  contentPadding,
                  contentPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayProductName(product),
                      maxLines: compact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          (compact
                                  ? theme.textTheme.titleMedium?.copyWith(
                                      fontSize: 14,
                                      height: 1.1,
                                    )
                                  : theme.textTheme.titleLarge)
                              ?.copyWith(
                                color: AppColors.primaryDark,
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                    SizedBox(height: compact ? 3 : 6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: compact ? 14 : 18,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: compact ? 3 : 4),
                        Expanded(
                          child: Text(
                            displayOrigin(product.origin),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                (compact
                                        ? theme.textTheme.bodySmall?.copyWith(
                                            fontSize: 11,
                                            height: 1.1,
                                          )
                                        : theme.textTheme.bodyLarge)
                                    ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    isPending
                        ? Text(
                            'Đang xét duyệt',
                            style: (compact
                                    ? theme.textTheme.titleMedium?.copyWith(
                                      fontSize: 14,
                                      height: 1.1,
                                    )
                                    : theme.textTheme.titleLarge)
                                ?.copyWith(
                              color: Colors.orange.shade800,
                              fontWeight: FontWeight.w800,
                            ),
                          )
                        : RichText(
                            text: TextSpan(
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: AppColors.textPrimary,
                              ),
                              children: [
                                TextSpan(
                                  text:
                                      MoneyFormatter.format(product.basePrice),
                                  style:
                                      (compact
                                              ? theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                fontSize: 14,
                                                height: 1.1,
                                              )
                                              : theme.textTheme.titleLarge)
                                          ?.copyWith(
                                    color: const Color(0xFF006A7C),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                TextSpan(
                                  text: '/${product.unit}',
                                  style:
                                      (compact
                                              ? theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                fontSize: 11,
                                                height: 1.1,
                                              )
                                              : theme.textTheme.bodyLarge)
                                          ?.copyWith(
                                              color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                    SizedBox(height: compact ? 3 : 6),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 9 : 10,
                        vertical: compact ? 3 : 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F1FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'MOQ: ${product.minOrderQuantity}${product.unit}',
                        style:
                            (compact
                                    ? theme.textTheme.bodySmall?.copyWith(
                                        fontSize: 11,
                                        height: 1.1,
                                      )
                                    : theme.textTheme.bodyMedium)
                                ?.copyWith(color: AppColors.primaryDark),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
