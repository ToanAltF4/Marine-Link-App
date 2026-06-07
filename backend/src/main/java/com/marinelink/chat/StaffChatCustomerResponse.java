package com.marinelink.chat;

import com.marinelink.users.User;

import java.util.UUID;

public record StaffChatCustomerResponse(
        UUID id,
        String fullName,
        String email,
        String phone
) {
    static StaffChatCustomerResponse from(User user) {
        return new StaffChatCustomerResponse(
                user.getPublicId(),
                user.getFullName(),
                user.getEmail(),
                user.getPhone());
    }
}
