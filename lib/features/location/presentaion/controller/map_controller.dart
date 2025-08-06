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

  // Properties for animated markers
  final Map<String, Timer> _animationTimers = {};
  final Map<String, LatLng> _targetPositions = {};
  final Map<String, DateTime> _startTimes = {};
  final Map<String, LatLng> _startPositions = {};
  final Duration animationDuration = Duration(seconds: 3);

  GoogleMapController? mapController;
  final String googleApiKey = 'AIzaSyBIJfuTJME0jr6ubJCNuDK9oUEHMWNrzEY';
  LatLng? currentPosition;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  String? mapStyle;

  final BuildContext context;
  MapController(this.context);

  Future<void> init() async {
    try {
      // Load resources in parallel for efficiency
      await Future.wait([_loadMapStyle(), _loadMarkerIcons()]);

      // Check location permissions and get current location
      await checkLocationPermission();
      await getCurrentLocation();

      // Generate nearby transport markers after getting current location
      if (currentPosition != null) {
        await generateNearbyTransportMarkers(markerIconTaxiAuto);
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
    markerIconRed = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(devicePixelRatio: 2.5),
      'assets/icons/red_marker.png',
    );
    markerIconGreen = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(devicePixelRatio: 2.5),
      'assets/icons/green_marker.png',
    );
    markerIconBike = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(devicePixelRatio: 2.5),
      'assets/icons/bike_marker.png',
    );

    // Load the taxi icon with a fixed size
    final Uint8List taxiIconBytes = await _getBytesFromAsset(
      'assets/icons/taxi.png',
      100,
    );

    final Uint8List autoRickshawIconBytes = await _getBytesFromAsset(
      'assets/icons/auto_marker.png',
      100,
    );

    final Uint8List bikeIconBytes = await _getBytesFromAsset(
      'assets/icons/bike_marker.png',
      100,
    );

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

      markers.add(
        Marker(
          markerId: MarkerId('start'),
          position: currentPosition!,
          icon: markerIconGreen,
          infoWindow: InfoWindow(
            title: 'Your Location',
            snippet: 'You are here',
          ),
        ),
      );

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
          final legs = data['routes'][0]['legs'];
          for (var leg in legs) {
            final steps = leg['steps'];
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
                width: 5,
                color: Colors.blue,
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
      await generateNearbyTransportMarkers(markerIconBike);
    } catch (e) {
      if (kDebugMode) {
        print('Error drawing route: $e');
      }
      // Still try to generate markers even if route drawing fails
      await generateNearbyTransportMarkers(markerIconTaxiAuto);
    }
  }

  void onPlaceSelected(double lat, double lng) {
    LatLng selected = LatLng(lat, lng);

    // Remove existing destination marker if it exists
    markers.removeWhere((marker) => marker.markerId.value == 'destination');

    // Add new destination marker
    markers.add(
      Marker(
        markerId: MarkerId('destination'),
        position: selected,
        icon: markerIconRed,
        infoWindow: InfoWindow(
          title: 'Destination',
          snippet: 'Your destination',
        ),
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

  /// Generates and plots random markers near the user's current location
  /// representing nearby transportation options within 1.5km range
  Future<void> generateNearbyTransportMarkers(
    BitmapDescriptor riderMarker,
  ) async {
    if (currentPosition == null) {
      await getCurrentLocation();
      if (currentPosition == null) return;
    }

    // Clear any existing nearby transport markers
    markers.removeWhere(
      (marker) => marker.markerId.value.startsWith('nearby_transport'),
    );

    // For debugging: Add at least one marker to verify it works
    markers.add(
      Marker(
        markerId: MarkerId('nearby_transport_debug'),
        position: LatLng(
          currentPosition!.latitude + 0.001,
          currentPosition!.longitude + 0.001,
        ),
        icon: riderMarker,
        infoWindow: InfoWindow(
          title: 'Debug Marker',
          snippet: 'Test marker to verify functionality',
        ),
      ),
    );

    // Get nearby places using Google Places API specifically for roads
    final Dio dio = Dio();
    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=${currentPosition!.latitude},${currentPosition!.longitude}'
        '&radius=1500' // 1.5km
        '&type=route' // 'route' is more specific for roads than 'road'
        '&rankby=distance' // Prioritize closer roads
        '&key=$googleApiKey';

    try {
      final response = await dio.get(url);
      if (response.statusCode == 200) {
        final data = response.data;

        if (data['results'] != null && data['results'].isNotEmpty) {
          // Limit to 5-8 markers
          final random = DateTime.now().millisecondsSinceEpoch;
          final numMarkers = 5 + (random % 4); // Random number between 5-8

          int count = 0;
          for (var place in data['results']) {
            if (count >= numMarkers) break;

            // Check if we have valid location data
            if (place['geometry'] != null &&
                place['geometry']['location'] != null &&
                place['geometry']['location']['lat'] != null &&
                place['geometry']['location']['lng'] != null) {
              // Get coordinates from the place
              final lat = place['geometry']['location']['lat'];
              final lng = place['geometry']['location']['lng'];

              // Calculate distance from current position
              final distance = Geolocator.distanceBetween(
                currentPosition!.latitude,
                currentPosition!.longitude,
                lat,
                lng,
              );

              // Only use places within 1.5km
              if (distance <= 1500) {
                // Add the marker using the provided rider marker
                markers.add(
                  Marker(
                    rotation: Random().nextDouble() * 360, // Random rotation
                    markerId: MarkerId('nearby_transport_${count}'),
                    position: LatLng(lat, lng),
                    icon: riderMarker,
                    infoWindow: InfoWindow(
                      title: 'Vehicle available',
                      snippet: 'Distance: ${distance.toStringAsFixed(0)}m',
                    ),
                  ),
                );

                count++;
              }
            }

            count++;
          }

          // If we didn't get enough places from the API, generate random positions
          while (count < numMarkers) {
            // Generate a random position within 1.5km
            final double radius = 1500; // meters
            final double radiusInDegrees =
                radius / 111000; // approx 111km per degree

            final random = DateTime.now().millisecondsSinceEpoch + count;
            final u = random / 2147483647; // random between 0 and 1
            final v = random % 1000 / 1000; // random between 0 and 1

            final w = radiusInDegrees * sqrt(u);
            final t = 2 * pi * v;
            final x = w * cos(t);
            final y = w * sin(t);

            final newLat = currentPosition!.latitude + y;
            final newLng = currentPosition!.longitude + x;

            // Add the marker using the provided rider marker
            markers.add(
              Marker(
                rotation: Random().nextDouble() * 360, // Random rotation
                markerId: MarkerId('nearby_transport_${count}'),
                position: LatLng(newLat, newLng),
                icon: riderMarker,
                infoWindow: InfoWindow(
                  title: 'Vehicle available',
                  snippet: 'Tap to book',
                ),
              ),
            );

            count++;
          }

          notifyListeners();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error generating nearby transport markers: $e');
      }

      // Fallback to purely random markers if API call fails
      _generateRandomMarkers(riderMarker);
    } finally {
      // Make sure we notify listeners even if there was an error
      notifyListeners();
    }
  }

  /// Fallback method to generate random markers without API
  void _generateRandomMarkers(BitmapDescriptor riderMarker) {
    if (currentPosition == null) return;

    // Generate 5-8 random markers
    final random = Random();
    final numMarkers = 5 + random.nextInt(4); // Random number between 5-8

    // Generate some simulated "road" directions from the current position
    // These angles represent typical road directions (N, NE, E, SE, S, SW, W, NW)
    final roadAngles = [0, 45, 90, 135, 180, 225, 270, 315];

    for (int i = 0; i < numMarkers; i++) {
      // Pick a random road angle and add some small randomization
      final baseAngle = roadAngles[random.nextInt(roadAngles.length)];
      final angle =
          (baseAngle + random.nextInt(20) - 10) *
          pi /
          180; // +/- 10 degrees variation

      // Generate a random distance between 200m and 1500m
      // More likely to be 500-1000m from user for better visibility
      final distance = 200 + random.nextInt(1300);

      // Convert to latitude/longitude offset
      // Approximately 111,111 meters per degree of latitude
      final latOffset = distance * cos(angle) / 111111;

      // Longitude degrees vary based on latitude
      // cos(lat) gives the scaling factor
      final lngOffset =
          distance *
          sin(angle) /
          (111111 * cos(currentPosition!.latitude * pi / 180));

      final newLat = currentPosition!.latitude + latOffset;
      final newLng = currentPosition!.longitude + lngOffset;

      // Add the marker
      markers.add(
        Marker(
          rotation: random.nextDouble() * 360, // Random rotation
          markerId: MarkerId('nearby_transport_${i}'),
          position: LatLng(newLat, newLng),
          icon: riderMarker,
          infoWindow: InfoWindow(
            title: 'Vehicle available',
            snippet: 'Distance: ~${distance}m',
          ),
        ),
      );
    }

    notifyListeners();
  }

  /// Generates 4-6 animated markers that move in random directions
  /// The markers will animate to move 200m in 3 seconds
  Future<void> generateAnimatedMarkers(BitmapDescriptor markerIcon) async {
    if (currentPosition == null) {
      await getCurrentLocation();
      if (currentPosition == null) return;
    }

    // Clear any existing animated markers
    // Cancel any existing animation timers first
    for (final timer in _animationTimers.values) {
      timer.cancel();
    }
    _animationTimers.clear();
    _targetPositions.clear();
    _startTimes.clear();
    _startPositions.clear();

    // Remove any existing animated markers from the map
    markers.removeWhere(
      (marker) => marker.markerId.value.startsWith('animated_marker'),
    );

    final random = Random();
    // Generate 4-6 markers
    final numMarkers = 4 + random.nextInt(3); // Random number between 4-6

    for (int i = 0; i < numMarkers; i++) {
      // Generate a random position within 1.5km
      final double radius = 1500; // meters
      final double radiusInDegrees = radius / 111000; // approx 111km per degree

      final u = random.nextDouble(); // random between 0 and 1
      final v = random.nextDouble(); // random between 0 and 1

      final w = radiusInDegrees * sqrt(u);
      final t = 2 * pi * v;
      final x = w * cos(t);
      final y = w * sin(t);

      final startLat = currentPosition!.latitude + y;
      final startLng = currentPosition!.longitude + x;
      final startPosition = LatLng(startLat, startLng);

      // Random rotation angle
      final rotation = random.nextDouble() * 360;

      // Generate a target position 200m away in a random direction
      final moveAngle = random.nextDouble() * 2 * pi; // Random angle in radians
      final moveDistance = 200; // 200 meters

      // Convert to latitude/longitude offset for the target position
      final moveLatOffset = moveDistance * cos(moveAngle) / 111111;
      final moveLngOffset =
          moveDistance * sin(moveAngle) / (111111 * cos(startLat * pi / 180));

      final targetLat = startLat + moveLatOffset;
      final targetLng = startLng + moveLngOffset;
      final targetPosition = LatLng(targetLat, targetLng);

      final markerId = 'animated_marker_$i';

      // Store animation data
      _startPositions[markerId] = startPosition;
      _targetPositions[markerId] = targetPosition;
      _startTimes[markerId] = DateTime.now();

      // Add the initial marker
      markers.add(
        Marker(
          markerId: MarkerId(markerId),
          position: startPosition,
          rotation: rotation,
          icon: markerIcon,
          infoWindow: InfoWindow(
            title: 'Moving Vehicle',
            snippet: 'This vehicle is in motion',
          ),
        ),
      );

      // Start animation timer
      _animationTimers[markerId] = Timer.periodic(
        const Duration(milliseconds: 16), // ~60fps
        (timer) => _updateMarkerPosition(markerId, timer),
      );
    }

    notifyListeners();
  }

  /// Updates the position of an animated marker based on elapsed time
  void _updateMarkerPosition(String markerId, Timer timer) {
    final startTime = _startTimes[markerId];
    final startPosition = _startPositions[markerId];
    final targetPosition = _targetPositions[markerId];

    if (startTime == null || startPosition == null || targetPosition == null) {
      timer.cancel();
      _animationTimers.remove(markerId);
      return;
    }

    final now = DateTime.now();
    final elapsedMilliseconds = now.difference(startTime).inMilliseconds;
    final totalMilliseconds = animationDuration.inMilliseconds;

    // Calculate progress (0.0 to 1.0)
    double progress = elapsedMilliseconds / totalMilliseconds;

    // Apply easing function for smoother animation (ease-in-out)
    if (progress < 0.5) {
      progress = 2 * progress * progress; // Ease in
    } else {
      progress = -1 + (4 - 2 * progress) * progress; // Ease out
    }

    // Clamp progress to 0.0-1.0
    progress = progress.clamp(0.0, 1.0);

    if (progress >= 1.0) {
      // Animation completed
      timer.cancel();
      _animationTimers.remove(markerId);
      _startTimes.remove(markerId);
      _startPositions.remove(markerId);
      _targetPositions.remove(markerId);

      // Generate a new random direction for the next movement
      final random = Random();
      final moveAngle = random.nextDouble() * 2 * pi;
      final moveDistance = 200; // 200 meters

      final moveLatOffset = moveDistance * cos(moveAngle) / 111111;
      final moveLngOffset =
          moveDistance *
          sin(moveAngle) /
          (111111 * cos(targetPosition.latitude * pi / 180));

      final newTargetLat = targetPosition.latitude + moveLatOffset;
      final newTargetLng = targetPosition.longitude + moveLngOffset;

      // Start a new animation cycle
      _startPositions[markerId] = targetPosition;
      _targetPositions[markerId] = LatLng(newTargetLat, newTargetLng);
      _startTimes[markerId] = now;

      _animationTimers[markerId] = Timer.periodic(
        const Duration(milliseconds: 16),
        (timer) => _updateMarkerPosition(markerId, timer),
      );
    } else {
      // Calculate interpolated position
      final lat =
          startPosition.latitude +
          (targetPosition.latitude - startPosition.latitude) * progress;
      final lng =
          startPosition.longitude +
          (targetPosition.longitude - startPosition.longitude) * progress;
      final currentPosition = LatLng(lat, lng);

      // Update marker position
      // We need to find the marker and replace it
      // Get a copy of the marker to update
      final oldMarkers = markers
          .where((m) => m.markerId.value == markerId)
          .toList();

      if (oldMarkers.isNotEmpty) {
        // Remove the old marker
        markers.removeWhere((m) => m.markerId.value == markerId);

        // Create the updated marker
        final updatedMarker = Marker(
          markerId: MarkerId(markerId),
          position: currentPosition,
          rotation: oldMarkers.first.rotation,
          icon: oldMarkers.first.icon,
          infoWindow: oldMarkers.first.infoWindow,
        );

        // Add the updated marker
        markers.add(updatedMarker);
      } else {
        // If marker not found, create a new one (fallback)
        markers.add(
          Marker(
            markerId: MarkerId(markerId),
            position: currentPosition,
            icon: markerIconTaxiCar, // Fallback icon
            rotation: Random().nextDouble() * 360,
            infoWindow: InfoWindow(
              title: 'Moving Vehicle',
              snippet: 'This vehicle is in motion',
            ),
          ),
        );
      }

      notifyListeners();
    }
  }

  @override
  void dispose() {
    // Cancel all animation timers
    for (final timer in _animationTimers.values) {
      timer.cancel();
    }
    _animationTimers.clear();
    super.dispose();
  }
}
