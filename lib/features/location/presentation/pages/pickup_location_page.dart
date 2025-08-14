import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:goyatri/features/location/data/models/location_model.dart';
import 'package:goyatri/routes/routes.dart';
import 'package:provider/provider.dart';
import '../provider/location_provider.dart';

class PickupLocationPage extends StatefulWidget {
  const PickupLocationPage({super.key});

  @override
  State<PickupLocationPage> createState() => _PickupLocationPageState();
}

class _PickupLocationPageState extends State<PickupLocationPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  Timer? _debounceTimer;
  bool _showSuggestions = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _setupListeners();
    _initializeProvider();
  }

  void _setupListeners() {
    // Focus listener for suggestions
    _searchFocusNode.addListener(_onFocusChanged);

    // Text change listener with debounce
    _searchController.addListener(_onSearchChanged);
  }

  void _onFocusChanged() {
    final hasFocus = _searchFocusNode.hasFocus;
    if (_showSuggestions != hasFocus) {
      setState(() {
        _showSuggestions = hasFocus;
      });
    }
  }

  void _initializeProvider() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      final provider = context.read<LocationProvider>();
      provider.switchMode(LocationMode.pickup);

      // Only initialize if not already initialized
      if (!_isInitialized) {
        await provider.init();
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    });
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        context.read<LocationProvider>().searchLocations(
          _searchController.text,
        );
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'PICKUP',
        style: TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<LocationProvider>(
      builder: (context, provider, child) {
        // Show loading only on first load
        if (!_isInitialized && provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CurrentLocationTile(onTap: _handleCurrentLocationTap),
            _SearchBar(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onClear: _handleSearchClear,
            ),
            const Divider(
              thickness: 1,
              color: Color.fromARGB(255, 228, 228, 228),
            ),
            Expanded(child: _buildLocationsList(provider)),
            _SelectOnMapButton(onPressed: _handleSelectOnMap),
          ],
        );
      },
    );
  }

  Widget _buildLocationsList(LocationProvider provider) {
    // Show search results when searching and has focus
    if (_showSuggestions && provider.searchResults.isNotEmpty) {
      return _LocationsList(
        locations: provider.searchResults,
        onLocationTap: _handleLocationTap,
        onFavoriteTap: _handleFavoriteTap,
        isSearchResults: true,
      );
    }

    // Show recent locations
    return _LocationsList(
      locations: provider.recentLocations,
      onLocationTap: _handleLocationTap,
      onFavoriteTap: _handleFavoriteTap,
      isSearchResults: false,
    );
  }

  // Event handlers
  Future<void> _handleCurrentLocationTap() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showPermissionDeniedDialog();
        return;
      }

      if (!mounted) return;

      await context.read<LocationProvider>().selectCurrentLocation();
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to get current location');
      }
    }
  }

  void _handleLocationTap(LocationModel location) {
    context.read<LocationProvider>().selectLocation(location);
    Navigator.pop(context);
  }

  void _handleFavoriteTap(String locationId) {
    context.read<LocationProvider>().toggleFavorite(locationId);
  }

  void _handleSearchClear() {
    _searchController.clear();
    context.read<LocationProvider>().clearSearchResults();
  }

  void _handleSelectOnMap() {
    Get.toNamed(AppRoutes.selectLocation, arguments: {'isPickup': true});
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'Please grant location permission to use current location feature.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// Extracted widgets for better performance
class _CurrentLocationTile extends StatelessWidget {
  final VoidCallback onTap;

  const _CurrentLocationTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.withOpacity(0.1),
              ),
              child: const Center(
                child: Icon(Icons.my_location, color: Colors.green, size: 20),
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
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, child) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            decoration: InputDecoration(
              hintText: 'pickup location',
              prefixIcon: const Icon(
                Icons.search,
                color: Colors.green,
                size: 20,
              ),
              suffixIcon: value.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: onClear,
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
          );
        },
      ),
    );
  }
}

class _LocationsList extends StatelessWidget {
  final List<LocationModel> locations;
  final Function(LocationModel) onLocationTap;
  final Function(String) onFavoriteTap;
  final bool isSearchResults;

  const _LocationsList({
    required this.locations,
    required this.onLocationTap,
    required this.onFavoriteTap,
    required this.isSearchResults,
  });

  @override
  Widget build(BuildContext context) {
    if (locations.isEmpty) {
      return Center(
        child: Text(
          isSearchResults ? 'No search results' : 'No recent locations',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: (locations.length < 10) ? locations.length : 10,
      cacheExtent: 500, // Improved scrolling performance
      itemBuilder: (context, index) {
        final location = locations[index];
        return _LocationTile(
          location: location,
          onTap: () => onLocationTap(location),
          onFavoriteTap: () => onFavoriteTap(location.id),
        );
      },
    );
  }
}

class _LocationTile extends StatelessWidget {
  final LocationModel location;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  const _LocationTile({
    required this.location,
    required this.onTap,
    required this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    // Skip current location items in recent locations
    if (_isCurrentLocationItem()) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 4.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on, color: Colors.green, size: 24),
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          location.address,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                    onPressed: onFavoriteTap,
                    padding: const EdgeInsets.all(4),
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.0),
              Divider(
                height: 0.5,
                color: const Color.fromARGB(255, 240, 240, 240),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isCurrentLocationItem() {
    return location.name.toLowerCase().contains("current location") ||
        location.address.toLowerCase().contains("your current location");
  }
}

class _SelectOnMapButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _SelectOnMapButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 2,
        ),
        child: const Text(
          'SELECT ON MAP',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
