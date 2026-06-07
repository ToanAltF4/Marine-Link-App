package com.marinelink.chat;

import com.marinelink.complaints.Complaint;
import com.marinelink.complaints.ComplaintStatus;

import java.time.Instant;
import java.util.UUID;

public record StaffChatComplaintResponse(
        UUID id,
        UUID roomId,
        UUID messageId,
        String title,
        String description,
        ComplaintStatus status,
        Instant createdAt
) {
    static StaffChatComplaintResponse from(Complaint complaint) {
        return new StaffChatComplaintResponse(
                complaint.getPublicId(),
                complaint.getChatRoom() == null ? null : complaint.getChatRoom().getPublicId(),
                complaint.getChatMessage() == null ? null : complaint.getChatMessage().getPublicId(),
                complaint.getTitle(),
                complaint.getDescription(),
                complaint.getStatus(),
                complaint.getCreatedAt());
    }
}
