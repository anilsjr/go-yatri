import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:goyatri/features/location/presentation/provider/map_controller.dart';
import 'package:goyatri/features/location/presentation/provider/location_provider.dart';
import 'package:goyatri/features/location/data/models/location_model.dart';

class SelectLocationPage extends StatefulWidget {
  const SelectLocationPage({super.key, required this.isPickup});

  final bool isPickup;

  @override
  State<SelectLocationPage> createState() => _SelectLocationPageState();
}

class _SelectLocationPageState extends State<SelectLocationPage> {
  late bool isPickup;
  GoogleMapController? googleMapController;
  LatLng? selectedLocation;
  String selectedAddress = "";
  late MapController _mapController;
  final _uuid = Uuid();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    print("====called init in select location page==========");
    isPickup = widget.isPickup;
    _mapController = Provider.of<MapController>(context, listen: false);

    // Set a default location (Delhi) so map renders instantly
    selectedLocation = const LatLng(28.6139, 77.2090);

    // Fetch actual location AFTER first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchLocationAndAddress();
    });
  }

  Future<void> _fetchLocationAndAddress() async {
    print("=====getting curr location====");
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        selectedLocation = LatLng(position.latitude, position.longitude);
      });

      _getAddressFromLatLng(selectedLocation!);
    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    print("====getting address from latlng====");
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          selectedAddress =
              "${place.street}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Location"),
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: selectedLocation ?? const LatLng(28.6139, 77.2090),
              zoom: 14,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: true,
            onMapCreated: (controller) {
              googleMapController = controller;
              _mapController.onMapCreated(controller);
            },
            onCameraMove: (position) {
              selectedLocation = position.target;
            },
            onCameraIdle: () {
              if (selectedLocation != null) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 500), () {
                  _getAddressFromLatLng(selectedLocation!);
                });
              }
            },
          ),

          // Current Location Button
          _locateMeBtn(),

          // Center pin
          Center(
            child: Icon(
              Icons.location_pin,
              size: 50,
              color: isPickup ? Colors.green : Colors.red,
            ),
          ),

          // Address + Confirm button
          Positioned(
            bottom: 20,
            left: 40,
            right: 40,
            child: ElevatedButton(
              onPressed: selectedLocation != null && selectedAddress.isNotEmpty
                  ? () {
                      final locationModel = LocationModel(
                        id: _uuid.v4(),
                        name: selectedAddress,
                        address: selectedAddress,
                        latitude: selectedLocation!.latitude,
                        longitude: selectedLocation!.longitude,
                        timestamp: DateTime.now(),
                      );

                      context.read<LocationProvider>().selectLocation(
                        locationModel,
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text(
                            "Location selected successfully!",
                          ),
                          backgroundColor: isPickup ? Colors.green : Colors.red,
                          duration: const Duration(seconds: 1),
                        ),
                      );

                      Navigator.pop(context);
                      Navigator.pop(context);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isPickup ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                disabledBackgroundColor: Colors.grey,
              ),
              child: Text(
                selectedAddress.isEmpty
                    ? "Getting address..."
                    : "Confirm Location",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _locateMeBtn() {
    return Positioned(
      bottom: 66,
      right: 16,
      child: Consumer<MapController>(
        builder: (context, mapController, child) {
          return IconButton(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.white),
              shape: WidgetStateProperty.all(const CircleBorder()),
            ),
            onPressed: () => mapController.moveToCurrentLocation(),
            icon: const Icon(Icons.my_location, color: Colors.blue),
          );
        },
      ),
    );
  }
}
