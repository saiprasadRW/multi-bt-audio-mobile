import '../core/constants/app_enums.dart';

class AppNotification {
  final String title;
  final String message;
  final ErrorSeverity severity;
  final DateTime timestamp;
  final String? actionLabel;
  final void Function()? onAction;
  bool isDismissed;

  AppNotification({
    required this.title,
    required this.message,
    this.severity = ErrorSeverity.info,
    DateTime? timestamp,
    this.actionLabel,
    this.onAction,
    this.isDismissed = false,
  }) : timestamp = timestamp ?? DateTime.now();
}
