import 'package:get/get.dart';
import 'package:goyatri/features/auth/presentaion/pages/home_page.dart';
import 'package:goyatri/features/auth/presentaion/pages/login_page.dart';

class AppRoutes {
  static const String home = '/home';
  static const String login = '/login';

  static final routes = [
    GetPage(name: home, page: () => HomePage()),
    GetPage(name: login, page: () => LoginPage()),
  ];
}
