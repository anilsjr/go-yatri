import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../provider/location_provider.dart';

class MapSelectionScreen extends StatefulWidget {
  final LocationMode mode;
  final LatLng? initialLocation;

  const MapSelectionScreen({Key? key, required this.mode, this.initialLocation})
    : super(key: key);

  @override
  State<MapSelectionScreen> createState() => _MapSelectionScreenState();
}

class _MapSelectionScreenState extends State<MapSelectionScreen> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: widget.mode == LocationMode.pickup
            ? Colors.green
            : Colors.red,
        title: Text(
          widget.mode == LocationMode.pickup
              ? 'Select Pickup Location'
              : 'Select Drop Location',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          _buildGoogleMap(),
          _buildCenterPin(),
          _buildLoadingIndicator(),
          _buildConfirmButton(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: widget.mode == LocationMode.pickup
            ? Colors.green
            : Colors.red,
        child: Icon(Icons.my_location, color: Colors.white),
        onPressed: _moveToCurrentLocation,
      ),
    );
  }

  Widget _buildGoogleMap() {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target:
            _selectedLocation ??
            LatLng(28.7041, 77.1025), // Default to Delhi if no location
        zoom: 15,
      ),
      onMapCreated: (controller) {
        _mapController = controller;
        setState(() => _isLoading = false);

        // Load map style
        _loadMapStyle();
      },
      onCameraMove: (position) {
        setState(() {
          _selectedLocation = position.target;
        });
      },
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: false,
      mapToolbarEnabled: false,
    );
  }

  Widget _buildCenterPin() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 36.0),
        child: Icon(
          Icons.location_pin,
          color: widget.mode == LocationMode.pickup ? Colors.green : Colors.red,
          size: 48,
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return _isLoading
        ? Center(child: CircularProgressIndicator())
        : SizedBox.shrink();
  }

  Widget _buildConfirmButton() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: ElevatedButton(
        onPressed: _selectedLocation == null
            ? null
            : () => Navigator.pop(
                context,
                _selectedLocation,
              ), // Return selected location to previous screen
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.mode == LocationMode.pickup
              ? Colors.green
              : Colors.red,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
        ),
        child: Text(
          'Confirm Location',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _moveToCurrentLocation() async {
    try {
      setState(() => _isLoading = true);

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final currentLocation = LatLng(position.latitude, position.longitude);

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(currentLocation, 15),
      );

      setState(() {
        _selectedLocation = currentLocation;
        _isLoading = false;
      });
    } catch (e) {
      print('Error getting current location: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMapStyle() async {
    try {
      String mapStyle = await DefaultAssetBundle.of(
        context,
      ).loadString('assets/map/map_style.json');
      _mapController?.setMapStyle(mapStyle);
    } catch (e) {
      print('Error loading map style: $e');
    }
  }
}
