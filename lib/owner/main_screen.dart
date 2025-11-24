import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fieldshub/owner/DashboardScreen.dart';
import 'package:fieldshub/owner/OrderScreen.dart';
import 'package:fieldshub/notification/NotificationsScreen.dart';
import 'package:fieldshub/owner/Profilescreen.dart';
import 'package:fieldshub/owner/SettingScreen.dart';
import 'package:fieldshub/owner/bottom_nav_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late PageController _pageController;
  String? _userId;
  int _unreadNotificationsCount = 0;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
    _pageController = PageController(initialPage: _currentIndex);
    _listenToUnreadNotifications();

    if (_userId == null) {
      print("⚠️ Warning: No authenticated user found at ${DateTime.now()}");
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _listenToUnreadNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userId = user.uid;

    // 🔍 Kiểm tra Firestore của bạn lưu user_id dạng nào trước khi chọn dòng bên dưới
    FirebaseFirestore.instance
        .collection('notifications')
        //.where('user_id', isEqualTo: userId) // ✅ Nếu user_id = UID
         .where('user_id', isEqualTo: '/users/$userId') // ✅ Nếu user_id = "/users/<UID>"
        .where('is_read', isEqualTo: false)
        .snapshots()
        .listen(
      (snapshot) {
        print("📢 Unread notifications: ${snapshot.docs.length} | userId: $userId | ${DateFormat('HH:mm:ss').format(DateTime.now())}");
        setState(() {
          _unreadNotificationsCount = snapshot.docs.length;
        });
      },
      onError: (error) {
        print("❌ Error while listening to notifications for $userId: $error");
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dynamicScreens = [
      const DashboardScreen(),
      const OrdersMainScreen(),
      _userId != null
          ? NotificationsScreen(userId: _userId!)
          : const Center(child: CircularProgressIndicator()),
      const ProfileScreen(),
      const SettingScreen(),
    ];

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: dynamicScreens,
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        unreadNotificationsCount: _unreadNotificationsCount,
      ),
    );
  }
}
