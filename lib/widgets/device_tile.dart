import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_enums.dart';
import '../models/bt_device.dart';

class DeviceTile extends StatelessWidget {
  final BTDevice device;
  final VoidCallback? onConnect;
  final VoidCallback? onDisconnect;
  final bool showActions;

  const DeviceTile({
    super.key,
    required this.device,
    this.onConnect,
    this.onDisconnect,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _getCardColor(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: ListTile(
          leading: _buildLeading(),
          title: Text(
            device.name,
            style: TextStyle(
              fontWeight:
                  device.isConnected ? FontWeight.bold : FontWeight.normal,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: _buildSubtitle(),
          trailing: showActions ? _buildTrailing() : null,
        ),
      ),
    );
  }

  Color _getCardColor() {
    switch (device.status) {
      case DeviceConnectionStatus.connected:
        return AppColors.success.withOpacity(0.15);
      case DeviceConnectionStatus.connecting:
      case DeviceConnectionStatus.disconnecting:
        return AppColors.warning.withOpacity(0.15);
      case DeviceConnectionStatus.failed:
        return AppColors.error.withOpacity(0.15);
      default:
        return AppColors.surfaceLight;
    }
  }

  Widget _buildLeading() {
    IconData icon;
    Color color;

    switch (device.status) {
      case DeviceConnectionStatus.connected:
        icon = Icons.headphones;
        color = AppColors.success;
        break;
      case DeviceConnectionStatus.connecting:
        return const SizedBox(
          width: 40,
          height: 40,
          child: Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      case DeviceConnectionStatus.failed:
        icon = Icons.error_outline;
        color = AppColors.error;
        break;
      default:
        icon = Icons.bluetooth;
        color = AppColors.disconnected;
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.2),
      child: Icon(icon, color: color),
    );
  }

  Widget? _buildSubtitle() {
    if (device.isFailed && device.errorMessage != null) {
      return Text(
        device.errorMessage!,
        style: const TextStyle(color: AppColors.error, fontSize: 12),
      );
    }

    if (device.isConnecting) {
      return const Text(
        'Connecting...',
        style: TextStyle(color: AppColors.warning, fontSize: 12),
      );
    }

    String subtitle = device.address;
    if (device.isConnected) {
      subtitle = '✓ Connected';
    }

    return Text(
      subtitle,
      style: TextStyle(
        fontSize: 12,
        color: device.isConnected ? AppColors.success : AppColors.textSecondary,
      ),
    );
  }

  Widget? _buildTrailing() {
    if (device.isConnecting) return null;

    if (device.isConnected) {
      return IconButton(
        icon: const Icon(Icons.link_off, color: AppColors.error),
        onPressed: onDisconnect,
        tooltip: 'Disconnect',
      );
    }

    return ElevatedButton(
      onPressed: onConnect,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      child: const Text('Connect'),
    );
  }
}
