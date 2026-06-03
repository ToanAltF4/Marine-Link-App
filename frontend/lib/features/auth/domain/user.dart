import 'package:equatable/equatable.dart';

/// Domain entity for User.
/// Only contains fields needed by the presentation layer.
/// No JSON serialization here — that lives in data/user_dto.dart.
class User extends Equatable {
  final String id; // public UUID
  final String fullName;
  final String email;
  final String phone;
  final String status; // PENDING_APPROVAL | ACTIVE | DISABLED
  final List<String> roles; // ['USER'] | ['STAFF'] | ['ADMIN']
  final String? storeName;
  final String? businessAddress;
  final String? taxCode;
  final String? avatarUrl;

  const User({
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

  bool get isAdmin => roles.contains('ADMIN');
  bool get isStaff => roles.contains('STAFF');
  bool get isUser => roles.contains('USER');
  bool get isActive => status == 'ACTIVE';

  @override
  List<Object?> get props => [id, fullName, email, phone, status, roles];
}
