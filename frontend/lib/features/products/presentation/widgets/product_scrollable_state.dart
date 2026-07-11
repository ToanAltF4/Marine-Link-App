import 'package:flutter/material.dart';

/// Bọc nội dung trạng thái (đang tải, lỗi, rỗng) trong vùng cuộn được, giúp căn giữa theo chiều cao khả dụng.
class ProductScrollableState extends StatelessWidget {
  final Widget child;

  const ProductScrollableState({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 28),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: child,
          ),
        );
      },
    );
  }
}
