import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class LoginController with ChangeNotifier {
  String phone = '';
  String smsOtp = '';
  int? _resendToken;
  String? _verificationId;
  bool _otpSent = false;

  bool get otpSent => _otpSent;
  void sendOtp() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    await auth.verifyPhoneNumber(
      phoneNumber: phone,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        print('Verification failed: ${e.message}');
      },
      codeSent: (String verificationId, int? resendToken) {
        _resendToken = resendToken;
        _verificationId = verificationId;
        _otpSent = true;
        notifyListeners();
        print('Code sent to $phone');
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        print('Code auto-retrieval timeout');
      },
    );
  }

  // void toggleOtpSent() {
  //   _otpSent = !_otpSent;
  //   notifyListeners();
  // }

  void resendOtp() async {
    FirebaseAuth auth = FirebaseAuth.instance;
    await auth.verifyPhoneNumber(
      phoneNumber: phone,
      forceResendingToken: _resendToken,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await auth.signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        print('Resend failed: ${e.message}');
      },
      codeSent: (String verificationId, int? resendToken) {
        _resendToken = resendToken;
        print('Code resent to $phone');
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        print('Resend code auto-retrieval timeout');
      },
    );
  }

  void verifyOTP() async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsOtp,
      );

      // Sign in with the credential
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      print('✅ Phone number verified. UID: ${userCredential.user?.uid}');

      Get.offNamed('/details');
    } catch (e) {
      print('❌ Invalid OTP or Verification Failed: $e');
    }
  }
}
