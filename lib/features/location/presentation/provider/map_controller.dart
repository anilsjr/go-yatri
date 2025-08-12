import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'dart:typed_data';
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
  final String googleApiKey = 'AIzaSyBIJfuTJME0jr6ubJCNuDK9oUEHMWNrzEY';
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

  final BuildContext context;
  MapController(this.context);

  // Getters for route information
  double? get routeDistance => currentRouteDistance;
  double? get routeDuration => currentRouteDuration;
  String? get routeDistanceText => currentRouteDistanceText;
  String? get routeDurationText => currentRouteDurationText;

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
    mapStyle = await DefaultAssetBundle.of(
      context,
    ).loadString(AppConstant.mapStylePath);
  }

  Future<void> _loadMarkerIcons() async {
    final Uint8List greenIconBytes = await _getBytesFromAsset(
      'assets/icons/green_marker.png',
      100,
    );

    final Uint8List redIconBytes = await _getBytesFromAsset(
      'assets/icons/red_marker.png',
      100,
    );

    // Load the taxi icon with a fixed size
    final Uint8List taxiIconBytes = await _getBytesFromAsset(
      'assets/icons/taxi.png',
      60,
    );

    final Uint8List autoRickshawIconBytes = await _getBytesFromAsset(
      'assets/icons/auto_marker.png',
      60,
    );

    final Uint8List bikeIconBytes = await _getBytesFromAsset(
      'assets/icons/bike_marker.png',
      60,
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
            print(
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
          print('Location services disabled. Opening settings...');
        }
        await Geolocator.openLocationSettings();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error checking location permission: $e');
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
        print(
          'Requesting directions from: ${start.latitude},${start.longitude} to ${end.latitude},${end.longitude}',
        );
      }

      final response = await dio.get(url);
      if (response.statusCode == 200) {
        final data = response.data;

        if (kDebugMode) {
          print('Response status: ${data['status']}');
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
              print('No polyline coordinates found in the response.');
            }
          }
        } else {
          if (kDebugMode) {
            print('No routes found in the response.');
          }
        }
      } else {
        if (kDebugMode) {
          print(
            'Direction API request failed with status: ${response.statusCode}',
          );
        }
      }

      // Generate nearby transport markers whether route drawing succeeds or not
      // await generateNearbyTransportMarkers(markerIconBike);
    } catch (e) {
      if (kDebugMode) {
        print('Error drawing route: $e');
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
            print('Distance: $distanceText ($distanceKm km)');
            print(
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
        print('Error calculating distance and time: $e');
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
      'duration_text': '${estimatedTime.round()} mins',
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
          print('Error calculating time for mode $mode: $e');
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
          'duration_text': '${estimatedTime.round()} mins',
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
      // Car route (for Cab Economy, Cab Premium)
      final carRoute = await calculateCarRoute(start, end);
      results['car'] = carRoute;

      // Bike route (for Bike rides)
      final bikeRoute = await calculateBikeRoute(start, end);
      results['bike'] = bikeRoute;

      // Auto route - use driving mode but with different speed estimation
      final autoRoute = await calculateDistanceAndTime(
        start,
        end,
        mode: 'driving',
      );
      if (autoRoute['success']) {
        // Auto rickshaws are typically slower than cars in traffic
        final adjustedDuration =
            autoRoute['duration_minutes'] * 1.2; // 20% slower
        results['auto'] = {
          ...autoRoute,
          'duration_minutes': adjustedDuration,
          'duration_text': '${adjustedDuration.round()} mins',
          'vehicle_type': 'auto',
        };
      } else {
        results['auto'] = autoRoute;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error calculating ride routes: $e');
      }

      // Fallback calculations
      final distance = calculateStraightLineDistance(start, end);

      results['car'] = {
        'distance_km': distance,
        'distance_text': '${distance.toStringAsFixed(1)} km',
        'duration_minutes': distance * 2, // 30 km/h average
        'duration_text': '${(distance * 2).round()} mins',
        'success': false,
        'fallback': true,
      };

      results['bike'] = {
        'distance_km': distance,
        'distance_text': '${distance.toStringAsFixed(1)} km',
        'duration_minutes': distance * 4, // 15 km/h average
        'duration_text': '${(distance * 4).round()} mins',
        'success': false,
        'fallback': true,
      };

      results['auto'] = {
        'distance_km': distance,
        'distance_text': '${distance.toStringAsFixed(1)} km',
        'duration_minutes': distance * 2.5, // 24 km/h average
        'duration_text': '${(distance * 2.5).round()} mins',
        'success': false,
        'fallback': true,
      };
    }

    return results;
  }

  /// Calculate estimated prices based on distance and vehicle type
  Map<String, double> calculateEstimatedPrices(double distanceKm) {
    // Base prices and per-km rates (you can adjust these)
    const Map<String, Map<String, double>> priceConfig = {
      'bike': {'base': 10.0, 'perKm': 6.0, 'min': 22.0},
      'auto': {'base': 20.0, 'perKm': 12.0, 'min': 35.0},
      'car_economy': {'base': 40.0, 'perKm': 15.0, 'min': 50.0},
      'car_premium': {'base': 60.0, 'perKm': 20.0, 'min': 80.0},
    };

    Map<String, double> prices = {};

    priceConfig.forEach((vehicleType, config) {
      final basePrice = config['base']!;
      final perKmRate = config['perKm']!;
      final minPrice = config['min']!;

      final calculatedPrice = basePrice + (distanceKm * perKmRate);
      prices[vehicleType] = calculatedPrice < minPrice
          ? minPrice
          : calculatedPrice;
    });

    return prices;
  }

  /// Get ride option data for the bottom sheet
  Future<List<Map<String, dynamic>>> getRideOptions(
    LatLng start,
    LatLng end,
  ) async {
    final routes = await calculateRideRoutes(start, end);
    final distance =
        routes['car']?['distance_km'] ??
        calculateStraightLineDistance(start, end);
    final prices = calculateEstimatedPrices(distance);

    return [
      {
        'id': 'bike',
        'icon': '🏍️',
        'title': 'Bike',
        'subtitle':
            '${routes['bike']?['duration_text'] ?? '2 mins'} • Drop ${_getEstimatedArrival(routes['bike']?['duration_minutes'] ?? 2)}',
        'price': '₹${prices['bike']?.round() ?? 59}',
        'isSelected': false,
        'fastestBadge': _isFastest('bike', routes),
      },
      {
        'id': 'car_economy',
        'icon': '🚕',
        'title': 'Cab Economy',
        'subtitle':
            'Affordable car rides\n${routes['car']?['duration_text'] ?? '2 mins'} away • Drop ${_getEstimatedArrival(routes['car']?['duration_minutes'] ?? 2)}',
        'price': '₹${prices['car_economy']?.round() ?? 138}',
        'isSelected': true,
        'badge': '👥 4',
        'fastestBadge': _isFastest('car', routes),
      },
      {
        'id': 'auto',
        'icon': '🛺',
        'title': 'Auto',
        'subtitle':
            '${routes['auto']?['duration_text'] ?? '2 mins'} • Drop ${_getEstimatedArrival(routes['auto']?['duration_minutes'] ?? 2)}',
        'price': '₹${prices['auto']?.round() ?? 111}',
        'isSelected': false,
        'fastestBadge': _isFastest('auto', routes),
      },
      {
        'id': 'car_premium',
        'icon': '🚗',
        'title': 'Cab Premium',
        'subtitle':
            '${routes['car']?['duration_text'] ?? '2 mins'} • Drop ${_getEstimatedArrival(routes['car']?['duration_minutes'] ?? 2)}',
        'price': '₹${prices['car_premium']?.round() ?? 166}',
        'isSelected': false,
      },
    ];
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

  void onPlaceSelected(double lat, double lng, placeName) {
    LatLng selected = LatLng(lat, lng);

    // Remove existing destination marker if it exists
    markers.removeWhere((marker) => marker.markerId.value == 'destination');

    // Add new destination marker
    markers.add(
      Marker(
        markerId: MarkerId('destination'),
        position: selected,
        icon: markerIconRed,
        infoWindow: InfoWindow(title: placeName),
      ),
    );

    notifyListeners();

    if (mapController != null) {
      mapController!.animateCamera(CameraUpdate.newLatLngZoom(selected, 14));
    }

    // Check if we have current position and draw route
    if (currentPosition != null) {
      drawRoute(currentPosition!, selected);
    } else {
      // If we don't have current position, try to get it first
      getCurrentLocation().then((_) {
        if (currentPosition != null) {
          drawRoute(currentPosition!, selected);
        }
      });
    }

    plotRandomRiderMarkers(markerIconTaxiCar);
  }

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
    final int count = 5 + random.nextInt(3); // 5 to 7 markers
    const double radiusInKm = 2;
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

  plotRandomRiderMarkers([BitmapDescriptor? riderMarkerIcon]) {
    final randomMarkers = generateRandomRiderMarkers(currentPosition!);

    for (int i = 0; i < randomMarkers.length; i++) {
      markers.add(
        Marker(
          markerId: MarkerId('rider_$i'),
          rotation: Random().nextDouble() * 360,
          position: randomMarkers[i],
          icon: riderMarkerIcon ?? markerIconBike,
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
