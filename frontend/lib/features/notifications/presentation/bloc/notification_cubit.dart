import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/notification.dart';
import '../../domain/notification_repository.dart';

part 'notification_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  final NotificationRepository notificationRepository;

  NotificationCubit({required this.notificationRepository}) : super(const NotificationState());

  Future<void> loadNotifications() async {
    emit(state.copyWith(status: NotificationStatus.loading));
    
    final response = await notificationRepository.getNotifications();
    
    if (response.success && response.data != null) {
      emit(state.copyWith(
        status: NotificationStatus.success,
        notifications: response.data,
      ));
    } else {
      emit(state.copyWith(status: NotificationStatus.failure));
    }
  }

  Future<void> markAsRead(String id) async {
    final response = await notificationRepository.markAsRead(id);
    if (response.success) {
      final updatedList = state.notifications.map((n) {
        return n.id == id ? n.copyWith(isRead: true) : n;
      }).toList();
      emit(state.copyWith(notifications: updatedList));
    }
  }
}
