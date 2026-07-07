package com.marinelink.notifications;

import com.marinelink.chat.ChatRoom;
import com.marinelink.chat.ChatRoomRepository;
import com.marinelink.common.exception.BusinessException;
import com.marinelink.common.exception.ResourceNotFoundException;
import com.marinelink.notifications.dto.BroadcastSummaryDTO;
import com.marinelink.notifications.dto.NotificationResponseDTO;
import com.marinelink.users.User;
import com.marinelink.users.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class NotificationServiceTest {

    @Mock
    private NotificationRepository notificationRepository;

    @Mock
    private ChatRoomRepository chatRoomRepository;

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private NotificationService notificationService;

    private User user;
    private UUID chatRoomPublicId;
    private Notification notification;

    @BeforeEach
    void setUp() {
        user = new User();
        user.setId(1L);
        chatRoomPublicId = UUID.randomUUID();

        notification = Notification.builder()
                .id(1L)
                .publicId(UUID.randomUUID())
                .user(user)
                .type(NotificationType.ORDER)
                .title("Test Title")
                .body("Test Body")
                .read(false)
                .relatedChatRoomId(101L)
                .build();
    }

    @Test
    void getNotifications_ShouldReturnPageOfDTOs() {
        Pageable pageable = PageRequest.of(0, 20);
        Page<Notification> page = new PageImpl<>(List.of(notification));
        
        when(notificationRepository.findByUserOrderByCreatedAtDesc(any(User.class), any(Pageable.class)))
                .thenReturn(page);
        when(chatRoomRepository.findById(101L)).thenReturn(Optional.of(ChatRoom.builder()
                .id(101L)
                .publicId(chatRoomPublicId)
                .build()));

        Page<NotificationResponseDTO> result = notificationService.getNotifications(user, null, pageable);

        assertThat(result.getContent()).hasSize(1);
        assertThat(result.getContent().get(0).getTitle()).isEqualTo("Test Title");
        assertThat(result.getContent().get(0).getRelatedChatRoomId()).isEqualTo(chatRoomPublicId);
        verify(notificationRepository).findByUserOrderByCreatedAtDesc(user, pageable);
    }

    @Test
    void markAsRead_ShouldUpdateStatus() {
        UUID publicId = notification.getPublicId();
        when(notificationRepository.findByPublicId(publicId)).thenReturn(Optional.of(notification));

        notificationService.markAsRead(publicId, user);

        assertThat(notification.isRead()).isTrue();
        assertThat(notification.getReadAt()).isNotNull();
        verify(notificationRepository).save(notification);
    }

    @Test
    void markAsRead_WhenNotificationBelongsToAnotherUser_ShouldThrowForbidden() {
        UUID publicId = notification.getPublicId();
        User otherUser = new User();
        otherUser.setId(2L);
        when(notificationRepository.findByPublicId(publicId)).thenReturn(Optional.of(notification));

        org.junit.jupiter.api.Assertions.assertThrows(
                BusinessException.class,
                () -> notificationService.markAsRead(publicId, otherUser)
        );
    }

    @Test
    void createNotification_ShouldSaveNewNotification() {
        notificationService.createNotification(
                user,
                NotificationType.ORDER,
                "New Title",
                "New Body",
                null
        );

        verify(notificationRepository).save(any(Notification.class));
    }

    @Test
    void createBroadcast_ShouldFanOutOneNotificationPerDealer() {
        User dealerA = new User();
        dealerA.setId(10L);
        User dealerB = new User();
        dealerB.setId(11L);
        when(userRepository.findActiveByRoleCode("USER")).thenReturn(List.of(dealerA, dealerB));
        UUID creator = UUID.randomUUID();

        BroadcastSummaryDTO summary = notificationService.createBroadcast(
                creator, new CreateBroadcastRequest("  Bảo trì  ", "  Hệ thống bảo trì  "));

        verify(notificationRepository, times(2)).save(any(Notification.class));
        assertThat(summary.title()).isEqualTo("Bảo trì");
        assertThat(summary.body()).isEqualTo("Hệ thống bảo trì");
        assertThat(summary.createdBy()).isEqualTo(creator);
        assertThat(summary.recipientCount()).isEqualTo(2);
    }

    @Test
    void createBroadcast_WhenNoDealers_ShouldThrow() {
        when(userRepository.findActiveByRoleCode("USER")).thenReturn(List.of());

        org.junit.jupiter.api.Assertions.assertThrows(
                BusinessException.class,
                () -> notificationService.createBroadcast(
                        UUID.randomUUID(), new CreateBroadcastRequest("T", "B"))
        );
        verify(notificationRepository, never()).save(any(Notification.class));
    }

    @Test
    void listBroadcasts_ShouldDelegateToRepository() {
        BroadcastSummaryDTO row = new BroadcastSummaryDTO(
                UUID.randomUUID(), "T", "B", UUID.randomUUID(), null, 3);
        when(notificationRepository.findBroadcastSummaries()).thenReturn(List.of(row));

        assertThat(notificationService.listBroadcasts()).containsExactly(row);
    }

    @Test
    void deleteBroadcast_WhenExists_ShouldDelete() {
        UUID broadcastId = UUID.randomUUID();
        when(notificationRepository.countByBroadcastId(broadcastId)).thenReturn(5L);

        notificationService.deleteBroadcast(broadcastId);

        verify(notificationRepository).deleteByBroadcastId(broadcastId);
    }

    @Test
    void deleteBroadcast_WhenMissing_ShouldThrowNotFound() {
        UUID broadcastId = UUID.randomUUID();
        when(notificationRepository.countByBroadcastId(broadcastId)).thenReturn(0L);

        org.junit.jupiter.api.Assertions.assertThrows(
                ResourceNotFoundException.class,
                () -> notificationService.deleteBroadcast(broadcastId)
        );
        verify(notificationRepository, never()).deleteByBroadcastId(any());
    }
}
