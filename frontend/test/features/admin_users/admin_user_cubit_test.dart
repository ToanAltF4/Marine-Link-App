import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marinelink/core/api/api_response.dart';
import 'package:marinelink/features/admin_users/domain/admin_user.dart';
import 'package:marinelink/features/admin_users/domain/admin_user_repository.dart';
import 'package:marinelink/features/admin_users/presentation/cubit/admin_user_cubit.dart';

class _FakeRepo implements AdminUserRepository {
  final Future<ApiResponse<List<AdminUser>>> Function() listResponder;
  final Future<ApiResponse<AdminUser>> Function(String id) approveResponder;
  final Future<ApiResponse<AdminUser>> Function(String roleCode)
  createResponder;

  _FakeRepo({
    required this.listResponder,
    Future<ApiResponse<AdminUser>> Function(String id)? approveResponder,
    Future<ApiResponse<AdminUser>> Function(String roleCode)? createResponder,
  }) : approveResponder =
           approveResponder ??
           ((_) async =>
               const ApiResponse(success: false, message: 'Không duyệt được')),
       createResponder =
           createResponder ??
           ((_) async =>
               const ApiResponse(success: false, message: 'Không tạo được'));

  @override
  Future<ApiResponse<List<AdminUser>>> getUsers() => listResponder();

  @override
  Future<ApiResponse<AdminUser>> approveUser(String id) => approveResponder(id);

  @override
  Future<ApiResponse<AdminUser>> lockUser(String id) => approveResponder(id);

  @override
  Future<ApiResponse<AdminUser>> unlockUser(String id) => approveResponder(id);

  @override
  Future<ApiResponse<AdminUser>> createUser({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    String roleCode = 'STAFF',
  }) => createResponder(roleCode);
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

const _createdStaff = AdminUser(
  id: 'staff-999',
  fullName: 'Nhân viên Mới',
  email: 'nhanvien@marinelink.demo',
  phone: '0987654321',
  role: AdminUserRole.staff,
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

  blocTest<AdminUserCubit, AdminUserState>(
    'createUser prepends the new account and clears the creating flag',
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
        createResponder: (roleCode) async {
          expect(roleCode, 'STAFF');
          return const ApiResponse(
            success: true,
            message: 'OK',
            data: _createdStaff,
          );
        },
      ),
    ),
    act: (cubit) => cubit.createUser(
      fullName: 'Nhân viên Mới',
      email: 'nhanvien@marinelink.demo',
      phone: '0987654321',
      password: 'matkhau123',
    ),
    expect: () => [
      isA<AdminUserState>().having(
        (state) => state.creatingUser,
        'creatingUser',
        isTrue,
      ),
      isA<AdminUserState>()
          .having(
            (state) => state.status,
            'status',
            AdminUserStatusView.success,
          )
          .having((state) => state.users.first, 'first user', _createdStaff)
          .having((state) => state.users.length, 'users', 2)
          .having((state) => state.creatingUser, 'creatingUser', isFalse),
    ],
  );

  blocTest<AdminUserCubit, AdminUserState>(
    'createUser keeps the list and exposes the backend message on failure',
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
        createResponder: (_) async =>
            const ApiResponse(success: false, message: 'Email đã tồn tại'),
      ),
    ),
    act: (cubit) => cubit.createUser(
      fullName: 'Nhân viên Mới',
      email: 'trung@marinelink.demo',
      phone: '0987654321',
      password: 'matkhau123',
    ),
    expect: () => [
      isA<AdminUserState>().having(
        (state) => state.creatingUser,
        'creatingUser',
        isTrue,
      ),
      isA<AdminUserState>()
          .having(
            (state) => state.status,
            'status',
            AdminUserStatusView.success,
          )
          .having((state) => state.users, 'users', const [_pendingUser])
          .having(
            (state) => state.errorMessage,
            'errorMessage',
            'Email đã tồn tại',
          )
          .having((state) => state.creatingUser, 'creatingUser', isFalse),
    ],
    verify: (cubit) => expect(cubit.state.creatingUser, isFalse),
  );
}
