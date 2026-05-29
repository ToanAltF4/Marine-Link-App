package com.marinelink.users;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.Instant;
import java.util.UUID;

/**
 * User entity — accounts for Đại lý (USER), Staff, and Admin.
 *
 * <p>ID strategy: {@code id bigint} is the internal DB primary key used for
 * JOINs and foreign keys. {@code publicId UUID} is returned to the API.
 *
 * <p>Authorization: role is linked via {@code role_id → roles.id}.
 */
@Entity
@Table(name = "users")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", updatable = false)
    private Long id;

    @Column(name = "public_id", nullable = false, unique = true, updatable = false,
            columnDefinition = "uuid default gen_random_uuid()")
    private UUID publicId;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "role_id", nullable = false)
    private Role role;

    @Column(name = "full_name", nullable = false)
    private String fullName;

    @Column(name = "email", nullable = false)
    private String email;

    @Column(name = "phone", nullable = false)
    private String phone;

    /** BCrypt hash — never returned in API response. */
    @Column(name = "password_hash", nullable = false)
    private String passwordHash;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    @Builder.Default
    private UserStatus status = UserStatus.PENDING_APPROVAL;

    @Column(name = "store_name")
    private String storeName;

    @Column(name = "business_address")
    private String businessAddress;

    @Column(name = "tax_code")
    private String taxCode;

    @Column(name = "avatar_url")
    private String avatarUrl;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;

    /** Soft delete — null means not deleted. */
    @Column(name = "deleted_at")
    private Instant deletedAt;

    public boolean isActive() {
        return status == UserStatus.ACTIVE && deletedAt == null;
    }

    public String getRoleCode() {
        return role != null ? role.getCode() : null;
    }
}
