import '../constants/app_enums.dart';

class AppException implements Exception {
  final String message;
  final String? userMessage;
  final String? code;
  final ErrorSeverity severity;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppException({
    required this.message,
    this.userMessage,
    this.code,
    this.severity = ErrorSeverity.error,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => 'AppException[$code]: $message';
}

class BluetoothException extends AppException {
  BluetoothException({
    required super.message,
    super.userMessage,
    super.code = 'BT_ERROR',
    super.severity,
    super.originalError,
    super.stackTrace,
  });
}

class AudioCaptureException extends AppException {
  AudioCaptureException({
    required super.message,
    super.userMessage,
    super.code = 'AUDIO_ERROR',
    super.severity,
    super.originalError,
    super.stackTrace,
  });
}

class PermissionException extends AppException {
  final PermissionType permissionType;

  PermissionException({
    required super.message,
    required this.permissionType,
    super.userMessage,
    super.code = 'PERM_ERROR',
    super.severity = ErrorSeverity.warning,
    super.originalError,
    super.stackTrace,
  });
}

class PlatformException extends AppException {
  PlatformException({
    required super.message,
    super.userMessage,
    super.code = 'PLATFORM_ERROR',
    super.severity = ErrorSeverity.critical,
    super.originalError,
    super.stackTrace,
  });
}
