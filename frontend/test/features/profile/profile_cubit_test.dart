import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/core/api/api_client.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/features/profile/domain/profile.dart';
import 'package:marinelink/features/profile/domain/profile_repository.dart';
import 'package:marinelink/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockProfileRepository repository;

  const tProfile = Profile(
    id: '1',
    fullName: 'Đại lý Test',
    email: 'test@example.com',
    phone: '0912345678',
    status: 'ACTIVE',
    roles: ['USER'],
    businessAddress: 'Cần Thơ',
    avatarUrl: 'https://example.com/avatar.png',
  );

  setUp(() {
    repository = MockProfileRepository();
  });

  group('ProfileCubit', () {
    blocTest<ProfileCubit, ProfileState>(
      'emits loading and success when loadProfile succeeds',
      build: () {
        when(() => repository.getProfile()).thenAnswer(
          (_) async =>
              const ApiResponse(success: true, message: 'OK', data: tProfile),
        );
        return ProfileCubit(profileRepository: repository);
      },
      act: (cubit) => cubit.loadProfile(),
      expect: () => [
        const ProfileState(status: ProfileStatus.loading),
        const ProfileState(status: ProfileStatus.success, profile: tProfile),
      ],
    );

    blocTest<ProfileCubit, ProfileState>(
      'emits failure with Vietnamese fallback when profile payload is empty',
      build: () {
        when(
          () => repository.getProfile(),
        ).thenAnswer((_) async => const ApiResponse(success: false));
        return ProfileCubit(profileRepository: repository);
      },
      act: (cubit) => cubit.loadProfile(),
      expect: () => [
        const ProfileState(status: ProfileStatus.loading),
        const ProfileState(
          status: ProfileStatus.failure,
          errorMessage: 'Không tải được hồ sơ.',
        ),
      ],
    );

    blocTest<ProfileCubit, ProfileState>(
      'emits updateSuccess and forwards avatarUrl when update succeeds',
      build: () {
        when(
          () => repository.updateProfile(
            fullName: any(named: 'fullName'),
            phone: any(named: 'phone'),
            businessAddress: any(named: 'businessAddress'),
            avatarUrl: any(named: 'avatarUrl'),
          ),
        ).thenAnswer(
          (_) async =>
              const ApiResponse(success: true, message: 'OK', data: tProfile),
        );
        return ProfileCubit(profileRepository: repository);
      },
      act: (cubit) => cubit.updateProfile(
        fullName: 'Đại lý Test',
        phone: '0912345678',
        businessAddress: 'Cần Thơ',
        avatarUrl: 'https://example.com/avatar.png',
      ),
      expect: () => [
        const ProfileState(status: ProfileStatus.updating),
        const ProfileState(
          status: ProfileStatus.updateSuccess,
          profile: tProfile,
        ),
      ],
      verify: (_) {
        verify(
          () => repository.updateProfile(
            fullName: 'Đại lý Test',
            phone: '0912345678',
            businessAddress: 'Cần Thơ',
            avatarUrl: 'https://example.com/avatar.png',
          ),
        ).called(1);
      },
    );

    blocTest<ProfileCubit, ProfileState>(
      'emits updateFailure when repository throws ApiException',
      build: () {
        when(
          () => repository.updateProfile(
            fullName: any(named: 'fullName'),
            phone: any(named: 'phone'),
            businessAddress: any(named: 'businessAddress'),
            avatarUrl: any(named: 'avatarUrl'),
          ),
        ).thenThrow(
          const ApiException(
            message: 'Số điện thoại đã tồn tại.',
            type: ApiExceptionType.validation,
            statusCode: 422,
          ),
        );
        return ProfileCubit(profileRepository: repository);
      },
      seed: () =>
          const ProfileState(status: ProfileStatus.success, profile: tProfile),
      act: (cubit) =>
          cubit.updateProfile(fullName: 'Đại lý Test', phone: '0912345678'),
      expect: () => [
        const ProfileState(status: ProfileStatus.updating, profile: tProfile),
        const ProfileState(
          status: ProfileStatus.updateFailure,
          profile: tProfile,
          errorMessage: 'Số điện thoại đã tồn tại.',
        ),
      ],
    );
  });
}
