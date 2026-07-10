import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../cart/domain/cart_pricing.dart';

const _bulkPromotionTitle = 'Ưu đãi mua nhiều';
const _bulkPromotionBannerText =
    'Giảm đến 8% cho đơn hàng từ ${CartBulkDiscountPolicy.eightPercentMinQuantity}kg';

/// Banner khuyến mãi mua nhiều ở đầu trang chủ, có nút mở danh sách sản phẩm.
class PromoBanner extends StatelessWidget {
  final VoidCallback onTap;

  const PromoBanner({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final compact = MediaQuery.sizeOf(context).width < 560;

    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0D4C97), Color(0xFF087B87)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x220B4F8F),
                blurRadius: 22,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: SizedBox(height: compact ? 136 : 160),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _DotPatternPainter()),
          ),
        ),
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFA726),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Ưu đãi',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SizedBox(height: compact ? 6 : 10),
                Text(
                  _bulkPromotionTitle,
                  style:
                      (compact
                              ? theme.textTheme.titleMedium
                              : theme.textTheme.titleLarge)
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                ),
                SizedBox(height: compact ? 4 : 6),
                Text(
                  _bulkPromotionBannerText,
                  style:
                      (compact
                              ? theme.textTheme.bodyMedium
                              : theme.textTheme.bodyLarge)
                          ?.copyWith(
                            color: Colors.white.withValues(alpha: 0.94),
                            fontWeight: FontWeight.w500,
                          ),
                ),
                const Spacer(),
                Align(
                  alignment: Alignment.bottomRight,
                  child: FilledButton(
                    key: const Key('homeQuickSearchButton'),
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFE8F4FF),
                      foregroundColor: AppColors.primaryDark,
                      minimumSize: Size(0, compact ? 32 : 40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: compact
                          ? theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            )
                          : null,
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 12 : 18,
                        vertical: compact ? 6 : 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: const Text('Xem ngay'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.16);
    const step = 20.0;
    const radius = 1.2;

    for (double x = 8; x < size.width; x += step) {
      for (double y = 8; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
