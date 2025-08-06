import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
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

  final BuildContext context;
  MapController(this.context);

  Future<void> init() async {
    await _loadMapStyle();
    await _loadMarkerIcons();
    await getCurrentLocation();
    await checkLocationPermission();

    // Generate nearby transport markers after getting current location
  }

  Future<void> _loadMapStyle() async {
    mapStyle = await DefaultAssetBundle.of(
      context,
    ).loadString(AppConstant.mapStylePath);
  }

  Future<void> _loadMarkerIcons() async {
    markerIconRed = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(devicePixelRatio: 1),
      'assets/icons/red_marker.png',
    );
    markerIconGreen = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(devicePixelRatio: 1),
      'assets/icons/green_marker.png',
    );
    markerIconBike = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(devicePixelRatio: 1),
      'assets/icons/bike_marker.png',
    );
    markerIconTaxiCar = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(devicePixelRatio: 1, size: Size(10, 48)),
      'assets/icons/taxi.png',
    );
    markerIconTaxiAuto = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(devicePixelRatio: 1),
      'assets/icons/auto3_marker.png',
    );
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

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    currentPosition = LatLng(position.latitude, position.longitude);
    // markers.add(
    //   Marker(
    //     markerId: MarkerId('current'),
    //     position: currentPosition!,
    //     icon: markerIconGreen,
    //   ),
    // );
    notifyListeners();
    if (mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(currentPosition!, 14),
      );
    }
  }

  Future<void> checkLocationPermission() async {
    if (await Permission.location.request().isGranted) {
      // Permission granted
    } else {
      await Permission.location.request();
    }
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (mapStyle != null) {
      mapController!.setMapStyle(mapStyle);
    }
    if (currentPosition != null) {
      markers.add(
        Marker(
          markerId: MarkerId('start'),
          position: currentPosition!,
          icon: markerIconGreen,
        ),
      );
    }
    notifyListeners();
  }

  Future<void> drawRoute(LatLng start, LatLng end) async {
    final Dio dio = Dio();
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&mode=driving&key=$googleApiKey';

    try {
      final response = await dio.get(url);
      if (response.statusCode == 200) {
        final data = response.data;
        if (kDebugMode) {
          print(
            'Response: ==================================================================================================================$data',
          );
          print(
            'Response: ==================================================================================================================end ---$url',
          );
        }
        if (data['routes'].isNotEmpty) {
          polylineCoordinates.clear();

          final legs = data['routes'][0]['legs'];
          for (var leg in legs) {
            final steps = leg['steps'];
            for (var step in steps) {
              final points = step['polyline']['points'];
              List<PointLatLng> result = PolylinePoints.decodePolyline(points);
              result.forEach((point) {
                polylineCoordinates.add(
                  LatLng(point.latitude, point.longitude),
                );
              });
            }
          }

          polylines.clear();
          polylines.add(
            Polyline(
              polylineId: PolylineId('route'),
              points: polylineCoordinates,
              width: 5,
              color: Colors.blue,
              patterns: [],
            ),
          );
          notifyListeners();
        }
      }
      await generateNearbyTransportMarkers(markerIconBike);
    } catch (e) {
      // Handle error
    }
  }

  void onPlaceSelected(double lat, double lng) {
    LatLng selected = LatLng(lat, lng);
    markers.add(
      Marker(
        markerId: MarkerId('destination'),
        position: selected,
        icon: markerIconRed,
      ),
    );
    notifyListeners();
    if (mapController != null) {
      mapController!.animateCamera(CameraUpdate.newLatLngZoom(selected, 14));
    }
    if (currentPosition != null) {
      drawRoute(currentPosition!, selected);
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
  Future<void> generateNearbyTransportMarkers(dynamic riderMarker) async {
    if (currentPosition == null) {
      await getCurrentLocation();
      if (currentPosition == null) return;
    }

    // Clear any existing nearby transport markers
    markers.removeWhere(
      (marker) => marker.markerId.value.startsWith('nearby_transport'),
    );

    // Get nearby places using Google Places API (roads)
    final Dio dio = Dio();
    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=${currentPosition!.latitude},${currentPosition!.longitude}'
        '&radius=1500' // 1.5km
        '&type=road'
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

            // Get coordinates from the place
            final lat = place['geometry']['location']['lat'];
            final lng = place['geometry']['location']['lng'];

            // Calculate a slightly offset position to ensure it's on the road side
            final offsetFactor = 0.00008; // Small offset
            final offsetLat =
                lat + (random % 100 - 50) / 1000000 * offsetFactor;
            final offsetLng =
                lng + (random % 100 - 50) / 1000000 * offsetFactor;

            // Select a random marker type
            final markerType = riderMarker;

            // Add the marker
            markers.add(
              Marker(
                rotation: Random().nextDouble() * 360, // Random rotation
                markerId: MarkerId(
                  'nearby_transport_${count}_${markerType['id']}',
                ),
                position: LatLng(offsetLat, offsetLng),
                icon: markerType['icon'] as BitmapDescriptor,
                infoWindow: InfoWindow(
                  title:
                      '${markerType['id'].toString().toUpperCase()} available',
                  snippet: 'Tap to book',
                ),
              ),
            );

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

            // Select a random marker type
            final markerType = riderMarker;

            // Add the marker
            markers.add(
              Marker(
                rotation: Random().nextDouble() * 360, // Random rotation
                markerId: MarkerId(
                  'nearby_transport_${count}_${markerType['id']}',
                ),
                position: LatLng(newLat, newLng),
                icon: markerType['icon'] as BitmapDescriptor,
                infoWindow: InfoWindow(
                  title:
                      '${markerType['id'].toString().toUpperCase()} available',
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
      _generateRandomMarkers();
    }
  }

  /// Fallback method to generate random markers without API
  void _generateRandomMarkers() {
    if (currentPosition == null) return;

    // List of marker types to use randomly
    final markerTypes = [
      {'id': 'bike', 'icon': markerIconBike},
      {'id': 'taxi', 'icon': markerIconTaxiCar},
      {'id': 'auto', 'icon': markerIconTaxiAuto},
    ];

    // Generate 5-8 random markers
    final random = DateTime.now().millisecondsSinceEpoch;
    final numMarkers = 5 + (random % 4); // Random number between 5-8

    for (int i = 0; i < numMarkers; i++) {
      // Generate random angle and distance (within 1.5km)
      final angle = (random + i * 50) % 360 * pi / 180;
      final distance = (random + i * 30) % 1500; // Random distance up to 1.5km

      // Convert to latitude/longitude offset
      // Approximately 111,111 meters per degree of latitude
      // Longitude degrees vary based on latitude
      final latOffset = distance * cos(angle) / 111111;
      final lngOffset =
          distance *
          sin(angle) /
          (111111 * cos(currentPosition!.latitude * pi / 180));

      final newLat = currentPosition!.latitude + latOffset;
      final newLng = currentPosition!.longitude + lngOffset;

      // Select a random marker type
      final markerType = markerTypes[(random + i) % markerTypes.length];

      // Add the marker
      markers.add(
        Marker(
          markerId: MarkerId('nearby_transport_${i}_${markerType['id']}'),
          position: LatLng(newLat, newLng),
          icon: markerType['icon'] as BitmapDescriptor,
          infoWindow: InfoWindow(
            title: '${markerType['id'].toString().toUpperCase()} available',
            snippet: 'Tap to book',
          ),
        ),
      );
    }

    notifyListeners();
  }
}
