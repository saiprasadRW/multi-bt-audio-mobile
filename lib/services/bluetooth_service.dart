import 'dart:io';
import 'package:multi_bt_audio/core/errors/error_handler.dart';
import 'package:multi_bt_audio/core/platform/platform_channel.dart';
import 'package:multi_bt_audio/core/utils/logger.dart';
import 'package:multi_bt_audio/models/bt_device.dart';

class BluetoothService {
  /// Get all paired Bluetooth devices (filtered to audio devices only)
  Future<List<BTDevice>> getPairedDevices() async {
    try {
      final List<dynamic>? devices =
          await PlatformChannel.invoke<List<dynamic>>('getPairedDevices');

      if (devices == null) return [];

      return devices
          .map((d) => BTDevice.fromMap(Map<String, dynamic>.from(d)))
          .toList();
    } catch (e, st) {
      AppLogger.error('Failed to get paired devices', e, st);
      throw ErrorHandler.handle(e, st);
    }
  }

  /// Get currently connected audio devices
  Future<List<BTDevice>> getConnectedAudioDevices() async {
    try {
      final List<dynamic>? devices =
          await PlatformChannel.invoke<List<dynamic>>(
              'getConnectedAudioDevices');

      if (devices == null) return [];

      return devices
          .map((d) => BTDevice.fromMap(Map<String, dynamic>.from(d)))
          .toList();
    } catch (e, st) {
      AppLogger.error('Failed to get connected devices', e, st);
      throw ErrorHandler.handle(e, st);
    }
  }

  /// Connect to a Bluetooth device by its MAC address
  Future<bool> connectDevice(String address) async {
    try {
      AppLogger.info('Connecting to device: $address');
      final result = await PlatformChannel.invoke<bool>(
        'connectDevice',
        {'address': address},
      );
      return result ?? false;
    } catch (e, st) {
      AppLogger.error('Failed to connect device: $address', e, st);
      throw ErrorHandler.handle(e, st);
    }
  }

  /// Disconnect from a Bluetooth device by its MAC address
  Future<bool> disconnectDevice(String address) async {
    try {
      AppLogger.info('Disconnecting device: $address');
      final result = await PlatformChannel.invoke<bool>(
        'disconnectDevice',
        {'address': address},
      );
      return result ?? false;
    } catch (e, st) {
      AppLogger.error('Failed to disconnect device: $address', e, st);
      throw ErrorHandler.handle(e, st);
    }
  }

  /// Check if Bluetooth is enabled on the device
  Future<bool> isBluetoothEnabled() async {
    try {
      final result = await PlatformChannel.invoke<bool>('isBluetoothEnabled');
      return result ?? false;
    } catch (e) {
      AppLogger.warning('Failed to check Bluetooth status $e');
      return false;
    }
  }

  /// Get the maximum number of simultaneous Bluetooth connections supported
  /// Note: This is theoretical - actual multi-device playback has limitations
  Future<int> getMaxConnections() async {
    if (Platform.isIOS) return 2; // iOS typically supports 2
    try {
      final result = await PlatformChannel.invoke<int>('getMaxConnections');
      return result ?? 5;
    } catch (e) {
      AppLogger.warning('Failed to get max connections $e');
      return 5;
    }
  }

  /// Connect to multiple devices sequentially
  /// Returns a map of address -> success status
  Future<Map<String, bool>> connectMultipleDevices(
      List<String> addresses) async {
    final results = <String, bool>{};

    for (final address in addresses) {
      try {
        final success = await connectDevice(address);
        results[address] = success;
        // Small delay between connections to avoid overwhelming the BT stack
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        AppLogger.error('Failed to connect to $address in batch', e);
        results[address] = false;
      }
    }

    return results;
  }

  /// Disconnect from multiple devices sequentially
  Future<Map<String, bool>> disconnectMultipleDevices(
      List<String> addresses) async {
    final results = <String, bool>{};

    for (final address in addresses) {
      try {
        final success = await disconnectDevice(address);
        results[address] = success;
      } catch (e) {
        AppLogger.error('Failed to disconnect from $address in batch', e);
        results[address] = false;
      }
    }

    return results;
  }

  /// Check if a specific device is currently connected
  Future<bool> isDeviceConnected(String address) async {
    try {
      final connectedDevices = await getConnectedAudioDevices();
      return connectedDevices.any((device) => device.address == address);
    } catch (e) {
      AppLogger.error('Failed to check device connection status', e);
      return false;
    }
  }
}
