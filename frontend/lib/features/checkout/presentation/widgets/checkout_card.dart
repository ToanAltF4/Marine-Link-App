import 'package:flutter/material.dart';

/// Khung thẻ trắng bo góc dùng chung cho các phần của màn thanh toán.
class CheckoutCard extends StatelessWidget {
  final Widget child;

  const CheckoutCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4EEF5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12052449),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: child,
      ),
    );
  }
}
