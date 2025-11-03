import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      selectedItemColor: Colors.blue[800],
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Trang chủ"),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: "Tìm kiếm"),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications_none),
          label: "Thông báo",
        ),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Tài khoản"),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: "Lịch sử đặt sân",
        ),
      ],
    );
  }
}
