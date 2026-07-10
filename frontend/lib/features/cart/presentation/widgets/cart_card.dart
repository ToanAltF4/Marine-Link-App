import 'package:flutter/material.dart';

const _cartSurfaceRadius = 18.0;
const _cartSurfaceBorder = Color(0xFFE4EEF5);
const _cartSurfaceShadow = BoxShadow(
  color: Color(0x12052449),
  blurRadius: 18,
  offset: Offset(0, 8),
);

/// Khung thẻ trắng bo góc dùng chung cho các phần của giỏ hàng.
class CartCard extends StatelessWidget {
  final Widget child;
  final bool selected;

  const CartCard({super.key, required this.child, this.selected = true});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(_cartSurfaceRadius),
        border: Border.all(
          color: selected ? _cartSurfaceBorder : const Color(0xFFD9E5EF),
        ),
        boxShadow: const [_cartSurfaceShadow],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: child,
      ),
    );
  }
}
