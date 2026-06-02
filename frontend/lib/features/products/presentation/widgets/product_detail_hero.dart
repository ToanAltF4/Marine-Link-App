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
        .clamp(228.0, 282.0)
        .toDouble();

    return SizedBox(
      key: const Key('productDetailHeroImage'),
      width: double.infinity,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageProvider != null)
            Image(image: imageProvider, fit: BoxFit.cover)
          else
            const DecoratedBox(
              decoration: BoxDecoration(color: Color(0xFFEAF6FF)),
              child: Center(
                child: Icon(
                  Icons.set_meal_rounded,
                  size: 74,
                  color: AppColors.primary,
                ),
              ),
            ),
          Positioned(top: 12, right: 12, child: _StockPill(detail: detail)),
        ],
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
        color: detail.isAvailable ? const Color(0xFF22C55E) : AppColors.error,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle_outline_rounded,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 5),
            Text(
              productStockLabel(detail),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
