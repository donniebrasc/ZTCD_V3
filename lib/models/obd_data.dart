class OBDData {
  final double rpm;
  final double speed;
  final double coolantTemp;
  final double engineLoad;
  final double throttlePosition;
  final double fuelLevel;
  final double maf;
  final double batteryVoltage;
  final DateTime timestamp;

  const OBDData({
    required this.rpm,
    required this.speed,
    required this.coolantTemp,
    required this.engineLoad,
    required this.throttlePosition,
    required this.fuelLevel,
    required this.maf,
    required this.batteryVoltage,
    required this.timestamp,
  });

  factory OBDData.empty() => OBDData(
        rpm: 0,
        speed: 0,
        coolantTemp: 0,
        engineLoad: 0,
        throttlePosition: 0,
        fuelLevel: 0,
        maf: 0,
        batteryVoltage: 0,
        timestamp: DateTime.now(),
      );

  factory OBDData.fromJson(Map<String, dynamic> json) => OBDData(
        rpm: (json['rpm'] as num).toDouble(),
        speed: (json['speed'] as num).toDouble(),
        coolantTemp: (json['coolantTemp'] as num).toDouble(),
        engineLoad: (json['engineLoad'] as num).toDouble(),
        throttlePosition: (json['throttlePosition'] as num).toDouble(),
        fuelLevel: (json['fuelLevel'] as num).toDouble(),
        maf: (json['maf'] as num).toDouble(),
        batteryVoltage: (json['batteryVoltage'] as num).toDouble(),
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  Map<String, dynamic> toJson() => {
        'rpm': rpm,
        'speed': speed,
        'coolantTemp': coolantTemp,
        'engineLoad': engineLoad,
        'throttlePosition': throttlePosition,
        'fuelLevel': fuelLevel,
        'maf': maf,
        'batteryVoltage': batteryVoltage,
        'timestamp': timestamp.toIso8601String(),
      };

  String toPromptString() => '''
OBD-II Sensor Data (${timestamp.toLocal()}):
- Engine RPM: ${rpm.toStringAsFixed(0)} RPM
- Vehicle Speed: ${speed.toStringAsFixed(1)} km/h
- Coolant Temperature: ${coolantTemp.toStringAsFixed(1)} °C
- Engine Load: ${engineLoad.toStringAsFixed(1)} %
- Throttle Position: ${throttlePosition.toStringAsFixed(1)} %
- Fuel Level: ${fuelLevel.toStringAsFixed(1)} %
- Mass Air Flow: ${maf.toStringAsFixed(2)} g/s
- Battery Voltage: ${batteryVoltage.toStringAsFixed(2)} V
''';
}
