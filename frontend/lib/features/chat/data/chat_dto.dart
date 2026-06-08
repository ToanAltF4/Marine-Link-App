import '../domain/chat.dart';

ChatThread chatThreadFromJson(dynamic json) {
  final map = json as Map<String, dynamic>? ?? const <String, dynamic>{};
  final messages = (map['messages'] as List<dynamic>? ?? const [])
      .whereType<Map<String, dynamic>>()
      .map(chatMessageFromJson)
      .toList();

  return ChatThread(
    roomId: _stringOrEmpty(map['roomId'] ?? map['id'] ?? map['publicId']),
    isClosed: _toBool(map['isClosed'] ?? map['closed']),
    messages: messages,
  );
}

ChatMessage chatMessageFromJson(dynamic json) {
  final map = json as Map<String, dynamic>? ?? const <String, dynamic>{};
  return ChatMessage(
    id: _stringOrEmpty(map['id'] ?? map['publicId'] ?? map['public_id']),
    roomId: _stringOrEmpty(map['roomId'] ?? map['room_id']),
    senderType: _senderTypeFromJson(map['senderType'] ?? map['sender_type']),
    content: _stringOrEmpty(map['content']),
    createdAt: _dateTimeFromJson(map['createdAt'] ?? map['created_at']),
    attachments: (map['attachments'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(chatAttachmentFromJson)
        .toList(),
  );
}

ChatAttachment chatAttachmentFromJson(dynamic json) {
  final map = json as Map<String, dynamic>? ?? const <String, dynamic>{};
  return ChatAttachment(
    id: _stringOrEmpty(map['id'] ?? map['publicId'] ?? map['public_id']),
    storageBucket: _stringOrEmpty(
      map['storageBucket'] ?? map['storage_bucket'],
    ),
    storagePath: _stringOrEmpty(map['storagePath'] ?? map['storage_path']),
    fileName: _stringOrEmpty(map['fileName'] ?? map['file_name']),
    mimeType: _stringOrEmpty(map['mimeType'] ?? map['mime_type']),
    fileSizeBytes: _toInt(map['fileSizeBytes'] ?? map['file_size_bytes']),
  );
}

List<StaffChatRoom> staffChatRoomsFromJson(dynamic json) {
  final list = json as List<dynamic>? ?? const [];
  return list
      .whereType<Map<String, dynamic>>()
      .map(staffChatRoomFromJson)
      .toList();
}

StaffChatRoom staffChatRoomFromJson(dynamic json) {
  final map = json as Map<String, dynamic>? ?? const <String, dynamic>{};
  return StaffChatRoom(
    roomId: _stringOrEmpty(map['roomId'] ?? map['room_id'] ?? map['id']),
    customer: staffChatCustomerFromJson(map['customer']),
    assignedStaff: map['assignedStaff'] == null && map['assigned_staff'] == null
        ? null
        : staffChatAssigneeFromJson(
            map['assignedStaff'] ?? map['assigned_staff'],
          ),
    isClosed: _toBool(map['isClosed'] ?? map['is_closed'] ?? map['closed']),
    lastMessageAt: _dateTimeFromJson(
      map['lastMessageAt'] ?? map['last_message_at'],
    ),
    createdAt: _dateTimeFromJson(map['createdAt'] ?? map['created_at']),
    updatedAt: _dateTimeFromJson(map['updatedAt'] ?? map['updated_at']),
    messageCount: _toInt(map['messageCount'] ?? map['message_count']),
    lastMessage: map['lastMessage'] == null && map['last_message'] == null
        ? null
        : chatMessageFromJson(map['lastMessage'] ?? map['last_message']),
    context: map['context'] == null
        ? null
        : staffChatContextFromJson(map['context']),
    summary: _stringOrEmpty(map['summary']),
  );
}

StaffChatContext staffChatContextFromJson(dynamic json) {
  final map = json as Map<String, dynamic>? ?? const <String, dynamic>{};
  return StaffChatContext(
    orderId: _nullableString(map['orderId'] ?? map['order_id']),
    orderCode: _nullableString(map['orderCode'] ?? map['order_code']),
    orderStatus: _nullableString(map['orderStatus'] ?? map['order_status']),
    orderTotalAmount:
        map['orderTotalAmount'] == null && map['order_total_amount'] == null
        ? null
        : _toNum(map['orderTotalAmount'] ?? map['order_total_amount']),
    productId: _nullableString(map['productId'] ?? map['product_id']),
    productName: _nullableString(map['productName'] ?? map['product_name']),
    productImageUrl: _nullableString(
      map['productImageUrl'] ?? map['product_image_url'],
    ),
  );
}

StaffChatCustomer staffChatCustomerFromJson(dynamic json) {
  final map = json as Map<String, dynamic>? ?? const <String, dynamic>{};
  return StaffChatCustomer(
    id: _stringOrEmpty(map['id'] ?? map['publicId'] ?? map['public_id']),
    fullName: _stringOrEmpty(map['fullName'] ?? map['full_name']),
    email: _stringOrEmpty(map['email']),
    phone: _stringOrEmpty(map['phone']),
  );
}

StaffChatAssignee staffChatAssigneeFromJson(dynamic json) {
  final map = json as Map<String, dynamic>? ?? const <String, dynamic>{};
  return StaffChatAssignee(
    id: _stringOrEmpty(map['id'] ?? map['publicId'] ?? map['public_id']),
    fullName: _stringOrEmpty(map['fullName'] ?? map['full_name']),
  );
}

StaffChatRoom staffChatRoomStatusFromJson(dynamic json) {
  final map = json as Map<String, dynamic>? ?? const <String, dynamic>{};
  return StaffChatRoom(
    roomId: _stringOrEmpty(map['roomId'] ?? map['room_id'] ?? map['id']),
    customer: const StaffChatCustomer(
      id: '',
      fullName: '',
      email: '',
      phone: '',
    ),
    isClosed: _toBool(map['isClosed'] ?? map['is_closed'] ?? map['closed']),
    messageCount: 0,
    summary: '',
  );
}

StaffChatComplaint staffChatComplaintFromJson(dynamic json) {
  final map = json as Map<String, dynamic>? ?? const <String, dynamic>{};
  return StaffChatComplaint(
    id: _stringOrEmpty(map['id'] ?? map['publicId'] ?? map['public_id']),
    roomId: _stringOrEmpty(map['roomId'] ?? map['room_id']),
    messageId: _nullableString(map['messageId'] ?? map['message_id']),
    title: _stringOrEmpty(map['title']),
    description: _stringOrEmpty(map['description']),
    status: _stringOrEmpty(map['status']),
    createdAt: _dateTimeFromJson(map['createdAt'] ?? map['created_at']),
  );
}

String _stringOrEmpty(dynamic value) {
  if (value == null) return '';
  if (value is num) {
    final parsed = _toNum(value);
    return parsed % 1 == 0 ? parsed.toInt().toString() : parsed.toString();
  }
  return value.toString();
}

String? _nullableString(dynamic value) {
  final text = _stringOrEmpty(value);
  return text.isEmpty ? null : text;
}

ChatSenderType _senderTypeFromJson(dynamic value) {
  return switch (value?.toString().toUpperCase()) {
    'STAFF' => ChatSenderType.staff,
    'AI_SAMPLE' => ChatSenderType.aiSample,
    _ => ChatSenderType.user,
  };
}

DateTime? _dateTimeFromJson(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

bool _toBool(dynamic value) {
  if (value is bool) return value;
  return value?.toString().toLowerCase() == 'true';
}

int _toInt(dynamic value) {
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

num _toNum(dynamic value) {
  if (value is num) return value;
  return num.tryParse('$value') ?? 0;
}
