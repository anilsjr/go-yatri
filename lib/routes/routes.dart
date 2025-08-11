import 'package:get/get.dart';
import 'package:goyatri/features/auth-firebase/presentaion/pages/home_page.dart';
import 'package:goyatri/features/auth-firebase/presentaion/pages/login_page.dart';
import 'package:goyatri/features/auth-firebase/presentaion/pages/signup_page.dart';
import 'package:goyatri/features/location/presentaion/pages/map_home_page.dart';
import 'package:goyatri/features/history/presentation/pages/ride_history_page.dart';

class AppRoutes {
  static const String home = '/home';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String mappage = '/map';
  static const String rideHistory = '/history';

  static final routes = [
    GetPage(name: home, page: () => HomePage()),
    GetPage(name: login, page: () => LoginPage()),
    GetPage(name: signup, page: () => SignupPage()),
    GetPage(name: mappage, page: () => MapScreen()),
    GetPage(name: rideHistory, page: () => RideHistoryPage()),
  ];
}
