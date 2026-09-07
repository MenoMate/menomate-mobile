class Device {
  final String id;
  final String userId;
  final String deviceIdentifier;
  final String? name;
  final String? firmwareVersion;
  final DateTime? lastConnectedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Device({
    required this.id,
    required this.userId,
    required this.deviceIdentifier,
    this.name,
    this.firmwareVersion,
    this.lastConnectedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      deviceIdentifier: json['device_identifier'] as String,
      name: json['name'] as String?,
      firmwareVersion: json['firmware_version'] as String?,
      lastConnectedAt: json['last_connected_at'] != null
          ? DateTime.parse(json['last_connected_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }
}

class DeviceCreate {
  final String deviceIdentifier;
  final String? name;
  final String? firmwareVersion;

  DeviceCreate({
    required this.deviceIdentifier,
    this.name,
    this.firmwareVersion,
  });

  Map<String, dynamic> toJson() {
    return {
      'device_identifier': deviceIdentifier,
      if (name != null) 'name': name,
      if (firmwareVersion != null) 'firmware_version': firmwareVersion,
    };
  }
}
