import '../../../core/api/api_response.dart';
import '../../auth/domain/user.dart';

abstract class ProfileRepository {
  Future<ApiResponse<User>> getProfile();
  Future<ApiResponse<User>> updateProfile({
    required String fullName,
    required String phone,
    String? businessAddress,
  });
}
