package com.marinelink.notifications;

import com.marinelink.common.exception.GlobalExceptionHandler;
import com.marinelink.users.User;
import com.marinelink.users.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import static org.mockito.ArgumentMatchers.eq;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class NotificationControllerTest {

    private final NotificationService notificationService = mock(NotificationService.class);
    private final UserRepository userRepository = mock(UserRepository.class);

    private final MockMvc mockMvc = MockMvcBuilders
            .standaloneSetup(new NotificationController(notificationService, userRepository))
            .setControllerAdvice(new GlobalExceptionHandler())
            .build();

    @Test
    void getNotifications_ShouldReturnPagedNotificationsForCurrentUser() throws java.lang.Exception {
        UUID userId = UUID.randomUUID();
        UUID notificationId = UUID.randomUUID();
        UUID chatRoomId = UUID.randomUUID();

        User mockUser = User.builder()
                .id(1L)
                .publicId(userId)
                .fullName("Test User")
                .build();

        when(userRepository.findActiveByPublicId(userId)).thenReturn(Optional.of(mockUser));
        when(notificationService.getNotifications(eq(mockUser), eq(false), eq(PageRequest.of(0, 20))))
                .thenReturn(new PageImpl<>(List.of(
                        com.marinelink.notifications.dto.NotificationResponseDTO.builder()
                                .id(notificationId)
                                .type(NotificationType.CHAT)
                                .title("Staff replied")
                                .body("Bạn có tin nhắn mới")
                                .relatedChatRoomId(chatRoomId)
                                .read(false)
                                .createdAt(Instant.parse("2026-05-28T08:30:00Z"))
                                .build()
                ), PageRequest.of(0, 20), 1));

        mockMvc.perform(get("/api/notifications")
                        .param("isRead", "false")
                        .principal(new TestingAuthenticationToken(userId.toString(), null))
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data[0].id").value(notificationId.toString()))
                .andExpect(jsonPath("$.data[0].relatedChatRoomId").value(chatRoomId.toString()))
                .andExpect(jsonPath("$.pagination.totalElements").value(1));
    }

    @Test
    void markAsRead_ShouldReturnSuccess() throws java.lang.Exception {
        UUID notificationId = UUID.randomUUID();
        UUID userId = UUID.randomUUID();

        User mockUser = User.builder()
                .id(1L)
                .publicId(userId)
                .fullName("Test User")
                .build();

        when(userRepository.findActiveByPublicId(userId)).thenReturn(Optional.of(mockUser));

        mockMvc.perform(put("/api/notifications/{id}/read", notificationId)
                        .principal(new TestingAuthenticationToken(userId.toString(), null))
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("Notification marked as read"));
    }

    @Test
    void markAsRead_WithInvalidId_ShouldReturnBadRequest() throws java.lang.Exception {
        mockMvc.perform(put("/api/notifications/not-a-uuid/read")
                        .principal(new TestingAuthenticationToken(UUID.randomUUID().toString(), null)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false));
    }
}
