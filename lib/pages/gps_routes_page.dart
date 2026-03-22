import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../models/trip.dart';
import '../services/location_service.dart';
import '../services/trip_service.dart';
import '../services/gemini_service.dart';
import '../theme/app_theme.dart';
import '../widgets/automotive_widgets.dart';

class GpsRoutesPage extends StatefulWidget {
  const GpsRoutesPage({super.key});

  @override
  State<GpsRoutesPage> createState() => _GpsRoutesPageState();
}

class _GpsRoutesPageState extends State<GpsRoutesPage> {
  final _locationService = LocationService();
  final _tripService = TripService();
  final _gemini = GeminiService();

  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  bool _tracking = false;
  bool _permissionDenied = false;
  List<LatLng> _livePolyline = [];

  StreamSubscription<dynamic>? _positionSub;
  StreamSubscription<Waypoint>? _waypointSub;

  String? _aiRecommendation;
  bool _loadingAI = false;

  /// Dark map style — minimal automotive look.
  static const String _darkMapStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#0a0a0f"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#9e9e9e"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#0a0a0f"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#1e1e2a"}]},
  {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#13131a"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#2a2a38"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#050510"}]},
  {"featureType":"poi","elementType":"labels","stylers":[{"visibility":"off"}]},
  {"featureType":"transit","stylers":[{"visibility":"off"}]}
]
''';

  @override
  void initState() {
    super.initState();
    _tripService.loadHistory();
    _initLocation();
  }

  Future<void> _initLocation() async {
    final granted = await _locationService.requestPermission();
    if (!granted) {
      if (mounted) setState(() => _permissionDenied = true);
      return;
    }

    _positionSub = _locationService.positionStream.listen((pos) {
      if (!mounted) return;
      final latLng = LatLng(pos.latitude, pos.longitude);
      setState(() => _currentPosition = latLng);
      _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
    });

    _waypointSub = _locationService.waypointStream.listen((wp) {
      if (!mounted) return;
      setState(() => _livePolyline.add(LatLng(wp.latitude, wp.longitude)));
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _waypointSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _toggleTracking() async {
    if (_tracking) {
      _locationService.stopTracking();
      setState(() => _tracking = false);
    } else {
      _livePolyline.clear();
      await _locationService.startTracking();
      setState(() => _tracking = true);
    }
  }

  Future<void> _getRouteRecommendation() async {
    final trips = _tripService.tripHistory;
    if (trips.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Record at least 2 trips to get route recommendations.'),
      ));
      return;
    }

    setState(() {
      _loadingAI = true;
      _aiRecommendation = null;
    });

    final summary = trips.take(5).map((t) {
      return 'Trip ${t.id}: ${t.distanceKm.toStringAsFixed(1)} km, '
          'damage score ${t.averageDamageScore.toStringAsFixed(0)}, '
          'duration ${t.duration.inMinutes}min';
    }).join('\n');

    final result = await _gemini.getRouteRecommendation(summary);
    if (mounted) {
      setState(() {
        _loadingAI = false;
        _aiRecommendation = result;
      });
    }
  }

  Set<Polyline> _buildPolylines() {
    final polylines = <Polyline>{};

    if (_livePolyline.length >= 2) {
      polylines.add(Polyline(
        polylineId: const PolylineId('live'),
        points: _livePolyline,
        color: AppTheme.racingRed,
        width: 5,
      ));
    }

    final trips = _tripService.tripHistory;
    final colors = [
      AppTheme.electricBlue,
      AppTheme.amber,
      AppTheme.successGreen,
    ];
    for (int i = 0; i < trips.length && i < 3; i++) {
      final pts = trips[i]
          .waypoints
          .map((w) => LatLng(w.latitude, w.longitude))
          .toList();
      if (pts.length >= 2) {
        polylines.add(Polyline(
          polylineId: PolylineId('trip_$i'),
          points: pts,
          color: colors[i % colors.length],
          width: 3,
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ));
      }
    }
    return polylines;
  }

  @override
  Widget build(BuildContext context) {
    if (_permissionDenied) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off,
                  size: 64, color: AppTheme.onSurfaceDim),
              const SizedBox(height: 16),
              Text(
                'Location permission denied.\nPlease enable it in system settings.',
                textAlign: TextAlign.center,
                style: GoogleFonts.rajdhani(
                  color: AppTheme.onSurfaceDim,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final trips = _tripService.tripHistory;

    return SingleChildScrollView(
      child: Column(
        children: [
          // ── Dark map with red route ────────────────────────────────────
          Stack(
            children: [
              SizedBox(
                height: 300,
                child: GoogleMap(
                  onMapCreated: (c) {
                    _mapController = c;
                    c.setMapStyle(_darkMapStyle);
                  },
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition ??
                        const LatLng(51.5074, -0.1278),
                    zoom: 15,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  polylines: _buildPolylines(),
                ),
              ),
              // Top gradient overlay
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppTheme.background,
                        AppTheme.background.withOpacity(0),
                      ],
                    ),
                  ),
                ),
              ),
              // Map controls overlay
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Track button
                    GestureDetector(
                      onTap: _toggleTracking,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.surface.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _tracking
                                ? AppTheme.racingRed
                                : AppTheme.electricBlue,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_tracking) ...[
                              const StatusLed(color: AppTheme.racingRed),
                              const SizedBox(width: 6),
                            ],
                            Icon(
                              _tracking
                                  ? Icons.stop_circle_outlined
                                  : Icons.play_circle_outlined,
                              color: _tracking
                                  ? AppTheme.racingRed
                                  : AppTheme.electricBlue,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _tracking ? 'STOP TRACKING' : 'START TRACKING',
                              style: GoogleFonts.rajdhani(
                                color: _tracking
                                    ? AppTheme.racingRed
                                    : AppTheme.electricBlue,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Re-centre button
                    GestureDetector(
                      onTap: () {
                        if (_currentPosition != null) {
                          _mapController?.animateCamera(
                            CameraUpdate.newLatLng(_currentPosition!),
                          );
                        }
                      },
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppTheme.surface.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFF2A2A38)),
                        ),
                        child: const Icon(
                          Icons.my_location,
                          color: AppTheme.onSurface,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Live stats row ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                _StatPill(
                    label: 'WAYPOINTS',
                    value: '${_livePolyline.length}',
                    icon: Icons.place_outlined),
                const SizedBox(width: 8),
                _StatPill(
                    label: 'TRIPS',
                    value: '${trips.length}',
                    icon: Icons.history_outlined),
                const SizedBox(width: 8),
                _StatPill(
                    label: 'STATUS',
                    value: _tracking ? 'ON' : 'OFF',
                    icon: Icons.sensors,
                    valueColor: _tracking
                        ? AppTheme.successGreen
                        : AppTheme.onSurfaceDim),
              ],
            ),
          ),

          // ── AI Route recommendation ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: SizedBox(
              width: double.infinity,
              child: AutomotiveButton(
                onPressed: _loadingAI ? null : _getRouteRecommendation,
                icon: Icons.psychology,
                label: _loadingAI ? 'ANALYSING…' : 'AI ROUTE RECOMMENDATION',
                color: AppTheme.electricBlue,
                loading: _loadingAI,
              ),
            ),
          ),

          if (_aiRecommendation != null) ...[
            DashCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.route,
                          color: AppTheme.electricBlue, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'AI ROUTE RECOMMENDATION',
                        style: GoogleFonts.rajdhani(
                          color: AppTheme.electricBlue,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SelectableText(
                    _aiRecommendation!,
                    style: GoogleFonts.rajdhani(
                      color: AppTheme.onSurface,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // ── Route history ─────────────────────────────────────────────
          DashCard(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ROUTE HISTORY',
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
                        'No recorded routes yet.',
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
                    itemBuilder: (_, i) {
                      final trip = trips[i];
                      final fmt = DateFormat('MMM d, HH:mm');
                      final routeColors = [
                        AppTheme.electricBlue,
                        AppTheme.amber,
                        AppTheme.successGreen,
                      ];
                      final routeColor = routeColors[i % routeColors.length];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: routeColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: routeColor.withOpacity(0.4)),
                              ),
                              child: Center(
                                child: Text(
                                  '${i + 1}',
                                  style: GoogleFonts.orbitron(
                                    color: routeColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
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
                                    '${trip.distanceKm.toStringAsFixed(1)} km · '
                                    '${trip.waypoints.length} waypoints',
                                    style: GoogleFonts.rajdhani(
                                      color: AppTheme.onSurfaceDim,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (trip.waypoints.length >= 2)
                              IconButton(
                                icon: const Icon(Icons.map_outlined,
                                    size: 18),
                                color: AppTheme.onSurfaceDim,
                                onPressed: () => _showRouteOnMap(trip),
                                tooltip: 'Show on map',
                              ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showRouteOnMap(Trip trip) {
    if (trip.waypoints.isEmpty) return;
    final first = trip.waypoints.first;
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(LatLng(first.latitude, first.longitude)),
    );
  }
}

// ── Stat pill ─────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? valueColor;

  const _StatPill({
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF2A2A38)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: AppTheme.onSurfaceDim),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: GoogleFonts.rajdhani(
                    color: AppTheme.onSurfaceDim,
                    fontSize: 9,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.orbitron(
                    color: valueColor ?? AppTheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
