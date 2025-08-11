import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/models/location_model.dart';

abstract class LocationRepository {
  Future<List<LocationModel>> getRecentLocations();
  Future<void> saveLocation(LocationModel location);
  Future<void> toggleFavorite(String locationId);
  Future<LatLng> getCurrentLocation();
  Future<List<LocationModel>> searchPlaces(String query);
}
