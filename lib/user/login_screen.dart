import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fieldshub/owner/main_screen.dart';
import 'package:fieldshub/user/forgot_password_screen.dart';
import 'package:fieldshub/user/main_user_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fieldshub/user/register_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool islogin = true;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

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
                vertical: 150,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 100),
                  //thanh tab giua login va register
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _tabButton("Login", islogin),
                      const SizedBox(width: 20),
                      _tabButton("Register", !islogin),
                    ],
                  ),
                  const SizedBox(height: 40),
                  //form hien thi cac thanh phan
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

  //widget login
  Widget _buildLoginForm() {
    return Column(
      key: const ValueKey('login'),
      children: [
        //nhap email
        _textfield(
          controller: _emailController,
          label: "Email",
          icon: Icons.email_outlined,
          hint: "abc123@gmail.com",
        ),
        const SizedBox(height: 40),
        //nhap pass
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ForgotPassword()),
              );
            },
            child: const Text(
              "Forgot Password",
              style: TextStyle(color: Colors.indigo, fontSize: 13),
            ),
          ),
        ),
        const SizedBox(height: 10),
        //nut login
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              String email = _emailController.text.trim();
              String password = _passwordController.text.trim();

              if (email.isEmpty || password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Vui lòng nhập đầy đủ email và mật khẩu!"),
                  ),
                );
                return;
              }
              try {
                final userCredential = await FirebaseAuth.instance
                    .signInWithEmailAndPassword(
                      email: email,
                      password: password,
                    );

                final uid = userCredential.user!.uid;

                //lay role
                final userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .get();

                if (!userDoc.exists) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Không tìm thấy thông tin người dùng"),
                    ),
                  );
                  return;
                }

                final rolePath = userDoc.data()?['role_id'];


                if (rolePath == null ||rolePath is String && rolePath.isEmpty || rolePath is! String && rolePath is! DocumentReference) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Người dùng chưa được gán vai trò"),
                    ),
                  );
                  return;
                }

                final DocumentReference roleRef = rolePath is DocumentReference ? rolePath : FirebaseFirestore.instance.doc(rolePath);
                final roleDoc = await roleRef.get();

                if(!roleDoc.exists){
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Không tìm thấy vai trò người dùng"),
                    ),
                  );
                  return;
                }

                final roleName = (roleDoc.data() as Map<String, dynamic>?)?['name'] ?? '';


                if (roleName == 'user') {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MainUserScreen(),
                    ),
                  );
                    }else if(roleName =='owner'){
                      Navigator.pushReplacement(context,
                   MaterialPageRoute(builder: (context) => const MainScreen()),);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Không xác định được vai trò người dùng"),
                    ),
                  );
                  return;
                }
              } on FirebaseAuthException catch (e) {
                String message = 'Đăng nhập thất bại';
                if (e.code == 'user-not-found') {
                  message = 'Tài khoản không tồn tại!';
                } else if (e.code == 'wrong-password') {
                  message = 'Mật khẩu không đúng';
                }
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(message)));
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

  //widget register
  Widget _buildRegisterForm() {
    return Column(
      key: const ValueKey('register'),
      children: [
        //nhap username
        _textfield(
          controller: _usernameController,
          label: "User name",
          icon: Icons.person_outline,
          hint: "abc123",
        ),
        const SizedBox(height: 15),
        //nhap phone
        _textfield(
          controller: _phoneController,
          label: "Phone",
          icon: Icons.phone_outlined,
          hint: "0123456789",
        ),
        const SizedBox(height: 15),
        //nhap email
        _textfield(
          controller: _emailController,
          label: "Email",
          icon: Icons.email_outlined,
          hint: "abc123@gmail.com",
        ),
        const SizedBox(height: 15),
        //nut register
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              String email = _emailController.text.trim();
              String username = _usernameController.text.trim();
              String phone = _phoneController.text.trim();

              if (email.isEmpty || username.isEmpty || phone.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Vui lòng nhập đẩy đủ thông tin")),
                );
                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RegisterPasswordScreen(
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

  //widget
  Widget _circle(double size) {
    return Container(
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
  }

  Widget _tabButton(String text, bool active) {
    return GestureDetector(
      onTap: () => setState(() => islogin = (text == "Login")),
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
