import 'package:equatable/equatable.dart';

import '../../auth/domain/user.dart';

class Profile extends Equatable {
  final String id;
  final String fullName;
  final String email;
  final String phone;
  final String status;
  final List<String> roles;
  final String? storeName;
  final String? businessAddress;
  final String? taxCode;
  final String? avatarUrl;

  const Profile({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.status,
    required this.roles,
    this.storeName,
    this.businessAddress,
    this.taxCode,
    this.avatarUrl,
  });

  factory Profile.fromUser(User user) {
    return Profile(
      id: user.id,
      fullName: user.fullName,
      email: user.email,
      phone: user.phone,
      status: user.status,
      roles: user.roles,
      storeName: user.storeName,
      businessAddress: user.businessAddress,
      taxCode: user.taxCode,
      avatarUrl: user.avatarUrl,
    );
  }

  bool get isAdmin => roles.contains('ADMIN');
  bool get isStaff => roles.contains('STAFF');
  bool get isUser => roles.contains('USER');
  bool get hasAvatar => avatarUrl != null && avatarUrl!.trim().isNotEmpty;

  @override
  List<Object?> get props => [
    id,
    fullName,
    email,
    phone,
    status,
    roles,
    storeName,
    businessAddress,
    taxCode,
    avatarUrl,
  ];
}
