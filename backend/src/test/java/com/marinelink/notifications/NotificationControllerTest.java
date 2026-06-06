package com.marinelink.notifications;

import com.marinelink.common.exception.GlobalExceptionHandler;
import com.marinelink.users.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.UUID;

import static org.mockito.Mockito.mock;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
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
    void markAsRead_ShouldReturnSuccess() throws java.lang.Exception {
        UUID notificationId = UUID.randomUUID();
        UUID userId = UUID.randomUUID();

        // Mô phỏng việc gọi API PUT /api/notifications/{id}/read
        mockMvc.perform(put("/api/notifications/{id}/read", notificationId)
                        .principal(new TestingAuthenticationToken(userId.toString(), null))
                        .contentType(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("Notification marked as read"));
    }

    @Test
    void markAsRead_WithInvalidId_ShouldReturnBadRequest() throws java.lang.Exception {
        // Test xem nếu truyền ID không phải UUID (ví dụ "abc") thì Controller có chặn lại không
        mockMvc.perform(put("/api/notifications/not-a-uuid/read")
                        .principal(new TestingAuthenticationToken(UUID.randomUUID().toString(), null)))
                .andExpect(status().isBadRequest());
    }
}