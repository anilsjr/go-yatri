import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:goyatri/features/location/data/models/location_model.dart';
import 'package:goyatri/features/location/presentation/provider/map_controller.dart';

class MapHomePage extends StatefulWidget {
  final LocationModel? pickupLocation;
  final LocationModel? dropLocation;
  final bool isPickupSelection;
  final LatLng? initialLocation;

  const MapHomePage({
    Key? key,
    this.pickupLocation,
    this.dropLocation,
    this.isPickupSelection = false,
    this.initialLocation,
  }) : super(key: key);

  @override
  State<MapHomePage> createState() => _MapHomePageState();
}

class _MapHomePageState extends State<MapHomePage> {
  late MapController _mapController;
  bool _isInitialized = false;
  bool _routeDrawn = false;
  bool _mapCreated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  Future<void> _initialize() async {
    _mapController = Provider.of<MapController>(context, listen: false);

    // Step 1: Ensure current location is loaded
    if (_mapController.currentPosition == null) {
      await _mapController.getCurrentLocation();
    }

    setState(() {
      _isInitialized = true;
    });

    // If map is already created, we can update route
    if (_mapCreated) {
      _updateRouteIfNeeded();
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    // Use the MapController's onMapCreated method
    _mapController.onMapCreated(controller);

    setState(() {
      _mapCreated = true;
    });

    // Now that map is created, update route if needed
    _updateRouteIfNeeded();
  }

  void _updateRouteIfNeeded() {
    // If this is a route view (both pickup and drop are provided)
    final pickupLatLng = LatLng(
      widget.pickupLocation!.latitude,
      widget.pickupLocation!.longitude,
    );

    final dropLatLng = LatLng(
      widget.dropLocation!.latitude,
      widget.dropLocation!.longitude,
    );

    // Add pickup marker
    _mapController.markers.removeWhere(
      (marker) => marker.markerId.value == 'pickup',
    );
    _mapController.markers.add(
      Marker(
        markerId: const MarkerId('pickup'),
        position: pickupLatLng,
        icon: _mapController.markerIconGreen,
        infoWindow: InfoWindow(
          title: widget.pickupLocation!.name,
          snippet: widget.pickupLocation!.address,
        ),
      ),
    );

    // Add drop marker
    _mapController.markers.removeWhere(
      (marker) => marker.markerId.value == 'drop',
    );
    _mapController.markers.add(
      Marker(
        markerId: const MarkerId('drop'),
        position: dropLatLng,
        icon: _mapController.markerIconRed,
        infoWindow: InfoWindow(
          title: widget.dropLocation!.name,
          snippet: widget.dropLocation!.address,
        ),
      ),
    );

    // Draw route between the two points
    _mapController.drawRoute(pickupLatLng, dropLatLng);

    //load rider markers

    _mapController.plotRandomRiderMarkers();
    setState(() {
      _routeDrawn = true;
    });
  }

  bool isRouteView = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Consumer<MapController>(
              builder: (context, mapController, child) {
                return Stack(
                  children: [
                    GoogleMap(
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: CameraPosition(
                        target:
                            widget.initialLocation ??
                            mapController.currentPosition ??
                            const LatLng(28.7041, 77.1025), // Default: Delhi
                        zoom: 14,
                      ),
                      markers: mapController.markers,
                      polylines: mapController.polylines,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      onCameraMove: (_) {
                        if (isRouteView) {
                          setState(() {
                            isRouteView = false;
                          });
                        }
                      },
                      onTap:
                          widget.pickupLocation != null &&
                              widget.dropLocation != null
                          ? null // Disable tap in route view mode
                          : _handleMapTap,
                    ),

                    // Current Location Button
                    _locateMeBtn(mapController),
                    // Locate Path Button
                    !isRouteView
                        ? _locatePathBtn(mapController)
                        : SizedBox(height: 1),

                    // Select this location button - only show in selection mode
                    if (!(widget.pickupLocation != null &&
                        widget.dropLocation != null))
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 80,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.isPickupSelection
                                ? Colors.green
                                : Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () {
                            // Return the center position of the map to the calling page
                            if (mapController.mapController != null) {
                              mapController.mapController!
                                  .getVisibleRegion()
                                  .then((bounds) {
                                    final center = LatLng(
                                      (bounds.northeast.latitude +
                                              bounds.southwest.latitude) /
                                          2,
                                      (bounds.northeast.longitude +
                                              bounds.southwest.longitude) /
                                          2,
                                    );
                                    Navigator.pop(context, center);
                                  });
                            }
                          },
                          child: const Text(
                            'SELECT THIS LOCATION',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),

                    // Book ride button - only show in route view mode
                    if (widget.pickupLocation != null &&
                        widget.dropLocation != null)
                      Positioned(
                        bottom: 16,
                        left: 16,
                        right: 80,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: () {
                            // TODO: Implement booking logic
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Booking functionality will be implemented soon!',
                                ),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: const Text(
                            'BOOK RIDE',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
    );
  }

  void _handleMapTap(LatLng position) {
    // If we're in selection mode, show a pin at the tapped location
    if (_mapController.mapController != null) {
      final markerId = MarkerId(
        widget.isPickupSelection ? 'pickup_select' : 'drop_select',
      );

      // Remove existing selection marker
      _mapController.markers.removeWhere(
        (marker) => marker.markerId.value == markerId,
      );

      // Add new marker
      _mapController.markers.add(
        Marker(
          markerId: markerId,
          position: position,
          icon: widget.isPickupSelection
              ? _mapController.markerIconGreen
              : _mapController.markerIconRed,
        ),
      );

      // Force a rebuild to show the new marker
      setState(() {});

      // Center the map on the selected location
      _mapController.mapController!.animateCamera(
        CameraUpdate.newLatLng(position),
      );
    }
  }

  Widget _locateMeBtn(MapController mapController) {
    return Positioned(
      bottom: 16,
      right: 16,
      child: IconButton(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(Colors.white),
          shape: WidgetStateProperty.all(const CircleBorder()),
        ),
        onPressed: () => mapController.moveToCurrentLocation(),
        icon: const Icon(Icons.my_location, color: Colors.blue),
      ),
    );
  }

  Widget _locatePathBtn(MapController mapController) {
    return Positioned(
      bottom: 60,
      right: 16,
      child: IconButton(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(Colors.white),
          shape: WidgetStateProperty.all(const CircleBorder()),
        ),
        onPressed: () {
          mapController.fitCameraToPolyline();
          setState(() {
            isRouteView = true;
          });
        },
        icon: const Icon(Icons.directions, color: Colors.brown),
      ),
    );
  }
}
