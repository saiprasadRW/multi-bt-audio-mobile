import 'dart:io';
import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';

class HowItWorks extends StatelessWidget {
  const HowItWorks({super.key});

  @override
  Widget build(BuildContext context) {
    final steps = [
      _Step('1', AppStrings.step1, Icons.bluetooth_searching),
      _Step('2', AppStrings.step2, Icons.play_circle_outline),
      _Step(
        '3',
        Platform.isIOS ? AppStrings.step3iOS : AppStrings.step3Android,
        Icons.security,
      ),
      _Step('4', AppStrings.step4, Icons.music_note),
      _Step('5', AppStrings.step5, Icons.celebration),
    ];

    return Card(
      color: AppColors.surfaceLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.help_outline, color: AppColors.accent, size: 22),
                SizedBox(width: 8),
                Text(
                  'How It Works',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              Platform.isIOS ? 'iOS Audio Routing' : 'Android Audio Capture',
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ...steps.map((step) => _buildStep(step)),
            if (Platform.isIOS) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade900.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.apple, color: Colors.white70, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        AppStrings.iosLimitation,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStep(_Step step) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.primary,
            child: Text(
              step.number,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(step.icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              step.text,
              style:
                  const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step {
  final String number;
  final String text;
  final IconData icon;

  _Step(this.number, this.text, this.icon);
}
