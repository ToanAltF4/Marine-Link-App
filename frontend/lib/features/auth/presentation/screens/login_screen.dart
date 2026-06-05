import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/validators.dart';
import '../../domain/user.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_brand_header.dart';

class LoginScreen extends StatefulWidget {
  final ValueChanged<User>? onAuthenticated;

  const LoginScreen({super.key, this.onAuthenticated});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailOrPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailOrPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đăng nhập thành công: ${state.user.fullName}'),
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
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Đăng nhập',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: const Color(0xFF052449),
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Chào mừng quay lại',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: const Color(0xFF4A5160)),
                            ),
                            const SizedBox(height: 28),
                            TextFormField(
                              key: const Key('loginEmailOrPhoneField'),
                              controller: _emailOrPhoneController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email hoặc số điện thoại',
                                hintText: 'Nhập email hoặc số điện thoại',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              textInputAction: TextInputAction.next,
                              validator: _validateEmailOrPhone,
                            ),
                            const SizedBox(height: 18),
                            TextFormField(
                              key: const Key('loginPasswordField'),
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'Mật khẩu',
                                hintText: 'Nhập mật khẩu',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  tooltip: _obscurePassword
                                      ? 'Hiện mật khẩu'
                                      : 'Ẩn mật khẩu',
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                  ),
                                ),
                              ),
                              obscureText: _obscurePassword,
                              onFieldSubmitted: (_) => _submit(),
                              validator: Validators.password,
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {},
                                child: const Text('Quên mật khẩu?'),
                              ),
                            ),
                            const SizedBox(height: 10),
                            BlocBuilder<AuthBloc, AuthState>(
                              builder: (context, state) {
                                final isLoading = state is AuthLoading;
                                return _GradientButton(
                                  key: const Key('loginSubmitButton'),
                                  onPressed: isLoading ? null : _submit,
                                  child: isLoading
                                      ? const SizedBox.square(
                                          dimension: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Đăng nhập'),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                            const _DividerLabel(label: 'Hoặc'),
                            const SizedBox(height: 18),
                            OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Google login sẽ được bổ sung sau MVP',
                                    ),
                                  ),
                                );
                              },
                              icon: const _GoogleMark(),
                              label: const Text('Đăng nhập với Google'),
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
                          'Chưa có tài khoản?',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: const Color(0xFF303642)),
                        ),
                        TextButton(
                          onPressed: () => context.go('/register'),
                          child: const Text('Đăng ký'),
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
    );
  }

  String? _validateEmailOrPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email hoặc số điện thoại không được để trống';
    }
    return null;
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
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
      router.go('/admin');
      return;
    }
    if (user.isStaff) {
      router.go('/staff');
      return;
    }
    router.go('/home');
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
