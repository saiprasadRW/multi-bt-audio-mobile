import 'dart:io';
import 'package:flutter/services.dart';
import '../utils/logger.dart';

class PlatformChannel {
  static const _channelName = 'com.example.multi_bt_audio/audio';
  static const _channel = MethodChannel(_channelName);

  static Future<T?> invoke<T>(String method,
      [Map<String, dynamic>? args]) async {
    try {
      AppLogger.debug('Platform call: $method ${args ?? ''}');
      final result = await _channel.invokeMethod<T>(method, args);
      AppLogger.debug('Platform result: $method → $result');
      return result;
    } on PlatformException catch (e) {
      AppLogger.error('Platform error [$method]: ${e.code} - ${e.message}');
      rethrow;
    } on MissingPluginException catch (e) {
      AppLogger.error('Missing plugin [$method]: ${e.message}');
      rethrow;
    }
  }

  static bool get isAndroid => Platform.isAndroid;
  static bool get isIOS => Platform.isIOS;

  static String get platformName {
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    return 'Unknown';
  }
}
