package com.marinelink.auth;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

/** Đặt lại mật khẩu bằng OTP đã gửi qua email. */
public record ResetPasswordRequest(
        @NotBlank(message = "Email không được để trống")
        @Email(message = "Email không hợp lệ")
        String email,

        @NotBlank(message = "Mã OTP không được để trống")
        @Size(min = 6, max = 6, message = "Mã OTP phải có đúng 6 chữ số")
        String otpCode,

        @NotBlank(message = "Mật khẩu mới không được để trống")
        @Size(min = 6, message = "Mật khẩu mới phải có ít nhất 6 ký tự")
        String newPassword
) {
}
