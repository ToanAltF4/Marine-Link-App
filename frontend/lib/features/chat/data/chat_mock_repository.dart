import '../../../core/api/api_response.dart';
import '../domain/chat.dart';
import '../domain/chat_repository.dart';

class ChatMockRepository implements ChatRepository {
  static const defaultRoomId = '550e8400-e29b-41d4-a716-44665544000a';
  static const emptyRoomId = '550e8400-e29b-41d4-a716-4466554400ee';

  final Map<String, ChatThread> _threads;

  ChatMockRepository({Map<String, ChatThread>? threads})
    : _threads = threads ?? _seedThreads();

  @override
  Future<ApiResponse<ChatThread>> getThread(String roomId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final thread = _threads[roomId];
    if (thread == null) {
      return const ApiResponse(
        success: false,
        message: 'Kh\u00f4ng t\u00ecm th\u1ea5y ph\u00f2ng chat.',
      );
    }
    return ApiResponse(success: true, message: 'OK', data: thread);
  }

  @override
  Future<ApiResponse<ChatMessage>> sendMessage({
    required String roomId,
    required String content,
    bool sendAsStaff = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      return const ApiResponse(
        success: false,
        message:
            'N\u1ed9i dung tin nh\u1eafn kh\u00f4ng \u0111\u01b0\u1ee3c \u0111\u1ec3 tr\u1ed1ng.',
      );
    }

    final thread = _threads[roomId];
    if (thread == null) {
      return const ApiResponse(
        success: false,
        message: 'Kh\u00f4ng t\u00ecm th\u1ea5y ph\u00f2ng chat.',
      );
    }
    if (thread.isClosed) {
      return const ApiResponse(
        success: false,
        message: 'Ph\u00f2ng chat \u0111\u00e3 \u0111\u00f3ng.',
      );
    }

    final message = ChatMessage(
      id: 'mock-message-${thread.messages.length + 1}',
      roomId: roomId,
      senderType: sendAsStaff ? ChatSenderType.staff : ChatSenderType.user,
      content: trimmed,
      createdAt: DateTime.now().toUtc(),
    );
    _threads[roomId] = thread.copyWith(messages: [...thread.messages, message]);

    return ApiResponse(success: true, message: 'Message sent', data: message);
  }

  static Map<String, ChatThread> _seedThreads() {
    final createdAt = DateTime.utc(2026, 5, 28, 8, 30);
    return {
      defaultRoomId: ChatThread(
        roomId: defaultRoomId,
        isClosed: false,
        messages: [
          ChatMessage(
            id: 'mock-message-1',
            roomId: defaultRoomId,
            senderType: ChatSenderType.user,
            content:
                'Cho t\u00f4i h\u1ecfi \u0111\u01a1n ML-20260528-0001 khi n\u00e0o giao?',
            createdAt: createdAt,
          ),
          ChatMessage(
            id: 'mock-message-2',
            roomId: defaultRoomId,
            senderType: ChatSenderType.staff,
            content:
                '\u0110\u01a1n h\u00e0ng \u0111ang \u0111\u01b0\u1ee3c chu\u1ea9n b\u1ecb, d\u1ef1 ki\u1ebfn giao trong h\u00f4m nay.',
            createdAt: createdAt.add(const Duration(minutes: 4)),
          ),
          ChatMessage(
            id: 'mock-message-3',
            roomId: defaultRoomId,
            senderType: ChatSenderType.aiSample,
            content:
                'M\u1eabu g\u1ee3i \u00fd: nh\u00e2n vi\u00ean c\u00f3 th\u1ec3 ki\u1ec3m tra m\u00e3 \u0111\u01a1n v\u00e0 ph\u1ea3n h\u1ed3i nhanh.',
            createdAt: createdAt.add(const Duration(minutes: 5)),
          ),
        ],
      ),
      emptyRoomId: const ChatThread(
        roomId: emptyRoomId,
        isClosed: false,
        messages: [],
      ),
    };
  }
}
