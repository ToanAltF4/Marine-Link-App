import 'package:flutter/material.dart';

const _productDetailCardShadow = BoxShadow(
  color: Color(0x0F052449),
  blurRadius: 18,
  offset: Offset(0, 8),
);

class ProductDetailCard extends StatelessWidget {
  final Widget child;

  const ProductDetailCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [_productDetailCardShadow],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: child,
      ),
    );
  }
}
