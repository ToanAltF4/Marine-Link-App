package com.marinelink.notifications;

import com.marinelink.chat.ChatRoomRepository;
import com.marinelink.common.exception.BusinessException;
import com.marinelink.notifications.dto.BroadcastSummaryDTO;
import com.marinelink.notifications.dto.NotificationResponseDTO;
import com.marinelink.users.User;
import com.marinelink.users.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.marinelink.common.exception.ResourceNotFoundException;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class NotificationService {

    private final NotificationRepository notificationRepository;
    private final ChatRoomRepository chatRoomRepository;
    private final UserRepository userRepository;

    /**
     * Admin/staff broadcast: fan out one notification per active dealer, tagged
     * with a shared broadcast id + the creator, and return a summary.
     */
    @Transactional
    public BroadcastSummaryDTO createBroadcast(UUID creatorPublicId, CreateBroadcastRequest request) {
        String title = request.title().trim();
        String body = request.body().trim();
        List<User> recipients = userRepository.findActiveByRoleCode("USER");
        if (recipients.isEmpty()) {
            throw new BusinessException("Chưa có đại lý nào để gửi thông báo.", HttpStatus.UNPROCESSABLE_ENTITY);
        }
        UUID broadcastId = UUID.randomUUID();
        Instant now = Instant.now();
        for (User recipient : recipients) {
            notificationRepository.save(Notification.builder()
                    .publicId(UUID.randomUUID())
                    .user(recipient)
                    .type(NotificationType.SYSTEM)
                    .title(title)
                    .body(body)
                    .broadcastId(broadcastId)
                    .createdBy(creatorPublicId)
                    .read(false)
                    .build());
        }
        return new BroadcastSummaryDTO(broadcastId, title, body, creatorPublicId, now, recipients.size());
    }

    /** History of admin/staff broadcasts, most recent first. */
    public List<BroadcastSummaryDTO> listBroadcasts() {
        return notificationRepository.findBroadcastSummaries();
    }

    /** Delete a broadcast (all its fanned-out rows). */
    @Transactional
    public void deleteBroadcast(UUID broadcastId) {
        if (notificationRepository.countByBroadcastId(broadcastId) == 0) {
            throw new ResourceNotFoundException("Không tìm thấy thông báo");
        }
        notificationRepository.deleteByBroadcastId(broadcastId);
    }

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
            throw new BusinessException("Bạn không có quyền đọc thông báo này.", HttpStatus.FORBIDDEN);
        }

        if (!notification.isRead()) {
            notification.setRead(true);
            notification.setReadAt(Instant.now());
            notificationRepository.save(notification);
        }
    }

    @Transactional
    public void createNotification(
            User user,
            NotificationType type,
            String title,
            String body,
            Object relatedEntity
    ) {
        Notification.NotificationBuilder builder = Notification.builder()
                .publicId(UUID.randomUUID())
                .user(user)
                .type(type)
                .title(title)
                .body(body)
                .read(false);

        if (relatedEntity instanceof com.marinelink.orders.Order order) {
            builder.relatedOrder(order);
        } else if (relatedEntity instanceof com.marinelink.products.Product product) {
            builder.relatedProduct(product);
        } else if (relatedEntity instanceof Long chatRoomId) {
            builder.relatedChatRoomId(chatRoomId);
        }

        notificationRepository.save(builder.build());
    }

    private NotificationResponseDTO toDTO(Notification n) {
        return NotificationResponseDTO.builder()
                .id(n.getPublicId())
                .type(n.getType())
                .title(n.getTitle())
                .body(n.getBody())
                .relatedOrderId(n.getRelatedOrder() != null ? n.getRelatedOrder().getPublicId() : null)
                .relatedProductId(n.getRelatedProduct() != null ? n.getRelatedProduct().getPublicId() : null)
                .relatedChatRoomId(resolveChatRoomPublicId(n.getRelatedChatRoomId()))
                .read(n.isRead())
                .createdAt(n.getCreatedAt())
                .readAt(n.getReadAt())
                .build();
    }

    private UUID resolveChatRoomPublicId(Long chatRoomId) {
        if (chatRoomId == null) {
            return null;
        }
        return chatRoomRepository.findById(chatRoomId)
                .map(room -> room.getPublicId())
                .orElse(null);
    }
}
