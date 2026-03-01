import 'damage_event.dart';

class Waypoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  const Waypoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  factory Waypoint.fromJson(Map<String, dynamic> json) => Waypoint(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': timestamp.toIso8601String(),
      };
}

class Trip {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final double distanceKm;
  final double averageDamageScore;
  final List<Waypoint> waypoints;
  final List<DamageEvent> damageEvents;

  const Trip({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.distanceKm,
    required this.averageDamageScore,
    required this.waypoints,
    required this.damageEvents,
  });

  bool get isActive => endTime == null;

  Duration get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  factory Trip.start() => Trip(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        startTime: DateTime.now(),
        distanceKm: 0,
        averageDamageScore: 0,
        waypoints: [],
        damageEvents: [],
      );

  Trip copyWith({
    DateTime? endTime,
    double? distanceKm,
    double? averageDamageScore,
    List<Waypoint>? waypoints,
    List<DamageEvent>? damageEvents,
  }) =>
      Trip(
        id: id,
        startTime: startTime,
        endTime: endTime ?? this.endTime,
        distanceKm: distanceKm ?? this.distanceKm,
        averageDamageScore: averageDamageScore ?? this.averageDamageScore,
        waypoints: waypoints ?? this.waypoints,
        damageEvents: damageEvents ?? this.damageEvents,
      );

  factory Trip.fromJson(Map<String, dynamic> json) => Trip(
        id: json['id'] as String,
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: json['endTime'] != null
            ? DateTime.parse(json['endTime'] as String)
            : null,
        distanceKm: (json['distanceKm'] as num).toDouble(),
        averageDamageScore: (json['averageDamageScore'] as num).toDouble(),
        waypoints: (json['waypoints'] as List<dynamic>)
            .map((w) => Waypoint.fromJson(w as Map<String, dynamic>))
            .toList(),
        damageEvents: (json['damageEvents'] as List<dynamic>)
            .map((e) => DamageEvent.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'distanceKm': distanceKm,
        'averageDamageScore': averageDamageScore,
        'waypoints': waypoints.map((w) => w.toJson()).toList(),
        'damageEvents': damageEvents.map((e) => e.toJson()).toList(),
      };
}
