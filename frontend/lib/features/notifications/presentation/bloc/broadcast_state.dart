part of 'broadcast_cubit.dart';

enum BroadcastStatus { initial, loading, ready, failure }

class BroadcastState extends Equatable {
  final BroadcastStatus status;
  final List<NotificationBroadcast> broadcasts;
  final bool submitting;
  final String? errorMessage;
  final String? infoMessage;

  const BroadcastState({
    this.status = BroadcastStatus.initial,
    this.broadcasts = const [],
    this.submitting = false,
    this.errorMessage,
    this.infoMessage,
  });

  BroadcastState copyWith({
    BroadcastStatus? status,
    List<NotificationBroadcast>? broadcasts,
    bool? submitting,
    String? errorMessage,
    String? infoMessage,
    bool clearError = false,
    bool clearInfo = false,
  }) {
    return BroadcastState(
      status: status ?? this.status,
      broadcasts: broadcasts ?? this.broadcasts,
      submitting: submitting ?? this.submitting,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      infoMessage: clearInfo ? null : infoMessage ?? this.infoMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    broadcasts,
    submitting,
    errorMessage,
    infoMessage,
  ];
}
