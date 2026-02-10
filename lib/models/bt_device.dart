import '../core/constants/app_enums.dart';

class BTDevice {
  final String name;
  final String address;
  final bool isAudio;
  DeviceConnectionStatus status;
  String? errorMessage;
  DateTime? lastConnected;

  BTDevice({
    required this.name,
    required this.address,
    this.isAudio = true,
    this.status = DeviceConnectionStatus.disconnected,
    this.errorMessage,
    this.lastConnected,
  });

  bool get isConnected => status == DeviceConnectionStatus.connected;
  bool get isConnecting => status == DeviceConnectionStatus.connecting;
  bool get isFailed => status == DeviceConnectionStatus.failed;

  factory BTDevice.fromMap(Map<String, dynamic> map) {
    return BTDevice(
      name: map['name'] ?? 'Unknown Device',
      address: map['address'] ?? '',
      isAudio: map['isAudio'] ?? true,
      status: (map['isConnected'] == true)
          ? DeviceConnectionStatus.connected
          : DeviceConnectionStatus.disconnected,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'address': address,
        'isAudio': isAudio,
        'isConnected': isConnected,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BTDevice &&
          runtimeType == other.runtimeType &&
          address == other.address;

  @override
  int get hashCode => address.hashCode;

  @override
  String toString() => 'BTDevice($name, $address, $status)';
}
