import 'dart:io';
import '../core/errors/app_exception.dart';
import '../core/errors/error_handler.dart';
import '../core/platform/platform_channel.dart';
import '../core/utils/logger.dart';

enum AudioStreamMode {
  /// Standard Bluetooth streaming (single device or rapid switching)
  bluetooth,
  
  /// WiFi-based streaming for true multi-device support
  wifi,
}

class AudioCaptureService {
  AudioStreamMode _currentMode = AudioStreamMode.bluetooth;
  
  /// Get the current streaming mode
  AudioStreamMode get currentMode => _currentMode;

  /// Start audio capture and routing
  /// 
  /// [mode] - Streaming mode (bluetooth or wifi)
  /// For Bluetooth: Routes to active Bluetooth device (switches between multiple)
  /// For WiFi: Broadcasts over WiFi to unlimited devices simultaneously
  Future<bool> startCapture({AudioStreamMode mode = AudioStreamMode.bluetooth}) async {
    try {
      _currentMode = mode;
      AppLogger.info('Starting audio capture in ${mode.name} mode');

      if (Platform.isAndroid) {
        return await _startAndroidCapture(mode);
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

  Future<bool> _startAndroidCapture(AudioStreamMode mode) async {
    final String method;
    
    switch (mode) {
      case AudioStreamMode.bluetooth:
        method = 'startSystemAudioCapture';
        break;
      case AudioStreamMode.wifi:
        method = 'startWiFiAudioStream';
        break;
    }
    
    final result = await PlatformChannel.invoke<bool>(method);
    return result ?? false;
  }

  Future<bool> _startiOSCapture() async {
    // iOS only supports Bluetooth routing
    final result = await PlatformChannel.invoke<bool>('startAudioRouting');
    return result ?? false;
  }

  /// Stop audio capture and streaming
  Future<bool> stopCapture() async {
    try {
      AppLogger.info('Stopping audio capture');

      if (Platform.isAndroid) {
        final String method = _currentMode == AudioStreamMode.wifi
            ? 'stopWiFiAudioStream'
            : 'stopSystemAudioCapture';
        
        final result = await PlatformChannel.invoke<bool>(method);
        return result ?? false;
      } else if (Platform.isIOS) {
        final result = await PlatformChannel.invoke<bool>('stopAudioRouting');
        return result ?? false;
      }

      return false;
    } catch (e, st) {
      AppLogger.error('Failed to stop audio capture', e, st);
      throw ErrorHandler.handle(e, st);
    }
  }

  /// Check if audio capture is currently active
  Future<bool> isCapturing() async {
    try {
      final result = await PlatformChannel.invoke<bool>('isCapturing');
      return result ?? false;
    } catch (e) {
      AppLogger.warning('Failed to check capture status', e);
      return false;
    }
  }

  /// Get detailed information about the current capture session
  /// 
  /// Returns a map containing:
  /// - isRunning: bool
  /// - connectedDevices: int (for Bluetooth) or clientCount: int (for WiFi)
  /// - platform: String
  /// - mode: String (bluetooth/wifi) - Android only
  /// - streamUrl: String - WiFi mode only
  Future<Map<String, dynamic>> getCaptureInfo() async {
    try {
      final result = await PlatformChannel.invoke<Map>('getCaptureInfo');
      if (result == null) return {};
      
      final info = Map<String, dynamic>.from(result);
      info['mode'] = _currentMode.name;
      
      return info;
    } catch (e) {
      AppLogger.warning('Failed to get capture info', e);
      return {'mode': _currentMode.name};
    }
  }

  /// Get the WiFi stream URL (WiFi mode only)
  /// Returns null if not in WiFi mode or streaming not active
  Future<String?> getWiFiStreamUrl() async {
    if (_currentMode != AudioStreamMode.wifi) {
      return null;
    }

    try {
      final result = await PlatformChannel.invoke<String>('getWiFiStreamUrl');
      return result;
    } catch (e) {
      AppLogger.warning('Failed to get WiFi stream URL', e);
      return null;
    }
  }

  /// Get the number of connected WiFi clients (WiFi mode only)
  Future<int> getWiFiClientCount() async {
    if (_currentMode != AudioStreamMode.wifi) {
      return 0;
    }

    try {
      final info = await getCaptureInfo();
      return info['clientCount'] as int? ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Switch between Bluetooth devices (Bluetooth mode only)
  /// Forces an immediate switch to the next device
  Future<bool> switchToNextDevice() async {
    if (_currentMode != AudioStreamMode.bluetooth || Platform.isIOS) {
      return false;
    }

    try {
      final result = await PlatformChannel.invoke<bool>('switchToNextDevice');
      return result ?? false;
    } catch (e) {
      AppLogger.error('Failed to switch device', e);
      return false;
    }
  }

  /// Get the current active Bluetooth device name (Bluetooth mode only)
  Future<String?> getCurrentActiveDevice() async {
    if (_currentMode != AudioStreamMode.bluetooth) {
      return null;
    }

    try {
      final info = await getCaptureInfo();
      return info['currentDevice'] as String?;
    } catch (e) {
      return null;
    }
  }

  /// Check if multi-device streaming is supported on this platform
  /// 
  /// Returns true for:
  /// - Android devices (via Bluetooth switching or WiFi)
  /// - iOS devices with LE Audio support (limited)
  Future<bool> isMultiDeviceSupported() async {
    if (Platform.isAndroid) {
      // Android always supports multi-device via switching or WiFi
      return true;
    } else if (Platform.isIOS) {
      // Check for iOS LE Audio support
      try {
        final result = await PlatformChannel.invoke<bool>('supportsLEAudio');
        return result ?? false;
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  /// Get recommended streaming mode based on device capabilities
  /// 
  /// Returns WiFi mode if:
  /// - More than 2 target devices
  /// - Low Bluetooth version
  /// - WiFi available
  /// 
  /// Otherwise returns Bluetooth mode
  Future<AudioStreamMode> getRecommendedMode({
    required int targetDeviceCount,
  }) async {
    try {
      // For more than 2 devices, WiFi is always better
      if (targetDeviceCount > 2) {
        return AudioStreamMode.wifi;
      }

      // For iOS or single device, Bluetooth is fine
      if (Platform.isIOS || targetDeviceCount <= 1) {
        return AudioStreamMode.bluetooth;
      }

      // Check if WiFi is available
      final hasWiFi = await _isWiFiAvailable();
      if (hasWiFi) {
        AppLogger.info('WiFi available - recommending WiFi mode for better quality');
        return AudioStreamMode.wifi;
      }

      return AudioStreamMode.bluetooth;
    } catch (e) {
      AppLogger.error('Failed to determine recommended mode', e);
      return AudioStreamMode.bluetooth; // Safe fallback
    }
  }

  Future<bool> _isWiFiAvailable() async {
    if (!Platform.isAndroid) return false;
    
    try {
      final result = await PlatformChannel.invoke<bool>('isWiFiConnected');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Restart capture with a different mode
  Future<bool> switchMode(AudioStreamMode newMode) async {
    try {
      final wasCapturing = await isCapturing();
      
      if (wasCapturing) {
        await stopCapture();
        // Brief delay to ensure clean shutdown
        await Future.delayed(const Duration(milliseconds: 500));
      }

      if (wasCapturing) {
        return await startCapture(mode: newMode);
      }

      _currentMode = newMode;
      return true;
    } catch (e, st) {
      AppLogger.error('Failed to switch mode', e, st);
      throw ErrorHandler.handle(e, st);
    }
  }

  /// Get statistics about the current audio stream
  /// 
  /// Returns:
  /// - bufferUnderrunCount: int
  /// - averageLatency: double (ms)
  /// - bytesSent: int
  Future<Map<String, dynamic>> getStreamStatistics() async {
    try {
      final result = await PlatformChannel.invoke<Map>('getStreamStatistics');
      if (result == null) return {};
      return Map<String, dynamic>.from(result);
    } catch (e) {
      AppLogger.warning('Failed to get stream statistics', e);
      return {};
    }
  }
}