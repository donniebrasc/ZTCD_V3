import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/trip.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _positionSub;
  Position? _currentPosition;
  final List<Waypoint> _currentRouteWaypoints = [];
  final _positionController = StreamController<Position>.broadcast();
  final _waypointController = StreamController<Waypoint>.broadcast();

  Stream<Position> get positionStream => _positionController.stream;
  Stream<Waypoint> get waypointStream => _waypointController.stream;
  Position? get currentPosition => _currentPosition;
  List<Waypoint> get currentRouteWaypoints =>
      List.unmodifiable(_currentRouteWaypoints);

  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;
    return true;
  }

  Future<void> startTracking() async {
    final granted = await requestPermission();
    if (!granted) return;

    _currentRouteWaypoints.clear();

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // metres between updates
    );

    _positionSub = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((position) {
      _currentPosition = position;
      _positionController.add(position);

      final waypoint = Waypoint(
        latitude: position.latitude,
        longitude: position.longitude,
        timestamp: DateTime.now(),
      );
      _currentRouteWaypoints.add(waypoint);
      _waypointController.add(waypoint);
    });
  }

  void stopTracking() {
    _positionSub?.cancel();
    _positionSub = null;
  }

  List<Waypoint> consumeWaypoints() {
    final waypoints = List<Waypoint>.from(_currentRouteWaypoints);
    _currentRouteWaypoints.clear();
    return waypoints;
  }

  /// Calculates total distance in km for a list of waypoints.
  static double calculateDistance(List<Waypoint> waypoints) {
    if (waypoints.length < 2) return 0;
    double total = 0;
    for (int i = 1; i < waypoints.length; i++) {
      total += Geolocator.distanceBetween(
        waypoints[i - 1].latitude,
        waypoints[i - 1].longitude,
        waypoints[i].latitude,
        waypoints[i].longitude,
      );
    }
    return total / 1000;
  }

  void dispose() {
    stopTracking();
    _positionController.close();
    _waypointController.close();
  }
}
