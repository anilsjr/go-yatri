import 'dart:convert';
import 'package:goyatri/features/location/domain/entities/location_entity.dart';
import 'package:goyatri/storage/local_share_preference.dart';

class LocationRepository {
  static const String _recentLocationsKey = 'recent_locations';
  static const String _favoriteLocationsKey = 'favorite_locations';
  
  // Get recent locations
  Future<List<LocationEntity>> getRecentLocations() async {
    final locationsString = await LocalStorage.getString(_recentLocationsKey);
    if (locationsString == null) return [];
    
    final List<dynamic> decodedList = jsonDecode(locationsString);
    return decodedList
        .map((item) => LocationEntity.fromJson(item))
        .toList();
  }
  
  // Save recent location
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
      jsonEncode(limitedLocations.map((e) => e.toJson()).toList())
    );
  }
  
  // Get favorite locations
  Future<List<LocationEntity>> getFavoriteLocations() async {
    final locationsString = await LocalStorage.getString(_favoriteLocationsKey);
    if (locationsString == null) return [];
    
    final List<dynamic> decodedList = jsonDecode(locationsString);
    return decodedList
        .map((item) => LocationEntity.fromJson(item))
        .toList();
  }
  
  // Toggle favorite location
  Future<void> toggleFavoriteLocation(LocationEntity location) async {
    final favorites = await getFavoriteLocations();
    
    final index = favorites.indexWhere((loc) => loc.id == location.id);
    if (index >= 0) {
      // Remove from favorites
      favorites.removeAt(index);
    } else {
      // Add to favorites
      favorites.add(location.copyWith(isFavorite: true));
    }
    
    // Save to storage
    await LocalStorage.saveString(
      _favoriteLocationsKey, 
      jsonEncode(favorites.map((e) => e.toJson()).toList())
    );
  }
  
  // Check if location is favorite
  Future<bool> isLocationFavorite(String locationId) async {
    final favorites = await getFavoriteLocations();
    return favorites.any((location) => location.id == locationId);
  }
}
