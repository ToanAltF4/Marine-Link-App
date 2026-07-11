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
  final String? taxCode;
  final String? storeName;
  final String? businessAddress;
  final String? avatarUrl;

  const AdminUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.role,
    required this.status,
    this.taxCode,
    this.storeName,
    this.businessAddress,
    this.avatarUrl,
  });

  AdminUser copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    AdminUserRole? role,
    AdminUserStatus? status,
    String? taxCode,
    String? storeName,
    String? businessAddress,
    String? avatarUrl,
  }) {
    return AdminUser(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      status: status ?? this.status,
      taxCode: taxCode ?? this.taxCode,
      storeName: storeName ?? this.storeName,
      businessAddress: businessAddress ?? this.businessAddress,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  List<Object?> get props => [
    id,
    fullName,
    email,
    phone,
    role,
    status,
    taxCode,
    storeName,
    businessAddress,
    avatarUrl,
  ];
}
