package com.marinelink.auth;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

/** Yêu cầu gửi OTP đặt lại mật khẩu tới email tài khoản. */
public record ForgotPasswordRequest(
        @NotBlank(message = "Email không được để trống")
        @Email(message = "Email không hợp lệ")
        String email
) {
}
