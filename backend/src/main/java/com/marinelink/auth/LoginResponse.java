package com.marinelink.auth;

public record LoginResponse(
        String token,
        String tokenType,
        long expiresIn,
        AuthUserResponse user
) {
}
