import 'dart:io';
import 'package:multi_bt_audio/core/errors/error_handler.dart';
import 'package:multi_bt_audio/core/platform/platform_channel.dart';
import 'package:multi_bt_audio/core/utils/logger.dart';
import 'package:multi_bt_audio/models/bt_device.dart';

class BluetoothService {
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

  Future<bool> isBluetoothEnabled() async {
    try {
      final result = await PlatformChannel.invoke<bool>('isBluetoothEnabled');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<int> getMaxConnections() async {
    if (Platform.isIOS) return 2; // iOS typically supports 2
    try {
      final result = await PlatformChannel.invoke<int>('getMaxConnections');
      return result ?? 5;
    } catch (e) {
      return 5;
    }
  }
}
