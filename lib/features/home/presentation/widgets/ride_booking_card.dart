import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:goyatri/features/location/presentation/provider/location_provider.dart';
import 'package:goyatri/features/location/presentation/pages/pickup_location_page.dart';
import 'package:goyatri/features/location/presentation/pages/drop_location_page.dart';

class RideBookingCard extends StatelessWidget {
  const RideBookingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section with modern typography
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFF3B82F6),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Where You Want To Go',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Pickup and Drop Location Fields with modern design
                _buildLocationFields(context, locationProvider),

                const SizedBox(height: 12),

                // Recent locations
                _buildRecentLocations(locationProvider),

                // Book Ride button (only show when both pickup and drop are selected)
                if (locationProvider.selectedPickupLocation != null &&
                    locationProvider.selectedDropLocation != null)
                  _buildBookRideButton(context, locationProvider),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBookRideButton(BuildContext context, LocationProvider provider) {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E293B), Color(0xFF334155)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E293B).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            if (provider.selectedPickupLocation == null ||
                provider.selectedDropLocation == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please select pickup and drop location'),
                  backgroundColor: Color(0xFFEF4444),
                ),
              );
              return;
            }
            if ((provider.selectedDropLocation?.latitude ==
                    provider.selectedPickupLocation?.latitude) &&
                (provider.selectedDropLocation?.longitude ==
                    provider.selectedPickupLocation?.longitude)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pickup and drop locations cannot be the same'),
                  backgroundColor: Color(0xFFEF4444),
                ),
              );
              return;
            } else {
              Navigator.pushNamed(
                context,
                '/mapHome',
                arguments: {
                  'pickupLocation': provider.selectedPickupLocation,
                  'dropLocation': provider.selectedDropLocation,
                  'isPickupSelection': true,
                  'showRoute': true,
                },
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.directions_car_rounded, size: 20),
              SizedBox(width: 8),
              Text(
                'Book Ride',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationFields(BuildContext context, LocationProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Pickup Location Field
          _buildLocationField(
            context: context,
            isPickup: true,
            provider: provider,
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.circle, color: Colors.white, size: 8),
            ),
            hintText: 'Pickup location',
            location: provider.selectedPickupLocation?.name ?? '',
          ),

          // Modern connecting line
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const SizedBox(width: 20),
                Container(
                  width: 2,
                  height: 24,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF10B981), Color(0xFFEF4444)],
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFE2E8F0),
                          const Color(0xFFE2E8F0).withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Drop Location Field
          _buildLocationField(
            context: context,
            isPickup: false,
            provider: provider,
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.circle, color: Colors.white, size: 8),
            ),
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location.isEmpty ? hintText : location,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: location.isEmpty
                          ? const Color(0xFF64748B)
                          : const Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (location.isNotEmpty) const SizedBox(height: 2),
                  if (location.isNotEmpty)
                    Text(
                      isPickup ? 'Pickup point' : 'Destination',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentLocations(LocationProvider provider) {
    // Only show recent locations if there are any
    if (provider.recentLocations.isEmpty) {
      return const SizedBox.shrink();
    }

    // Get up to 3 recent locations
    final recentLocations = provider.recentLocations.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF6B7280).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.history_rounded,
                size: 16,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Recent',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...recentLocations.map(
          (location) => _buildRecentLocationTile(location, provider),
        ),
      ],
    );
  }

  Widget _buildRecentLocationTile(location, LocationProvider provider) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
      ),
      child: InkWell(
        onTap: () {
          provider.selectLocation(location);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF64748B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  size: 16,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      location.address,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  location.isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 16,
                  color: location.isFavorite
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
