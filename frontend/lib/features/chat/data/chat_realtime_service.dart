import '../domain/chat.dart';

/// Handle returned by [ChatRealtimeService.subscribeToRoom]; cancel to stop
/// receiving live messages for that room.
abstract class ChatRealtimeSubscription {
  void cancel();
}

/// Pushes new chat messages to the client in realtime (STOMP/WebSocket).
///
/// The cubit subscribes to the room it is viewing and appends messages as they
/// arrive, instead of waiting for the polling fallback.
abstract class ChatRealtimeService {
  ChatRealtimeSubscription subscribeToRoom(
    String roomId,
    void Function(ChatMessage message) onMessage,
  );

  Future<void> dispose();
}

/// No-op realtime used in mock mode and tests — the UI falls back to polling.
class DisabledChatRealtimeService implements ChatRealtimeService {
  const DisabledChatRealtimeService();

  @override
  ChatRealtimeSubscription subscribeToRoom(
    String roomId,
    void Function(ChatMessage message) onMessage,
  ) => const _NoopSubscription();

  @override
  Future<void> dispose() async {}
}

class _NoopSubscription implements ChatRealtimeSubscription {
  const _NoopSubscription();
  @override
  void cancel() {}
}
