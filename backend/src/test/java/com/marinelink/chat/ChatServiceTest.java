package com.marinelink.chat;

import com.marinelink.common.exception.BusinessException;
import com.marinelink.complaints.Complaint;
import com.marinelink.complaints.ComplaintRepository;
import com.marinelink.orders.Order;
import com.marinelink.orders.OrderItem;
import com.marinelink.orders.OrderRepository;
import com.marinelink.orders.OrderStatus;
import com.marinelink.products.Product;
import com.marinelink.users.Role;
import com.marinelink.users.User;
import com.marinelink.users.UserRepository;
import org.junit.jupiter.api.Test;
import org.springframework.security.access.AccessDeniedException;

import java.math.BigDecimal;
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
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class ChatServiceTest {

    private final ChatRoomRepository chatRoomRepository = mock(ChatRoomRepository.class);
    private final ChatMessageRepository chatMessageRepository = mock(ChatMessageRepository.class);
    private final UserRepository userRepository = mock(UserRepository.class);
    private final ComplaintRepository complaintRepository = mock(ComplaintRepository.class);
    private final OrderRepository orderRepository = mock(OrderRepository.class);
    private final org.springframework.messaging.simp.SimpMessagingTemplate messagingTemplate =
            mock(org.springframework.messaging.simp.SimpMessagingTemplate.class);
    private final ChatService chatService = new ChatService(
            chatRoomRepository,
            chatMessageRepository,
            userRepository,
            complaintRepository,
            orderRepository,
            messagingTemplate);

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
        // Realtime broadcast to the room topic (ML-63).
        verify(messagingTemplate).convertAndSend(
                org.mockito.ArgumentMatchers.eq("/topic/chat." + roomPublicId),
                org.mockito.ArgumentMatchers.<Object>any());
    }

    @Test
    void listMyRoomsReturnsRoomsTitledByFirstMessage() {
        UUID userPublicId = UUID.fromString("550e8400-e29b-41d4-a716-446655440003");
        User owner = user(21L, userPublicId, "USER");
        ChatRoom room = room(UUID.fromString("550e8400-e29b-41d4-a716-44665544000a"), owner, null);
        ChatMessage first = message(room, owner, ChatSenderType.USER, "Xin chao shop");
        when(userRepository.findActiveByPublicId(userPublicId)).thenReturn(Optional.of(owner));
        when(chatRoomRepository.findMyRooms(owner)).thenReturn(List.of(room));
        when(chatMessageRepository.findTopByRoomOrderByCreatedAtAsc(room))
                .thenReturn(Optional.of(first));

        List<ChatRoomSummaryResponse> rooms = chatService.listMyRooms(userPublicId);

        assertEquals(1, rooms.size());
        assertEquals("Xin chao shop", rooms.get(0).title());
        assertEquals(room.getPublicId(), rooms.get(0).roomId());
    }

    @Test
    void listMyRoomsFallsBackToNewConversationTitleWhenEmpty() {
        UUID userPublicId = UUID.fromString("550e8400-e29b-41d4-a716-446655440003");
        User owner = user(21L, userPublicId, "USER");
        ChatRoom room = room(UUID.fromString("550e8400-e29b-41d4-a716-44665544000a"), owner, null);
        when(userRepository.findActiveByPublicId(userPublicId)).thenReturn(Optional.of(owner));
        when(chatRoomRepository.findMyRooms(owner)).thenReturn(List.of(room));
        when(chatMessageRepository.findTopByRoomOrderByCreatedAtAsc(room))
                .thenReturn(Optional.empty());

        assertEquals("Cuộc trò chuyện mới",
                chatService.listMyRooms(userPublicId).get(0).title());
    }

    @Test
    void createMySupportRoomCreatesEmptyRoom() {
        UUID userPublicId = UUID.fromString("550e8400-e29b-41d4-a716-446655440003");
        User owner = user(21L, userPublicId, "USER");
        when(userRepository.findActiveByPublicId(userPublicId)).thenReturn(Optional.of(owner));
        when(chatRoomRepository.save(any(ChatRoom.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));
        when(chatMessageRepository.findByRoomOrderByCreatedAtAsc(any(ChatRoom.class)))
                .thenReturn(List.of());

        ChatThreadResponse thread = chatService.createMySupportRoom(userPublicId);

        assertEquals(0, thread.messages().size());
        assertEquals(false, thread.isClosed());
        verify(chatRoomRepository).save(any(ChatRoom.class));
    }

    @Test
    void listStaffRoomsFiltersOpenRoomsAndReturnsSummary() {
        UUID staffPublicId = UUID.fromString("550e8400-e29b-41d4-a716-446655440004");
        UUID roomPublicId = UUID.fromString("550e8400-e29b-41d4-a716-44665544000a");
        User owner = user(21L, UUID.fromString("550e8400-e29b-41d4-a716-446655440003"), "USER");
        User staff = user(22L, staffPublicId, "STAFF");
        ChatRoom room = room(roomPublicId, owner, staff);
        room.setRelatedOrder(Order.builder()
                .id(41L)
                .publicId(UUID.fromString("550e8400-e29b-41d4-a716-446655440009"))
                .orderCode("ML-20260528-0001")
                .status(OrderStatus.PENDING)
                .totalAmount(BigDecimal.valueOf(4200000))
                .build());
        room.setRelatedProduct(Product.builder()
                .id(42L)
                .publicId(UUID.fromString("550e8400-e29b-41d4-a716-446655440003"))
                .name("Muc kho loai 1")
                .imageUrl("https://example.com/product.png")
                .build());
        ChatMessage message = message(room, owner, ChatSenderType.USER, "Can kiem tra don hang");

        when(userRepository.findActiveByPublicId(staffPublicId)).thenReturn(Optional.of(staff));
        when(chatRoomRepository.searchStaffRooms(false, "%daily%")).thenReturn(List.of(room));
        when(chatMessageRepository.findTopByRoomOrderByCreatedAtDesc(room)).thenReturn(Optional.of(message));
        when(chatMessageRepository.countByRoom(room)).thenReturn(1L);
        when(chatMessageRepository.findByRoomOrderByCreatedAtAsc(room)).thenReturn(List.of(message));

        List<StaffChatRoomResponse> response = chatService.listStaffRooms(
                staffPublicId,
                true,
                "OPEN",
                "Daily");

        assertEquals(1, response.size());
        assertEquals(roomPublicId, response.getFirst().roomId());
        assertEquals("Nguyen Van A", response.getFirst().customer().fullName());
        assertEquals(ChatSenderType.USER, response.getFirst().lastMessage().senderType());
        assertEquals("ML-20260528-0001", response.getFirst().context().orderCode());
        assertEquals("Muc kho loai 1", response.getFirst().context().productName());
    }

    @Test
    void listStaffRoomsWithoutSearchUsesListQuery() {
        // No-search path avoids nullable text parameters in LIKE expressions on
        // real Postgres.
        UUID staffPublicId = UUID.fromString("550e8400-e29b-41d4-a716-446655440004");
        User staff = user(22L, staffPublicId, "STAFF");

        when(userRepository.findActiveByPublicId(staffPublicId)).thenReturn(Optional.of(staff));
        when(chatRoomRepository.findStaffRooms(null)).thenReturn(List.of());

        List<StaffChatRoomResponse> response = chatService.listStaffRooms(
                staffPublicId,
                true,
                "ALL",
                null);

        assertEquals(0, response.size());
        verify(chatRoomRepository).findStaffRooms(null);
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

    @Test
    void sendMessageRejectsNullContentBeforeSaving() {
        UUID userPublicId = UUID.fromString("550e8400-e29b-41d4-a716-446655440003");
        UUID roomPublicId = UUID.fromString("550e8400-e29b-41d4-a716-44665544000a");
        ChatSendRequest request = new ChatSendRequest(roomPublicId, null, null);

        assertThrows(
                BusinessException.class,
                () -> chatService.sendMessage(userPublicId, false, request));
        verify(chatMessageRepository, never()).save(any(ChatMessage.class));
    }

    @Test
    void getOrCreateMyRoomReturnsExistingSupportRoom() {
        UUID userPublicId = UUID.fromString("550e8400-e29b-41d4-a716-446655440003");
        UUID roomPublicId = UUID.fromString("550e8400-e29b-41d4-a716-44665544000a");
        User owner = user(21L, userPublicId, "USER");
        ChatRoom room = room(roomPublicId, owner, null);

        when(userRepository.findActiveByPublicId(userPublicId)).thenReturn(Optional.of(owner));
        when(chatRoomRepository
                .findFirstByUserAndRelatedOrderIsNullAndRelatedProductIsNullOrderByCreatedAtAsc(owner))
                .thenReturn(Optional.of(room));
        when(chatMessageRepository.findByRoomOrderByCreatedAtAsc(room)).thenReturn(List.of());

        ChatThreadResponse response = chatService.getOrCreateMyRoom(userPublicId);

        assertEquals(roomPublicId, response.roomId());
        verify(chatRoomRepository, never()).save(any());
    }

    @Test
    void getOrCreateMyRoomCreatesRoomWhenMissing() {
        UUID userPublicId = UUID.fromString("550e8400-e29b-41d4-a716-446655440003");
        User owner = user(21L, userPublicId, "USER");

        when(userRepository.findActiveByPublicId(userPublicId)).thenReturn(Optional.of(owner));
        when(chatRoomRepository
                .findFirstByUserAndRelatedOrderIsNullAndRelatedProductIsNullOrderByCreatedAtAsc(owner))
                .thenReturn(Optional.empty());
        when(chatRoomRepository.save(any(ChatRoom.class)))
                .thenAnswer(invocation -> invocation.getArgument(0));
        when(chatMessageRepository.findByRoomOrderByCreatedAtAsc(any())).thenReturn(List.of());

        ChatThreadResponse response = chatService.getOrCreateMyRoom(userPublicId);

        assertNotNull(response.roomId());
        verify(chatRoomRepository).save(any(ChatRoom.class));
    }

    @Test
    void getOrCreateMyRoomRejectsStaffAccount() {
        UUID staffPublicId = UUID.fromString("550e8400-e29b-41d4-a716-446655440004");
        User staff = user(22L, staffPublicId, "STAFF");

        when(userRepository.findActiveByPublicId(staffPublicId)).thenReturn(Optional.of(staff));

        BusinessException exception = assertThrows(
                BusinessException.class,
                () -> chatService.getOrCreateMyRoom(staffPublicId)
        );

        assertEquals("Chỉ đại lý mới có phòng chat hỗ trợ riêng.", exception.getMessage());
        verify(chatRoomRepository, never())
                .findFirstByUserAndRelatedOrderIsNullAndRelatedProductIsNullOrderByCreatedAtAsc(any());
        verify(chatRoomRepository, never()).save(any(ChatRoom.class));
    }

    @Test
    void getOrCreateOrderComplaintRoomCreatesRoomWithSeedMessage() {
        UUID userPublicId = UUID.fromString("550e8400-e29b-41d4-a716-446655440003");
        UUID orderPublicId = UUID.fromString("550e8400-e29b-41d4-a716-446655440009");
        User owner = user(21L, userPublicId, "USER");
        Product product = Product.builder()
                .id(51L)
                .publicId(UUID.fromString("550e8400-e29b-41d4-a716-446655440051"))
                .name("Muc kho loai 1")
                .imageUrl("https://example.com/muc.png")
                .build();
        Order order = completedOrder(orderPublicId, owner, product);

        when(userRepository.findActiveByPublicId(userPublicId)).thenReturn(Optional.of(owner));
        when(orderRepository.findDetailByPublicId(orderPublicId)).thenReturn(Optional.of(order));
        when(chatRoomRepository.findFirstByUserAndRelatedOrderOrderByCreatedAtAsc(owner, order))
                .thenReturn(Optional.empty());
        when(chatRoomRepository.save(any(ChatRoom.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(chatMessageRepository.countByRoom(any(ChatRoom.class))).thenReturn(0L);
        when(chatMessageRepository.save(any(ChatMessage.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(chatMessageRepository.findByRoomOrderByCreatedAtAsc(any(ChatRoom.class)))
                .thenAnswer(invocation -> List.of(message(
                        invocation.getArgument(0),
                        null,
                        ChatSenderType.AI_SAMPLE,
                        "Khiếu nại đơn hàng ML-20260528-0001")));

        ChatThreadResponse response = chatService.getOrCreateOrderComplaintRoom(userPublicId, orderPublicId);

        assertNotNull(response.roomId());
        assertEquals(1, response.messages().size());
        assertEquals(ChatSenderType.AI_SAMPLE, response.messages().getFirst().senderType());
        verify(chatRoomRepository, times(2)).save(any(ChatRoom.class));
        verify(chatMessageRepository).save(any(ChatMessage.class));
    }

    @Test
    void getOrCreateOrderComplaintRoomRejectsNonCompletedOrder() {
        UUID userPublicId = UUID.fromString("550e8400-e29b-41d4-a716-446655440003");
        UUID orderPublicId = UUID.fromString("550e8400-e29b-41d4-a716-446655440009");
        User owner = user(21L, userPublicId, "USER");
        Order order = Order.builder()
                .id(41L)
                .publicId(orderPublicId)
                .orderCode("ML-20260528-0001")
                .user(owner)
                .status(OrderStatus.SHIPPING)
                .build();

        when(userRepository.findActiveByPublicId(userPublicId)).thenReturn(Optional.of(owner));
        when(orderRepository.findDetailByPublicId(orderPublicId)).thenReturn(Optional.of(order));

        assertThrows(
                BusinessException.class,
                () -> chatService.getOrCreateOrderComplaintRoom(userPublicId, orderPublicId));
        verify(chatRoomRepository, never()).save(any(ChatRoom.class));
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

    private Order completedOrder(UUID publicId, User owner, Product product) {
        Order order = Order.builder()
                .id(41L)
                .publicId(publicId)
                .orderCode("ML-20260528-0001")
                .user(owner)
                .status(OrderStatus.COMPLETED)
                .totalAmount(BigDecimal.valueOf(4200000))
                .build();
        order.getItems().add(OrderItem.builder()
                .id(42L)
                .order(order)
                .product(product)
                .productNameSnapshot(product.getName())
                .productUnitSnapshot("kg")
                .unitPrice(BigDecimal.valueOf(420000))
                .quantity(10)
                .lineTotal(BigDecimal.valueOf(4200000))
                .build());
        return order;
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
