import '../../../core/api/api_response.dart';
import '../../auth/domain/user.dart';
import '../domain/profile_repository.dart';

class ProfileMockRepository implements ProfileRepository {
  User _mockUser = const User(
    id: 'user-001',
    fullName: 'Đại lý Hải Sản Cà Mau',
    email: 'daily-camau@marinelink.vn',
    phone: '0912345678',
    status: 'ACTIVE',
    roles: ['USER'],
    businessAddress: '123 Đường Hải Sản, TP. Cà Mau',
    storeName: 'Hải Sản Cam Mau Store',
  );

  @override
  Future<ApiResponse<User>> getProfile() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return ApiResponse(success: true, message: 'OK', data: _mockUser);
  }

  @override
  Future<ApiResponse<User>> updateProfile({
    required String fullName,
    required String phone,
    String? businessAddress,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    _mockUser = User(
      id: _mockUser.id,
      fullName: fullName,
      email: _mockUser.email,
      phone: phone,
      status: _mockUser.status,
      roles: _mockUser.roles,
      businessAddress: businessAddress,
      storeName: _mockUser.storeName,
      taxCode: _mockUser.taxCode,
      avatarUrl: _mockUser.avatarUrl,
    );
    return ApiResponse(success: true, message: 'Cập nhật thành công', data: _mockUser);
  }
}
