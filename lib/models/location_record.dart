/// 位置记录模型
class LocationRecord {
  final int? id;
  final String userId;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final int? batteryLevel;
  final bool? isCharging;
  final DateTime createdAt;

  LocationRecord({
    this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.speed,
    this.batteryLevel,
    this.isCharging,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory LocationRecord.fromJson(Map<String, dynamic> json) {
    return LocationRecord(
      id: json['id'] as int?,
      userId: json['user_id'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      batteryLevel: json['battery_level'] as int?,
      isCharging: json['is_charging'] as bool?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'altitude': altitude,
      'speed': speed,
      'battery_level': batteryLevel,
      'is_charging': isCharging,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
