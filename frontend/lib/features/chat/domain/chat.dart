import 'package:equatable/equatable.dart';

enum ChatSenderType { user, staff, aiSample }

class ChatAttachment extends Equatable {
  final String id;
  final String storageBucket;
  final String storagePath;
  final String fileName;
  final String mimeType;
  final int fileSizeBytes;

  const ChatAttachment({
    required this.id,
    required this.storageBucket,
    required this.storagePath,
    required this.fileName,
    required this.mimeType,
    required this.fileSizeBytes,
  });

  @override
  List<Object?> get props => [
    id,
    storageBucket,
    storagePath,
    fileName,
    mimeType,
    fileSizeBytes,
  ];
}

class ChatMessage extends Equatable {
  final String id;
  final String roomId;
  final ChatSenderType senderType;
  final String content;
  final DateTime? createdAt;
  final List<ChatAttachment> attachments;

  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderType,
    required this.content,
    this.createdAt,
    this.attachments = const [],
  });

  @override
  List<Object?> get props => [
    id,
    roomId,
    senderType,
    content,
    createdAt,
    attachments,
  ];
}

class ChatThread extends Equatable {
  final String roomId;
  final bool isClosed;
  final List<ChatMessage> messages;

  const ChatThread({
    required this.roomId,
    required this.isClosed,
    required this.messages,
  });

  ChatThread copyWith({
    String? roomId,
    bool? isClosed,
    List<ChatMessage>? messages,
  }) {
    return ChatThread(
      roomId: roomId ?? this.roomId,
      isClosed: isClosed ?? this.isClosed,
      messages: messages ?? this.messages,
    );
  }

  @override
  List<Object?> get props => [roomId, isClosed, messages];
}
