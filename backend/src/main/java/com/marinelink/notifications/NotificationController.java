package com.marinelink.notifications;

import com.marinelink.common.api.ApiResponse;
import com.marinelink.common.api.ApiResponse.PaginationMeta;
import com.marinelink.notifications.dto.NotificationResponseDTO;
import com.marinelink.users.User;
import com.marinelink.users.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
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
            @RequestParam(defaultValue = "20") int size
    ) {
        User currentUser = getCurrentUser();
        Pageable pageable = PageRequest.of(page, size);
        Page<NotificationResponseDTO> response = notificationService.getNotifications(currentUser, isRead, pageable);
        return ResponseEntity.ok(
                ApiResponse.ok(response.getContent(), PaginationMeta.of(response))
        );
    }

    @PutMapping("/{id}/read")
    @PreAuthorize("hasAnyRole('USER', 'STAFF', 'ADMIN')")
    public ResponseEntity<ApiResponse<java.lang.Void>> markAsRead(@PathVariable java.util.UUID id) {
        User currentUser = getCurrentUser();
        notificationService.markAsRead(id, currentUser);
        return ResponseEntity.ok(
                ApiResponse.<Void>builder()
                        .success(true)
                        .message("Notification marked as read")
                        .build()
        );
    }

    private User getCurrentUser() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        if (auth == null || !auth.isAuthenticated()) {
            throw new IllegalStateException("No authenticated user in security context");
        }
        UUID publicId = UUID.fromString((String) auth.getPrincipal());
        return userRepository.findActiveByPublicId(publicId)
                .orElseThrow(() -> new IllegalStateException("User not found"));
    }
}
