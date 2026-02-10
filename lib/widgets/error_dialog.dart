import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_enums.dart';
import '../core/errors/app_exception.dart';
import '../core/utils/permission_helper.dart';

class ErrorDialog extends StatelessWidget {
  final AppException exception;
  final VoidCallback? onRetry;
  final VoidCallback onDismiss;

  const ErrorDialog({
    super.key,
    required this.exception,
    this.onRetry,
    required this.onDismiss,
  });

  static Future<void> show(
    BuildContext context, {
    required AppException exception,
    VoidCallback? onRetry,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => ErrorDialog(
        exception: exception,
        onRetry: onRetry,
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(_getIcon(), color: _getColor(), size: 28),
          const SizedBox(width: 12),
          Text(_getTitle(), style: TextStyle(color: _getColor())),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exception.userMessage ?? exception.message,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
          ),
          if (exception is PermissionException) ...[
            const SizedBox(height: 16),
            _buildPermissionHelp(exception as PermissionException),
          ],
          const SizedBox(height: 8),
          Text(
            'Error code: ${exception.code}',
            style:
                const TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
      actions: [
        if (exception is PermissionException)
          TextButton(
            onPressed: () {
              PermissionHelper.openSettings();
              onDismiss();
            },
            child: const Text('OPEN SETTINGS'),
          ),
        if (onRetry != null)
          TextButton(
            onPressed: () {
              onDismiss();
              onRetry!();
            },
            child: const Text('RETRY'),
          ),
        TextButton(
          onPressed: onDismiss,
          child: const Text('OK'),
        ),
      ],
    );
  }

  Widget _buildPermissionHelp(PermissionException e) {
    String help;
    switch (e.permissionType) {
      case PermissionType.bluetooth:
        help = 'Go to Settings → App Permissions → Bluetooth → Allow';
        break;
      case PermissionType.microphone:
        help = 'Go to Settings → App Permissions → Microphone → Allow';
        break;
      case PermissionType.location:
        help = 'Go to Settings → App Permissions → Location → Allow';
        break;
      case PermissionType.mediaProjection:
        help = 'When prompted, tap "Start now" to allow audio capture';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade900.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.help_outline, color: Colors.white70, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              help,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon() {
    switch (exception.severity) {
      case ErrorSeverity.info:
        return Icons.info_outline;
      case ErrorSeverity.warning:
        return Icons.warning_amber_rounded;
      case ErrorSeverity.error:
        return Icons.error_outline;
      case ErrorSeverity.critical:
        return Icons.dangerous;
    }
  }

  Color _getColor() {
    switch (exception.severity) {
      case ErrorSeverity.info:
        return Colors.blue;
      case ErrorSeverity.warning:
        return AppColors.warning;
      case ErrorSeverity.error:
        return AppColors.error;
      case ErrorSeverity.critical:
        return Colors.red;
    }
  }

  String _getTitle() {
    switch (exception.severity) {
      case ErrorSeverity.info:
        return 'Information';
      case ErrorSeverity.warning:
        return 'Warning';
      case ErrorSeverity.error:
        return 'Error';
      case ErrorSeverity.critical:
        return 'Critical Error';
    }
  }
}
