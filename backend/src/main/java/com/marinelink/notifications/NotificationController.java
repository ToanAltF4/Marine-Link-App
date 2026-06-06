package com.marinelink.notifications;

import com.marinelink.common.api.ApiResponse;
import com.marinelink.common.api.ApiResponse.PaginationMeta;
import com.marinelink.common.exception.BusinessException;
import com.marinelink.common.exception.ResourceNotFoundException;
import com.marinelink.notifications.dto.NotificationResponseDTO;
import com.marinelink.users.User;
import com.marinelink.users.UserRepository;
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

    private User getCurrentUser(Authentication auth) {
        if (auth == null) {
            throw new BusinessException("Authentication required", HttpStatus.UNAUTHORIZED);
        }
        UUID publicId = UUID.fromString(auth.getName());
        return userRepository.findActiveByPublicId(publicId)
                .orElseThrow(() -> new ResourceNotFoundException("User not found"));
    }
}