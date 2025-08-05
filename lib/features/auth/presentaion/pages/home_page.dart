import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:goyatri/routes/routes.dart';
import 'package:permission_handler/permission_handler.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home Page')),
      body: Center(child: Text('Welcome to the Home Page!')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Check location permission
          var status = await Permission.location.status;
          if (!status.isGranted) {
            status = await Permission.location.request();
            if (!status.isGranted) {
              await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Location Permission Required'),
                  content: Text(
                    'Please grant location permission to continue.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () async {
                        await openAppSettings();
                        Navigator.of(context).pop();
                      },
                      child: Text('Open Settings'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Cancel'),
                    ),
                  ],
                ),
              );
              return;
            }
          }
          Get.toNamed(AppRoutes.mappage);
        },
        child: Icon(Icons.map),
      ),
    );
  }
}
