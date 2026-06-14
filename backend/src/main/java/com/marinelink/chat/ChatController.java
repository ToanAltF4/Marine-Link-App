package com.marinelink.chat;

import com.marinelink.common.api.ApiResponse;
import com.marinelink.common.exception.BusinessException;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/chat")
@RequiredArgsConstructor
public class ChatController {

    private final ChatService chatService;

    @GetMapping("/room")
    public ApiResponse<ChatThreadResponse> getMyRoom(Authentication authentication) {
        return ApiResponse.ok(chatService.getOrCreateMyRoom(currentUserId(authentication)));
    }

    @GetMapping("/orders/{orderId}/room")
    public ApiResponse<ChatThreadResponse> getOrderComplaintRoom(
            Authentication authentication,
            @PathVariable UUID orderId) {
        return ApiResponse.ok(chatService.getOrCreateOrderComplaintRoom(
                currentUserId(authentication),
                orderId));
    }

    @GetMapping("/{roomId}")
    public ApiResponse<ChatThreadResponse> getThread(
            Authentication authentication,
            @PathVariable UUID roomId) {
        return ApiResponse.ok(chatService.getThread(
                currentUserId(authentication),
                canAccessStaffRooms(authentication),
                roomId));
    }

    @PostMapping("/send")
    public ResponseEntity<ApiResponse<ChatMessageResponse>> send(
            Authentication authentication,
            @Valid @RequestBody ChatSendRequest request) {
        ChatMessageResponse response = chatService.sendMessage(
                currentUserId(authentication),
                canAccessStaffRooms(authentication),
                request);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.created(response, "Message sent"));
    }

    private UUID currentUserId(Authentication authentication) {
        if (authentication == null || authentication.getName() == null) {
            throw new BusinessException("Authentication required", HttpStatus.UNAUTHORIZED);
        }
        try {
            return UUID.fromString(authentication.getName());
        } catch (IllegalArgumentException ex) {
            throw new BusinessException("Invalid authentication subject", HttpStatus.UNAUTHORIZED);
        }
    }

    private boolean canAccessStaffRooms(Authentication authentication) {
        if (authentication == null) {
            return false;
        }
        return authentication.getAuthorities()
                .stream()
                .anyMatch(authority ->
                        authority.getAuthority().equals("ROLE_STAFF")
                                || authority.getAuthority().equals("ROLE_ADMIN"));
    }
}
