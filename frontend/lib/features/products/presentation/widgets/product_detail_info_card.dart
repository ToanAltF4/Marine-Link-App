import 'package:flutter/material.dart';

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
            'Th\u00f4ng tin chi ti\u1ebft',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            detail.description ??
                'S\u1ea3n ph\u1ea9m \u0111ang \u0111\u01b0\u1ee3c b\u1ed5 sung m\u00f4 t\u1ea3 chi ti\u1ebft.',
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
                  'Quy c\u00e1ch \u0111\u00f3ng g\u00f3i',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'T\u00fai 1kg / Th\u00f9ng 20kg',
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
