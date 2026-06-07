package com.marinelink.users;

import com.marinelink.auth.AuthUserResponse;
import com.marinelink.common.exception.ResourceNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class UserService {

    private final UserRepository userRepository;

    public AuthUserResponse getProfile(UUID publicId) {
        User user = userRepository.findActiveByPublicId(publicId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy người dùng"));
        return AuthUserResponse.from(user);
    }

    @Transactional
    public AuthUserResponse updateProfile(UUID publicId, UpdateProfileRequest request) {
        User user = userRepository.findActiveByPublicId(publicId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy người dùng"));

        user.setFullName(request.fullName().trim());
        user.setPhone(request.phone().trim());
        user.setBusinessAddress(request.businessAddress() != null ? request.businessAddress().trim() : null);

        return AuthUserResponse.from(userRepository.save(user));
    }
}
