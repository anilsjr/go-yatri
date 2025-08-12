import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:goyatri/routes/routes.dart';

class LoginController with ChangeNotifier {
  String phone = '';
  String smsOtp = '';
  int? _resendToken;
  String? _verificationId;
  bool _otpSent = false;
  bool _isLoading = false;
  String? _errorMessage;

  bool get otpSent => _otpSent;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  Future<void> sendOtp() async {
    if (_isLoading) return;
    _setLoading(true);
    _setError(null);

    try {
      FirebaseAuth auth = FirebaseAuth.instance;
      await auth.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await auth.signInWithCredential(credential);
            Get.offNamed(AppRoutes.home);
          } catch (e) {
            _setError('Auto-verification failed: ${e.toString()}');
          } finally {
            _setLoading(false);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          _setError('Verification failed: ${e.message}');
          _setLoading(false);
        },
        codeSent: (String verificationId, int? resendToken) {
          _resendToken = resendToken;
          _verificationId = verificationId;
          _otpSent = true;
          _setError(null);
          _setLoading(false);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Timeout handled
        },
      );
    } catch (e) {
      _setError('Failed to send OTP: ${e.toString()}');
      _setLoading(false);
    }
  }

  Future<void> resendOtp() async {
    if (_isLoading) return;
    _setLoading(true);
    _setError(null);

    try {
      FirebaseAuth auth = FirebaseAuth.instance;
      await auth.verifyPhoneNumber(
        phoneNumber: phone,
        forceResendingToken: _resendToken,
        verificationCompleted: (PhoneAuthCredential credential) async {
          try {
            await auth.signInWithCredential(credential);
            Get.offNamed(AppRoutes.home);
          } catch (e) {
            _setError('Auto-verification failed: ${e.toString()}');
          } finally {
            _setLoading(false);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          _setError('Resend failed: ${e.message}');
          _setLoading(false);
        },
        codeSent: (String verificationId, int? resendToken) {
          _resendToken = resendToken;
          _verificationId = verificationId;
          _setError(null);
          _setLoading(false);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Timeout handled
        },
      );
    } catch (e) {
      _setError('Failed to resend OTP: ${e.toString()}');
      _setLoading(false);
    }
  }

  Future<void> verifyOTP() async {
    if (_isLoading) return;
    _setLoading(true);
    _setError(null);

    try {
      if (_verificationId == null) {
        throw Exception('Verification ID is null');
      }

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsOtp,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      Get.offNamed(AppRoutes.home);
    } catch (e) {
      _setError('Invalid OTP or Verification Failed: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }
}
