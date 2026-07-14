package com.marinelink.chat;

import com.marinelink.users.User;

import java.util.UUID;

public record StaffChatAssigneeResponse(
        UUID id,
        String fullName
) {
    static StaffChatAssigneeResponse from(User user) {
        if (user == null) {
            return null;
        }
        return new StaffChatAssigneeResponse(user.getPublicId(), user.getFullName());
    }
}
