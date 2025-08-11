import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../provider/location_provider.dart';
import '../../data/models/location_model.dart';
import 'map_selection_screen.dart';

class LocationSelectionScreen extends StatefulWidget {
  const LocationSelectionScreen({Key? key}) : super(key: key);

  @override
  State<LocationSelectionScreen> createState() =>
      _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _showSuggestions = false;

  @override
  void initState() {
    super.initState();
    // Initialize the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: _buildModeToggle(),
      ),
      body: Consumer<LocationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCurrentLocationItem(provider),
              _buildSearchBar(provider),
              _buildSelectOnMapButton(context),
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
            ],
          );
        },
      ),
    );
  }

  Widget _buildModeToggle() {
    return Consumer<LocationProvider>(
      builder: (context, provider, child) {
        return Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => provider.switchMode(LocationMode.pickup),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: provider.mode == LocationMode.pickup
                            ? Colors.green
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'PICKUP',
                      style: TextStyle(
                        color: provider.mode == LocationMode.pickup
                            ? Colors.green
                            : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => provider.switchMode(LocationMode.drop),
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: provider.mode == LocationMode.drop
                            ? Colors.red
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'DROP',
                      style: TextStyle(
                        color: provider.mode == LocationMode.drop
                            ? Colors.red
                            : Colors.grey[400],
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCurrentLocationItem(LocationProvider provider) {
    final Color iconColor = provider.mode == LocationMode.pickup
        ? Colors.green
        : Colors.red;

    return InkWell(
      onTap: () {
        provider.selectCurrentLocation();
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
                color: iconColor.withOpacity(0.1),
              ),
              child: Center(
                child: Icon(Icons.my_location, color: iconColor, size: 20),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Location',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'Using GPS',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(LocationProvider provider) {
    final Color iconColor = provider.mode == LocationMode.pickup
        ? Colors.green
        : Colors.red;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        decoration: InputDecoration(
          hintText: provider.mode == LocationMode.pickup
              ? 'Enter pickup location'
              : 'Enter drop location',
          prefixIcon: Icon(Icons.search, color: iconColor, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear),
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
          contentPadding: EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildSelectOnMapButton(BuildContext context) {
    return Consumer<LocationProvider>(
      builder: (context, provider, child) {
        final Color buttonColor = provider.mode == LocationMode.pickup
            ? Colors.green
            : Colors.red;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: OutlinedButton.icon(
            onPressed: () async {
              // Navigate to map selection screen
              final LatLng? result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MapSelectionScreen(
                    mode: provider.mode,
                    initialLocation: provider.currentLocation,
                  ),
                ),
              );

              if (result != null) {
                // Process the selected location from map
                provider.createLocationFromLatLng(
                  result,
                  'Selected Location',
                  'Location selected on map',
                );
                // Return to previous screen (home)
                Navigator.pop(context);
              }
            },
            icon: Icon(Icons.map_outlined, color: buttonColor, size: 18),
            label: Text(
              'Select on map',
              style: TextStyle(
                color: buttonColor,
                fontWeight: FontWeight.w500,
                fontSize: 15,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: buttonColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Colors.white,
              minimumSize: Size(double.infinity, 48),
            ),
          ),
        );
      },
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
      return Center(child: Text('No recent locations'));
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

  Widget _buildLocationTile(LocationModel location, LocationProvider provider) {
    final Color iconColor = provider.mode == LocationMode.pickup
        ? Colors.green
        : Colors.red;

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
            Icon(Icons.location_on, color: iconColor, size: 24),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.name,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 2),
                  Text(
                    location.address,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8),
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
}
