package com.marinelink.admin;

import com.marinelink.users.UserStatus;
import jakarta.validation.constraints.Size;

public record AdminUserUpdateRequest(
        UserStatus status,
        @Size(max = 120, message = "Họ tên tối đa 120 ký tự")
        String fullName,
        @Size(max = 20, message = "Số điện thoại tối đa 20 ký tự")
        String phone,
        @Size(max = 500, message = "Địa chỉ kinh doanh tối đa 500 ký tự")
        String businessAddress
) {
}
