import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_enums.dart';
import '../models/broadcast_state.dart';

class BroadcastCard extends StatelessWidget {
  final BroadcastState state;
  final int connectedCount;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const BroadcastCard({
    super.key,
    required this.state,
    required this.connectedCount,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: state.isBroadcasting
                ? AppColors.gradientBroadcasting
                : AppColors.gradientIdle,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildIcon(),
            const SizedBox(height: 16),
            _buildTitle(),
            const SizedBox(height: 8),
            _buildMessage(),
            if (state.isBroadcasting) ...[
              const SizedBox(height: 8),
              _buildDuration(),
            ],
            if (state.hasError) ...[
              const SizedBox(height: 12),
              _buildError(),
            ],
            const SizedBox(height: 20),
            _buildButton(),
            if (state.isLoading) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Icon(
        state.isBroadcasting ? Icons.cell_tower : Icons.bluetooth_audio,
        key: ValueKey(state.isBroadcasting),
        size: 64,
        color: Colors.white,
      ),
    );
  }

  Widget _buildTitle() {
    String title;
    switch (state.status) {
      case BroadcastStatus.idle:
        title = 'READY TO BROADCAST';
        break;
      case BroadcastStatus.starting:
        title = 'STARTING...';
        break;
      case BroadcastStatus.broadcasting:
        title = 'BROADCASTING';
        break;
      case BroadcastStatus.stopping:
        title = 'STOPPING...';
        break;
      case BroadcastStatus.error:
        title = 'ERROR';
        break;
    }

    return Text(
      title,
      style: const TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildMessage() {
    return Text(
      state.message,
      style: const TextStyle(color: Colors.white70, fontSize: 14),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDuration() {
    final duration = state.broadcastDuration;
    if (duration == null) return const SizedBox.shrink();

    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$hours:$minutes:$seconds',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontFamily: 'monospace',
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade900.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            state.errorSeverity == ErrorSeverity.warning
                ? Icons.warning_amber_rounded
                : Icons.error_outline,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              state.errorMessage ?? 'Unknown error',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton() {
    if (state.isBroadcasting) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onStop,
          icon: const Icon(Icons.stop_circle, size: 28),
          label: const Text('STOP BROADCAST',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      );
    }

    final canStart = connectedCount >= 2;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: canStart && !state.isLoading ? onStart : null,
        icon: const Icon(Icons.play_circle_fill, size: 28),
        label: Text(
          canStart
              ? 'START BROADCAST'
              : 'CONNECT ${2 - connectedCount} MORE DEVICE(S)',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primary,
          disabledBackgroundColor: Colors.white24,
          disabledForegroundColor: Colors.white54,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
