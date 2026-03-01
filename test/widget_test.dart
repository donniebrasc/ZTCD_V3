import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ztcd_v3/main.dart';
import 'package:ztcd_v3/models/obd_data.dart';
import 'package:ztcd_v3/models/damage_event.dart';
import 'package:ztcd_v3/models/trip.dart';
import 'package:ztcd_v3/services/location_service.dart';

void main() {
  testWidgets('App renders main scaffold with navigation bar',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ZTCDApp());
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('DIAGNOSIS'), findsOneWidget);
    expect(find.text('DAMAGE'), findsOneWidget);
    expect(find.text('ROUTES'), findsOneWidget);
  });

  group('OBDData', () {
    test('empty factory returns zeroed data', () {
      final data = OBDData.empty();
      expect(data.rpm, 0);
      expect(data.speed, 0);
      expect(data.batteryVoltage, 0);
    });

    test('toJson / fromJson round-trip', () {
      final original = OBDData(
        rpm: 1500,
        speed: 60,
        coolantTemp: 85,
        engineLoad: 45,
        throttlePosition: 25,
        fuelLevel: 70,
        maf: 12.5,
        batteryVoltage: 14.2,
        timestamp: DateTime(2024, 1, 15, 10, 30),
      );
      final decoded = OBDData.fromJson(original.toJson());
      expect(decoded.rpm, original.rpm);
      expect(decoded.speed, original.speed);
      expect(decoded.coolantTemp, original.coolantTemp);
      expect(decoded.batteryVoltage, original.batteryVoltage);
    });

    test('toPromptString includes all sensor fields', () {
      final data = OBDData(
        rpm: 2000,
        speed: 80,
        coolantTemp: 90,
        engineLoad: 50,
        throttlePosition: 30,
        fuelLevel: 65,
        maf: 15,
        batteryVoltage: 14.0,
        timestamp: DateTime.now(),
      );
      final prompt = data.toPromptString();
      expect(prompt, contains('RPM'));
      expect(prompt, contains('Speed'));
      expect(prompt, contains('Coolant'));
      expect(prompt, contains('Battery'));
    });
  });

  group('DamageEvent', () {
    test('toJson / fromJson round-trip for all event types', () {
      for (final type in DamageEventType.values) {
        final event = DamageEvent(
          timestamp: DateTime(2024, 6, 1),
          type: type,
          severity: 55.0,
          value: 3.14,
        );
        final decoded = DamageEvent.fromJson(event.toJson());
        expect(decoded.type, type);
        expect(decoded.severity, event.severity);
        expect(decoded.value, event.value);
      }
    });

    test('DamageEventType displayName is non-empty', () {
      for (final type in DamageEventType.values) {
        expect(type.displayName, isNotEmpty);
      }
    });
  });

  group('Trip', () {
    test('Trip.start creates active trip with empty collections', () {
      final trip = Trip.start();
      expect(trip.isActive, isTrue);
      expect(trip.waypoints, isEmpty);
      expect(trip.damageEvents, isEmpty);
      expect(trip.distanceKm, 0);
    });

    test('Trip.copyWith sets endTime correctly', () {
      final trip = Trip.start();
      final end = DateTime(2024, 3, 20, 12, 0);
      final completed = trip.copyWith(endTime: end);
      expect(completed.isActive, isFalse);
      expect(completed.endTime, end);
    });

    test('Trip toJson / fromJson round-trip', () {
      final event = DamageEvent(
        timestamp: DateTime(2024, 1, 1),
        type: DamageEventType.harshBraking,
        severity: 70,
        value: -15,
      );
      final waypoint = Waypoint(
        latitude: 51.5,
        longitude: -0.12,
        timestamp: DateTime(2024, 1, 1),
      );
      final trip = Trip(
        id: 'test_id',
        startTime: DateTime(2024, 1, 1, 9, 0),
        endTime: DateTime(2024, 1, 1, 9, 30),
        distanceKm: 12.5,
        averageDamageScore: 35,
        waypoints: [waypoint],
        damageEvents: [event],
      );
      final decoded = Trip.fromJson(trip.toJson());
      expect(decoded.id, trip.id);
      expect(decoded.distanceKm, trip.distanceKm);
      expect(decoded.averageDamageScore, trip.averageDamageScore);
      expect(decoded.waypoints.length, 1);
      expect(decoded.damageEvents.length, 1);
      expect(decoded.waypoints.first.latitude, waypoint.latitude);
    });

    test('Trip duration is calculated correctly', () {
      final start = DateTime(2024, 1, 1, 8, 0, 0);
      final end = DateTime(2024, 1, 1, 8, 15, 0);
      final trip = Trip(
        id: '1',
        startTime: start,
        endTime: end,
        distanceKm: 5,
        averageDamageScore: 20,
        waypoints: [],
        damageEvents: [],
      );
      expect(trip.duration.inMinutes, 15);
    });
  });

  group('LocationService.calculateDistance', () {
    test('returns 0 for empty waypoints', () {
      expect(LocationService.calculateDistance([]), 0);
    });

    test('returns 0 for single waypoint', () {
      final wp = Waypoint(
          latitude: 51.5, longitude: -0.12, timestamp: DateTime.now());
      expect(LocationService.calculateDistance([wp]), 0);
    });

    test('calculates non-zero distance for two distinct waypoints', () {
      final wp1 = Waypoint(
          latitude: 51.5074, longitude: -0.1278, timestamp: DateTime.now());
      final wp2 = Waypoint(
          latitude: 51.5154, longitude: -0.1415, timestamp: DateTime.now());
      final dist = LocationService.calculateDistance([wp1, wp2]);
      expect(dist, greaterThan(0));
      // London city centre ~1.5 km apart
      expect(dist, lessThan(5));
    });
  });
}

