import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/product.dart';
import 'product_visuals.dart';

class ProductHeroImage extends StatelessWidget {
  final ProductDetail detail;

  const ProductHeroImage({super.key, required this.detail});

  @override
  Widget build(BuildContext context) {
    final imageProvider = productImageProvider(detail);
    final height = (MediaQuery.sizeOf(context).width * 0.66)
        .clamp(220.0, 276.0)
        .toDouble();

    return Padding(
      key: const Key('productDetailHeroImage'),
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: double.infinity,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (imageProvider != null)
                Image(image: imageProvider, fit: BoxFit.cover)
              else
                const DecoratedBox(
                  decoration: BoxDecoration(color: AppColors.surfaceSky),
                  child: Center(
                    child: Icon(
                      Icons.set_meal_rounded,
                      size: 72,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              Positioned(top: 12, right: 12, child: _StockPill(detail: detail)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StockPill extends StatelessWidget {
  final Product detail;

  const _StockPill({required this.detail});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: productStockBgColor(detail),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12052449),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              detail.isAvailable
                  ? Icons.check_circle_outline_rounded
                  : Icons.highlight_off_rounded,
              size: 16,
              color: productStockTextColor(detail),
            ),
            const SizedBox(width: 5),
            Text(
              productStockQuantityLabel(detail),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: productStockTextColor(detail),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
