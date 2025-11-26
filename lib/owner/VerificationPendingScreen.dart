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

  Widget _buildLoading() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF78A9D6), Color(0xFFD6ECFF)],
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 3,
        ),
      ),
    );
  }

  Widget _buildPending(String msg) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 360;
    final isMediumScreen = size.width < 600;
    
    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        color: const Color(0xFFD6ECFF),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Top curved decoration
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: size.height * 0.18,
                decoration: const BoxDecoration(
                  color: Color(0xFF6B9AC4),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(200),
                    bottomRight: Radius.circular(200),
                  ),
                ),
              ),
            ),

            // Bottom left large circle
            Positioned(
              bottom: 0,
              left: -80,
              child: Container(
                height: 260,
                width: 260,
                decoration: const BoxDecoration(
                  color: Color(0xFF0D5C89),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 95,
                    top: 110,
                  ),
                  child: Text(
                    'Thể thao là\nđam mê.',
                    style: TextStyle(
                      color: const Color(0xFFF46A6A),
                      fontSize: isSmallScreen ? 22 : isMediumScreen ? 26 : 30,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ),

            // Bottom right circle
            Positioned(
              bottom: 30,
              right: 20,
              child: Container(
                height: isSmallScreen ? 110 : 140,
                width: isSmallScreen ? 110 : 140,
                decoration: const BoxDecoration(
                  color: Color(0xFF0D5C89),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'sân chơi\nlà cuộc\nsống.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 14 : isMediumScreen ? 16 : 18,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Top section with title
                  SizedBox(height: size.height * 0.04),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: Column(
                      children: [
                        Text(
                          'Chào mừng bạn đến với',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 15 : 17,
                            color: Colors.white,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'FieldHub',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 28 : isMediumScreen ? 32 : 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Middle section with message
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              msg,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: isSmallScreen ? 14 : isMediumScreen ? 15 : 16,
                                color: const Color(0xFF0D5C89),
                                height: 1.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 30),
                            const CircularProgressIndicator(
                              color: Color(0xFF0D5C89),
                              strokeWidth: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Bottom spacing
                  SizedBox(height: size.height * 0.12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApproved() {
    return _buildPending(
      "Chúc mừng! Hồ sơ đã được duyệt!\nĐang chuyển về trang đăng nhập...",
    );
  }
}