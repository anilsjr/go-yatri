import 'dart:convert';
import 'package:goyatri/features/location/domain/entities/location_entity.dart';
import 'package:goyatri/features/location/domain/repositories/location_repository_interface.dart';
import 'package:goyatri/storage/local_share_preference.dart';

class LocationRepository implements LocationRepositoryInterface {
  static const String _recentLocationsKey = 'recent_locations';
  static const String _favoriteLocationsKey = 'favorite_locations';

  @override
  Future<List<LocationEntity>> getRecentLocations() async {
    final locationsString = await LocalStorage.getString(_recentLocationsKey);
    if (locationsString == null) return [];

    final List<dynamic> decodedList = jsonDecode(locationsString);
    return decodedList.map((item) => LocationEntity.fromJson(item)).toList();
  }

  @override
  Future<void> saveRecentLocation(LocationEntity location) async {
    // Get existing locations
    final locations = await getRecentLocations();

    // Check if location already exists
    final index = locations.indexWhere((loc) => loc.id == location.id);
    if (index >= 0) {
      // Remove existing entry to move it to the top
      locations.removeAt(index);
    }

    // Add to the beginning of the list
    locations.insert(0, location.copyWith(isRecent: true));

    // Limit to 10 recent locations
    final limitedLocations = locations.take(10).toList();

    // Save to storage
    await LocalStorage.saveString(
      _recentLocationsKey,
      jsonEncode(limitedLocations.map((e) => e.toJson()).toList()),
    );
  }

  @override
  Future<List<LocationEntity>> getFavoriteLocations() async {
    final locationsString = await LocalStorage.getString(_favoriteLocationsKey);
    if (locationsString == null) return [];

    final List<dynamic> decodedList = jsonDecode(locationsString);
    return decodedList.map((item) => LocationEntity.fromJson(item)).toList();
  }

  @override
  Future<void> addFavoriteLocation(LocationEntity location) async {
    final favorites = await getFavoriteLocations();

    // Check if location is already a favorite
    final index = favorites.indexWhere((loc) => loc.id == location.id);
    if (index == -1) {
      favorites.add(location.copyWith(isFavorite: true));

      // Save to storage
      await LocalStorage.saveString(
        _favoriteLocationsKey,
        jsonEncode(favorites.map((e) => e.toJson()).toList()),
      );
    }
  }

  @override
  Future<void> removeFavoriteLocation(String locationId) async {
    final favorites = await getFavoriteLocations();

    favorites.removeWhere((location) => location.id == locationId);

    // Save to storage
    await LocalStorage.saveString(
      _favoriteLocationsKey,
      jsonEncode(favorites.map((e) => e.toJson()).toList()),
    );
  }

  @override
  Future<void> clearRecentLocations() async {
    await LocalStorage.remove(_recentLocationsKey);
  }

  @override
  Future<void> clearFavoriteLocations() async {
    await LocalStorage.remove(_favoriteLocationsKey);
  }

  // Additional utility methods
  Future<void> toggleFavoriteLocation(LocationEntity location) async {
    final favorites = await getFavoriteLocations();

    final index = favorites.indexWhere((loc) => loc.id == location.id);
    if (index >= 0) {
      // Remove from favorites
      await removeFavoriteLocation(location.id);
    } else {
      // Add to favorites
      await addFavoriteLocation(location);
    }
  }

  Future<bool> isLocationFavorite(String locationId) async {
    final favorites = await getFavoriteLocations();
    return favorites.any((location) => location.id == locationId);
  }
}
