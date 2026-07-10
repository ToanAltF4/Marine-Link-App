import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/theme/app_theme.dart';
import '../../domain/product.dart';
import 'product_detail_card.dart';
import 'product_detail_price_formatter.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class OrderQuantityCard extends StatelessWidget {
  final ProductDetail detail;
  final double effectivePrice;
  final int quantity;
  final bool outOfStock;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback? onAddToCart;

  const OrderQuantityCard({
    super.key,
    required this.detail,
    required this.effectivePrice,
    required this.quantity,
    required this.outOfStock,
    required this.onDecrease,
    required this.onIncrease,
    required this.onQuantityChanged,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final authState = context.watch<AuthBloc>().state;
    final isPending = authState is AuthAuthenticated &&
        authState.user.status == 'PENDING_APPROVAL';

    return ProductDetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\u0110\u1eb7t h\u00e0ng',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _QuantityButton(icon: Icons.remove_rounded, onTap: onDecrease),
              Expanded(
                child: Column(
                  children: [
                    _QuantityInput(
                      key: const Key('productDetailQuantityInput'),
                      quantity: quantity,
                      unit: detail.unit,
                      minQuantity: detail.minOrderQuantity,
                      maxQuantity: detail.stockQuantity,
                      onQuantityChanged: onQuantityChanged,
                    ),
                    const SizedBox(height: 2),
                    if (!isPending)
                      Text(
                        productDetailUnitPrice(effectivePrice, detail.unit),
                        style: theme.textTheme.bodyMedium,
                      )
                    else
                      Text(
                        'Giá: Đang xét duyệt',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
              ),
              _QuantityButton(icon: Icons.add_rounded, onTap: onIncrease),
            ],
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            key: const Key('addToCartButton'),
            onPressed: isPending ? null : onAddToCart,
            icon: Icon(
              isPending
                  ? Icons.lock_clock_outlined
                  : Icons.add_shopping_cart_outlined,
            ),
            label: Text(
              isPending
                  ? 'Tài khoản chờ duyệt'
                  : (outOfStock ? 'T\u1ea1m h\u1ebft h\u00e0ng' : 'Th\u00eam v\u00e0o gi\u1ecf'),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityInput extends StatefulWidget {
  final int quantity;
  final String unit;
  final int minQuantity;
  final int maxQuantity;
  final ValueChanged<int> onQuantityChanged;

  const _QuantityInput({
    super.key,
    required this.quantity,
    required this.unit,
    required this.minQuantity,
    required this.maxQuantity,
    required this.onQuantityChanged,
  });

  @override
  State<_QuantityInput> createState() => _QuantityInputState();
}

class _QuantityInputState extends State<_QuantityInput> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.quantity}');
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _QuantityInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.quantity != oldWidget.quantity && !_focusNode.hasFocus) {
      _controller.text = '${widget.quantity}';
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
    final theme = Theme.of(context);

    final quantityStyle = theme.textTheme.titleLarge?.copyWith(
      color: AppColors.primaryDark,
      fontWeight: FontWeight.w800,
    );

    return DecoratedBox(
      key: const Key('productDetailQuantityInputFrame'),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD6E6F2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 58,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                textAlign: TextAlign.right,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: quantityStyle,
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
                onSubmitted: _commit,
                onEditingComplete: () => _commit(_controller.text),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              widget.unit,
              style: quantityStyle?.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _commit(String value) {
    final parsed = int.tryParse(value);
    final next = (parsed ?? widget.minQuantity).clamp(
      widget.minQuantity,
      widget.maxQuantity,
    );
    _controller.text = '$next';
    _controller.selection = TextSelection.collapsed(
      offset: _controller.text.length,
    );
    widget.onQuantityChanged(next);
    _focusNode.unfocus();
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QuantityButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onTap,
      style: IconButton.styleFrom(
        minimumSize: const Size(44, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: Icon(icon),
    );
  }
}
