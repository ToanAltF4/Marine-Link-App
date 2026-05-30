package com.marinelink.auth;

import com.marinelink.users.User;

import java.util.List;
import java.util.UUID;

public record RegisterResponse(
        UUID id,
        String status,
        List<String> roles
) {
    static RegisterResponse from(User user) {
        return new RegisterResponse(
                user.getPublicId(),
                user.getStatus().name(),
                List.of(user.getRoleCode()));
    }
}
