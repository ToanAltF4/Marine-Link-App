import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/features/auth/domain/auth_repository.dart';
import 'package:marinelink/features/auth/domain/user.dart';
import 'package:marinelink/features/auth/presentation/cubit/auth_form_cubit.dart';

void main() {
  group('AuthFormCubit', () {
    blocTest<AuthFormCubit, AuthFormState>(
      'keeps untouched fields quiet and invalidates a dirty login email',
      build: AuthFormCubit.new,
      act: (cubit) => cubit.loginEmailOrPhoneChanged('bad-email'),
      expect: () => [
        isA<AuthFormState>()
            .having(
              (state) => state.loginEmailOrPhone.status,
              'loginEmailOrPhone.status',
              AuthFieldStatus.invalid,
            )
            .having(
              (state) => state.loginEmailOrPhone.visibleMessage,
              'visibleMessage',
              'Email không hợp lệ',
            )
            .having((state) => state.canSubmitLogin, 'canSubmitLogin', false),
      ],
    );

    blocTest<AuthFormCubit, AuthFormState>(
      'validates register password confirmation in realtime',
      build: AuthFormCubit.new,
      act: (cubit) {
        cubit.registerPasswordChanged('Daily@123');
        cubit.registerConfirmPasswordChanged('wrong');
        cubit.registerConfirmPasswordChanged('Daily@123');
      },
      expect: () => [
        isA<AuthFormState>().having(
          (state) => state.password.status,
          'password.status',
          AuthFieldStatus.valid,
        ),
        isA<AuthFormState>().having(
          (state) => state.confirmPassword.status,
          'confirmPassword.status',
          AuthFieldStatus.invalid,
        ),
        isA<AuthFormState>().having(
          (state) => state.confirmPassword.status,
          'confirmPassword.status',
          AuthFieldStatus.valid,
        ),
      ],
    );

    blocTest<AuthFormCubit, AuthFormState>(
      'debounces register email availability checks',
      build: () => AuthFormCubit(
        authRepository: _AvailabilityRepository(
          usedEmails: {'used@example.com'},
        ),
        emailDebounceDuration: const Duration(milliseconds: 10),
      ),
      act: (cubit) => cubit.registerEmailChanged('used@example.com'),
      wait: const Duration(milliseconds: 30),
      expect: () => [
        isA<AuthFormState>().having(
          (state) => state.email.status,
          'email.status',
          AuthFieldStatus.checking,
        ),
        isA<AuthFormState>()
            .having(
              (state) => state.email.status,
              'email.status',
              AuthFieldStatus.serverInvalid,
            )
            .having(
              (state) => state.email.visibleMessage,
              'visibleMessage',
              'Email đã được sử dụng.',
            )
            .having((state) => state.canSubmitRegister, 'canSubmit', false),
      ],
    );

    blocTest<AuthFormCubit, AuthFormState>(
      'debounces register phone availability checks',
      build: () => AuthFormCubit(
        authRepository: _AvailabilityRepository(usedPhones: {'0912345678'}),
        phoneDebounceDuration: const Duration(milliseconds: 10),
      ),
      act: (cubit) => cubit.registerPhoneChanged('0912345678'),
      wait: const Duration(milliseconds: 30),
      expect: () => [
        isA<AuthFormState>().having(
          (state) => state.phone.status,
          'phone.status',
          AuthFieldStatus.checking,
        ),
        isA<AuthFormState>()
            .having(
              (state) => state.phone.status,
              'phone.status',
              AuthFieldStatus.serverInvalid,
            )
            .having(
              (state) => state.phone.visibleMessage,
              'visibleMessage',
              'Số điện thoại đã được sử dụng.',
            )
            .having((state) => state.canSubmitRegister, 'canSubmit', false),
      ],
    );

    test(
      'enables register submit only when required fields are valid',
      () async {
        final cubit = AuthFormCubit(
          authRepository: _AvailabilityRepository(),
          emailDebounceDuration: const Duration(milliseconds: 10),
          phoneDebounceDuration: const Duration(milliseconds: 10),
        );
        addTearDown(cubit.close);

        cubit
          ..registerFullNameChanged('Nguyen Van B')
          ..registerEmailChanged('daily-b@marinelink.demo')
          ..registerPhoneChanged('0912345000')
          ..registerPasswordChanged('Daily@123')
          ..registerConfirmPasswordChanged('Daily@123')
          ..registerAddressChanged('123 Tran Hung Dao, Can Tho');

        await Future<void>.delayed(const Duration(milliseconds: 30));

        expect(cubit.state.canSubmitRegister, isTrue);
      },
    );
  });
}

class _AvailabilityRepository implements AuthRepository {
  final Set<String> usedEmails;
  final Set<String> usedPhones;

  _AvailabilityRepository({Set<String>? usedEmails, Set<String>? usedPhones})
    : usedEmails = usedEmails ?? const {},
      usedPhones = usedPhones ?? const {};

  @override
  Future<bool> isEmailAvailable({required String email}) async {
    return !usedEmails.contains(email.toLowerCase());
  }

  @override
  Future<bool> isPhoneAvailable({required String phone, String? email}) async {
    return !usedPhones.contains(phone.trim());
  }

  @override
  Future<({String token, User user})> login({
    required String emailOrPhone,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<({String token, User user})> loginWithGoogle() {
    throw UnimplementedError();
  }

  @override
  Future<User> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    String? storeName,
    String? businessAddress,
    String? taxCode,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> verifyEmail({required String email, required String otpCode}) {
    throw UnimplementedError();
  }

  @override
  Future<void> resendOtp({required String email}) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() {
    throw UnimplementedError();
  }

  @override
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<User?> getCurrentUser() {
    throw UnimplementedError();
  }
}
