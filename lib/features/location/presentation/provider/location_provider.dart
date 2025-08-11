import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/location_model.dart';
import '../../data/repositories/location_repository_impl.dart';
import '../../domain/repositories/location_selection_repository.dart';

enum LocationMode { pickup, drop }

class LocationProvider extends ChangeNotifier {
  final LocationRepository _repository = LocationRepositoryImpl();
  final _uuid = Uuid();

  LocationMode _mode = LocationMode.pickup;
  List<LocationModel> _recentLocations = [];
  List<LocationModel> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  LatLng? _currentLocation;
  LocationModel? _selectedPickupLocation;
  LocationModel? _selectedDropLocation;

  // Getters
  LocationMode get mode => _mode;
  List<LocationModel> get recentLocations => _recentLocations;
  List<LocationModel> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  LatLng? get currentLocation => _currentLocation;
  LocationModel? get selectedPickupLocation => _selectedPickupLocation;
  LocationModel? get selectedDropLocation => _selectedDropLocation;

  LocationModel? get selectedLocation => _mode == LocationMode.pickup
      ? _selectedPickupLocation
      : _selectedDropLocation;

  // Initialize the provider
  Future<void> init() async {
    _setLoading(true);
    await _loadCurrentLocation();
    await _loadRecentLocations();
    _setLoading(false);
  }

  // Load user's current location
  Future<void> _loadCurrentLocation() async {
    try {
      _currentLocation = await _repository.getCurrentLocation();
      notifyListeners();
    } catch (e) {
      print('Error loading current location: $e');
    }
  }

  // Load recent locations from storage
  Future<void> _loadRecentLocations() async {
    try {
      _recentLocations = await _repository.getRecentLocations();
      notifyListeners();
    } catch (e) {
      print('Error loading recent locations: $e');
    }
  }

  // Switch between pickup and drop mode
  void switchMode(LocationMode newMode) {
    _mode = newMode;
    _searchResults = [];
    notifyListeners();
  }

  // Search for locations based on query
  Future<void> searchLocations(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      _searchResults = await _repository.searchPlaces(query);
    } catch (e) {
      print('Error searching locations: $e');
      _searchResults = [];
    }

    _isSearching = false;
    notifyListeners();
  }

  // Select a location (from search or recent)
  void selectLocation(LocationModel location) {
    if (_mode == LocationMode.pickup) {
      _selectedPickupLocation = location;
    } else {
      _selectedDropLocation = location;
    }

    // Save to recent locations
    _saveToRecentLocations(location);
    notifyListeners();
  }

  // Select current location
  Future<void> selectCurrentLocation() async {
    if (_currentLocation == null) {
      await _loadCurrentLocation();
    }

    if (_currentLocation != null) {
      final location = LocationModel(
        id: _uuid.v4(),
        name: 'Current Location',
        address: 'Your current location',
        latitude: _currentLocation!.latitude,
        longitude: _currentLocation!.longitude,
        timestamp: DateTime.now(),
      );

      selectLocation(location);
    }
  }

  // Save a location to recent locations
  Future<void> _saveToRecentLocations(LocationModel location) async {
    try {
      await _repository.saveLocation(location);
      await _loadRecentLocations(); // Reload the list
    } catch (e) {
      print('Error saving to recent locations: $e');
    }
  }

  // Toggle favorite status for a location
  Future<void> toggleFavorite(String locationId) async {
    try {
      await _repository.toggleFavorite(locationId);
      await _loadRecentLocations(); // Reload to reflect changes
    } catch (e) {
      print('Error toggling favorite: $e');
    }
  }

  // Create location from LatLng (when selecting from map)
  Future<void> createLocationFromLatLng(
    LatLng latLng,
    String name,
    String address,
  ) async {
    final location = LocationModel(
      id: _uuid.v4(),
      name: name,
      address: address,
      latitude: latLng.latitude,
      longitude: latLng.longitude,
      timestamp: DateTime.now(),
    );

    selectLocation(location);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Clear search results
  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }
}
