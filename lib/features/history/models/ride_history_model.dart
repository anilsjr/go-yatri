import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RideHistoryModel {
  final String id;
  final DateTime timestamp;
  final String vehicleType;
  final String startLocation;
  final String endLocation;
  final double fare;
  final String driverName;
  final String driverRating;
  final LatLng startCoordinates;
  final LatLng endCoordinates;

  RideHistoryModel({
    required this.id,
    required this.timestamp,
    required this.vehicleType,
    required this.startLocation,
    required this.endLocation,
    required this.fare,
    required this.driverName,
    required this.driverRating,
    required this.startCoordinates,
    required this.endCoordinates,
  });

  factory RideHistoryModel.fromMap(Map<String, dynamic> map) {
    return RideHistoryModel(
      id: map['id'],
      timestamp: DateTime.parse(map['timestamp']),
      vehicleType: map['vehicleType'],
      startLocation: map['startLocation'],
      endLocation: map['endLocation'],
      fare: map['fare'],
      driverName: map['driverName'],
      driverRating: map['driverRating'],
      startCoordinates: LatLng(map['startLat'], map['startLng']),
      endCoordinates: LatLng(map['endLat'], map['endLng']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'vehicleType': vehicleType,
      'startLocation': startLocation,
      'endLocation': endLocation,
      'fare': fare,
      'driverName': driverName,
      'driverRating': driverRating,
      'startLat': startCoordinates.latitude,
      'startLng': startCoordinates.longitude,
      'endLat': endCoordinates.latitude,
      'endLng': endCoordinates.longitude,
    };
  }
}
