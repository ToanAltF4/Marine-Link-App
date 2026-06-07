import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_response.dart';
import '../../auth/data/auth_dto.dart';
import '../../auth/domain/user.dart';
import '../domain/profile_repository.dart';

class ProfileRemoteRepository implements ProfileRepository {
  final ApiClient apiClient;

  ProfileRemoteRepository({required this.apiClient});

  @override
  Future<ApiResponse<User>> getProfile() async {
    return await apiClient.get<User>(
      ApiEndpoints.me,
      fromJson: (json) => UserDto.fromJson(json).toDomain(),
    );
  }

  @override
  Future<ApiResponse<User>> updateProfile({
    required String fullName,
    required String phone,
    String? businessAddress,
  }) async {
    return await apiClient.put<User>(
      ApiEndpoints.me,
      data: {
        'fullName': fullName,
        'phone': phone,
        'businessAddress': businessAddress,
      },
      fromJson: (json) => UserDto.fromJson(json).toDomain(),
    );
  }
}
