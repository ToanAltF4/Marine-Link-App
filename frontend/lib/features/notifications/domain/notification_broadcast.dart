import 'package:equatable/equatable.dart';

/// A broadcast notification created by admin/staff and fanned out to dealers.
/// One row in the "sent notifications" history.
class NotificationBroadcast extends Equatable {
  final String broadcastId;
  final String title;
  final String body;
  final String? createdBy;
  final DateTime createdAt;
  final int recipientCount;

  const NotificationBroadcast({
    required this.broadcastId,
    required this.title,
    required this.body,
    required this.createdAt,
    this.createdBy,
    this.recipientCount = 0,
  });

  @override
  List<Object?> get props => [
    broadcastId,
    title,
    body,
    createdBy,
    createdAt,
    recipientCount,
  ];
}
