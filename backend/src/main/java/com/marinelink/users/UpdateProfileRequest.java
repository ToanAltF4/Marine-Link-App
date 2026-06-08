package com.marinelink.users;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record UpdateProfileRequest(
    @NotBlank(message = "Họ tên không được để trống")
    @Size(max = 100, message = "Họ tên không quá 100 ký tự")
    String fullName,

    @NotBlank(message = "Số điện thoại không được để trống")
    @Pattern(regexp = "^(0|\\+84)(\\d{9,10})$", message = "Số điện thoại không hợp lệ")
    String phone,

    @Size(max = 255, message = "Địa chỉ không quá 255 ký tự")
    String businessAddress,

    @Size(max = 500, message = "Avatar URL không quá 500 ký tự")
    String avatarUrl
) {}
