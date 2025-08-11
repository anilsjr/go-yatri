import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationEntity {
  final String id;
  final String name;
  final String address;
  final LatLng? coordinates;
  final bool isFavorite;
  final bool isRecent;

  LocationEntity({
    required this.id,
    required this.name,
    required this.address,
    this.coordinates,
    this.isFavorite = false,
    this.isRecent = false,
  });

  LocationEntity copyWith({
    String? id,
    String? name,
    String? address,
    LatLng? coordinates,
    bool? isFavorite,
    bool? isRecent,
  }) {
    return LocationEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      coordinates: coordinates ?? this.coordinates,
      isFavorite: isFavorite ?? this.isFavorite,
      isRecent: isRecent ?? this.isRecent,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'coordinates': coordinates != null
          ? {
              'latitude': coordinates!.latitude,
              'longitude': coordinates!.longitude,
            }
          : null,
      'isFavorite': isFavorite,
      'isRecent': isRecent,
    };
  }

  factory LocationEntity.fromJson(Map<String, dynamic> json) {
    return LocationEntity(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      coordinates: json['coordinates'] != null
          ? LatLng(
              json['coordinates']['latitude'],
              json['coordinates']['longitude'],
            )
          : null,
      isFavorite: json['isFavorite'] ?? false,
      isRecent: json['isRecent'] ?? false,
    );
  }
}
