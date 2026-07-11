import 'package:flutter/material.dart';
import 'package:marinelink/core/constants/app_strings.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/product.dart';
import 'product_detail_card.dart';

class ProductInformationCard extends StatelessWidget {
  final ProductDetail detail;

  const ProductInformationCard({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ProductDetailCard(
      key: const Key('productDetailInfoCard'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.productDetailInfoTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            detail.description ?? AppStrings.productDescriptionPending,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 20 / 13,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          const _PackagingSpec(),
        ],
      ),
    );
  }
}

class _PackagingSpec extends StatelessWidget {
  const _PackagingSpec();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      key: const Key('productDetailPackagingSpec'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSky,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD8E7EF)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            color: Color(0xFF007C89),
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.packagingSpecTitle,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppStrings.defaultPackagingSpec,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
