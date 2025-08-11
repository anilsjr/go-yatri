import 'package:flutter/foundation.dart';

class LocationModel {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final bool isFavorite;
  final DateTime timestamp;

  LocationModel({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.isFavorite = false,
    required this.timestamp,
  });

  LocationModel copyWith({
    String? id,
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    bool? isFavorite,
    DateTime? timestamp,
  }) {
    return LocationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isFavorite: isFavorite ?? this.isFavorite,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'isFavorite': isFavorite,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      isFavorite: json['isFavorite'] ?? false,
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
