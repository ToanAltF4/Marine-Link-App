import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../domain/product.dart';
import '../../domain/product_repository.dart';
import '../bloc/product_bloc.dart';
import '../widgets/product_visuals.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;
  final ProductRepository? productRepository;

  const ProductDetailScreen({
    super.key,
    required this.productId,
    this.productRepository,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late final ProductRepository _productRepository;
  late final ProductBloc _productBloc;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _productRepository = widget.productRepository ?? sl<ProductRepository>();
    _productBloc = ProductBloc(productRepository: _productRepository)
      ..add(ProductDetailRequested(widget.productId));
  }

  @override
  void dispose() {
    _productBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _productBloc,
      child: BlocListener<ProductBloc, ProductState>(
        listener: (context, state) {
          if (state is ProductDetailLoaded &&
              _quantity < state.product.minOrderQuantity) {
            setState(() => _quantity = state.product.minOrderQuantity);
          }
        },
        child: BlocBuilder<ProductBloc, ProductState>(
          builder: (context, state) {
            if (state is ProductInitial || state is ProductDetailLoading) {
              return const Scaffold(
                body: AppLoadingIndicator(
                  message: 'Dang tai chi tiet san pham',
                ),
              );
            }
            if (state is ProductDetailError) {
              return Scaffold(
                body: AppErrorState(
                  message: state.message,
                  onRetry: () => _productBloc.add(
                    ProductDetailRequested(widget.productId),
                  ),
                ),
              );
            }

            final detail = (state as ProductDetailLoaded).product;
            final effectivePrice = detail.priceFor(_quantity);
            final outOfStock = detail.stockQuantity <= 0;
            final visual = productVisualStyle(detail);
            final stockColor = productStockColor(detail);

            return Scaffold(
              body: SafeArea(
                bottom: false,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    Row(
                      children: [
                        _HeaderIconButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                              return;
                            }
                            context.go(AppRoutes.productList);
                          },
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Chi tiet san pham',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _HeaderIconButton(
                          icon: Icons.notifications_none_rounded,
                          onTap: () => context.go(AppRoutes.notifications),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [visual.startColor, visual.endColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  detail.category?.name ?? 'Catalog',
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  productStockLabel(detail),
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: Container(
                              width: 156,
                              height: 156,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(32),
                              ),
                              child: Icon(
                                visual.icon,
                                size: 72,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          Text(
                            detail.name,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            detail.origin ?? 'Nguon hang dang cap nhat',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.82),
                                ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            '${MoneyFormatter.format(detail.basePrice)}/${detail.unit}',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _DetailStatCard(
                            title: 'MOQ',
                            value: '${detail.minOrderQuantity}${detail.unit}',
                            icon: Icons.shopping_bag_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DetailStatCard(
                            title: 'Ton kho',
                            value: '${detail.stockQuantity}${detail.unit}',
                            icon: Icons.inventory_2_outlined,
                            accentColor: stockColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DetailStatCard(
                            title: 'Ap dung',
                            value:
                                '${MoneyFormatter.format(effectivePrice)}/${detail.unit}',
                            icon: Icons.stacked_line_chart_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thong tin nguon hang',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            detail.description ??
                                'San pham dang duoc bo sung mo ta chi tiet cho kenh B2B.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _DetailBadge(
                                icon: Icons.category_outlined,
                                label: detail.category?.name ?? 'Khac',
                              ),
                              _DetailBadge(
                                icon: Icons.place_outlined,
                                label: detail.origin ?? 'Chua ro nguon goc',
                              ),
                              const _DetailBadge(
                                icon: Icons.verified_user_outlined,
                                label: 'B2B sourcing',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Gia theo muc so luong',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Gia se duoc doi theo so luong dat trong don hien tai.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 14),
                    for (final tier in detail.priceTiers) ...[
                      _PriceTierTile(
                        key: Key('priceTier-${tier.id}'),
                        tier: tier,
                        unit: detail.unit,
                        selected: tier.matches(_quantity),
                      ),
                      const SizedBox(height: 12),
                    ],
                    const SizedBox(height: 22),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'So luong dat',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              _QuantityButton(
                                icon: Icons.remove_rounded,
                                onTap: _quantity > detail.minOrderQuantity
                                    ? () => setState(() => _quantity -= 1)
                                    : null,
                              ),
                              Expanded(
                                child: Column(
                                  children: [
                                    Text(
                                      '$_quantity ${detail.unit}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w900,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'MOQ toi thieu ${detail.minOrderQuantity}${detail.unit}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                              _QuantityButton(
                                icon: Icons.add_rounded,
                                onTap: _quantity < detail.stockQuantity
                                    ? () => setState(() => _quantity += 1)
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 110),
                  ],
                ),
              ),
              bottomNavigationBar: SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Gia ap dung',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${MoneyFormatter.format(effectivePrice)}/${detail.unit}',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w900,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: FilledButton.icon(
                          key: const Key('addToCartButton'),
                          onPressed: outOfStock
                              ? null
                              : () => _addToCart(detail),
                          icon: const Icon(Icons.add_shopping_cart_outlined),
                          label: Text(
                            outOfStock ? 'Tam het hang' : 'Them vao gio',
                          ),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(58),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _addToCart(ProductDetail detail) {
    context.read<CartCubit>().addItem(product: detail, quantity: _quantity);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Da them ${detail.name} vao gio hang')),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(icon, color: AppColors.primaryDark),
        ),
      ),
    );
  }
}

class _DetailStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? accentColor;

  const _DetailStatCard({
    required this.title,
    required this.value,
    required this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _DetailBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceSky,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
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
        minimumSize: const Size(52, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: Icon(icon),
    );
  }
}

class _PriceTierTile extends StatelessWidget {
  final PriceTier tier;
  final String unit;
  final bool selected;

  const _PriceTierTile({
    super.key,
    required this.tier,
    required this.unit,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rangeLabel = tier.maxQuantity == null
        ? 'Tu ${tier.minQuantity}$unit'
        : '${tier.minQuantity}-${tier.maxQuantity}$unit';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: selected ? AppColors.primaryDark : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: selected ? AppColors.primaryDark : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            selected ? Icons.check_circle : Icons.local_offer_outlined,
            color: selected ? Colors.white : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rangeLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: selected
                        ? Colors.white
                        : theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${MoneyFormatter.format(tier.unitPrice)}/$unit',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: selected
                        ? Colors.white.withValues(alpha: 0.82)
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
