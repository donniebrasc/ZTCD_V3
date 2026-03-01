import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/damage_event.dart';
import '../models/trip.dart';
import '../services/damage_service.dart';
import '../services/trip_service.dart';
import '../services/obd_service.dart';

class DamageLogPage extends StatefulWidget {
  const DamageLogPage({super.key});

  @override
  State<DamageLogPage> createState() => _DamageLogPageState();
}

class _DamageLogPageState extends State<DamageLogPage> {
  final _damageService = DamageService();
  final _tripService = TripService();
  final _obdService = OBDService();

  double _currentScore = 0;
  final List<DamageEvent> _recentEvents = [];
  final List<FlSpot> _scoreHistory = [];
  int _spotIndex = 0;

  StreamSubscription<double>? _scoreSub;
  StreamSubscription<DamageEvent>? _eventSub;
  StreamSubscription<dynamic>? _obdSub;

  @override
  void initState() {
    super.initState();
    _damageService.startMonitoring();
    _tripService.loadHistory();

    _scoreSub = _damageService.scoreStream.listen((score) {
      if (mounted) {
        setState(() {
          _currentScore = score;
          _scoreHistory.add(FlSpot(_spotIndex.toDouble(), score));
          _spotIndex++;
          if (_scoreHistory.length > 60) _scoreHistory.removeAt(0);
        });
      }
    });

    _eventSub = _damageService.eventStream.listen((event) {
      if (mounted) {
        setState(() {
          _recentEvents.insert(0, event);
          if (_recentEvents.length > 50) _recentEvents.removeLast();
        });
      }
    });

    _obdSub = _obdService.dataStream.listen((data) {
      _damageService.processOBDData(data);
    });
  }

  @override
  void dispose() {
    _scoreSub?.cancel();
    _eventSub?.cancel();
    _obdSub?.cancel();
    super.dispose();
  }

  Color _scoreColor(double score) {
    if (score < 30) return Colors.green;
    if (score < 60) return Colors.orange;
    return Colors.red;
  }

  String _scoreLabel(double score) {
    if (score < 30) return 'Good';
    if (score < 60) return 'Fair';
    return 'Poor';
  }

  Future<void> _toggleTrip() async {
    if (_tripService.isRecording) {
      final trip = await _tripService.stopTrip();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Trip saved: ${trip.distanceKm.toStringAsFixed(1)} km, '
              'score ${trip.averageDamageScore.toStringAsFixed(0)}'),
        ));
        setState(() {});
      }
    } else {
      await _tripService.startTrip();
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final scoreColor = _scoreColor(_currentScore);
    final trips = _tripService.tripHistory;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // ── Damage score card ────────────────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('Current Damage Score',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: _currentScore / 100,
                          strokeWidth: 12,
                          backgroundColor: cs.surfaceContainerHighest,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(scoreColor),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentScore.toStringAsFixed(0),
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: scoreColor,
                                ),
                          ),
                          Text(_scoreLabel(_currentScore),
                              style: TextStyle(color: scoreColor)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _toggleTrip,
                    icon: Icon(_tripService.isRecording
                        ? Icons.stop
                        : Icons.play_arrow),
                    label: Text(_tripService.isRecording
                        ? 'Stop Trip Recording'
                        : 'Start Trip Recording'),
                    style: _tripService.isRecording
                        ? FilledButton.styleFrom(
                            backgroundColor: cs.error,
                            foregroundColor: cs.onError,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),

          // ── Score chart ───────────────────────────────────────────────────
          if (_scoreHistory.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Score History (last 60s)',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: false),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          minY: 0,
                          maxY: 100,
                          lineBarsData: [
                            LineChartBarData(
                              spots: _scoreHistory,
                              isCurved: true,
                              color: cs.primary,
                              barWidth: 2,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: cs.primary.withOpacity(0.15),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Recent events ────────────────────────────────────────────────
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text('Recent Events',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                if (_recentEvents.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No damage events detected yet.',
                        style: TextStyle(color: Colors.grey)),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _recentEvents.length.clamp(0, 10),
                    itemBuilder: (_, i) {
                      final e = _recentEvents[i];
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          _eventIcon(e.type),
                          color: _scoreColor(e.severity),
                          size: 20,
                        ),
                        title: Text(e.type.displayName),
                        subtitle: Text(
                            DateFormat('HH:mm:ss').format(e.timestamp)),
                        trailing: Chip(
                          label: Text(e.severity.toStringAsFixed(0)),
                          backgroundColor:
                              _scoreColor(e.severity).withOpacity(0.15),
                          labelStyle:
                              TextStyle(color: _scoreColor(e.severity)),
                          padding: EdgeInsets.zero,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),

          // ── Trip history ─────────────────────────────────────────────────
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text('Trip History',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                if (trips.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No trips recorded yet.',
                        style: TextStyle(color: Colors.grey)),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: trips.length,
                    itemBuilder: (_, i) => _TripTile(trip: trips[i]),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  IconData _eventIcon(DamageEventType type) {
    switch (type) {
      case DamageEventType.harshAcceleration:
        return Icons.arrow_upward;
      case DamageEventType.harshBraking:
        return Icons.arrow_downward;
      case DamageEventType.sharpTurn:
        return Icons.turn_right;
      case DamageEventType.highRpm:
        return Icons.speed;
      case DamageEventType.overheating:
        return Icons.thermostat;
      case DamageEventType.lowBattery:
        return Icons.battery_alert;
    }
  }
}

class _TripTile extends StatelessWidget {
  final Trip trip;
  const _TripTile({required this.trip});

  Color _scoreColor(double s) {
    if (s < 30) return Colors.green;
    if (s < 60) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, HH:mm');
    final duration = trip.duration;
    final durationStr =
        '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            _scoreColor(trip.averageDamageScore).withOpacity(0.2),
        child: Text(
          trip.averageDamageScore.toStringAsFixed(0),
          style: TextStyle(
              color: _scoreColor(trip.averageDamageScore),
              fontWeight: FontWeight.bold,
              fontSize: 13),
        ),
      ),
      title: Text(fmt.format(trip.startTime)),
      subtitle: Text(
          '${trip.distanceKm.toStringAsFixed(1)} km · $durationStr · '
          '${trip.damageEvents.length} events'),
      trailing: Icon(Icons.chevron_right,
          color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }
}
