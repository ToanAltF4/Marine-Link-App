import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/auth_repository.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../cubit/auth_form_cubit.dart';
import '../widgets/auth_brand_header.dart';

class RegisterScreen extends StatefulWidget {
  final AuthRepository? authRepository;

  const RegisterScreen({super.key, this.authRepository});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  late final AuthFormCubit _formCubit;
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _taxCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _formCubit = AuthFormCubit(authRepository: _resolveAuthRepository());
  }

  @override
  void dispose() {
    _formCubit.close();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _storeNameController.dispose();
    _addressController.dispose();
    _taxCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _formCubit,
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthOtpSent) {
            context.go(AppRoutes.verifyEmail, extra: state.email);
          }
          if (state is AuthFailure) {
            _applyServerFieldError(state.message);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F7FC),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AuthBrandHeader(compact: true),
                      const SizedBox(height: 24),
                      AuthCard(
                        child: BlocBuilder<AuthFormCubit, AuthFormState>(
                          builder: (context, formState) => Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                AppStrings.registerDealerTitle,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: const Color(0xFF052449),
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppStrings.registerDealerSubtitle,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(color: const Color(0xFF4A5160)),
                              ),
                              const SizedBox(height: 28),
                              TextFormField(
                                key: const Key('registerFullNameField'),
                                controller: _fullNameController,
                                decoration: InputDecoration(
                                  labelText: AppStrings.fullNameRequiredLabel,
                                  prefixIcon: const Icon(Icons.badge_outlined),
                                  suffixIcon: _fieldStatusIcon(
                                    formState.fullName,
                                  ),
                                  errorText: formState.fullName.visibleMessage,
                                ),
                                textInputAction: TextInputAction.next,
                                onChanged: context
                                    .read<AuthFormCubit>()
                                    .registerFullNameChanged,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                key: const Key('registerEmailField'),
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: AppStrings.emailRequiredLabel,
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  suffixIcon: _fieldStatusIcon(formState.email),
                                  errorText: formState.email.visibleMessage,
                                ),
                                textInputAction: TextInputAction.next,
                                onChanged: context
                                    .read<AuthFormCubit>()
                                    .registerEmailChanged,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                key: const Key('registerPhoneField'),
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  labelText: AppStrings.phoneRequiredLabel,
                                  prefixIcon: const Icon(Icons.phone_outlined),
                                  suffixIcon: _fieldStatusIcon(formState.phone),
                                  errorText: formState.phone.visibleMessage,
                                ),
                                textInputAction: TextInputAction.next,
                                onChanged: context
                                    .read<AuthFormCubit>()
                                    .registerPhoneChanged,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                key: const Key('registerPasswordField'),
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: AppStrings.passwordRequiredLabel,
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: _fieldStatusIcon(
                                    formState.password,
                                  ),
                                  errorText: formState.password.visibleMessage,
                                ),
                                obscureText: true,
                                textInputAction: TextInputAction.next,
                                onChanged: context
                                    .read<AuthFormCubit>()
                                    .registerPasswordChanged,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                key: const Key('registerConfirmPasswordField'),
                                controller: _confirmPasswordController,
                                decoration: InputDecoration(
                                  labelText:
                                      AppStrings.confirmPasswordRequiredLabel,
                                  prefixIcon: const Icon(
                                    Icons.verified_user_outlined,
                                  ),
                                  suffixIcon: _fieldStatusIcon(
                                    formState.confirmPassword,
                                  ),
                                  errorText:
                                      formState.confirmPassword.visibleMessage,
                                ),
                                obscureText: true,
                                textInputAction: TextInputAction.next,
                                onChanged: context
                                    .read<AuthFormCubit>()
                                    .registerConfirmPasswordChanged,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                key: const Key('registerStoreNameField'),
                                controller: _storeNameController,
                                decoration: InputDecoration(
                                  labelText: AppStrings.storeNameLabel,
                                  prefixIcon: const Icon(
                                    Icons.storefront_outlined,
                                  ),
                                  suffixIcon: _fieldStatusIcon(
                                    formState.storeName,
                                  ),
                                ),
                                textInputAction: TextInputAction.next,
                                onChanged: context
                                    .read<AuthFormCubit>()
                                    .registerStoreNameChanged,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                key: const Key('registerBusinessAddressField'),
                                controller: _addressController,
                                decoration: InputDecoration(
                                  labelText:
                                      AppStrings.businessAddressRequiredLabel,
                                  prefixIcon: const Icon(
                                    Icons.location_on_outlined,
                                  ),
                                  suffixIcon: _fieldStatusIcon(
                                    formState.address,
                                  ),
                                  errorText: formState.address.visibleMessage,
                                ),
                                textInputAction: TextInputAction.next,
                                onChanged: context
                                    .read<AuthFormCubit>()
                                    .registerAddressChanged,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                key: const Key('registerTaxCodeField'),
                                controller: _taxCodeController,
                                decoration: InputDecoration(
                                  labelText: AppStrings.taxCodeLabel,
                                  prefixIcon: const Icon(
                                    Icons.receipt_long_outlined,
                                  ),
                                  suffixIcon: _fieldStatusIcon(
                                    formState.taxCode,
                                  ),
                                  errorText: formState.taxCode.visibleMessage,
                                ),
                                textInputAction: TextInputAction.done,
                                onChanged: context
                                    .read<AuthFormCubit>()
                                    .registerTaxCodeChanged,
                              ),
                              const SizedBox(height: 24),
                              BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                                  final isLoading = state is AuthLoading;
                                  return FilledButton.icon(
                                    key: const Key('registerSubmitButton'),
                                    onPressed:
                                        isLoading ||
                                            !formState.canSubmitRegister
                                        ? null
                                        : _submit,
                                    icon: isLoading
                                        ? const SizedBox.square(
                                            dimension: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(Icons.person_add_alt_1),
                                    label: const Text(AppStrings.register),
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size.fromHeight(56),
                                      textStyle: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            AppStrings.alreadyHaveAccount,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: const Color(0xFF303642)),
                          ),
                          TextButton(
                            onPressed: () => context.go(AppRoutes.login),
                            child: const Text(AppStrings.loginTitle),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formCubit.state.canSubmitRegister) return;
    context.read<AuthBloc>().add(
      AuthRegisterRequested(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        storeName: _trimOptional(_storeNameController.text),
        businessAddress: _trimOptional(_addressController.text),
        taxCode: _trimOptional(_taxCodeController.text),
      ),
    );
  }

  String? _trimOptional(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  AuthRepository? _resolveAuthRepository() {
    if (widget.authRepository != null) {
      return widget.authRepository;
    }
    return sl.isRegistered<AuthRepository>() ? sl<AuthRepository>() : null;
  }

  void _applyServerFieldError(String message) {
    if (message.contains('Email')) {
      _formCubit.registerEmailServerInvalid(message);
      return;
    }
    if (message.contains('Số điện thoại')) {
      _formCubit.registerPhoneServerInvalid(message);
    }
  }

  Widget? _fieldStatusIcon(AuthValidatedField field) {
    final icon = switch (field.status) {
      AuthFieldStatus.valid when field.dirty => const Icon(
        Icons.check_circle,
        color: Color(0xFF138A5B),
      ),
      AuthFieldStatus.invalid || AuthFieldStatus.serverInvalid => const Icon(
        Icons.error_outline,
        color: Color(0xFFD64545),
      ),
      AuthFieldStatus.checking => const Center(
        widthFactor: 1,
        heightFactor: 1,
        child: SizedBox.square(
          dimension: 14,
          child: CircularProgressIndicator(strokeWidth: 1.6),
        ),
      ),
      _ => null,
    };
    return icon;
  }
}
