package com.marinelink.admin;

import com.marinelink.common.exception.BusinessException;
import com.marinelink.common.exception.ConflictException;
import com.marinelink.common.exception.ResourceNotFoundException;
import com.marinelink.notifications.NotificationService;
import com.marinelink.notifications.NotificationType;
import com.marinelink.users.Role;
import com.marinelink.users.RoleRepository;
import com.marinelink.users.User;
import com.marinelink.users.UserRepository;
import com.marinelink.users.UserStatus;
import jakarta.persistence.criteria.Predicate;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AdminUserService {

    private static final String DEFAULT_CREATED_ROLE = "STAFF";

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final AdminUserNotificationService notificationService;
    private final NotificationService appNotificationService;
    private final org.springframework.security.crypto.password.PasswordEncoder passwordEncoder;

    /**
     * Admin tạo tài khoản trực tiếp (mặc định là nhân viên - STAFF).
     *
     * <p>Tài khoản do admin tạo được kích hoạt luôn ({@link UserStatus#ACTIVE}) —
     * không phải chờ xác thực email hay chờ duyệt.
     */
    @Transactional
    public AdminUserResponse createUser(AdminUserCreateRequest request) {
        String email = request.email().trim().toLowerCase(Locale.ROOT);
        String phone = request.phone().trim();

        if (userRepository.existsVerifiedByEmail(email)) {
            throw new ConflictException("Email đã được sử dụng");
        }
        if (userRepository.existsActiveByPhone(phone)) {
            throw new ConflictException("Số điện thoại đã được sử dụng");
        }

        String roleCode = request.roleCode() == null || request.roleCode().isBlank()
                ? DEFAULT_CREATED_ROLE
                : request.roleCode().trim().toUpperCase(Locale.ROOT);
        Role role = roleRepository.findByCode(roleCode)
                .orElseThrow(() -> new BusinessException(
                        "Vai trò không hợp lệ: " + roleCode,
                        org.springframework.http.HttpStatus.UNPROCESSABLE_ENTITY));

        User user = User.builder()
                .publicId(UUID.randomUUID())
                .role(role)
                .fullName(request.fullName().trim())
                .email(email)
                .phone(phone)
                .passwordHash(passwordEncoder.encode(request.password()))
                .status(UserStatus.ACTIVE) // admin tạo => duyệt sẵn
                .build();

        return AdminUserResponse.from(userRepository.save(user));
    }

    public Page<AdminUserResponse> listUsers(
            int page,
            int size,
            String role,
            UserStatus status,
            String query) {
        Pageable pageable = PageRequest.of(
                Math.max(page, 0),
                Math.max(1, Math.min(size, 100)),
                Sort.by(Sort.Order.desc("createdAt"), Sort.Order.asc("fullName")));

        Specification<User> specification = (root, ignoredQuery, cb) -> {
            List<Predicate> predicates = new ArrayList<>();
            predicates.add(cb.isNull(root.get("deletedAt")));

            if (role != null && !role.isBlank()) {
                predicates.add(cb.equal(root.get("role").get("code"),
                        role.trim().toUpperCase(Locale.ROOT)));
            }

            if (status != null) {
                predicates.add(cb.equal(root.get("status"), status));
            }

            if (query != null && !query.isBlank()) {
                String keyword = "%" + query.trim().toLowerCase(Locale.ROOT) + "%";
                predicates.add(cb.or(
                        cb.like(cb.lower(root.get("fullName")), keyword),
                        cb.like(cb.lower(root.get("email")), keyword),
                        cb.like(root.get("phone"), keyword),
                        cb.like(cb.lower(root.get("storeName")), keyword)));
            }

            return cb.and(predicates.toArray(Predicate[]::new));
        };

        return userRepository.findAll(specification, pageable)
                .map(AdminUserResponse::from);
    }

    public AdminUserResponse getUser(UUID publicId) {
        return AdminUserResponse.from(findUser(publicId));
    }

    @Transactional
    public AdminUserResponse updateUser(UUID publicId, AdminUserUpdateRequest request) {
        User user = findUser(publicId);
        UserStatus previousStatus = user.getStatus();

        if (request.status() != null) {
            user.setStatus(request.status());
        }
        if (request.fullName() != null) {
            user.setFullName(request.fullName().trim());
        }
        if (request.phone() != null) {
            user.setPhone(request.phone().trim());
        }
        if (request.businessAddress() != null) {
            user.setBusinessAddress(request.businessAddress().trim());
        }

        User savedUser = userRepository.save(user);
        if (previousStatus == UserStatus.PENDING_APPROVAL && savedUser.getStatus() == UserStatus.ACTIVE) {
            notificationService.sendAccountApprovedEmail(savedUser);
            appNotificationService.createNotification(
                    savedUser,
                    NotificationType.SYSTEM,
                    "Chào mừng đến với MarineLink",
                    "Tài khoản của bạn đã được admin duyệt. Bạn có thể đăng nhập và sử dụng MarineLink ngay bây giờ.",
                    null);
        }

        return AdminUserResponse.from(savedUser);
    }

    @Transactional
    public AdminUserResponse updateRole(UUID publicId, AdminUserRoleUpdateRequest request) {
        User user = findUser(publicId);
        Role role = roleRepository.findByCode(request.roleCode().trim().toUpperCase(Locale.ROOT))
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy role"));

        user.setRole(role);
        return AdminUserResponse.from(userRepository.save(user));
    }

    private User findUser(UUID publicId) {
        return userRepository.findActiveByPublicId(publicId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy người dùng"));
    }
}
