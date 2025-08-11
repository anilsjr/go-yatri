import 'package:get/get.dart';
import 'package:goyatri/features/auth-firebase/presentaion/pages/home_page.dart';
import 'package:goyatri/features/auth-firebase/presentaion/pages/login_page.dart';
import 'package:goyatri/features/auth-firebase/presentaion/pages/signup_page.dart';
import 'package:goyatri/features/location/presentation/pages/map_home_page.dart';
import 'package:goyatri/features/home/presentation/pages/new_home_page.dart';
import 'package:goyatri/features/home/presentation/pages/menu_page.dart';

class AppRoutes {
  static const String home = '/home';
  static const String newHome = '/new-home';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String mappage = '/map';
  static const String menu = '/menu';

  static final routes = [
    GetPage(name: home, page: () => NewHomePage()),
    GetPage(name: newHome, page: () => NewHomePage()),
    GetPage(name: login, page: () => LoginPage()),
    GetPage(name: signup, page: () => SignupPage()),
    GetPage(name: mappage, page: () => MapHomePage()),
    GetPage(name: menu, page: () => MenuPage()),
  ];
}
