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

String _stringOrEmpty(dynamic value) {
  if (value == null) return '';
  if (value is num) {
    final parsed = _toNum(value);
    return parsed % 1 == 0 ? parsed.toInt().toString() : parsed.toString();
  }
  return value.toString();
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
