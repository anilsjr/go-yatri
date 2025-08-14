import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:goyatri/routes/routes.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../provider/location_provider.dart';
import '../../../map/presentation/pages/map_home_page.dart';

class DropLocationPage extends StatefulWidget {
  const DropLocationPage({super.key});

  @override
  State<DropLocationPage> createState() => _DropLocationPageState();
}

class _DropLocationPageState extends State<DropLocationPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _showSuggestions = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Initialize the provider for drop location (non-blocking)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<LocationProvider>();
      provider.switchMode(LocationMode.drop);
      // Load data asynchronously without blocking UI
      _initializeAsync(provider);
    });

    // Listen to focus changes for showing/hiding suggestions
    _searchFocusNode.addListener(() {
      setState(() {
        _showSuggestions = _searchFocusNode.hasFocus;
      });
    });

    // Listen to text changes for search with debounce
    _searchController.addListener(_onSearchChanged);
  }

  // Initialize provider data asynchronously
  Future<void> _initializeAsync(LocationProvider provider) async {
    // Don't call init() if data is already available
    if (provider.recentLocations.isEmpty || provider.currentLocation == null) {
      await provider.init();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Cancel previous timer if it exists
    _debounceTimer?.cancel();

    // Start new timer for debounced search
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      final provider = context.read<LocationProvider>();
      provider.searchLocations(_searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'DROP',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: Selector<LocationProvider, bool>(
        selector: (_, provider) => provider.isLoading,
        builder: (context, isLoading, child) {
          if (isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCurrentLocationItem(),
              _buildSearchBar(),
              const Divider(
                thickness: 1,
                color: Color.fromARGB(255, 228, 228, 228),
              ),
              Expanded(
                child: Selector<LocationProvider, bool>(
                  selector: (_, provider) => provider.searchResults.isNotEmpty,
                  builder: (context, hasSearchResults, child) {
                    return _showSuggestions && hasSearchResults
                        ? _buildSearchResults()
                        : _buildRecentLocations();
                  },
                ),
              ),
              Selector<LocationProvider, bool>(
                selector: (_, provider) =>
                    provider.selectedPickupLocation != null &&
                    provider.selectedDropLocation != null,
                builder: (context, showButton, child) {
                  return _buildSelectOnMapButton(context);
                  // : const SizedBox.shrink();
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: 'drop location',
          prefixIcon: const Icon(Icons.search, color: Colors.red, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<LocationProvider>().clearSearchResults();
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[200],
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    return Consumer<LocationProvider>(
      builder: (context, provider, child) {
        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: provider.searchResults.length,
          itemBuilder: (context, index) {
            final location = provider.searchResults[index];
            return _buildLocationTile(location);
          },
        );
      },
    );
  }

  Widget _buildRecentLocations() {
    return Consumer<LocationProvider>(
      builder: (context, provider, child) {
        if (provider.recentLocations.isEmpty) {
          return const Center(child: Text('No recent locations'));
        }

        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: provider.recentLocations.length < 10
              ? provider.recentLocations.length
              : 10,
          itemBuilder: (context, index) {
            final location = provider.recentLocations[index];
            return _buildLocationTile(location);
          },
        );
      },
    );
  }

  Widget _buildCurrentLocationItem() {
    return InkWell(
      onTap: () {
        _checkLocationPermission();
        context.read<LocationProvider>().selectCurrentLocation();
        Navigator.pop(context); // Return to home screen
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withOpacity(0.1),
              ),
              child: const Center(
                child: Icon(Icons.my_location, color: Colors.red, size: 20),
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Location',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'Using GPS',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
      return;
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }
  }

  Widget _buildLocationTile(location) {
    if ((location.name.toLowerCase().contains("current location")) ||
        (location.address.toLowerCase().contains("your current location"))) {
      return const SizedBox.shrink(); // Skip empty locations
    }
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 4.0),
      child: InkWell(
        onTap: () {
          context.read<LocationProvider>().selectLocation(location);
          Navigator.pop(context); // Return to previous screen
        },
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, color: Colors.red, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        location.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        location.address,
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    location.isFavorite
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: location.isFavorite ? Colors.red : Colors.grey,
                    size: 22,
                  ),
                  onPressed: () => context
                      .read<LocationProvider>()
                      .toggleFavorite(location.id),
                ),
              ],
            ),
            SizedBox(height: 2.0),
            Divider(height: 0.5, color: Colors.grey[300]),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectOnMapButton(BuildContext context) {
    return Consumer<LocationProvider>(
      builder: (context, provider, child) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: () {
              // Navigate to map view with pickup and drop locations
              Get.toNamed(
                AppRoutes.selectLocation,

                arguments: {'isPickup': true},
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text(
              'SELECT ON MAP',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }
}
