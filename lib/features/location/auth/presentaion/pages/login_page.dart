import 'package:flutter/material.dart';
import 'package:goyatri/features/auth-firebase/presentaion/controller/login_controller.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final LoginController loginController = Provider.of<LoginController>(
      context,
      listen: true,
    );
    return Scaffold(
      appBar: AppBar(title: Text('Login Page')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(labelText: 'Phone Number'),
            ),
            loginController.otpSent
                ? TextField(
                    controller: _otpController,
                    decoration: InputDecoration(labelText: 'OTP'),
                  )
                : Container(),
            ElevatedButton(
              onPressed: () {
                if (!loginController.otpSent) {
                  // Send OTP
                  loginController.phone = _phoneController.text;
                  loginController.sendOtp();
                } else {
                  // Verify OTP
                  loginController.smsOtp = _otpController.text;

                  loginController.verifyOTP();
                  // You might want to call a verify method here
                }
              },
              child: loginController.otpSent
                  ? Text('Verify OTP')
                  : Text('Send OTP'),
            ),
          ],
        ),
      ),
    );
  }
}
