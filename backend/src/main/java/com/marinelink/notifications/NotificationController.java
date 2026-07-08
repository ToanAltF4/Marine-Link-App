package com.marinelink.notifications;

import com.marinelink.common.api.ApiResponse;
import com.marinelink.common.api.ApiResponse.PaginationMeta;
import com.marinelink.common.exception.BusinessException;
import com.marinelink.common.exception.ResourceNotFoundException;
import com.marinelink.notifications.dto.BroadcastSummaryDTO;
import com.marinelink.notifications.dto.NotificationResponseDTO;
import com.marinelink.users.User;
import com.marinelink.users.UserRepository;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final NotificationService notificationService;
    private final UserRepository userRepository;

    @GetMapping
    @PreAuthorize("hasAnyRole('USER', 'STAFF', 'ADMIN')")
    public ResponseEntity<ApiResponse<java.util.List<NotificationResponseDTO>>> getNotifications(
            @RequestParam(required = false) Boolean isRead,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            Authentication authentication
    ) {
        User currentUser = getCurrentUser(authentication);
        Pageable pageable = PageRequest.of(page, size);
        Page<NotificationResponseDTO> response = notificationService.getNotifications(currentUser, isRead, pageable);
        return ResponseEntity.ok(
                ApiResponse.ok(response.getContent(), PaginationMeta.of(response))
        );
    }

    @PutMapping("/{id}/read")
    @PreAuthorize("hasAnyRole('USER', 'STAFF', 'ADMIN')")
    public ResponseEntity<ApiResponse<java.lang.Void>> markAsRead(
            @PathVariable UUID id,
            Authentication authentication
    ) {
        User currentUser = getCurrentUser(authentication);
        notificationService.markAsRead(id, currentUser);
        return ResponseEntity.ok(
                ApiResponse.<Void>builder()
                        .success(true)
                        .message("Notification marked as read")
                        .build()
        );
    }

    // ── Admin/staff broadcasts (ML-67) ─────────────────────────────────────────

    @PostMapping
    @PreAuthorize("hasAnyRole('STAFF', 'ADMIN')")
    public ResponseEntity<ApiResponse<BroadcastSummaryDTO>> createBroadcast(
            @Valid @RequestBody CreateBroadcastRequest request,
            Authentication authentication
    ) {
        User currentUser = getCurrentUser(authentication);
        BroadcastSummaryDTO summary = notificationService.createBroadcast(currentUser.getPublicId(), request);
        return ResponseEntity.status(HttpStatus.CREATED).body(
                ApiResponse.<BroadcastSummaryDTO>builder()
                        .success(true)
                        .message("Đã gửi thông báo đến các đại lý")
                        .data(summary)
                        .build()
        );
    }

    @GetMapping("/broadcasts")
    @PreAuthorize("hasAnyRole('STAFF', 'ADMIN')")
    public ResponseEntity<ApiResponse<java.util.List<BroadcastSummaryDTO>>> listBroadcasts() {
        return ResponseEntity.ok(ApiResponse.ok(notificationService.listBroadcasts()));
    }

    @DeleteMapping("/broadcasts/{broadcastId}")
    @PreAuthorize("hasAnyRole('STAFF', 'ADMIN')")
    public ResponseEntity<ApiResponse<java.lang.Void>> deleteBroadcast(@PathVariable UUID broadcastId) {
        notificationService.deleteBroadcast(broadcastId);
        return ResponseEntity.ok(
                ApiResponse.<Void>builder()
                        .success(true)
                        .message("Đã xóa thông báo")
                        .build()
        );
    }

    private User getCurrentUser(Authentication auth) {
        if (auth == null) {
            throw new BusinessException("Authentication required", HttpStatus.UNAUTHORIZED);
        }
        UUID publicId = UUID.fromString(auth.getName());
        return userRepository.findActiveByPublicId(publicId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
    }
}