package com.marinelink.auth;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.marinelink.common.exception.GlobalExceptionHandler;
import com.marinelink.users.UserStatus;
import org.junit.jupiter.api.Test;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.List;
import java.util.UUID;

import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class AuthControllerTest {

    private final AuthService authService = mock(AuthService.class);
    private final MockMvc mockMvc = MockMvcBuilders
            .standaloneSetup(new AuthController(authService))
            .setControllerAdvice(new GlobalExceptionHandler())
            .build();
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Test
    void loginReturnsApiEnvelope() throws Exception {
        AuthUserResponse user = new AuthUserResponse(
                UUID.fromString("550e8400-e29b-41d4-a716-446655440001"),
                "MarineLink Admin",
                "admin@marinelink.demo",
                "0900000000",
                UserStatus.ACTIVE.name(),
                List.of("ADMIN"),
                null,
                null,
                null,
                null);
        LoginRequest request = new LoginRequest("admin@marinelink.demo", "Admin@123");
        when(authService.login(request)).thenReturn(
                new LoginResponse("jwt-token", "Bearer", 3600L, user));

        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("Login successful"))
                .andExpect(jsonPath("$.data.token").value("jwt-token"))
                .andExpect(jsonPath("$.data.user.roles[0]").value("ADMIN"));
    }

    @Test
    void googleLoginReturnsApiEnvelope() throws Exception {
        AuthUserResponse user = new AuthUserResponse(
                UUID.fromString("550e8400-e29b-41d4-a716-446655440003"),
                "Google User",
                "google-user@gmail.com",
                null,
                UserStatus.ACTIVE.name(),
                List.of("USER"),
                null,
                null,
                null,
                "http://pic");
        GoogleLoginRequest request = new GoogleLoginRequest("google-id-token");
        when(authService.googleLogin(request))
                .thenReturn(new LoginResponse("jwt-token", "Bearer", 3600L, user));

        mockMvc.perform(post("/api/auth/google")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.token").value("jwt-token"))
                .andExpect(jsonPath("$.data.user.roles[0]").value("USER"));
    }

    @Test
    void googleLoginRejectsMissingIdToken() throws Exception {
        mockMvc.perform(post("/api/auth/google")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(new GoogleLoginRequest(""))))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false));
    }

    @Test
    void registerReturnsCreatedEnvelope() throws Exception {
        RegisterRequest request = new RegisterRequest(
                "Nguyen Van A",
                "daily-new@example.com",
                "0912345678",
                "StrongPassword123",
                "Hai San A",
                "Can Tho",
                "0312345678");
        RegisterResponse response = new RegisterResponse(
                UUID.fromString("550e8400-e29b-41d4-a716-446655440002"),
                UserStatus.PENDING_APPROVAL.name(),
                List.of("USER"));
        when(authService.register(request)).thenReturn(response);

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("Register successful. Please check your email for the OTP."))
                .andExpect(jsonPath("$.data.roles[0]").value("USER"));
    }

    @Test
    void emailAvailabilityReturnsApiEnvelope() throws Exception {
        EmailAvailabilityResponse response = new EmailAvailabilityResponse(
                true,
                "Email có thể sử dụng");
        when(authService.emailAvailability("daily-new@example.com")).thenReturn(response);

        mockMvc.perform(get("/api/auth/email-availability")
                        .param("email", "daily-new@example.com"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.available").value(true))
                .andExpect(jsonPath("$.data.message").value("Email có thể sử dụng"));
    }

    @Test
    void phoneAvailabilityReturnsApiEnvelope() throws Exception {
        PhoneAvailabilityResponse response = new PhoneAvailabilityResponse(
                false,
                "Số điện thoại đã được sử dụng");
        when(authService.phoneAvailability("0912345678", "daily-new@example.com")).thenReturn(response);

        mockMvc.perform(get("/api/auth/phone-availability")
                        .param("phone", "0912345678")
                        .param("email", "daily-new@example.com"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.available").value(false))
                .andExpect(jsonPath("$.data.message").value("Số điện thoại đã được sử dụng"));
    }
}
