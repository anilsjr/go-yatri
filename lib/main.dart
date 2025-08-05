import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:goyatri/features/auth/presentaion/pages/login_page.dart';
import 'package:get/get.dart';
import 'package:goyatri/routes/routes.dart';
import 'package:provider/provider.dart';
import 'package:goyatri/features/auth/presentaion/controller/login_controller.dart';

import 'package:goyatri/features/location/presentaion/controller/map_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => LoginController()),
        ChangeNotifierProvider(
          create: (context) {
            final controller = MapController(navigatorKey.currentContext!);
            controller.init();
            return controller;
          },
        ),
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
      initialRoute: AppRoutes.mappage,
      getPages: AppRoutes.routes,
    );
  }
}
