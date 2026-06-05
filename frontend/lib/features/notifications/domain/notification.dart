import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

enum NotificationType {
  promotion,
  product,
  order,
  chat,
  system;

  static NotificationType fromString(String value) {
    return switch (value.toUpperCase()) {
      'PROMOTION' => NotificationType.promotion,
      'PRODUCT' => NotificationType.product,
      'ORDER' => NotificationType.order,
      'CHAT' => NotificationType.chat,
      'SYSTEM' => NotificationType.system,
      _ => NotificationType.system,
    };
  }

  String get apiValue => name.toUpperCase();
}

class NotificationEntity extends Equatable {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String? relatedId;

  const NotificationEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    this.relatedId,
  });

  NotificationEntity copyWith({bool? isRead}) {
    return NotificationEntity(
      id: id,
      type: type,
      title: title,
      message: message,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      relatedId: relatedId,
    );
  }

  @override
  List<Object?> get props => [id, isRead];
}
