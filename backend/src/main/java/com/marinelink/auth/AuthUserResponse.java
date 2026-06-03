package com.marinelink.auth;

import com.marinelink.users.User;

import java.util.List;
import java.util.UUID;

public record AuthUserResponse(
        UUID id,
        String fullName,
        String email,
        String phone,
        String status,
        List<String> roles,
        String storeName,
        String businessAddress,
        String taxCode,
        String avatarUrl
) {
    public static AuthUserResponse from(User user) {
        return new AuthUserResponse(
                user.getPublicId(),
                user.getFullName(),
                user.getEmail(),
                user.getPhone(),
                user.getStatus().name(),
                List.of(user.getRoleCode()),
                user.getStoreName(),
                user.getBusinessAddress(),
                user.getTaxCode(),
                user.getAvatarUrl());
    }
}
