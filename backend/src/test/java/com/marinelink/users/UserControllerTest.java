package com.marinelink.users;

import com.marinelink.common.exception.GlobalExceptionHandler;
import org.junit.jupiter.api.Test;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.Optional;
import java.util.UUID;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class UserControllerTest {

    private final UserRepository userRepository = mock(UserRepository.class);
    private final MockMvc mockMvc = MockMvcBuilders
            .standaloneSetup(new UserController(userRepository))
            .setControllerAdvice(new GlobalExceptionHandler())
            .build();

    @Test
    void getCurrentUserReturnsAuthenticatedUserEnvelope() throws Exception {
        UUID userId = UUID.fromString("550e8400-e29b-41d4-a716-446655440003");
        User user = demoUser(userId, "USER");
        when(userRepository.findActiveByPublicId(userId)).thenReturn(Optional.of(user));

        mockMvc.perform(get("/api/users/me")
                        .principal(new TestingAuthenticationToken(userId.toString(), null)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.id").value(userId.toString()))
                .andExpect(jsonPath("$.data.roles[0]").value("USER"));
    }

    @Test
    void getCurrentUserRejectsInvalidSubject() throws Exception {
        mockMvc.perform(get("/api/users/me")
                        .principal(new TestingAuthenticationToken("not-a-uuid", null)))
                .andExpect(status().isUnauthorized())
                .andExpect(jsonPath("$.success").value(false));
    }

    private User demoUser(UUID userId, String roleCode) {
        Role role = Role.builder()
                .id(3L)
                .code(roleCode)
                .name(roleCode)
                .build();

        return User.builder()
                .id(1L)
                .publicId(userId)
                .role(role)
                .fullName("Dai ly Demo")
                .email("daily-a@marinelink.demo")
                .phone("0912345678")
                .passwordHash("bcrypt-hash")
                .status(UserStatus.ACTIVE)
                .build();
    }
}
