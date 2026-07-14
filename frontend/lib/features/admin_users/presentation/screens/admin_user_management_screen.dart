import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:marinelink/core/constants/app_strings.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/role_back_to_dashboard_scope.dart';
import '../../../../shared/widgets/app_empty_state.dart';
import '../../../../shared/widgets/role_bottom_nav.dart';
import '../../domain/admin_user.dart';
import '../cubit/admin_user_cubit.dart';

class AdminUserManagementScreen extends StatelessWidget {
  const AdminUserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminUserCubit>(
      create: (_) => sl<AdminUserCubit>()..load(),
      child: const _AdminUserView(),
    );
  }
}

class _AdminUserView extends StatelessWidget {
  const _AdminUserView();

  @override
  Widget build(BuildContext context) {
    return RoleBackToDashboardScope(
      dashboardLocation: AppRoutes.adminDashboard,
      child: Scaffold(
        key: const Key('adminUsersScreen'),
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(AppStrings.adminUsersTitle),
          actions: [
            IconButton(
              key: const Key('adminCreateUserButton'),
              tooltip: AppStrings.adminCreateUserAction,
              icon: const Icon(Icons.person_add_alt_1_outlined),
              onPressed: () => _showCreateUserForm(context),
            ),
          ],
        ),
        bottomNavigationBar: const AdminBottomNav(
          currentTab: AdminBottomNavTab.users,
        ),
        body: BlocBuilder<AdminUserCubit, AdminUserState>(
          builder: (context, state) {
            switch (state.status) {
              case AdminUserStatusView.initial:
              case AdminUserStatusView.loading:
                return const Center(
                  key: Key('adminUsersLoading'),
                  child: CircularProgressIndicator(),
                );
              case AdminUserStatusView.failure:
                return _AdminUsersError(
                  message:
                      state.errorMessage ?? AppStrings.adminUsersLoadFailed,
                  onRetry: () => context.read<AdminUserCubit>().load(),
                );
              case AdminUserStatusView.empty:
                return const _AdminUsersEmpty();
              case AdminUserStatusView.success:
                return RefreshIndicator(
                  onRefresh: () => context.read<AdminUserCubit>().load(),
                  child: _AdminUsersContent(state: state),
                );
            }
          },
        ),
      ),
    );
  }
}

class _AdminUsersError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _AdminUsersError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('adminUsersError'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: AppColors.error,
              size: 42,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('adminUsersRetryButton'),
              onPressed: onRetry,
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminUsersEmpty extends StatelessWidget {
  const _AdminUsersEmpty();

  @override
  Widget build(BuildContext context) {
    return const Center(
      key: Key('adminUsersEmpty'),
      child: AppEmptyState(message: AppStrings.noUsers),
    );
  }
}

class _AdminUsersContent extends StatelessWidget {
  final AdminUserState state;

  const _AdminUsersContent({required this.state});

  @override
  Widget build(BuildContext context) {
    final visibleUsers = state.visibleUsers;
    return ListView(
      key: const Key('adminUsersList'),
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _AdminUsersHeader(users: state.users),
        const SizedBox(height: 14),
        _AdminUserFilters(state: state),
        const SizedBox(height: 14),
        if (visibleUsers.isEmpty)
          const _FilteredEmptyState()
        else
          ...visibleUsers.map(
            (user) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AdminUserCard(
                user: user,
                approving: state.approvingUserId == user.id,
              ),
            ),
          ),
      ],
    );
  }
}

class _AdminUsersHeader extends StatelessWidget {
  final List<AdminUser> users;

  const _AdminUsersHeader({required this.users});

  @override
  Widget build(BuildContext context) {
    final pendingCount = users
        .where((user) => user.status == AdminUserStatus.pendingApproval)
        .length;
    return DecoratedBox(
      key: const Key('adminUsersSummaryCard'),
      decoration: _cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const _IconTile(
              icon: Icons.people_alt_outlined,
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceSky,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.systemAccounts,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.adminUserSummary(
                      userCount: users.length,
                      pendingCount: pendingCount,
                    ),
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

class _AdminUserFilters extends StatelessWidget {
  final AdminUserState state;

  const _AdminUserFilters({required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('adminUsersFilters'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FilterRow(
          children: [
            _RoleFilterChip(
              key: const Key('adminUserRoleFilterAll'),
              label: AppStrings.all,
              selected: state.selectedRole == null,
              role: null,
            ),
            _RoleFilterChip(
              key: const Key('adminUserRoleFilterAdmin'),
              label: 'Admin',
              selected: state.selectedRole == AdminUserRole.admin,
              role: AdminUserRole.admin,
            ),
            _RoleFilterChip(
              key: const Key('adminUserRoleFilterStaff'),
              label: AppStrings.staff,
              selected: state.selectedRole == AdminUserRole.staff,
              role: AdminUserRole.staff,
            ),
            _RoleFilterChip(
              key: const Key('adminUserRoleFilterUser'),
              label: AppStrings.dealer,
              selected: state.selectedRole == AdminUserRole.user,
              role: AdminUserRole.user,
            ),
          ],
        ),
        const SizedBox(height: 10),
        _FilterRow(
          children: [
            _StatusFilterChip(
              key: const Key('adminUserStatusFilterAll'),
              label: AppStrings.allStatuses,
              selected: state.selectedUserStatus == null,
              status: null,
            ),
            _StatusFilterChip(
              key: const Key('adminUserStatusFilterPending'),
              label: AppStrings.orderPendingApproval,
              selected:
                  state.selectedUserStatus == AdminUserStatus.pendingApproval,
              status: AdminUserStatus.pendingApproval,
            ),
            _StatusFilterChip(
              key: const Key('adminUserStatusFilterActive'),
              label: AppStrings.userActive,
              selected: state.selectedUserStatus == AdminUserStatus.active,
              status: AdminUserStatus.active,
            ),
            _StatusFilterChip(
              key: const Key('adminUserStatusFilterDisabled'),
              label: AppStrings.userLocked,
              selected: state.selectedUserStatus == AdminUserStatus.disabled,
              status: AdminUserStatus.disabled,
            ),
          ],
        ),
      ],
    );
  }
}

class _FilterRow extends StatelessWidget {
  final List<Widget> children;

  const _FilterRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final child in children)
            Padding(padding: const EdgeInsets.only(right: 8), child: child),
        ],
      ),
    );
  }
}

class _RoleFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final AdminUserRole? role;

  const _RoleFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => context.read<AdminUserCubit>().setRoleFilter(role),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final AdminUserStatus? status;

  const _StatusFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => context.read<AdminUserCubit>().setStatusFilter(status),
    );
  }
}

class _FilteredEmptyState extends StatelessWidget {
  const _FilteredEmptyState();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      key: const Key('adminUsersFilteredEmpty'),
      decoration: _cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(
          AppStrings.noFilteredUsers,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _AdminUserCard extends StatelessWidget {
  final AdminUser user;
  final bool approving;

  const _AdminUserCard({required this.user, required this.approving});

  @override
  Widget build(BuildContext context) {
    final statusStyle = _statusStyle(user.status);
    return DecoratedBox(
      key: Key('adminUserCard_${user.id}'),
      decoration: _cardDecoration,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          key: Key('adminUserCardTap_${user.id}'),
          borderRadius: BorderRadius.circular(8),
          onTap: () => context.push(AppRoutes.adminUserDetail, extra: user),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _UserAvatar(user: user),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    _StatusPill(
                      label: statusStyle.label,
                      textColor: statusStyle.textColor,
                      backgroundColor: statusStyle.backgroundColor,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _MetaLine(
                        icon: Icons.call_outlined,
                        text: user.phone,
                      ),
                    ),
                    const SizedBox(width: 10),
                    _RoleBadge(role: user.role),
                  ],
                ),
                if (user.status == AdminUserStatus.pendingApproval) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      key: Key('adminUserApproveButton_${user.id}'),
                      onPressed: approving
                          ? null
                          : () => context.read<AdminUserCubit>().approveUser(
                              user.id,
                            ),
                      icon: approving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.verified_user_outlined),
                      label: const Text(AppStrings.approveDealer),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final AdminUser user;

  const _UserAvatar({required this.user});

  @override
  Widget build(BuildContext context) {
    final name = user.fullName.trim();
    final label = name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.surfaceSky,
        shape: BoxShape.circle,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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

class _IconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const _IconTile({
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 22),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: textColor,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

/// Mở form tạo tài khoản (nhân viên mặc định) trong modal bottom sheet —
/// cùng cách trình bày với form sản phẩm của admin.
Future<void> _showCreateUserForm(BuildContext context) {
  final cubit = context.read<AdminUserCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.background,
    builder: (_) =>
        BlocProvider.value(value: cubit, child: const _CreateUserFormSheet()),
  );
}

class _CreateUserFormSheet extends StatefulWidget {
  const _CreateUserFormSheet();

  @override
  State<_CreateUserFormSheet> createState() => _CreateUserFormSheetState();
}

class _CreateUserFormSheetState extends State<_CreateUserFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  String _roleCode = 'STAFF';
  bool _obscurePassword = true;
  bool _submitting = false;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            key: const Key('adminCreateUserForm'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  AppStrings.adminCreateUserTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppStrings.adminCreateUserActiveNote,
                  key: const Key('adminCreateUserActiveNote'),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  key: const Key('adminCreateUserFullNameField'),
                  controller: _fullNameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: AppStrings.fullNameLabel,
                  ),
                  validator: (value) => Validators.required(
                    value,
                    fieldName: AppStrings.fullNameLabel,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  key: const Key('adminCreateUserEmailField'),
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: AppStrings.emailLabel,
                  ),
                  validator: Validators.email,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  key: const Key('adminCreateUserPhoneField'),
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: AppStrings.phoneLabel,
                  ),
                  validator: Validators.phone,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  key: const Key('adminCreateUserPasswordField'),
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: AppStrings.passwordLabel,
                    suffixIcon: IconButton(
                      key: const Key('adminCreateUserPasswordToggle'),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: _password,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  key: const Key('adminCreateUserRoleDropdown'),
                  initialValue: _roleCode,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: AppStrings.adminCreateUserRoleLabel,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'STAFF',
                      child: Text(AppStrings.adminCreateUserRoleStaff),
                    ),
                    DropdownMenuItem(
                      value: 'ADMIN',
                      child: Text(AppStrings.adminCreateUserRoleAdmin),
                    ),
                    DropdownMenuItem(
                      value: 'USER',
                      child: Text(AppStrings.adminCreateUserRoleUser),
                    ),
                  ],
                  onChanged: _submitting
                      ? null
                      : (value) {
                          if (value != null) setState(() => _roleCode = value);
                        },
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: const Key('adminCreateUserSubmitButton'),
                    // Vô hiệu hoá khi đang gửi để tránh tạo trùng tài khoản.
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            key: Key('adminCreateUserSubmitProgress'),
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.person_add_alt_1_outlined),
                    label: const Text(AppStrings.adminCreateUserSubmit),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final messenger = ScaffoldMessenger.of(context);
    if (!_formKey.currentState!.validate()) {
      messenger.showSnackBar(
        const SnackBar(
          key: Key('adminCreateUserErrorSnackBar'),
          content: Text(AppStrings.adminCreateUserFormInvalid),
        ),
      );
      return;
    }

    final cubit = context.read<AdminUserCubit>();
    final navigator = Navigator.of(context);

    setState(() => _submitting = true);
    final created = await cubit.createUser(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      roleCode: _roleCode,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (created) {
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(
          key: Key('adminCreateUserSuccessSnackBar'),
          content: Text(AppStrings.adminCreateUserSuccess),
        ),
      );
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        key: const Key('adminCreateUserErrorSnackBar'),
        content: Text(
          cubit.state.errorMessage ?? AppStrings.adminCreateUserFailed,
        ),
        backgroundColor: AppColors.error,
      ),
    );
  }
}

/// Mật khẩu tối thiểu 6 ký tự — khớp ràng buộc của backend cho form này.
String? _password(String? value) {
  if (value == null || value.isEmpty) return AppStrings.passwordRequired;
  if (value.length < 6) return AppStrings.passwordMin6;
  return null;
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
