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
}
