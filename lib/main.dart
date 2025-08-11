import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:goyatri/features/auth/presentaion/pages/login_page.dart';
import 'package:get/get.dart';
import 'package:goyatri/routes/routes.dart';
import 'package:goyatri/features/auth-firebase/presentaion/pages/home_page.dart';
import 'package:goyatri/features/auth-firebase/presentaion/pages/login_page.dart';
import 'package:provider/provider.dart';
import 'package:goyatri/features/auth-firebase/presentaion/controller/login_controller.dart';
import 'package:goyatri/features/auth-firebase/presentaion/controller/logout_controller.dart';
import 'package:goyatri/features/history/presentation/controller/history_controller.dart';
import 'package:goyatri/features/location/presentaion/controller/map_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set portrait orientation only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LoginController()),
        ChangeNotifierProvider(create: (context) => LogoutController()),
        ChangeNotifierProvider(
          create: (context) {
            final controller = MapController(navigatorKey.currentContext!);
            controller.init();
            return controller;
          },
        ),
        ChangeNotifierProvider(create: (context) => HistoryController()),
      ],
      child: MyApp(),
    ),
  );
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'GoYatri',
      home: AuthWrapper(),
      getPages: AppRoutes.routes,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          // User is signed in
          return HomePage();
        } else {
          // User is not signed in
          return LoginPage();
        }
      },
    );
  }
}
