import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/product.dart';
import 'product_detail_card.dart';
import 'product_detail_price_formatter.dart';
import 'product_visuals.dart';

class WholesalePricingCard extends StatelessWidget {
  final ProductDetail detail;

  const WholesalePricingCard({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = _buildWholesaleRows(detail);

    return ProductDetailCard(
      key: const Key('productDetailWholesaleCard'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayProductName(detail),
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w900,
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
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Gi\u00e1 s\u1ec9 t\u1eeb:',
            style: theme.textTheme.bodyLarge?.copyWith(
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
                      fontWeight: FontWeight.w900,
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
                    'D\u1eb7t t\u1ed1i thi\u1ec3u ${detail.minOrderQuantity}${detail.unit}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: const Color(0xFF007C89),
                      fontWeight: FontWeight.w700,
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
            'B\u1ea3ng gi\u00e1 s\u1ec9',
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w900,
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
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w500,
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
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: row.isContact
                          ? const Color(0xFF007C89)
                          : AppColors.primaryDark,
                      fontWeight: FontWeight.w900,
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
        priceLabel: 'Li\u00ean h\u1ec7',
        isContact: true,
      ),
    );
  }

  if (rows.isEmpty) {
    rows.add(
      _WholesaleRow(
        rangeLabel: 'T\u1eeb ${detail.minOrderQuantity} ${detail.unit}',
        priceLabel: productDetailUnitPrice(detail.basePrice, detail.unit),
      ),
    );
  }
  return rows;
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
