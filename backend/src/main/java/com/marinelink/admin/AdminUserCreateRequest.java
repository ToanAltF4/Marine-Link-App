package com.marinelink.admin;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/**
 * Admin tạo tài khoản (nhân viên/đại lý) trực tiếp.
 *
 * <p>Tài khoản do admin tạo được kích hoạt luôn (ACTIVE) — không phải chờ duyệt.
 */
public record AdminUserCreateRequest(
        @NotBlank(message = "Họ tên không được để trống")
        @Size(max = 120, message = "Họ tên tối đa 120 ký tự")
        String fullName,

        @NotBlank(message = "Email không được để trống")
        @Email(message = "Email không hợp lệ")
        String email,

        @NotBlank(message = "Số điện thoại không được để trống")
        @Pattern(regexp = "^(0|\\+84)[0-9]{9,10}$", message = "Số điện thoại không hợp lệ")
        String phone,

        @NotBlank(message = "Mật khẩu không được để trống")
        @Size(min = 6, message = "Mật khẩu phải có ít nhất 6 ký tự")
        String password,

        /** Mã vai trò: STAFF (mặc định) hoặc ADMIN / USER. */
        String roleCode
) {
}
