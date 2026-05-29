package com.marinelink.users;

import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.Instant;
import java.util.UUID;

/**
 * Role entity. System roles: ADMIN, STAFF, USER.
 * Stored in {@code roles} table; linked to {@code users.role_id}.
 */
@Entity
@Table(name = "roles")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Role {

    /** Internal DB primary key — never exposed via API. */
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", updatable = false)
    private Long id;

    /** Public UUIDv4 — used in API responses. */
    @Column(name = "public_id", nullable = false, unique = true, updatable = false,
            columnDefinition = "uuid default gen_random_uuid()")
    private UUID publicId;

    /** Role code, e.g. ADMIN, STAFF, USER. */
    @Column(name = "code", nullable = false, unique = true)
    private String code;

    @Column(name = "name", nullable = false)
    private String name;

    @Column(name = "description")
    private String description;

    /** System roles should not be deleted by admin UI. */
    @Column(name = "is_system", nullable = false)
    @Builder.Default
    private boolean isSystem = false;

    @CreationTimestamp
    @Column(name = "created_at", nullable = false, updatable = false)
    private Instant createdAt;

    @UpdateTimestamp
    @Column(name = "updated_at", nullable = false)
    private Instant updatedAt;
}
