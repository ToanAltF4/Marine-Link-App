package com.marinelink.chat;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ChatMessageRepository extends JpaRepository<ChatMessage, Long> {
    @EntityGraph(attributePaths = "attachments")
    List<ChatMessage> findByRoomOrderByCreatedAtAsc(ChatRoom room);
}
