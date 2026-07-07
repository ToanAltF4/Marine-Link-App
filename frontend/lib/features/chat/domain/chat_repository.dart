import '../../../core/api/api_response.dart';
import 'chat.dart';

abstract class ChatRepository {
  Future<ApiResponse<ChatThread>> getThread(String roomId);

  /// Lấy (hoặc tạo) phòng hỗ trợ chung của user hiện tại — dùng cho tab Chat buyer.
  Future<ApiResponse<ChatThread>> getMyRoom();

  /// Danh sách lịch sử chat của buyer (mỗi phòng có tiêu đề = tin nhắn đầu tiên).
  Future<ApiResponse<List<ChatRoomSummary>>> getMyRooms();

  /// Tạo cuộc trò chuyện hỗ trợ mới cho buyer ("Cuộc trò chuyện mới").
  Future<ApiResponse<ChatThread>> createRoom();

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
