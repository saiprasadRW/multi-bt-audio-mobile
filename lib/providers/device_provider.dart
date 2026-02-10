import 'package:flutter/material.dart';
import '../core/constants/app_enums.dart';
import '../core/errors/app_exception.dart';
import '../core/errors/error_handler.dart';
import '../core/utils/logger.dart';
import '../models/bt_device.dart';
import '../services/bluetooth_service.dart';

class DeviceProvider extends ChangeNotifier {
  final BluetoothService _btService = BluetoothService();

  List<BTDevice> _pairedDevices = [];
  List<BTDevice> _connectedDevices = [];
  bool _isLoading = false;
  AppException? _lastError;
  bool _bluetoothEnabled = true;

  // Getters
  List<BTDevice> get pairedDevices => _pairedDevices;
  List<BTDevice> get connectedDevices => _connectedDevices;
  bool get isLoading => _isLoading;
  AppException? get lastError => _lastError;
  bool get bluetoothEnabled => _bluetoothEnabled;
  int get connectedCount => _connectedDevices.length;
  bool get hasEnoughDevices => _connectedDevices.length >= 2;

  List<BTDevice> get disconnectedDevices => _pairedDevices
      .where((d) => !_connectedDevices.any((c) => c.address == d.address))
      .toList();

  Future<void> loadDevices() async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      _bluetoothEnabled = await _btService.isBluetoothEnabled();
      if (!_bluetoothEnabled) {
        _lastError = BluetoothException(
          message: 'Bluetooth is disabled',
          userMessage: 'Please turn on Bluetooth in your device settings',
          severity: ErrorSeverity.warning,
        );
        _isLoading = false;
        notifyListeners();
        return;
      }

      _pairedDevices = await _btService.getPairedDevices();
      _connectedDevices = await _btService.getConnectedAudioDevices();

      // Update status of paired devices
      for (var device in _pairedDevices) {
        if (_connectedDevices.any((c) => c.address == device.address)) {
          device.status = DeviceConnectionStatus.connected;
        }
      }

      AppLogger.info(
        'Loaded ${_pairedDevices.length} paired, '
        '${_connectedDevices.length} connected',
      );
    } catch (e, st) {
      _lastError = ErrorHandler.handle(e, st);
      AppLogger.logException(_lastError!);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> connectDevice(BTDevice device) async {
    device.status = DeviceConnectionStatus.connecting;
    device.errorMessage = null;
    notifyListeners();

    try {
      final success = await _btService.connectDevice(device.address);

      if (success) {
        device.status = DeviceConnectionStatus.connected;
        device.lastConnected = DateTime.now();
        await loadDevices(); // Refresh all
        return true;
      } else {
        device.status = DeviceConnectionStatus.failed;
        device.errorMessage = 'Connection was rejected by the device';
        notifyListeners();
        return false;
      }
    } catch (e, st) {
      final error = ErrorHandler.handle(e, st);
      device.status = DeviceConnectionStatus.failed;
      device.errorMessage = ErrorHandler.getUserFriendlyMessage(error);
      AppLogger.logException(error);
      notifyListeners();
      return false;
    }
  }

  Future<bool> disconnectDevice(BTDevice device) async {
    device.status = DeviceConnectionStatus.disconnecting;
    notifyListeners();

    try {
      await _btService.disconnectDevice(device.address);
      device.status = DeviceConnectionStatus.disconnected;
      await loadDevices();
      return true;
    } catch (e, st) {
      final error = ErrorHandler.handle(e, st);
      device.errorMessage = ErrorHandler.getUserFriendlyMessage(error);
      AppLogger.logException(error);
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }
}
