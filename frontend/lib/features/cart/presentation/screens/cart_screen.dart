import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/navigation/buyer_navigation.dart';
import '../../../../shared/widgets/buyer_back_to_home_scope.dart';
import '../../../../shared/widgets/buyer_bottom_nav.dart';
import '../../domain/cart.dart';
import '../cubit/cart_cubit.dart';

const _cartSurfaceRadius = 18.0;
const _cartInnerRadius = 14.0;
const _cartControlRadius = 10.0;
const _cartImageFrameRadius = 18.0;
const _cartImageRadius = 16.0;
const _cartSurfaceBorder = Color(0xFFE4EEF5);
const _cartSurfaceShadow = BoxShadow(
  color: Color(0x12052449),
  blurRadius: 18,
  offset: Offset(0, 8),
);

class CartScreen extends StatelessWidget {
  final VoidCallback? onCheckout;
  final VoidCallback? onContinueShopping;

  const CartScreen({super.key, this.onCheckout, this.onContinueShopping});

  @override
  Widget build(BuildContext context) {
    return BuyerBackToHomeScope(
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FC),
        bottomNavigationBar: const BuyerBottomNav(
          currentTab: BuyerBottomNavTab.cart,
        ),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _CartHeader(onBack: () => _goBack(context)),
              Expanded(
                child: BlocBuilder<CartCubit, CartState>(
                  builder: (context, state) {
                    return _CartBody(
                      state: state,
                      onCheckout: () => _goCheckout(context),
                      onContinueShopping: () => _goProducts(context),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goBack(BuildContext context) {
    BuyerNavigation.popOrGo(context, AppRoutes.home);
  }

  void _goProducts(BuildContext context) {
    if (onContinueShopping != null) {
      onContinueShopping!();
      return;
    }
    BuyerNavigation.push(context, AppRoutes.productList);
  }

  void _goCheckout(BuildContext context) {
    if (onCheckout != null) {
      onCheckout!();
      return;
    }
    GoRouter.maybeOf(context)?.go(AppRoutes.checkout);
  }
}

class _CartHeader extends StatelessWidget {
  final VoidCallback onBack;

  const _CartHeader({required this.onBack});

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
                'Gi\u1ecf h\u00e0ng c\u1ee7a b\u1ea1n',
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
                tooltip: 'Quay l\u1ea1i',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartBody extends StatelessWidget {
  final CartState state;
  final VoidCallback onCheckout;
  final VoidCallback onContinueShopping;

  const _CartBody({
    required this.state,
    required this.onCheckout,
    required this.onContinueShopping,
  });

  @override
  Widget build(BuildContext context) {
    if (state.cart.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                _CartEmptyState(onContinueShopping: onContinueShopping),
                const SizedBox(height: 10),
                _OrderSummaryCard(state: state, onCheckout: onCheckout),
              ],
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      key: const Key('cartScrollView'),
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 18),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            children: [
              for (final item in state.cart.items) ...[
                _CartItemCard(item: item),
                const SizedBox(height: 8),
              ],
              _OrderSummaryCard(state: state, onCheckout: onCheckout),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartEmptyState extends StatelessWidget {
  final VoidCallback onContinueShopping;

  const _CartEmptyState({required this.onContinueShopping});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _CartCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            const Icon(
              Icons.shopping_cart_outlined,
              size: 42,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 10),
            Text(
              'Gi\u1ecf h\u00e0ng \u0111ang tr\u1ed1ng',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onContinueShopping,
              icon: const Icon(Icons.add_shopping_cart_outlined),
              label: const Text('Ch\u1ecdn s\u1ea3n ph\u1ea9m'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_cartInnerRadius),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItem item;

  const _CartItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.read<CartCubit>();

    return InkWell(
      key: Key('cartSelectedToggle-${item.productId}'),
      onTap: () => cubit.toggleSelected(item.productId),
      borderRadius: BorderRadius.circular(_cartSurfaceRadius),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: item.selected ? 1 : 0.56,
        child: _CartCard(
          selected: item.selected,
          child: SizedBox(
            height: 74,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final priceLeft = constraints.maxWidth < 330 ? 186.0 : 204.0;

                return Stack(
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: _CartItemThumbnail(item: item),
                    ),
                    Positioned(
                      left: 86,
                      right: 30,
                      top: 4,
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
                    Positioned(
                      left: 86,
                      right: 30,
                      top: 27,
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
                          tooltip: 'X\u00f3a s\u1ea3n ph\u1ea9m',
                          icon: const Icon(Icons.delete_outline_rounded),
                          iconSize: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 86,
                      bottom: 2,
                      child: _QuantityStepper(item: item),
                    ),
                    Positioned(
                      left: priceLeft,
                      right: 0,
                      bottom: 6,
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
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CartItemThumbnail extends StatelessWidget {
  final CartItem item;

  const _CartItemThumbnail({required this.item});

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
            child: _ProductImage(path: item.productImageUrl, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String path;
  final BoxFit fit;

  const _ProductImage({required this.path, this.fit = BoxFit.contain});

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
            const _ProductImageFallback(),
      );
    }
    return const _ProductImageFallback();
  }
}

class _ProductImageFallback extends StatelessWidget {
  const _ProductImageFallback();

  @override
  Widget build(BuildContext context) {
    return const Icon(
      Icons.set_meal_outlined,
      size: 28,
      color: AppColors.primary,
    );
  }
}

class _QuantityStepper extends StatelessWidget {
  final CartItem item;

  const _QuantityStepper({required this.item});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CartCubit>();

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
            _QuantityButton(
              key: Key('cartDecreaseButton-${item.productId}'),
              icon: Icons.remove_rounded,
              onPressed: item.quantity > item.minOrderQuantity
                  ? () =>
                        cubit.updateQuantity(item.productId, item.quantity - 1)
                  : null,
            ),
            SizedBox(
              width: 38,
              child: Text(
                '${item.quantity}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.primaryDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            _QuantityButton(
              key: Key('cartIncreaseButton-${item.productId}'),
              icon: Icons.add_rounded,
              onPressed: item.quantity < item.stockQuantity
                  ? () =>
                        cubit.updateQuantity(item.productId, item.quantity + 1)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;

  const _QuantityButton({
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

class _OrderSummaryCard extends StatelessWidget {
  final CartState state;
  final VoidCallback onCheckout;

  const _OrderSummaryCard({required this.state, required this.onCheckout});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtotal = state.subtotalAmount;
    final discount = subtotal > 0 ? subtotal * 0.05 : 0.0;
    final total = subtotal - discount;

    return _CartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'T\u1ed5ng \u0111\u01a1n h\u00e0ng',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.primaryDark,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFEAF0F5)),
          const SizedBox(height: 13),
          _SummaryRow(
            label: 'T\u1ed5ng s\u1ed1 l\u01b0\u1ee3ng:',
            value: _totalQuantityLabel(state.cart),
            valueColor: AppColors.primaryDark,
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            label: 'T\u1ea1m t\u00ednh:',
            value: _formatVnd(subtotal),
            valueColor: AppColors.primaryDark,
          ),
          const SizedBox(height: 12),
          _SummaryRow(
            label: 'Gi\u1ea3m gi\u00e1 s\u1ec9 (5%):',
            value: '-${_formatVnd(discount)}',
            valueColor: AppColors.success,
          ),
          const SizedBox(height: 12),
          const _SummaryRow(
            label: 'Ph\u00ed v\u1eadn chuy\u1ec3n:',
            value: 'Mi\u1ec5n ph\u00ed',
            valueColor: AppColors.success,
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFEAF0F5)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  'T\u1ed5ng c\u1ed9ng:',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.primaryDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    _formatVnd(total),
                    textAlign: TextAlign.end,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppColors.primaryDark,
                      fontSize: 22,
                      height: 1.1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          FilledButton(
            key: const Key('cartCheckoutButton'),
            onPressed: state.canCheckout ? onCheckout : null,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(44),
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: const Color(0xFFB7C8D7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(_cartInnerRadius),
              ),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
            child: const Text('Ti\u1ebfn h\u00e0nh \u0111\u1eb7t h\u00e0ng'),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF475569),
              fontSize: 13,
            ),
          ),
        ),
        Text(
          value,
          textAlign: TextAlign.end,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: valueColor,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _CartCard extends StatelessWidget {
  final Widget child;
  final bool selected;

  const _CartCard({required this.child, this.selected = true});

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

String _formatVnd(num amount) {
  final normalized = amount.round();
  return '${NumberFormat.decimalPattern('vi_VN').format(normalized)}\u0111';
}

String _totalQuantityLabel(Cart cart) {
  final selectedItems = cart.selectedItems;
  final quantity = cart.totalSelectedItemCount;
  if (selectedItems.isEmpty) {
    return '0 kg';
  }

  final unit = selectedItems.first.unit;
  final sameUnit = selectedItems.every((item) => item.unit == unit);
  return sameUnit ? '$quantity $unit' : '$quantity m\u1ee5c';
}

String _cartProductName(CartItem item) {
  return switch (item.productId) {
    'prod-001' => 'M\u1ef1c kh\u00f4 lo\u1ea1i 1',
    'prod-002' => 'T\u00f4m kh\u00f4 \u0111\u1eb7c bi\u1ec7t',
    'prod-003' => 'C\u00e1 ch\u1ec9 v\u00e0ng kh\u00f4',
    'prod-004' => 'M\u1ef1c m\u1ed9t n\u1eafng',
    'prod-005' => 'M\u1ef1c kh\u00f4 x\u00e9 s\u1ee3i',
    'prod-006' => 'M\u1ef1c kh\u00f4 lo\u1ea1i 2',
    'prod-007' => 'N\u01b0\u1edbc m\u1eafm nh\u0129 Ph\u00fa Qu\u1ed1c',
    _ => item.productName,
  };
}
