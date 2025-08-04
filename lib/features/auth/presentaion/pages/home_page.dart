import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:goyatri/routes/routes.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home Page')),
      body: Center(child: Text('Welcome to the Home Page!')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.toNamed(AppRoutes.mappage);
        },
        child: Icon(Icons.map),
      ),
    );
  }
}
