enum DamageEventType {
  harshAcceleration,
  harshBraking,
  sharpTurn,
  highRpm,
  overheating,
  lowBattery,
}

extension DamageEventTypeExtension on DamageEventType {
  String get displayName {
    switch (this) {
      case DamageEventType.harshAcceleration:
        return 'Harsh Acceleration';
      case DamageEventType.harshBraking:
        return 'Harsh Braking';
      case DamageEventType.sharpTurn:
        return 'Sharp Turn';
      case DamageEventType.highRpm:
        return 'High RPM';
      case DamageEventType.overheating:
        return 'Overheating';
      case DamageEventType.lowBattery:
        return 'Low Battery';
    }
  }

  String get jsonValue {
    switch (this) {
      case DamageEventType.harshAcceleration:
        return 'harsh_accel';
      case DamageEventType.harshBraking:
        return 'harsh_brake';
      case DamageEventType.sharpTurn:
        return 'sharp_turn';
      case DamageEventType.highRpm:
        return 'high_rpm';
      case DamageEventType.overheating:
        return 'overheating';
      case DamageEventType.lowBattery:
        return 'low_battery';
    }
  }

  static DamageEventType fromJson(String value) {
    switch (value) {
      case 'harsh_accel':
        return DamageEventType.harshAcceleration;
      case 'harsh_brake':
        return DamageEventType.harshBraking;
      case 'sharp_turn':
        return DamageEventType.sharpTurn;
      case 'high_rpm':
        return DamageEventType.highRpm;
      case 'overheating':
        return DamageEventType.overheating;
      case 'low_battery':
        return DamageEventType.lowBattery;
      default:
        return DamageEventType.harshAcceleration;
    }
  }
}

class DamageEvent {
  final DateTime timestamp;
  final DamageEventType type;
  final double severity; // 0-100
  final double value;

  const DamageEvent({
    required this.timestamp,
    required this.type,
    required this.severity,
    required this.value,
  });

  factory DamageEvent.fromJson(Map<String, dynamic> json) => DamageEvent(
        timestamp: DateTime.parse(json['timestamp'] as String),
        type: DamageEventTypeExtension.fromJson(json['type'] as String),
        severity: (json['severity'] as num).toDouble(),
        value: (json['value'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'type': type.jsonValue,
        'severity': severity,
        'value': value,
      };
}
