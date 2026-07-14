package com.marinelink.notifications;

import com.marinelink.notifications.dto.BroadcastSummaryDTO;
import com.marinelink.users.User;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface NotificationRepository extends JpaRepository<Notification, Long> {

    Page<Notification> findByUserOrderByCreatedAtDesc(User user, Pageable pageable);

    Page<Notification> findByUserAndReadOrderByCreatedAtDesc(User user, boolean read, Pageable pageable);

    Optional<Notification> findByPublicId(UUID publicId);

    long countByUserAndReadFalse(User user);

    // ── Admin/staff broadcasts (ML-67) ─────────────────────────────────────────

    @Query("""
            SELECT new com.marinelink.notifications.dto.BroadcastSummaryDTO(
                n.broadcastId, n.title, n.body, n.createdBy,
                max(n.createdAt), count(n))
            FROM Notification n
            WHERE n.broadcastId IS NOT NULL
            GROUP BY n.broadcastId, n.title, n.body, n.createdBy
            ORDER BY max(n.createdAt) DESC
            """)
    List<BroadcastSummaryDTO> findBroadcastSummaries();

    long countByBroadcastId(UUID broadcastId);

    @Modifying
    @Query("DELETE FROM Notification n WHERE n.broadcastId = :broadcastId")
    void deleteByBroadcastId(@Param("broadcastId") UUID broadcastId);
}
