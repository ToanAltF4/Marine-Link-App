import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_response.dart';
import '../domain/profile.dart';
import '../domain/profile_repository.dart';
import 'profile_dto.dart';

class ProfileRemoteRepository implements ProfileRepository {
  final ApiClient apiClient;

  ProfileRemoteRepository({required this.apiClient});

  @override
  Future<ApiResponse<Profile>> getProfile() async {
    return await apiClient.get<Profile>(
      ApiEndpoints.me,
      fromJson: profileFromJson,
    );
  }

  @override
  Future<ApiResponse<Profile>> updateProfile({
    required String fullName,
    required String phone,
    String? businessAddress,
    String? avatarUrl,
  }) async {
    return await apiClient.put<Profile>(
      ApiEndpoints.me,
      data: {
        'fullName': fullName,
        'phone': phone,
        'businessAddress': businessAddress,
        'avatarUrl': avatarUrl,
      },
      fromJson: profileFromJson,
    );
  }
}
