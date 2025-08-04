import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// import 'package:goyatri/features/auth/presentaion/pages/login_page.dart';
import 'package:get/get.dart';
import 'package:goyatri/routes/routes.dart';
import 'package:provider/provider.dart';
import 'package:goyatri/features/auth/presentaion/controller/login_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    ChangeNotifierProvider(
      create: (context) => LoginController(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'GoYatri',
      initialRoute: AppRoutes.mappage,
      getPages: AppRoutes.routes,
    );
  }
}
