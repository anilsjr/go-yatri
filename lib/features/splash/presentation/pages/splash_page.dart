import 'package:flutter/material.dart';
import 'package:goyatri/asset_loader/asset_loader.dart';
import 'package:goyatri/routes/routes.dart';
import 'package:get/get.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      AssetLoader().startLoading(context);
    });

    // Navigate to the home page after a 2-second delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Get.offNamed(AppRoutes.home);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFC3E4C8),
      body: Center(
        child: Image.asset(
          'assets/icons/app_logo.png',
          width: 200,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
