import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../shared/widgets/buyer_bottom_nav.dart';
import '../../../../shared/widgets/role_bottom_nav.dart';
import '../../../auth/domain/user.dart';

/// Thanh điều hướng dưới cùng, thay đổi theo vai trò người dùng.
class NotificationBottomNav extends StatelessWidget {
  final User? user;

  const NotificationBottomNav({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    if (user?.isStaff == true) {
      return const StaffBottomNav(currentTab: StaffBottomNavTab.work);
    }
    if (user?.isAdmin == true) {
      return const AdminBottomNav(currentTab: AdminBottomNavTab.dashboard);
    }
    return const BuyerBottomNav(currentTab: BuyerBottomNavTab.home);
  }
}

/// Tiêu đề màn thông báo kèm nút quay lại và mô tả ngắn.
class NotificationHeader extends StatelessWidget {
  final User? user;

  const NotificationHeader({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          key: const Key('notificationsBackButton'),
          tooltip: 'Quay lại',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
              return;
            }
            context.go(_fallbackLocation(user));
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thông báo',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Theo dõi cập nhật đơn hàng, sản phẩm và phản hồi hỗ trợ.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _fallbackLocation(User? user) {
    if (user?.isAdmin == true) {
      return AppRoutes.adminDashboard;
    }
    if (user?.isStaff == true) {
      return AppRoutes.staffDashboard;
    }
    return AppRoutes.home;
  }
}
