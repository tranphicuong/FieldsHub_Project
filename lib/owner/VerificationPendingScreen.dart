import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VerificationPendingScreen extends StatelessWidget {
  const VerificationPendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Trường hợp cực hiếm: user bị logout giữa chừng
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      });
      return const SizedBox.shrink();
    }

    final userRef = FirebaseFirestore.instance.doc('users/${user.uid}');

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>?>(
  stream: FirebaseFirestore.instance
      .collection('owner_documents')
      .where('user_id', isEqualTo: userRef)
      .orderBy('created_at', descending: true)
      .limit(1)
      .snapshots()
      .map<DocumentSnapshot<Map<String, dynamic>>?>(
    (querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first;
      }
      return null;
    },
  ),
        builder: (context, snapshot) {
          // Đang loading lần đầu
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingUI();
          }

          // Không có hồ sơ nào (chưa nộp)
          if (!snapshot.hasData || snapshot.data == null) {
            return _buildPendingUI("Hồ sơ của bạn đang được xét duyệt.\nBạn sẽ sớm được sử dụng đầy đủ tính năng!");
          }

          final doc = snapshot.data!;
          final statusRef = doc['status_id'] as DocumentReference?;

          // Debug (có thể bỏ khi release)
          print("Status path: ${statusRef?.path ?? 'null'}");

          // ĐÃ DUYỆT → chuyển ngay sang Dashboard
          if (statusRef?.path == 'status/5') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                print("ĐÃ DUYỆT → Chuyển đến Login");
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
              }
            });
            // Vẫn hiển thị UI chờ một chút để tránh flash
            return _buildApprovedUI();
          }

          // Bị từ chối hoặc trạng thái khác (tùy bạn có muốn xử lý riêng không)
          if (statusRef?.path == 'status/6') { // ví dụ: 6 = rejected
            return _buildRejectedUI();
          }

          // Các trạng thái khác: đang duyệt, chờ bổ sung,...
          return _buildPendingUI("Hồ sơ của bạn đang được xét duyệt.\nBạn sẽ sớm được sử dụng đầy đủ tính năng!");
        },
      ),
    );
  }

  // UI khi đang load
  Widget _buildLoadingUI() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF004A8E), Color(0xFF0077CC)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }

  // UI chờ duyệt (chính)
  Widget _buildPendingUI(String message) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF004A8E), Color(0xFF0077CC)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo bóng đá
          CircleAvatar(
            radius: 70,
            backgroundColor: Colors.white,
            child: Icon(Icons.sports_soccer, size: 90, color: const Color(0xFF004A8E)),
          ),
          const SizedBox(height: 50),

          // Tiêu đề
          const Text(
            'Chào mừng bạn đến với',
            style: TextStyle(fontSize: 26, color: Colors.white70),
          ),
          const Text(
            'FieldHub',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 40),

          // Nội dung thông báo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, color: Colors.white, height: 1.5),
            ),
          ),
          const SizedBox(height: 30),

          // Hiệu ứng nhẹ nhàng
          const Text(
            'Vui lòng chờ trong giây lát...',
            style: TextStyle(fontSize: 14, color: Colors.white60),
          ),
        ],
      ),
    );
  }

  // UI khi đã được duyệt (hiện thoáng qua trước khi chuyển màn hình)
  Widget _buildApprovedUI() {
    return _buildPendingUI("Đã duyệt thành công! Đang chuyển đến trang chủ...");
  }

  // UI khi bị từ chối (tùy chọn mở rộng sau)
  Widget _buildRejectedUI() {
    return _buildPendingUI("Hồ sơ của bạn bị từ chối.\nVui lòng kiểm tra lại thông tin và nộp lại.");
  }
}