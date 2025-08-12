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
    super.key,
    this.pickupLocation,
    this.dropLocation,
    this.isPickupSelection = false,
    this.showRoute = false,
    this.initialLocation,
  });

  @override
  State<MapHomePage> createState() => _MapHomePageState();
}

class _MapHomePageState extends State<MapHomePage> {
  late MapController _mapController;
  bool _isInitialized = false;
  bool _mapCreated = false;

  // Cache for ride options to prevent rebuilds
  Future<List<Map<String, dynamic>>>? _cachedRideOptionsFuture;
  String? _lastRouteKey;

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

    // Only load rider markers when showRoute is true (i.e., when 'VIEW ROUTE' button was clicked)
    if (widget.showRoute) {
      _mapController.plotRandomRiderMarkers('Bike', pickupLatLng);
    }
  }

  bool isRouteView = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Consumer<MapController>(
                    builder: (context, mapController, child) {
                      return Stack(
                        children: [
                          GoogleMap(
                            onMapCreated: _onMapCreated,
                            initialCameraPosition: CameraPosition(
                              target:
                                  widget.initialLocation ??
                                  mapController.currentPosition ??
                                  const LatLng(
                                    28.7041,
                                    77.1025,
                                  ), // Default: Delhi
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
                        ],
                      );
                    },
                  ),
                ),
                // Ride options container - show only in route view mode
                // This is outside the Consumer to prevent rebuilds on map changes
                if (widget.showRoute) _buildRideOptionsContainer(),
              ],
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
      debugPrint('Error getting ride options: $e');
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
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Colors.black.withOpacity(0.05) : Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.black.withOpacity(0.1)
                      : const Color.fromARGB(255, 255, 255, 250),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Image.asset(
                    'assets/icons/$icon.png',
                    width: isSelected ? 30 : 26,
                    height: isSelected ? 30 : 26,
                  ),
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
                              horizontal: 4,
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
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        if (badge != null) ...[
                          const SizedBox(width: 4),
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
    // Get the MapController without listening to changes (since parent Selector handles this)
    final mapController = Provider.of<MapController>(context, listen: false);
    final selectedOption = mapController.getSelectedTransportOptionDetails();
    final optionTitle = selectedOption?['title'] ?? 'Cab Economy';

    return SizedBox(
      width: double.infinity - 50,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Booking $optionTitle...'),
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
        child: Text(
          'Book $optionTitle',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Cached ride options container - only rebuild when location selection changes
  Widget _buildRideOptionsContainer() {
    return Container(
      height: 400,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ride options - Only rebuild when transport selection changes
            Selector<MapController, String>(
              selector: (context, mapController) =>
                  mapController.selectedTransportOption,
              builder: (context, selectedTransportOption, child) {
                return FutureBuilder<List<Map<String, dynamic>>>(
                  future: _getCachedRideOptions(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }

                    final rideOptions =
                        snapshot.data ?? _getDefaultRideOptions();

                    return Column(
                      children: rideOptions.map((option) {
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
                            if (option['id'] != null) {
                              _mapController.selectTransportOption(
                                option['id'],
                              );
                              
                              // Map option IDs to appropriate marker types
                              String vehicleType;
                              switch (option['id']) {
                                case 'car_economy':
                                case 'car_premium':
                                  vehicleType = 'Cab';
                                  break;
                                case 'auto':
                                  vehicleType = 'Auto';
                                  break;
                                case 'bike':
                                default:
                                  vehicleType = 'Bike';
                                  break;
                              }
                              
                              print('Plotting random rider markers for $vehicleType');
                              _mapController.plotRandomRiderMarkers(
                                vehicleType,
                                LatLng(
                                  widget.pickupLocation?.latitude ?? 0,
                                  widget.pickupLocation?.longitude ?? 0,
                                ),
                              );
                            }
                          },
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),

            // Book button
            const SizedBox(height: 16),
            Selector<MapController, String>(
              selector: (context, mapController) =>
                  mapController.selectedTransportOption,
              builder: (context, selectedTransportOption, child) {
                return _buildBookButton();
              },
            ),
          ],
        ),
      ),
    );
  }

  // Cache management for ride options
  Future<List<Map<String, dynamic>>> _getCachedRideOptions() {
    final routeKey =
        '${widget.pickupLocation?.latitude ?? 0},${widget.pickupLocation?.longitude ?? 0}-${widget.dropLocation?.latitude ?? 0},${widget.dropLocation?.longitude ?? 0}';

    if (_lastRouteKey != routeKey || _cachedRideOptionsFuture == null) {
      _lastRouteKey = routeKey;
      _cachedRideOptionsFuture = _getRideOptions();
    }

    return _cachedRideOptionsFuture!;
  }
}
