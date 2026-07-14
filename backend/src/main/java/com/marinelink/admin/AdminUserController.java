package com.marinelink.admin;

import com.marinelink.common.api.ApiResponse;
import com.marinelink.users.UserStatus;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/admin/users")
@RequiredArgsConstructor
public class AdminUserController {

    private final AdminUserService adminUserService;

    @GetMapping
    public ApiResponse<List<AdminUserResponse>> listUsers(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(required = false) String role,
            @RequestParam(required = false) UserStatus status,
            @RequestParam(name = "q", required = false) String query) {
        Page<AdminUserResponse> users = adminUserService.listUsers(page, size, role, status, query);
        return ApiResponse.ok(users.getContent(), ApiResponse.PaginationMeta.of(users));
    }

    /** Admin tạo tài khoản (mặc định STAFF); tài khoản được kích hoạt sẵn (ACTIVE). */
    @PostMapping
    public ResponseEntity<ApiResponse<AdminUserResponse>> createUser(
            @Valid @RequestBody AdminUserCreateRequest request) {
        return ResponseEntity
                .status(HttpStatus.CREATED)
                .body(ApiResponse.created(
                        adminUserService.createUser(request),
                        "Đã tạo tài khoản"));
    }

    @GetMapping("/{id}")
    public ApiResponse<AdminUserResponse> getUser(@PathVariable UUID id) {
        return ApiResponse.ok(adminUserService.getUser(id));
    }

    @PutMapping("/{id}")
    public ApiResponse<AdminUserResponse> updateUser(
            @PathVariable UUID id,
            @Valid @RequestBody AdminUserUpdateRequest request) {
        return ApiResponse.ok(adminUserService.updateUser(id, request), "User updated");
    }

    @PutMapping("/{id}/role")
    public ApiResponse<AdminUserResponse> updateRole(
            @PathVariable UUID id,
            @Valid @RequestBody AdminUserRoleUpdateRequest request) {
        return ApiResponse.ok(adminUserService.updateRole(id, request), "User role updated");
    }
}
