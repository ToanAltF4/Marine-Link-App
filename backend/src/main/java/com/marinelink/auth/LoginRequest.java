package com.marinelink.auth;

import jakarta.validation.constraints.NotBlank;

public record LoginRequest(
        @NotBlank(message = "Email hoặc số điện thoại không được để trống")
        String emailOrPhone,

        @NotBlank(message = "Mật khẩu không được để trống")
        String password
) {
}
