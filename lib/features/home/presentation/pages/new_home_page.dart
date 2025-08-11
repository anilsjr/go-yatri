import 'package:flutter/material.dart';
import 'package:goyatri/features/home/presentation/widgets/home_app_bar.dart';
import 'package:goyatri/features/home/presentation/widgets/recent_places_section.dart';
import 'package:goyatri/features/home/presentation/widgets/explore_section.dart';
import 'package:goyatri/features/home/presentation/widgets/promotion_banner.dart';
import 'package:provider/provider.dart';
import 'package:goyatri/features/auth-firebase/presentaion/controller/logout_controller.dart';

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
          // Handle menu tap (drawer or navigation)
          _scaffoldKey.currentState?.openDrawer();
        },
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(0)),
                // shape: BoxShape.rectangle,
              ),
              child: Text(
                'GoYatri',
                style: TextStyle(color: Colors.black, fontSize: 24),
                textAlign: TextAlign.center,
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to profile page
              },
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text('Ride History'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to ride history page
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                // Navigate to settings page
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () async {
                Navigator.pop(context);
                final logoutController = Provider.of<LogoutController>(
                  context,
                  listen: false,
                );
                final shouldLogout = await logoutController
                    .showLogoutConfirmation(context);

                if (shouldLogout) {
                  await logoutController.logout();
                }
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recent places section

            // Divider

            // Explore section
            ExploreSection(),

            // Promotion banner
          ],
        ),
      ),
    );
  }
}
