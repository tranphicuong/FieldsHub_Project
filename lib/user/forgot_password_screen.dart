import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fieldshub/Database/email_sevice.dart';
import 'package:fieldshub/user/login_screen.dart';
import 'package:fieldshub/Database/api_service.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _newpasswordController = TextEditingController();
  final TextEditingController _repasswordController = TextEditingController();

  String? _otpSent;
  DateTime? _otpExpire;

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Vui lòng nhập email"),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 50, left: 20, right: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    try {
      final otp = EmailService.generateOtp();
      await EmailService.sendOtpEmail(receiverEmail: email, otp: otp);

      setState(() {
        _otpSent = otp;
        _otpExpire = DateTime.now().add(const Duration(minutes: 5));
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Mã OTP đã được gửi đến email"),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 50, left: 20, right: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gửi OTP thất bại: $e"),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 50, left: 20, right: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _forgotpassword() async {
    final email = _emailController.text.trim();
    final newpassword = _newpasswordController.text.trim();
    final repassword = _repasswordController.text.trim();
    final otpInput = _otpController.text.trim();

    // --- VALIDATION ---
    if (email.isEmpty ||
        newpassword.isEmpty ||
        repassword.isEmpty ||
        otpInput.isEmpty) {
      _showSnackBar("Vui lòng nhập đầy đủ thông tin");
      return;
    }
    if (newpassword != repassword) {
      _showSnackBar("Mật khẩu nhập lại không khớp");
      return;
    }
    if (newpassword.length < 6) {
      _showSnackBar("Mật khẩu phải có ít nhất 6 ký tự");
      return;
    }
    if (_otpSent == null) {
      _showSnackBar("Vui lòng gửi mã OTP");
      return;
    }
    if (DateTime.now().isAfter(_otpExpire!)) {
      _showSnackBar("Mã OTP đã hết hạn");
      return;
    }
    if (otpInput != _otpSent) {
      _showSnackBar("Mã OTP không chính xác");
      return;
    }

    // --- GỌI API RESET PASSWORD ---
    try {
      final response = await http.post(
        ApiService.resetPassword(),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'newPassword': newpassword}),
      );

      final result = jsonDecode(response.body);

      if (response.statusCode == 200 && result['success'] == true) {
        _showSnackBar("Đổi mật khẩu thành công");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        _showSnackBar(
          "Lỗi: ${result['error'] ?? result['message'] ?? 'Unknown'}",
        );
      }
    } catch (e) {
      _showSnackBar("Lỗi kết nối: $e");
    }
  }

  // Helper để tránh lặp code SnackBar
  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 50, left: 20, right: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: Stack(
        children: [
          Positioned(top: -100, left: -30, child: _circle(235)),
          Positioned(top: -50, left: 170, child: _circle(280)),
          Positioned(bottom: -120, left: -60, child: _circle(220)),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 30,
                vertical: 110,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 100),
                  const Text(
                    "Forgot Password",
                    style: TextStyle(
                      fontSize: 25,
                      color: Color.fromARGB(255, 3, 38, 239),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _textfield(
                    controller: _emailController,
                    label: "Email",
                    icon: Icons.email_outlined,
                    hint: "abc123@gmail.com",
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _sendOtp,
                      child: const Text(
                        "Send Confirmation Code Via Email",
                        style: TextStyle(
                          color: Colors.indigo,
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                  _textfield(
                    controller: _otpController,
                    label: "OTP",
                    icon: Icons.mark_email_unread_sharp,
                  ),
                  const SizedBox(height: 10),
                  _textfield(
                    controller: _newpasswordController,
                    label: "New Password",
                    icon: Icons.lock_outline,
                    obscure: true,
                  ),
                  const SizedBox(height: 10),
                  _textfield(
                    controller: _repasswordController,
                    label: "Re-Password",
                    icon: Icons.lock_outline_sharp,
                    obscure: true,
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _forgotpassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        "Submit",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF1565C0),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black, blurRadius: 8, offset: Offset(4, 4)),
        ],
      ),
    );
  }

  Widget _textfield({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.indigo),
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
