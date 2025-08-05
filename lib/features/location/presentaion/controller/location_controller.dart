// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:google_places_flutter/google_places_flutter.dart';
// import 'package:dio/dio.dart';
// import 'package:flutter_polyline_points/flutter_polyline_points.dart';
// import 'package:permission_handler/permission_handler.dart';

// void main() {
//   runApp(MaterialApp(home: MapScreen()));
// }

// class MapScreen extends StatefulWidget {
//   @override
//   State<MapScreen> createState() => _MapScreenState();
// }

// class _MapScreenState extends State<MapScreen> {
//   late GoogleMapController mapController;
//   final String googleApiKey =
//       'AIzaSyBIJfuTJME0jr6ubJCNuDK9oUEHMWNrzEY'; // <-- Replace with your API key

//   final LatLng _initialPosition = LatLng(28.6139, 77.2090); // Delhi
//   Set<Marker> _markers = {};
//   Set<Polyline> _polylines = {};
//   List<LatLng> _polylineCoordinates = [];

//   final TextEditingController _searchController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     _checkLocationPermission();
//   }

//   Future<void> _checkLocationPermission() async {
//     if (await Permission.location.request().isGranted) {
//       // Permission granted
//     } else {
//       await Permission.location.request();
//     }
//   }

//   void _onMapCreated(GoogleMapController controller) {
//     mapController = controller;
//     setState(() {
//       _markers.add(
//         Marker(markerId: MarkerId('start'), position: _initialPosition),
//       );
//     });
//   }

//   Future<void> _drawRoute(LatLng start, LatLng end) async {
//     final Dio dio = Dio();
//     final url =
//         'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&key=$googleApiKey';

//     print("Fetching route from: $url");

//     final response = await dio.get(url);
//     if (response.statusCode == 200) {
//       final points = response.data['routes'][0]['overview_polyline']['points'];
//       PolylinePoints polylinePoints = PolylinePoints(apiKey: googleApiKey);
//       List<PointLatLng> result = PolylinePoints.decodePolyline(points);

//       _polylineCoordinates.clear();
//       result.forEach((point) {
//         _polylineCoordinates.add(LatLng(point.latitude, point.longitude));
//       });

//       setState(() {
//         _polylines.clear();
//         _polylines.add(
//           Polyline(
//             polylineId: PolylineId('route'),
//             points: _polylineCoordinates,
//             width: 4,
//             color: Colors.blue,
//           ),
//         );
//       });
//     }
//   }

//   void _onPlaceSelected(double lat, double lng) {
//     LatLng selected = LatLng(lat, lng);

//     setState(() {
//       _markers.add(
//         Marker(markerId: MarkerId('destination'), position: selected),
//       );
//     });

//     mapController.animateCamera(CameraUpdate.newLatLngZoom(selected, 14));
//     _drawRoute(_initialPosition, selected);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Google Maps with Search')),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(8),
//             child: GooglePlaceAutoCompleteTextField(
//               textEditingController: _searchController,
//               googleAPIKey: googleApiKey,
//               inputDecoration: InputDecoration(
//                 hintText: 'Search Places',
//                 border: OutlineInputBorder(),
//               ),
//               debounceTime: 600,
//               countries: ["in"],
//               isLatLngRequired: true,
//               getPlaceDetailWithLatLng: (prediction) {
//                 final lat = double.parse(prediction.lat!);
//                 final lng = double.parse(prediction.lng!);
//                 _onPlaceSelected(lat, lng);
//               },
//               itemClick: (prediction) {
//                 _searchController.text = prediction.description!;
//                 FocusScope.of(context).unfocus();
//               },
//             ),
//           ),
//           Expanded(
//             child: GoogleMap(
//               onMapCreated: _onMapCreated,
//               initialCameraPosition: CameraPosition(
//                 target: _initialPosition,
//                 zoom: 12,
//               ),
//               markers: _markers,
//               polylines: _polylines,
//               myLocationEnabled: true,
//               myLocationButtonEnabled: true,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
