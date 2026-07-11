import 'user.dart';

/// Abstract auth repository interface.
/// Mock implementation: AuthMockRepository (data/)
/// Remote implementation: AuthRemoteRepository (data/) — Sprint 5
abstract class AuthRepository {
  Future<({String token, User user})> login({
    required String emailOrPhone,
    required String password,
  });

  /// Sign in with Google: launches the Google picker, exchanges the resulting
  /// ID token with the backend, and returns the app session.
  Future<({String token, User user})> loginWithGoogle();

  Future<User> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    String? storeName,
    String? businessAddress,
    String? taxCode,
  });

  Future<bool> isEmailAvailable({required String email});

  Future<bool> isPhoneAvailable({required String phone, String? email});

  Future<void> verifyEmail({required String email, required String otpCode});

  Future<void> resendOtp({required String email});

  /// Request a password-reset OTP for [email]. The backend always responds 204
  /// regardless of whether the account exists (to avoid email enumeration).
  Future<void> forgotPassword({required String email});

  /// Complete a password reset using the OTP sent to [email].
  Future<void> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  });

  Future<void> logout();

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  });

  Future<User?> getCurrentUser();
}
