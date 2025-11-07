import 'package:flutter/material.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final int unreadNotificationsCount; // Thêm tham số để nhận số lượng thông báo chưa đọc

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.unreadNotificationsCount, // Yêu cầu tham số này
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 10,
          color: const Color(0xFFB7D8F9),
        ),
        BottomNavigationBar(
          currentIndex: currentIndex,
          backgroundColor: const Color(0xFF004A8E),
          selectedItemColor: Colors.white,
          unselectedItemColor: Colors.white70,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
          onTap: onTap,
          items: [
            const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
            const BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Đơn đặt'),
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications),
                  if (unreadNotificationsCount > 0) // Chỉ hiển thị badge nếu có thông báo chưa đọc
                    Positioned(
                      right: -6,
                      top: -4,
                      child: CircleAvatar(
                        radius: 8,
                        backgroundColor: Colors.red,
                        child: Text(
                          unreadNotificationsCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              label: 'Thông báo',
            ),
            const BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
            const BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Cài đặt'),
          ],
        ),
      ],
    );
  }
}