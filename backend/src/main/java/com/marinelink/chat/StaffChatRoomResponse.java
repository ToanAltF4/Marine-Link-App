package com.marinelink.chat;

import java.time.Instant;
import java.util.UUID;

public record StaffChatRoomResponse(
        UUID roomId,
        StaffChatCustomerResponse customer,
        StaffChatAssigneeResponse assignedStaff,
        boolean isClosed,
        Instant lastMessageAt,
        Instant createdAt,
        Instant updatedAt,
        long messageCount,
        ChatMessageResponse lastMessage,
        StaffChatContextResponse context,
        String summary
) {
    static StaffChatRoomResponse from(
            ChatRoom room,
            ChatMessage lastMessage,
            long messageCount,
            String summary) {
        return new StaffChatRoomResponse(
                room.getPublicId(),
                StaffChatCustomerResponse.from(room.getUser()),
                StaffChatAssigneeResponse.from(room.getAssignedStaff()),
                room.isClosed(),
                room.getLastMessageAt(),
                room.getCreatedAt(),
                room.getUpdatedAt(),
                messageCount,
                lastMessage == null ? null : ChatMessageResponse.from(lastMessage),
                StaffChatContextResponse.from(room),
                summary);
    }
}
