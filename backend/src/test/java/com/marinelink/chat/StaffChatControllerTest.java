package com.marinelink.chat;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.marinelink.common.exception.GlobalExceptionHandler;
import com.marinelink.complaints.ComplaintStatus;
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
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class StaffChatControllerTest {

    private final ChatService chatService = mock(ChatService.class);
    private final MockMvc mockMvc = MockMvcBuilders
            .standaloneSetup(new StaffChatController(chatService))
            .setControllerAdvice(new GlobalExceptionHandler())
            .build();
    private final ObjectMapper objectMapper = new ObjectMapper().findAndRegisterModules();

    @Test
    void listRoomsReturnsStaffInbox() throws Exception {
        UUID staffId = UUID.fromString("550e8400-e29b-41d4-a716-446655440004");
        UUID roomId = UUID.fromString("550e8400-e29b-41d4-a716-44665544000a");
        StaffChatRoomResponse room = new StaffChatRoomResponse(
                roomId,
                new StaffChatCustomerResponse(
                        UUID.fromString("550e8400-e29b-41d4-a716-446655440003"),
                        "Dai ly A",
                        "daily-a@marinelink.demo",
                        "0901000001"),
                new StaffChatAssigneeResponse(staffId, "Staff Demo"),
                false,
                Instant.parse("2026-05-28T08:30:00Z"),
                Instant.parse("2026-05-28T08:00:00Z"),
                Instant.parse("2026-05-28T08:30:00Z"),
                2,
                null,
                "Dai ly: Can ho tro don hang");

        when(chatService.listStaffRooms(staffId, true, "OPEN", "daily"))
                .thenReturn(List.of(room));

        mockMvc.perform(get("/api/staff/chat/rooms")
                        .queryParam("status", "OPEN")
                        .queryParam("q", "daily")
                        .principal(new TestingAuthenticationToken(
                                staffId.toString(),
                                null,
                                "ROLE_STAFF")))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data[0].roomId").value(roomId.toString()))
                .andExpect(jsonPath("$.data[0].customer.fullName").value("Dai ly A"))
                .andExpect(jsonPath("$.data[0].isClosed").value(false));

        verify(chatService).listStaffRooms(staffId, true, "OPEN", "daily");
    }

    @Test
    void updateStatusReturnsEnvelope() throws Exception {
        UUID staffId = UUID.fromString("550e8400-e29b-41d4-a716-446655440004");
        UUID roomId = UUID.fromString("550e8400-e29b-41d4-a716-44665544000a");
        when(chatService.updateRoomStatus(staffId, true, roomId, true))
                .thenReturn(new StaffChatRoomStatusResponse(roomId, true));

        mockMvc.perform(put("/api/staff/chat/rooms/{roomId}/status", roomId)
                        .principal(new TestingAuthenticationToken(
                                staffId.toString(),
                                null,
                                "ROLE_STAFF"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of("isClosed", true))))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.message").value("Chat room status updated"))
                .andExpect(jsonPath("$.data.isClosed").value(true));
    }

    @Test
    void createComplaintReturnsCreatedEnvelope() throws Exception {
        UUID staffId = UUID.fromString("550e8400-e29b-41d4-a716-446655440004");
        UUID roomId = UUID.fromString("550e8400-e29b-41d4-a716-44665544000a");
        UUID complaintId = UUID.fromString("550e8400-e29b-41d4-a716-446655440077");
        when(chatService.createComplaint(eq(staffId), eq(true), eq(roomId), any(StaffChatComplaintRequest.class)))
                .thenReturn(new StaffChatComplaintResponse(
                        complaintId,
                        roomId,
                        null,
                        "Giao thieu hang",
                        "Khach bao giao thieu hang",
                        ComplaintStatus.OPEN,
                        Instant.parse("2026-05-28T08:40:00Z")));

        mockMvc.perform(post("/api/staff/chat/rooms/{roomId}/complaints", roomId)
                        .principal(new TestingAuthenticationToken(
                                staffId.toString(),
                                null,
                                "ROLE_STAFF"))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(Map.of(
                                "title", "Giao thieu hang",
                                "description", "Khach bao giao thieu hang"))))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.message").value("Complaint created"))
                .andExpect(jsonPath("$.data.id").value(complaintId.toString()))
                .andExpect(jsonPath("$.data.status").value("OPEN"));
    }
}
