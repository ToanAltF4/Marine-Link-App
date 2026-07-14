import 'package:marinelink/core/constants/app_strings.dart';
import '../domain/auth_repository.dart';
import '../domain/user.dart';

/// Mock AuthRepository for Sprint 1.
/// Returns hard-coded demo users matching the documented demo accounts.
///
/// Replace with AuthRemoteRepository in Sprint 5 via DI — no UI changes needed.
class AuthMockRepository implements AuthRepository {
  User? _currentUser;
  String? _currentToken;

  static const _demoAdmin = User(
    id: '550e8400-e29b-41d4-a716-446655440001',
    fullName: 'MarineLink Admin',
    email: 'admin@marinelink.demo',
    phone: '0900000000',
    status: 'ACTIVE',
    roles: ['ADMIN'],
  );

  static const _demoStaff = User(
    id: '550e8400-e29b-41d4-a716-446655440002',
    fullName: 'Nhân viên Demo',
    email: 'staff@marinelink.demo',
    phone: '0900000001',
    status: 'ACTIVE',
    roles: ['STAFF'],
  );

  static const _demoUser = User(
    id: '550e8400-e29b-41d4-a716-446655440003',
    fullName: 'Đại lý Nguyễn Văn A',
    email: 'daily-a@marinelink.demo',
    phone: '0912345678',
    status: 'ACTIVE',
    roles: ['USER'],
    storeName: 'Hải Sản A Cần Thơ',
    businessAddress: AppStrings.originCanTho,
    taxCode: '0312345678',
  );

  static const _demoPasswords = {
    'admin@marinelink.demo': 'Admin@123',
    '0900000000': 'Admin@123',
    'staff@marinelink.demo': 'Staff@123',
    '0900000001': 'Staff@123',
    'daily-a@marinelink.demo': 'Daily@123',
    '0912345678': 'Daily@123',
  };

  @override
  Future<({String token, User user})> login({
    required String emailOrPhone,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500)); // simulate latency

    final expectedPassword =
        _demoPasswords[emailOrPhone.toLowerCase()] ??
        _demoPasswords[emailOrPhone];

    if (expectedPassword == null || expectedPassword != password) {
      throw Exception(AppStrings.invalidCredentials);
    }

    final user = _userForCredential(emailOrPhone);
    final token = 'mock-jwt-token-${user.roles.first.toLowerCase()}';
    _currentUser = user;
    _currentToken = token;
    return (token: token, user: user);
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
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // Check for duplicates
    if (_demoPasswords.containsKey(email.toLowerCase())) {
      throw Exception(AppStrings.emailAlreadyUsedNoPeriod);
    }

    return User(
      id: 'mock-new-user-${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName,
      email: email,
      phone: phone,
      status: 'PENDING_APPROVAL',
      roles: const ['USER'],
      storeName: storeName,
      businessAddress: businessAddress,
      taxCode: taxCode,
    );
  }

  @override
  Future<bool> isEmailAvailable({required String email}) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return !_demoPasswords.containsKey(email.toLowerCase());
  }

  @override
  Future<bool> isPhoneAvailable({required String phone, String? email}) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return !_demoPasswords.containsKey(phone.trim());
  }

  @override
  Future<({String token, User user})> loginWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 500));
    const user = User(
      id: '550e8400-e29b-41d4-a716-4466554400a0',
      fullName: 'Google Demo User',
      email: 'google-demo@gmail.com',
      phone: '',
      status: 'ACTIVE',
      roles: ['USER'],
    );
    const token = 'mock-jwt-token-google';
    _currentUser = user;
    _currentToken = token;
    return (token: token, user: user);
  }

  @override
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _currentUser = null;
    _currentToken = null;
  }

  @override
  Future<void> verifyEmail({
    required String email,
    required String otpCode,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Mock: accept any 6-digit code
    if (otpCode.length != 6) {
      throw Exception(AppStrings.otpInvalidAlt);
    }
  }

  @override
  Future<void> resendOtp({required String email}) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    // Backend always returns 204 to avoid email enumeration — mock mirrors that.
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // Mock: treat "000000" as an invalid/expired OTP to exercise the error path.
    if (otpCode == '000000') {
      throw Exception(AppStrings.otpInvalidOrUsed);
    }
  }

  @override
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    if (oldPassword == 'wrong') {
      throw Exception(AppStrings.currentPasswordIncorrect);
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    if (_currentToken == null) return null;
    return _currentUser;
  }

  User _userForCredential(String emailOrPhone) {
    final key = emailOrPhone.toLowerCase();
    if (key.contains('admin') || key == '0900000000') return _demoAdmin;
    if (key.contains('staff') || key == '0900000001') return _demoStaff;
    return _demoUser;
  }
}
