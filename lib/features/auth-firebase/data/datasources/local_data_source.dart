import 'dart:convert';
import '../models/auth_model.dart';
import '../../../../storage/local_share_preference.dart';

abstract class AuthLocalDataSource {
  Future<AuthModel?> getCachedUser();
  Future<void> cacheUser(AuthModel user);
  Future<void> clearCachedUser();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  static const String _userKey = 'cached_user';

  @override
  Future<AuthModel?> getCachedUser() async {
    try {
      final userString = await LocalStorage.getString(_userKey);
      if (userString != null) {
        final Map<String, dynamic> userJson = jsonDecode(userString);
        return AuthModel.fromJson(userJson);
      }
      return null;
    } catch (e) {
      print('Error getting cached user: $e');
      return null;
    }
  }

  @override
  Future<void> cacheUser(AuthModel user) async {
    try {
      final userJson = jsonEncode(user.toJson());
      await LocalStorage.saveString(_userKey, userJson);
    } catch (e) {
      print('Error caching user: $e');
    }
  }

  @override
  Future<void> clearCachedUser() async {
    try {
      await LocalStorage.remove(_userKey);
    } catch (e) {
      print('Error clearing cached user: $e');
    }
  }
}
