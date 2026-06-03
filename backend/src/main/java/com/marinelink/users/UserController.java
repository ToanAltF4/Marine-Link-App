package com.marinelink.users;

import com.marinelink.auth.AuthUserResponse;
import com.marinelink.common.api.ApiResponse;
import com.marinelink.common.exception.BusinessException;
import com.marinelink.common.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserRepository userRepository;

    @GetMapping("/me")
    public ApiResponse<AuthUserResponse> getCurrentUser(Authentication authentication) {
        if (authentication == null || authentication.getName() == null) {
            throw new BusinessException("Authentication required", HttpStatus.UNAUTHORIZED);
        }

        UUID publicId = parsePublicId(authentication.getName());
        User user = userRepository.findActiveByPublicId(publicId)
                .orElseThrow(() -> new ResourceNotFoundException("Khong tim thay nguoi dung"));

        return ApiResponse.ok(AuthUserResponse.from(user));
    }

    private UUID parsePublicId(String subject) {
        try {
            return UUID.fromString(subject);
        } catch (IllegalArgumentException ex) {
            throw new BusinessException("Invalid authentication subject", HttpStatus.UNAUTHORIZED);
        }
    }
}
