package com.marinelink.notifications.dto;

import com.marinelink.notifications.NotificationType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.Instant;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class NotificationResponseDTO {
    private UUID id;
    private NotificationType type;
    private String title;
    private String body;
    private UUID relatedOrderId;
    private UUID relatedProductId;
    private boolean read;
    private Instant createdAt;
    private Instant readAt;
}
