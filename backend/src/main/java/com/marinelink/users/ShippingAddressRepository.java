package com.marinelink.users;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ShippingAddressRepository extends JpaRepository<ShippingAddress, Long> {

    @Query("""
            SELECT a FROM ShippingAddress a
            WHERE a.user.publicId = :userPublicId AND a.deletedAt IS NULL
            ORDER BY a.defaultAddress DESC, a.updatedAt DESC
            """)
    List<ShippingAddress> findActiveByUserPublicId(@Param("userPublicId") UUID userPublicId);

    @Query("""
            SELECT a FROM ShippingAddress a
            WHERE a.publicId = :publicId
              AND a.user.publicId = :userPublicId
              AND a.deletedAt IS NULL
            """)
    Optional<ShippingAddress> findActiveByPublicIdAndUserPublicId(
            @Param("publicId") UUID publicId,
            @Param("userPublicId") UUID userPublicId);

    @Query("SELECT COUNT(a) FROM ShippingAddress a WHERE a.user.id = :userId AND a.deletedAt IS NULL")
    long countActiveByUserId(@Param("userId") Long userId);

    Optional<ShippingAddress> findFirstByUser_IdAndDeletedAtIsNullOrderByUpdatedAtDesc(Long userId);

    @Modifying
    @Query("""
            UPDATE ShippingAddress a
            SET a.defaultAddress = false
            WHERE a.user.id = :userId
              AND a.deletedAt IS NULL
            """)
    void clearDefaultForUser(@Param("userId") Long userId);

    @Modifying
    @Query("""
            UPDATE ShippingAddress a
            SET a.defaultAddress = false
            WHERE a.user.id = :userId
              AND a.deletedAt IS NULL
              AND a.id <> :exceptId
            """)
    void clearDefaultForUserExcept(@Param("userId") Long userId, @Param("exceptId") Long exceptId);
}
