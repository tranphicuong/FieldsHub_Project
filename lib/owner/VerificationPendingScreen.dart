import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fieldshub/user/login_screen.dart';

class VerificationPendingScreen extends StatefulWidget {
  const VerificationPendingScreen({super.key});

  @override
  State<VerificationPendingScreen> createState() => _VerificationPendingScreenState();
}

class _VerificationPendingScreenState extends State<VerificationPendingScreen> {
  bool _hasNavigated = false;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      });
      return const SizedBox.shrink();
    }

    final userRef = FirebaseFirestore.instance.doc('users/${user.uid}');

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('owner_documents')
            .where('user_id', isEqualTo: userRef)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoading();
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildPending("Bạn chưa nộp hồ sơ chủ sân.");
          }

          final hasApproved = snapshot.data!.docs.any((doc) {
            final statusRef = doc['status_id'] as DocumentReference?;
            return statusRef != null && statusRef.id == '5';
          });

          if (hasApproved && !_hasNavigated) {
            print("ĐÃ TÌM THẤY HỒ SƠ status/5 → TỰ ĐỘNG VỀ LOGIN!");
            _hasNavigated = true;
            _navigateToLogin();
            return _buildApproved();
          }

          return _buildPending(
            "Hồ sơ chủ sân của bạn đang được xét duyệt.\nVui lòng chờ Admin phê duyệt.",
          );
        },
      ),
    );
  }

  // Hàm điều hướng về login khi duyệt xong
  void _navigateToLogin() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      await FirebaseAuth.instance.signOut();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Chúc mừng! Hồ sơ đã được duyệt thành công!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    });
  }

  // Màn loading ban đầu
  Widget _buildLoading() => Stack(
        children: [
          Container(color: const Color(0xFFD6ECFF)),
          const Center(child: CircularProgressIndicator(color: Colors.blue)),
        ],
      );

  // Màn đang chờ duyệt
  Widget _buildPending(String msg) {
    return Stack(
      children: [
        // Nền nhạt
        Container(color: const Color(0xFFD6ECFF)),

        // Vùng cong trên
        Positioned(
          top: -120,
          left: -50,
          right: -50,
          child: Container(
            height: 260,
            decoration: const BoxDecoration(
              color: Color(0xFF78A9D6),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(200),
                bottomRight: Radius.circular(200),
              ),
            ),
          ),
        ),

        // Vùng tròn to dưới trái
        Positioned(
          bottom: -100,
          left: -60,
          child: Container(
            height: 260,
            width: 260,
            decoration: const BoxDecoration(
              color: Color(0xFF0D5C89),
              shape: BoxShape.circle,
            ),
            child: const Padding(
              padding: EdgeInsets.only(left: 25, top: 110),
              child: Text(
                'Thể thao là\nđam mê.',
                style: TextStyle(
                  color: Color(0xFFF46A6A),
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),

        // Vùng tròn nhỏ dưới phải
        Positioned(
          bottom: 10,
          right: 20,
          child: Container(
            height: 130,
            width: 130,
            decoration: const BoxDecoration(
              color: Color(0xFF095E85),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                'sân chơi\nlà cuộc\nsống.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ),

        // Nội dung chính
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 60),
                const Text(
                  'Chào mừng bạn đến với',
                  style: TextStyle(fontSize: 20, color: Colors.white70),
                ),
                const SizedBox(height: 5),
                const Text(
                  'FieldHub',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 50),
                Text(
                  msg,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF004A8E),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 40),
                const CircularProgressIndicator(color: Colors.blue),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Màn đã được duyệt
  Widget _buildApproved() =>
      _buildPending("Chúc mừng! Hồ sơ đã được duyệt!\nĐang chuyển về trang đăng nhập...");
}
