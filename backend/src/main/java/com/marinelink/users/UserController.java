package com.marinelink.users;

import com.marinelink.auth.AuthUserResponse;
import com.marinelink.common.api.ApiResponse;
import com.marinelink.common.exception.BusinessException;
import com.marinelink.common.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.UUID;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @GetMapping("/me")
    public ApiResponse<AuthUserResponse> getCurrentUser(Authentication authentication) {
        UUID publicId = getPublicId(authentication);
        return ApiResponse.ok(userService.getProfile(publicId));
    }

    @PutMapping("/me")
    public ApiResponse<AuthUserResponse> updateProfile(
            @jakarta.validation.Valid @RequestBody UpdateProfileRequest request,
            Authentication authentication
    ) {
        UUID publicId = getPublicId(authentication);
        return ApiResponse.ok(userService.updateProfile(publicId, request));
    }

    private UUID getPublicId(Authentication auth) {
        if (auth == null || auth.getName() == null) {
            throw new com.marinelink.common.exception.BusinessException("Authentication required", HttpStatus.UNAUTHORIZED);
        }
        try {
            return UUID.fromString(auth.getName());
        } catch (IllegalArgumentException ex) {
            throw new com.marinelink.common.exception.BusinessException("Invalid authentication subject", HttpStatus.UNAUTHORIZED);
        }
    }
}
