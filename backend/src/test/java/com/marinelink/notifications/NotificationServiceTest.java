package com.marinelink.notifications;

import com.marinelink.notifications.dto.NotificationResponseDTO;
import com.marinelink.users.User;
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

    @InjectMocks
    private NotificationService notificationService;

    private User user;
    private Notification notification;

    @BeforeEach
    void setUp() {
        user = new User();
        user.setId(1L);

        notification = Notification.builder()
                .id(1L)
                .publicId(UUID.randomUUID())
                .user(user)
                .type(NotificationType.ORDER)
                .title("Test Title")
                .body("Test Body")
                .read(false)
                .build();
    }

    @Test
    void getNotifications_ShouldReturnPageOfDTOs() {
        Pageable pageable = PageRequest.of(0, 20);
        Page<Notification> page = new PageImpl<>(List.of(notification));
        
        when(notificationRepository.findByUserOrderByCreatedAtDesc(any(User.class), any(Pageable.class)))
                .thenReturn(page);

        Page<NotificationResponseDTO> result = notificationService.getNotifications(user, null, pageable);

        assertThat(result.getContent()).hasSize(1);
        assertThat(result.getContent().get(0).getTitle()).isEqualTo("Test Title");
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
}
