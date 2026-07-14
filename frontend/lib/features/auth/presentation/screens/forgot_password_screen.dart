import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/service_locator.dart';
import '../../../../app/router/app_router.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/auth_repository.dart';
import '../cubit/forgot_password_cubit.dart';
import '../widgets/auth_brand_header.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final AuthRepository? authRepository;

  const ForgotPasswordScreen({super.key, this.authRepository});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final ForgotPasswordCubit _cubit;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cubit = ForgotPasswordCubit(authRepository: _resolveAuthRepository());
  }

  @override
  void dispose() {
    _cubit.close();
    _emailController.dispose();
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
    _cubit.requestOtp(_emailController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<ForgotPasswordCubit, ForgotPasswordState>(
        listener: (context, state) {
          if (state.status == ForgotPasswordStatus.otpSent) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(AppStrings.otpSentToEmail),
                backgroundColor: const Color(0xFF0B3D91),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
            context.push(AppRoutes.resetPassword, extra: state.email);
          }
          if (state.status == ForgotPasswordStatus.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                key: const Key('forgotPasswordError'),
                content: Text(
                  state.errorMessage ?? AppStrings.forgotPasswordFailed,
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
                                AppStrings.forgotPasswordTitle,
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
                              Text(
                                AppStrings.forgotPasswordSubtitle,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: const Color(0xFF4A5160)),
                              ),
                              const SizedBox(height: 28),
                              TextFormField(
                                key: const Key('forgotPasswordEmailField'),
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.done,
                                autovalidateMode:
                                    AutovalidateMode.onUserInteraction,
                                validator: Validators.email,
                                decoration: const InputDecoration(
                                  labelText: AppStrings.forgotPasswordEmailLabel,
                                  hintText: AppStrings.forgotPasswordEmailHint,
                                  prefixIcon: Icon(Icons.email_outlined),
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
                                    key: const Key('forgotPasswordSubmitButton'),
                                    onPressed: state.isLoading ? null : _submit,
                                    icon: state.isLoading
                                        ? const SizedBox.square(
                                            key: Key('forgotPasswordLoading'),
                                            dimension: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(Icons.send_rounded),
                                    label: const Text(AppStrings.sendOtpButton),
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
                        key: const Key('forgotPasswordBackToLoginButton'),
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
