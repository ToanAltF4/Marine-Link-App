package com.marinelink.notifications;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.marinelink.common.exception.GlobalExceptionHandler;
import com.marinelink.notifications.dto.BroadcastSummaryDTO;
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
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
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

    @Test
    void createBroadcast_ShouldReturnCreatedSummary() throws java.lang.Exception {
        UUID userId = UUID.randomUUID();
        UUID broadcastId = UUID.randomUUID();
        User mockUser = User.builder().id(1L).publicId(userId).fullName("Staff").build();

        when(userRepository.findActiveByPublicId(userId)).thenReturn(Optional.of(mockUser));
        when(notificationService.createBroadcast(eq(userId), any(CreateBroadcastRequest.class)))
                .thenReturn(new BroadcastSummaryDTO(
                        broadcastId, "Bảo trì", "Nội dung", userId, Instant.parse("2026-05-28T08:30:00Z"), 4));

        mockMvc.perform(post("/api/notifications")
                        .principal(new TestingAuthenticationToken(userId.toString(), null))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(new ObjectMapper().writeValueAsString(
                                new CreateBroadcastRequest("Bảo trì", "Nội dung"))))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.broadcastId").value(broadcastId.toString()))
                .andExpect(jsonPath("$.data.recipientCount").value(4));
    }

    @Test
    void createBroadcast_WithBlankTitle_ShouldReturnBadRequest() throws java.lang.Exception {
        UUID userId = UUID.randomUUID();
        User mockUser = User.builder().id(1L).publicId(userId).build();
        when(userRepository.findActiveByPublicId(userId)).thenReturn(Optional.of(mockUser));

        mockMvc.perform(post("/api/notifications")
                        .principal(new TestingAuthenticationToken(userId.toString(), null))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(new ObjectMapper().writeValueAsString(
                                new CreateBroadcastRequest("", "Nội dung"))))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    void listBroadcasts_ShouldReturnHistory() throws java.lang.Exception {
        UUID broadcastId = UUID.randomUUID();
        when(notificationService.listBroadcasts()).thenReturn(List.of(
                new BroadcastSummaryDTO(broadcastId, "Bảo trì", "Nội dung",
                        UUID.randomUUID(), Instant.parse("2026-05-28T08:30:00Z"), 4)));

        mockMvc.perform(get("/api/notifications/broadcasts")
                        .principal(new TestingAuthenticationToken(UUID.randomUUID().toString(), null)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data[0].broadcastId").value(broadcastId.toString()));
    }

    @Test
    void deleteBroadcast_ShouldReturnSuccess() throws java.lang.Exception {
        UUID broadcastId = UUID.randomUUID();

        mockMvc.perform(delete("/api/notifications/broadcasts/{id}", broadcastId)
                        .principal(new TestingAuthenticationToken(UUID.randomUUID().toString(), null)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true));

        verify(notificationService).deleteBroadcast(broadcastId);
    }
}
