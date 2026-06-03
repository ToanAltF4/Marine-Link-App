import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

class ProductDetailHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onNotifications;

  const ProductDetailHeader({
    super.key,
    required this.onBack,
    required this.onNotifications,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.background,
      child: SizedBox(
        height: 58,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Text(
                'Chi tiết sản phẩm',
                key: const Key('productDetailLogo'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                  fontFamily: 'serif',
                ),
              ),
            ),
            Positioned(
              left: 6,
              top: 4,
              bottom: 4,
              child: IconButton(
                onPressed: onBack,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 22),
                color: AppColors.primaryDark,
                tooltip: 'Quay lại',
              ),
            ),
            Positioned(
              right: 6,
              top: 4,
              bottom: 4,
              child: IconButton(
                onPressed: onNotifications,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.notifications_none_rounded, size: 24),
                color: AppColors.primaryDark,
                tooltip: 'Thông báo',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
