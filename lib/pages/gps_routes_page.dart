import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../models/trip.dart';
import '../services/location_service.dart';
import '../services/trip_service.dart';
import '../services/gemini_service.dart';

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
      setState(() =>
          _livePolyline.add(LatLng(wp.latitude, wp.longitude)));
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

    // Live route
    if (_livePolyline.length >= 2) {
      polylines.add(Polyline(
        polylineId: const PolylineId('live'),
        points: _livePolyline,
        color: Colors.blue,
        width: 4,
      ));
    }

    // Historical routes (last 3 trips)
    final trips = _tripService.tripHistory;
    final colors = [Colors.orange, Colors.green, Colors.purple];
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
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Location permission denied.\nPlease enable it in system settings.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final cs = Theme.of(context).colorScheme;
    final trips = _tripService.tripHistory;

    return SingleChildScrollView(
      child: Column(
        children: [
          // ── Map ───────────────────────────────────────────────────────────
          SizedBox(
            height: 300,
            child: Stack(
              children: [
                GoogleMap(
                  onMapCreated: (c) => _mapController = c,
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition ??
                        const LatLng(51.5074, -0.1278), // London default
                    zoom: 15,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  polylines: _buildPolylines(),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: FloatingActionButton.extended(
                    heroTag: 'trackingFab',
                    onPressed: _toggleTracking,
                    icon:
                        Icon(_tracking ? Icons.stop : Icons.play_arrow),
                    label: Text(_tracking ? 'Stop' : 'Track'),
                    backgroundColor:
                        _tracking ? cs.error : cs.primaryContainer,
                    foregroundColor:
                        _tracking ? cs.onError : cs.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),

          // ── Route recommendation ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: _loadingAI ? null : _getRouteRecommendation,
                    icon: _loadingAI
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.psychology),
                    label: Text(_loadingAI
                        ? 'Analysing…'
                        : 'AI Route Recommendation'),
                  ),
                ),
                if (_aiRecommendation != null) ...[
                  const SizedBox(height: 8),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.route, size: 18),
                              const SizedBox(width: 8),
                              Text('AI Recommendation',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SelectableText(_aiRecommendation!),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Trip routes list ─────────────────────────────────────────────
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Text('Route History',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                if (trips.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('No recorded routes yet.',
                        style: TextStyle(color: Colors.grey)),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: trips.length,
                    itemBuilder: (_, i) {
                      final trip = trips[i];
                      final fmt = DateFormat('MMM d, HH:mm');
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: cs.primaryContainer,
                          child: Text('${i + 1}',
                              style: TextStyle(
                                  color: cs.onPrimaryContainer,
                                  fontWeight: FontWeight.bold)),
                        ),
                        title: Text(fmt.format(trip.startTime)),
                        subtitle: Text(
                            '${trip.distanceKm.toStringAsFixed(1)} km · '
                            '${trip.waypoints.length} waypoints'),
                        trailing: trip.waypoints.length >= 2
                            ? IconButton(
                                icon: const Icon(Icons.map_outlined),
                                onPressed: () => _showRouteOnMap(trip),
                                tooltip: 'Show on map',
                              )
                            : null,
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
