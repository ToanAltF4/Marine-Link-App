import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:marinelink/core/constants/app_strings.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../cart/domain/cart_pricing.dart';
import '../../domain/product.dart';
import 'product_detail_card.dart';
import 'product_detail_price_formatter.dart';
import 'product_visuals.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class WholesalePricingCard extends StatelessWidget {
  final ProductDetail detail;

  const WholesalePricingCard({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = _buildWholesaleRows(detail);

    final authState = context.watch<AuthBloc>().state;
    final isPending =
        authState is AuthAuthenticated &&
        authState.user.status == 'PENDING_APPROVAL';

    return ProductDetailCard(
      key: const Key('productDetailWholesaleCard'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayProductName(detail),
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  displayOrigin(detail.origin),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (isPending) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lock_clock_outlined,
                    color: Colors.orange.shade800,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      AppStrings.productPricePending,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.orange.shade900,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Text(
              AppStrings.wholesalePriceFrom,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      productDetailUnitPrice(detail.basePrice, detail.unit),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppColors.primary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDF7FA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    child: Text(
                      AppStrings.minOrderQuantity(
                        detail.minOrderQuantity,
                        detail.unit,
                      ),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: const Color(0xFF007C89),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Divider(height: 1, color: Color(0xFFEAF0F5)),
            const SizedBox(height: 14),
            Text(
              AppStrings.wholesalePriceTable,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            for (var i = 0; i < rows.length; i++) ...[
              _WholesalePriceRow(
                key: rows[i].keyId == null
                    ? null
                    : Key('priceTier-${rows[i].keyId}'),
                row: rows[i],
              ),
              if (i != rows.length - 1)
                const Divider(height: 1, color: Color(0xFFF0F4F8)),
            ],
          ],
        ],
      ),
    );
  }
}

class _WholesalePriceRow extends StatelessWidget {
  final _WholesaleRow row;

  const _WholesalePriceRow({super.key, required this.row});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              row.rangeLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    row.priceLabel,
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: row.isContact
                          ? const Color(0xFF007C89)
                          : AppColors.primaryDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (row.discountLabel != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    row.discountLabel!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.success,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WholesaleRow {
  final String? keyId;
  final String rangeLabel;
  final String priceLabel;
  final String? discountLabel;
  final bool isContact;

  const _WholesaleRow({
    this.keyId,
    required this.rangeLabel,
    required this.priceLabel,
    this.discountLabel,
    this.isContact = false,
  });
}

List<_WholesaleRow> _buildWholesaleRows(ProductDetail detail) {
  if (detail.unit == 'kg') {
    return _buildBulkDiscountPolicyRows(detail);
  }

  final sortedTiers = [...detail.priceTiers]
    ..sort((a, b) => a.minQuantity.compareTo(b.minQuantity));
  final showContactRow = _shouldShowContactRow(detail, sortedTiers);

  final rows = <_WholesaleRow>[];
  for (final tier in sortedTiers) {
    final displayMax = showContactRow && tier == sortedTiers.last
        ? 499
        : tier.maxQuantity;
    rows.add(
      _WholesaleRow(
        keyId: tier.id,
        rangeLabel: _formatQuantityRange(
          minQuantity: tier.minQuantity,
          maxQuantity: displayMax,
          unit: detail.unit,
        ),
        priceLabel: productDetailUnitPrice(tier.unitPrice, detail.unit),
        discountLabel: _formatDiscount(detail.basePrice, tier.unitPrice),
      ),
    );
  }

  if (showContactRow) {
    rows.add(
      _WholesaleRow(
        rangeLabel: '500 ${detail.unit}+',
        priceLabel: AppStrings.contact,
        isContact: true,
      ),
    );
  }

  if (rows.isEmpty) {
    rows.add(
      _WholesaleRow(
        rangeLabel: AppStrings.quantityFrom(
          detail.minOrderQuantity,
          detail.unit,
        ),
        priceLabel: productDetailUnitPrice(detail.basePrice, detail.unit),
      ),
    );
  }
  return rows;
}

List<_WholesaleRow> _buildBulkDiscountPolicyRows(ProductDetail detail) {
  return [
    _bulkDiscountPolicyRow(
      detail: detail,
      keyId: 'bulk-50-99',
      minQuantity: CartBulkDiscountPolicy.twoPercentMinQuantity,
      maxQuantity: CartBulkDiscountPolicy.fourPercentMinQuantity - 1,
      discountRate: CartBulkDiscountPolicy.twoPercent,
    ),
    _bulkDiscountPolicyRow(
      detail: detail,
      keyId: 'bulk-100-199',
      minQuantity: CartBulkDiscountPolicy.fourPercentMinQuantity,
      maxQuantity: CartBulkDiscountPolicy.sixPercentMinQuantity - 1,
      discountRate: CartBulkDiscountPolicy.fourPercent,
    ),
    _bulkDiscountPolicyRow(
      detail: detail,
      keyId: 'bulk-200-499',
      minQuantity: CartBulkDiscountPolicy.sixPercentMinQuantity,
      maxQuantity: CartBulkDiscountPolicy.eightPercentMinQuantity - 1,
      discountRate: CartBulkDiscountPolicy.sixPercent,
    ),
    _bulkDiscountPolicyRow(
      detail: detail,
      keyId: 'bulk-500-plus',
      minQuantity: CartBulkDiscountPolicy.eightPercentMinQuantity,
      maxQuantity: null,
      discountRate: CartBulkDiscountPolicy.eightPercent,
    ),
  ];
}

_WholesaleRow _bulkDiscountPolicyRow({
  required ProductDetail detail,
  required String keyId,
  required int minQuantity,
  required int? maxQuantity,
  required double discountRate,
}) {
  return _WholesaleRow(
    keyId: keyId,
    rangeLabel: _formatQuantityRange(
      minQuantity: minQuantity,
      maxQuantity: maxQuantity,
      unit: detail.unit,
    ),
    priceLabel: productDetailUnitPrice(
      detail.basePrice * (1 - discountRate),
      detail.unit,
    ),
    discountLabel: _formatPolicyDiscount(discountRate),
  );
}

bool _shouldShowContactRow(ProductDetail detail, List<PriceTier> sortedTiers) {
  if (detail.unit != 'kg' || sortedTiers.isEmpty) {
    return false;
  }
  final lastTier = sortedTiers.last;
  return lastTier.maxQuantity == null && lastTier.minQuantity < 500;
}

String _formatQuantityRange({
  required int minQuantity,
  required int? maxQuantity,
  required String unit,
}) {
  if (maxQuantity == null) {
    return '$minQuantity $unit+';
  }
  return '$minQuantity - $maxQuantity $unit';
}

String? _formatDiscount(num basePrice, num unitPrice) {
  if (basePrice <= 0 || unitPrice >= basePrice) {
    return null;
  }
  final discount = (((basePrice - unitPrice) / basePrice) * 100).round();
  if (discount <= 0) {
    return null;
  }
  return '(-$discount%)';
}

String _formatPolicyDiscount(double discountRate) {
  return '(-${(discountRate * 100).round()}%)';
}
