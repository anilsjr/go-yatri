import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../provider/location_provider.dart';
import '../../../map/presentation/pages/map_home_page.dart';

class DropLocationPage extends StatefulWidget {
  const DropLocationPage({Key? key}) : super(key: key);

  @override
  State<DropLocationPage> createState() => _DropLocationPageState();
}

class _DropLocationPageState extends State<DropLocationPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    // Initialize the provider for drop location
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LocationProvider>().switchMode(LocationMode.drop);
      context.read<LocationProvider>().init();
    });

    // Listen to focus changes for showing/hiding suggestions
    _searchFocusNode.addListener(() {
      setState(() {
        _showSuggestions = _searchFocusNode.hasFocus;
      });
    });

    // Listen to text changes for search
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final provider = context.read<LocationProvider>();
    provider.searchLocations(_searchController.text);
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
      body: Consumer<LocationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(provider),
              _buildSelectOnMapButton(context, provider),
              Padding(
                padding: const EdgeInsets.only(
                  left: 16.0,
                  top: 16.0,
                  bottom: 8.0,
                ),
                child: Text(
                  'RECENT LOCATIONS',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Expanded(
                child: _showSuggestions && provider.searchResults.isNotEmpty
                    ? _buildSearchResults(provider)
                    : _buildRecentLocations(provider),
              ),
              if (provider.selectedPickupLocation != null &&
                  provider.selectedDropLocation != null)
                _buildViewRouteButton(context, provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(LocationProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: 'Enter drop location',
          prefixIcon: const Icon(Icons.search, color: Colors.red, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    provider.clearSearchResults();
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

  Widget _buildSelectOnMapButton(
    BuildContext context,
    LocationProvider provider,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: OutlinedButton.icon(
        onPressed: () async {
          // Navigate to map selection screen
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MapHomePage(
                isPickupSelection: false, // This is drop selection
                initialLocation: provider.currentLocation,
              ),
            ),
          );

          if (result != null && result is LatLng) {
            // Process the selected location from map
            provider.createLocationFromLatLng(
              result,
              'Selected Location',
              'Location selected on map',
            );
            Navigator.pop(context); // Return to previous screen
          }
        },
        icon: const Icon(Icons.map_outlined, color: Colors.red, size: 18),
        label: const Text(
          'Select on map',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
    );
  }

  Widget _buildSearchResults(LocationProvider provider) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: provider.searchResults.length,
      itemBuilder: (context, index) {
        final location = provider.searchResults[index];
        return _buildLocationTile(location, provider);
      },
    );
  }

  Widget _buildRecentLocations(LocationProvider provider) {
    if (provider.recentLocations.isEmpty) {
      return const Center(child: Text('No recent locations'));
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: provider.recentLocations.length,
      itemBuilder: (context, index) {
        final location = provider.recentLocations[index];
        return _buildLocationTile(location, provider);
      },
    );
  }

  Widget _buildLocationTile(location, LocationProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: InkWell(
        onTap: () {
          provider.selectLocation(location);
          Navigator.pop(context); // Return to previous screen
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                location.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: location.isFavorite ? Colors.red : Colors.grey,
                size: 22,
              ),
              onPressed: () => provider.toggleFavorite(location.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewRouteButton(
    BuildContext context,
    LocationProvider provider,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ElevatedButton(
        onPressed: () {
          // Navigate to map view with pickup and drop locations
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MapHomePage(
                pickupLocation: provider.selectedPickupLocation,
                dropLocation: provider.selectedDropLocation,
              ),
            ),
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
          'VIEW ROUTE',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
