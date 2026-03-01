import 'dart:async';
import 'package:flutter/material.dart';
import '../models/obd_data.dart';
import '../services/obd_service.dart';
import '../services/gemini_service.dart';

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
        return Colors.green;
      case OBDConnectionState.connecting:
        return Colors.orange;
      case OBDConnectionState.error:
        return Colors.red;
      case OBDConnectionState.disconnected:
        return Colors.grey;
    }
  }

  String get _connectionLabel {
    switch (_connState) {
      case OBDConnectionState.connected:
        return 'Connected';
      case OBDConnectionState.connecting:
        return 'Connecting…';
      case OBDConnectionState.error:
        return 'Error – tap to retry';
      case OBDConnectionState.disconnected:
        return 'Disconnected';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _connState == OBDConnectionState.connected;
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // ── Connection card ──────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.circle, color: _connectionColor, size: 14),
                      const SizedBox(width: 8),
                      Text(_connectionLabel,
                          style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      if (_connState == OBDConnectionState.connecting)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Transport selector
                  Wrap(
                    spacing: 8,
                    children: OBDTransport.values.map((t) {
                      return ChoiceChip(
                        label: Text(t.name.toUpperCase()),
                        selected: _transport == t,
                        onSelected: isConnected
                            ? null
                            : (_) => setState(() => _transport = t),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _connState == OBDConnectionState.connecting
                          ? null
                          : _toggleConnection,
                      icon: Icon(
                          isConnected ? Icons.link_off : Icons.link),
                      label: Text(isConnected ? 'Disconnect' : 'Connect'),
                      style: isConnected
                          ? FilledButton.styleFrom(
                              backgroundColor: cs.error,
                              foregroundColor: cs.onError,
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Sensor grid ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.6,
              children: [
                _SensorCard(
                    label: 'RPM',
                    value: isConnected
                        ? _data.rpm.toStringAsFixed(0)
                        : '--',
                    unit: 'rpm',
                    icon: Icons.speed),
                _SensorCard(
                    label: 'Speed',
                    value: isConnected
                        ? _data.speed.toStringAsFixed(1)
                        : '--',
                    unit: 'km/h',
                    icon: Icons.directions_car),
                _SensorCard(
                    label: 'Coolant',
                    value: isConnected
                        ? _data.coolantTemp.toStringAsFixed(1)
                        : '--',
                    unit: '°C',
                    icon: Icons.thermostat,
                    warningAbove: 100),
                _SensorCard(
                    label: 'Engine Load',
                    value: isConnected
                        ? _data.engineLoad.toStringAsFixed(1)
                        : '--',
                    unit: '%',
                    icon: Icons.power),
                _SensorCard(
                    label: 'Throttle',
                    value: isConnected
                        ? _data.throttlePosition.toStringAsFixed(1)
                        : '--',
                    unit: '%',
                    icon: Icons.trending_up),
                _SensorCard(
                    label: 'Fuel Level',
                    value: isConnected
                        ? _data.fuelLevel.toStringAsFixed(1)
                        : '--',
                    unit: '%',
                    icon: Icons.local_gas_station,
                    warningBelow: 15),
                _SensorCard(
                    label: 'MAF',
                    value: isConnected
                        ? _data.maf.toStringAsFixed(2)
                        : '--',
                    unit: 'g/s',
                    icon: Icons.air),
                _SensorCard(
                    label: 'Battery',
                    value: isConnected
                        ? _data.batteryVoltage.toStringAsFixed(2)
                        : '--',
                    unit: 'V',
                    icon: Icons.battery_charging_full,
                    warningBelow: 11.8),
              ],
            ),
          ),

          // ── AI Diagnosis button ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: (!isConnected || _loadingAI) ? null : _runAIDiagnostics,
                icon: _loadingAI
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.psychology),
                label: Text(_loadingAI
                    ? 'Analysing…'
                    : 'Run AI Diagnosis'),
              ),
            ),
          ),

          // ── AI Result ────────────────────────────────────────────────────
          if (_aiResult != null)
            Card(
              child: ExpansionTile(
                initiallyExpanded: _aiExpanded,
                leading: const Icon(Icons.smart_toy_outlined),
                title: const Text('AI Diagnostic Report'),
                onExpansionChanged: (v) => setState(() => _aiExpanded = v),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: SelectableText(_aiResult!),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SensorCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final double? warningAbove;
  final double? warningBelow;

  const _SensorCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    this.warningAbove,
    this.warningBelow,
  });

  bool get _inWarning {
    final numeric = double.tryParse(value);
    if (numeric == null) return false;
    if (warningAbove != null && numeric > warningAbove!) return true;
    if (warningBelow != null && numeric < warningBelow!) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final warnColor = _inWarning ? Colors.orange.shade700 : null;

    return Card(
      margin: EdgeInsets.zero,
      color: _inWarning ? Colors.orange.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: warnColor ?? cs.primary),
                const SizedBox(width: 4),
                Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: warnColor)),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: warnColor,
                      ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(unit,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: warnColor ?? cs.onSurfaceVariant)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
