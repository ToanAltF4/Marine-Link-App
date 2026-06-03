import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/navigation/buyer_navigation.dart';

class ProductDetailFlatBottomNav extends StatelessWidget {
  const ProductDetailFlatBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        key: const Key('productDetailFlatBottomNav'),
        padding: const EdgeInsets.fromLTRB(2, 6, 2, 7),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5EDF4))),
        ),
        child: Row(
          children: [
            _FlatNavItem(
              icon: Icons.home_outlined,
              label: 'Trang ch\u1ee7',
              onTap: () => BuyerNavigation.push(context, AppRoutes.home),
            ),
            _FlatNavItem(
              icon: Icons.sailing_outlined,
              label: 'S\u1ea3n ph\u1ea9m',
              active: true,
              onTap: () => BuyerNavigation.push(context, AppRoutes.productList),
            ),
            _FlatNavItem(
              icon: Icons.shopping_cart_outlined,
              label: 'Gi\u1ecf h\u00e0ng',
              onTap: () => BuyerNavigation.push(context, AppRoutes.cart),
            ),
            _FlatNavItem(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Chat',
              onTap: () => BuyerNavigation.push(context, AppRoutes.chat),
            ),
            _FlatNavItem(
              icon: Icons.person_outline_rounded,
              label: 'T\u00e0i kho\u1ea3n',
              onTap: () => BuyerNavigation.push(context, AppRoutes.profile),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlatNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FlatNavItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.textPrimary;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 50,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  softWrap: false,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontSize: 11.5,
                    height: 1,
                    fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
