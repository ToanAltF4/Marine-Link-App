import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/validators.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../widgets/auth_brand_header.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _taxCodeController = TextEditingController();

  @override
  void dispose() {
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
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthRegistrationSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng ký thành công, tài khoản đang chờ duyệt'),
            ),
          );
          GoRouter.maybeOf(context)?.go('/login');
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
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const AuthBrandHeader(compact: true),
                    const SizedBox(height: 24),
                    AuthCard(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Đăng ký đại lý',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: const Color(0xFF052449),
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tạo hồ sơ giao dịch cho cửa hàng hải sản',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(color: const Color(0xFF4A5160)),
                            ),
                            const SizedBox(height: 28),
                            TextFormField(
                              key: const Key('registerFullNameField'),
                              controller: _fullNameController,
                              decoration: const InputDecoration(
                                labelText: 'Họ tên',
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                              textInputAction: TextInputAction.next,
                              validator: (value) => Validators.required(
                                value,
                                fieldName: 'Họ tên',
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              key: const Key('registerEmailField'),
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              textInputAction: TextInputAction.next,
                              validator: Validators.email,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              key: const Key('registerPhoneField'),
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Số điện thoại',
                                prefixIcon: Icon(Icons.phone_outlined),
                              ),
                              textInputAction: TextInputAction.next,
                              validator: Validators.phone,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              key: const Key('registerPasswordField'),
                              controller: _passwordController,
                              decoration: const InputDecoration(
                                labelText: 'Mật khẩu',
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                              obscureText: true,
                              textInputAction: TextInputAction.next,
                              validator: Validators.password,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              key: const Key('registerConfirmPasswordField'),
                              controller: _confirmPasswordController,
                              decoration: const InputDecoration(
                                labelText: 'Nhập lại mật khẩu',
                                prefixIcon: Icon(Icons.verified_user_outlined),
                              ),
                              obscureText: true,
                              textInputAction: TextInputAction.next,
                              validator: (value) => Validators.confirmPassword(
                                value,
                                _passwordController.text,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              key: const Key('registerStoreNameField'),
                              controller: _storeNameController,
                              decoration: const InputDecoration(
                                labelText: 'Tên cửa hàng',
                                prefixIcon: Icon(Icons.storefront_outlined),
                              ),
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              key: const Key('registerBusinessAddressField'),
                              controller: _addressController,
                              decoration: const InputDecoration(
                                labelText: 'Địa chỉ kinh doanh',
                                prefixIcon: Icon(Icons.location_on_outlined),
                              ),
                              textInputAction: TextInputAction.next,
                              validator: Validators.address,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              key: const Key('registerTaxCodeField'),
                              controller: _taxCodeController,
                              decoration: const InputDecoration(
                                labelText: 'Mã số thuế',
                                prefixIcon: Icon(Icons.receipt_long_outlined),
                              ),
                              textInputAction: TextInputAction.done,
                              validator: Validators.taxCode,
                            ),
                            const SizedBox(height: 24),
                            BlocBuilder<AuthBloc, AuthState>(
                              builder: (context, state) {
                                final isLoading = state is AuthLoading;
                                return FilledButton.icon(
                                  key: const Key('registerSubmitButton'),
                                  onPressed: isLoading ? null : _submit,
                                  icon: isLoading
                                      ? const SizedBox.square(
                                          dimension: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.person_add_alt_1),
                                  label: const Text('Đăng ký'),
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
                          'Đã có tài khoản?',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: const Color(0xFF303642)),
                        ),
                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: const Text('Đăng nhập'),
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

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
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
}
