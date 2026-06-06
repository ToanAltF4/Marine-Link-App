package com.marinelink.notifications;

import com.marinelink.notifications.dto.NotificationResponseDTO;
import com.marinelink.users.User;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.marinelink.common.exception.ResourceNotFoundException;

import java.time.Instant;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class NotificationService {

    private final NotificationRepository notificationRepository;

    public Page<NotificationResponseDTO> getNotifications(User user, Boolean isRead, Pageable pageable) {
        Page<Notification> page;
        if (isRead != null) {
            page = notificationRepository.findByUserAndReadOrderByCreatedAtDesc(user, isRead, pageable);
        } else {
            page = notificationRepository.findByUserOrderByCreatedAtDesc(user, pageable);
        }

        return page.map(this::toDTO);
    }

    @Transactional
    public void markAsRead(UUID publicId, User user) {
        Notification notification = notificationRepository.findByPublicId(publicId)
                .orElseThrow(() -> new ResourceNotFoundException("Notification not found"));

        if (!notification.getUser().getId().equals(user.getId())) {
            throw new SecurityException("Not authorized to read this notification");
        }

        if (!notification.isRead()) {
            notification.setRead(true);
            notification.setReadAt(Instant.now());
            notificationRepository.save(notification);
        }
    }

    private NotificationResponseDTO toDTO(Notification n) {
        return NotificationResponseDTO.builder()
                .id(n.getPublicId())
                .type(n.getType())
                .title(n.getTitle())
                .body(n.getBody())
                .relatedOrderId(n.getRelatedOrder() != null ? n.getRelatedOrder().getPublicId() : null)
                .relatedProductId(n.getRelatedProduct() != null ? n.getRelatedProduct().getPublicId() : null)
                .relatedChatRoomId(n.getRelatedChatRoomId()) // Bổ sung map trường này
                .read(n.isRead())
                .createdAt(n.getCreatedAt())
                .readAt(n.getReadAt())
                .build();
    }
}
