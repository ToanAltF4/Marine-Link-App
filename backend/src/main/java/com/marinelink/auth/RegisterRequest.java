package com.marinelink.auth;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record RegisterRequest(
        @NotBlank(message = "Họ tên không được để trống")
        String fullName,

        @NotBlank(message = "Email không được để trống")
        @Email(message = "Email không hợp lệ")
        String email,

        @NotBlank(message = "Số điện thoại không được để trống")
        @Pattern(regexp = "^(0|\\+84)[0-9]{9,10}$", message = "Số điện thoại không hợp lệ")
        String phone,

        @NotBlank(message = "Mật khẩu không được để trống")
        @Size(min = 8, message = "Mật khẩu phải có ít nhất 8 ký tự")
        String password,

        String storeName,
        String businessAddress,

        @Pattern(regexp = "^$|^\\d{10}(-\\d{3})?$", message = "Mã số thuế không hợp lệ")
        String taxCode
) {
}
