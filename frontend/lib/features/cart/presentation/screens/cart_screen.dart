import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../shared/navigation/buyer_navigation.dart';
import '../../../../shared/widgets/buyer_back_to_home_scope.dart';
import '../../../../shared/widgets/buyer_bottom_nav.dart';
import '../cubit/cart_cubit.dart';
import '../widgets/cart_body.dart';
import '../widgets/cart_header.dart';

class CartScreen extends StatefulWidget {
  final VoidCallback? onCheckout;
  final VoidCallback? onContinueShopping;

  const CartScreen({super.key, this.onCheckout, this.onContinueShopping});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CartCubit>().loadCart();
    });
  }

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
              CartHeader(onBack: () => _goBack(context)),
              Expanded(
                child: BlocBuilder<CartCubit, CartState>(
                  builder: (context, state) {
                    return RefreshIndicator(
                      onRefresh: () =>
                          context.read<CartCubit>().loadCart(force: true),
                      child: CartBody(
                        state: state,
                        onCheckout: () => _goCheckout(context),
                        onContinueShopping: () => _goProducts(context),
                      ),
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
    if (widget.onContinueShopping != null) {
      widget.onContinueShopping!();
      return;
    }
    BuyerNavigation.push(context, AppRoutes.productList);
  }

  void _goCheckout(BuildContext context) {
    if (widget.onCheckout != null) {
      widget.onCheckout!();
      return;
    }
    GoRouter.maybeOf(context)?.go(AppRoutes.checkout);
  }
}
