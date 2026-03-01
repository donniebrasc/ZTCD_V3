import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/damage_event.dart';
import '../models/trip.dart';
import '../services/damage_service.dart';
import '../services/trip_service.dart';
import '../services/obd_service.dart';
import '../theme/app_theme.dart';
import '../widgets/automotive_widgets.dart';

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
    if (score < 30) return AppTheme.successGreen;
    if (score < 60) return AppTheme.amber;
    return AppTheme.racingRed;
  }

  String _scoreLabel(double score) {
    if (score < 30) return 'GOOD';
    if (score < 60) return 'FAIR';
    return 'POOR';
  }

  Future<void> _toggleTrip() async {
    if (_tripService.isRecording) {
      final trip = await _tripService.stopTrip();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'Trip saved — ${trip.distanceKm.toStringAsFixed(1)} km · '
            'score ${trip.averageDamageScore.toStringAsFixed(0)}',
          ),
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
    final scoreColor = _scoreColor(_currentScore);
    final trips = _tripService.tripHistory;
    final isRecording = _tripService.isRecording;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // ── Speedometer-style damage gauge ──────────────────────────────
          DashCard(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'DAMAGE SCORE',
                      style: GoogleFonts.rajdhani(
                        color: AppTheme.onSurfaceDim,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (isRecording)
                      Row(
                        children: [
                          StatusLed(color: AppTheme.racingRed),
                          const SizedBox(width: 6),
                          Text(
                            'RECORDING',
                            style: GoogleFonts.rajdhani(
                              color: AppTheme.racingRed,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 200,
                  height: 120,
                  child: CustomPaint(
                    painter: _SpeedometerPainter(
                      value: _currentScore / 100,
                      color: scoreColor,
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currentScore.toStringAsFixed(0),
                              style: GoogleFonts.orbitron(
                                color: scoreColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 36,
                              ),
                            ),
                            Text(
                              _scoreLabel(_currentScore),
                              style: GoogleFonts.rajdhani(
                                color: scoreColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: AutomotiveButton(
                    onPressed: _toggleTrip,
                    icon: isRecording ? Icons.stop_circle_outlined : Icons.play_circle_outlined,
                    label: isRecording ? 'STOP RECORDING' : 'START TRIP RECORDING',
                    color: isRecording ? AppTheme.racingRed : AppTheme.successGreen,
                  ),
                ),
              ],
            ),
          ),

          // ── Score chart ─────────────────────────────────────────────────
          if (_scoreHistory.isNotEmpty)
            DashCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SCORE HISTORY',
                    style: GoogleFonts.rajdhani(
                      color: AppTheme.onSurfaceDim,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 110,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 25,
                          getDrawingHorizontalLine: (_) => FlLine(
                            color: const Color(0xFF2A2A38),
                            strokeWidth: 1,
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              interval: 50,
                              getTitlesWidget: (v, _) => Text(
                                v.toInt().toString(),
                                style: GoogleFonts.rajdhani(
                                  color: AppTheme.onSurfaceDim,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        minY: 0,
                        maxY: 100,
                        lineBarsData: [
                          LineChartBarData(
                            spots: _scoreHistory,
                            isCurved: true,
                            color: _scoreColor(_currentScore),
                            barWidth: 2,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: _scoreColor(_currentScore).withOpacity(0.1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── Recent events ─────────────────────────────────────────────
          DashCard(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RECENT EVENTS',
                  style: GoogleFonts.rajdhani(
                    color: AppTheme.onSurfaceDim,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                if (_recentEvents.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text(
                        'No damage events detected.',
                        style: GoogleFonts.rajdhani(
                          color: AppTheme.onSurfaceDim,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _recentEvents.length.clamp(0, 10),
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final e = _recentEvents[i];
                      final ec = _scoreColor(e.severity);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: ec.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: ec.withOpacity(0.4)),
                              ),
                              child: Icon(
                                _eventIcon(e.type),
                                color: ec,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.type.displayName.toUpperCase(),
                                    style: GoogleFonts.rajdhani(
                                      color: AppTheme.onSurface,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('HH:mm:ss')
                                        .format(e.timestamp),
                                    style: GoogleFonts.rajdhani(
                                      color: AppTheme.onSurfaceDim,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: ec.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: ec.withOpacity(0.4)),
                              ),
                              child: Text(
                                e.severity.toStringAsFixed(0),
                                style: GoogleFonts.orbitron(
                                  color: ec,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),

          // ── Trip history ──────────────────────────────────────────────
          DashCard(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TRIP HISTORY',
                  style: GoogleFonts.rajdhani(
                    color: AppTheme.onSurfaceDim,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                if (trips.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text(
                        'No trips recorded yet.',
                        style: GoogleFonts.rajdhani(
                          color: AppTheme.onSurfaceDim,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: trips.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) => _TripRow(trip: trips[i]),
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

// ── Speedometer arc painter ───────────────────────────────────────────────────

class _SpeedometerPainter extends CustomPainter {
  final double value; // 0.0 – 1.0
  final Color color;

  _SpeedometerPainter({required this.value, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.75;
    final radius = math.min(size.width, size.height) * 0.75;

    const startAngle = math.pi; // 180°
    const sweepFull = math.pi;  // 180° arc (left to right)

    final trackPaint = Paint()
      ..color = const Color(0xFF2A2A38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final valuePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final rect = Rect.fromCircle(
        center: Offset(cx, cy), radius: radius);

    // Track
    canvas.drawArc(rect, startAngle, sweepFull, false, trackPaint);

    // Glow + value arc
    final sweep = sweepFull * value;
    if (sweep > 0) {
      canvas.drawArc(rect, startAngle, sweep, false, glowPaint);
      canvas.drawArc(rect, startAngle, sweep, false, valuePaint);
    }

    // Tick marks
    final tickPaint = Paint()
      ..color = const Color(0xFF444455)
      ..strokeWidth = 1.5;

    for (int i = 0; i <= 10; i++) {
      final angle = startAngle + (sweepFull * i / 10);
      final inner = Offset(
        cx + (radius - 14) * math.cos(angle),
        cy + (radius - 14) * math.sin(angle),
      );
      final outer = Offset(
        cx + radius * math.cos(angle),
        cy + radius * math.sin(angle),
      );
      canvas.drawLine(inner, outer, tickPaint);
    }
  }

  @override
  bool shouldRepaint(_SpeedometerPainter old) =>
      old.value != value || old.color != color;
}

// ── Trip row ──────────────────────────────────────────────────────────────────

class _TripRow extends StatelessWidget {
  final Trip trip;
  const _TripRow({required this.trip});

  Color _scoreColor(double s) {
    if (s < 30) return AppTheme.successGreen;
    if (s < 60) return AppTheme.amber;
    return AppTheme.racingRed;
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('MMM d, HH:mm');
    final duration = trip.duration;
    final durationStr =
        '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    final sc = _scoreColor(trip.averageDamageScore);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: sc.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: sc.withOpacity(0.4)),
            ),
            child: Center(
              child: Text(
                trip.averageDamageScore.toStringAsFixed(0),
                style: GoogleFonts.orbitron(
                  color: sc,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fmt.format(trip.startTime),
                  style: GoogleFonts.rajdhani(
                    color: AppTheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${trip.distanceKm.toStringAsFixed(1)} km · $durationStr · '
                  '${trip.damageEvents.length} events',
                  style: GoogleFonts.rajdhani(
                    color: AppTheme.onSurfaceDim,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppTheme.onSurfaceDim, size: 18),
        ],
      ),
    );
  }
}
