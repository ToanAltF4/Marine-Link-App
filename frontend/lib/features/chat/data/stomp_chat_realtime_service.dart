import 'dart:convert';

import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../../../core/storage/secure_token_storage.dart';
import '../domain/chat.dart';
import 'chat_dto.dart';
import 'chat_realtime_service.dart';

/// Realtime chat over STOMP/WebSocket (ML-63).
///
/// One shared connection to the backend `/ws` endpoint (JWT sent on CONNECT).
/// Each viewed room subscribes to `/topic/chat.{roomId}`; incoming frames are
/// parsed into [ChatMessage] and pushed to the cubit.
class StompChatRealtimeService implements ChatRealtimeService {
  final String wsUrl;
  final SecureTokenStorage tokenStorage;

  StompClient? _client;
  bool _connected = false;
  final Map<int, _RoomSubscription> _subscriptions = {};
  int _seq = 0;

  StompChatRealtimeService({required this.wsUrl, required this.tokenStorage});

  @override
  ChatRealtimeSubscription subscribeToRoom(
    String roomId,
    void Function(ChatMessage message) onMessage,
  ) {
    final sub = _RoomSubscription(
      id: _seq++,
      roomId: roomId,
      onMessage: onMessage,
      owner: this,
    );
    _subscriptions[sub.id] = sub;
    _ensureConnected().then((_) => _activate(sub));
    return sub;
  }

  Future<void> _ensureConnected() async {
    if (_client != null) return;
    final token = await tokenStorage.getToken();
    final headers = <String, String>{
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    _client = StompClient(
      config: StompConfig(
        url: wsUrl,
        stompConnectHeaders: headers,
        webSocketConnectHeaders: headers,
        reconnectDelay: const Duration(seconds: 3),
        onConnect: _onConnect,
        onWebSocketError: (_) => _connected = false,
        onStompError: (_) => _connected = false,
        onDisconnect: (_) => _connected = false,
      ),
    );
    _client!.activate();
  }

  void _onConnect(StompFrame frame) {
    _connected = true;
    for (final sub in _subscriptions.values) {
      _activate(sub);
    }
  }

  void _activate(_RoomSubscription sub) {
    if (!_connected || _client == null || sub.cancelled || sub.unsubscribe != null) {
      return;
    }
    sub.unsubscribe = _client!.subscribe(
      destination: '/topic/chat.${sub.roomId}',
      callback: (frame) {
        final body = frame.body;
        if (body == null || body.isEmpty) return;
        try {
          sub.onMessage(chatMessageFromJson(jsonDecode(body)));
        } catch (_) {
          // Ignore malformed frames.
        }
      },
    );
  }

  void _remove(_RoomSubscription sub) {
    sub.cancelled = true;
    sub.unsubscribe?.call();
    sub.unsubscribe = null;
    _subscriptions.remove(sub.id);
  }

  @override
  Future<void> dispose() async {
    for (final sub in _subscriptions.values) {
      sub.unsubscribe?.call();
    }
    _subscriptions.clear();
    _client?.deactivate();
    _client = null;
    _connected = false;
  }
}

class _RoomSubscription implements ChatRealtimeSubscription {
  final int id;
  final String roomId;
  final void Function(ChatMessage message) onMessage;
  final StompChatRealtimeService owner;
  StompUnsubscribe? unsubscribe;
  bool cancelled = false;

  _RoomSubscription({
    required this.id,
    required this.roomId,
    required this.onMessage,
    required this.owner,
  });

  @override
  void cancel() => owner._remove(this);
}
