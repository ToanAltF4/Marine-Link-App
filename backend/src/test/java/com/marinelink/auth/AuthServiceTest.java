package com.marinelink.auth;

import com.marinelink.auth.otp.EmailOtpService;
import com.marinelink.common.exception.BusinessException;
import com.marinelink.common.security.JwtTokenProvider;
import com.marinelink.users.Role;
import com.marinelink.users.RoleRepository;
import com.marinelink.users.User;
import com.marinelink.users.UserRepository;
import com.marinelink.users.UserStatus;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private RoleRepository roleRepository;

    @Mock
    private PasswordEncoder passwordEncoder;

    @Mock
    private JwtTokenProvider jwtTokenProvider;

    @Mock
    private EmailOtpService emailOtpService;

    @InjectMocks
    private AuthService authService;

    @Test
    void loginReturnsJwtAndUserRolesForActiveUser() {
        User user = activeUser("ADMIN");
        when(userRepository.findActiveByEmailOrPhone("admin@marinelink.demo"))
                .thenReturn(Optional.of(user));
        when(passwordEncoder.matches("Admin@123", user.getPasswordHash())).thenReturn(true);
        when(jwtTokenProvider.generateToken(user.getPublicId(), List.of("ADMIN")))
                .thenReturn("jwt-token");
        when(jwtTokenProvider.getExpirationSeconds()).thenReturn(3600L);

        LoginResponse response = authService.login(
                new LoginRequest("admin@marinelink.demo", "Admin@123"));

        assertThat(response.token()).isEqualTo("jwt-token");
        assertThat(response.tokenType()).isEqualTo("Bearer");
        assertThat(response.expiresIn()).isEqualTo(3600L);
        assertThat(response.user().roles()).containsExactly("ADMIN");
    }

    @Test
    void loginRejectsWrongPassword() {
        User user = activeUser("USER");
        when(userRepository.findActiveByEmailOrPhone("daily-a@marinelink.demo"))
                .thenReturn(Optional.of(user));
        when(passwordEncoder.matches("wrong", user.getPasswordHash())).thenReturn(false);

        assertThatThrownBy(() -> authService.login(
                new LoginRequest("daily-a@marinelink.demo", "wrong")))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("không đúng");
    }

    @Test
    void registerCreatesPendingUserWithDefaultUserRoleAndHashedPassword() {
        Role userRole = Role.builder().id(3L).code("USER").name("Đại lý").build();
        when(userRepository.existsActiveByEmail("daily-new@example.com")).thenReturn(false);
        when(userRepository.existsActiveByPhone("0912345678")).thenReturn(false);
        when(roleRepository.findByCode("USER")).thenReturn(Optional.of(userRole));
        when(passwordEncoder.encode("StrongPassword123")).thenReturn("bcrypt-hash");
        when(userRepository.saveAndFlush(any(User.class))).thenAnswer(invocation -> invocation.getArgument(0));

        RegisterResponse response = authService.register(
                new RegisterRequest(
                        "Nguyen Van A",
                        "daily-new@example.com",
                        "0912345678",
                        "StrongPassword123",
                        "Hai San A",
                        "Can Tho",
                        "0312345678"));

        assertThat(response.status()).isEqualTo(UserStatus.PENDING_VERIFICATION.name());
        assertThat(response.roles()).containsExactly("USER");
        verify(userRepository).saveAndFlush(any(User.class));
    }

    @Test
    void changePasswordUpdatesPasswordWhenOldMatches() {
        User user = activeUser("USER");
        UUID publicId = user.getPublicId();
        when(userRepository.findActiveByPublicId(publicId)).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("OldPass123", user.getPasswordHash())).thenReturn(true);
        when(passwordEncoder.encode("NewPass123")).thenReturn("new-bcrypt-hash");

        authService.changePassword(publicId, new ChangePasswordRequest("OldPass123", "NewPass123"));

        assertThat(user.getPasswordHash()).isEqualTo("new-bcrypt-hash");
        verify(userRepository).save(user);
    }

    @Test
    void changePasswordThrowsWhenOldPasswordIncorrect() {
        User user = activeUser("USER");
        UUID publicId = user.getPublicId();
        when(userRepository.findActiveByPublicId(publicId)).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("WrongPass", user.getPasswordHash())).thenReturn(false);

        assertThatThrownBy(() -> authService.changePassword(
                publicId, new ChangePasswordRequest("WrongPass", "NewPass123")))
                .isInstanceOf(BusinessException.class)
                .hasMessageContaining("không chính xác");
    }

    private User activeUser(String roleCode) {
        Role role = Role.builder().id(1L).code(roleCode).name(roleCode).build();
        return User.builder()
                .id(1L)
                .publicId(UUID.randomUUID())
                .role(role)
                .fullName("MarineLink User")
                .email("admin@marinelink.demo")
                .phone("0900000000")
                .passwordHash("bcrypt-hash")
                .status(UserStatus.ACTIVE)
                .build();
    }
}
