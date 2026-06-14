package com.marinelink.auth.otp;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface EmailOtpRepository extends JpaRepository<EmailOtp, Long> {

    /**
     * Returns the most recently created, still-unused OTP for the given email.
     */
    Optional<EmailOtp> findTopByEmailAndUsedFalseOrderByCreatedAtDesc(String email);

    /**
     * Returns ALL OTP records for a given email (for debug/diagnostic purposes).
     */
    List<EmailOtp> findAllByEmailOrderByCreatedAtDesc(String email);

    /**
     * Deletes all OTP entries for the given email — called before issuing a new OTP (resend).
     */
    @Modifying(clearAutomatically = true, flushAutomatically = true)
    @Query("DELETE FROM EmailOtp o WHERE o.email = :email")
    void deleteByEmail(@Param("email") String email);
}
