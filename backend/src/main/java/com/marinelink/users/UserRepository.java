package com.marinelink.users;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;
import java.util.UUID;

public interface UserRepository extends JpaRepository<User, Long> {

    @Query("SELECT u FROM User u WHERE (lower(u.email) = lower(:emailOrPhone) OR u.phone = :emailOrPhone) AND u.deletedAt IS NULL")
    Optional<User> findActiveByEmailOrPhone(@Param("emailOrPhone") String emailOrPhone);

    @Query("SELECT u FROM User u WHERE u.publicId = :publicId AND u.deletedAt IS NULL")
    Optional<User> findActiveByPublicId(@Param("publicId") UUID publicId);

    @Query("SELECT CASE WHEN COUNT(u) > 0 THEN true ELSE false END FROM User u WHERE lower(u.email) = lower(:email) AND u.deletedAt IS NULL")
    boolean existsActiveByEmail(@Param("email") String email);

    @Query("SELECT CASE WHEN COUNT(u) > 0 THEN true ELSE false END FROM User u WHERE u.phone = :phone AND u.deletedAt IS NULL")
    boolean existsActiveByPhone(@Param("phone") String phone);
}
