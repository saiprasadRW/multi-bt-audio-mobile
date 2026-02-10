import 'dart:io';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';

class PermissionSheet extends StatelessWidget {
  final VoidCallback onGrantPermissions;

  const PermissionSheet({super.key, required this.onGrantPermissions});

  static Future<void> show(BuildContext context, VoidCallback onGrant) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PermissionSheet(onGrantPermissions: onGrant),
    );
  }

  @override
  Widget build(BuildContext context) {
    final permissions = <_PermInfo>[
      _PermInfo(
        Icons.bluetooth,
        AppStrings.bluetoothPermTitle,
        AppStrings.bluetoothPermDesc,
        true,
      ),
      if (Platform.isAndroid) ...[
        _PermInfo(
          Icons.location_on,
          AppStrings.locationPermTitle,
          AppStrings.locationPermDesc,
          true,
        ),
        _PermInfo(
          Icons.mic,
          AppStrings.micPermTitle,
          AppStrings.micPermDesc,
          true,
        ),
      ],
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white30,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Icon(Icons.security, size: 48, color: AppColors.accent),
          const SizedBox(height: 16),
          const Text(
            'Permissions Required',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'These permissions are needed for the app to work properly',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ...permissions.map((p) => _buildPermItem(p)),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onGrantPermissions();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'GRANT PERMISSIONS',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPermItem(_PermInfo info) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withOpacity(0.2),
            child: Icon(info.icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      info.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (info.required_) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Required',
                          style:
                              TextStyle(color: AppColors.error, fontSize: 10),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  info.description,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PermInfo {
  final IconData icon;
  final String title;
  final String description;
  final bool required_;

  _PermInfo(this.icon, this.title, this.description, this.required_);
}
