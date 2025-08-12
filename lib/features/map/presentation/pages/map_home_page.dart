import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:goyatri/features/location/data/models/location_model.dart';
import 'package:goyatri/features/location/presentation/provider/map_controller.dart';

class MapHomePage extends StatefulWidget {
  final LocationModel? pickupLocation;
  final LocationModel? dropLocation;
  final bool isPickupSelection;
  final bool showRoute;
  final LatLng? initialLocation;

  const MapHomePage({
    Key? key,
    this.pickupLocation,
    this.dropLocation,
    this.isPickupSelection = false,
    this.showRoute = false,
    this.initialLocation,
  }) : super(key: key);

  @override
  State<MapHomePage> createState() => _MapHomePageState();
}

class _MapHomePageState extends State<MapHomePage> {
  late MapController _mapController;
  bool _isInitialized = false;
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
    // Only draw route if we have both locations and showRoute is true
    if (widget.pickupLocation == null ||
        widget.dropLocation == null ||
        !widget.showRoute) {
      return;
    }

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
                        if (widget.showRoute) {
                          setState(() {
                            isRouteView = false;
                          });
                        }
                      },
                      onTap: widget.showRoute
                          ? null // Disable tap in route view mode
                          : _handleMapTap,
                    ),

                    // Current Location Button
                    _locateMeBtn(mapController),
                    // Locate Path Button
                    _locatePathBtn(mapController),

                    // Book ride button - only show in route view mode
                    if (widget.showRoute)
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
                          onPressed: () => _showRideOptionsBottomSheet(context),
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

  void _showRideOptionsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.65,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Ride options
              Flexible(
                child: Consumer<MapController>(
                  builder: (context, mapController, child) {
                    return FutureBuilder<List<Map<String, dynamic>>>(
                      key: ValueKey(
                        mapController.selectedTransportOption,
                      ), // Force rebuild when selection changes
                      future: _getRideOptions(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final rideOptions =
                            snapshot.data ?? _getDefaultRideOptions();

                        return ListView.builder(
                          controller: scrollController,
                          itemCount: rideOptions.length,
                          itemBuilder: (context, index) {
                            final option = rideOptions[index];
                            return _buildRideOption(
                              icon: option['icon'],
                              title: option['title'],
                              subtitle: option['subtitle'],
                              price: option['price'],
                              isSelected: option['isSelected'] ?? false,
                              badge: option['badge'],
                              fastestBadge: option['fastestBadge'] ?? false,
                              optionId: option['id'],
                              onTap: () {
                                print(
                                  'DEBUG: Option tapped: ${option['id']} - ${option['title']}',
                                );
                                if (option['id'] != null) {
                                  _mapController.selectTransportOption(
                                    option['id'],
                                  );
                                }
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),

              // Book button
              _buildBookButton(),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getRideOptions() async {
    if (widget.pickupLocation == null || widget.dropLocation == null) {
      return _getDefaultRideOptions();
    }

    final pickupLatLng = LatLng(
      widget.pickupLocation!.latitude,
      widget.pickupLocation!.longitude,
    );

    final dropLatLng = LatLng(
      widget.dropLocation!.latitude,
      widget.dropLocation!.longitude,
    );

    try {
      return await _mapController.getRideOptions(pickupLatLng, dropLatLng);
    } catch (e) {
      print('Error getting ride options: $e');
      return _getDefaultRideOptions();
    }
  }

  List<Map<String, dynamic>> _getDefaultRideOptions() {
    return [
      {
        'id': 'bike',
        'icon': '🏍️',
        'title': 'Bike',
        'subtitle': '2 mins • Drop 11:53 pm',
        'price': '₹59',
        'isSelected': _mapController.selectedTransportOption == 'bike',
        'fastestBadge': true,
      },
      {
        'id': 'car_economy',
        'icon': '🚗',
        'title': 'Cab Economy',
        'subtitle': 'Affordable car rides\n2 mins away • Drop 11:53 pm',
        'price': '₹138',
        'isSelected': _mapController.selectedTransportOption == 'car_economy',
        'badge': '👥 4',
      },
      {
        'id': 'auto',
        'icon': '🛺',
        'title': 'Auto',
        'subtitle': '2 mins • Drop 11:53 pm',
        'price': '₹111',
        'isSelected': _mapController.selectedTransportOption == 'auto',
      },
      {
        'id': 'car_premium',
        'icon': '🚗',
        'title': 'Cab Premium',
        'subtitle': '2 mins • Drop 11:53 pm',
        'price': '₹166',
        'isSelected': _mapController.selectedTransportOption == 'car_premium',
      },
    ];
  }

  Widget _buildRideOption({
    required String icon,
    required String title,
    required String subtitle,
    required String price,
    required bool isSelected,
    String? badge,
    bool fastestBadge = false,
    String? optionId,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Colors.black.withOpacity(0.05) : Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.black.withOpacity(0.1)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(icon, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (fastestBadge) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'FASTEST',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            badge,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // Price
              Text(
                price,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          final selectedOption = _mapController
              .getSelectedTransportOptionDetails();
          final optionName = selectedOption?['title'] ?? 'Cab Economy';

          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Booking $optionName...'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(
            0xFFFFC107,
          ), // Yellow color like in image
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: const Text(
          'Book Cab Economy',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
