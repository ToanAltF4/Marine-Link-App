package com.marinelink.chat;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface ChatMessageRepository extends JpaRepository<ChatMessage, Long> {
    @EntityGraph(attributePaths = "attachments")
    List<ChatMessage> findByRoomOrderByCreatedAtAsc(ChatRoom room);

    @EntityGraph(attributePaths = "attachments")
    Optional<ChatMessage> findTopByRoomOrderByCreatedAtDesc(ChatRoom room);

    Optional<ChatMessage> findByPublicId(UUID publicId);

    long countByRoom(ChatRoom room);
}
