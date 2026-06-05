import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_router.dart';
import '../../app/theme/app_theme.dart';

enum AdminBottomNavTab { dashboard, products, orders, users, profile }

enum StaffBottomNavTab { work, orders, chat, profile }

class AdminBottomNav extends StatelessWidget {
  final AdminBottomNavTab currentTab;

  const AdminBottomNav({super.key, required this.currentTab});

  @override
  Widget build(BuildContext context) {
    return RoleBottomNav(
      items: [
        RoleBottomNavItem(
          key: const Key('adminBottomNavDashboard'),
          selected: currentTab == AdminBottomNavTab.dashboard,
          icon: Icons.dashboard_outlined,
          label: 'Tổng quan',
          location: AppRoutes.adminDashboard,
        ),
        RoleBottomNavItem(
          key: const Key('adminBottomNavProducts'),
          selected: currentTab == AdminBottomNavTab.products,
          icon: Icons.inventory_2_outlined,
          label: 'Sản phẩm',
          location: AppRoutes.adminProducts,
        ),
        RoleBottomNavItem(
          key: const Key('adminBottomNavOrders'),
          selected: currentTab == AdminBottomNavTab.orders,
          icon: Icons.fact_check_outlined,
          label: 'Đơn hàng',
          location: AppRoutes.adminOrders,
        ),
        RoleBottomNavItem(
          key: const Key('adminBottomNavUsers'),
          selected: currentTab == AdminBottomNavTab.users,
          icon: Icons.people_alt_outlined,
          label: 'Tài khoản',
          location: AppRoutes.adminUsers,
        ),
        RoleBottomNavItem(
          key: const Key('adminBottomNavProfile'),
          selected: currentTab == AdminBottomNavTab.profile,
          icon: Icons.person_outline_rounded,
          label: 'Hồ sơ',
          location: AppRoutes.adminProfile,
        ),
      ],
    );
  }
}

class StaffBottomNav extends StatelessWidget {
  final StaffBottomNavTab currentTab;

  const StaffBottomNav({super.key, required this.currentTab});

  @override
  Widget build(BuildContext context) {
    return RoleBottomNav(
      items: [
        RoleBottomNavItem(
          key: const Key('staffBottomNavWork'),
          selected: currentTab == StaffBottomNavTab.work,
          icon: Icons.work_outline_rounded,
          label: 'Công việc',
          location: AppRoutes.staffDashboard,
        ),
        RoleBottomNavItem(
          key: const Key('staffBottomNavOrders'),
          selected: currentTab == StaffBottomNavTab.orders,
          icon: Icons.fact_check_outlined,
          label: 'Đơn hàng',
          location: AppRoutes.staffOrders,
        ),
        RoleBottomNavItem(
          key: const Key('staffBottomNavChat'),
          selected: currentTab == StaffBottomNavTab.chat,
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Tin nhắn',
          location: AppRoutes.staffChat,
        ),
        RoleBottomNavItem(
          key: const Key('staffBottomNavProfile'),
          selected: currentTab == StaffBottomNavTab.profile,
          icon: Icons.person_outline_rounded,
          label: 'Hồ sơ',
          location: AppRoutes.staffProfile,
        ),
      ],
    );
  }
}

class RoleBottomNav extends StatelessWidget {
  final List<RoleBottomNavItem> items;

  const RoleBottomNav({super.key, required this.items});

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
          children: items
              .map(
                (item) => _RoleNavItem(
                  key: item.key,
                  item: item,
                  onTap: () => _go(context, item),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _go(BuildContext context, RoleBottomNavItem item) {
    if (item.selected) {
      return;
    }
    context.go(item.location);
  }
}

class RoleBottomNavItem {
  final Key key;
  final bool selected;
  final IconData icon;
  final String label;
  final String location;

  const RoleBottomNavItem({
    required this.key,
    required this.selected,
    required this.icon,
    required this.label,
    required this.location,
  });
}

class _RoleNavItem extends StatelessWidget {
  final RoleBottomNavItem item;
  final VoidCallback onTap;

  const _RoleNavItem({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final iconColor = item.selected
        ? const Color(0xFF118D96)
        : AppColors.textSecondary;
    final labelColor = item.selected
        ? const Color(0xFF118D96)
        : AppColors.textPrimary;

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
                    color: item.selected
                        ? const Color(0xFFD7F5F8)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Icon(item.icon, size: 23, color: iconColor),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 14,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      item.label,
                      maxLines: 1,
                      softWrap: false,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: labelColor,
                        fontWeight: item.selected
                            ? FontWeight.w700
                            : FontWeight.w600,
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
