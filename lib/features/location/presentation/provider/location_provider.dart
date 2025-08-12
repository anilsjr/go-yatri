import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/location_model.dart';
import '../../data/repositories/location_repository_impl.dart';

enum LocationMode { pickup, drop }

class LocationProvider extends ChangeNotifier {
  final LocationRepositoryImpl _repository = LocationRepositoryImpl();
  final _uuid = Uuid();

  LocationMode _mode = LocationMode.pickup;
  List<LocationModel> _recentLocations = [];
  List<LocationModel> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  LatLng? _currentLocation;
  LocationModel? _selectedPickupLocation;
  LocationModel? _selectedDropLocation;
  
  // Cache flags to avoid redundant API calls
  bool _isInitialized = false;
  bool _isCurrentLocationLoaded = false;
  bool _areRecentLocationsLoaded = false;

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

  // Initialize the provider with caching
  Future<void> init() async {
    if (_isInitialized) return; // Avoid redundant initialization
    
    _setLoading(true);
    
    // Load data in parallel for faster initialization
    await Future.wait([
      _loadCurrentLocation(),
      _loadRecentLocations(),
    ]);
    
    _isInitialized = true;
    _setLoading(false);
  }

  // Load user's current location with caching
  Future<void> _loadCurrentLocation() async {
    if (_isCurrentLocationLoaded && _currentLocation != null) return;
    
    try {
      _currentLocation = await _repository.getCurrentLocation();
      _isCurrentLocationLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading current location: $e');
    }
  }

  // Load recent locations from storage with caching
  Future<void> _loadRecentLocations() async {
    if (_areRecentLocationsLoaded && _recentLocations.isNotEmpty) return;
    
    try {
      _recentLocations = await _repository.getRecentLocations();
      _areRecentLocationsLoaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading recent locations: $e');
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
      debugPrint('Error searching locations: $e');
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
      // Invalidate cache and reload
      _areRecentLocationsLoaded = false;
      await _loadRecentLocations();
    } catch (e) {
      debugPrint('Error saving to recent locations: $e');
    }
  }

  // Toggle favorite status for a location
  Future<void> toggleFavorite(String locationId) async {
    try {
      await _repository.toggleFavorite(locationId);
      // Invalidate cache and reload
      _areRecentLocationsLoaded = false;
      await _loadRecentLocations();
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
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
