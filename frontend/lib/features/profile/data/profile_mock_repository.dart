import '../../../core/api/api_response.dart';
import '../../auth/domain/auth_repository.dart';
import '../domain/profile.dart';
import '../domain/profile_repository.dart';

class ProfileMockRepository implements ProfileRepository {
  final AuthRepository _authRepository;

  ProfileMockRepository(this._authRepository);

  static const _dealerFallback = Profile(
    id: 'user-001',
    fullName: 'Đại lý Hải Sản Cà Mau',
    email: 'daily-camau@marinelink.vn',
    phone: '0912345678',
    status: 'ACTIVE',
    roles: ['USER'],
    businessAddress: '123 Đường Hải Sản, TP. Cà Mau',
    storeName: 'Hải Sản Cà Mau Store',
    avatarUrl: 'https://example.com/avatar.png',
  );

  Profile? _updatedProfile;

  @override
  Future<ApiResponse<Profile>> getProfile() async {
    await Future.delayed(const Duration(milliseconds: 400));

    if (_updatedProfile != null) {
      return ApiResponse(success: true, message: 'OK', data: _updatedProfile);
    }

    final currentUser = await _authRepository.getCurrentUser();
    if (currentUser != null) {
      return ApiResponse(
        success: true,
        message: 'OK',
        data: Profile.fromUser(currentUser),
      );
    }

    return ApiResponse(success: true, message: 'OK', data: _dealerFallback);
  }

  @override
  Future<ApiResponse<Profile>> updateProfile({
    required String fullName,
    required String phone,
    String? businessAddress,
    String? avatarUrl,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final currentUser = await _authRepository.getCurrentUser();
    final base =
        _updatedProfile ??
        (currentUser == null ? null : Profile.fromUser(currentUser)) ??
        _dealerFallback;

    _updatedProfile = Profile(
      id: base.id,
      fullName: fullName,
      email: base.email,
      phone: phone,
      status: base.status,
      roles: base.roles,
      businessAddress: businessAddress,
      storeName: base.storeName,
      taxCode: base.taxCode,
      avatarUrl: avatarUrl,
    );
    return ApiResponse(
      success: true,
      message: 'Cập nhật thành công',
      data: _updatedProfile,
    );
  }
}
