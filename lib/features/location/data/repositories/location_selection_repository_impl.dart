import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../domain/repositories/location_selection_repository.dart';
import '../models/location_model.dart';
import '../datasources/local_data_source.dart';
import '../datasources/remote_data_source.dart';

class LocationSelectionRepositoryImpl implements LocationSelectionRepository {
  final LocationLocalDataSource localDataSource;
  final LocationRemoteDataSource remoteDataSource;

  LocationSelectionRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  @override
  Future<List<LocationModel>> getRecentLocations() async {
    return await localDataSource.getRecentLocations();
  }

  @override
  Future<void> saveLocation(LocationModel location) async {
    await localDataSource.saveLocation(location);
  }

  @override
  Future<void> toggleFavorite(String locationId) async {
    await localDataSource.toggleFavorite(locationId);
  }

  @override
  Future<LatLng> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permissions are permanently denied, we cannot request permissions.',
        );
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      throw Exception('Failed to get current location: $e');
    }
  }

  @override
  Future<List<LocationModel>> searchPlaces(String query) async {
    return await remoteDataSource.searchPlaces(query);
  }

  @override
  Future<LocationModel?> reverseGeocode(LatLng coordinates) async {
    return await remoteDataSource.reverseGeocode(coordinates);
  }

  @override
  Future<List<LocationModel>> getAutocompleteSuggestions(String query) async {
    return await remoteDataSource.getAutocompleteSuggestions(query);
  }
}
