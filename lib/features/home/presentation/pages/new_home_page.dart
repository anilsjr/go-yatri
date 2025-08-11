import 'package:flutter/material.dart';
import 'package:goyatri/features/home/presentation/widgets/home_app_bar.dart';
import 'package:goyatri/features/home/presentation/widgets/explore_section.dart';
import 'package:get/get.dart';
import 'package:goyatri/routes/routes.dart';

class NewHomePage extends StatefulWidget {
  const NewHomePage({super.key});

  @override
  State<NewHomePage> createState() => _NewHomePageState();
}

class _NewHomePageState extends State<NewHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color.fromARGB(255, 255, 255, 250),
      appBar: HomeAppBar(
        onMenuTap: () {
          // Navigate to the menu page instead of opening drawer
          Get.toNamed(AppRoutes.menu);
        },
      ),

      // We'll keep the drawer definition but we won't be using it anymore
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Explore section
            ExploreSection(),
          ],
        ),
      ),
    );
  }
}
