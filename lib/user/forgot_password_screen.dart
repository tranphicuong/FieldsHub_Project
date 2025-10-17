import 'package:fieldshub/user/login_screen.dart';
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: Stack(
        children: [
          //hinh tron cua nen
         Positioned(top: -100, left: -30, child: _circle(235)),
          Positioned(top: -50, left: 170, child: _circle(280)),
          Positioned(bottom: -120, left: -60, child: _circle(220)),
          //noi dung
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
                  const SizedBox(height: 0.5),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () {},
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
                  //nut submit
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                        );
                      },
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
