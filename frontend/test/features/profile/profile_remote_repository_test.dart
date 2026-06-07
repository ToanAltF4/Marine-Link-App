import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:marinelink/core/api/api_client.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/features/profile/data/profile_remote_repository.dart';
import 'package:marinelink/features/auth/domain/user.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient mockApiClient;
  late ProfileRemoteRepository repository;

  setUp(() {
    mockApiClient = MockApiClient();
    repository = ProfileRemoteRepository(apiClient: mockApiClient);
  });

  group('ProfileRemoteRepository', () {
    final tUserJson = {
      'id': '550e8400-e29b-41d4-a716-446655440003',
      'fullName': 'Test User',
      'email': 'test@example.com',
      'phone': '0123456789',
      'status': 'ACTIVE',
      'roles': ['USER'],
      'businessAddress': 'Test Address',
    };

    test('getProfile returns user when successful', () async {
      when(() => mockApiClient.get<User>(
            any(),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((invocation) async {
        final fromJson = invocation.namedArguments[#fromJson] as User Function(dynamic);
        return ApiResponse(success: true, message: 'OK', data: fromJson(tUserJson));
      });

      final result = await repository.getProfile();

      expect(result.success, true);
      expect(result.data?.id, '550e8400-e29b-41d4-a716-446655440003');
      expect(result.data?.fullName, 'Test User');
    });

    test('updateProfile returns updated user', () async {
      final updatedJson = {...tUserJson, 'fullName': 'New Name'};
      when(() => mockApiClient.put<User>(
            any(),
            data: any(named: 'data'),
            fromJson: any(named: 'fromJson'),
          )).thenAnswer((invocation) async {
        final fromJson = invocation.namedArguments[#fromJson] as User Function(dynamic);
        return ApiResponse(success: true, message: 'OK', data: fromJson(updatedJson));
      });

      final result = await repository.updateProfile(
        fullName: 'New Name',
        phone: '0123456789',
      );

      expect(result.success, true);
      expect(result.data?.fullName, 'New Name');
      verify(() => mockApiClient.put<User>(
            '/api/users/me',
            data: any(named: 'data'),
            fromJson: any(named: 'fromJson'),
          )).called(1);
    });
  });
}
