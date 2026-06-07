import 'package:equatable/equatable.dart';

enum AdminUserRole { admin, staff, user }

enum AdminUserStatus { pendingApproval, active, disabled }

class AdminUser extends Equatable {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final AdminUserRole role;
  final AdminUserStatus status;

  const AdminUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
  });

  AdminUser copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    AdminUserRole? role,
    AdminUserStatus? status,
  }) {
    return AdminUser(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [id, fullName, email, phone, role, status];
}
