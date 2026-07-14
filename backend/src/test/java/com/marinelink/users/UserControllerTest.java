package com.marinelink.users;

import com.marinelink.auth.AuthUserResponse;
import com.marinelink.common.exception.GlobalExceptionHandler;
import org.junit.jupiter.api.Test;
import org.springframework.security.authentication.TestingAuthenticationToken;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.List;
import java.util.UUID;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class UserControllerTest {

    private final UserService userService = mock(UserService.class);
    private final MockMvc mockMvc = MockMvcBuilders
            .standaloneSetup(new UserController(userService))
            .setControllerAdvice(new GlobalExceptionHandler())
            .build();

    @Test
    void getCurrentUserReturnsAuthenticatedUserEnvelope() throws Exception {
        UUID userId = UUID.fromString("550e8400-e29b-41d4-a716-446655440003");
        AuthUserResponse response = new AuthUserResponse(
                userId,
                "Dai ly Demo",
                "daily-a@marinelink.demo",
                "0912345678",
                "ACTIVE",
                List.of("USER"),
                null,
                null,
                null,
                null
        );
        when(userService.getProfile(userId)).thenReturn(response);

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

    @Test
    void updateCurrentUserAcceptsAvatarUrl() throws Exception {
        UUID userId = UUID.fromString("550e8400-e29b-41d4-a716-446655440004");
        AuthUserResponse response = new AuthUserResponse(
                userId,
                "Dai ly Demo",
                "daily-a@marinelink.demo",
                "0912345678",
                "ACTIVE",
                List.of("USER"),
                null,
                "Can Tho",
                null,
                "https://example.com/avatar.png"
        );
        when(userService.updateProfile(
                org.mockito.ArgumentMatchers.eq(userId),
                org.mockito.ArgumentMatchers.any(UpdateProfileRequest.class)
        )).thenReturn(response);

        mockMvc.perform(put("/api/users/me")
                        .principal(new TestingAuthenticationToken(userId.toString(), null))
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "fullName": "Dai ly Demo",
                                  "phone": "0912345678",
                                  "businessAddress": "Can Tho",
                                  "avatarUrl": "https://example.com/avatar.png"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.avatarUrl").value("https://example.com/avatar.png"));
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
