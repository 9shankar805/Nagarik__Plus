// Model representing a discovered nearby device
class DeviceModel {
  final String id;           // Unique identifier (MAC or endpoint ID)
  final String name;         // Human-readable device name
  final String connectionType; // 'WiFi Direct', 'Hotspot', 'LAN'
  final String? ipAddress;   // IP address once connected
  final bool isConnected;

  const DeviceModel({
    required this.id,
    required this.name,
    required this.connectionType,
    this.ipAddress,
    this.isConnected = false,
  });

  DeviceModel copyWith({
    String? id,
    String? name,
    String? connectionType,
    String? ipAddress,
    bool? isConnected,
  }) {
    return DeviceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      connectionType: connectionType ?? this.connectionType,
      ipAddress: ipAddress ?? this.ipAddress,
      isConnected: isConnected ?? this.isConnected,
    );
  }

  @override
  String toString() =>
      'DeviceModel(id: $id, name: $name, type: $connectionType, ip: $ipAddress)';
}
