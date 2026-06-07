package com.marinelink.admin;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.marinelink.common.exception.GlobalExceptionHandler;
import com.marinelink.users.UserStatus;
import org.junit.jupiter.api.Test;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.List;
import java.util.UUID;

import static org.hamcrest.Matchers.hasKey;
import static org.hamcrest.Matchers.not;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.put;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

class AdminUserControllerTest {

    private final AdminUserService adminUserService = mock(AdminUserService.class);
    private final MockMvc mockMvc = MockMvcBuilders
            .standaloneSetup(new AdminUserController(adminUserService))
            .setControllerAdvice(new GlobalExceptionHandler())
            .build();
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Test
    void listUsersReturnsPaginatedEnvelopeAndDoesNotExposePasswordHash() throws Exception {
        UUID userId = UUID.fromString("550e8400-e29b-41d4-a716-446655440301");
        AdminUserResponse user = response(userId, "USER", "PENDING_APPROVAL");
        when(adminUserService.listUsers(0, 20, "USER", UserStatus.PENDING_APPROVAL, "daily"))
                .thenReturn(new PageImpl<>(List.of(user), PageRequest.of(0, 20), 1));

        mockMvc.perform(get("/api/admin/users")
                        .queryParam("role", "USER")
                        .queryParam("status", "PENDING_APPROVAL")
                        .queryParam("q", "daily"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data[0].id").value(userId.toString()))
                .andExpect(jsonPath("$.data[0].publicId").value(userId.toString()))
                .andExpect(jsonPath("$.data[0].role").value("USER"))
                .andExpect(jsonPath("$.data[0].status").value("PENDING_APPROVAL"))
                .andExpect(jsonPath("$.data[0]", not(hasKey("passwordHash"))))
                .andExpect(jsonPath("$.pagination.totalElements").value(1));
    }

    @Test
    void getUserReturnsDetail() throws Exception {
        UUID userId = UUID.fromString("550e8400-e29b-41d4-a716-446655440302");
        when(adminUserService.getUser(userId)).thenReturn(response(userId, "ADMIN", "ACTIVE"));

        mockMvc.perform(get("/api/admin/users/{id}", userId))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.data.email").value("admin@marinelink.demo"))
                .andExpect(jsonPath("$.data.roles[0]").value("ADMIN"));
    }

    @Test
    void updateUserApprovesPendingDealer() throws Exception {
        UUID userId = UUID.fromString("550e8400-e29b-41d4-a716-446655440303");
        AdminUserUpdateRequest request = new AdminUserUpdateRequest(
                UserStatus.ACTIVE,
                null,
                null,
                null);
        when(adminUserService.updateUser(eq(userId), eq(request)))
                .thenReturn(response(userId, "USER", "ACTIVE"));

        mockMvc.perform(put("/api/admin/users/{id}", userId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("User updated"))
                .andExpect(jsonPath("$.data.status").value("ACTIVE"));
    }

    @Test
    void updateRoleUsesSingularRoleEndpointFromContract() throws Exception {
        UUID userId = UUID.fromString("550e8400-e29b-41d4-a716-446655440304");
        AdminUserRoleUpdateRequest request = new AdminUserRoleUpdateRequest("STAFF");
        when(adminUserService.updateRole(eq(userId), eq(request)))
                .thenReturn(response(userId, "STAFF", "ACTIVE"));

        mockMvc.perform(put("/api/admin/users/{id}/role", userId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.success").value(true))
                .andExpect(jsonPath("$.message").value("User role updated"))
                .andExpect(jsonPath("$.data.role").value("STAFF"));

        verify(adminUserService).updateRole(userId, request);
    }

    @Test
    void updateRoleRejectsInvalidRoleCode() throws Exception {
        UUID userId = UUID.fromString("550e8400-e29b-41d4-a716-446655440305");

        mockMvc.perform(put("/api/admin/users/{id}/role", userId)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("{\"roleCode\":\"MANAGER\"}"))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.success").value(false))
                .andExpect(jsonPath("$.errors[0].field").value("roleCode"));
    }

    private AdminUserResponse response(UUID id, String role, String status) {
        return new AdminUserResponse(
                id,
                id,
                role.equals("ADMIN") ? "MarineLink Admin" : "Đại lý A",
                role.equals("ADMIN") ? "admin@marinelink.demo" : "daily-a@marinelink.demo",
                "0912345678",
                role,
                status,
                List.of(role),
                "Đại lý hải sản A",
                "Sóc Trăng",
                "0123456789",
                null);
    }
}
