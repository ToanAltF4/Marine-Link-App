import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_router.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/user.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../cubit/auth_form_cubit.dart';
import '../widgets/auth_brand_header.dart';

class LoginScreen extends StatefulWidget {
  final ValueChanged<User>? onAuthenticated;

  const LoginScreen({super.key, this.onAuthenticated});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AuthFormCubit _formCubit;
  final _emailOrPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _formCubit = AuthFormCubit();
  }

  @override
  void dispose() {
    _formCubit.close();
    _emailOrPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _formCubit,
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppStrings.loginSuccess(state.user.fullName)),
              ),
            );
            _routeByRole(context, state.user);
          }
          if (state is AuthFailure) {
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
                padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AuthBrandHeader(),
                      const SizedBox(height: 34),
                      AuthCard(
                        child: BlocBuilder<AuthFormCubit, AuthFormState>(
                          builder: (context, formState) => Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                AppStrings.loginTitle,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: const Color(0xFF052449),
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                AppStrings.loginWelcomeBack,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(color: const Color(0xFF4A5160)),
                              ),
                              const SizedBox(height: 28),
                              TextFormField(
                                key: const Key('loginEmailOrPhoneField'),
                                controller: _emailOrPhoneController,
                                keyboardType: TextInputType.emailAddress,
                                decoration: InputDecoration(
                                  labelText: AppStrings.loginEmailOrPhoneLabel,
                                  hintText: AppStrings.loginEmailOrPhoneHint,
                                  prefixIcon: const Icon(Icons.person_outline),
                                  suffixIcon: _fieldStatusIcon(
                                    formState.loginEmailOrPhone,
                                  ),
                                  errorText: formState
                                      .loginEmailOrPhone
                                      .visibleMessage,
                                ),
                                textInputAction: TextInputAction.next,
                                onChanged: context
                                    .read<AuthFormCubit>()
                                    .loginEmailOrPhoneChanged,
                              ),
                              const SizedBox(height: 18),
                              TextFormField(
                                key: const Key('loginPasswordField'),
                                controller: _passwordController,
                                decoration: InputDecoration(
                                  labelText: AppStrings.passwordLabel,
                                  hintText: AppStrings.passwordHint,
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  suffixIcon: _fieldStatusIcon(
                                    formState.loginPassword,
                                    actions: [
                                      IconButton(
                                        tooltip: _obscurePassword
                                            ? AppStrings.showPassword
                                            : AppStrings.hidePassword,
                                        onPressed: () => setState(
                                          () => _obscurePassword =
                                              !_obscurePassword,
                                        ),
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                        ),
                                      ),
                                    ],
                                  ),
                                  errorText:
                                      formState.loginPassword.visibleMessage,
                                ),
                                obscureText: _obscurePassword,
                                onChanged: context
                                    .read<AuthFormCubit>()
                                    .loginPasswordChanged,
                                onFieldSubmitted: (_) => _submit(),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  key: const Key('loginForgotPasswordButton'),
                                  onPressed: () =>
                                      context.push(AppRoutes.forgotPassword),
                                  child: const Text(AppStrings.forgotPassword),
                                ),
                              ),
                              const SizedBox(height: 10),
                              BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                                  final isLoading = state is AuthLoading;
                                  return _GradientButton(
                                    key: const Key('loginSubmitButton'),
                                    onPressed:
                                        isLoading || !formState.canSubmitLogin
                                        ? null
                                        : _submit,
                                    child: isLoading
                                        ? const SizedBox.square(
                                            dimension: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Text(AppStrings.loginTitle),
                                  );
                                },
                              ),
                              const SizedBox(height: 24),
                              const _DividerLabel(label: AppStrings.or),
                              const SizedBox(height: 18),
                              BlocBuilder<AuthBloc, AuthState>(
                                builder: (context, state) {
                                  final isLoading = state is AuthLoading;
                                  return OutlinedButton.icon(
                                    key: const Key('loginGoogleButton'),
                                    onPressed: isLoading
                                        ? null
                                        : () => context.read<AuthBloc>().add(
                                            const AuthGoogleLoginRequested(),
                                          ),
                                    icon: const _GoogleMark(),
                                    label: const Text(
                                      AppStrings.loginWithGoogle,
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(56),
                                      foregroundColor: const Color(0xFF006C67),
                                      side: const BorderSide(
                                        color: Color(0xFF006C67),
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            AppStrings.noAccount,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: const Color(0xFF303642)),
                          ),
                          TextButton(
                            onPressed: () => context.go(AppRoutes.register),
                            child: const Text(AppStrings.register),
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
    if (!_formCubit.state.canSubmitLogin) return;
    context.read<AuthBloc>().add(
      AuthLoginRequested(
        emailOrPhone: _emailOrPhoneController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  void _routeByRole(BuildContext context, User user) {
    if (widget.onAuthenticated != null) {
      widget.onAuthenticated!(user);
      return;
    }

    final router = GoRouter.maybeOf(context);
    if (router == null) return;

    if (user.isAdmin) {
      router.go(AppRoutes.adminDashboard);
      return;
    }
    if (user.isStaff) {
      router.go(AppRoutes.staffDashboard);
      return;
    }
    router.go(AppRoutes.home);
  }

  Widget? _fieldStatusIcon(
    AuthValidatedField field, {
    List<Widget> actions = const [],
  }) {
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

    if (icon == null && actions.isEmpty) return null;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null)
          Padding(padding: const EdgeInsets.only(right: 4), child: icon),
        ...actions,
      ],
    );
  }
}

class _GradientButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;

  const _GradientButton({
    super.key,
    required this.onPressed,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: onPressed == null
            ? null
            : const LinearGradient(
                colors: [Color(0xFF0B4F8F), Color(0xFF007A78)],
              ),
        color: onPressed == null ? const Color(0xFFB7C0CC) : null,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (onPressed != null)
            BoxShadow(
              color: const Color(0xFF006C67).withValues(alpha: 0.22),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
        ],
      ),
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(58),
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: child,
      ),
    );
  }
}

class _DividerLabel extends StatelessWidget {
  final String label;

  const _DividerLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF7A8190),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        color: Color(0xFF4285F4),
        fontSize: 22,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}
