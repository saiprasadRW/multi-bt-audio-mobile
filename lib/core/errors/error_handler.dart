import 'package:flutter/services.dart' as flutter_services;
import '../constants/app_enums.dart';
import '../constants/app_strings.dart';
import 'app_exception.dart';

class ErrorHandler {
  static AppException handle(dynamic error, [StackTrace? stackTrace]) {
    if (error is AppException) return error;

    if (error is PlatformException) {
      return _handlePlatformException(error, stackTrace);
    }

    if (error is flutter_services.MissingPluginException) {
      return AppException(
        message: error.toString(),
        userMessage: AppStrings.platformNotSupported,
        code: 'MISSING_PLUGIN',
        severity: ErrorSeverity.critical,
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    return AppException(
      message: error.toString(),
      userMessage: AppStrings.unknownError,
      code: 'UNKNOWN',
      severity: ErrorSeverity.error,
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  static AppException _handlePlatformException(
    PlatformException error,
    StackTrace? stackTrace,
  ) {
    switch (error.code) {
      case 'PERMISSION':
      case 'PERM_DENIED':
        return PermissionException(
          message: error.message,
          permissionType: PermissionType.bluetooth,
          userMessage: AppStrings.permissionDenied,
          originalError: error,
          stackTrace: stackTrace,
        );

      case 'BT_DISABLED':
        return BluetoothException(
          message: error.message,
          userMessage: AppStrings.bluetoothDisabled,
          severity: ErrorSeverity.warning,
          originalError: error,
          stackTrace: stackTrace,
        );

      case 'CONNECT_FAILED':
        return BluetoothException(
          message: error.message,
          userMessage: AppStrings.connectionFailed,
          originalError: error,
          stackTrace: stackTrace,
        );

      case 'CAPTURE_DENIED':
        return AudioCaptureException(
          message: error.message,
          userMessage: AppStrings.captureDenied,
          severity: ErrorSeverity.warning,
          originalError: error,
          stackTrace: stackTrace,
        );

      case 'CAPTURE_FAILED':
        return AudioCaptureException(
          message: error.message,
          userMessage: AppStrings.captureStartFailed,
          originalError: error,
          stackTrace: stackTrace,
        );

      case 'DRM_BLOCKED':
        return AudioCaptureException(
          message: error.message,
          userMessage: AppStrings.drmBlocked,
          severity: ErrorSeverity.info,
          originalError: error,
          stackTrace: stackTrace,
        );

      default:
        return AppException(
          message: error.message,
          userMessage: error.message,
          code: error.code,
          originalError: error,
          stackTrace: stackTrace,
        );
    }
  }

  static String getUserFriendlyMessage(AppException exception) {
    return exception.userMessage ?? exception.message;
  }
}