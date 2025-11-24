import 'package:cloud_firestore/cloud_firestore.dart';
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
  bool _obscurePassword = true;

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
          // Background circles - responsive
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

          // Nội dung chính
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
              String email = _emailController.text.trim();
              if (!email.contains('@')) {
                email = '$email@gmail.com';
              }
              final password = _passwordController.text.trim();

              if (email.isEmpty || password.isEmpty) {
                _showSnackBar("Vui lòng nhập đầy đủ thông tin!");
                return;
              }

              try {
                final result = await Database.loginUser(
                  email: email,
                  password: password,
                );
                if (result == null) {
                  _showSnackBar("Email hoặc mật khẩu không đúng!");
                  return;
                }

                final String uid = result['uid'];
                final String role = result['role'] ?? 'user';

                
                final lockSnapshot = await FirebaseFirestore.instance
                    .collection('lockAccount')
                    .where(
                      'user_id',
                      isEqualTo: FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid),
                    )
                    .where('isComplete', isEqualTo: true)
                    .limit(1)
                    .get();

                if (lockSnapshot.docs.isNotEmpty) {
                  final lockData = lockSnapshot.docs.first.data();

                  final Timestamp? startTs =
                      lockData['start_time'] as Timestamp?;
                  final Timestamp? endTs = lockData['end_time'] as Timestamp?;
                  final String reason = lockData['content'] ?? 'Không có lý do';

                  final String startDate = startTs != null
                      ? '${startTs.toDate().day}/${startTs.toDate().month}/${startTs.toDate().year} ${startTs.toDate().hour}:${startTs.toDate().minute.toString().padLeft(2, '0')}'
                      : 'Không xác định';
                  final String endDate = endTs != null
                      ? '${endTs.toDate().day}/${endTs.toDate().month}/${endTs.toDate().year} ${endTs.toDate().hour}:${endTs.toDate().minute.toString().padLeft(2, '0')}'
                      : 'Vô thời hạn';

                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Row(
                        children: [
                          Icon(Icons.lock_outline, color: Colors.red, size: 28),
                          SizedBox(width: 10),
                          Text(
                            "Tài khoản bị khóa",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Tài khoản của bạn đã bị tạm khóa do vi phạm quy định.",
                            style: TextStyle(fontSize: 15),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "• Thời gian khóa:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text("  Từ: $startDate"),
                          Text("  Đến: $endDate"),
                          const SizedBox(height: 12),
                          Text(
                            "• Lý do:",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text("  $reason"),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text(
                            "Đóng",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                  return;  
                }

                
                if (role == 'owner') {
                  final ownerDocSnap = await FirebaseFirestore.instance
                      .collection('owner_documents')
                      .where(
                        'user_id',
                        isEqualTo: FirebaseFirestore.instance
                            .collection('users')
                            .doc(uid),
                      )
                      .limit(1)
                      .get();

                  if (ownerDocSnap.docs.isEmpty) {
                    _showSnackBar(
                      "Không tìm thấy hồ sơ chủ sân. Vui lòng liên hệ Admin.",
                    );
                    return;
                  }

                  final ownerData = ownerDocSnap.docs.first.data();
                  final DocumentReference? statusRef =
                      ownerData['status_id'] as DocumentReference?;

                  if (statusRef?.id != '5') {
                    _showSnackBar(
                      "Tài khoản chủ sân của bạn chưa được duyệt! Vui lòng chờ Admin phê duyệt.",
                    );
                    return;
                  }

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const MainScreen()),
                  );
                } else if (role == 'user') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const MainUserScreen()),
                  );
                }
              } catch (e) {
                _showSnackBar("Lỗi kết nối: ${e.toString()}");
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
