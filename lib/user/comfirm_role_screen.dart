import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fieldshub/owner/VerificationScreen.dart';
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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _saveRole() async {
    if (selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn vai trò")),
      );
      return;
    }

    try {
      final user = _auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Không tìm thấy tài khoản")),
        );
        return;
      }

      // gan role theo nguoi dung chon
      String roleId = selectedRole == "user" ? "/roles/1" : "/roles/2";

      // cap nhat len firestore
      await _firestore.collection('users').doc(user.uid).update({
        'role_id': roleId,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cập nhật vai trò thành công")),
      );

     
       if (selectedRole == "user") {
         Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => VerificationScreen()));
       }

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e")),
      );
    }
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 100),
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
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black87,
                          fontWeight: FontWeight.w400,
                        ),
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
                        title: const Text("Người dùng (đặt dịch vụ / tiêu dùng)"),
                        value: "user",
                        groupValue: selectedRole,
                        onChanged: (value) => setState(() => selectedRole = value),
                      ),
                      RadioListTile<String>(
                        title: const Text("Doanh nghiệp (cung cấp dịch vụ / cho thuê)"),
                        value: "owner",
                        groupValue: selectedRole,
                        onChanged: (value) => setState(() => selectedRole = value),
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
                                horizontal: 40, vertical: 12),
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
                    padding: const EdgeInsets.only(bottom: 20),
                    child: RichText(
                      text: const TextSpan(
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
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(4, 4)),
        ],
      ),
    );
  }
}
