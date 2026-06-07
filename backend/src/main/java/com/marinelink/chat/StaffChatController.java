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
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/staff/chat")
@RequiredArgsConstructor
public class StaffChatController {

    private final ChatService chatService;

    @GetMapping("/rooms")
    public ApiResponse<List<StaffChatRoomResponse>> listRooms(
            Authentication authentication,
            @RequestParam(defaultValue = "OPEN") String status,
            @RequestParam(required = false) String q) {
        return ApiResponse.ok(chatService.listStaffRooms(
                currentUserId(authentication),
                canAccessStaffRooms(authentication),
                status,
                q));
    }

    @PutMapping("/rooms/{roomId}/status")
    public ApiResponse<StaffChatRoomStatusResponse> updateStatus(
            Authentication authentication,
            @PathVariable UUID roomId,
            @Valid @RequestBody StaffChatRoomStatusUpdateRequest request) {
        return ApiResponse.ok(
                chatService.updateRoomStatus(
                        currentUserId(authentication),
                        canAccessStaffRooms(authentication),
                        roomId,
                        request.isClosed()),
                "Chat room status updated");
    }

    @PostMapping("/rooms/{roomId}/complaints")
    public ResponseEntity<ApiResponse<StaffChatComplaintResponse>> createComplaint(
            Authentication authentication,
            @PathVariable UUID roomId,
            @Valid @RequestBody StaffChatComplaintRequest request) {
        StaffChatComplaintResponse response = chatService.createComplaint(
                currentUserId(authentication),
                canAccessStaffRooms(authentication),
                roomId,
                request);
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.created(response, "Complaint created"));
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
