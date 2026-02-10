import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../core/constants/app_enums.dart';
import '../core/constants/app_strings.dart';
import '../core/errors/error_handler.dart';
import '../core/utils/logger.dart';
import '../models/broadcast_state.dart';
import '../services/audio_capture_service.dart';

class BroadcastProvider extends ChangeNotifier {
  final AudioCaptureService _captureService = AudioCaptureService();

  BroadcastState _state = const BroadcastState();
  Timer? _durationTimer;

  BroadcastState get state => _state;

  Future<bool> startBroadcast(int connectedDeviceCount) async {
    if (connectedDeviceCount < 2) {
      _state = _state.copyWith(
        status: BroadcastStatus.error,
        errorMessage: AppStrings.needMoreDevices,
        errorSeverity: ErrorSeverity.warning,
      );
      notifyListeners();
      return false;
    }

    _state = _state.copyWith(
      status: BroadcastStatus.starting,
      message: 'Starting broadcast...',
      connectedDeviceCount: connectedDeviceCount,
    );
    notifyListeners();

    try {
      final success = await _captureService.startCapture();

      if (success) {
        _state = _state.copyWith(
          status: BroadcastStatus.broadcasting,
          message: _getBroadcastMessage(connectedDeviceCount),
          startedAt: DateTime.now(),
          connectedDeviceCount: connectedDeviceCount,
        );

        _startDurationTimer();
        AppLogger.info('Broadcast started to $connectedDeviceCount devices');
      } else {
        _state = _state.copyWith(
          status: BroadcastStatus.error,
          errorMessage: AppStrings.captureStartFailed,
          errorSeverity: ErrorSeverity.error,
        );
      }

      notifyListeners();
      return success;
    } catch (e, st) {
      final error = ErrorHandler.handle(e, st);
      _state = _state.copyWith(
        status: BroadcastStatus.error,
        errorMessage: ErrorHandler.getUserFriendlyMessage(error),
        errorSeverity: error.severity,
      );
      AppLogger.logException(error);
      notifyListeners();
      return false;
    }
  }

  Future<void> stopBroadcast() async {
    _state = _state.copyWith(
      status: BroadcastStatus.stopping,
      message: 'Stopping broadcast...',
    );
    notifyListeners();

    try {
      await _captureService.stopCapture();
      _durationTimer?.cancel();

      _state = const BroadcastState(
        status: BroadcastStatus.idle,
        message: AppStrings.stopped,
      );
      AppLogger.info('Broadcast stopped');
    } catch (e, st) {
      final error = ErrorHandler.handle(e, st);
      _state = _state.copyWith(
        status: BroadcastStatus.error,
        errorMessage: ErrorHandler.getUserFriendlyMessage(error),
      );
      AppLogger.logException(error);
    }

    notifyListeners();
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners(); // Update duration display
    });
  }

  String _getBroadcastMessage(int count) {
    if (Platform.isIOS) {
      return 'Routing audio to $count devices';
    }
    return 'Broadcasting to $count devices - Play audio in any app!';
  }

  void clearError() {
    if (_state.hasError) {
      _state = const BroadcastState();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    super.dispose();
  }
}