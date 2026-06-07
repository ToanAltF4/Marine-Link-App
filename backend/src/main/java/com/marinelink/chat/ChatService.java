package com.marinelink.chat;

import com.marinelink.common.exception.BusinessException;
import com.marinelink.common.exception.ConflictException;
import com.marinelink.common.exception.ResourceNotFoundException;
import com.marinelink.complaints.Complaint;
import com.marinelink.complaints.ComplaintRepository;
import com.marinelink.complaints.ComplaintStatus;
import com.marinelink.users.User;
import com.marinelink.users.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ChatService {

    private final ChatRoomRepository chatRoomRepository;
    private final ChatMessageRepository chatMessageRepository;
    private final UserRepository userRepository;
    private final ComplaintRepository complaintRepository;

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
        if (sendAsStaff && room.getAssignedStaff() == null) {
            room.setAssignedStaff(currentUser);
        }
        chatRoomRepository.save(room);
        return ChatMessageResponse.from(saved);
    }

    public List<StaffChatRoomResponse> listStaffRooms(
            UUID currentUserPublicId,
            boolean canAccessStaffRooms,
            String status,
            String query) {
        assertStaffScope(canAccessStaffRooms);
        getCurrentUser(currentUserPublicId);

        Boolean closed = switch (normalizeStatus(status)) {
            case "OPEN" -> false;
            case "CLOSED" -> true;
            case "ALL" -> null;
            default -> throw new BusinessException("Tr\u1ea1ng th\u00e1i ph\u00f2ng chat kh\u00f4ng h\u1ee3p l\u1ec7.");
        };
        String normalizedQuery = normalizeQuery(query);

        return chatRoomRepository.findStaffRooms(closed, normalizedQuery)
                .stream()
                .map(this::toStaffRoomResponse)
                .toList();
    }

    @Transactional
    public StaffChatRoomStatusResponse updateRoomStatus(
            UUID currentUserPublicId,
            boolean canAccessStaffRooms,
            UUID roomPublicId,
            boolean closed) {
        assertStaffScope(canAccessStaffRooms);
        User currentUser = getCurrentUser(currentUserPublicId);
        ChatRoom room = getRoom(roomPublicId);
        room.setClosed(closed);
        if (room.getAssignedStaff() == null) {
            room.setAssignedStaff(currentUser);
        }
        return StaffChatRoomStatusResponse.from(chatRoomRepository.save(room));
    }

    @Transactional
    public StaffChatComplaintResponse createComplaint(
            UUID currentUserPublicId,
            boolean canAccessStaffRooms,
            UUID roomPublicId,
            StaffChatComplaintRequest request) {
        assertStaffScope(canAccessStaffRooms);
        User currentUser = getCurrentUser(currentUserPublicId);
        ChatRoom room = getRoom(roomPublicId);
        ChatMessage message = resolveComplaintMessage(room, request.messageId());

        Complaint complaint = Complaint.builder()
                .publicId(UUID.randomUUID())
                .user(room.getUser())
                .chatRoom(room)
                .chatMessage(message)
                .title(request.title().trim())
                .description(request.description().trim())
                .status(ComplaintStatus.OPEN)
                .assignedStaff(currentUser)
                .build();

        if (room.getAssignedStaff() == null) {
            room.setAssignedStaff(currentUser);
            chatRoomRepository.save(room);
        }
        return StaffChatComplaintResponse.from(complaintRepository.save(complaint));
    }

    private User getCurrentUser(UUID publicId) {
        return userRepository.findActiveByPublicId(publicId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
    }

    private ChatRoom getRoom(UUID roomPublicId) {
        return chatRoomRepository.findByPublicId(roomPublicId)
                .orElseThrow(() -> new ResourceNotFoundException("Chat room not found"));
    }

    private StaffChatRoomResponse toStaffRoomResponse(ChatRoom room) {
        ChatMessage lastMessage = chatMessageRepository.findTopByRoomOrderByCreatedAtDesc(room)
                .orElse(null);
        long messageCount = chatMessageRepository.countByRoom(room);
        String summary = summarize(room);
        return StaffChatRoomResponse.from(room, lastMessage, messageCount, summary);
    }

    private String summarize(ChatRoom room) {
        List<ChatMessage> messages = chatMessageRepository.findByRoomOrderByCreatedAtAsc(room);
        if (messages.isEmpty()) {
            return "Ch\u01b0a c\u00f3 l\u1ecbch s\u1eed trao \u0111\u1ed5i.";
        }
        int fromIndex = Math.max(0, messages.size() - 3);
        return messages.subList(fromIndex, messages.size())
                .stream()
                .map(message -> label(message.getSenderType()) + ": " + shorten(message.getContent()))
                .reduce((left, right) -> left + " | " + right)
                .orElse("Ch\u01b0a c\u00f3 l\u1ecbch s\u1eed trao \u0111\u1ed5i.");
    }

    private ChatMessage resolveComplaintMessage(ChatRoom room, UUID messagePublicId) {
        if (messagePublicId == null) {
            return null;
        }
        ChatMessage message = chatMessageRepository.findByPublicId(messagePublicId)
                .orElseThrow(() -> new ResourceNotFoundException("Chat message not found"));
        if (!sameRoom(room, message.getRoom())) {
            throw new BusinessException("Tin nh\u1eafn kh\u00f4ng thu\u1ed9c ph\u00f2ng chat n\u00e0y.", HttpStatus.UNPROCESSABLE_ENTITY);
        }
        return message;
    }

    private void assertStaffScope(boolean canAccessStaffRooms) {
        if (!canAccessStaffRooms) {
            throw new AccessDeniedException("Access denied");
        }
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

    private boolean sameRoom(ChatRoom left, ChatRoom right) {
        return left != null && right != null && left.getId() != null && left.getId().equals(right.getId());
    }

    private List<ChatAttachmentRequest> safeAttachments(List<ChatAttachmentRequest> attachments) {
        return attachments == null ? List.of() : attachments;
    }

    private String normalizeStatus(String status) {
        if (status == null || status.isBlank()) {
            return "OPEN";
        }
        return status.trim().toUpperCase(Locale.ROOT);
    }

    private String normalizeQuery(String query) {
        if (query == null || query.trim().isEmpty()) {
            return null;
        }
        return query.trim();
    }

    private String label(ChatSenderType type) {
        return switch (type) {
            case USER -> "\u0110\u1ea1i l\u00fd";
            case STAFF -> "Nh\u00e2n vi\u00ean";
            case AI_SAMPLE -> "G\u1ee3i \u00fd";
        };
    }

    private String shorten(String content) {
        String trimmed = content == null ? "" : content.trim().replaceAll("\\s+", " ");
        if (trimmed.length() <= 80) {
            return trimmed;
        }
        return trimmed.substring(0, 77) + "...";
    }
}
