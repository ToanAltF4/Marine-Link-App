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
    return SizedBox(
      height: 56,
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
                  ),
            ),
          ),
          Positioned(
            left: 6,
            top: 4,
            bottom: 4,
            child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.primaryDark,
              tooltip: 'Quay lai',
            ),
          ),
          Positioned(
            right: 6,
            top: 4,
            bottom: 4,
            child: IconButton(
              onPressed: onNotifications,
              icon: const Icon(Icons.notifications_none_rounded),
              color: AppColors.textPrimary,
              tooltip: 'Thong bao',
            ),
          ),
        ],
      ),
    );
  }
}
