import 'package:get/get.dart';
import 'package:goyatri/features/auth-firebase/presentaion/pages/login_page.dart';
import 'package:goyatri/features/auth-firebase/presentaion/pages/signup_page.dart';
import 'package:goyatri/features/home/presentation/pages/new_home_page.dart';
import 'package:goyatri/features/home/presentation/pages/menu_page.dart';
import 'package:goyatri/features/map/presentation/pages/map_home_page.dart';
import 'package:goyatri/features/splash/presentation/pages/splash_page.dart';
import 'package:goyatri/wrapper/wrapper.dart';

class AppRoutes {
  static const String home = '/home';
  static const String auth = '/auth';

  static const String newHome = '/new-home';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String mappage = '/mapHome';
  static const String menu = '/menu';
  static const String splash = '/splash';

  static final routes = [
    GetPage(name: home, page: () => NewHomePage()),
    GetPage(
      name: mappage,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        return MapHomePage(
          pickupLocation: args?['pickupLocation'],
          dropLocation: args?['dropLocation'],
          isPickupSelection: args?['isPickupSelection'] ?? false,
          showRoute: args?['showRoute'] ?? false,
          initialLocation: args?['initialLocation'],
        );
      },
    ),
    GetPage(name: login, page: () => LoginPage()),
    GetPage(name: signup, page: () => SignupPage()),
    GetPage(name: menu, page: () => MenuPage()),
    GetPage(name: splash, page: () => SplashPage()),
    GetPage(name: auth, page: () => AuthWrapper()),
  ];
}
