import 'package:google_sign_in/google_sign_in.dart';
import 'package:marinelink/core/constants/app_strings.dart';

import '../domain/auth_exceptions.dart';

/// Obtains a Google ID token to exchange with the MarineLink backend.
///
/// The plugin dependency is isolated here so the rest of the auth feature
/// (bloc, repository, tests) does not import `google_sign_in` directly.
abstract class GoogleAuthService {
  /// Launches the Google account picker and returns a Google ID token.
  /// Throws [GoogleSignInCancelled] if the user cancels.
  Future<String> signInAndGetIdToken();

  Future<void> signOut();
}

class GoogleSignInAuthService implements GoogleAuthService {
  GoogleSignInAuthService({GoogleSignIn? googleSignIn})
    : _googleSignIn =
          googleSignIn ??
          GoogleSignIn(
            scopes: const ['email', 'profile'],
            // serverClientId = the Google Cloud "Web application" OAuth client ID.
            // Passed via --dart-define=GOOGLE_SERVER_CLIENT_ID=... so the issued
            // ID token's audience matches the backend's GOOGLE_CLIENT_IDS.
            serverClientId: _serverClientId.isEmpty ? null : _serverClientId,
          );

  static const String _serverClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );

  final GoogleSignIn _googleSignIn;

  @override
  Future<String> signInAndGetIdToken() async {
    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw const GoogleSignInCancelled();
    }
    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception(AppStrings.googleIdTokenMissing);
    }
    return idToken;
  }

  @override
  Future<void> signOut() => _googleSignIn.signOut();
}
