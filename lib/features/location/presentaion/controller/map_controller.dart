import 'dart:async';
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
  GoogleMapController? mapController;
  final String googleApiKey = 'AIzaSyBIJfuTJME0jr6ubJCNuDK9oUEHMWNrzEY';
  LatLng? currentPosition;
  LatLng initialPosition = AppConstant.initialPosition;
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
    initialPosition = currentPosition!;
    markers.add(
      Marker(
        markerId: MarkerId('current'),
        position: currentPosition!,
        icon: markerIconGreen,
      ),
    );
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
    markers.add(
      Marker(
        markerId: MarkerId('start'),
        position: currentPosition ?? initialPosition,
        icon: markerIconGreen,
      ),
    );
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
}
