package com.marinelink.chat;

import java.time.Instant;
import java.util.Comparator;
import java.util.List;
import java.util.UUID;

public record ChatMessageResponse(
        UUID id,
        UUID roomId,
        ChatSenderType senderType,
        String content,
        Instant createdAt,
        List<ChatAttachmentResponse> attachments
) {
    static ChatMessageResponse from(ChatMessage message) {
        List<ChatAttachmentResponse> attachments = message.getAttachments()
                .stream()
                .sorted(Comparator.comparing(ChatAttachment::getCreatedAt,
                        Comparator.nullsLast(Comparator.naturalOrder())))
                .map(ChatAttachmentResponse::from)
                .toList();

        return new ChatMessageResponse(
                message.getPublicId(),
                message.getRoom().getPublicId(),
                message.getSenderType(),
                message.getContent(),
                message.getCreatedAt(),
                attachments);
    }
}
