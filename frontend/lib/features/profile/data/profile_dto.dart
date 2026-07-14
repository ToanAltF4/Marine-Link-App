import '../domain/profile.dart';

Profile profileFromJson(dynamic json) {
  final map = json as Map<String, dynamic>;
  return Profile(
    id: _stringOrEmpty(map['id'] ?? map['publicId']),
    fullName: _stringOrEmpty(map['fullName']),
    email: _stringOrEmpty(map['email']),
    phone: _stringOrEmpty(map['phone']),
    status: _stringOrEmpty(map['status'], fallback: 'ACTIVE'),
    roles: _rolesFromJson(map['roles'] ?? map['role']),
    storeName: _optionalString(map['storeName']),
    businessAddress: _optionalString(map['businessAddress']),
    taxCode: _optionalString(map['taxCode']),
    avatarUrl: _optionalString(map['avatarUrl']),
  );
}

List<String> _rolesFromJson(dynamic value) {
  if (value is List) {
    return value.map((role) => role.toString()).toList();
  }
  if (value == null) return const [];
  return [value.toString()];
}

String _stringOrEmpty(dynamic value, {String fallback = ''}) {
  if (value == null) return fallback;
  if (value is num) {
    final parsed = _toNum(value);
    return parsed % 1 == 0 ? parsed.toInt().toString() : parsed.toString();
  }
  final text = value.toString();
  return text.isEmpty ? fallback : text;
}

String? _optionalString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

num _toNum(dynamic value) {
  if (value is num) return value;
  return num.tryParse('$value') ?? 0;
}
