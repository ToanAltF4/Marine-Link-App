import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';

/// Bố cục nền của màn thanh toán: header + phần nội dung co giãn.
class CheckoutScaffold extends StatelessWidget {
  final Widget child;
  final VoidCallback onBack;

  const CheckoutScaffold({super.key, required this.child, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            CheckoutHeader(onBack: onBack),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

/// Thanh tiêu đề "Thanh toán" kèm nút quay lại.
class CheckoutHeader extends StatelessWidget {
  final VoidCallback onBack;

  const CheckoutHeader({super.key, required this.onBack});

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
                'Thanh toán',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.primaryDark,
                  fontFamily: 'serif',
                  fontWeight: FontWeight.w700,
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
          ],
        ),
      ),
    );
  }
}
