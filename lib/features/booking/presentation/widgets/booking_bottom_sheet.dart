import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:goyatri/features/booking/presentation/controller/booking_controller.dart';

class BookingBottomSheet extends StatefulWidget {
  final LatLng origin;
  final LatLng destination;
  final String destinationName;

  const BookingBottomSheet({
    Key? key,
    required this.origin,
    required this.destination,
    required this.destinationName,
  }) : super(key: key);

  @override
  State<BookingBottomSheet> createState() => _BookingBottomSheetState();
}

class _BookingBottomSheetState extends State<BookingBottomSheet> {
  int _selectedVehicleIndex = 0;
  final List<Map<String, dynamic>> _vehicleOptions = [
    {
      'name': 'Bike',
      'icon': 'assets/icons/bike_marker.png',
      'price': 80,
      'time': '12 min',
    },
    {
      'name': 'Auto',
      'icon': 'assets/icons/auto_marker.png',
      'price': 120,
      'time': '18 min',
    },
    {
      'name': 'Car',
      'icon': 'assets/icons/taxi.png',
      'price': 200,
      'time': '20 min',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final bookingController = Provider.of<BookingController>(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose your ride',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'To: ${widget.destinationName}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                // Vehicle type selection
                SizedBox(
                  height: 140,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _vehicleOptions.length,
                    itemBuilder: (context, index) {
                      final vehicle = _vehicleOptions[index];
                      final isSelected = _selectedVehicleIndex == index;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedVehicleIndex = index;
                          });
                        },
                        child: Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.1)
                                : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).primaryColor
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 50,
                                child: Image.asset(
                                  vehicle['icon'],
                                  width: 48,
                                  height: 48,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                vehicle['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${vehicle['price']}',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                vehicle['time'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                // Payment method
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.payment, color: Colors.grey[700]),
                      const SizedBox(width: 12),
                      const Text(
                        'Cash',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const Spacer(),
                      Text(
                        '₹${_vehicleOptions[_selectedVehicleIndex]['price']}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Book now button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      final selectedVehicle =
                          _vehicleOptions[_selectedVehicleIndex];
                      bookingController.startBooking(
                        origin: widget.origin,
                        destination: widget.destination,
                        destinationName: widget.destinationName,
                        vehicleType: selectedVehicle['name'],
                        price: selectedVehicle['price'],
                        estimatedTime: selectedVehicle['time'],
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Book Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
