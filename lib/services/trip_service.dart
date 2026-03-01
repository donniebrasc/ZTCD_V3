import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/trip.dart';
import '../models/damage_event.dart';
import 'damage_service.dart';
import 'location_service.dart';

class TripService {
  static final TripService _instance = TripService._internal();
  factory TripService() => _instance;
  TripService._internal();

  final _damageService = DamageService();
  final _locationService = LocationService();

  Trip? _activeTrip;
  List<Trip> _tripHistory = [];
  bool _loaded = false;

  Trip? get activeTrip => _activeTrip;
  List<Trip> get tripHistory => List.unmodifiable(_tripHistory);
  bool get isRecording => _activeTrip != null;

  Future<void> loadHistory() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final file = await _tripsFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final List<dynamic> data = jsonDecode(content) as List<dynamic>;
        _tripHistory = data
            .map((e) => Trip.fromJson(e as Map<String, dynamic>))
            .toList()
            .reversed
            .toList();
      }
    } catch (_) {
      _tripHistory = [];
    }
  }

  Future<void> startTrip() async {
    if (_activeTrip != null) return;
    _damageService.startMonitoring();
    await _locationService.startTracking();
    _damageService.clearEvents();
    _activeTrip = Trip.start();
  }

  Future<Trip> stopTrip() async {
    final active = _activeTrip;
    if (active == null) throw StateError('No active trip');

    _damageService.stopMonitoring();
    _locationService.stopTracking();

    final waypoints = _locationService.consumeWaypoints();
    final events = List<DamageEvent>.from(_damageService.recentEvents);
    final distance = LocationService.calculateDistance(waypoints);
    final avgScore = events.isEmpty
        ? 0.0
        : events.map((e) => e.severity).reduce((a, b) => a + b) /
            events.length;

    final completed = active.copyWith(
      endTime: DateTime.now(),
      waypoints: waypoints,
      damageEvents: events,
      distanceKm: distance,
      averageDamageScore: avgScore,
    );

    _activeTrip = null;
    _tripHistory.insert(0, completed);
    await _saveHistory();
    return completed;
  }

  Future<void> _saveHistory() async {
    try {
      final file = await _tripsFile();
      final data = _tripHistory.map((t) => t.toJson()).toList();
      await file.writeAsString(jsonEncode(data));
    } catch (_) {}
  }

  Future<File> _tripsFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/trips.json');
  }
}
