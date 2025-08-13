import 'package:flutter/material.dart';
import 'package:goyatri/features/home/presentation/widgets/ride_booking_card.dart';
import 'package:goyatri/features/location/presentation/provider/map_controller.dart';

class ExploreSection extends StatelessWidget {
  const ExploreSection({super.key});

  @override
  Widget build(BuildContext context) {
    final MapController _mapController = MapController(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ride Booking Card - New UI Component
        // const RideBookingCard(),
        const SizedBox(height: 24),

        // Explore header with modern styling
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: const Text(
            'Our Service',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
              letterSpacing: -0.5,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Modern grid layout for explore items
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _ExploreItem(
                  title: 'Auto',
                  subtitle: 'Quick & Affordable',
                  imagePath: 'assets/icons/auto_marker.png',
                  color: const Color(0xFF10B981),
                  textFontSize: 12,
                  onTap: () {
                    // Handle Auto tap
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ExploreItem(
                  title: 'Cab Economy',
                  subtitle: 'Comfortable Ride',
                  imagePath: 'assets/icons/car.png',
                  color: const Color(0xFF3B82F6),
                  textFontSize: 12,
                  onTap: () {
                    // Handle Cab tap
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ExploreItem(
                  title: 'Bike',
                  subtitle: 'Fastest Option',
                  imagePath: 'assets/icons/motorbike.png',
                  color: const Color(0xFFEF4444),
                  textFontSize: 12,
                  onTap: () {
                    _mapController.selectedTransportOption = 'Bike';
                  },
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }
}

class _ExploreItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imagePath;
  final Color color;
  final VoidCallback onTap;
  final double textFontSize;

  const _ExploreItem({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.color,
    required this.onTap,
    required this.textFontSize,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon container with colored background
            Container(
              width: 48,
              height: 48,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(imagePath, fit: BoxFit.contain),
            ),

            const SizedBox(height: 12),

            // Title
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: textFontSize,
                color: Color(0xFF1E293B),
              ),
            ),

            const SizedBox(height: 4),

            // Subtitle
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 8),

            //
          ],
        ),
      ),
    );
  }
}
