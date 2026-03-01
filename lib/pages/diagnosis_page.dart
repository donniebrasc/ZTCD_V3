import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/obd_data.dart';
import '../services/obd_service.dart';
import '../services/gemini_service.dart';
import '../theme/app_theme.dart';
import '../widgets/automotive_widgets.dart';

class DiagnosisPage extends StatefulWidget {
  const DiagnosisPage({super.key});

  @override
  State<DiagnosisPage> createState() => _DiagnosisPageState();
}

class _DiagnosisPageState extends State<DiagnosisPage> {
  final _obd = OBDService();
  final _gemini = GeminiService();

  OBDData _data = OBDData.empty();
  OBDConnectionState _connState = OBDConnectionState.disconnected;
  OBDTransport _transport = OBDTransport.simulation;

  StreamSubscription<OBDData>? _dataSub;
  StreamSubscription<OBDConnectionState>? _stateSub;

  bool _loadingAI = false;
  String? _aiResult;
  bool _aiExpanded = false;

  @override
  void initState() {
    super.initState();
    _connState = _obd.connectionState;
    _transport = _obd.transport;
    _data = _obd.lastData;

    _stateSub = _obd.connectionStream.listen((state) {
      if (mounted) setState(() => _connState = state);
    });
    _dataSub = _obd.dataStream.listen((data) {
      if (mounted) setState(() => _data = data);
    });
  }

  @override
  void dispose() {
    _dataSub?.cancel();
    _stateSub?.cancel();
    super.dispose();
  }

  Future<void> _toggleConnection() async {
    if (_connState == OBDConnectionState.connected) {
      await _obd.disconnect();
    } else if (_connState != OBDConnectionState.connecting) {
      _obd.setTransport(_transport);
      await _obd.connect();
    }
  }

  Future<void> _runAIDiagnostics() async {
    setState(() {
      _loadingAI = true;
      _aiResult = null;
    });
    final result = await _gemini.runDiagnostics(_data.toPromptString());
    if (mounted) {
      setState(() {
        _loadingAI = false;
        _aiResult = result;
        _aiExpanded = true;
      });
    }
  }

  Color get _connectionColor {
    switch (_connState) {
      case OBDConnectionState.connected:
        return AppTheme.successGreen;
      case OBDConnectionState.connecting:
        return AppTheme.amber;
      case OBDConnectionState.error:
        return AppTheme.racingRed;
      case OBDConnectionState.disconnected:
        return AppTheme.onSurfaceDim;
    }
  }

  String get _connectionLabel {
    switch (_connState) {
      case OBDConnectionState.connected:
        return 'CONNECTED';
      case OBDConnectionState.connecting:
        return 'CONNECTING…';
      case OBDConnectionState.error:
        return 'CONNECTION ERROR — TAP TO RETRY';
      case OBDConnectionState.disconnected:
        return 'DISCONNECTED';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _connState == OBDConnectionState.connected;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // ── Connection card ───────────────────────────────────────────────
          DashCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status row
                Row(
                  children: [
                    StatusLed(color: _connectionColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _connectionLabel,
                        style: GoogleFonts.rajdhani(
                          color: _connectionColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    if (_connState == OBDConnectionState.connecting)
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.amber,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                // Transport selector chips
                Wrap(
                  spacing: 8,
                  children: OBDTransport.values.map((t) {
                    final selected = _transport == t;
                    return ChoiceChip(
                      label: Text(
                        t.name.toUpperCase(),
                        style: GoogleFonts.rajdhani(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          letterSpacing: 1,
                          color: selected
                              ? AppTheme.racingRed
                              : AppTheme.onSurfaceDim,
                        ),
                      ),
                      selected: selected,
                      onSelected: isConnected
                          ? null
                          : (_) => setState(() => _transport = t),
                      selectedColor: AppTheme.racingRed.withOpacity(0.2),
                      side: BorderSide(
                        color: selected
                            ? AppTheme.racingRed
                            : const Color(0xFF444455),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: AutomotiveButton(
                    onPressed: _connState == OBDConnectionState.connecting
                        ? null
                        : _toggleConnection,
                    icon: isConnected ? Icons.link_off : Icons.link,
                    label: isConnected ? 'DISCONNECT' : 'CONNECT',
                    color: isConnected
                        ? AppTheme.racingRed
                        : AppTheme.successGreen,
                  ),
                ),
              ],
            ),
          ),

          // ── Sensor grid ───────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.55,
              children: [
                GaugeCard(
                  label: 'ENGINE RPM',
                  value:
                      isConnected ? _data.rpm.toStringAsFixed(0) : '--',
                  unit: 'RPM',
                  icon: Icons.speed,
                  warningAbove: 4000,
                  numericValue: isConnected ? _data.rpm : null,
                  maxValue: 8000,
                ),
                GaugeCard(
                  label: 'SPEED',
                  value: isConnected
                      ? _data.speed.toStringAsFixed(1)
                      : '--',
                  unit: 'KM/H',
                  icon: Icons.directions_car,
                  numericValue: isConnected ? _data.speed : null,
                  maxValue: 250,
                ),
                GaugeCard(
                  label: 'COOLANT',
                  value: isConnected
                      ? _data.coolantTemp.toStringAsFixed(1)
                      : '--',
                  unit: '°C',
                  icon: Icons.thermostat,
                  warningAbove: 100,
                  numericValue: isConnected ? _data.coolantTemp : null,
                  maxValue: 130,
                ),
                GaugeCard(
                  label: 'ENGINE LOAD',
                  value: isConnected
                      ? _data.engineLoad.toStringAsFixed(1)
                      : '--',
                  unit: '%',
                  icon: Icons.power,
                  warningAbove: 80,
                  numericValue: isConnected ? _data.engineLoad : null,
                  maxValue: 100,
                ),
                GaugeCard(
                  label: 'THROTTLE',
                  value: isConnected
                      ? _data.throttlePosition.toStringAsFixed(1)
                      : '--',
                  unit: '%',
                  icon: Icons.trending_up,
                  numericValue:
                      isConnected ? _data.throttlePosition : null,
                  maxValue: 100,
                ),
                GaugeCard(
                  label: 'FUEL LEVEL',
                  value: isConnected
                      ? _data.fuelLevel.toStringAsFixed(1)
                      : '--',
                  unit: '%',
                  icon: Icons.local_gas_station,
                  warningBelow: 15,
                  numericValue: isConnected ? _data.fuelLevel : null,
                  maxValue: 100,
                ),
                GaugeCard(
                  label: 'MAF',
                  value: isConnected
                      ? _data.maf.toStringAsFixed(2)
                      : '--',
                  unit: 'G/S',
                  icon: Icons.air,
                  numericValue: isConnected ? _data.maf : null,
                  maxValue: 200,
                ),
                GaugeCard(
                  label: 'BATTERY',
                  value: isConnected
                      ? _data.batteryVoltage.toStringAsFixed(2)
                      : '--',
                  unit: 'V',
                  icon: Icons.battery_charging_full,
                  warningBelow: 11.8,
                  numericValue:
                      isConnected ? _data.batteryVoltage : null,
                  maxValue: 15,
                ),
              ],
            ),
          ),

          // ── AI Diagnosis button ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: SizedBox(
              width: double.infinity,
              child: AutomotiveButton(
                onPressed:
                    (!isConnected || _loadingAI) ? null : _runAIDiagnostics,
                icon: Icons.psychology,
                label: _loadingAI ? 'ANALYSING…' : 'RUN AI DIAGNOSIS',
                color: AppTheme.electricBlue,
                loading: _loadingAI,
              ),
            ),
          ),

          // ── AI Result card ────────────────────────────────────────────────
          if (_aiResult != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: DashCard(
                padding: EdgeInsets.zero,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    dividerColor: Colors.transparent,
                  ),
                  child: ExpansionTile(
                    initiallyExpanded: _aiExpanded,
                    leading: const Icon(Icons.smart_toy_outlined,
                        color: AppTheme.electricBlue, size: 20),
                    title: Text(
                      'AI DIAGNOSTIC REPORT',
                      style: GoogleFonts.rajdhani(
                        color: AppTheme.electricBlue,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: 1,
                      ),
                    ),
                    onExpansionChanged: (v) =>
                        setState(() => _aiExpanded = v),
                    children: [
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: SelectableText(
                          _aiResult!,
                          style: GoogleFonts.rajdhani(
                            color: AppTheme.onSurface,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ── Dashboard gauge card ──────────────────────────────────────────────────────

class GaugeCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final double? warningAbove;
  final double? warningBelow;
  final double? numericValue;
  final double maxValue;

  const GaugeCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.maxValue,
    this.warningAbove,
    this.warningBelow,
    this.numericValue,
  });

  bool get _inWarning {
    if (numericValue == null) return false;
    if (warningAbove != null && numericValue! > warningAbove!) return true;
    if (warningBelow != null && numericValue! < warningBelow!) return true;
    return false;
  }

  Color get _accentColor =>
      _inWarning ? AppTheme.amber : AppTheme.electricBlue;

  double get _fraction {
    if (numericValue == null) return 0;
    return (numericValue! / maxValue).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _inWarning
              ? AppTheme.amber.withOpacity(0.5)
              : const Color(0xFF2A2A38),
        ),
        boxShadow: _inWarning
            ? [
                BoxShadow(
                    color: AppTheme.amber.withOpacity(0.15),
                    blurRadius: 8,
                    spreadRadius: 1)
              ]
            : null,
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Label row
          Row(
            children: [
              Icon(icon, size: 13, color: _accentColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.rajdhani(
                    color: AppTheme.onSurfaceDim,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          // Value
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.orbitron(
                  color: _inWarning ? AppTheme.amber : AppTheme.onSurface,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
              ),
              const SizedBox(width: 3),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  unit,
                  style: GoogleFonts.rajdhani(
                    color: AppTheme.onSurfaceDim,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: _fraction,
              minHeight: 3,
              backgroundColor: const Color(0xFF2A2A38),
              valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
            ),
          ),
        ],
      ),
    );
  }
}
