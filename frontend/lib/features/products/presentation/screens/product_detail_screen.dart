import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../app/router/app_router.dart';
import '../../../../shared/navigation/buyer_navigation.dart';
import '../../../../shared/widgets/app_back_exit_scope.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../../../cart/presentation/cubit/cart_cubit.dart';
import '../../domain/product.dart';
import '../../domain/product_repository.dart';
import '../bloc/product_bloc.dart';
import '../widgets/product_detail_bottom_nav.dart';
import '../widgets/product_detail_header.dart';
import '../widgets/product_detail_hero.dart';
import '../widgets/product_detail_info_card.dart';
import '../widgets/product_detail_order_card.dart';
import '../widgets/product_detail_pricing_card.dart';
import '../widgets/product_visuals.dart';

const _detailBackground = Color(0xFFF4F7FC);

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
    return AppBackExitScope(
      onFirstBack: _goBackFromDetail,
      child: BlocProvider.value(
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
                  backgroundColor: _detailBackground,
                  body: AppLoadingIndicator(
                    message:
                        '\u0110ang t\u1ea3i chi ti\u1ebft s\u1ea3n ph\u1ea9m',
                  ),
                );
              }
              if (state is ProductDetailError) {
                return Scaffold(
                  backgroundColor: _detailBackground,
                  body: AppErrorState(
                    message: state.message,
                    onRetry: () => _productBloc.add(
                      ProductDetailRequested(widget.productId),
                    ),
                  ),
                );
              }

              return _ProductDetailContent(
                detail: (state as ProductDetailLoaded).product,
                quantity: _quantity,
                onBack: () => _goBackFromDetail(context),
                onNotifications: () =>
                    BuyerNavigation.push(context, AppRoutes.notifications),
                onDecrease: _decreaseQuantity,
                onIncrease: _increaseQuantity,
                onAddToCart: _addToCart,
              );
            },
          ),
        ),
      ),
    );
  }

  void _goBackFromDetail(BuildContext context) {
    BuyerNavigation.popOrGo(context, AppRoutes.productList);
  }

  void _decreaseQuantity(ProductDetail detail) {
    if (_quantity <= detail.minOrderQuantity) {
      return;
    }
    setState(() => _quantity -= 1);
  }

  void _increaseQuantity(ProductDetail detail) {
    if (_quantity >= detail.stockQuantity) {
      return;
    }
    setState(() => _quantity += 1);
  }

  void _addToCart(ProductDetail detail) {
    context.read<CartCubit>().addItem(product: detail, quantity: _quantity);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '\u0110\u00e3 th\u00eam ${displayProductName(detail)} '
          'v\u00e0o gi\u1ecf h\u00e0ng',
        ),
      ),
    );
  }
}

class _ProductDetailContent extends StatelessWidget {
  final ProductDetail detail;
  final int quantity;
  final VoidCallback onBack;
  final VoidCallback onNotifications;
  final void Function(ProductDetail detail) onDecrease;
  final void Function(ProductDetail detail) onIncrease;
  final void Function(ProductDetail detail) onAddToCart;

  const _ProductDetailContent({
    required this.detail,
    required this.quantity,
    required this.onBack,
    required this.onNotifications,
    required this.onDecrease,
    required this.onIncrease,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePrice = detail.priceFor(quantity);
    final outOfStock = !detail.isAvailable;

    return Scaffold(
      backgroundColor: _detailBackground,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          key: const Key('productDetailScrollView'),
          child: Column(
            children: [
              ProductDetailHeader(
                onBack: onBack,
                onNotifications: onNotifications,
              ),
              ProductHeroImage(detail: detail),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                child: Column(
                  children: [
                    WholesalePricingCard(detail: detail),
                    const SizedBox(height: 16),
                    ProductInformationCard(detail: detail),
                    const SizedBox(height: 16),
                    OrderQuantityCard(
                      detail: detail,
                      effectivePrice: effectivePrice,
                      quantity: quantity,
                      outOfStock: outOfStock,
                      onDecrease: quantity > detail.minOrderQuantity
                          ? () => onDecrease(detail)
                          : null,
                      onIncrease: quantity < detail.stockQuantity
                          ? () => onIncrease(detail)
                          : null,
                      onAddToCart: outOfStock
                          ? null
                          : () => onAddToCart(detail),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const ProductDetailFlatBottomNav(),
    );
  }
}
