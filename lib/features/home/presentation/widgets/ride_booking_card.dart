import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:goyatri/features/location/presentation/provider/location_provider.dart';
import 'package:goyatri/features/location/presentation/pages/pickup_location_page.dart';
import 'package:goyatri/features/location/presentation/pages/drop_location_page.dart';
import 'package:goyatri/features/map/presentation/pages/map_home_page.dart';

class RideBookingCard extends StatelessWidget {
  const RideBookingCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section
                Row(
                  children: [
                    Text(
                      'Pickup',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    _buildForMeDropdown(),
                  ],
                ),
                SizedBox(height: 16),
                // Pickup and Drop Location Fields
                _buildLocationFields(context, locationProvider),
                SizedBox(height: 8),
                // Select on map button
                _buildSelectOnMapButton(context),
                SizedBox(height: 8),
                // Recent locations
                _buildRecentLocations(locationProvider),

                // View Route button (only show when both pickup and drop are selected)
                if (locationProvider.selectedPickupLocation != null &&
                    locationProvider.selectedDropLocation != null)
                  _buildViewRouteButton(context, locationProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildViewRouteButton(
    BuildContext context,
    LocationProvider provider,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: ElevatedButton(
        onPressed: () {
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
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: const Text(
          'VIEW ROUTE',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildForMeDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'For me',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down, size: 18),
        ],
      ),
    );
  }

  Widget _buildLocationFields(BuildContext context, LocationProvider provider) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Pickup Location Field
          _buildLocationField(
            context: context,
            isPickup: true,
            provider: provider,
            icon: Icon(Icons.circle, color: Colors.green, size: 12),
            hintText: 'Pickup location',
            location: provider.selectedPickupLocation?.name ?? '',
          ),

          // Divider with line connecting pickup and drop icons
          Row(
            children: [
              SizedBox(width: 24),
              Container(width: 2, height: 20, color: Colors.grey.shade300),
              Expanded(
                child: Divider(
                  height: 0,
                  thickness: 1,
                  color: Colors.grey.shade200,
                ),
              ),
            ],
          ),

          // Drop Location Field
          _buildLocationField(
            context: context,
            isPickup: false,
            provider: provider,
            icon: Icon(Icons.circle, color: Colors.red, size: 12),
            hintText: 'Drop location',
            location: provider.selectedDropLocation?.name ?? '',
          ),
        ],
      ),
    );
  }

  Widget _buildLocationField({
    required BuildContext context,
    required bool isPickup,
    required LocationProvider provider,
    required Widget icon,
    required String hintText,
    required String location,
  }) {
    return InkWell(
      onTap: () async {
        provider.switchMode(isPickup ? LocationMode.pickup : LocationMode.drop);
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChangeNotifierProvider.value(
              value: provider,
              child: isPickup ? PickupLocationPage() : DropLocationPage(),
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            icon,
            SizedBox(width: 12),
            Expanded(
              child: Text(
                location.isEmpty ? hintText : location,
                style: TextStyle(
                  fontSize: 16,
                  color: location.isEmpty ? Colors.grey : Colors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectOnMapButton(BuildContext context) {
    return InkWell(
      onTap: () {
        // Navigate to map selection screen
        final provider = Provider.of<LocationProvider>(context, listen: false);
        provider.switchMode(LocationMode.pickup);

        // Only show map directly if both locations are selected
        if (provider.selectedPickupLocation != null &&
            provider.selectedDropLocation != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MapHomePage(
                pickupLocation: provider.selectedPickupLocation,
                dropLocation: provider.selectedDropLocation,
              ),
            ),
          );
        } else {
          // Default to pickup location page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChangeNotifierProvider.value(
                value: provider,
                child: PickupLocationPage(),
              ),
            ),
          );
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 18, color: Colors.black87),
            SizedBox(width: 8),
            Text(
              'Select on map',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentLocations(LocationProvider provider) {
    // Only show recent locations if there are any
    if (provider.recentLocations.isEmpty) {
      return SizedBox.shrink();
    }

    // Get up to 3 recent locations
    final recentLocations = provider.recentLocations.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(),
        ...recentLocations.map(
          (location) => _buildRecentLocationTile(location, provider),
        ),
      ],
    );
  }

  Widget _buildRecentLocationTile(location, LocationProvider provider) {
    return InkWell(
      onTap: () {
        provider.selectLocation(location);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(Icons.history, size: 18, color: Colors.grey),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.name,
                    style: TextStyle(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    location.address,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              location.isFavorite ? Icons.favorite : Icons.favorite_border,
              size: 18,
              color: location.isFavorite ? Colors.red : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
