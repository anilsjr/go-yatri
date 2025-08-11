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
