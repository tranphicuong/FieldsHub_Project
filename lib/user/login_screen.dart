import 'package:fieldshub/Database/database.dart';
import 'package:fieldshub/owner/main_screen.dart';
import 'package:fieldshub/user/forgot_password_screen.dart';
import 'package:fieldshub/user/main_user_screen.dart';
import 'package:fieldshub/user/register_password_screen.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool islogin = true;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
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
                vertical: 150,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 100),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _tabButton("Login", islogin),
                      const SizedBox(width: 20),
                      _tabButton("Register", !islogin),
                    ],
                  ),
                  const SizedBox(height: 40),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: islogin ? _buildLoginForm() : _buildRegisterForm(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  //  LOGIN FORM
  Widget _buildLoginForm() {
    return Column(
      key: const ValueKey('login'),
      children: [
        _textfield(
          controller: _emailController,
          label: "Email",
          icon: Icons.email_outlined,
          hint: "abc123@gmail.com",
        ),
        const SizedBox(height: 40),
        _textfield(
          controller: _passwordController,
          label: "Password",
          icon: Icons.lock_outlined,
          obscure: true,
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ForgotPassword()),
            ),
            child: const Text(
              "Forgot Password",
              style: TextStyle(color: Colors.indigo, fontSize: 13),
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              final email = _emailController.text.trim();
              final password = _passwordController.text.trim();
              if (email.isEmpty || password.isEmpty) {
                _showSnackBar("Vui lòng nhập đầy đủ!");
                return;
              }

              try {
                final result = await Database.loginUser(
                  email: email,
                  password: password,
                );
                if (result == null) {
                  _showSnackBar("Không tìm thấy người dùng hoặc vai trò");
                  return;
                }

                if (result['role'] == 'user') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const MainUserScreen()),
                  );
                } else if (result['role'] == 'owner') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const MainScreen()),
                  );
                }
              } catch (e) {
                _showSnackBar(e.toString());
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text(
              "Login",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  //REGISTER FORM
  Widget _buildRegisterForm() {
    return Column(
      key: const ValueKey('register'),
      children: [
        _textfield(
          controller: _usernameController,
          label: "User name",
          icon: Icons.person_outline,
          hint: "abc123",
        ),
        const SizedBox(height: 15),
        _textfield(
          controller: _phoneController,
          label: "Phone",
          icon: Icons.phone_outlined,
          hint: "0123456789",
        ),
        const SizedBox(height: 15),
        _textfield(
          controller: _emailController,
          label: "Email",
          icon: Icons.email_outlined,
          hint: "abc123@gmail.com",
        ),
        const SizedBox(height: 15),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              final email = _emailController.text.trim();
              final username = _usernameController.text.trim();
              final phone = _phoneController.text.trim();
              if (email.isEmpty || username.isEmpty || phone.isEmpty) {
                _showSnackBar("Vui lòng nhập đầy đủ thông tin");
                return;
              }
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => RegisterPasswordScreen(
                    email: email,
                    username: username,
                    phone: phone,
                  ),
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
              "Register",
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  //  WIDGETS
  Widget _circle(double size) => Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
      color: Color(0xFF1565C0),
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(4, 4)),
      ],
    ),
  );

  Widget _tabButton(String text, bool active) => GestureDetector(
    onTap: () => setState(() => islogin = text == "Login"),
    child: Column(
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 18,
            color: active
                ? const Color.fromARGB(255, 181, 63, 63)
                : Colors.black54,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        if (active)
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 50,
            height: 2,
            color: const Color.fromARGB(255, 181, 63, 63),
          ),
      ],
    ),
  );

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
