import 'dart:io';
import '../core/errors/app_exception.dart';
import '../core/errors/error_handler.dart';
import '../core/platform/platform_channel.dart';
import '../core/utils/logger.dart';

class AudioCaptureService {
  Future<bool> startCapture() async {
    try {
      AppLogger.info('Starting system audio capture');

      if (Platform.isAndroid) {
        return await _startAndroidCapture();
      } else if (Platform.isIOS) {
        return await _startiOSCapture();
      }

      throw PlatformException(
        message: 'Unsupported platform',
        userMessage: 'This platform is not supported',
      );
    } catch (e, st) {
      AppLogger.error('Failed to start audio capture', e, st);
      throw ErrorHandler.handle(e, st);
    }
  }

  Future<bool> _startAndroidCapture() async {
    final result =
        await PlatformChannel.invoke<bool>('startSystemAudioCapture');
    return result ?? false;
  }

  Future<bool> _startiOSCapture() async {
    final result = await PlatformChannel.invoke<bool>('startAudioRouting');
    return result ?? false;
  }

  Future<bool> stopCapture() async {
    try {
      AppLogger.info('Stopping audio capture');

      String method =
          Platform.isAndroid ? 'stopSystemAudioCapture' : 'stopAudioRouting';

      final result = await PlatformChannel.invoke<bool>(method);
      return result ?? false;
    } catch (e, st) {
      AppLogger.error('Failed to stop audio capture', e, st);
      throw ErrorHandler.handle(e, st);
    }
  }

  Future<bool> isCapturing() async {
    try {
      final result = await PlatformChannel.invoke<bool>('isCapturing');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getCaptureInfo() async {
    try {
      final result = await PlatformChannel.invoke<Map>('getCaptureInfo');
      if (result == null) return {};
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return {};
    }
  }
}
