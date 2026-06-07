import '../../../core/api/api_response.dart';
import 'chat.dart';

abstract class ChatRepository {
  Future<ApiResponse<ChatThread>> getThread(String roomId);

  Future<ApiResponse<ChatMessage>> sendMessage({
    required String roomId,
    required String content,
    bool sendAsStaff = false,
  });
}
