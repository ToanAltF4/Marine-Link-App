import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('adminDashboardScreen'),
      backgroundColor: const Color(0xFFF2F8FA),
      appBar: AppBar(title: const Text('Bảng điều khiển')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _AdminSummaryHeader(),
          const SizedBox(height: 12),
          _AdminActionCard(
            key: const Key('adminOrdersShortcut'),
            icon: Icons.receipt_long_outlined,
            title: 'Quản lý đơn hàng',
            description: 'Xem đơn mới và cập nhật trạng thái xử lý.',
            onTap: () => context.go(AppRoutes.adminOrders),
          ),
          const SizedBox(height: 12),
          _DisabledActionCard(
            icon: Icons.inventory_2_outlined,
            title: 'Sản phẩm',
            description: 'Quản trị catalog sẽ được mở ở sprint sau.',
          ),
          const SizedBox(height: 12),
          _DisabledActionCard(
            icon: Icons.people_alt_outlined,
            title: 'Người dùng',
            description: 'Duyệt đại lý và phân quyền sẽ được bổ sung sau.',
          ),
        ],
      ),
    );
  }
}

class _AdminSummaryHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _panelDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.admin_panel_settings_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vận hành MarineLink',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tập trung xử lý đơn hàng trước, giữ đúng phạm vi S2-07.',
                    style: Theme.of(context).textTheme.bodyMedium,
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

class _AdminActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _AdminActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: DecoratedBox(
        decoration: _panelDecoration,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _ActionIcon(icon: icon, enabled: true),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCopy(title: title, body: description),
              ),
              const Icon(Icons.chevron_right, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _DisabledActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _DisabledActionCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _panelDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _ActionIcon(icon: icon, enabled: false),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCopy(title: title, body: description),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final IconData icon;
  final bool enabled;

  const _ActionIcon({required this.icon, required this.enabled});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: enabled ? const Color(0xFFEAF6FF) : const Color(0xFFF3F6F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: enabled ? AppColors.primary : AppColors.textSecondary,
      ),
    );
  }
}

class _ActionCopy extends StatelessWidget {
  final String title;
  final String body;

  const _ActionCopy({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(body, style: Theme.of(context).textTheme.bodyMedium),
      ],
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
