import 'dart:convert';
import 'package:dio/dio.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/location_model.dart';

abstract class LocationRemoteDataSource {
  Future<List<LocationModel>> searchPlaces(String query);
  Future<LocationModel?> reverseGeocode(LatLng coordinates);
  Future<List<LocationModel>> getAutocompleteSuggestions(String query);
}

class LocationRemoteDataSourceImpl implements LocationRemoteDataSource {
  final String apiKey;
  final Dio dio = Dio();

  LocationRemoteDataSourceImpl({required this.apiKey});

  @override
  Future<List<LocationModel>> searchPlaces(String query) async {
    try {
      final String url =
          'https://maps.googleapis.com/maps/api/place/textsearch/json?query=$query&key=$apiKey';

      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        final List<dynamic> results = data['results'] ?? [];

        return results.map((place) {
          final geometry = place['geometry'];
          final location = geometry['location'];

          return LocationModel(
            id: place['place_id'] ?? '',
            name: place['name'] ?? '',
            address: place['formatted_address'] ?? '',
            latitude: location['lat']?.toDouble() ?? 0.0,
            longitude: location['lng']?.toDouble() ?? 0.0,
            timestamp: DateTime.now(),
          );
        }).toList();
      } else {
        throw Exception('Failed to search places: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching places: $e');
    }
  }

  @override
  Future<LocationModel?> reverseGeocode(LatLng coordinates) async {
    try {
      final String url =
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=${coordinates.latitude},${coordinates.longitude}&key=$apiKey';

      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        final List<dynamic> results = data['results'] ?? [];

        if (results.isNotEmpty) {
          final place = results.first;

          return LocationModel(
            id: place['place_id'] ?? '',
            name: _extractLocationName(place['address_components']),
            address: place['formatted_address'] ?? '',
            latitude: coordinates.latitude,
            longitude: coordinates.longitude,
            timestamp: DateTime.now(),
          );
        }
      } else {
        throw Exception('Failed to reverse geocode: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error reverse geocoding: $e');
    }
    return null;
  }

  @override
  Future<List<LocationModel>> getAutocompleteSuggestions(String query) async {
    try {
      final String url =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$apiKey';

      final response = await dio.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = response.data;
        final List<dynamic> predictions = data['predictions'] ?? [];

        return predictions.map((prediction) {
          return LocationModel(
            id: prediction['place_id'] ?? '',
            name: prediction['structured_formatting']['main_text'] ?? '',
            address: prediction['description'] ?? '',
            latitude: 0.0, // Will be fetched when selected
            longitude: 0.0, // Will be fetched when selected
            timestamp: DateTime.now(),
          );
        }).toList();
      } else {
        throw Exception(
          'Failed to get autocomplete suggestions: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error getting autocomplete suggestions: $e');
    }
  }

  String _extractLocationName(List<dynamic> addressComponents) {
    for (final component in addressComponents) {
      final types = List<String>.from(component['types'] ?? []);
      if (types.contains('establishment') ||
          types.contains('premise') ||
          types.contains('subpremise')) {
        return component['long_name'] ?? '';
      }
    }

    // Fallback to first component
    if (addressComponents.isNotEmpty) {
      return addressComponents.first['long_name'] ?? '';
    }

    return 'Unknown Location';
  }
}
