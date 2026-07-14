package com.marinelink.auth;

import jakarta.validation.constraints.NotBlank;

public record GoogleLoginRequest(
        @NotBlank(message = "Google ID token không được để trống")
        String idToken
) {
}
