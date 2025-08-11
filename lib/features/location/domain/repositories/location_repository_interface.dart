import 'package:goyatri/features/location/domain/entities/location_entity.dart';

abstract class LocationRepositoryInterface {
  Future<List<LocationEntity>> getRecentLocations();
  Future<void> saveRecentLocation(LocationEntity location);
  Future<List<LocationEntity>> getFavoriteLocations();
  Future<void> addFavoriteLocation(LocationEntity location);
  Future<void> removeFavoriteLocation(String locationId);
  Future<void> clearRecentLocations();
  Future<void> clearFavoriteLocations();
}
