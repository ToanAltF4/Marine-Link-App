package com.marinelink.admin;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public record AdminUserRoleUpdateRequest(
        @NotBlank(message = "Role không được để trống")
        @Pattern(regexp = "ADMIN|STAFF|USER", message = "Role không hợp lệ")
        String roleCode
) {
}
