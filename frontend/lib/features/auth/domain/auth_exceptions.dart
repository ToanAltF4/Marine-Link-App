/// Raised when the user dismisses the Google sign-in dialog. Treated as a
/// silent, non-error outcome (no failure message shown to the user).
class GoogleSignInCancelled implements Exception {
  const GoogleSignInCancelled();
}
