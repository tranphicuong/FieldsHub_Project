import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fieldshub/owner/FieldListScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart'; 
import 'package:fieldshub/user/chat_screen.dart';
import 'package:fieldshub/owner/ManageFieldScreen.dart';
import 'package:fieldshub/owner/OrderScreen.dart';
import 'package:fieldshub/owner/RevenueReportScreen.dart';
import 'package:fieldshub/owner/ReviewScreen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? userName;
  int _unreadMessagesCount = 3;
  int _unreadNotificationsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _listenToUnreadNotifications();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => userName = 'Khách');
      return;
    }
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      setState(() => userName = userDoc.data()?['name'] ?? 'Khách');
    } catch (e) {
      print("Error loading user data: $e");
      setState(() => userName = 'Khách');
    }
  }

  void _listenToUnreadNotifications() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    FirebaseFirestore.instance
        .collection('notifications')
        .where('user_id', isEqualTo: '/users/${user.uid}')
        .where('is_read', isEqualTo: false)
        .snapshots()
        .listen(
      (snapshot) {
        print("Số lượng thông báo chưa đọc: ${snapshot.docs.length} - Time: ${DateFormat('HH:mm:ss').format(DateTime.now())}");
        setState(() => _unreadNotificationsCount = snapshot.docs.length);
      },
      onError: (error) => print("Lỗi truy vấn thông báo: $error"),
    );
  }

  Stream<Map<String, int>> _getFieldCounts() {
  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  return FirebaseFirestore.instance
      .collection('fields')
      .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
      .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
      .snapshots()
      .map((snapshot) {
    int footballCount = 0;
    int billiardCount = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final sport = (data['sport'] ?? '').toString().toLowerCase();

      if (sport.contains('bong') || sport.contains('football') || sport.contains('soccer')) {
        footballCount++;
      } else if (sport.contains('bida') || sport.contains('billiard') || sport.contains('pool')) {
        billiardCount++;
      }
    }

    return {'Bóng Đá': footballCount, 'Bida': billiardCount};
  });
}




  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      backgroundColor: const Color(0xFFE8F3FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF004A8E),
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.black),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "xin chào",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  userName ?? "Nguyen Van A",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                  tooltip: "Chat",
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          fieldId: '',
                          fieldName: 'Tên sân mặc định',
                        ),
                      ),
                    );
                  },
                ),
                if (_unreadMessagesCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        _unreadMessagesCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            Stack(
              children: [
                if (_unreadNotificationsCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        _unreadNotificationsCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Just for you",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Đánh Giá Tháng 10",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "Tiếp tục giữ vững phong độ bạn nhé!",
                          style: TextStyle(fontSize: 13),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber),
                            Icon(Icons.star, color: Colors.amber),
                            Icon(Icons.star, color: Colors.amber),
                            Icon(Icons.star, color: Colors.amber),
                            Icon(Icons.star_half, color: Colors.amber),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Column(
                    children: [
                      Text(
                        "4.8",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(Icons.star, color: Colors.amber, size: 32),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMenuItem(
                  Icons.bar_chart,
                  "Doanh Thu",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RevenueReportScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  Icons.receipt_long,
                  "Đơn Đặt",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OrdersMainScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  Icons.list_alt,
                  "Danh sách Sân",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>  ManageFieldScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  Icons.star_rate,
                  "Đánh Giá",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DanhGiaCuaToiScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
                        StreamBuilder<Map<String, int>>(
              stream: _getFieldCounts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData) {
                  return const Center(child: Text("Không có dữ liệu sân hoặc lỗi kết nối"));
                }

                final fieldCounts = snapshot.data!;
                final footballCount = fieldCounts['Bóng Đá'] ?? 0;
                final billiardCount = fieldCounts['Bida'] ?? 0;
              
                return Column(
                  children: [
                    _buildFieldItem(
                      icon: Icons.sports_soccer,
                      title: "Sân Bóng",
                      location: "702, Nguyễn Giáp, Hiệp Phú, Thủ Đức",
                      details: "5:00 - 23:00",
                      sub: "$footballCount Sân",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DanhSachSanScreen(
                              initialFilter: 'Bóng Đá', 
                            ),
                          ),
                        );
                      },
                    ),
                    _buildFieldItem(
                      icon: Icons.sports_bar,
                      title: "Bàn Bida",
                      location: "702, Nguyễn Giáp, Hiệp Phú, Thủ Đức",
                      details: "24/24",
                      sub: "$billiardCount Bàn",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DanhSachSanScreen(
                              initialFilter: 'Bida', 
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 15),
            const Text(
              "Dashboard",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 15),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _PieChart(title: "Doanh Thu Tháng 10"),
                _PieChart(title: "Doanh Thu Ngày 22/10"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.blueAccent, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  static Widget _buildFieldItem({
    required IconData icon,
    required String title,
    required String location,
    required String details,
    required String sub,
     required VoidCallback onTap, 
  }) {
   return InkWell(
    onTap: onTap, 
    borderRadius: BorderRadius.circular(12),
    child: Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 40, color: Colors.blueAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  location,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  details,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                sub,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 3),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ],
      ),
    ),
   );
  }
}

class _PieChart extends StatelessWidget {
  final String title;
  const _PieChart({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(value: 40, color: Colors.red, title: ''),
                PieChartSectionData(value: 30, color: Colors.blue, title: ''),
                PieChartSectionData(value: 30, color: Colors.grey, title: ''),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }
}