package com.marinelink.chat;

import com.marinelink.users.User;
import com.marinelink.orders.Order;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ChatRoomRepository extends JpaRepository<ChatRoom, Long> {
    Optional<ChatRoom> findByPublicId(UUID publicId);

    // Phòng hỗ trợ chung của 1 user (không gắn đơn/sản phẩm cụ thể).
    Optional<ChatRoom> findFirstByUserAndRelatedOrderIsNullAndRelatedProductIsNullOrderByCreatedAtAsc(
            User user);

    Optional<ChatRoom> findFirstByUserAndRelatedOrderOrderByCreatedAtAsc(
            User user,
            Order relatedOrder);

    @EntityGraph(attributePaths = {"user", "assignedStaff", "relatedOrder", "relatedProduct"})
    @Query("""
            SELECT r FROM ChatRoom r
            WHERE (:closed IS NULL OR r.closed = :closed)
            ORDER BY COALESCE(r.lastMessageAt, r.createdAt) DESC
            """)
    List<ChatRoom> findStaffRooms(
            @Param("closed") Boolean closed);

    @EntityGraph(attributePaths = {"user", "assignedStaff", "relatedOrder", "relatedProduct"})
    @Query("""
            SELECT r FROM ChatRoom r
            JOIN r.user u
            LEFT JOIN r.relatedOrder o
            LEFT JOIN r.relatedProduct p
            WHERE (:closed IS NULL OR r.closed = :closed)
              AND (
                lower(u.fullName) LIKE :likeQuery
                OR lower(u.email) LIKE :likeQuery
                OR u.phone LIKE :likeQuery
                OR lower(o.orderCode) LIKE :likeQuery
                OR lower(p.name) LIKE :likeQuery
              )
            ORDER BY COALESCE(r.lastMessageAt, r.createdAt) DESC
            """)
    List<ChatRoom> searchStaffRooms(
            @Param("closed") Boolean closed,
            @Param("likeQuery") String likeQuery);
}
