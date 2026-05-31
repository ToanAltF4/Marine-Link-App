import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_router.dart';
import '../../app/theme/app_theme.dart';

enum BuyerBottomNavTab { home, products, cart, chat, profile }

class BuyerBottomNav extends StatelessWidget {
  final BuyerBottomNavTab? currentTab;

  const BuyerBottomNav({super.key, this.currentTab});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(0, 0, 0, 12),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.98),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x16052449),
              blurRadius: 24,
              offset: Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          children: [
            _BuyerNavItem(
              tab: BuyerBottomNavTab.home,
              currentTab: currentTab,
              icon: Icons.home_outlined,
              activeIcon: Icons.home_outlined,
              label: 'Trang\nch\u1ee7',
              onTap: () => _go(context, AppRoutes.home),
            ),
            _BuyerNavItem(
              tab: BuyerBottomNavTab.products,
              currentTab: currentTab,
              icon: Icons.sailing_outlined,
              activeIcon: Icons.sailing_outlined,
              label: 'S\u1ea3n\nph\u1ea9m',
              onTap: () => _go(context, AppRoutes.productList),
            ),
            _BuyerNavItem(
              tab: BuyerBottomNavTab.cart,
              currentTab: currentTab,
              icon: Icons.shopping_cart_outlined,
              activeIcon: Icons.shopping_cart_outlined,
              label: 'Gi\u1ecf\nh\u00e0ng',
              onTap: () => _go(context, AppRoutes.cart),
            ),
            _BuyerNavItem(
              tab: BuyerBottomNavTab.chat,
              currentTab: currentTab,
              icon: Icons.chat_bubble_outline_rounded,
              activeIcon: Icons.chat_bubble_outline_rounded,
              label: 'Chat',
              onTap: () => _go(context, AppRoutes.chat),
            ),
            _BuyerNavItem(
              tab: BuyerBottomNavTab.profile,
              currentTab: currentTab,
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_outline_rounded,
              label: 'T\u00e0i kho\u1ea3n',
              onTap: () => _go(context, AppRoutes.profile),
            ),
          ],
        ),
      ),
    );
  }

  void _go(BuildContext context, String location) {
    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.go(location);
    }
  }
}

class _BuyerNavItem extends StatelessWidget {
  final BuyerBottomNavTab tab;
  final BuyerBottomNavTab? currentTab;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final VoidCallback onTap;

  const _BuyerNavItem({
    required this.tab,
    required this.currentTab,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = currentTab == tab;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFD6F0FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                active ? activeIcon : icon,
                size: 24,
                color: active ? const Color(0xFF006A7C) : AppColors.textPrimary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: active
                      ? const Color(0xFF006A7C)
                      : AppColors.textPrimary,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
