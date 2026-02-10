enum BroadcastStatus {
  idle,
  starting,
  broadcasting,
  stopping,
  error,
}

enum DeviceConnectionStatus {
  disconnected,
  connecting,
  connected,
  disconnecting,
  failed,
}

enum AppPlatform {
  android,
  ios,
  unsupported,
}

enum PermissionType {
  bluetooth,
  microphone,
  location,
  mediaProjection,
}

enum ErrorSeverity {
  info,
  warning,
  error,
  critical,
}