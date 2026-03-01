import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';
import '../models/damage_event.dart';
import '../models/obd_data.dart';

class DamageService {
  static final DamageService _instance = DamageService._internal();
  factory DamageService() => _instance;
  DamageService._internal();

  // Thresholds
  static const double _harshAccelThreshold = 15.0; // m/s²
  static const double _harshBrakeThreshold = -12.0; // m/s²
  static const double _sharpTurnThreshold = 12.0;  // rad/s gyro
  static const double _highRpmThreshold = 4500.0;
  static const double _overheatThreshold = 100.0;  // °C

  double _currentScore = 0;
  final List<DamageEvent> _recentEvents = [];
  StreamSubscription<AccelerometerEvent>? _accelSub;
  StreamSubscription<GyroscopeEvent>? _gyroSub;
  final _scoreController = StreamController<double>.broadcast();
  final _eventController = StreamController<DamageEvent>.broadcast();

  Stream<double> get scoreStream => _scoreController.stream;
  Stream<DamageEvent> get eventStream => _eventController.stream;
  double get currentScore => _currentScore;
  List<DamageEvent> get recentEvents => List.unmodifiable(_recentEvents);

  void startMonitoring() {
    _accelSub ??= accelerometerEventStream().listen(_onAccelerometer);
    _gyroSub ??= gyroscopeEventStream().listen(_onGyroscope);
  }

  void stopMonitoring() {
    _accelSub?.cancel();
    _accelSub = null;
    _gyroSub?.cancel();
    _gyroSub = null;
  }

  void processOBDData(OBDData data) {
    if (data.rpm > _highRpmThreshold) {
      _addEvent(DamageEvent(
        timestamp: DateTime.now(),
        type: DamageEventType.highRpm,
        severity: _scaleSeverity(data.rpm, _highRpmThreshold, 6000),
        value: data.rpm,
      ));
    }
    if (data.coolantTemp > _overheatThreshold) {
      _addEvent(DamageEvent(
        timestamp: DateTime.now(),
        type: DamageEventType.overheating,
        severity: _scaleSeverity(data.coolantTemp, _overheatThreshold, 120),
        value: data.coolantTemp,
      ));
    }
    if (data.batteryVoltage < 11.8 && data.batteryVoltage > 0) {
      _addEvent(DamageEvent(
        timestamp: DateTime.now(),
        type: DamageEventType.lowBattery,
        severity: _scaleSeverity(12.0 - data.batteryVoltage, 0.2, 1.0),
        value: data.batteryVoltage,
      ));
    }
  }

  void _onAccelerometer(AccelerometerEvent event) {
    if (event.y > _harshAccelThreshold) {
      _addEvent(DamageEvent(
        timestamp: DateTime.now(),
        type: DamageEventType.harshAcceleration,
        severity: _scaleSeverity(event.y, _harshAccelThreshold, 25),
        value: event.y,
      ));
    } else if (event.y < _harshBrakeThreshold) {
      _addEvent(DamageEvent(
        timestamp: DateTime.now(),
        type: DamageEventType.harshBraking,
        severity: _scaleSeverity(event.y.abs(), _harshBrakeThreshold.abs(), 25),
        value: event.y,
      ));
    }
  }

  void _onGyroscope(GyroscopeEvent event) {
    final lateral = sqrt(event.x * event.x + event.z * event.z);
    if (lateral > _sharpTurnThreshold) {
      _addEvent(DamageEvent(
        timestamp: DateTime.now(),
        type: DamageEventType.sharpTurn,
        severity: _scaleSeverity(lateral, _sharpTurnThreshold, 20),
        value: lateral,
      ));
    }
  }

  double _scaleSeverity(double value, double min, double max) =>
      ((value - min) / (max - min) * 100).clamp(0, 100);

  void _addEvent(DamageEvent event) {
    _recentEvents.add(event);
    if (_recentEvents.length > 100) _recentEvents.removeAt(0);
    _eventController.add(event);
    _updateScore();
  }

  void _updateScore() {
    if (_recentEvents.isEmpty) {
      _currentScore = 0;
    } else {
      final recent = _recentEvents
          .where((e) => DateTime.now().difference(e.timestamp).inMinutes < 10)
          .toList();
      if (recent.isEmpty) {
        _currentScore = 0;
      } else {
        _currentScore =
            recent.map((e) => e.severity).reduce((a, b) => a + b) /
                recent.length;
      }
    }
    _scoreController.add(_currentScore);
  }

  void clearEvents() {
    _recentEvents.clear();
    _currentScore = 0;
    _scoreController.add(0);
  }

  void dispose() {
    stopMonitoring();
    _scoreController.close();
    _eventController.close();
  }
}


