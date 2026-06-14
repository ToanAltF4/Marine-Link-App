package com.marinelink.auth.google;

/**
 * Verifies a Google ID token and returns the identity it asserts.
 *
 * <p>Implementations must reject tokens that are expired, tampered, or whose
 * audience ({@code aud}) is not one of the app's configured OAuth client IDs.
 */
public interface GoogleTokenVerifier {

    GoogleUserInfo verify(String idToken);
}
