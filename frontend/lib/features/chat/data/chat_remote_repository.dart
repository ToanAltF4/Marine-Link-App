import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_response.dart';
import '../domain/chat.dart';
import '../domain/chat_repository.dart';
import 'chat_dto.dart';

class ChatRemoteRepository implements ChatRepository {
  final ApiClient apiClient;

  const ChatRemoteRepository({required this.apiClient});

  @override
  Future<ApiResponse<ChatThread>> getThread(String roomId) {
    return apiClient.get(
      ApiEndpoints.chatRoom(roomId),
      fromJson: chatThreadFromJson,
    );
  }

  @override
  Future<ApiResponse<List<StaffChatRoom>>> getStaffRooms({
    StaffChatRoomFilter filter = StaffChatRoomFilter.open,
    String? query,
  }) {
    return apiClient.get(
      ApiEndpoints.staffChatRooms,
      queryParameters: {
        'status': _filterToQuery(filter),
        if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      },
      fromJson: staffChatRoomsFromJson,
    );
  }

  @override
  Future<ApiResponse<ChatMessage>> sendMessage({
    required String roomId,
    required String content,
    bool sendAsStaff = false,
  }) {
    return apiClient.post(
      ApiEndpoints.chatSend,
      data: {
        'roomId': roomId,
        'content': content,
        'attachments': const <Map<String, dynamic>>[],
      },
      fromJson: chatMessageFromJson,
    );
  }

  @override
  Future<ApiResponse<StaffChatRoom>> setRoomClosed({
    required String roomId,
    required bool isClosed,
  }) {
    return apiClient.put(
      ApiEndpoints.staffChatRoomStatus(roomId),
      data: {'isClosed': isClosed},
      fromJson: staffChatRoomStatusFromJson,
    );
  }

  @override
  Future<ApiResponse<StaffChatComplaint>> createComplaint({
    required String roomId,
    required String title,
    required String description,
    String? messageId,
  }) {
    return apiClient.post(
      ApiEndpoints.staffChatRoomComplaints(roomId),
      data: {
        'title': title,
        'description': description,
        if (messageId != null && messageId.isNotEmpty) 'messageId': messageId,
      },
      fromJson: staffChatComplaintFromJson,
    );
  }
}

String _filterToQuery(StaffChatRoomFilter filter) {
  return switch (filter) {
    StaffChatRoomFilter.open => 'OPEN',
    StaffChatRoomFilter.closed => 'CLOSED',
    StaffChatRoomFilter.all => 'ALL',
  };
}
