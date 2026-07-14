package com.marinelink.auth.google;

/**
 * Verified identity extracted from a Google ID token.
 */
public record GoogleUserInfo(
        String sub,
        String email,
        boolean emailVerified,
        String name,
        String picture
) {
}
