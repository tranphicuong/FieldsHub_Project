import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fieldshub/user/user_home_screen.dart';
import 'package:fieldshub/user/search_screen.dart';
import 'package:fieldshub/notification/NotificationsScreen.dart';
import 'package:fieldshub/profile/Profilescreen.dart';
import 'package:fieldshub/user/booking_history_screen.dart';

class MainUserScreen extends StatefulWidget {
  const MainUserScreen({Key? key}) : super(key: key);

  @override
  State<MainUserScreen> createState() => _MainUserScreenState();
}

class _MainUserScreenState extends State<MainUserScreen> {
  int _selectedIndex = 0;
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    _screens = [
      const UserHomeScreen(),
      const SearchScreen(),
      NotificationsScreen(userId: _currentUser?.uid ?? ''),
      const ProfileScreen(),
      const BookingHistoryScreen(),
    ];
  }

  void _onTabSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabSelected,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue[800],
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Trang chủ"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Tìm kiếm"),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: "Thông báo",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Cá nhân"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "Lịch sử"),
        ],
      ),
    );
  }
}
