import '../../../core/api/api_response.dart';
import '../../auth/domain/auth_repository.dart';
import '../../auth/domain/user.dart';
import '../domain/profile_repository.dart';

class ProfileMockRepository implements ProfileRepository {
  final AuthRepository _authRepository;

  ProfileMockRepository(this._authRepository);

  static const _dealerFallback = User(
    id: 'user-001',
    fullName: 'Đại lý Hải Sản Cà Mau',
    email: 'daily-camau@marinelink.vn',
    phone: '0912345678',
    status: 'ACTIVE',
    roles: ['USER'],
    businessAddress: '123 Đường Hải Sản, TP. Cà Mau',
    storeName: 'Hải Sản Cam Mau Store',
  );

  User? _updatedUser;

  @override
  Future<ApiResponse<User>> getProfile() async {
    await Future.delayed(const Duration(milliseconds: 500));

    if (_updatedUser != null) {
      return ApiResponse(success: true, message: 'OK', data: _updatedUser);
    }

    final currentUser = await _authRepository.getCurrentUser();
    if (currentUser != null) {
      return ApiResponse(success: true, message: 'OK', data: currentUser);
    }

    return ApiResponse(success: true, message: 'OK', data: _dealerFallback);
  }

  @override
  Future<ApiResponse<User>> updateProfile({
    required String fullName,
    required String phone,
    String? businessAddress,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    final base =
        _updatedUser ?? await _authRepository.getCurrentUser() ?? _dealerFallback;

    _updatedUser = User(
      id: base.id,
      fullName: fullName,
      email: base.email,
      phone: phone,
      status: base.status,
      roles: base.roles,
      businessAddress: businessAddress,
      storeName: base.storeName,
      taxCode: base.taxCode,
      avatarUrl: base.avatarUrl,
    );
    return ApiResponse(
        success: true, message: 'Cập nhật thành công', data: _updatedUser);
  }
}