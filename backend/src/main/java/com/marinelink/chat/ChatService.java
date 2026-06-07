package com.marinelink.chat;

import com.marinelink.common.exception.BusinessException;
import com.marinelink.common.exception.ConflictException;
import com.marinelink.common.exception.ResourceNotFoundException;
import com.marinelink.users.User;
import com.marinelink.users.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ChatService {

    private final ChatRoomRepository chatRoomRepository;
    private final ChatMessageRepository chatMessageRepository;
    private final UserRepository userRepository;

    public ChatThreadResponse getThread(UUID currentUserPublicId, boolean canAccessStaffRooms, UUID roomPublicId) {
        User currentUser = getCurrentUser(currentUserPublicId);
        ChatRoom room = getRoom(roomPublicId);
        assertCanAccess(room, currentUser, canAccessStaffRooms);

        List<ChatMessageResponse> messages = chatMessageRepository
                .findByRoomOrderByCreatedAtAsc(room)
                .stream()
                .map(ChatMessageResponse::from)
                .toList();

        return new ChatThreadResponse(room.getPublicId(), room.isClosed(), messages);
    }

    @Transactional
    public ChatMessageResponse sendMessage(
            UUID currentUserPublicId,
            boolean sendAsStaff,
            ChatSendRequest request) {
        String content = request.content() == null ? "" : request.content().trim();
        if (content.isEmpty()) {
            throw new BusinessException("N\u1ed9i dung tin nh\u1eafn kh\u00f4ng \u0111\u01b0\u1ee3c \u0111\u1ec3 tr\u1ed1ng.");
        }

        User currentUser = getCurrentUser(currentUserPublicId);
        ChatRoom room = getRoom(request.roomId());
        assertCanAccess(room, currentUser, sendAsStaff);
        if (room.isClosed()) {
            throw new ConflictException("Ph\u00f2ng chat \u0111\u00e3 \u0111\u00f3ng.");
        }

        Instant now = Instant.now();
        ChatMessage message = ChatMessage.builder()
                .publicId(UUID.randomUUID())
                .room(room)
                .sender(currentUser)
                .senderType(sendAsStaff ? ChatSenderType.STAFF : ChatSenderType.USER)
                .content(content)
                .createdAt(now)
                .build();

        for (ChatAttachmentRequest attachmentRequest : safeAttachments(request.attachments())) {
            ChatAttachment attachment = ChatAttachment.builder()
                    .publicId(UUID.randomUUID())
                    .message(message)
                    .uploadedBy(currentUser)
                    .storageBucket(attachmentRequest.storageBucket())
                    .storagePath(attachmentRequest.storagePath())
                    .fileName(attachmentRequest.fileName())
                    .mimeType(attachmentRequest.mimeType())
                    .fileSizeBytes(attachmentRequest.fileSizeBytes())
                    .createdAt(now)
                    .build();
            message.getAttachments().add(attachment);
        }

        ChatMessage saved = chatMessageRepository.save(message);
        room.setLastMessageAt(now);
        chatRoomRepository.save(room);
        return ChatMessageResponse.from(saved);
    }

    private User getCurrentUser(UUID publicId) {
        return userRepository.findActiveByPublicId(publicId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
    }

    private ChatRoom getRoom(UUID roomPublicId) {
        return chatRoomRepository.findByPublicId(roomPublicId)
                .orElseThrow(() -> new ResourceNotFoundException("Chat room not found"));
    }

    private void assertCanAccess(ChatRoom room, User user, boolean canAccessStaffRooms) {
        if (canAccessStaffRooms || sameUser(room.getUser(), user) || sameUser(room.getAssignedStaff(), user)) {
            return;
        }
        throw new AccessDeniedException("Access denied");
    }

    private boolean sameUser(User left, User right) {
        return left != null && right != null && left.getId() != null && left.getId().equals(right.getId());
    }

    private List<ChatAttachmentRequest> safeAttachments(List<ChatAttachmentRequest> attachments) {
        return attachments == null ? List.of() : attachments;
    }
}
