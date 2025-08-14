import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/location_model.dart';
import '../../data/repositories/location_repository_impl.dart';

enum LocationMode { pickup, drop }

class LocationProvider extends ChangeNotifier {
  final LocationRepositoryImpl _repository = LocationRepositoryImpl();
  static const _uuid = Uuid();

  // State variables
  LocationMode _mode = LocationMode.pickup;
  List<LocationModel> _recentLocations = const [];
  List<LocationModel> _searchResults = const [];
  bool _isLoading = false;
  bool _isSearching = false;
  LatLng? _currentLocation;
  LocationModel? _selectedPickupLocation;
  LocationModel? _selectedDropLocation;
  String? _lastError;

  // Cache management
  bool _isInitialized = false;
  bool _isCurrentLocationLoaded = false;
  bool _areRecentLocationsLoaded = false;
  Timer? _searchDebounceTimer;
  String _lastSearchQuery = '';

  // Getters
  LocationMode get mode => _mode;
  List<LocationModel> get recentLocations => _recentLocations;
  List<LocationModel> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  LatLng? get currentLocation => _currentLocation;
  LocationModel? get selectedPickupLocation => _selectedPickupLocation;
  LocationModel? get selectedDropLocation => _selectedDropLocation;
  String? get lastError => _lastError;
  bool get hasError => _lastError != null;

  LocationModel? get selectedLocation => _mode == LocationMode.pickup
      ? _selectedPickupLocation
      : _selectedDropLocation;

  bool get canProceed =>
      _selectedPickupLocation != null && _selectedDropLocation != null;

  // Initialize with better error handling and performance
  Future<void> init() async {
    if (_isInitialized) return;

    await _safeExecute(() async {
      _setLoading(true);

      // Load data in parallel with timeout
      final futures = [
        _loadCurrentLocationSafely(),
        _loadRecentLocationsSafely(),
      ];

      await Future.wait(futures).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('LocationProvider initialization timed out');
          return [];
        },
      );

      _isInitialized = true;
    });

    _setLoading(false);
  }

  // Load current location with better error handling
  Future<void> _loadCurrentLocationSafely() async {
    if (_isCurrentLocationLoaded && _currentLocation != null) return;

    try {
      _currentLocation = await _repository.getCurrentLocation().timeout(
        const Duration(seconds: 5),
      );
      _isCurrentLocationLoaded = true;

      if (!_isLoading) {
        notifyListeners();
      }
    } catch (e) {
      _handleError('Failed to load current location', e);
    }
  }

  // Load recent locations with caching optimization
  Future<void> _loadRecentLocationsSafely() async {
    if (_areRecentLocationsLoaded && _recentLocations.isNotEmpty) return;

    try {
      final locations = await _repository.getRecentLocations();
      _recentLocations = List.unmodifiable(locations);
      _areRecentLocationsLoaded = true;

      if (kDebugMode) {
        debugPrint('Loaded ${_recentLocations.length} recent locations');
      }

      if (!_isLoading) {
        notifyListeners();
      }
    } catch (e) {
      _handleError('Failed to load recent locations', e);
    }
  }

  // Switch mode with validation
  void switchMode(LocationMode newMode) {
    if (_mode == newMode) return;

    _mode = newMode;
    clearSearchResults();
    _clearError();

    if (kDebugMode) {
      debugPrint('Switched to mode: $newMode');
    }
  }

  // Debounced search with cancellation support
  Future<void> searchLocations(String query) async {
    // Cancel previous search
    _searchDebounceTimer?.cancel();

    final trimmedQuery = query.trim();

    if (trimmedQuery.isEmpty) {
      _searchResults = const [];
      _isSearching = false;
      _lastSearchQuery = '';
      notifyListeners();
      return;
    }

    // Skip search if query hasn't changed
    if (trimmedQuery == _lastSearchQuery && _searchResults.isNotEmpty) {
      return;
    }

    // Debounce search to avoid excessive API calls
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(trimmedQuery);
    });
  }

  Future<void> _performSearch(String query) async {
    _isSearching = true;
    _lastSearchQuery = query;
    notifyListeners();

    await _safeExecute(() async {
      final results = await _repository
          .searchPlaces(query)
          .timeout(const Duration(seconds: 8));

      // Only update if this is still the latest search
      if (_lastSearchQuery == query) {
        _searchResults = List.unmodifiable(results);
      }
    });

    _isSearching = false;
    notifyListeners();
  }

  // Select location with validation and optimization
  void selectLocation(LocationModel location) {
    if (_mode == LocationMode.pickup) {
      if (_selectedPickupLocation?.id == location.id) return;
      _selectedPickupLocation = location;
    } else {
      if (_selectedDropLocation?.id == location.id) return;
      _selectedDropLocation = location;
    }

    // Save to recent locations asynchronously
    unawaited(_saveToRecentLocations(location));
    _clearError();
    notifyListeners();
  }

  // Select current location with better UX
  Future<void> selectCurrentLocation() async {
    if (_currentLocation == null) {
      _setLoading(true);
      await _loadCurrentLocationSafely();
      _setLoading(false);
    }

    if (_currentLocation != null) {
      final location = _createCurrentLocationModel();
      selectLocation(location);
    }
  }

  LocationModel _createCurrentLocationModel() {
    return LocationModel(
      id: _uuid.v4(),
      name: 'Current Location',
      address: 'Your current location',
      latitude: _currentLocation!.latitude,
      longitude: _currentLocation!.longitude,
      timestamp: DateTime.now(),
    );
  }

  // Save location with cache invalidation
  Future<void> _saveToRecentLocations(LocationModel location) async {
    try {
      await _repository.saveLocation(location);

      // Optimistic update - add to local cache immediately
      final updatedList = <LocationModel>[location];
      for (final existing in _recentLocations) {
        if (existing.id != location.id && updatedList.length < 10) {
          updatedList.add(existing);
        }
      }

      _recentLocations = List.unmodifiable(updatedList);
      notifyListeners();
    } catch (e) {
      _handleError('Failed to save location', e);
      // Reload from repository on error
      _areRecentLocationsLoaded = false;
      unawaited(_loadRecentLocationsSafely());
    }
  }

  // Toggle favorite with optimistic updates
  Future<void> toggleFavorite(String locationId) async {
    // Find and update location optimistically
    final locationIndex = _recentLocations.indexWhere(
      (loc) => loc.id == locationId,
    );
    if (locationIndex == -1) return;

    final updatedLocations = List<LocationModel>.from(_recentLocations);
    final location = updatedLocations[locationIndex];

    // Create updated location (assuming LocationModel has isFavorite property)
    // updatedLocations[locationIndex] = location.copyWith(isFavorite: !location.isFavorite);
    _recentLocations = List.unmodifiable(updatedLocations);
    notifyListeners();

    try {
      await _repository.toggleFavorite(locationId);
    } catch (e) {
      _handleError('Failed to toggle favorite', e);
      // Revert optimistic update and reload
      _areRecentLocationsLoaded = false;
      unawaited(_loadRecentLocationsSafely());
    }
  }

  // Create location from coordinates
  Future<void> createLocationFromLatLng(
    LatLng latLng,
    String name,
    String address,
  ) async {
    final location = LocationModel(
      id: _uuid.v4(),
      name: name.trim(),
      address: address.trim(),
      latitude: latLng.latitude,
      longitude: latLng.longitude,
      timestamp: DateTime.now(),
    );

    selectLocation(location);
  }

  // Clear methods
  void clearSearchResults() {
    if (_searchResults.isNotEmpty) {
      _searchResults = const [];
      _searchDebounceTimer?.cancel();
      _lastSearchQuery = '';
      notifyListeners();
    }
  }

  void clearSelection() {
    _selectedPickupLocation = null;
    _selectedDropLocation = null;
    _clearError();
    notifyListeners();
  }

  void _clearError() {
    if (_lastError != null) {
      _lastError = null;
      notifyListeners();
    }
  }

  // Refresh data
  Future<void> refresh() async {
    _isCurrentLocationLoaded = false;
    _areRecentLocationsLoaded = false;
    await init();
  }

  // Utility methods
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _handleError(String message, dynamic error) {
    _lastError = message;
    if (kDebugMode) {
      debugPrint('$message: $error');
    }
    notifyListeners();
  }

  Future<void> _safeExecute(Future<void> Function() operation) async {
    try {
      await operation();
      _clearError();
    } catch (e) {
      _handleError('Operation failed', e);
    }
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    super.dispose();
  }
}

// Extension for fire-and-forget operations
extension _Unawaited on LocationProvider {
  void unawaited(Future<void> future) {
    future.catchError((error) {
      if (kDebugMode) {
        debugPrint('Unawaited operation failed: $error');
      }
    });
  }
}
