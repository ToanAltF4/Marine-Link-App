import '../../../core/api/api_response.dart';
import 'chat.dart';

abstract class ChatRepository {
  Future<ApiResponse<ChatThread>> getThread(String roomId);

  /// Lấy (hoặc tạo) phòng hỗ trợ chung của user hiện tại — dùng cho tab Chat buyer.
  Future<ApiResponse<ChatThread>> getMyRoom();

  Future<ApiResponse<ChatThread>> getOrderRoom(String orderId);

  Future<ApiResponse<List<StaffChatRoom>>> getStaffRooms({
    StaffChatRoomFilter filter = StaffChatRoomFilter.open,
    String? query,
  });

  Future<ApiResponse<ChatMessage>> sendMessage({
    required String roomId,
    required String content,
    bool sendAsStaff = false,
  });

  Future<ApiResponse<StaffChatRoom>> setRoomClosed({
    required String roomId,
    required bool isClosed,
  });

  Future<ApiResponse<StaffChatComplaint>> createComplaint({
    required String roomId,
    required String title,
    required String description,
    String? messageId,
  });
}
