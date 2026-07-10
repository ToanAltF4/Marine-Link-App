import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/cart.dart';
import '../cubit/cart_cubit.dart';
import 'cart_card.dart';

const _cartSurfaceRadius = 18.0;
const _cartControlRadius = 10.0;
const _cartImageFrameRadius = 18.0;
const _cartImageRadius = 16.0;

/// Thẻ hiển thị một sản phẩm trong giỏ hàng kèm thao tác chọn/xóa/số lượng.
class CartItemCard extends StatelessWidget {
  final CartItem item;

  const CartItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<CartCubit>();

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: item.selected ? 1 : 0.56,
      child: CartCard(
        selected: item.selected,
        child: SizedBox(
          height: 74,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final priceLeft = constraints.maxWidth < 330 ? 186.0 : 204.0;

              return Stack(
                children: [
                  // Lớp dưới cùng: Vùng bấm để chọn/bỏ chọn sản phẩm
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        key: Key('cartSelectedToggle-${item.productId}'),
                        onTap: () => cubit.toggleSelected(item.productId),
                        borderRadius: BorderRadius.circular(_cartSurfaceRadius),
                      ),
                    ),
                  ),

                  // Lớp hiển thị nội dung (không nhận sự kiện để InkWell bên dưới nhận được)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    child: IgnorePointer(child: CartItemThumbnail(item: item)),
                  ),
                  Positioned(
                    left: 86,
                    right: 30,
                    top: 4,
                    child: IgnorePointer(
                      child: Text(
                        _cartProductName(item),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.primaryDark,
                          fontSize: 15,
                          height: 1.05,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 86,
                    right: 30,
                    top: 27,
                    child: IgnorePointer(
                      child: Text(
                        '${_formatVnd(item.unitPrice)}/${item.unit}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF64748B),
                          fontSize: 12,
                          height: 1.05,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  // Lớp trên cùng: Các nút điều khiển (phải nằm trên InkWell)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: SizedBox.square(
                      dimension: 28,
                      child: IconButton(
                        key: Key('cartRemoveButton-${item.productId}'),
                        onPressed: () => cubit.removeItem(item.productId),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Xóa sản phẩm',
                        icon: const Icon(Icons.delete_outline_rounded),
                        iconSize: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 86,
                    bottom: 2,
                    child: QuantityStepper(item: item),
                  ),
                  Positioned(
                    left: priceLeft,
                    right: 0,
                    bottom: 6,
                    child: IgnorePointer(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            _formatVnd(item.lineTotal),
                            textAlign: TextAlign.end,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.primary,
                              fontSize: 17.5,
                              height: 1,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Ảnh thu nhỏ có khung của một sản phẩm trong giỏ hàng.
class CartItemThumbnail extends StatelessWidget {
  final CartItem item;

  const CartItemThumbnail({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      key: Key('cartProductThumbnail-${item.productId}'),
      borderRadius: BorderRadius.circular(_cartImageFrameRadius),
      child: Container(
        width: 74,
        height: 74,
        padding: const EdgeInsets.all(4),
        color: const Color(0xFFF8FBFF),
        child: ClipRRect(
          key: Key('cartProductImageClip-${item.productId}'),
          borderRadius: BorderRadius.circular(_cartImageRadius),
          child: Container(
            key: Key('cartProductImageSurface-${item.productId}'),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(_cartImageRadius),
              border: Border.all(color: const Color(0xFFEAF0F5)),
            ),
            child: ProductImage(path: item.productImageUrl, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}

/// Hiển thị ảnh sản phẩm từ asset hoặc mạng, có ảnh dự phòng khi lỗi.
class ProductImage extends StatelessWidget {
  final String path;
  final BoxFit fit;

  const ProductImage({
    super.key,
    required this.path,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        width: double.infinity,
        height: double.infinity,
        fit: fit,
      );
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        width: double.infinity,
        height: double.infinity,
        fit: fit,
        errorBuilder: (context, error, stackTrace) =>
            const ProductImageFallback(),
      );
    }
    return const ProductImageFallback();
  }
}

/// Biểu tượng dự phòng khi không tải được ảnh sản phẩm.
class ProductImageFallback extends StatelessWidget {
  const ProductImageFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.set_meal_outlined,
      size: 28,
      color: AppColors.primary,
    );
  }
}

/// Bộ điều chỉnh số lượng (tăng/giảm/nhập) cho một sản phẩm trong giỏ hàng.
class QuantityStepper extends StatefulWidget {
  final CartItem item;

  const QuantityStepper({super.key, required this.item});

  @override
  State<QuantityStepper> createState() => _QuantityStepperState();
}

class _QuantityStepperState extends State<QuantityStepper> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  CartItem get item => widget.item;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${item.quantity}');
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _commit(_controller.text);
      }
    });
  }

  @override
  void didUpdateWidget(covariant QuantityStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    final visibleQuantity = int.tryParse(_controller.text);
    final shouldSyncFocusedValue =
        _focusNode.hasFocus && visibleQuantity != item.quantity;
    if (item.quantity != oldWidget.item.quantity &&
        (!_focusNode.hasFocus || shouldSyncFocusedValue)) {
      _controller.text = '${item.quantity}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F6FC),
        borderRadius: BorderRadius.circular(_cartControlRadius),
      ),
      child: SizedBox(
        height: 30,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            QuantityButton(
              key: Key('cartDecreaseButton-${item.productId}'),
              icon: Icons.remove_rounded,
              onPressed: item.quantity > item.minOrderQuantity
                  ? () => _stepQuantity(-1)
                  : null,
            ),
            SizedBox(
              width: 42,
              child: TextField(
                key: Key('cartQuantityInput-${item.productId}'),
                controller: _controller,
                focusNode: _focusNode,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                textAlign: TextAlign.center,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.primaryDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: _handleChanged,
                onSubmitted: _commit,
                onEditingComplete: () => _commit(_controller.text),
              ),
            ),
            QuantityButton(
              key: Key('cartIncreaseButton-${item.productId}'),
              icon: Icons.add_rounded,
              onPressed: item.quantity < item.stockQuantity
                  ? () => _stepQuantity(1)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  void _commit(String value) {
    final parsed = int.tryParse(value);
    final next = (parsed ?? item.minOrderQuantity).clamp(
      item.minOrderQuantity,
      item.stockQuantity,
    );
    _controller.text = '$next';
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
    context.read<CartCubit>().updateQuantity(item.productId, next);
    _focusNode.unfocus();
  }

  void _handleChanged(String value) {
    if (value.isEmpty) return;

    final parsed = int.tryParse(value);
    if (parsed == null) return;

    final next = parsed.clamp(item.minOrderQuantity, item.stockQuantity);
    if (next != parsed) {
      _controller.text = '$next';
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }
    context.read<CartCubit>().updateQuantity(item.productId, next);
  }

  void _stepQuantity(int delta) {
    final parsed = int.tryParse(_controller.text);
    final current = (parsed ?? item.quantity).clamp(
      item.minOrderQuantity,
      item.stockQuantity,
    );
    final next = (current + delta).clamp(
      item.minOrderQuantity,
      item.stockQuantity,
    );
    _controller.text = '$next';
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
    context.read<CartCubit>().updateQuantity(item.productId, next);
  }
}

/// Nút vuông tăng hoặc giảm số lượng trong [QuantityStepper].
class QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const QuantityButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(_cartControlRadius),
      child: SizedBox.square(
        dimension: 30,
        child: Icon(
          icon,
          size: 16,
          color: onPressed == null
              ? const Color(0xFFCBD5E1)
              : AppColors.primaryDark,
        ),
      ),
    );
  }
}

String _formatVnd(num amount) {
  final normalized = amount.round();
  return '${NumberFormat.decimalPattern('vi_VN').format(normalized)}đ';
}

String _cartProductName(CartItem item) {
  return switch (item.productId) {
    'prod-001' => 'Mực khô loại 1',
    'prod-002' => 'Tôm khô đặc biệt',
    'prod-003' => 'Cá chỉ vàng khô',
    'prod-004' => 'Mực một nắng',
    'prod-005' => 'Mực khô xé sợi',
    'prod-006' => 'Mực khô loại 2',
    'prod-007' => 'Nước mắm nhĩ Phú Quốc',
    _ => item.productName,
  };
}
