import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/storage/secure_token_storage.dart';
import '../domain/auth_repository.dart';
import '../domain/user.dart';
import 'auth_dto.dart';
import 'google_sign_in_service.dart';

class AuthRemoteRepository implements AuthRepository {
  final ApiClient apiClient;
  final SecureTokenStorage tokenStorage;
  final GoogleAuthService googleAuthService;

  const AuthRemoteRepository({
    required this.apiClient,
    required this.tokenStorage,
    required this.googleAuthService,
  });

  @override
  Future<({String token, User user})> login({
    required String emailOrPhone,
    required String password,
  }) async {
    final response = await apiClient.post<LoginResponseDto>(
      ApiEndpoints.login,
      data: {'emailOrPhone': emailOrPhone, 'password': password},
      fromJson: (json) =>
          LoginResponseDto.fromJson(json as Map<String, dynamic>),
    );

    if (!response.success || response.data == null) {
      throw ApiException(
        message: response.message ?? AppStrings.loginFailed,
        type: ApiExceptionType.unauthorized,
      );
    }

    final login = response.data!;
    final user = login.user.toDomain();
    await _persistSession(login.token, user);
    return (token: login.token, user: user);
  }

  @override
  Future<({String token, User user})> loginWithGoogle() async {
    final idToken = await googleAuthService.signInAndGetIdToken();

    final response = await apiClient.post<LoginResponseDto>(
      ApiEndpoints.googleLogin,
      data: {'idToken': idToken},
      fromJson: (json) =>
          LoginResponseDto.fromJson(json as Map<String, dynamic>),
    );

    if (!response.success || response.data == null) {
      throw ApiException(
        message: response.message ?? AppStrings.googleLoginFailed,
        type: ApiExceptionType.unauthorized,
      );
    }

    final login = response.data!;
    final user = login.user.toDomain();
    await _persistSession(login.token, user);
    return (token: login.token, user: user);
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
    final response = await apiClient.post<RegisterResponseDto>(
      ApiEndpoints.register,
      data: {
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'password': password,
        'storeName': ?storeName,
        'businessAddress': ?businessAddress,
        'taxCode': ?taxCode,
      },
      fromJson: (json) =>
          RegisterResponseDto.fromJson(json as Map<String, dynamic>),
    );

    if (!response.success || response.data == null) {
      throw ApiException(
        message: response.message ?? AppStrings.registerFailed,
        type: ApiExceptionType.validation,
      );
    }

    final created = response.data!;
    return User(
      id: created.id,
      fullName: fullName,
      email: email,
      phone: phone,
      status: created.status,
      roles: created.roles,
      storeName: storeName,
      businessAddress: businessAddress,
      taxCode: taxCode,
    );
  }

  @override
  Future<bool> isEmailAvailable({required String email}) async {
    final response = await apiClient.get<bool>(
      ApiEndpoints.emailAvailability,
      queryParameters: {'email': email},
      fromJson: (json) {
        final map = json as Map<String, dynamic>;
        return map['available'] as bool? ?? false;
      },
    );

    if (!response.success || response.data == null) {
      throw ApiException(
        message: response.message ?? AppStrings.emailCheckFailed,
        type: ApiExceptionType.validation,
      );
    }

    return response.data!;
  }

  @override
  Future<bool> isPhoneAvailable({required String phone, String? email}) async {
    final response = await apiClient.get<bool>(
      ApiEndpoints.phoneAvailability,
      queryParameters: {
        'phone': phone,
        if (email != null && email.trim().isNotEmpty) 'email': email,
      },
      fromJson: (json) {
        final map = json as Map<String, dynamic>;
        return map['available'] as bool? ?? false;
      },
    );

    if (!response.success || response.data == null) {
      throw ApiException(
        message: response.message ?? AppStrings.phoneCheckFailed,
        type: ApiExceptionType.validation,
      );
    }

    return response.data!;
  }

  @override
  Future<void> logout() => tokenStorage.clearAll();

  @override
  Future<void> verifyEmail({
    required String email,
    required String otpCode,
  }) async {
    final response = await apiClient.post<void>(
      ApiEndpoints.verifyEmail,
      data: {'email': email, 'otpCode': otpCode},
      fromJson: (_) {},
    );

    if (!response.success) {
      throw ApiException(
        message: response.message ?? AppStrings.verifyEmailFailed,
        type: ApiExceptionType.validation,
      );
    }
  }

  @override
  Future<void> resendOtp({required String email}) async {
    final response = await apiClient.post<void>(
      ApiEndpoints.resendOtp,
      data: {'email': email},
      fromJson: (_) {},
    );

    if (!response.success) {
      throw ApiException(
        message: response.message ?? AppStrings.resendOtpFailed,
        type: ApiExceptionType.validation,
      );
    }
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    final response = await apiClient.post<void>(
      ApiEndpoints.authForgotPassword,
      data: {'email': email},
      fromJson: (_) {},
    );

    if (!response.success) {
      throw ApiException(
        message: response.message ?? AppStrings.forgotPasswordFailed,
        type: ApiExceptionType.validation,
      );
    }
  }

  @override
  Future<void> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  }) async {
    final response = await apiClient.post<void>(
      ApiEndpoints.authResetPassword,
      data: {
        'email': email,
        'otpCode': otpCode,
        'newPassword': newPassword,
      },
      fromJson: (_) {},
    );

    if (!response.success) {
      throw ApiException(
        message: response.message ?? AppStrings.resetPasswordFailed,
        type: ApiExceptionType.validation,
      );
    }
  }

  @override
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final response = await apiClient.post<void>(
      ApiEndpoints.changePassword,
      data: {'oldPassword': oldPassword, 'newPassword': newPassword},
      fromJson: (_) {},
    );

    if (!response.success) {
      throw ApiException(
        message: response.message ?? AppStrings.changePasswordFailed,
        type: ApiExceptionType.validation,
      );
    }
  }

  @override
  Future<User?> getCurrentUser() async {
    if (!await tokenStorage.hasToken()) {
      return null;
    }

    try {
      final response = await apiClient.get<User>(
        ApiEndpoints.me,
        fromJson: (json) =>
            UserDto.fromJson(json as Map<String, dynamic>).toDomain(),
      );
      if (!response.success || response.data == null) {
        await tokenStorage.clearAll();
        return null;
      }

      await _persistSession(
        await tokenStorage.getToken() ?? '',
        response.data!,
      );
      return response.data!;
    } on ApiException catch (e) {
      if (e.type == ApiExceptionType.unauthorized ||
          e.type == ApiExceptionType.forbidden) {
        await tokenStorage.clearAll();
        return null;
      }
      rethrow;
    }
  }

  Future<void> _persistSession(String token, User user) async {
    if (token.isNotEmpty) {
      await tokenStorage.saveToken(token);
    }
    await tokenStorage.saveUserId(user.id);
    await tokenStorage.saveRoles(user.roles);
  }
}
