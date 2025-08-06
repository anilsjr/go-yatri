import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:provider/provider.dart';
import '../controller/map_controller.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _MapScreenBody();
  }
}

class _MapScreenBody extends StatefulWidget {
  const _MapScreenBody();

  @override
  State<_MapScreenBody> createState() => _MapScreenBodyState();
}

class _MapScreenBodyState extends State<_MapScreenBody> {
  final TextEditingController _searchController = TextEditingController();
  bool isMyLocation = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MapController>(
      builder: (context, controller, child) {
        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: GooglePlaceAutoCompleteTextField(
                    textEditingController: _searchController,
                    googleAPIKey: controller.googleApiKey,
                    inputDecoration: const InputDecoration(
                      hintText: 'Search Places',
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      border: InputBorder.none,
                    ),
                    debounceTime: 600,
                    countries: ["in"],
                    isLatLngRequired: true,
                    getPlaceDetailWithLatLng: (prediction) {
                      final lat = double.parse(prediction.lat!);
                      final lng = double.parse(prediction.lng!);
                      controller.onPlaceSelected(lat, lng);
                      // Hide keyboard when place details are received
                      FocusScope.of(context).unfocus();
                    },
                    itemClick: (prediction) {
                      _searchController.text = prediction.description!;
                      FocusScope.of(context).unfocus();
                    },
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      GoogleMap(
                        onMapCreated: controller.onMapCreated,
                        rotateGesturesEnabled: false,
                        zoomControlsEnabled: false,
                        myLocationButtonEnabled: false,
                        compassEnabled: false,
                        initialCameraPosition: CameraPosition(
                          target:
                              controller.currentPosition ??
                              LatLng(20.5937, 78.9629),
                          zoom: 12,
                        ),
                        markers: controller.markers,
                        polylines: controller.polylines,
                        myLocationEnabled: true,
                      ),
                      Positioned(
                        bottom: 60,
                        right: 16,
                        child: IconButton(
                          iconSize: 20,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: const CircleBorder(),
                            // padding: const EdgeInsets.all(4),
                          ),
                          icon: const Icon(Icons.undo_rounded),
                          onPressed: () {
                            setState(() {
                              isMyLocation = false;
                            });
                            controller.fitCameraToPolyline();
                          },
                          tooltip: "Show Complete Path",
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: IconButton(
                          iconSize: 20,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: const CircleBorder(),
                          ),
                          onPressed: () {
                            setState(() {
                              isMyLocation = true;
                            });
                            controller.moveToCurrentLocation();
                          },
                          tooltip: "My Location",
                          icon: const Icon(Icons.my_location),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        left: 16,
                        child: IconButton(
                          iconSize: 20,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: const CircleBorder(),
                          ),
                          onPressed: () {
                            controller.generateNearbyTransportMarkers(
                              controller.markerIconTaxiAuto,
                            );
                          },
                          tooltip: "Show Nearby Transport",
                          icon: const Icon(Icons.local_taxi),
                        ),
                      ),
                      // Animated markers button
                      Positioned(
                        bottom: 60,
                        left: 60,
                        child: IconButton(
                          iconSize: 20,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: const CircleBorder(),
                          ),
                          onPressed: () {
                            controller.generateAnimatedMarkers(
                              controller.markerIconTaxiCar,
                            );
                          },
                          tooltip: "Show Moving Vehicles",
                          icon: const Icon(Icons.directions_car),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
