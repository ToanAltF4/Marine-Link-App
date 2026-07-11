import '../domain/admin_user.dart';

List<AdminUser> adminUsersFromJson(dynamic json) {
  final rawItems = switch (json) {
    {'items': final List<dynamic> items} => items,
    {'content': final List<dynamic> content} => content,
    {'users': final List<dynamic> users} => users,
    final List<dynamic> list => list,
    _ => const <dynamic>[],
  };

  return rawItems
      .whereType<Map<String, dynamic>>()
      .map(adminUserFromJson)
      .toList();
}

AdminUser adminUserFromJson(dynamic json) {
  final map = json as Map<String, dynamic>;
  return AdminUser(
    id: _idFromJson(map),
    fullName: _stringOrEmpty(map['fullName']),
    email: _stringOrEmpty(map['email']),
    phone: _stringOrEmpty(map['phone']),
    role: _roleFromJson(map['role'] ?? map['roleCode'] ?? map['roles']),
    status: _statusFromJson(map['status']),
    taxCode: _stringOrNull(map['taxCode']),
    storeName: _stringOrNull(map['storeName']),
    businessAddress: _stringOrNull(map['businessAddress']),
    avatarUrl: _stringOrNull(map['avatarUrl']),
  );
}

String? _stringOrNull(dynamic value) {
  if (value == null) return null;
  final text = _stringOrEmpty(value).trim();
  return text.isEmpty ? null : text;
}

String _idFromJson(Map<String, dynamic> map) {
  final raw = map['id'] ?? map['publicId'] ?? map['public_id'];
  if (raw == null) return '';
  if (raw is num) return _toInt(raw).toString();
  return raw.toString();
}

String _stringOrEmpty(dynamic value) {
  if (value == null) return '';
  if (value is num) {
    final parsed = _toNum(value);
    return parsed % 1 == 0 ? parsed.toInt().toString() : parsed.toString();
  }
  return value.toString();
}

AdminUserRole _roleFromJson(dynamic value) {
  final raw = value is List && value.isNotEmpty ? value.first : value;
  return switch (raw?.toString().toUpperCase()) {
    'ADMIN' => AdminUserRole.admin,
    'STAFF' => AdminUserRole.staff,
    _ => AdminUserRole.user,
  };
}

AdminUserStatus _statusFromJson(dynamic value) {
  return switch (value?.toString().toUpperCase()) {
    'ACTIVE' => AdminUserStatus.active,
    'DISABLED' => AdminUserStatus.disabled,
    _ => AdminUserStatus.pendingApproval,
  };
}

int _toInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

num _toNum(dynamic value) {
  if (value is num) return value;
  return num.tryParse('$value') ?? 0;
}
