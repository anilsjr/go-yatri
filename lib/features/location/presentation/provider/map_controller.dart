import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:goyatri/core/util/app_constant.dart' show AppConstant;
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class MapController extends ChangeNotifier {
  late BitmapDescriptor markerIconGreen;
  late BitmapDescriptor markerIconRed;
  late BitmapDescriptor markerIconBike;
  late BitmapDescriptor markerIconTaxiCar;
  late BitmapDescriptor markerIconTaxiAuto;

  GoogleMapController? mapController;
  final String googleApiKey = AppConstant.googleApiKey;
  LatLng? currentPosition;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  String? mapStyle;

  // Route information
  double? currentRouteDistance; // in kilometers
  double? currentRouteDuration; // in minutes
  String? currentRouteDistanceText;
  String? currentRouteDurationText;

  // Transportation option selection
  String _selectedTransportOption = 'car_economy'; // Default selection
  List<Map<String, dynamic>> _availableRideOptions = [];

  // Route calculation cache
  String? _lastRouteKey;
  Map<String, Map<String, dynamic>>? _cachedRoutes;
  List<Map<String, dynamic>>? _cachedRideOptions;

  final BuildContext context;
  MapController(this.context);

  // Getters for route information
  double? get routeDistance => currentRouteDistance;
  double? get routeDuration => currentRouteDuration;
  String? get routeDistanceText => currentRouteDistanceText;
  String? get routeDurationText => currentRouteDurationText;

  // Getters for transportation options
  String get selectedTransportOption => _selectedTransportOption;
  void selecteTransportOption(String value) {
    _selectedTransportOption = value;
    notifyListeners();
  }

  List<Map<String, dynamic>> get availableRideOptions => _availableRideOptions;

  /// Format duration consistently across all transportation modes
  String _formatDuration(double durationMinutes) {
    final int totalMinutes = durationMinutes.round();

    if (totalMinutes >= 60) {
      final int hours = totalMinutes ~/ 60;
      final int remainingMinutes = totalMinutes % 60;

      if (remainingMinutes == 0) {
        return '$hours hour${hours > 1 ? 's' : ''}';
      } else {
        return '$hours hour${hours > 1 ? 's' : ''} $remainingMinutes min${remainingMinutes > 1 ? 's' : ''}';
      }
    } else {
      return '$totalMinutes min${totalMinutes > 1 ? 's' : ''}';
    }
  }

  /// Get formatted route info for display
  String get routeInfo {
    if (currentRouteDistanceText != null && currentRouteDurationText != null) {
      return '$currentRouteDistanceText • $currentRouteDurationText';
    } else if (currentRouteDistance != null && currentRouteDuration != null) {
      return '${currentRouteDistance!.toStringAsFixed(1)} km • ${currentRouteDuration!.round()} mins';
    }
    return 'Calculating route...';
  }

  Future<void> init() async {
    try {
      // Load resources in parallel for efficiency
      await Future.wait([_loadMapStyle(), _loadMarkerIcons()]);

      // Check location permissions and get current location
      await checkLocationPermission();
      await getCurrentLocation();

      // Generate nearby transport markers after getting current location
      if (currentPosition != null) {
        // await generateNearbyTransportMarkers(markerIconTaxiAuto);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing map controller: $e');
      }
    }
  }

  Future<void> _loadMapStyle() async {
    // mapStyle = await DefaultAssetBundle.of(
    //   context,
    // ).loadString(AppConstant.mapStylePath);

    // final mapStyle = AssetLoader().getJson("assets/map/map_style.json");
  }

  Future<void> _loadMarkerIcons() async {
    final Uint8List greenIconBytes = await _getBytesFromAsset(
      'assets/icons/green_marker.png',
      120,
    );

    final Uint8List redIconBytes = await _getBytesFromAsset(
      'assets/icons/red_marker.png',
      120,
    );

    // Load the taxi icon with a fixed size
    final Uint8List taxiIconBytes = await _getBytesFromAsset(
      'assets/icons/taxi.png',
      100,
    );

    final Uint8List autoRickshawIconBytes = await _getBytesFromAsset(
      'assets/icons/auto_marker_top_view.png',
      80,
    );

    final Uint8List bikeIconBytes = await _getBytesFromAsset(
      'assets/icons/bike_marker.png',
      100,
    );
    markerIconRed = BitmapDescriptor.fromBytes(redIconBytes);
    markerIconGreen = BitmapDescriptor.fromBytes(greenIconBytes);
    markerIconTaxiCar = BitmapDescriptor.fromBytes(taxiIconBytes);
    markerIconTaxiAuto = BitmapDescriptor.fromBytes(autoRickshawIconBytes);
    markerIconBike = BitmapDescriptor.fromBytes(bikeIconBytes);
  }

  Future<Uint8List> _getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
  }

  Future<void> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      currentPosition = LatLng(position.latitude, position.longitude);

      // Add marker for current location
      // Remove existing 'start' marker if it exists
      markers.removeWhere((marker) => marker.markerId.value == 'start');

      notifyListeners();
      if (mapController != null) {
        mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(currentPosition!, 14),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting current location: $e');
      }
    }
  }

  Future<void> checkLocationPermission() async {
    try {
      var status = await Permission.location.status;

      if (status.isDenied) {
        // Request permission
        status = await Permission.location.request();

        if (status.isPermanentlyDenied) {
          // The user opted to never again see the permission request dialog
          if (kDebugMode) {
            debugPrint(
              'Location permission permanently denied. Please enable in settings.',
            );
          }
          // You might want to show a dialog here instructing the user to enable location in settings
        }
      }

      // Even if permission was previously granted, ensure location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (kDebugMode) {
          debugPrint('Location services disabled. Opening settings...');
        }
        await Geolocator.openLocationSettings();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error checking location permission: $e');
      }
    }
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (mapStyle != null) {
      mapController!.setMapStyle(mapStyle);
    }

    // We'll handle markers in getCurrentLocation, no need to add here
    // as it could create duplicate markers

    // If we already have the current position, center the map on it
    if (currentPosition != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(currentPosition!, 14),
      );
    } else {
      // If we don't have the position yet, try to get it
      getCurrentLocation();
    }

    notifyListeners();
  }

  Future<void> drawRoute(LatLng start, LatLng end) async {
    // Clear existing route
    polylineCoordinates.clear();
    polylines.clear();
    notifyListeners();

    final Dio dio = Dio();
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&mode=driving&key=$googleApiKey';

    try {
      if (kDebugMode) {
        debugPrint(
          'Requesting directions from: ${start.latitude},${start.longitude} to ${end.latitude},${end.longitude}',
        );
      }

      final response = await dio.get(url);
      if (response.statusCode == 200) {
        final data = response.data;

        if (kDebugMode) {
          debugPrint('Response status: ${data['status']}');
        }

        if (data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];

          // Store distance and duration information
          currentRouteDistance =
              leg['distance']['value'] / 1000.0; // Convert to km
          currentRouteDuration =
              leg['duration']['value'] / 60.0; // Convert to minutes
          currentRouteDistanceText = leg['distance']['text'];
          currentRouteDurationText = leg['duration']['text'];

          final legs = data['routes'][0]['legs'];
          for (var legData in legs) {
            final steps = legData['steps'];
            for (var step in steps) {
              final points = step['polyline']['points'];
              List<PointLatLng> result = PolylinePoints.decodePolyline(points);
              for (var point in result) {
                polylineCoordinates.add(
                  LatLng(point.latitude, point.longitude),
                );
              }
            }
          }

          if (polylineCoordinates.isNotEmpty) {
            polylines.add(
              Polyline(
                polylineId: PolylineId('route'),
                points: polylineCoordinates,
                width: 2,
                color: Colors.black,
                patterns: [],
              ),
            );

            // Fit the map to show the entire route
            fitCameraToPolyline();

            notifyListeners();
          } else {
            if (kDebugMode) {
              debugPrint('No polyline coordinates found in the response.');
            }
          }
        } else {
          if (kDebugMode) {
            debugPrint('No routes found in the response.');
          }
        }
      } else {
        if (kDebugMode) {
          debugPrint(
            'Direction API request failed with status: ${response.statusCode}',
          );
        }
      }

      // Generate nearby transport markers whether route drawing succeeds or not
      // await generateNearbyTransportMarkers(markerIconBike);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error drawing route: $e');
      }
    }
  }

  /// Calculate straight-line distance between two points using Haversine formula
  /// Returns distance in kilometers
  double calculateStraightLineDistance(LatLng start, LatLng end) {
    const double earthRadius = 6371.0; // Earth's radius in kilometers

    final double lat1Rad = start.latitude * pi / 180;
    final double lon1Rad = start.longitude * pi / 180;
    final double lat2Rad = end.latitude * pi / 180;
    final double lon2Rad = end.longitude * pi / 180;

    final double deltaLat = lat2Rad - lat1Rad;
    final double deltaLon = lon2Rad - lon1Rad;

    final double a =
        sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(deltaLon / 2) * sin(deltaLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Calculate driving distance and duration using Google Directions API
  /// Returns a map with 'distance' (in km) and 'duration' (in minutes)
  Future<Map<String, dynamic>> calculateDistanceAndTime(
    LatLng start,
    LatLng end, {
    String mode = 'driving',
  }) async {
    final Dio dio = Dio();
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&mode=$mode&key=$googleApiKey';

    try {
      final response = await dio.get(url);
      if (response.statusCode == 200) {
        final data = response.data;

        if (data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];

          // Extract distance and duration
          final distanceText = leg['distance']['text'];
          final distanceValue = leg['distance']['value']; // in meters
          final durationText = leg['duration']['text'];
          final durationValue = leg['duration']['value']; // in seconds

          // Convert to more usable units
          final distanceKm = distanceValue / 1000.0; // Convert to kilometers
          final durationMinutes = durationValue / 60.0; // Convert to minutes

          if (kDebugMode) {
            debugPrint('Distance: $distanceText ($distanceKm km)');
            debugPrint(
              'Duration: $durationText (${durationMinutes.round()} minutes)',
            );
          }

          return {
            'distance_km': distanceKm,
            'distance_text': distanceText,
            'duration_minutes': durationMinutes,
            'duration_text': durationText,
            'success': true,
          };
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error calculating distance and time: $e');
      }
    }

    // Fallback to straight-line distance if API fails
    final straightDistance = calculateStraightLineDistance(start, end);
    final estimatedTime =
        straightDistance * 2; // Rough estimate: 2 minutes per km

    return {
      'distance_km': straightDistance,
      'distance_text': '${straightDistance.toStringAsFixed(1)} km',
      'duration_minutes': estimatedTime,
      'duration_text': _formatDuration(estimatedTime),
      'success': false,
      'fallback': true,
    };
  }

  /// Calculate estimated time for different transportation modes
  Future<Map<String, Map<String, dynamic>>> calculateTimeForAllModes(
    LatLng start,
    LatLng end,
  ) async {
    final modes = ['driving', 'walking', 'transit', 'bicycling'];
    final results = <String, Map<String, dynamic>>{};

    for (String mode in modes) {
      try {
        final result = await calculateDistanceAndTime(start, end, mode: mode);
        results[mode] = result;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error calculating time for mode $mode: $e');
        }
        // Use fallback calculation
        final distance = calculateStraightLineDistance(start, end);
        double estimatedTime;

        switch (mode) {
          case 'walking':
            estimatedTime = distance * 12; // ~5 km/h walking speed
            break;
          case 'bicycling':
            estimatedTime = distance * 4; // ~15 km/h cycling speed
            break;
          case 'transit':
            estimatedTime = distance * 3; // ~20 km/h average transit speed
            break;
          case 'driving':
          default:
            estimatedTime = distance * 2; // ~30 km/h average driving in city
            break;
        }

        results[mode] = {
          'distance_km': distance,
          'distance_text': '${distance.toStringAsFixed(1)} km',
          'duration_minutes': estimatedTime,
          'duration_text': _formatDuration(estimatedTime),
          'success': false,
          'fallback': true,
        };
      }
    }

    return results;
  }

  /// Get formatted distance and time string for UI display
  String getFormattedDistanceTime(LatLng start, LatLng end) {
    final distance = calculateStraightLineDistance(start, end);
    final estimatedTime = (distance * 2).round(); // 2 minutes per km estimate

    return '${distance.toStringAsFixed(1)} km • $estimatedTime mins';
  }

  /// Calculate distance and time specifically for car route
  Future<Map<String, dynamic>> calculateCarRoute(
    LatLng start,
    LatLng end,
  ) async {
    return await calculateDistanceAndTime(start, end, mode: 'driving');
  }

  /// Calculate distance and time specifically for bike route
  Future<Map<String, dynamic>> calculateBikeRoute(
    LatLng start,
    LatLng end,
  ) async {
    return await calculateDistanceAndTime(start, end, mode: 'bicycling');
  }

  /// Calculate routes for different vehicle types used in ride booking
  Future<Map<String, Map<String, dynamic>>> calculateRideRoutes(
    LatLng start,
    LatLng end,
  ) async {
    final results = <String, Map<String, dynamic>>{};

    try {
      // Single car route calculation (most reliable)
      final carRoute = await calculateCarRoute(start, end);
      results['car'] = carRoute;

      if (carRoute['success']) {
        // Use car route data to estimate other routes (faster)
        final carDistance = carRoute['distance_km'];
        final carDuration = carRoute['duration_minutes'];

        // Auto route - 20% slower than car in city traffic
        final autoDuration = carDuration * 1.2;
        results['auto'] = {
          'distance_km': carDistance,
          'distance_text': carRoute['distance_text'],
          'duration_minutes': autoDuration,
          'duration_text': _formatDuration(autoDuration),
          'success': true,
          'vehicle_type': 'auto',
        };

        // Bike route - typically 30% faster than car in traffic but use conservative estimate
        final bikeDuration = carDuration * 0.8;
        results['bike'] = {
          'distance_km': carDistance,
          'distance_text': carRoute['distance_text'],
          'duration_minutes': bikeDuration,
          'duration_text': _formatDuration(bikeDuration),
          'success': true,
          'vehicle_type': 'bike',
        };
      } else {
        // Fallback to direct calculations if car route fails
        _calculateFallbackRoutes(start, end, results);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error calculating ride routes: $e');
      }
      _calculateFallbackRoutes(start, end, results);
    }

    return results;
  }

  /// Calculate fallback routes using straight-line distance
  void _calculateFallbackRoutes(
    LatLng start,
    LatLng end,
    Map<String, Map<String, dynamic>> results,
  ) {
    final distance = calculateStraightLineDistance(start, end);

    final carDuration = distance * 2; // 30 km/h average
    final bikeDuration = distance * 2.5; // 24 km/h average for bikes in traffic
    final autoDuration = distance * 2.5; // 24 km/h average

    results['car'] = {
      'distance_km': distance,
      'distance_text': '${distance.toStringAsFixed(1)} km',
      'duration_minutes': carDuration,
      'duration_text': _formatDuration(carDuration),
      'success': false,
      'fallback': true,
    };

    results['bike'] = {
      'distance_km': distance,
      'distance_text': '${distance.toStringAsFixed(1)} km',
      'duration_minutes': bikeDuration,
      'duration_text': _formatDuration(bikeDuration),
      'success': false,
      'fallback': true,
    };

    results['auto'] = {
      'distance_km': distance,
      'distance_text': '${distance.toStringAsFixed(1)} km',
      'duration_minutes': autoDuration,
      'duration_text': _formatDuration(autoDuration),
      'success': false,
      'fallback': true,
    };
  }

  /// Calculate estimated prices based on distance and vehicle type (optimized)
  Map<String, double> calculateEstimatedPrices(double distanceKm) {
    // Pre-calculated base prices and per-km rates for faster computation
    const bikeBase = 10.0, bikePerKm = 4.0, bikeMin = 22.0;
    const autoBase = 30.0, autoPerKm = 6.0, autoMin = 35.0;
    const carEconomyBase = 40.0, carEconomyPerKm = 10.0, carEconomyMin = 50.0;
    const carPremiumBase = 60.0, carPremiumPerKm = 15.0, carPremiumMin = 80.0;

    final bikePrice = (bikeBase + (distanceKm * bikePerKm));
    final autoPrice = (autoBase + (distanceKm * autoPerKm));
    final carEconomyPrice = (carEconomyBase + (distanceKm * carEconomyPerKm));
    final carPremiumPrice = (carPremiumBase + (distanceKm * carPremiumPerKm));

    return {
      'bike': bikePrice < bikeMin ? bikeMin : bikePrice,
      'auto': autoPrice < autoMin ? autoMin : autoPrice,
      'car_economy': carEconomyPrice < carEconomyMin
          ? carEconomyMin
          : carEconomyPrice,
      'car_premium': carPremiumPrice < carPremiumMin
          ? carPremiumMin
          : carPremiumPrice,
    };
  }

  /// Quickly update selection state in cached options without full recalculation
  void updateSelectionInCache(String optionId) {
    if (_cachedRideOptions != null) {
      for (final option in _cachedRideOptions!) {
        option['isSelected'] = option['id'] == optionId;
      }
    }
  }

  /// Select a transportation option
  void selectTransportOption(String optionId) {
    // Early return if same option is selected
    if (_selectedTransportOption == optionId) return;

    _selectedTransportOption = optionId;

    // Efficiently update selection state in both current and cached options
    if (_availableRideOptions.isNotEmpty) {
      for (final option in _availableRideOptions) {
        option['isSelected'] = option['id'] == optionId;
      }
    }

    // Also update cached options to avoid recalculation
    updateSelectionInCache(optionId);

    notifyListeners();
  }

  /// Pre-calculate ride options to improve performance
  Future<void> preCalculateRideOptions(LatLng start, LatLng end) async {
    final routeKey =
        '${start.latitude},${start.longitude}-${end.latitude},${end.longitude}';

    // Only calculate if not already cached
    if (_lastRouteKey != routeKey) {
      try {
        // Calculate routes in background
        await _getCachedRoutes(start, end, routeKey);

        // Calculate ride options in background
        await getRideOptions(start, end);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error pre-calculating ride options: $e');
        }
      }
    }
  }

  /// Clear route cache when locations change
  void clearRouteCache() {
    _lastRouteKey = null;
    _cachedRoutes = null;
    _cachedRideOptions = null;
  }

  /// Get the currently selected transportation option details
  Map<String, dynamic>? getSelectedTransportOptionDetails() {
    if (_availableRideOptions.isEmpty) return null;

    try {
      return _availableRideOptions.firstWhere(
        (option) => option['id'] == _selectedTransportOption,
      );
    } catch (e) {
      return null;
    }
  }

  /// Update ride options with current selection state
  void _updateRideOptionsSelectionState(List<Map<String, dynamic>> options) {
    for (var option in options) {
      option['isSelected'] = option['id'] == _selectedTransportOption;
    }
    _availableRideOptions = options;
  }

  /// Get ride option data for the bottom sheet with caching
  Future<List<Map<String, dynamic>>> getRideOptions(
    LatLng start,
    LatLng end,
  ) async {
    // Create a unique key for this route
    final routeKey =
        '${start.latitude},${start.longitude}-${end.latitude},${end.longitude}';

    // Return cached options if available and route hasn't changed
    if (_lastRouteKey == routeKey && _cachedRideOptions != null) {
      // Update selection state and return cached options
      for (final option in _cachedRideOptions!) {
        option['isSelected'] = option['id'] == _selectedTransportOption;
      }
      return _cachedRideOptions!;
    }

    // Calculate routes (this will be cached)
    final routes = await _getCachedRoutes(start, end, routeKey);
    final distance =
        routes['car']?['distance_km'] ??
        calculateStraightLineDistance(start, end);
    final prices = calculateEstimatedPrices(distance);

    final options = [
      {
        'id': 'bike',
        'icon': 'motorbike',
        'title': 'Bike',
        'subtitle':
            '${routes['bike']?['duration_text'] ?? '2 mins'} • Drop ${_getEstimatedArrival(routes['bike']?['duration_minutes'] ?? 2)}',
        'price': '₹${prices['bike']?.round() ?? 59}',
        'isSelected': _selectedTransportOption == 'bike',
        'fastestBadge': _isFastest('bike', routes),
      },
      {
        'id': 'car_economy',
        'icon': 'car',
        'title': 'Cab Economy',
        'subtitle':
            '${routes['car']?['duration_text'] ?? '2 mins'} away • Drop ${_getEstimatedArrival(routes['car']?['duration_minutes'] ?? 2)}',
        'price': '₹${prices['car_economy']?.round() ?? 138}',
        'isSelected': _selectedTransportOption == 'car_economy',
        'badge': '',
        'fastestBadge': _isFastest('car', routes),
      },
      {
        'id': 'auto',
        'icon': 'auto_marker',
        'title': 'Auto',
        'subtitle':
            '${routes['auto']?['duration_text'] ?? '2 mins'} • Drop ${_getEstimatedArrival(routes['auto']?['duration_minutes'] ?? 2)}',
        'price': '₹${prices['auto']?.round() ?? 111}',
        'isSelected': _selectedTransportOption == 'auto',
        'fastestBadge': _isFastest('auto', routes),
      },
      {
        'id': 'car_premium',
        'icon': 'car',
        'title': 'Cab Premium',
        'subtitle':
            '${routes['car']?['duration_text'] ?? '2 mins'} • Drop ${_getEstimatedArrival(routes['car']?['duration_minutes'] ?? 2)}',
        'price': '₹${prices['car_premium']?.round() ?? 166}',
        'isSelected': _selectedTransportOption == 'car_premium',
      },
    ];

    // Cache the results
    _lastRouteKey = routeKey;
    _cachedRideOptions = options;
    _updateRideOptionsSelectionState(options);

    return options;
  }

  /// Get cached routes or calculate new ones
  Future<Map<String, Map<String, dynamic>>> _getCachedRoutes(
    LatLng start,
    LatLng end,
    String routeKey,
  ) async {
    // Return cached routes if available
    if (_lastRouteKey == routeKey && _cachedRoutes != null) {
      return _cachedRoutes!;
    }

    // Calculate and cache new routes
    _cachedRoutes = await calculateRideRoutes(start, end);
    return _cachedRoutes!;
  }

  bool _isFastest(
    String vehicleType,
    Map<String, Map<String, dynamic>> routes,
  ) {
    final durations = <String, double>{};

    routes.forEach((type, route) {
      durations[type] = route['duration_minutes'] ?? double.infinity;
    });

    final validDurations = durations.values.where((d) => d != double.infinity);
    if (validDurations.isEmpty) return false;

    final minDuration = validDurations.reduce(min);

    if (vehicleType == 'bike') {
      return durations['bike']! <= minDuration;
    } else if (vehicleType == 'auto') {
      return durations['auto']! <= minDuration;
    } else if (vehicleType == 'car') {
      return durations['car']! <= minDuration;
    }

    return false;
  }

  String _getEstimatedArrival(double durationMinutes) {
    final now = DateTime.now();
    final arrival = now.add(Duration(minutes: durationMinutes.round()));
    final hour = arrival.hour;
    final minute = arrival.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'pm' : 'am';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '$displayHour:$minute $period';
  }

  // void onPlaceSelected(double lat, double lng, placeName) {
  //   LatLng selected = LatLng(lat, lng);

  //   // Clear route cache when destination changes
  //   clearRouteCache();

  //   // Remove existing destination marker if it exists
  //   markers.removeWhere((marker) => marker.markerId.value == 'destination');

  //   // Add new destination marker
  //   markers.add(
  //     Marker(
  //       markerId: MarkerId('destination'),
  //       position: selected,
  //       icon: markerIconRed,
  //       infoWindow: InfoWindow(title: placeName),
  //     ),
  //   );

  //   notifyListeners();

  //   if (mapController != null) {
  //     mapController!.animateCamera(CameraUpdate.newLatLngZoom(selected, 14));
  //   }

  //   // Check if we have current position and draw route
  //   if (currentPosition != null) {
  //     drawRoute(currentPosition!, selected);
  //   } else {
  //     // If we don't have current position, try to get it first
  //     getCurrentLocation().then((_) {
  //       if (currentPosition != null) {
  //         drawRoute(currentPosition!, selected);
  //       }
  //     });
  //   }

  //   plotRandomRiderMarkers('markerIconTaxiCar', pickupLatLng);
  // }

  void moveToCurrentLocation() {
    if (currentPosition != null && mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(currentPosition!, 18),
      );
    }
  }

  void fitCameraToPolyline() {
    if (polylines.isEmpty || mapController == null) return;

    final points = polylines.first.points;
    if (points.isEmpty) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50), // 50 is padding
    );
  }

  List<LatLng> generateRandomRiderMarkers(LatLng userLocation) {
    final random = Random();
    final int count = 5;
    const double radiusInKm = 3;
    const double earthRadius = 6371.0;

    List<LatLng> randomMarkers = [];

    for (int i = 0; i < count; i++) {
      // Generate random distance and bearing
      final double distanceKm = random.nextDouble() * radiusInKm;
      final double bearing = random.nextDouble() * 2 * pi;

      // Convert distance to angular distance
      final double angularDistance = distanceKm / earthRadius;

      final double lat1 = userLocation.latitude * pi / 180;
      final double lon1 = userLocation.longitude * pi / 180;

      final double lat2 = asin(
        sin(lat1) * cos(angularDistance) +
            cos(lat1) * sin(angularDistance) * cos(bearing),
      );

      final double lon2 =
          lon1 +
          atan2(
            sin(bearing) * sin(angularDistance) * cos(lat1),
            cos(angularDistance) - sin(lat1) * sin(lat2),
          );

      final newLat = lat2 * 180 / pi;
      final newLon = lon2 * 180 / pi;

      randomMarkers.add(LatLng(newLat, newLon));
    }

    return randomMarkers;
  }

  plotRandomRiderMarkers(LatLng pickupLatLng) {
    BitmapDescriptor riderMarkerIcon;
    Map<String, dynamic>? options = getSelectedTransportOptionDetails();
    String s = options?['title'] ?? '';
    switch (s) {
      case 'Cab Economy':
      case 'Cab Premium':
        riderMarkerIcon = markerIconTaxiCar;
        break;
      case 'Auto':
        riderMarkerIcon = markerIconTaxiAuto;
        break;
      case 'Bike':
      default:
        riderMarkerIcon = markerIconBike;
        break;
    }
    debugPrint('s ===>>>>>>> $s');
    final randomMarkers = generateRandomRiderMarkers(pickupLatLng);

    for (int i = 0; i < randomMarkers.length; i++) {
      markers.removeWhere((marker) => marker.markerId.value == 'rider_$i');

      markers.add(
        Marker(
          markerId: MarkerId('rider_$i'),
          rotation: Random().nextDouble() * 360,
          position: randomMarkers[i],
          icon: riderMarkerIcon,
          // infoWindow: InfoWindow(
          //   title: 'Rider $i',
          //   snippet: 'Random rider location',
          // ),
        ),
      );
    }

    notifyListeners();
  }
}
