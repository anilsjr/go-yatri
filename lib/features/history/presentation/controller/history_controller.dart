import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:goyatri/features/history/models/ride_history_model.dart';

class HistoryController extends ChangeNotifier {
  List<RideHistoryModel> _rideHistory = [];
  List<RideHistoryModel> get rideHistory => _rideHistory;

  final Uuid _uuid = const Uuid();

  Future<void> loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList('ride_history') ?? [];

      _rideHistory = historyJson
          .map((json) => RideHistoryModel.fromMap(jsonDecode(json)))
          .toList();

      // Sort by date, newest first
      _rideHistory.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      notifyListeners();
    } catch (e) {
      debugPrint('Error loading history: $e');
    }
  }

  Future<void> saveRide({
    required LatLng startLocation,
    required LatLng endLocation,
    required String startAddress,
    required String endAddress,
    required String vehicleType,
    required double fare,
    required String driverName,
    required String driverRating,
  }) async {
    try {
      final ride = RideHistoryModel(
        id: _uuid.v4(),
        timestamp: DateTime.now(),
        vehicleType: vehicleType,
        startLocation: startAddress,
        endLocation: endAddress,
        fare: fare,
        driverName: driverName,
        driverRating: driverRating,
        startCoordinates: startLocation,
        endCoordinates: endLocation,
      );

      _rideHistory.insert(0, ride);

      // Save to preferences
      final prefs = await SharedPreferences.getInstance();
      final historyJson = _rideHistory
          .map((ride) => jsonEncode(ride.toMap()))
          .toList();

      await prefs.setStringList('ride_history', historyJson);

      notifyListeners();
    } catch (e) {
      debugPrint('Error saving ride: $e');
    }
  }

  // Helper method to generate sample data
  Future<void> generateSampleHistory() async {
    // Clear existing data
    _rideHistory = [];

    // Create some sample locations in India
    final locations = [
      {
        'start': {'name': 'Connaught Place', 'lat': 28.6315, 'lng': 77.2167},
        'end': {'name': 'India Gate', 'lat': 28.6129, 'lng': 77.2295},
      },
      {
        'start': {'name': 'Cyber City', 'lat': 28.4961, 'lng': 77.0908},
        'end': {'name': 'DLF Mall of India', 'lat': 28.5671, 'lng': 77.3213},
      },
      {
        'start': {'name': 'Lodhi Gardens', 'lat': 28.5929, 'lng': 77.2209},
        'end': {'name': 'Humayun\'s Tomb', 'lat': 28.5933, 'lng': 77.2507},
      },
      {
        'start': {'name': 'Chandni Chowk', 'lat': 28.6506, 'lng': 77.2310},
        'end': {'name': 'Red Fort', 'lat': 28.6562, 'lng': 77.2410},
      },
    ];

    final vehicleTypes = ['Bike', 'Auto', 'Car'];
    final driverNames = ['Rajesh', 'Sunil', 'Amit', 'Vijay', 'Anil'];

    // Generate rides from the past 30 days
    final now = DateTime.now();

    for (int i = 0; i < locations.length; i++) {
      final location = locations[i];
      final vehicleType = vehicleTypes[i % vehicleTypes.length];
      final driverName = driverNames[i % driverNames.length];
      final driverRating = (3.5 + (i % 20) / 10).toStringAsFixed(1);
      final fare = 50.0 + (i * 30);
      final daysAgo = i * 2;

      final ride = RideHistoryModel(
        id: _uuid.v4(),
        timestamp: now.subtract(Duration(days: daysAgo)),
        vehicleType: vehicleType,
        startLocation: location['start']!['name'] as String,
        endLocation: location['end']!['name'] as String,
        fare: fare,
        driverName: driverName,
        driverRating: driverRating,
        startCoordinates: LatLng(
          location['start']!['lat'] as double,
          location['start']!['lng'] as double,
        ),
        endCoordinates: LatLng(
          location['end']!['lat'] as double,
          location['end']!['lng'] as double,
        ),
      );

      _rideHistory.add(ride);
    }

    // Save to preferences
    final prefs = await SharedPreferences.getInstance();
    final historyJson = _rideHistory
        .map((ride) => jsonEncode(ride.toMap()))
        .toList();

    await prefs.setStringList('ride_history', historyJson);

    notifyListeners();
  }
}
