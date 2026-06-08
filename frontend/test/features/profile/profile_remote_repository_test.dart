import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/core/api/api_client.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/features/profile/data/profile_remote_repository.dart';
import 'package:marinelink/features/profile/domain/profile.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late ProfileRemoteRepository repository;

  final tProfileJson = {
    'id': '550e8400-e29b-41d4-a716-446655440003',
    'fullName': 'Test User',
    'email': 'test@example.com',
    'phone': '0123456789',
    'status': 'ACTIVE',
    'roles': ['USER'],
    'businessAddress': 'Test Address',
    'avatarUrl': 'https://example.com/avatar.png',
  };

  setUp(() {
    mockApiClient = MockApiClient();
    repository = ProfileRemoteRepository(apiClient: mockApiClient);
  });

  group('ProfileRemoteRepository', () {
    test('getProfile returns profile when successful', () async {
      when(
        () =>
            mockApiClient.get<Profile>(any(), fromJson: any(named: 'fromJson')),
      ).thenAnswer((invocation) async {
        final fromJson =
            invocation.namedArguments[#fromJson] as Profile Function(dynamic);
        return ApiResponse(
          success: true,
          message: 'OK',
          data: fromJson(tProfileJson),
        );
      });

      final result = await repository.getProfile();

      expect(result.success, true);
      expect(result.data?.id, '550e8400-e29b-41d4-a716-446655440003');
      expect(result.data?.fullName, 'Test User');
      expect(result.data?.avatarUrl, 'https://example.com/avatar.png');
    });

    test('updateProfile sends avatarUrl and returns updated profile', () async {
      final updatedJson = {...tProfileJson, 'fullName': 'New Name'};
      when(
        () => mockApiClient.put<Profile>(
          any(),
          data: any(named: 'data'),
          fromJson: any(named: 'fromJson'),
        ),
      ).thenAnswer((invocation) async {
        final fromJson =
            invocation.namedArguments[#fromJson] as Profile Function(dynamic);
        return ApiResponse(
          success: true,
          message: 'OK',
          data: fromJson(updatedJson),
        );
      });

      final result = await repository.updateProfile(
        fullName: 'New Name',
        phone: '0123456789',
        businessAddress: 'Test Address',
        avatarUrl: 'https://example.com/avatar.png',
      );

      expect(result.success, true);
      expect(result.data?.fullName, 'New Name');
      verify(
        () => mockApiClient.put<Profile>(
          '/api/users/me',
          data: {
            'fullName': 'New Name',
            'phone': '0123456789',
            'businessAddress': 'Test Address',
            'avatarUrl': 'https://example.com/avatar.png',
          },
          fromJson: any(named: 'fromJson'),
        ),
      ).called(1);
    });
  });
}
