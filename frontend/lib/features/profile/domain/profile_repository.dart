import '../../../core/api/api_response.dart';
import 'profile.dart';

abstract class ProfileRepository {
  Future<ApiResponse<Profile>> getProfile();
  Future<ApiResponse<Profile>> updateProfile({
    required String fullName,
    required String phone,
    String? businessAddress,
    String? avatarUrl,
  });
}
