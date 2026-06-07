package com.marinelink.admin;

import com.marinelink.common.exception.ResourceNotFoundException;
import com.marinelink.users.Role;
import com.marinelink.users.RoleRepository;
import com.marinelink.users.User;
import com.marinelink.users.UserRepository;
import com.marinelink.users.UserStatus;
import org.junit.jupiter.api.Test;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.jpa.domain.Specification;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class AdminUserServiceTest {

    private final UserRepository userRepository = mock(UserRepository.class);
    private final RoleRepository roleRepository = mock(RoleRepository.class);
    private final AdminUserService adminUserService = new AdminUserService(userRepository, roleRepository);

    @Test
    void listUsersMapsPublicFieldsWithoutPasswordHash() {
        User pendingDealer = user("USER", UserStatus.PENDING_APPROVAL);
        when(userRepository.findAll(any(Specification.class), any(org.springframework.data.domain.Pageable.class)))
                .thenReturn(new PageImpl<>(List.of(pendingDealer)));

        Page<AdminUserResponse> response = adminUserService.listUsers(
                0,
                20,
                "USER",
                UserStatus.PENDING_APPROVAL,
                "daily");

        AdminUserResponse item = response.getContent().getFirst();
        assertEquals(pendingDealer.getPublicId(), item.id());
        assertEquals("USER", item.role());
        assertEquals("PENDING_APPROVAL", item.status());
        assertEquals(List.of("USER"), item.roles());
        assertEquals("Đại lý A", item.fullName());
    }

    @Test
    void updateUserApprovesPendingDealerAndKeepsUnspecifiedFields() {
        UUID publicId = UUID.randomUUID();
        User pendingDealer = user("USER", UserStatus.PENDING_APPROVAL);
        pendingDealer.setPublicId(publicId);

        when(userRepository.findActiveByPublicId(publicId)).thenReturn(Optional.of(pendingDealer));
        when(userRepository.save(pendingDealer)).thenReturn(pendingDealer);

        AdminUserResponse response = adminUserService.updateUser(
                publicId,
                new AdminUserUpdateRequest(UserStatus.ACTIVE, null, null, null));

        assertEquals("ACTIVE", response.status());
        assertEquals("Đại lý A", response.fullName());
        verify(userRepository).save(pendingDealer);
    }

    @Test
    void updateUserCanChangeProfileAdminFields() {
        UUID publicId = UUID.randomUUID();
        User dealer = user("USER", UserStatus.ACTIVE);
        dealer.setPublicId(publicId);
        when(userRepository.findActiveByPublicId(publicId)).thenReturn(Optional.of(dealer));
        when(userRepository.save(dealer)).thenReturn(dealer);

        AdminUserResponse response = adminUserService.updateUser(
                publicId,
                new AdminUserUpdateRequest(
                        UserStatus.DISABLED,
                        "  Đại lý B  ",
                        "  0987654321  ",
                        "  Cần Thơ  "));

        assertEquals("DISABLED", response.status());
        assertEquals("Đại lý B", response.fullName());
        assertEquals("0987654321", response.phone());
        assertEquals("Cần Thơ", response.businessAddress());
    }

    @Test
    void updateRoleReplacesSingleRole() {
        UUID publicId = UUID.randomUUID();
        User user = user("USER", UserStatus.ACTIVE);
        user.setPublicId(publicId);
        Role staffRole = Role.builder().id(2L).code("STAFF").name("Nhân viên").build();

        when(userRepository.findActiveByPublicId(publicId)).thenReturn(Optional.of(user));
        when(roleRepository.findByCode("STAFF")).thenReturn(Optional.of(staffRole));
        when(userRepository.save(user)).thenReturn(user);

        AdminUserResponse response = adminUserService.updateRole(
                publicId,
                new AdminUserRoleUpdateRequest("STAFF"));

        assertEquals("STAFF", response.role());
        assertEquals(staffRole, user.getRole());
    }

    @Test
    void getUserThrowsWhenMissing() {
        UUID publicId = UUID.randomUUID();
        when(userRepository.findActiveByPublicId(publicId)).thenReturn(Optional.empty());

        ResourceNotFoundException exception = assertThrows(
                ResourceNotFoundException.class,
                () -> adminUserService.getUser(publicId));

        assertTrue(exception.getMessage().contains("Không tìm thấy người dùng"));
    }

    private User user(String roleCode, UserStatus status) {
        return User.builder()
                .id(1L)
                .publicId(UUID.randomUUID())
                .role(Role.builder().id(3L).code(roleCode).name(roleCode).build())
                .fullName("Đại lý A")
                .email("daily-a@marinelink.demo")
                .phone("0912345678")
                .passwordHash("bcrypt-secret")
                .status(status)
                .storeName("Đại lý hải sản A")
                .businessAddress("Sóc Trăng")
                .taxCode("0123456789")
                .avatarUrl("https://example.com/avatar.png")
                .createdAt(Instant.parse("2026-06-07T01:00:00Z"))
                .build();
    }
}
