package com.marinelink.chat;

import com.marinelink.common.exception.BusinessException;
import com.marinelink.complaints.Complaint;
import com.marinelink.complaints.ComplaintRepository;
import com.marinelink.users.Role;
import com.marinelink.users.User;
import com.marinelink.users.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.security.access.AccessDeniedException;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class ChatServiceTest {

    private final ChatRoomRepository chatRoomRepository = mock(ChatRoomRepository.class);
    private final ChatMessageRepository chatMessageRepository = mock(ChatMessageRepository.class);
    private final UserRepository userRepository = mock(UserRepository.class);
    private final ComplaintRepository complaintRepository = mock(ComplaintRepository.class);
    private final ChatService chatService = new ChatService(
            chatRoomRepository,
            chatMessageRepository,
            userRepository,
            complaintRepository);

    @Test
    void getThreadReturnsMessagesForRoomOwner() {
        UUID userPublicId = UUID.fromString("550e8400-e29b-41d4-a716-446655440003");
        UUID roomPublicId = UUID.fromString("550e8400-e29b-41d4-a716-44665544000a");
        User owner = user(21L, userPublicId, "USER");
        ChatRoom room = room(roomPublicId, owner, null);
        ChatMessage message = message(room, owner, ChatSenderType.USER, "Cho toi hoi don hang");
        message.getAttachments().add(ChatAttachment.builder()
                .publicId(UUID.fromString("550e8400-e29b-41d4-a716-4466554400ab"))
                .message(message)
                .uploadedBy(owner)
                .storageBucket("chat-attachments")
                .storagePath("rooms/file.png")
                .fileName("file.png")
                .mimeType("image/png")
                .fileSizeBytes(102400L)
                .createdAt(Instant.parse("2026-05-28T08:31:00Z"))
                .build());

        when(userRepository.findActiveByPublicId(userPublicId)).thenReturn(Optional.of(owner));
        when(chatRoomRepository.findByPublicId(roomPublicId)).thenReturn(Optional.of(room));
        when(chatMessageRepository.findByRoomOrderByCreatedAtAsc(room)).thenReturn(List.of(message));

        ChatThreadResponse response = chatService.getThread(userPublicId, false, roomPublicId);

        assertEquals(roomPublicId, response.roomId());
        assertEquals(1, response.messages().size());
        assertEquals(ChatSenderType.USER, response.messages().getFirst().senderType());
        assertEquals(1, response.messages().getFirst().attachments().size());
    }

    @Test
    void getThreadRejectsOtherUserWhenNotStaffOrAdmin() {
        UUID currentUserId = UUID.fromString("550e8400-e29b-41d4-a716-446655440003");
        UUID otherUserId = UUID.fromString("550e8400-e29b-41d4-a716-446655440004");
        UUID roomPublicId = UUID.fromString("550e8400-e29b-41d4-a716-44665544000a");
        User currentUser = user(21L, currentUserId, "USER");
        User owner = user(22L, otherUserId, "USER");
        ChatRoom room = room(roomPublicId, owner, null);

        when(userRepository.findActiveByPublicId(currentUserId)).thenReturn(Optional.of(currentUser));
        when(chatRoomRepository.findByPublicId(roomPublicId)).thenReturn(Optional.of(room));

        assertThrows(
                AccessDeniedException.class,
                () -> chatService.getThread(currentUserId, false, roomPublicId));
    }

    @Test
    void staffCanSendMessageAndUpdatesRoomLastMessage() {
        UUID staffPublicId = UUID.fromString("550e8400-e29b-41d4-a716-446655440004");
        UUID roomPublicId = UUID.fromString("550e8400-e29b-41d4-a716-44665544000a");
        User owner = user(21L, UUID.fromString("550e8400-e29b-41d4-a716-446655440003"), "USER");
        User staff = user(22L, staffPublicId, "STAFF");
        ChatRoom room = room(roomPublicId, owner, staff);
        ChatSendRequest request = new ChatSendRequest(roomPublicId, "  Don hang se duoc giao hom nay  ", List.of());

        when(userRepository.findActiveByPublicId(staffPublicId)).thenReturn(Optional.of(staff));
        when(chatRoomRepository.findByPublicId(roomPublicId)).thenReturn(Optional.of(room));
        when(chatMessageRepository.save(any(ChatMessage.class))).thenAnswer(invocation -> invocation.getArgument(0));

        ChatMessageResponse response = chatService.sendMessage(staffPublicId, true, request);

        assertEquals(ChatSenderType.STAFF, response.senderType());
        assertEquals("Don hang se duoc giao hom nay", response.content());
        assertNotNull(room.getLastMessageAt());
        assertEquals(staff, room.getAssignedStaff());
        verify(chatRoomRepository).save(room);
    }

    @Test
    void listStaffRoomsFiltersOpenRoomsAndReturnsSummary() {
        UUID staffPublicId = UUID.fromString("550e8400-e29b-41d4-a716-446655440004");
        UUID roomPublicId = UUID.fromString("550e8400-e29b-41d4-a716-44665544000a");
        User owner = user(21L, UUID.fromString("550e8400-e29b-41d4-a716-446655440003"), "USER");
        User staff = user(22L, staffPublicId, "STAFF");
        ChatRoom room = room(roomPublicId, owner, staff);
        ChatMessage message = message(room, owner, ChatSenderType.USER, "Can kiem tra don hang");

        when(userRepository.findActiveByPublicId(staffPublicId)).thenReturn(Optional.of(staff));
        when(chatRoomRepository.findStaffRooms(false, "daily")).thenReturn(List.of(room));
        when(chatMessageRepository.findTopByRoomOrderByCreatedAtDesc(room)).thenReturn(Optional.of(message));
        when(chatMessageRepository.countByRoom(room)).thenReturn(1L);
        when(chatMessageRepository.findByRoomOrderByCreatedAtAsc(room)).thenReturn(List.of(message));

        List<StaffChatRoomResponse> response = chatService.listStaffRooms(
                staffPublicId,
                true,
                "OPEN",
                "daily");

        assertEquals(1, response.size());
        assertEquals(roomPublicId, response.getFirst().roomId());
        assertEquals("Nguyen Van A", response.getFirst().customer().fullName());
        assertEquals(ChatSenderType.USER, response.getFirst().lastMessage().senderType());
    }

    @Test
    void updateRoomStatusClosesRoomAndAssignsStaff() {
        UUID staffPublicId = UUID.fromString("550e8400-e29b-41d4-a716-446655440004");
        UUID roomPublicId = UUID.fromString("550e8400-e29b-41d4-a716-44665544000a");
        User owner = user(21L, UUID.fromString("550e8400-e29b-41d4-a716-446655440003"), "USER");
        User staff = user(22L, staffPublicId, "STAFF");
        ChatRoom room = room(roomPublicId, owner, null);

        when(userRepository.findActiveByPublicId(staffPublicId)).thenReturn(Optional.of(staff));
        when(chatRoomRepository.findByPublicId(roomPublicId)).thenReturn(Optional.of(room));
        when(chatRoomRepository.save(room)).thenReturn(room);

        StaffChatRoomStatusResponse response = chatService.updateRoomStatus(
                staffPublicId,
                true,
                roomPublicId,
                true);

        assertEquals(roomPublicId, response.roomId());
        assertEquals(true, response.isClosed());
        assertEquals(staff, room.getAssignedStaff());
    }

    @Test
    void createComplaintLinksRoomAndMessage() {
        UUID staffPublicId = UUID.fromString("550e8400-e29b-41d4-a716-446655440004");
        UUID roomPublicId = UUID.fromString("550e8400-e29b-41d4-a716-44665544000a");
        UUID messagePublicId = UUID.fromString("550e8400-e29b-41d4-a716-44665544000b");
        User owner = user(21L, UUID.fromString("550e8400-e29b-41d4-a716-446655440003"), "USER");
        User staff = user(22L, staffPublicId, "STAFF");
        ChatRoom room = room(roomPublicId, owner, staff);
        ChatMessage message = message(room, owner, ChatSenderType.USER, "Giao thieu hang");
        StaffChatComplaintRequest request = new StaffChatComplaintRequest(
                "Giao thieu hang",
                "Khach bao giao thieu hang tu chat",
                messagePublicId);

        when(userRepository.findActiveByPublicId(staffPublicId)).thenReturn(Optional.of(staff));
        when(chatRoomRepository.findByPublicId(roomPublicId)).thenReturn(Optional.of(room));
        when(chatMessageRepository.findByPublicId(messagePublicId)).thenReturn(Optional.of(message));
        when(complaintRepository.save(any(Complaint.class))).thenAnswer(invocation -> invocation.getArgument(0));

        StaffChatComplaintResponse response = chatService.createComplaint(
                staffPublicId,
                true,
                roomPublicId,
                request);

        assertEquals(roomPublicId, response.roomId());
        assertEquals(messagePublicId, response.messageId());
        assertEquals("Giao thieu hang", response.title());
    }

    @Test
    void sendMessageRejectsBlankContentBeforeSaving() {
        UUID userPublicId = UUID.fromString("550e8400-e29b-41d4-a716-446655440003");
        UUID roomPublicId = UUID.fromString("550e8400-e29b-41d4-a716-44665544000a");
        ChatSendRequest request = new ChatSendRequest(roomPublicId, "   ", null);

        assertThrows(
                BusinessException.class,
                () -> chatService.sendMessage(userPublicId, false, request));
        verify(chatMessageRepository, never()).save(any(ChatMessage.class));
    }

    private ChatRoom room(UUID publicId, User owner, User assignedStaff) {
        return ChatRoom.builder()
                .id(31L)
                .publicId(publicId)
                .user(owner)
                .assignedStaff(assignedStaff)
                .closed(false)
                .build();
    }

    private ChatMessage message(ChatRoom room, User sender, ChatSenderType senderType, String content) {
        return ChatMessage.builder()
                .id(41L)
                .publicId(UUID.fromString("550e8400-e29b-41d4-a716-44665544000b"))
                .room(room)
                .sender(sender)
                .senderType(senderType)
                .content(content)
                .createdAt(Instant.parse("2026-05-28T08:30:00Z"))
                .build();
    }

    private User user(Long id, UUID publicId, String roleCode) {
        return User.builder()
                .id(id)
                .publicId(publicId)
                .role(Role.builder().code(roleCode).build())
                .fullName("Nguyen Van A")
                .email(publicId + "@example.com")
                .phone("0912345678")
                .passwordHash("hash")
                .build();
    }
}
