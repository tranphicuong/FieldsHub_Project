import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

  bool _obscurePassword = true;
  bool _obscureRePassword = true;

  String? _otpSent;
  DateTime? _otpExpire;

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar("Vui lòng nhập email");
      return;
    }

    // generate OTP local
    final otp = _generateOtp();

    try {
      final response = await http.post(
        ApiService.sendOtp(),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      );

      final body = jsonDecode(response.body);

      if (response.statusCode == 200 && body['success'] == true) {
        setState(() {
          _otpSent = otp;
          _otpExpire = DateTime.now().add(const Duration(minutes: 5));
        });

        _showSnackBar("OTP đã gửi đến email");
      } else {
        _showSnackBar("Lỗi gửi OTP: ${body['error'] ?? 'Unknown'}");
      }
    } catch (e) {
      _showSnackBar("Lỗi kết nối: $e");
    }
  }

  String _generateOtp() {
    final rand = DateTime.now().millisecondsSinceEpoch.remainder(1000000);
    return rand.toString().padLeft(6, '0');
  }

  Future<void> _forgotpassword() async {
    final email = _emailController.text.trim();
    final newpassword = _newpasswordController.text.trim();
    final repassword = _repasswordController.text.trim();
    final otpInput = _otpController.text.trim();

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
      _showSnackBar("Mật khẩu phải đủ 6 ký tự");
      return;
    }
    if (_otpSent == null) {
      _showSnackBar("Vui lòng gửi OTP");
      return;
    }
    if (DateTime.now().isAfter(_otpExpire!)) {
      _showSnackBar("OTP hết hạn");
      return;
    }
    if (otpInput != _otpSent) {
      _showSnackBar("OTP không đúng");
      return;
    }

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
        _showSnackBar("Lỗi: ${result['error'] ?? result['message']}");
      }
    } catch (e) {
      _showSnackBar("Lỗi kết nối: $e");
    }
  }

  void _showSnackBar(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 50, left: 20, right: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: Stack(
        children: [
          // RESPONSIVE BACKGROUND CIRCLES
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;

              return Stack(
                children: [
                  // Top-left circle
                  Positioned(
                    top: -height * 0.15,
                    left: -width * 0.2,
                    child: _circle(width * 0.65),
                  ),
                  // Top-right circle
                  Positioned(
                    top: -height * 0.1,
                    left: width * 0.35,
                    child: _circle(width * 0.75),
                  ),
                  // Bottom-left circle
                  Positioned(
                    bottom: -height * 0.2,
                    left: -width * 0.25,
                    child: _circle(width * 0.6),
                  ),
                ],
              );
            },
          ),

          // MAIN CONTENT (giữ nguyên của bạn)
          SafeArea(
            child: SingleChildScrollView(
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
                      obscure: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.indigo,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                    _textfield(
                      controller: _repasswordController,
                      label: "Re-Password",
                      icon: Icons.lock_outline_sharp,
                      obscure: _obscureRePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureRePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.indigo,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureRePassword = !_obscureRePassword;
                          });
                        },
                      ),
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
    Widget? suffixIcon,
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
        suffixIcon: suffixIcon,
      ),
    );
  }
}
