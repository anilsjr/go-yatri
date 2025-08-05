import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  // Implement local storage methods here
  static Future<SharedPreferences> get prefs async {
    return await SharedPreferences.getInstance();
  }

  static Future<void> saveString(String key, String value) async {
    final SharedPreferences preferences = await prefs;
    await preferences.setString(key, value);
  }

  static Future<String?> getString(String key) async {
    final SharedPreferences preferences = await prefs;
    return preferences.getString(key);
  }

  static Future<void> remove(String key) async {
    final SharedPreferences preferences = await prefs;
    await preferences.remove(key);
  }

  static Future<void> clear() async {
    final SharedPreferences preferences = await prefs;
    await preferences.clear();
  }

  // static Future<bool> containsKey(String key) async {
  //   final SharedPreferences preferences = await prefs;
  //   return preferences.containsKey(key);
  // }
}
