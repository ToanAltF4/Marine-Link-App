import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/features/auth/domain/user.dart';
import 'package:marinelink/features/profile/domain/profile_repository.dart';
import 'package:marinelink/features/profile/presentation/bloc/profile_cubit.dart';

class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  late MockProfileRepository repository;
  late ProfileCubit cubit;

  const tUser = User(
    id: '1',
    fullName: 'Test',
    email: 'test@example.com',
    phone: '0123',
    status: 'ACTIVE',
    roles: ['USER'],
  );

  setUp(() {
    repository = MockProfileRepository();
    cubit = ProfileCubit(profileRepository: repository);
  });

  tearDown(() {
    cubit.close();
  });

  group('ProfileCubit', () {
    blocTest<ProfileCubit, ProfileState>(
      'emits [loading, success] when loadProfile is successful',
      build: () {
        when(() => repository.getProfile()).thenAnswer(
          (_) async => const ApiResponse(success: true, message: 'OK', data: tUser),
        );
        return cubit;
      },
      act: (c) => c.loadProfile(),
      expect: () => [
        const ProfileState(status: ProfileStatus.loading),
        const ProfileState(status: ProfileStatus.success, user: tUser),
      ],
    );

    blocTest<ProfileCubit, ProfileState>(
      'emits [updating, updateSuccess] when updateProfile is successful',
      build: () {
        when(() => repository.updateProfile(
              fullName: any(named: 'fullName'),
              phone: any(named: 'phone'),
              businessAddress: any(named: 'businessAddress'),
            )).thenAnswer(
          (_) async => const ApiResponse(success: true, message: 'OK', data: tUser),
        );
        return cubit;
      },
      act: (c) => c.updateProfile(fullName: 'New', phone: '0123'),
      expect: () => [
        const ProfileState(status: ProfileStatus.updating),
        const ProfileState(status: ProfileStatus.updateSuccess, user: tUser),
      ],
    );
  });
}
