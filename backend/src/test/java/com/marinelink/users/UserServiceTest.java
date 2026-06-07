package com.marinelink.users;

import com.marinelink.auth.AuthUserResponse;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class UserServiceTest {

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private UserService userService;

    private User user;
    private UUID publicId;

    @BeforeEach
    void setUp() {
        publicId = UUID.randomUUID();
        user = User.builder()
                .id(1L)
                .publicId(publicId)
                .fullName("Old Name")
                .phone("0123456789")
                .businessAddress("Old Address")
                .role(Role.builder().code("USER").build())
                .build();
    }

    @Test
    void getProfile_ShouldReturnAuthUserResponse() {
        when(userRepository.findActiveByPublicId(publicId)).thenReturn(Optional.of(user));

        AuthUserResponse response = userService.getProfile(publicId);

        assertThat(response.fullName()).isEqualTo("Old Name");
        verify(userRepository).findActiveByPublicId(publicId);
    }

    @Test
    void updateProfile_ShouldUpdateFieldsAndSave() {
        UpdateProfileRequest request = new UpdateProfileRequest("New Name", "0987654321", "New Address");
        when(userRepository.findActiveByPublicId(publicId)).thenReturn(Optional.of(user));
        when(userRepository.save(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));

        AuthUserResponse response = userService.updateProfile(publicId, request);

        assertThat(response.fullName()).isEqualTo("New Name");
        assertThat(response.phone()).isEqualTo("0987654321");
        assertThat(user.getBusinessAddress()).isEqualTo("New Address");
        verify(userRepository).save(user);
    }
}
