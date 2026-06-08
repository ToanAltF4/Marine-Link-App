import '../../../core/api/api_response.dart';
import '../domain/chat.dart';
import '../domain/chat_repository.dart';

class ChatMockRepository implements ChatRepository {
  static const defaultRoomId = '550e8400-e29b-41d4-a716-44665544000a';
  static const emptyRoomId = '550e8400-e29b-41d4-a716-4466554400ee';
  static const closedRoomId = '550e8400-e29b-41d4-a716-4466554400cc';
  static const orderComplaintRoomId = '550e8400-e29b-41d4-a716-4466554400dd';

  final Map<String, ChatThread> _threads;
  final Map<String, StaffChatRoom> _rooms;
  final List<StaffChatComplaint> _complaints = [];

  ChatMockRepository({
    Map<String, ChatThread>? threads,
    Map<String, StaffChatRoom>? rooms,
  }) : _threads = threads ?? _seedThreads(),
       _rooms = rooms ?? _seedRooms();

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
  Future<ApiResponse<ChatThread>> getMyRoom() => getThread(defaultRoomId);

  @override
  Future<ApiResponse<ChatThread>> getOrderRoom(String orderId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return getThread(orderComplaintRoomId);
  }

  @override
  Future<ApiResponse<List<StaffChatRoom>>> getStaffRooms({
    StaffChatRoomFilter filter = StaffChatRoomFilter.open,
    String? query,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final normalizedQuery = query?.trim().toLowerCase();
    final rooms =
        _rooms.values.where((room) {
          final matchesFilter = switch (filter) {
            StaffChatRoomFilter.open => !room.isClosed,
            StaffChatRoomFilter.closed => room.isClosed,
            StaffChatRoomFilter.all => true,
          };
          if (!matchesFilter) return false;
          if (normalizedQuery == null || normalizedQuery.isEmpty) return true;
          final customer = room.customer;
          return customer.fullName.toLowerCase().contains(normalizedQuery) ||
              customer.email.toLowerCase().contains(normalizedQuery) ||
              customer.phone.contains(normalizedQuery);
        }).toList()..sort((a, b) {
          final left = a.lastMessageAt ?? a.createdAt ?? DateTime(1970);
          final right = b.lastMessageAt ?? b.createdAt ?? DateTime(1970);
          return right.compareTo(left);
        });
    return ApiResponse(success: true, message: 'OK', data: rooms);
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

    final now = DateTime.now().toUtc();
    final message = ChatMessage(
      id: 'mock-message-${thread.messages.length + 1}',
      roomId: roomId,
      senderType: sendAsStaff ? ChatSenderType.staff : ChatSenderType.user,
      content: trimmed,
      createdAt: now,
    );
    final updatedMessages = [...thread.messages, message];
    _threads[roomId] = thread.copyWith(messages: updatedMessages);
    final currentRoom = _rooms[roomId];
    if (currentRoom != null) {
      _rooms[roomId] = currentRoom.copyWith(
        lastMessageAt: now,
        updatedAt: now,
        messageCount: updatedMessages.length,
        lastMessage: message,
        summary: _summary(updatedMessages),
      );
    }

    return ApiResponse(success: true, message: 'Message sent', data: message);
  }

  @override
  Future<ApiResponse<StaffChatRoom>> setRoomClosed({
    required String roomId,
    required bool isClosed,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final room = _rooms[roomId];
    final thread = _threads[roomId];
    if (room == null || thread == null) {
      return const ApiResponse(
        success: false,
        message: 'Kh\u00f4ng t\u00ecm th\u1ea5y ph\u00f2ng chat.',
      );
    }
    final updatedRoom = room.copyWith(
      isClosed: isClosed,
      updatedAt: DateTime.now().toUtc(),
    );
    _rooms[roomId] = updatedRoom;
    _threads[roomId] = thread.copyWith(isClosed: isClosed);
    return ApiResponse(
      success: true,
      message: 'Chat room status updated',
      data: updatedRoom,
    );
  }

  @override
  Future<ApiResponse<StaffChatComplaint>> createComplaint({
    required String roomId,
    required String title,
    required String description,
    String? messageId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final trimmedTitle = title.trim();
    final trimmedDescription = description.trim();
    if (trimmedTitle.isEmpty || trimmedDescription.isEmpty) {
      return const ApiResponse(
        success: false,
        message:
            'Vui l\u00f2ng nh\u1eadp ti\u00eau \u0111\u1ec1 v\u00e0 m\u00f4 t\u1ea3 khi\u1ebfu n\u1ea1i.',
      );
    }
    if (!_rooms.containsKey(roomId)) {
      return const ApiResponse(
        success: false,
        message: 'Kh\u00f4ng t\u00ecm th\u1ea5y ph\u00f2ng chat.',
      );
    }
    final complaint = StaffChatComplaint(
      id: 'mock-complaint-${_complaints.length + 1}',
      roomId: roomId,
      messageId: messageId,
      title: trimmedTitle,
      description: trimmedDescription,
      status: 'OPEN',
      createdAt: DateTime.now().toUtc(),
    );
    _complaints.add(complaint);
    return ApiResponse(
      success: true,
      message: 'Complaint created',
      data: complaint,
    );
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
      closedRoomId: ChatThread(
        roomId: closedRoomId,
        isClosed: true,
        messages: [
          ChatMessage(
            id: 'mock-message-closed-1',
            roomId: closedRoomId,
            senderType: ChatSenderType.user,
            content:
                'T\u00f4i \u0111\u00e3 nh\u1eadn \u0111\u1ee7 h\u00e0ng, c\u1ea3m \u01a1n.',
            createdAt: createdAt.subtract(const Duration(hours: 3)),
          ),
        ],
      ),
      orderComplaintRoomId: ChatThread(
        roomId: orderComplaintRoomId,
        isClosed: false,
        messages: [
          ChatMessage(
            id: 'mock-message-order-complaint-1',
            roomId: orderComplaintRoomId,
            senderType: ChatSenderType.aiSample,
            content:
                'Khi\u1ebfu n\u1ea1i \u0111\u01a1n h\u00e0ng ML-20260526-0001\nS\u1ea3n ph\u1ea9m: Kh\u00f4 c\u00e1 l\u00f3c\nT\u1ed5ng ti\u1ec1n: 7800000 VND\nVui l\u00f2ng m\u00f4 t\u1ea3 v\u1ea5n \u0111\u1ec1 c\u1ea7n h\u1ed7 tr\u1ee3.',
            createdAt: createdAt.add(const Duration(minutes: 12)),
          ),
        ],
      ),
    };
  }

  static Map<String, StaffChatRoom> _seedRooms() {
    final threads = _seedThreads();
    return {
      defaultRoomId: _roomFromThread(
        thread: threads[defaultRoomId]!,
        customer: const StaffChatCustomer(
          id: '550e8400-e29b-41d4-a716-446655440003',
          fullName: '\u0110\u1ea1i l\u00fd H\u1ea3i S\u1ea3n A',
          email: 'daily-a@marinelink.demo',
          phone: '0901000001',
        ),
        assignedStaff: const StaffChatAssignee(
          id: '550e8400-e29b-41d4-a716-446655440004',
          fullName: 'Staff Demo',
        ),
      ),
      emptyRoomId: _roomFromThread(
        thread: threads[emptyRoomId]!,
        customer: const StaffChatCustomer(
          id: '550e8400-e29b-41d4-a716-446655440013',
          fullName: '\u0110\u1ea1i l\u00fd M\u1ef1c Kh\u00f4 B',
          email: 'daily-b@marinelink.demo',
          phone: '0901000002',
        ),
      ),
      closedRoomId: _roomFromThread(
        thread: threads[closedRoomId]!,
        customer: const StaffChatCustomer(
          id: '550e8400-e29b-41d4-a716-446655440023',
          fullName: '\u0110\u1ea1i l\u00fd T\u00f4m Kh\u00f4 C',
          email: 'daily-c@marinelink.demo',
          phone: '0901000003',
        ),
        assignedStaff: const StaffChatAssignee(
          id: '550e8400-e29b-41d4-a716-446655440004',
          fullName: 'Staff Demo',
        ),
      ),
      orderComplaintRoomId: _roomFromThread(
        thread: threads[orderComplaintRoomId]!,
        customer: const StaffChatCustomer(
          id: '550e8400-e29b-41d4-a716-446655440003',
          fullName: '\u0110\u1ea1i l\u00fd H\u1ea3i S\u1ea3n A',
          email: 'daily-a@marinelink.demo',
          phone: '0901000001',
        ),
      ),
    };
  }

  static StaffChatRoom _roomFromThread({
    required ChatThread thread,
    required StaffChatCustomer customer,
    StaffChatAssignee? assignedStaff,
  }) {
    final lastMessage = thread.messages.isEmpty ? null : thread.messages.last;
    final createdAt = thread.messages.isEmpty
        ? DateTime.utc(2026, 5, 28, 7, 30)
        : thread.messages.first.createdAt;
    return StaffChatRoom(
      roomId: thread.roomId,
      customer: customer,
      assignedStaff: assignedStaff,
      isClosed: thread.isClosed,
      lastMessageAt: lastMessage?.createdAt,
      createdAt: createdAt,
      updatedAt: lastMessage?.createdAt ?? createdAt,
      messageCount: thread.messages.length,
      lastMessage: lastMessage,
      summary: _summary(thread.messages),
    );
  }

  static String _summary(List<ChatMessage> messages) {
    if (messages.isEmpty) {
      return 'Ch\u01b0a c\u00f3 l\u1ecbch s\u1eed trao \u0111\u1ed5i.';
    }
    final recent = messages.skip(messages.length > 3 ? messages.length - 3 : 0);
    return recent
        .map(
          (message) =>
              '${_senderLabel(message.senderType)}: ${message.content}',
        )
        .join(' | ');
  }
}

String _senderLabel(ChatSenderType type) {
  return switch (type) {
    ChatSenderType.user => '\u0110\u1ea1i l\u00fd',
    ChatSenderType.staff => 'Nh\u00e2n vi\u00ean',
    ChatSenderType.aiSample => 'G\u1ee3i \u00fd',
  };
}
