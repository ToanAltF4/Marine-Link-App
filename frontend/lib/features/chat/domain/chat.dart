import 'package:equatable/equatable.dart';

enum ChatSenderType { user, staff, aiSample }

enum StaffChatRoomFilter { open, closed, all }

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

class StaffChatCustomer extends Equatable {
  final String id;
  final String fullName;
  final String email;
  final String phone;

  const StaffChatCustomer({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
  });

  @override
  List<Object?> get props => [id, fullName, email, phone];
}

class StaffChatAssignee extends Equatable {
  final String id;
  final String fullName;

  const StaffChatAssignee({required this.id, required this.fullName});

  @override
  List<Object?> get props => [id, fullName];
}

class StaffChatContext extends Equatable {
  final String? orderId;
  final String? orderCode;
  final String? orderStatus;
  final num? orderTotalAmount;
  final String? productId;
  final String? productName;
  final String? productImageUrl;

  const StaffChatContext({
    this.orderId,
    this.orderCode,
    this.orderStatus,
    this.orderTotalAmount,
    this.productId,
    this.productName,
    this.productImageUrl,
  });

  bool get hasOrder => orderId != null || orderCode != null;

  bool get hasProduct => productId != null || productName != null;

  @override
  List<Object?> get props => [
    orderId,
    orderCode,
    orderStatus,
    orderTotalAmount,
    productId,
    productName,
    productImageUrl,
  ];
}

class StaffChatRoom extends Equatable {
  final String roomId;
  final StaffChatCustomer customer;
  final StaffChatAssignee? assignedStaff;
  final bool isClosed;
  final DateTime? lastMessageAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int messageCount;
  final ChatMessage? lastMessage;
  final StaffChatContext? context;
  final String summary;

  const StaffChatRoom({
    required this.roomId,
    required this.customer,
    this.assignedStaff,
    required this.isClosed,
    this.lastMessageAt,
    this.createdAt,
    this.updatedAt,
    required this.messageCount,
    this.lastMessage,
    this.context,
    required this.summary,
  });

  StaffChatRoom copyWith({
    StaffChatAssignee? assignedStaff,
    bool? isClosed,
    DateTime? lastMessageAt,
    DateTime? updatedAt,
    int? messageCount,
    ChatMessage? lastMessage,
    StaffChatContext? context,
    String? summary,
  }) {
    return StaffChatRoom(
      roomId: roomId,
      customer: customer,
      assignedStaff: assignedStaff ?? this.assignedStaff,
      isClosed: isClosed ?? this.isClosed,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messageCount: messageCount ?? this.messageCount,
      lastMessage: lastMessage ?? this.lastMessage,
      context: context ?? this.context,
      summary: summary ?? this.summary,
    );
  }

  @override
  List<Object?> get props => [
    roomId,
    customer,
    assignedStaff,
    isClosed,
    lastMessageAt,
    createdAt,
    updatedAt,
    messageCount,
    lastMessage,
    context,
    summary,
  ];
}

class StaffChatComplaint extends Equatable {
  final String id;
  final String roomId;
  final String? messageId;
  final String title;
  final String description;
  final String status;
  final DateTime? createdAt;

  const StaffChatComplaint({
    required this.id,
    required this.roomId,
    this.messageId,
    required this.title,
    required this.description,
    required this.status,
    this.createdAt,
  });

  @override
  List<Object?> get props => [
    id,
    roomId,
    messageId,
    title,
    description,
    status,
    createdAt,
  ];
}
