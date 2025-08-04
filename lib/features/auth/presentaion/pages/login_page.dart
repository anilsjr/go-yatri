import 'package:flutter/material.dart';
import 'package:goyatri/features/auth/presentaion/controller/login_controller.dart';
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
    final LoginController _loginController = Provider.of<LoginController>(
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
            _loginController.otpSent
                ? TextField(
                    controller: _otpController,
                    decoration: InputDecoration(labelText: 'OTP'),
                  )
                : Container(),
            ElevatedButton(
              onPressed: () {
                if (!_loginController.otpSent) {
                  // Send OTP
                  _loginController.phone = _phoneController.text;
                  _loginController.sendOtp();
                } else {
                  // Verify OTP
                  _loginController.smsOtp = _otpController.text;

                  _loginController.verifyOTP();
                  // You might want to call a verify method here
                }
              },
              child: _loginController.otpSent
                  ? Text('Verify OTP')
                  : Text('Send OTP'),
            ),
          ],
        ),
      ),
    );
  }
}
