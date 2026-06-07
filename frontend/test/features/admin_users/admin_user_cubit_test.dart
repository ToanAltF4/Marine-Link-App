import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/features/admin_users/domain/admin_user.dart';
import 'package:marinelink/features/admin_users/domain/admin_user_repository.dart';
import 'package:marinelink/features/admin_users/presentation/cubit/admin_user_cubit.dart';

class _FakeRepo implements AdminUserRepository {
  final Future<ApiResponse<List<AdminUser>>> Function() listResponder;
  final Future<ApiResponse<AdminUser>> Function(String id) approveResponder;

  _FakeRepo({
    required this.listResponder,
    Future<ApiResponse<AdminUser>> Function(String id)? approveResponder,
  }) : approveResponder =
           approveResponder ??
           ((_) async =>
               const ApiResponse(success: false, message: 'Không duyệt được'));

  @override
  Future<ApiResponse<List<AdminUser>>> getUsers() => listResponder();

  @override
  Future<ApiResponse<AdminUser>> approveUser(String id) => approveResponder(id);
}

const _pendingUser = AdminUser(
  id: 'pending-001',
  fullName: 'Đại lý mới',
  email: 'new@marinelink.demo',
  phone: '0911111111',
  role: AdminUserRole.user,
  status: AdminUserStatus.pendingApproval,
);

const _activeUser = AdminUser(
  id: 'pending-001',
  fullName: 'Đại lý mới',
  email: 'new@marinelink.demo',
  phone: '0911111111',
  role: AdminUserRole.user,
  status: AdminUserStatus.active,
);

void main() {
  blocTest<AdminUserCubit, AdminUserState>(
    'emits [loading, success] when repository returns users',
    build: () => AdminUserCubit(
      repository: _FakeRepo(
        listResponder: () async => const ApiResponse(
          success: true,
          message: 'OK',
          data: [_pendingUser],
        ),
      ),
    ),
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<AdminUserState>().having(
        (state) => state.status,
        'status',
        AdminUserStatusView.loading,
      ),
      isA<AdminUserState>()
          .having(
            (state) => state.status,
            'status',
            AdminUserStatusView.success,
          )
          .having((state) => state.users, 'users', const [_pendingUser]),
    ],
  );

  blocTest<AdminUserCubit, AdminUserState>(
    'emits [loading, empty] when repository returns an empty list',
    build: () => AdminUserCubit(
      repository: _FakeRepo(
        listResponder: () async =>
            const ApiResponse(success: true, message: 'OK', data: []),
      ),
    ),
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<AdminUserState>().having(
        (state) => state.status,
        'status',
        AdminUserStatusView.loading,
      ),
      isA<AdminUserState>().having(
        (state) => state.status,
        'status',
        AdminUserStatusView.empty,
      ),
    ],
  );

  blocTest<AdminUserCubit, AdminUserState>(
    'emits [loading, failure] when repository reports failure',
    build: () => AdminUserCubit(
      repository: _FakeRepo(
        listResponder: () async =>
            const ApiResponse(success: false, message: 'Server lỗi'),
      ),
    ),
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<AdminUserState>().having(
        (state) => state.status,
        'status',
        AdminUserStatusView.loading,
      ),
      isA<AdminUserState>()
          .having(
            (state) => state.status,
            'status',
            AdminUserStatusView.failure,
          )
          .having((state) => state.errorMessage, 'errorMessage', 'Server lỗi'),
    ],
  );

  blocTest<AdminUserCubit, AdminUserState>(
    'emits [loading, failure] when repository throws',
    build: () => AdminUserCubit(
      repository: _FakeRepo(listResponder: () async => throw Exception('boom')),
    ),
    act: (cubit) => cubit.load(),
    expect: () => [
      isA<AdminUserState>().having(
        (state) => state.status,
        'status',
        AdminUserStatusView.loading,
      ),
      isA<AdminUserState>().having(
        (state) => state.status,
        'status',
        AdminUserStatusView.failure,
      ),
    ],
  );

  blocTest<AdminUserCubit, AdminUserState>(
    'approveUser updates the selected pending account',
    seed: () => const AdminUserState(
      status: AdminUserStatusView.success,
      users: [_pendingUser],
    ),
    build: () => AdminUserCubit(
      repository: _FakeRepo(
        listResponder: () async => const ApiResponse(
          success: true,
          message: 'OK',
          data: [_pendingUser],
        ),
        approveResponder: (_) async =>
            const ApiResponse(success: true, message: 'OK', data: _activeUser),
      ),
    ),
    act: (cubit) => cubit.approveUser('pending-001'),
    expect: () => [
      isA<AdminUserState>().having(
        (state) => state.approvingUserId,
        'approvingUserId',
        'pending-001',
      ),
      isA<AdminUserState>()
          .having(
            (state) => state.status,
            'status',
            AdminUserStatusView.success,
          )
          .having(
            (state) => state.users.single.status,
            'status',
            AdminUserStatus.active,
          )
          .having((state) => state.approvingUserId, 'approvingUserId', isNull),
    ],
  );
}
