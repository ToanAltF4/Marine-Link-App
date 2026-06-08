package com.marinelink.chat;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.marinelink.common.exception.GlobalExceptionHandler;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.time.Instant;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class ChatControllerTest {

    private final ChatService chatService = mock(ChatService.class);
    private final MockMvc mockMvc = MockMvcBuilders
            .standaloneSetup(new ChatController(chatService))
            .setControllerAdvice(new GlobalExceptionHandler())
            .build();
    private final ObjectMapper objectMapper = new ObjectMapper().findAndRegisterModules();

    @Test
    void getThreadReturnsMessagesAndUsesStaffScope() throws Exception {
        UUID staffId = UUID.fromString("550e8400-e29b-41d4-a716-446655440004");
        UUID roomId = UUID.fromString("550e8400-e29b-41d4-a716-44665544000a");
        ChatThreadResponse response = new ChatThreadResponse(
                roomId,
                false,
                List.of(new ChatMessageResponse(
                        UUID.fromString("550e8400-e29b-41d4-a716-44665544000b"),
                        roomId,
                        ChatSenderType.STAFF,
                        "Don hang dang duoc xu ly",
                        Instant.parse("2026-05-28T08:30:00Z"),
                        List.of())));

        when(chatService.getThread(staffId, true, roomId)).thenReturn(response);

        mockMvc.perform(get("/api/chat/{roomId}", roomId)
                        .principal(new TestingAuthenticationToken(
                                staffId.toString(),
                                null,
                                "ROLE_STAFF")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.roomId").value(roomId.toString()))
                .andExpect(jsonPath("$.data.messages[0].senderType").value("STAFF"));

        verify(chatService).getThread(staffId, true, roomId);
    }

    @Test
    void sendMessageReturnsCreatedEnvelope() throws Exception {
        UUID userId = UUID.fromString("550e8400-e29b-41d4-a716-446655440003");
        UUID roomId = UUID.fromString("550e8400-e29b-41d4-a716-44665544000a");
        UUID messageId = UUID.fromString("550e8400-e29b-41d4-a716-44665544000b");
        ChatMessageResponse response = new ChatMessageResponse(
                messageId,
                roomId,
                ChatSenderType.USER,
                "Cho toi hoi don hang",
                Instant.parse("2026-05-28T08:30:00Z"),
                List.of());

        when(chatService.sendMessage(eq(userId), eq(false), any(ChatSendRequest.class)))
                .thenReturn(response);

        mockMvc.perform(post("/api/chat/send")
                        .principal(new TestingAuthenticationToken(userId.toString(), null, "ROLE_USER"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "roomId", roomId.toString(),
                                "content", "Cho toi hoi don hang",
                                "attachments", List.of()))))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("Message sent"))
                .andExpect(jsonPath("$.data.id").value(messageId.toString()))
                .andExpect(jsonPath("$.data.senderType").value("USER"));
    }

    @Test
    void sendMessageRejectsBlankContent() throws Exception {
        UUID userId = UUID.fromString("550e8400-e29b-41d4-a716-446655440003");
        UUID roomId = UUID.fromString("550e8400-e29b-41d4-a716-44665544000a");

        mockMvc.perform(post("/api/chat/send")
                        .principal(new TestingAuthenticationToken(userId.toString(), null, "ROLE_USER"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "roomId", roomId.toString(),
                                "content", "   "))))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    void sendMessageRejectsMissingContent() throws Exception {
        UUID userId = UUID.fromString("550e8400-e29b-41d4-a716-446655440003");
        UUID roomId = UUID.fromString("550e8400-e29b-41d4-a716-44665544000a");

        mockMvc.perform(post("/api/chat/send")
                        .principal(new TestingAuthenticationToken(userId.toString(), null, "ROLE_USER"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "roomId", roomId.toString()))))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false));
    }
}
