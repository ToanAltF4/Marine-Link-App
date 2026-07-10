import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../app/router/app_router.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/assets/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/navigation/buyer_navigation.dart';
import '../../../../shared/widgets/app_error_state.dart';
import '../../../../shared/widgets/app_loading_indicator.dart';
import '../../../../shared/widgets/buyer_bottom_nav.dart';
import '../../../../shared/widgets/role_bottom_nav.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/profile.dart';
import '../bloc/profile_cubit.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => sl<ProfileCubit>()..loadProfile(),
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView();

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  final _formKey = GlobalKey<FormState>();
  final _phoneRegex = RegExp(r'^(0|\+84)\d{9,10}$');

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _addressController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _fillFields(Profile profile) {
    if (_isEditing) return;
    _nameController.text = profile.fullName;
    _phoneController.text = profile.phone;
    _addressController.text = profile.businessAddress ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('profileScreen'),
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.personalProfileTitle),
        actions: [
          if (!_isEditing)
            IconButton(
              key: const Key('profileEditButton'),
              tooltip: AppStrings.editProfile,
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
            ),
        ],
      ),
      bottomNavigationBar: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state is AuthAuthenticated ? state.user : null;
          if (user?.isStaff == true) {
            return const StaffBottomNav(currentTab: StaffBottomNavTab.profile);
          }
          if (user?.isAdmin == true) {
            return const AdminBottomNav(currentTab: AdminBottomNavTab.profile);
          }
          return const BuyerBottomNav(currentTab: BuyerBottomNavTab.profile);
        },
      ),
      body: BlocConsumer<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state.status == ProfileStatus.updateSuccess) {
            setState(() => _isEditing = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(AppStrings.profileUpdateSuccess)),
            );
          }
          if (state.status == ProfileStatus.updateFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.errorMessage ?? AppStrings.profileUpdateFailed,
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          final profile = state.profile;
          if (state.status == ProfileStatus.loading && profile == null) {
            return const AppLoadingIndicator(
              key: Key('profileLoading'),
              message: AppStrings.profileLoading,
            );
          }

          if (state.status == ProfileStatus.failure && profile == null) {
            return AppErrorState(
              key: const Key('profileError'),
              message: state.errorMessage ?? AppStrings.profileLoadFailed,
              retryLabel: AppStrings.reload,
              onRetry: context.read<ProfileCubit>().loadProfile,
            );
          }

          if (profile == null) {
            return const AppErrorState(
              key: Key('profileError'),
              message: AppStrings.profileNotFound,
            );
          }

          _fillFields(profile);

          return SingleChildScrollView(
            key: const Key('profileScrollView'),
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileHeader(profile: profile),
                  const SizedBox(height: 16),
                  _buildInfoPanel(),
                  const SizedBox(height: 16),
                  if (_isEditing)
                    _buildActionButtons(context, state)
                  else
                    _buildNavigationTiles(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoPanel() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildField(
              key: const Key('profileNameField'),
              label: AppStrings.fullNameLabel,
              controller: _nameController,
              enabled: _isEditing,
              icon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              validator: _validateName,
            ),
            const SizedBox(height: 14),
            _buildField(
              key: const Key('profilePhoneField'),
              label: AppStrings.phoneLabel,
              controller: _phoneController,
              enabled: _isEditing,
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              validator: _validatePhone,
            ),
            const SizedBox(height: 14),
            _buildField(
              key: const Key('profileAddressField'),
              label: AppStrings.businessAddressLabel,
              controller: _addressController,
              enabled: _isEditing,
              icon: Icons.location_on_outlined,
              maxLines: 2,
              textInputAction: TextInputAction.done,
              validator: _validateAddress,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required Key key,
    required String label,
    required TextEditingController controller,
    required bool enabled,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 8),
        TextFormField(
          key: key,
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.primary),
            filled: !enabled,
            fillColor: enabled ? Colors.white : AppColors.background,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, ProfileState state) {
    final isUpdating = state.status == ProfileStatus.updating;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            key: const Key('profileCancelButton'),
            onPressed: isUpdating
                ? null
                : () {
                    setState(() => _isEditing = false);
                    final profile = state.profile;
                    if (profile != null) _fillFields(profile);
                  },
            icon: const Icon(Icons.close_rounded),
            label: const Text(AppStrings.cancel),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            key: const Key('profileSaveButton'),
            onPressed: isUpdating ? null : _saveProfile,
            icon: isUpdating
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text(AppStrings.save),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationTiles(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final isBuyer = user?.isUser ?? true;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          if (isBuyer) ...[
            _ProfileActionTile(
              key: const Key('profileOrdersTile'),
              icon: Icons.receipt_long_outlined,
              title: AppStrings.myOrders,
              subtitle: AppStrings.myOrdersSubtitle,
              onTap: () => BuyerNavigation.push(context, AppRoutes.orders),
            ),
            const Divider(height: 1, indent: 64),
          ],
          _ProfileActionTile(
            key: const Key('profileSupportTile'),
            icon: Icons.support_agent_outlined,
            title: AppStrings.support,
            subtitle: isBuyer
                ? AppStrings.buyerSupportSubtitle
                : AppStrings.internalSupportSubtitle,
            onTap: () {
              if (user?.isStaff == true) {
                context.push(AppRoutes.staffChat);
              } else if (user?.isAdmin == true) {
                context.push(AppRoutes.adminDashboard);
              } else {
                context.push(AppRoutes.chat);
              }
            },
          ),
          const Divider(height: 1, indent: 64),
          _ProfileActionTile(
            key: const Key('profileChangePasswordTile'),
            icon: Icons.lock_outline_rounded,
            title: AppStrings.changePasswordTitle,
            subtitle: AppStrings.changePasswordSubtitle,
            onTap: () => context.push(AppRoutes.changePassword),
          ),
          const Divider(height: 1, indent: 64),
          _ProfileActionTile(
            key: const Key('profileLogoutTile'),
            icon: Icons.logout_rounded,
            title: AppStrings.logout,
            subtitle: AppStrings.logoutSubtitle,
            onTap: () => _showLogoutConfirmation(context),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          AppStrings.logoutTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          AppStrings.logoutConfirmMessage,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        actionsPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        actions: [
          TextButton(
            key: const Key('profileLogoutCancelButton'),
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              AppStrings.cancel,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            key: const Key('profileLogoutConfirmButton'),
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthBloc>().add(const AuthLogoutRequested());
              context.go(AppRoutes.login);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              AppStrings.logout,
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  String? _validateName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return AppStrings.nameRequired;
    if (text.length < 2) return AppStrings.nameTooShort;
    if (text.length > 100) return AppStrings.nameTooLong;
    return null;
  }

  String? _validatePhone(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return AppStrings.phoneRequired;
    if (!_phoneRegex.hasMatch(text)) return AppStrings.phoneInvalidShort;
    return null;
  }

  String? _validateAddress(String? value) {
    final text = value?.trim() ?? '';
    if (text.length > 255) return AppStrings.addressTooLong;
    return null;
  }

  void _saveProfile() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<ProfileCubit>().updateProfile(
        fullName: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        businessAddress: _emptyToNull(_addressController.text),
        avatarUrl: null,
      );
    }
  }

  String? _emptyToNull(String value) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }
}

class _ProfileHeader extends StatelessWidget {
  final Profile profile;

  const _ProfileHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _AvatarPreview(key: const Key('profileAvatar')),
            const SizedBox(height: 14),
            Text(
              profile.fullName,
              key: const Key('profileFullNameText'),
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              profile.email,
              key: const Key('profileEmailText'),
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 96,
      child: ClipOval(
        child: ColoredBox(
          color: AppColors.surfaceSky,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Image.asset(AppAssets.logoCircle, fit: BoxFit.contain),
          ),
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
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceSky,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: AppColors.primary),
          ),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.textSecondary,
        ),
        onTap: onTap,
      ),
    );
  }
}
