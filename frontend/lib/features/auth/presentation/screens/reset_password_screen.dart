import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/auth_repository.dart';
import '../cubit/forgot_password_cubit.dart';
import '../widgets/auth_brand_header.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final AuthRepository? authRepository;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    this.authRepository,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  static const int _otpLength = 6;

  late final ForgotPasswordCubit _cubit;
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _cubit = ForgotPasswordCubit(authRepository: _resolveAuthRepository());
  }

  @override
  void dispose() {
    _cubit.close();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  AuthRepository _resolveAuthRepository() {
    if (widget.authRepository != null) {
      return widget.authRepository!;
    }
    return sl<AuthRepository>();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    _cubit.resetPassword(
      email: widget.email,
      otpCode: _otpController.text.trim(),
      newPassword: _newPasswordController.text,
    );
  }

  String? _validateOtp(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return AppStrings.otpCodeRequired;
    }
    if (trimmed.length != _otpLength) {
      return AppStrings.otpCodeLength;
    }
    return null;
  }

  String? _validateNewPassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.newPasswordRequired;
    }
    if (value.length < 6) {
      return AppStrings.passwordMin6;
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppStrings.confirmPasswordRequired;
    }
    if (value != _newPasswordController.text) {
      return AppStrings.confirmPasswordMismatch;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<ForgotPasswordCubit, ForgotPasswordState>(
        listener: (context, state) {
          if (state.status == ForgotPasswordStatus.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                key: const Key('resetPasswordSuccess'),
                content: const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.white),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        AppStrings.resetPasswordSuccess,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF1B8F5B),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
            context.go(AppRoutes.login);
          }
          if (state.status == ForgotPasswordStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                key: const Key('resetPasswordError'),
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        state.errorMessage ?? AppStrings.resetPasswordFailed,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFFD32F2F),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF0F4FF),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AuthBrandHeader(compact: true),
                      const SizedBox(height: 28),
                      AuthCard(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF0B3D91),
                                        Color(0xFF1565C0),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF0B3D91,
                                        ).withValues(alpha: 0.30),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.lock_reset_rounded,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                AppStrings.resetPasswordTitle,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      color: const Color(0xFF052449),
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: const Color(0xFF4A5160),
                                      ),
                                  children: [
                                    const TextSpan(
                                      text: AppStrings.resetPasswordSubtitle,
                                    ),
                                    if (widget.email.isNotEmpty) ...[
                                      const TextSpan(text: '\n'),
                                      TextSpan(
                                        text: widget.email,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF0B3D91),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 28),
                              TextFormField(
                                key: const Key('resetPasswordOtpField'),
                                controller: _otpController,
                                keyboardType: TextInputType.number,
                                maxLength: _otpLength,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: _validateOtp,
                                decoration: const InputDecoration(
                                  counterText: '',
                                  labelText: AppStrings.otpCodeLabel,
                                  hintText: AppStrings.otpCodeHint,
                                  prefixIcon: Icon(Icons.pin_outlined),
                                ),
                              ),
                              const SizedBox(height: 18),
                              TextFormField(
                                key: const Key('resetPasswordNewField'),
                                controller: _newPasswordController,
                                obscureText: _obscureNew,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                validator: _validateNewPassword,
                                decoration: InputDecoration(
                                  labelText: AppStrings.newPasswordLabel,
                                  hintText: AppStrings.passwordHint,
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    tooltip: _obscureNew
                                        ? AppStrings.showPassword
                                        : AppStrings.hidePassword,
                                    onPressed: () => setState(
                                      () => _obscureNew = !_obscureNew,
                                    ),
                                    icon: Icon(
                                      _obscureNew
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              TextFormField(
                                key: const Key('resetPasswordConfirmField'),
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirm,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                validator: _validateConfirmPassword,
                                decoration: InputDecoration(
                                  labelText: AppStrings.confirmPasswordLabel,
                                  hintText: AppStrings.confirmPasswordHint,
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    tooltip: _obscureConfirm
                                        ? AppStrings.showPassword
                                        : AppStrings.hidePassword,
                                    onPressed: () => setState(
                                      () => _obscureConfirm = !_obscureConfirm,
                                    ),
                                    icon: Icon(
                                      _obscureConfirm
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                  ),
                                ),
                                onFieldSubmitted: (_) => _submit(),
                              ),
                              const SizedBox(height: 24),
                              BlocBuilder<
                                ForgotPasswordCubit,
                                ForgotPasswordState
                              >(
                                builder: (context, state) {
                                  return FilledButton.icon(
                                    key: const Key('resetPasswordSubmitButton'),
                                    onPressed: state.isLoading ? null : _submit,
                                    icon: state.isLoading
                                        ? const SizedBox.square(
                                            key: Key('resetPasswordLoading'),
                                            dimension: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.check_rounded),
                                    label: const Text(
                                      AppStrings.resetPasswordButton,
                                    ),
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size.fromHeight(52),
                                      backgroundColor: const Color(0xFF0B3D91),
                                      textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
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
                      TextButton.icon(
                        key: const Key('resetPasswordBackToLoginButton'),
                        onPressed: () => context.go(AppRoutes.login),
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 14,
                        ),
                        label: const Text(AppStrings.backToLogin),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF4A5160),
                        ),
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
}
