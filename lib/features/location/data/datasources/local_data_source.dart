import 'dart:convert';
import '../models/location_model.dart';
import '../../../../storage/local_share_preference.dart';

abstract class LocationLocalDataSource {
  Future<List<LocationModel>> getRecentLocations();
  Future<void> saveLocation(LocationModel location);
  Future<void> toggleFavorite(String locationId);
  Future<List<LocationModel>> getFavoriteLocations();
  Future<void> clearRecentLocations();
}

class LocationLocalDataSourceImpl implements LocationLocalDataSource {
  static const String _recentLocationsKey = 'recent_locations';
  static const String _favoriteLocationsKey = 'favorite_locations';

  @override
  Future<List<LocationModel>> getRecentLocations() async {
    final locationsString = await LocalStorage.getString(_recentLocationsKey);
    if (locationsString == null) return [];

    final List<dynamic> decodedList = jsonDecode(locationsString);
    return decodedList.map((item) => LocationModel.fromJson(item)).toList();
  }

  @override
  Future<void> saveLocation(LocationModel location) async {
    final locations = await getRecentLocations();

    // Remove if already exists
    locations.removeWhere((loc) => loc.id == location.id);

    // Add to beginning
    locations.insert(0, location.copyWith(timestamp: DateTime.now()));

    // Limit to 10 recent locations
    final limitedLocations = locations.take(10).toList();

    await LocalStorage.saveString(
      _recentLocationsKey,
      jsonEncode(limitedLocations.map((e) => e.toJson()).toList()),
    );
  }

  @override
  Future<List<LocationModel>> getFavoriteLocations() async {
    final locationsString = await LocalStorage.getString(_favoriteLocationsKey);
    if (locationsString == null) return [];

    final List<dynamic> decodedList = jsonDecode(locationsString);
    return decodedList.map((item) => LocationModel.fromJson(item)).toList();
  }

  @override
  Future<void> toggleFavorite(String locationId) async {
    final recentLocations = await getRecentLocations();
    final favoriteLocations = await getFavoriteLocations();

    // Find location in recent locations
    final locationIndex = recentLocations.indexWhere(
      (loc) => loc.id == locationId,
    );
    if (locationIndex == -1) return;

    final location = recentLocations[locationIndex];

    // Check if already in favorites
    final favoriteIndex = favoriteLocations.indexWhere(
      (loc) => loc.id == locationId,
    );

    if (favoriteIndex >= 0) {
      // Remove from favorites
      favoriteLocations.removeAt(favoriteIndex);
    } else {
      // Add to favorites
      favoriteLocations.add(location.copyWith(isFavorite: true));
    }

    // Update recent locations with new favorite status
    recentLocations[locationIndex] = location.copyWith(
      isFavorite: favoriteIndex == -1,
    );

    // Save both lists
    await LocalStorage.saveString(
      _favoriteLocationsKey,
      jsonEncode(favoriteLocations.map((e) => e.toJson()).toList()),
    );

    await LocalStorage.saveString(
      _recentLocationsKey,
      jsonEncode(recentLocations.map((e) => e.toJson()).toList()),
    );
  }

  @override
  Future<void> clearRecentLocations() async {
    await LocalStorage.remove(_recentLocationsKey);
  }
}
