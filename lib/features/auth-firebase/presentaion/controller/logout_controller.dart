import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:goyatri/routes/routes.dart';

class LogoutController with ChangeNotifier {
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Logs out the current user and navigates to the login screen
  Future<void> logout() async {
    _setLoading(true);
    try {
      await FirebaseAuth.instance.signOut();
      // Navigate to login page after successful logout
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      // If there's an error, show it
      Get.snackbar(
        'Logout Error',
        'Failed to logout: ${e.toString()}',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red[100],
        colorText: Colors.red[800],
        duration: const Duration(seconds: 4),
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Shows a confirmation dialog before logging out
  Future<bool> showLogoutConfirmation(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    return shouldLogout ?? false;
  }
}
