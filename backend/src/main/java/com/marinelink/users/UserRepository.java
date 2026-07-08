package com.marinelink.users;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface UserRepository extends JpaRepository<User, Long>, JpaSpecificationExecutor<User> {

    @Query("SELECT u FROM User u WHERE u.deletedAt IS NULL AND u.role.code = :roleCode")
    List<User> findActiveByRoleCode(@Param("roleCode") String roleCode);

    @Query("SELECT u FROM User u WHERE (lower(u.email) = lower(:emailOrPhone) OR u.phone = :emailOrPhone) AND u.deletedAt IS NULL")
    Optional<User> findActiveByEmailOrPhone(@Param("emailOrPhone") String emailOrPhone);

    @Query("SELECT u FROM User u WHERE u.publicId = :publicId AND u.deletedAt IS NULL")
    Optional<User> findActiveByPublicId(@Param("publicId") UUID publicId);

    @Query("SELECT CASE WHEN COUNT(u) > 0 THEN true ELSE false END FROM User u WHERE lower(u.email) = lower(:email) AND u.deletedAt IS NULL")
    boolean existsActiveByEmail(@Param("email") String email);

    @Query("SELECT CASE WHEN COUNT(u) > 0 THEN true ELSE false END FROM User u "
            + "WHERE lower(u.email) = lower(:email) "
            + "AND u.status <> com.marinelink.users.UserStatus.PENDING_VERIFICATION "
            + "AND u.deletedAt IS NULL")
    boolean existsVerifiedByEmail(@Param("email") String email);

    @Query("SELECT CASE WHEN COUNT(u) > 0 THEN true ELSE false END FROM User u WHERE u.phone = :phone AND u.deletedAt IS NULL")
    boolean existsActiveByPhone(@Param("phone") String phone);

    @Query("SELECT CASE WHEN COUNT(u) > 0 THEN true ELSE false END FROM User u WHERE u.phone = :phone AND u.publicId <> :publicId AND u.deletedAt IS NULL")
    boolean existsActiveByPhoneAndPublicIdNot(@Param("phone") String phone, @Param("publicId") UUID publicId);

    @Query("SELECT COUNT(u) FROM User u WHERE u.deletedAt IS NULL "
            + "AND u.status = com.marinelink.users.UserStatus.ACTIVE "
            + "AND u.role.code = 'USER'")
    long countActiveDealers();

    @Query("SELECT u FROM User u WHERE lower(u.email) = lower(:email) AND u.status = :status AND u.deletedAt IS NULL")
    Optional<User> findByEmailAndStatus(@Param("email") String email, @Param("status") UserStatus status);

    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("DELETE FROM User u "
            + "WHERE u.status = com.marinelink.users.UserStatus.PENDING_VERIFICATION "
            + "AND u.deletedAt IS NULL "
            + "AND u.createdAt < :cutoff")
    int deletePendingVerificationCreatedBefore(@Param("cutoff") Instant cutoff);
}
