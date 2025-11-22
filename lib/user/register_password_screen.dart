import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fieldshub/user/comfirm_role_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fieldshub/Database/email_sevice.dart';

class RegisterPasswordScreen extends StatefulWidget {
  final String email;
  final String username;
  final String phone;

  const RegisterPasswordScreen({
    super.key,
    required this.email,
    required this.username,
    required this.phone,
  });

  @override
  State<RegisterPasswordScreen> createState() => _RegisterPasswordScreen();
}

class _RegisterPasswordScreen extends State<RegisterPasswordScreen> {
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _repasswordController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? _otpSent;
  DateTime? _otpExpire;
  bool _obscurePassword = true;
  bool _obscureRePassword = true;
  //gui ma otp

  Future<void> _sendOtp() async {
    try {
      final otp = EmailService.generateOtp();
      await EmailService.sendOtpEmail(receiverEmail: widget.email, otp: otp);
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

  // dang ky tai khoan
  Future<void> _registerAccount() async {
    final email = widget.email;
    final password = _passwordController.text.trim();
    final username = widget.username;
    final phone = widget.phone;
    final otpInput = _otpController.text.trim();

    if (password != _repasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Mật khẩu nhập lại không khớp"),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 50, left: 20, right: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(" Mật khẩu phải có ít nhất 6 ký tự"),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 50, left: 20, right: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    if (_otpSent == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Vui lòng gửi mã OTP"),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 50, left: 20, right: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    if (DateTime.now().isAfter(_otpExpire!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Mã OTP đã hết hạn"),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 50, left: 20, right: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    if (otpInput != _otpSent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Mã OTP không chính xác"),
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
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': username,
        'phone': phone,
        'email': email,
        'address': '',
        'avatar': '',
        'dob': null,
        'gender': '',
        'role_id': '/roles/3',
      });

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ConfirmRoleScreen()),
      );
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Loi: ${e.message}"),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 50, left: 20, right: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE3F2FD),
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
                  vertical: 150,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 100),
                    const Text(
                      "Password-Recode",
                      style: TextStyle(
                        fontSize: 25,
                        color: Color.fromARGB(255, 23, 3, 249),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _textfield(
                      controller: _passwordController,
                      label: "Password",
                      icon: Icons.lock_outline,
                      obscure: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
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
                      icon: Icons.lock_outline,
                      obscure: _obscureRePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                          color: Colors.indigo,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureRePassword = !_obscureRePassword;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 0.5),
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
                    const SizedBox(height: 8),
                    _textfield(
                      controller: _otpController,
                      label: "OTP",
                      icon: Icons.mark_email_unread_outlined,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _registerAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          "Register",
                          style: TextStyle(fontSize: 13, color: Colors.white),
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

  //widget
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

  //widget textfield
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
