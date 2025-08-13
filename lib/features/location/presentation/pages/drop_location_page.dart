import 'dart:async';
import 'package:flutter/material.dart';
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
              _buildSearchBar(),
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
                  return showButton
                      ? _buildViewRouteButton(context)
                      : const SizedBox.shrink();
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
          itemCount: provider.recentLocations.length,
          itemBuilder: (context, index) {
            final location = provider.recentLocations[index];
            return _buildLocationTile(location);
          },
        );
      },
    );
  }

  Widget _buildLocationTile(location) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: InkWell(
        onTap: () {
          context.read<LocationProvider>().selectLocation(location);
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
              onPressed: () =>
                  context.read<LocationProvider>().toggleFavorite(location.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewRouteButton(BuildContext context) {
    return Consumer<LocationProvider>(
      builder: (context, provider, child) {
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
      },
    );
  }
}
