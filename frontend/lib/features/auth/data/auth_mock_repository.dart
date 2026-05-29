import '../domain/auth_repository.dart';
import '../domain/user.dart';

/// Mock AuthRepository for Sprint 1.
/// Returns hard-coded demo users matching the seed data in migration 009.
///
/// Replace with AuthRemoteRepository in Sprint 5 via DI — no UI changes needed.
class AuthMockRepository implements AuthRepository {
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
    businessAddress: 'Cần Thơ',
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
      throw Exception('Email/số điện thoại hoặc mật khẩu không đúng');
    }

    final user = _userForCredential(emailOrPhone);
    return (
      token: 'mock-jwt-token-${user.roles.first.toLowerCase()}',
      user: user,
    );
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
      throw Exception('Email đã được sử dụng');
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
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<User?> getCurrentUser() async {
    // In mock mode, no persistent session — return null to show login
    return null;
  }

  User _userForCredential(String emailOrPhone) {
    final key = emailOrPhone.toLowerCase();
    if (key.contains('admin') || key == '0900000000') return _demoAdmin;
    if (key.contains('staff') || key == '0900000001') return _demoStaff;
    return _demoUser;
  }
}
