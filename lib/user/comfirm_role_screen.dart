import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fieldshub/Database/database.dart';
import 'package:fieldshub/owner/field_owner_registration_screen.dart';
import 'package:fieldshub/user/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ConfirmRoleScreen extends StatefulWidget {
  const ConfirmRoleScreen({super.key});
  @override
  State<ConfirmRoleScreen> createState() => _ConfirmRoleScreenState();
}

class _ConfirmRoleScreenState extends State<ConfirmRoleScreen> {
  String? selectedRole;

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _saveRole() async {
    if (selectedRole == null) return _showSnackBar("Vui lòng chọn vai trò");

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return _showSnackBar("Không tìm thấy tài khoản");

    final roleRef = FirebaseFirestore.instance.doc(
      selectedRole == "user" ? '/roles/1' : '/roles/2',
    );

    try {
      await Database.updateUserRole(uid: user.uid, roleRef: roleRef);
      _showSnackBar("Cập nhật vai trò thành công");

      if (selectedRole == "user") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const FieldOwnerRegistrationScreen(),
          ),
        );
      }
    } catch (e) {
      _showSnackBar(e.toString());
    }
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

          // MAIN CONTENT
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 30,
                vertical: 100,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 60),
                      const Text(
                        "Chào mừng bạn đến với",
                        style: TextStyle(fontSize: 18, color: Colors.black87),
                      ),
                      const Text(
                        "FieldHub",
                        style: TextStyle(
                          fontSize: 28,
                          color: Colors.indigo,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        "Bạn muốn sử dụng FieldHub với vai trò nào?",
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                      const SizedBox(height: 15),
                      RadioListTile<String>(
                        title: const Text(
                          "Người dùng (đặt dịch vụ / tiêu dùng)",
                        ),
                        value: "user",
                        groupValue: selectedRole,
                        onChanged: (v) => setState(() => selectedRole = v),
                      ),
                      RadioListTile<String>(
                        title: const Text(
                          "Doanh nghiệp (cung cấp dịch vụ / cho thuê)",
                        ),
                        value: "owner",
                        groupValue: selectedRole,
                        onChanged: (v) => setState(() => selectedRole = v),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: _saveRole,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            "Submit",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 20),
                    child: RichText(
                      textAlign: TextAlign.center, // CĂN GIỮA
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "Thể thao là đam mê.\n",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 220, 75, 60),
                            ),
                          ),
                          TextSpan(
                            text: "Sân chơi là cuộc sống.",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.indigo,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ); // ĐÓNG Scaffold & return
  }

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
}
