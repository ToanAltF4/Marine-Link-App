import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/core/api/api_client.dart';
import 'package:marinelink/core/api/api_endpoints.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/features/admin_users/data/admin_user_remote_repository.dart';
import 'package:marinelink/features/admin_users/domain/admin_user.dart';
import 'package:mocktail/mocktail.dart';

class _MockApiClient extends Mock implements ApiClient {}

const _user = AdminUser(
  id: 'user-001',
  fullName: 'Dai ly A',
  email: 'daily-a@marinelink.demo',
  phone: '0912345678',
  role: AdminUserRole.user,
  status: AdminUserStatus.active,
);

void main() {
  test('getUsers calls admin users endpoint', () async {
    final apiClient = _MockApiClient();
    when(
      () => apiClient.get<List<AdminUser>>(
        ApiEndpoints.adminUsers,
        fromJson: any(named: 'fromJson'),
      ),
    ).thenAnswer((_) async => const ApiResponse(success: true, data: [_user]));

    final repository = AdminUserRemoteRepository(apiClient: apiClient);

    final response = await repository.getUsers();

    expect(response.data, [_user]);
    verify(
      () => apiClient.get<List<AdminUser>>(
        ApiEndpoints.adminUsers,
        fromJson: any(named: 'fromJson'),
      ),
    ).called(1);
  });

  test(
    'approveUser updates status through admin user detail endpoint',
    () async {
      final apiClient = _MockApiClient();
      when(
        () => apiClient.put<AdminUser>(
          ApiEndpoints.adminUserDetail('user-001'),
          data: any(named: 'data'),
          fromJson: any(named: 'fromJson'),
        ),
      ).thenAnswer((_) async => const ApiResponse(success: true, data: _user));

      final repository = AdminUserRemoteRepository(apiClient: apiClient);

      final response = await repository.approveUser('user-001');

      expect(response.data, _user);
      final data =
          verify(
                () => apiClient.put<AdminUser>(
                  ApiEndpoints.adminUserDetail('user-001'),
                  data: captureAny(named: 'data'),
                  fromJson: any(named: 'fromJson'),
                ),
              ).captured.single
              as Map<String, dynamic>;
      expect(data, {'status': 'ACTIVE'});
    },
  );
}
