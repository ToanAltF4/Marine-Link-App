package com.marinelink.admin;

import com.marinelink.users.User;

import java.util.List;
import java.util.UUID;

public record AdminUserResponse(
        UUID id,
        UUID publicId,
        String fullName,
        String email,
        String phone,
        String role,
        String status,
        List<String> roles,
        String storeName,
        String businessAddress,
        String taxCode,
        String avatarUrl
) {
    public static AdminUserResponse from(User user) {
        String roleCode = user.getRoleCode();
        return new AdminUserResponse(
                user.getPublicId(),
                user.getPublicId(),
                user.getFullName(),
                user.getEmail(),
                user.getPhone(),
                roleCode,
                user.getStatus().name(),
                roleCode == null ? List.of() : List.of(roleCode),
                user.getStoreName(),
                user.getBusinessAddress(),
                user.getTaxCode(),
                user.getAvatarUrl());
    }
}
