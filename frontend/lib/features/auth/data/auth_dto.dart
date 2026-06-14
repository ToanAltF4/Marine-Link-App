import '../domain/user.dart';

class UserDto {
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

  const UserDto({
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

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as String,
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String,
      // Google sign-up accounts have no phone; the API omits null fields.
      phone: json['phone'] as String? ?? '',
      status: json['status'] as String? ?? 'ACTIVE',
      roles: (json['roles'] as List<dynamic>? ?? const [])
          .map((role) => role.toString())
          .toList(),
      storeName: json['storeName'] as String?,
      businessAddress: json['businessAddress'] as String?,
      taxCode: json['taxCode'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  User toDomain() => User(
    id: id,
    fullName: fullName,
    email: email,
    phone: phone,
    status: status,
    roles: roles,
    storeName: storeName,
    businessAddress: businessAddress,
    taxCode: taxCode,
    avatarUrl: avatarUrl,
  );
}

class LoginResponseDto {
  final String token;
  final String tokenType;
  final int expiresIn;
  final UserDto user;

  const LoginResponseDto({
    required this.token,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) {
    return LoginResponseDto(
      token: json['token'] as String,
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      expiresIn: json['expiresIn'] as int? ?? 0,
      user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class RegisterResponseDto {
  final String id;
  final String status;
  final List<String> roles;

  const RegisterResponseDto({
    required this.id,
    required this.status,
    required this.roles,
  });

  factory RegisterResponseDto.fromJson(Map<String, dynamic> json) {
    return RegisterResponseDto(
      id: json['id'] as String,
      status: json['status'] as String? ?? 'PENDING_APPROVAL',
      roles: (json['roles'] as List<dynamic>? ?? const [])
          .map((role) => role.toString())
          .toList(),
    );
  }
}
