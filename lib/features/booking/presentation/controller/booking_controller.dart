import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum BookingStatus {
  idle,
  searching,
  driverFound,
  driverArriving,
  onTrip,
  completed,
  cancelled,
}

class BookingController extends ChangeNotifier {
  BookingStatus _status = BookingStatus.idle;
  BookingStatus get status => _status;

  // Booking details
  LatLng? _origin;
  LatLng? _destination;
  String? _destinationName;
  String? _vehicleType;
  int? _price;
  String? _estimatedTime;

  // Driver details
  String? _driverName;
  String? _driverRating;
  String? _vehicleDetails;
  String? _driverPhoneNumber;
  LatLng? _driverLocation;

  // Getters
  LatLng? get origin => _origin;
  LatLng? get destination => _destination;
  String? get destinationName => _destinationName;
  String? get vehicleType => _vehicleType;
  int? get price => _price;
  String? get estimatedTime => _estimatedTime;
  String? get driverName => _driverName;
  String? get driverRating => _driverRating;
  String? get vehicleDetails => _vehicleDetails;
  String? get driverPhoneNumber => _driverPhoneNumber;
  LatLng? get driverLocation => _driverLocation;

  // Timer for simulating driver movement
  Timer? _driverMovementTimer;
  Timer? _statusUpdateTimer;

  void startBooking({
    required LatLng origin,
    required LatLng destination,
    required String destinationName,
    required String vehicleType,
    required int price,
    required String estimatedTime,
  }) {
    _origin = origin;
    _destination = destination;
    _destinationName = destinationName;
    _vehicleType = vehicleType;
    _price = price;
    _estimatedTime = estimatedTime;

    // Change status to searching
    _status = BookingStatus.searching;
    notifyListeners();

    // Simulate finding a driver after 3 seconds
    _statusUpdateTimer = Timer(const Duration(seconds: 3), () {
      _status = BookingStatus.driverFound;
      _assignRandomDriver();
      notifyListeners();

      // Simulate driver arriving after 5 seconds
      _statusUpdateTimer = Timer(const Duration(seconds: 5), () {
        _status = BookingStatus.driverArriving;
        _startDriverMovement();
        notifyListeners();

        // Simulate trip start after 10 seconds
        _statusUpdateTimer = Timer(const Duration(seconds: 10), () {
          _status = BookingStatus.onTrip;
          _startTripMovement();
          notifyListeners();

          // Simulate trip completion after 15 seconds
          _statusUpdateTimer = Timer(const Duration(seconds: 15), () {
            _status = BookingStatus.completed;
            _stopDriverMovement();
            _saveRideToHistory();
            notifyListeners();
          });
        });
      });
    });
  }

  void cancelBooking() {
    _status = BookingStatus.cancelled;
    _stopDriverMovement();
    _statusUpdateTimer?.cancel();
    notifyListeners();

    // Reset after 3 seconds
    Timer(const Duration(seconds: 3), () {
      resetBooking();
    });
  }

  void resetBooking() {
    _status = BookingStatus.idle;
    _origin = null;
    _destination = null;
    _destinationName = null;
    _vehicleType = null;
    _price = null;
    _estimatedTime = null;
    _driverName = null;
    _driverRating = null;
    _vehicleDetails = null;
    _driverPhoneNumber = null;
    _driverLocation = null;
    notifyListeners();
  }

  void _assignRandomDriver() {
    // Generate random driver details
    final Random random = Random();
    final List<String> names = ['Rahul', 'Amit', 'Vijay', 'Sanjay', 'Rajesh'];
    final List<String> vehicles = [
      'Honda Activa',
      'Bajaj Pulsar',
      'TVS Jupiter',
      'Royal Enfield',
      'Hero Splendor',
    ];

    _driverName = names[random.nextInt(names.length)];
    _driverRating = (3.5 + random.nextDouble() * 1.5).toStringAsFixed(1);
    _vehicleDetails = vehicles[random.nextInt(vehicles.length)];
    _driverPhoneNumber = '+91${9800000000 + random.nextInt(999999999)}';

    // Set initial driver location (1-2 km away from origin)
    final double distance = 0.01 + random.nextDouble() * 0.01; // ~1-2 km
    final double bearing = random.nextDouble() * 2 * pi;

    final double lat1 = _origin!.latitude * pi / 180;
    final double lon1 = _origin!.longitude * pi / 180;

    final double lat2 = asin(
      sin(lat1) * cos(distance) + cos(lat1) * sin(distance) * cos(bearing),
    );

    final double lon2 =
        lon1 +
        atan2(
          sin(bearing) * sin(distance) * cos(lat1),
          cos(distance) - sin(lat1) * sin(lat2),
        );

    _driverLocation = LatLng(lat2 * 180 / pi, lon2 * 180 / pi);
  }

  void _startDriverMovement() {
    // Update driver location every second to simulate movement towards pickup point
    _driverMovementTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_driverLocation != null && _origin != null) {
        // Move driver 10% closer to pickup location
        final double newLat =
            _driverLocation!.latitude +
            (_origin!.latitude - _driverLocation!.latitude) * 0.1;
        final double newLng =
            _driverLocation!.longitude +
            (_origin!.longitude - _driverLocation!.longitude) * 0.1;
        _driverLocation = LatLng(newLat, newLng);
        notifyListeners();

        // Check if driver is close enough to pickup point
        if (_isDriverNearLocation(_driverLocation!, _origin!)) {
          timer.cancel();
        }
      }
    });
  }

  void _startTripMovement() {
    // Update driver location every second to simulate movement towards destination
    _driverMovementTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_driverLocation != null && _destination != null) {
        // Move driver 10% closer to destination
        final double newLat =
            _driverLocation!.latitude +
            (_destination!.latitude - _driverLocation!.latitude) * 0.1;
        final double newLng =
            _driverLocation!.longitude +
            (_destination!.longitude - _driverLocation!.longitude) * 0.1;
        _driverLocation = LatLng(newLat, newLng);
        notifyListeners();

        // Check if driver is close enough to destination
        if (_isDriverNearLocation(_driverLocation!, _destination!)) {
          timer.cancel();
        }
      }
    });
  }

  bool _isDriverNearLocation(LatLng driverLocation, LatLng targetLocation) {
    // Calculate distance between two points
    const double threshold = 0.0005; // Approximately 50 meters
    final double distance = sqrt(
      pow(driverLocation.latitude - targetLocation.latitude, 2) +
          pow(driverLocation.longitude - targetLocation.longitude, 2),
    );
    return distance < threshold;
  }

  void _stopDriverMovement() {
    _driverMovementTimer?.cancel();
    _driverMovementTimer = null;
  }

  // Save ride to history when completed
  void _saveRideToHistory() {
    if (_origin != null &&
        _destination != null &&
        _status == BookingStatus.completed) {
      try {
        // This method would need to be implemented in a real app
        // You would inject the HistoryController and call its saveRide method
        // For this example, we'll leave it as a placeholder

        // Future implementation:
        // historyController.saveRide(
        //   startLocation: _origin!,
        //   endLocation: _destination!,
        //   startAddress: 'Your Location',
        //   endAddress: _destinationName ?? 'Destination',
        //   vehicleType: _vehicleType ?? 'Bike',
        //   fare: _price?.toDouble() ?? 0.0,
        //   driverName: _driverName ?? 'Driver',
        //   driverRating: _driverRating ?? '4.5',
        // );
      } catch (e) {
        debugPrint('Error saving ride to history: $e');
      }
    }
  }

  @override
  void dispose() {
    _stopDriverMovement();
    _statusUpdateTimer?.cancel();
    super.dispose();
  }
}
