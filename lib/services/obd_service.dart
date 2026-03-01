import 'dart:async';
import 'dart:math';
import '../models/obd_data.dart';

enum OBDTransport { bluetooth, usb, simulation }

enum OBDConnectionState { disconnected, connecting, connected, error }

class OBDService {
  static final OBDService _instance = OBDService._internal();
  factory OBDService() => _instance;
  OBDService._internal();

  OBDTransport _transport = OBDTransport.simulation;
  OBDConnectionState _connectionState = OBDConnectionState.disconnected;
  OBDData _lastData = OBDData.empty();
  Timer? _simTimer;
  final _random = Random();

  final _dataController = StreamController<OBDData>.broadcast();
  final _stateController =
      StreamController<OBDConnectionState>.broadcast();

  Stream<OBDData> get dataStream => _dataController.stream;
  Stream<OBDConnectionState> get connectionStream => _stateController.stream;

  OBDTransport get transport => _transport;
  OBDConnectionState get connectionState => _connectionState;
  OBDData get lastData => _lastData;

  void setTransport(OBDTransport transport) {
    _transport = transport;
  }

  Future<void> connect() async {
    if (_connectionState == OBDConnectionState.connected) return;

    _setState(OBDConnectionState.connecting);
    await Future.delayed(const Duration(milliseconds: 1500));

    if (_transport == OBDTransport.simulation) {
      _setState(OBDConnectionState.connected);
      _startSimulation();
    } else {
      // Real Bluetooth/USB connection would be implemented here.
      // For now, fall back to simulation with an error note.
      _setState(OBDConnectionState.error);
    }
  }

  Future<void> disconnect() async {
    _simTimer?.cancel();
    _simTimer = null;
    _setState(OBDConnectionState.disconnected);
    _lastData = OBDData.empty();
  }

  void _setState(OBDConnectionState state) {
    _connectionState = state;
    _stateController.add(state);
  }

  // Simulation variables that evolve over time for realism.
  double _simRpm = 800;
  double _simSpeed = 0;
  double _simCoolant = 25;
  double _simLoad = 5;
  double _simThrottle = 3;
  double _simFuel = 75;
  double _simMaf = 2.0;
  double _simBattery = 12.6;

  void _startSimulation() {
    _simTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _simRpm = (_simRpm + (_random.nextDouble() * 400 - 200)).clamp(700, 5500);
      _simSpeed =
          (_simSpeed + (_random.nextDouble() * 10 - 5)).clamp(0, 180);
      _simCoolant =
          (_simCoolant + (_random.nextDouble() * 2 - 0.5)).clamp(20, 110);
      _simLoad =
          (_simLoad + (_random.nextDouble() * 10 - 5)).clamp(5, 100);
      _simThrottle =
          (_simThrottle + (_random.nextDouble() * 6 - 3)).clamp(0, 100);
      _simFuel = (_simFuel - _random.nextDouble() * 0.05).clamp(0, 100);
      _simMaf = (_simMaf + (_random.nextDouble() * 1 - 0.5)).clamp(1, 50);
      _simBattery =
          (_simBattery + (_random.nextDouble() * 0.2 - 0.1)).clamp(11.5, 14.8);

      _lastData = OBDData(
        rpm: _simRpm,
        speed: _simSpeed,
        coolantTemp: _simCoolant,
        engineLoad: _simLoad,
        throttlePosition: _simThrottle,
        fuelLevel: _simFuel,
        maf: _simMaf,
        batteryVoltage: _simBattery,
        timestamp: DateTime.now(),
      );
      _dataController.add(_lastData);
    });
  }

  void dispose() {
    _simTimer?.cancel();
    _dataController.close();
    _stateController.close();
  }
}
