package com.marinelink.chat;

import java.util.UUID;

public record ChatAttachmentResponse(
        UUID id,
        String storageBucket,
        String storagePath,
        String fileName,
        String mimeType,
        Long fileSizeBytes
) {
    static ChatAttachmentResponse from(ChatAttachment attachment) {
        return new ChatAttachmentResponse(
                attachment.getPublicId(),
                attachment.getStorageBucket(),
                attachment.getStoragePath(),
                attachment.getFileName(),
                attachment.getMimeType(),
                attachment.getFileSizeBytes());
    }
}
