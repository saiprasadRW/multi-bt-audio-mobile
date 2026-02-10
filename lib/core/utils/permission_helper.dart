import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import '../constants/app_enums.dart';
import '../errors/app_exception.dart';
import 'logger.dart';

class PermissionHelper {
  static Future<Map<PermissionType, bool>> requestAllPermissions() async {
    final results = <PermissionType, bool>{};

    if (Platform.isAndroid) {
      results[PermissionType.bluetooth] = await _requestPermission(
        Permission.bluetoothConnect,
        PermissionType.bluetooth,
      );

      await _requestPermission(
        Permission.bluetoothScan,
        PermissionType.bluetooth,
      );

      results[PermissionType.location] = await _requestPermission(
        Permission.locationWhenInUse,
        PermissionType.location,
      );

      results[PermissionType.microphone] = await _requestPermission(
        Permission.microphone,
        PermissionType.microphone,
      );
    } else if (Platform.isIOS) {
      results[PermissionType.bluetooth] = await _requestPermission(
        Permission.bluetooth,
        PermissionType.bluetooth,
      );
    }

    return results;
  }

  static Future<bool> _requestPermission(
    Permission permission,
    PermissionType type,
  ) async {
    try {
      final status = await permission.request();

      if (status.isGranted) {
        AppLogger.info('Permission granted: $type');
        return true;
      }

      if (status.isPermanentlyDenied) {
        AppLogger.warning('Permission permanently denied: $type');
        throw PermissionException(
          message: 'Permission permanently denied: $type',
          permissionType: type,
          userMessage:
              'Please enable this permission in Settings → App Permissions',
        );
      }

      AppLogger.warning('Permission denied: $type');
      return false;
    } catch (e) {
      if (e is PermissionException) rethrow;
      AppLogger.error('Permission request failed: $type', e);
      return false;
    }
  }

  static Future<bool> checkPermission(Permission permission) async {
    final status = await permission.status;
    return status.isGranted;
  }

  static Future<void> openSettings() async {
    await openAppSettings();
  }
}
