import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dio/dio.dart';
import '../models/location_model.dart';
import '../../domain/repositories/location_selection_repository.dart';

class LocationRepositoryImpl implements LocationRepository {
  final Dio _dio = Dio();
  final String _googleApiKey = 'AIzaSyBIJfuTJME0jr6ubJCNuDK9oUEHMWNrzEY';
  final String _storageKey = 'recent_locations';

  @override
  Future<List<LocationModel>> getRecentLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationsJson = prefs.getStringList(_storageKey) ?? [];

      return locationsJson
          .map((json) => LocationModel.fromJson(jsonDecode(json)))
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } catch (e) {
      print('Error getting recent locations: $e');
      return [];
    }
  }

  @override
  Future<void> saveLocation(LocationModel location) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationsJson = prefs.getStringList(_storageKey) ?? [];

      // Check if location already exists
      final existingLocations = locationsJson
          .map((json) => LocationModel.fromJson(jsonDecode(json)))
          .toList();

      final existingIndex = existingLocations.indexWhere(
        (loc) => loc.id == location.id,
      );

      if (existingIndex >= 0) {
        // Update existing location
        existingLocations[existingIndex] = location;
      } else {
        // Add new location
        existingLocations.add(location);
      }

      // Save back to SharedPreferences
      final updatedJson = existingLocations
          .map((location) => jsonEncode(location.toJson()))
          .toList();

      await prefs.setStringList(_storageKey, updatedJson);
    } catch (e) {
      print('Error saving location: $e');
    }
  }

  @override
  Future<void> toggleFavorite(String locationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final locationsJson = prefs.getStringList(_storageKey) ?? [];

      final locations = locationsJson
          .map((json) => LocationModel.fromJson(jsonDecode(json)))
          .toList();

      final index = locations.indexWhere((loc) => loc.id == locationId);

      if (index >= 0) {
        final location = locations[index];
        locations[index] = location.copyWith(isFavorite: !location.isFavorite);

        final updatedJson = locations
            .map((location) => jsonEncode(location.toJson()))
            .toList();

        await prefs.setStringList(_storageKey, updatedJson);
      }
    } catch (e) {
      print('Error toggling favorite: $e');
    }
  }

  @override
  Future<LatLng> getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      print('Error getting current location: $e');
      // Default to a fallback location
      return LatLng(28.7041, 77.1025); // Default to Delhi
    }
  }

  @override
  Future<List<LocationModel>> searchPlaces(String query) async {
    if (query.isEmpty) return [];

    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json',
        queryParameters: {
          'input': query,
          'key': _googleApiKey,
          'components': 'country:in', // Restrict to India
        },
      );

      if (response.statusCode == 200) {
        final predictions = response.data['predictions'] as List;

        List<LocationModel> results = [];

        for (var prediction in predictions) {
          final placeId = prediction['place_id'];
          final details = await getPlaceDetails(placeId);

          if (details != null) {
            results.add(details);
          }
        }

        return results;
      }

      return [];
    } catch (e) {
      print('Error searching places: $e');
      return [];
    }
  }

  Future<LocationModel?> getPlaceDetails(String placeId) async {
    try {
      final response = await _dio.get(
        'https://maps.googleapis.com/maps/api/place/details/json',
        queryParameters: {
          'place_id': placeId,
          'key': _googleApiKey,
          'fields': 'name,formatted_address,geometry',
        },
      );

      if (response.statusCode == 200 && response.data['status'] == 'OK') {
        final result = response.data['result'];
        final location = result['geometry']['location'];

        return LocationModel(
          id: placeId,
          name: result['name'],
          address: result['formatted_address'],
          latitude: location['lat'],
          longitude: location['lng'],
          timestamp: DateTime.now(),
        );
      }

      return null;
    } catch (e) {
      print('Error getting place details: $e');
      return null;
    }
  }
}
