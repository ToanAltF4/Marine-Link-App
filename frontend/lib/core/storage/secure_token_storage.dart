import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Secure storage for JWT token.
/// Uses platform keychain (Keystore on Android, Keychain on iOS).
/// Never stores plaintext password or secret.
class SecureTokenStorage {
  static const _tokenKey = 'marinelink_jwt';
  static const _userIdKey = 'marinelink_user_public_id';
  static const _rolesKey = 'marinelink_user_roles';

  final FlutterSecureStorage _storage;

  SecureTokenStorage()
    : _storage = const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );

  // ── Token ──────────────────────────────────────────────────────────────────

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<void> deleteToken() => _storage.delete(key: _tokenKey);

  // ── User public ID ────────────────────────────────────────────────────────

  Future<void> saveUserId(String publicId) =>
      _storage.write(key: _userIdKey, value: publicId);

  Future<String?> getUserId() => _storage.read(key: _userIdKey);

  // ── Roles ─────────────────────────────────────────────────────────────────

  /// Saves roles as comma-separated string, e.g. "ADMIN,USER".
  Future<void> saveRoles(List<String> roles) =>
      _storage.write(key: _rolesKey, value: roles.join(','));

  Future<List<String>> getRoles() async {
    final raw = await _storage.read(key: _rolesKey);
    if (raw == null || raw.isEmpty) return [];
    return raw.split(',');
  }

  // ── Clear all ──────────────────────────────────────────────────────────────

  /// Clears all auth data on logout.
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
