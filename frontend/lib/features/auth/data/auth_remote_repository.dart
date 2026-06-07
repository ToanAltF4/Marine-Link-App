import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/storage/secure_token_storage.dart';
import '../domain/auth_repository.dart';
import '../domain/user.dart';
import 'auth_dto.dart';

class AuthRemoteRepository implements AuthRepository {
  final ApiClient apiClient;
  final SecureTokenStorage tokenStorage;

  const AuthRemoteRepository({
    required this.apiClient,
    required this.tokenStorage,
  });

  @override
  Future<({String token, User user})> login({
    required String emailOrPhone,
    required String password,
  }) async {
    final response = await apiClient.post<LoginResponseDto>(
      ApiEndpoints.login,
      data: {
        'emailOrPhone': emailOrPhone,
        'password': password,
      },
      fromJson: (json) =>
          LoginResponseDto.fromJson(json as Map<String, dynamic>),
    );

    if (!response.success || response.data == null) {
      throw ApiException(
        message: response.message ?? 'Dang nhap that bai',
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
        message: response.message ?? 'Dang ky that bai',
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
  Future<void> logout() => tokenStorage.clearAll();

  @override
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final response = await apiClient.post<void>(
      ApiEndpoints.changePassword,
      data: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      },
      fromJson: (_) {},
    );

    if (!response.success) {
      throw ApiException(
        message: response.message ?? 'Đổi mật khẩu thất bại',
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

      await _persistSession(await tokenStorage.getToken() ?? '', response.data!);
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
