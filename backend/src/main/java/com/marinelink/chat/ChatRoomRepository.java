package com.marinelink.chat;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ChatRoomRepository extends JpaRepository<ChatRoom, Long> {
    Optional<ChatRoom> findByPublicId(UUID publicId);

    @EntityGraph(attributePaths = {"user", "assignedStaff"})
    @Query("""
            SELECT r FROM ChatRoom r
            JOIN r.user u
            LEFT JOIN r.assignedStaff s
            WHERE (:closed IS NULL OR r.closed = :closed)
              AND (
                :query IS NULL
                OR lower(u.fullName) LIKE lower(concat('%', cast(:query as string), '%'))
                OR lower(u.email) LIKE lower(concat('%', cast(:query as string), '%'))
                OR u.phone LIKE concat('%', cast(:query as string), '%')
              )
            ORDER BY COALESCE(r.lastMessageAt, r.createdAt) DESC
            """)
    List<ChatRoom> findStaffRooms(
            @Param("closed") Boolean closed,
            @Param("query") String query);
}
