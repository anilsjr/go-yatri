import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:goyatri/core/util/app_constant.dart' show AppConstant;
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  final String googleApiKey = AppConstant.googleApiKey;
  LatLng? _currentPosition;

  final LatLng _initialPosition = AppConstant.initialPosition;

  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<LatLng> _polylineCoordinates = [];

  final TextEditingController _searchController = TextEditingController();
  String? _mapStyle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadMapStyle();
      _getCurrentLocation();
      _checkLocationPermission();
    });
  }

  Future<void> _loadMapStyle() async {
    _mapStyle = await DefaultAssetBundle.of(
      context,
    ).loadString(AppConstant.mapStylePath);
  }

  Future<void> _getCurrentLocation() async {
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

    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _markers.add(
        Marker(
          markerId: MarkerId('current'),
          position: _currentPosition!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );

      // Move camera to current location
      mapController.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition!, 14),
      );
    });
  }

  Future<void> _checkLocationPermission() async {
    if (await Permission.location.request().isGranted) {
      // Permission granted
    } else {
      await Permission.location.request();
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    if (_mapStyle != null) {
      mapController.setMapStyle(_mapStyle);
    }
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId('start'),
          position: _currentPosition ?? _initialPosition,
        ),
      );
    });
  }

  Future<void> _drawRoute(LatLng start, LatLng end) async {
    final Dio dio = Dio();
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&mode=driving&key=$googleApiKey';

    print("Fetching route from: $url");

    try {
      final response = await dio.get(url);
      if (response.statusCode == 200) {
        final data = response.data;

        if (data['routes'].isNotEmpty) {
          _polylineCoordinates.clear();

          // Get all steps from all legs
          final legs = data['routes'][0]['legs'];
          for (var leg in legs) {
            final steps = leg['steps'];
            for (var step in steps) {
              final points = step['polyline']['points'];
              List<PointLatLng> result = PolylinePoints.decodePolyline(points);

              result.forEach((point) {
                _polylineCoordinates.add(
                  LatLng(point.latitude, point.longitude),
                );
              });
            }
          }

          setState(() {
            _polylines.clear();
            _polylines.add(
              Polyline(
                polylineId: PolylineId('route'),
                points: _polylineCoordinates,
                width: 5,
                color: Colors.blue,
                patterns: [], // Solid line
              ),
            );
          });
        }
      }
    } catch (e) {
      print("Error fetching route: $e");
    }
  }

  void _onPlaceSelected(double lat, double lng) {
    LatLng selected = LatLng(lat, lng);

    setState(() {
      _markers.add(
        Marker(markerId: MarkerId('destination'), position: selected),
      );
    });

    mapController.animateCamera(CameraUpdate.newLatLngZoom(selected, 14));
    // _drawRoute(_initialPosition, selected);
    _drawRoute(_currentPosition!, selected);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Google Maps with Search')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: GooglePlaceAutoCompleteTextField(
              textEditingController: _searchController,
              googleAPIKey: googleApiKey,
              inputDecoration: InputDecoration(
                hintText: 'Search Places',
                contentPadding: EdgeInsets.symmetric(
                  // vertical: 10,
                  horizontal: 12,
                ),
                border: InputBorder.none,
              ),
              debounceTime: 600,
              countries: ["in"],
              isLatLngRequired: true,
              getPlaceDetailWithLatLng: (prediction) {
                final lat = double.parse(prediction.lat!);
                final lng = double.parse(prediction.lng!);
                _onPlaceSelected(lat, lng);
              },
              itemClick: (prediction) {
                _searchController.text = prediction.description!;
                FocusScope.of(context).unfocus();
              },
            ),
          ),
          Expanded(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _initialPosition,
                zoom: 12,
              ),
              markers: _markers,
              polylines: _polylines,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
          ),
        ],
      ),
    );
  }
}
