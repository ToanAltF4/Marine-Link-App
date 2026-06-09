import 'user.dart';

/// Abstract auth repository interface.
/// Mock implementation: AuthMockRepository (data/)
/// Remote implementation: AuthRemoteRepository (data/) — Sprint 5
abstract class AuthRepository {
  Future<({String token, User user})> login({
    required String emailOrPhone,
    required String password,
  });

  Future<User> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    String? storeName,
    String? businessAddress,
    String? taxCode,
  });

  Future<void> verifyEmail({
    required String email,
    required String otpCode,
  });

  Future<void> resendOtp({required String email});

  Future<void> logout();

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  });

  Future<User?> getCurrentUser();
}
