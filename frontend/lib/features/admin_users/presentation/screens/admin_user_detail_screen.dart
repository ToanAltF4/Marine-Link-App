import 'package:flutter/material.dart';
import 'package:marinelink/core/constants/app_strings.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/assets/app_assets.dart';
import '../../../../shared/widgets/role_back_to_dashboard_scope.dart';
import '../../domain/admin_user.dart';

class AdminUserDetailScreen extends StatelessWidget {
  final AdminUser? user;

  const AdminUserDetailScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final user = this.user;
    return RoleBackToDashboardScope(
      dashboardLocation: AppRoutes.adminUsers,
      child: Scaffold(
        key: const Key('adminUserDetailScreen'),
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text(AppStrings.adminUserDetailTitle)),
        body: user == null
            ? const _AdminUserDetailMissing()
            : _AdminUserDetailContent(user: user),
      ),
    );
  }
}

class _AdminUserDetailMissing extends StatelessWidget {
  const _AdminUserDetailMissing();

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('adminUserDetailMissing'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          AppStrings.adminUsersLoadFailed,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _AdminUserDetailContent extends StatelessWidget {
  final AdminUser user;

  const _AdminUserDetailContent({required this.user});

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('adminUserDetailContent'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _AdminUserHeaderCard(user: user),
        const SizedBox(height: 14),
        _AdminUserSection(
          title: AppStrings.adminUserDetailContactSection,
          rows: [
            _DetailRow(
              key: const Key('adminUserDetailEmail'),
              icon: Icons.mail_outline,
              label: AppStrings.emailLabel,
              value: user.email,
            ),
            _DetailRow(
              key: const Key('adminUserDetailPhone'),
              icon: Icons.call_outlined,
              label: AppStrings.phoneLabel,
              value: user.phone,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _AdminUserSection(
          title: AppStrings.adminUserDetailBusinessSection,
          rows: [
            _DetailRow(
              key: const Key('adminUserDetailStoreName'),
              icon: Icons.storefront_outlined,
              label: AppStrings.storeNameLabel,
              value: user.storeName,
            ),
            _DetailRow(
              key: const Key('adminUserDetailTaxCode'),
              icon: Icons.badge_outlined,
              label: AppStrings.taxCodeMstLabel,
              value: user.taxCode,
            ),
            _DetailRow(
              key: const Key('adminUserDetailBusinessAddress'),
              icon: Icons.location_on_outlined,
              label: AppStrings.businessAddressLabel,
              value: user.businessAddress,
            ),
          ],
        ),
      ],
    );
  }
}

class _AdminUserHeaderCard extends StatelessWidget {
  final AdminUser user;

  const _AdminUserHeaderCard({required this.user});

  @override
  Widget build(BuildContext context) {
    final statusStyle = _statusStyle(user.status);
    return DecoratedBox(
      key: const Key('adminUserDetailHeaderCard'),
      decoration: _cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _DetailAvatar(user: user),
            const SizedBox(height: 12),
            Text(
              user.fullName.trim().isEmpty ? '—' : user.fullName,
              key: const Key('adminUserDetailFullName'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RoleBadge(role: user.role),
                const SizedBox(width: 8),
                _StatusPill(
                  label: statusStyle.label,
                  textColor: statusStyle.textColor,
                  backgroundColor: statusStyle.backgroundColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailAvatar extends StatelessWidget {
  final AdminUser user;

  const _DetailAvatar({required this.user});

  @override
  Widget build(BuildContext context) {
    final avatarUrl = user.avatarUrl;
    final name = user.fullName.trim();
    final label = name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();

    return Container(
      width: 76,
      height: 76,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.surfaceSky,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: avatarUrl != null && avatarUrl.isNotEmpty
          ? Image.network(
              avatarUrl,
              width: 76,
              height: 76,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _AvatarFallback(label: label),
            )
          : _AvatarFallback(label: label),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String label;

  const _AvatarFallback({required this.label});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      AppAssets.logoCircle,
      width: 76,
      height: 76,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Center(
        child: Text(
          label,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _AdminUserSection extends StatelessWidget {
  final String title;
  final List<Widget> rows;

  const _AdminUserSection({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: _cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const Divider(height: 20, color: AppColors.border),
              rows[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;

  const _DetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final display = (value == null || value!.trim().isEmpty)
        ? AppStrings.notUpdatedValue
        : value!.trim();
    final isEmpty = value == null || value!.trim().isEmpty;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                display,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isEmpty
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                  fontWeight: isEmpty ? FontWeight.w400 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final AdminUserRole role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceSky,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          _roleLabel(role),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color backgroundColor;

  const _StatusPill({
    required this.label,
    required this.textColor,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

String _roleLabel(AdminUserRole role) {
  return switch (role) {
    AdminUserRole.admin => 'ADMIN',
    AdminUserRole.staff => 'STAFF',
    AdminUserRole.user => 'USER',
  };
}

({String label, Color textColor, Color backgroundColor}) _statusStyle(
  AdminUserStatus status,
) {
  return switch (status) {
    AdminUserStatus.pendingApproval => (
      label: AppStrings.orderPendingApproval,
      textColor: AppColors.warning,
      backgroundColor: const Color(0xFFFFF7E6),
    ),
    AdminUserStatus.active => (
      label: AppStrings.userActive,
      textColor: AppColors.success,
      backgroundColor: const Color(0xFFE8F8EF),
    ),
    AdminUserStatus.disabled => (
      label: AppStrings.userLocked,
      textColor: AppColors.error,
      backgroundColor: const Color(0xFFFFEFEF),
    ),
  };
}

final _cardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(8),
  border: Border.all(color: AppColors.border),
  boxShadow: const [
    BoxShadow(color: Color(0x110B3760), blurRadius: 12, offset: Offset(0, 4)),
  ],
);
