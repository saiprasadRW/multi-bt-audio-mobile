class AppStrings {
  AppStrings._();

  static const appName = 'Multi BT Audio';

  // Status messages
  static const ready = 'Ready - Connect devices and start broadcasting';
  static const broadcasting = 'Broadcasting audio to all connected devices';
  static const stopped = 'Broadcast stopped';
  static const connecting = 'Connecting...';
  static const disconnecting = 'Disconnecting...';

  // Errors
  static const noDevicesConnected = 'No Bluetooth audio devices connected';
  static const needMoreDevices = 'Connect at least 2 devices to broadcast';
  static const bluetoothDisabled = 'Bluetooth is turned off';
  static const permissionDenied = 'Required permission was denied';
  static const captureDenied = 'Audio capture permission was denied';
  static const connectionFailed = 'Failed to connect to device';
  static const captureStartFailed = 'Failed to start audio capture';
  static const unknownError = 'An unexpected error occurred';
  static const platformNotSupported =
      'This feature is not supported on your device';
  static const drmBlocked = 'This app blocks audio capture (DRM protected)';

  // iOS Specific
  static const iosLimitation =
      'iOS allows routing to multiple outputs using AVAudioSession. '
      'Some limitations may apply depending on iOS version.';
  static const iosRouteChangeInfo =
      'Audio route changed. Please check your connected devices.';

  // Instructions
  static const step1 = 'Connect 2+ Bluetooth earphones';
  static const step2 = 'Tap "START BROADCAST"';
  static const step3Android = 'Grant screen capture permission';
  static const step3iOS = 'Allow audio routing permission';
  static const step4 = 'Open ANY music/video app and play';
  static const step5 = 'Audio plays on ALL connected earphones! 🎉';

  // Permissions
  static const bluetoothPermTitle = 'Bluetooth Permission';
  static const bluetoothPermDesc =
      'Needed to discover and connect to your earphones';
  static const micPermTitle = 'Microphone Permission';
  static const micPermDesc = 'Needed to capture system audio (Android). '
      'We do NOT record your voice.';
  static const locationPermTitle = 'Location Permission';
  static const locationPermDesc =
      'Required by Android to scan for Bluetooth devices. '
      'We do NOT track your location.';
}
