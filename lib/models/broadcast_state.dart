import '../core/constants/app_enums.dart';

class BroadcastState {
  final BroadcastStatus status;
  final String message;
  final int connectedDeviceCount;
  final DateTime? startedAt;
  final String? errorMessage;
  final ErrorSeverity? errorSeverity;

  const BroadcastState({
    this.status = BroadcastStatus.idle,
    this.message = 'Ready',
    this.connectedDeviceCount = 0,
    this.startedAt,
    this.errorMessage,
    this.errorSeverity,
  });

  bool get isBroadcasting => status == BroadcastStatus.broadcasting;
  bool get isIdle => status == BroadcastStatus.idle;
  bool get hasError => status == BroadcastStatus.error;
  bool get isLoading =>
      status == BroadcastStatus.starting || status == BroadcastStatus.stopping;

  Duration? get broadcastDuration {
    if (startedAt == null) return null;
    return DateTime.now().difference(startedAt!);
  }

  BroadcastState copyWith({
    BroadcastStatus? status,
    String? message,
    int? connectedDeviceCount,
    DateTime? startedAt,
    String? errorMessage,
    ErrorSeverity? errorSeverity,
  }) {
    return BroadcastState(
      status: status ?? this.status,
      message: message ?? this.message,
      connectedDeviceCount: connectedDeviceCount ?? this.connectedDeviceCount,
      startedAt: startedAt ?? this.startedAt,
      errorMessage: errorMessage,
      errorSeverity: errorSeverity,
    );
  }
}
