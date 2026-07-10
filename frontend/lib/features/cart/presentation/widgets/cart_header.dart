import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

/// Thanh tiêu đề của màn giỏ hàng kèm nút quay lại.
class CartHeader extends StatelessWidget {
  final VoidCallback onBack;

  const CartHeader({super.key, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF5F7FC),
      child: SizedBox(
        height: 50,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Center(
              child: Text(
                'Giỏ hàng của bạn',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primaryDark,
                  fontFamily: 'serif',
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Positioned(
              left: 4,
              top: 2,
              bottom: 2,
              child: IconButton(
                onPressed: onBack,
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 21),
                color: AppColors.primaryDark,
                tooltip: 'Quay lại',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
