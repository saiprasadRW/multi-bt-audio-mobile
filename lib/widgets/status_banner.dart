import 'package:flutter/material.dart';
import '../core/constants/app_enums.dart';
import '../core/errors/app_exception.dart';

class StatusBanner extends StatelessWidget {
  final AppException? error;
  final VoidCallback? onDismiss;
  final VoidCallback? onAction;
  final String? actionLabel;

  const StatusBanner({
    super.key,
    this.error,
    this.onDismiss,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (error == null) return const SizedBox.shrink();

    Color bgColor;
    IconData icon;

    switch (error!.severity) {
      case ErrorSeverity.info:
        bgColor = Colors.blue.shade900;
        icon = Icons.info_outline;
        break;
      case ErrorSeverity.warning:
        bgColor = Colors.orange.shade900;
        icon = Icons.warning_amber_rounded;
        break;
      case ErrorSeverity.error:
        bgColor = Colors.red.shade900;
        icon = Icons.error_outline;
        break;
      case ErrorSeverity.critical:
        bgColor = Colors.red.shade800;
        icon = Icons.dangerous;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  error!.userMessage ?? error!.message,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                if (actionLabel != null) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: onAction,
                    child: Text(
                      actionLabel!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70, size: 20),
              onPressed: onDismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }
}
