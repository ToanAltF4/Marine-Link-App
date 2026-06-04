import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/navigation/buyer_navigation.dart';
import '../../../../shared/widgets/buyer_back_to_home_scope.dart';
import '../../../../shared/widgets/buyer_bottom_nav.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BuyerBackToHomeScope(
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F8FA),
        appBar: AppBar(title: const Text('Tài khoản'), centerTitle: true),
        bottomNavigationBar: const BuyerBottomNav(
          currentTab: BuyerBottomNavTab.profile,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            DecoratedBox(
              decoration: _panelDecoration,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5F6FA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: AppColors.primary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đại lý MarineLink',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Quản lý thông tin và hoạt động mua hàng',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Material(
              color: Colors.white,
              elevation: 2,
              shadowColor: const Color(0x110B3760),
              borderRadius: BorderRadius.circular(8),
              child: Column(
                children: [
                  _ProfileActionTile(
                    icon: Icons.receipt_long_outlined,
                    title: 'Đơn hàng của tôi',
                    subtitle: 'Theo dõi đơn đã đặt và trạng thái giao hàng',
                    onTap: () =>
                        BuyerNavigation.push(context, AppRoutes.orders),
                  ),
                  const Divider(height: 1),
                  _ProfileActionTile(
                    icon: Icons.location_on_outlined,
                    title: 'Địa chỉ giao hàng',
                    subtitle: 'Quản lý địa chỉ nhận hàng đã lưu',
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  _ProfileActionTile(
                    icon: Icons.support_agent_outlined,
                    title: 'Hỗ trợ',
                    subtitle: 'Chat với nhân viên MarineLink',
                    onTap: () => BuyerNavigation.push(context, AppRoutes.chat),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      minVerticalPadding: 14,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

final _panelDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(8),
  boxShadow: const [
    BoxShadow(color: Color(0x110B3760), blurRadius: 12, offset: Offset(0, 4)),
  ],
);
