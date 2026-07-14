import 'package:flutter/material.dart';

import '../../app/router/app_router.dart';
import '../../app/theme/app_theme.dart';
import '../../core/constants/app_strings.dart';
import '../navigation/buyer_navigation.dart';

enum BuyerBottomNavTab { home, products, cart, chat, profile }

class BuyerBottomNav extends StatelessWidget {
  final BuyerBottomNavTab? currentTab;

  const BuyerBottomNav({super.key, this.currentTab});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
        constraints: const BoxConstraints(minHeight: 84),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE4EEF5)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x16052449),
              blurRadius: 28,
              offset: Offset(0, 8),
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
              label: AppStrings.homeTitle,
              onTap: () => _go(context, AppRoutes.home),
            ),
            _BuyerNavItem(
              tab: BuyerBottomNavTab.products,
              currentTab: currentTab,
              icon: Icons.sailing_outlined,
              activeIcon: Icons.sailing_outlined,
              label: AppStrings.productsTitle,
              onTap: () => _go(context, AppRoutes.productList),
            ),
            _BuyerNavItem(
              tab: BuyerBottomNavTab.cart,
              currentTab: currentTab,
              icon: Icons.shopping_cart_outlined,
              activeIcon: Icons.shopping_cart_outlined,
              label: AppStrings.cartTitle,
              onTap: () => _go(context, AppRoutes.cart),
            ),
            _BuyerNavItem(
              tab: BuyerBottomNavTab.chat,
              currentTab: currentTab,
              icon: Icons.chat_bubble_outline_rounded,
              activeIcon: Icons.chat_bubble_outline_rounded,
              label: AppStrings.chatTitle,
              onTap: () => _go(context, AppRoutes.chat),
            ),
            _BuyerNavItem(
              tab: BuyerBottomNavTab.profile,
              currentTab: currentTab,
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_outline_rounded,
              label: AppStrings.accountTitle,
              onTap: () => _go(context, AppRoutes.profile),
            ),
          ],
        ),
      ),
    );
  }

  void _go(BuildContext context, String location) {
    BuyerNavigation.push(context, location);
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
    final iconColor = active
        ? const Color(0xFF118D96)
        : AppColors.textSecondary;
    final labelColor = active ? const Color(0xFF118D96) : AppColors.textPrimary;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 50,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFFD7F5F8)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Icon(
                    active ? activeIcon : icon,
                    size: 23,
                    color: iconColor,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 14,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      softWrap: false,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: labelColor,
                        fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 11.5,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
