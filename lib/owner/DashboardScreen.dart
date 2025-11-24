import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fieldshub/owner/ChatListScreen.dart';
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
import 'package:cloud_firestore/cloud_firestore.dart';


class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? userName;
  String userAvatar = '';
  int _unreadMessagesCount = 0; // Đang hard-code, bạn sẽ làm realtime sau
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
      final data = userDoc.data();
      setState(() {
        userName = data?['name'] ?? 'Khách';
        userAvatar = data?['avatar'] ?? '';
      });
    } catch (e) {
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
        .listen((snapshot) {
      setState(() => _unreadNotificationsCount = snapshot.docs.length);
    });
  }

  // TỔNG SỐ SÂN HIỆN TẠI (KHÔNG PHẢI SÂN TẠO HÔM NAY)
  Stream<Map<String, int>> _getTotalFieldCounts() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.value({'Bóng Đá': 0, 'Bida': 0});

    return FirebaseFirestore.instance
        .collection('fields')
        .where('owner_id', isEqualTo: FirebaseFirestore.instance.doc('users/$userId'))
        .snapshots()
        .map((snapshot) {
      int footballCount = 0;
      int billiardCount = 0;

      for (var doc in snapshot.docs) {
        final sport = (doc['sport']?.toString() ?? '').toLowerCase();
        if (sport.contains('bóng') || sport.contains('football') || sport.contains('soccer')) {
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
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 22,
                backgroundImage: userAvatar.isNotEmpty
                    ? NetworkImage('$userAvatar?w=100,h=100,c_fill')
                    : null,
                child: userAvatar.isEmpty
                    ? const Icon(Icons.person, color: Colors.blue, size: 28)
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Xin chào,", style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text(
                  userName ?? "Đang tải...",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const Spacer(),
            // Chat
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChatListScreen()),
                    );
                  },
                ),
                if (_unreadMessagesCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        _unreadMessagesCount.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            // Notification
           
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Just for you", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),

            // 1. ĐÁNH GIÁ THÁNG HIỆN TẠI
            _buildMonthlyRatingCard(),
            const SizedBox(height: 20),

            // MENU NHANH
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMenuItem(Icons.bar_chart, "Doanh Thu", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RevenueReportScreen()))),
                _buildMenuItem(Icons.receipt_long, "Đơn Đặt", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersMainScreen()))),
                _buildMenuItem(Icons.list_alt, "Danh sách Sân", onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageFieldScreen()))),
                _buildMenuItem(Icons.star_rate, "Đánh Giá", onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DanhGiaCuaToiScreen(ownerUserId: FirebaseAuth.instance.currentUser!.uid),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 20),

            // 2. TỔNG SỐ SÂN HIỆN TẠI
            StreamBuilder<Map<String, int>>(
              stream: _getTotalFieldCounts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final footballCount = snapshot.data?['Bóng Đá'] ?? 0;
                final billiardCount = snapshot.data?['Bida'] ?? 0;

                return Column(
                  children: [
                    _buildFieldItem(
                      icon: Icons.sports_soccer,
                      title: "Sân Bóng",
                      location: "Toàn bộ sân bóng của bạn",
                      details: "Đang hoạt động",
                      sub: "$footballCount Sân",
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DanhSachSanScreen(initialFilter: 'BongDa'))),
                    ),
                    _buildFieldItem(
                      icon: Icons.sports_bar,
                      title: "Bàn Bida",
                      location: "Toàn bộ bàn bida của bạn",
                      details: "24/24",
                      sub: "$billiardCount Bàn",
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DanhSachSanScreen(initialFilter: 'BiDa'))),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),
            const Text("Dashboard", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 15),

            // 3. BIỂU ĐỒ DOANH THU
            _buildRevenueCharts(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  // ==================== PHẦN 1: ĐÁNH GIÁ THÁNG ====================
  // ==================== PHẦN 1: ĐÁNH GIÁ THÁNG (ĐÃ FIX HOÀN HẢO) ====================
Widget _buildMonthlyRatingCard() {
  final userId = FirebaseAuth.instance.currentUser?.uid;
  if (userId == null) {
    return _ratingCard("Đánh Giá Tháng Này", "Đăng nhập để xem", 0.0, 0);
  }

  final now = DateTime.now();
  final startOfMonth = DateTime(now.year, now.month, 1);

  // Dùng FutureBuilder + setState để tránh nhấp nháy
  return FutureBuilder<Map<String, dynamic>>(
    future: _fetchMonthlyRating(userId, startOfMonth),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return _ratingCard("Đánh Giá Tháng ${DateFormat('MM/yyyy').format(now)}", "Đang tải...", 0.0, 0);
      }

      if (!snapshot.hasData || snapshot.data!['count'] == 0) {
        return _ratingCard(
          "Đánh Giá Tháng ${DateFormat('MM/yyyy').format(now)}",
          "Chưa có đánh giá nào",
          0.0,
          0,
        );
      }

      final data = snapshot.data!;
      return _ratingCard(
        "Đánh Giá Tháng ${DateFormat('MM/yyyy').format(now)}",
        _getMotivationMessage(data['avg']),
        data['avg'],
        data['count'],
      );
    },
  );
}

// Hàm lấy đánh giá tháng (chạy 1 lần duy nhất, không nhấp nháy)
Future<Map<String, dynamic>> _fetchMonthlyRating(String userId, DateTime startOfMonth) async {
  try {
    final fieldSnapshot = await FirebaseFirestore.instance
        .collection('fields')
        .where('owner_id', whereIn: [userId, FirebaseFirestore.instance.doc('users/$userId')])
        .get();

    if (fieldSnapshot.docs.isEmpty) return {'avg': 0.0, 'count': 0};

    final fieldIds = fieldSnapshot.docs.map((e) => e.reference).toList();

    // Fallback nếu index chưa build
    try {
      final reviewSnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('field_id', whereIn: fieldIds)
          .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .orderBy('created_at', descending: true)  // Thêm orderBy để dùng index
          .get();

      if (reviewSnapshot.docs.isEmpty) return {'avg': 0.0, 'count': 0};

      double total = 0;
      for (var doc in reviewSnapshot.docs) {
        total += (doc['rating'] as num).toDouble();
      }

      return {
        'avg': total / reviewSnapshot.docs.length,
        'count': reviewSnapshot.docs.length,
      };
    } catch (e) {
      print('Index đang build, dùng fallback: $e');
      // Fallback: không filter created_at
      final reviewSnapshot = await FirebaseFirestore.instance
          .collection('reviews')
          .where('field_id', whereIn: fieldIds)
          .get();

      if (reviewSnapshot.docs.isEmpty) return {'avg': 0.0, 'count': 0};

      double total = 0;
      for (var doc in reviewSnapshot.docs) {
        total += (doc['rating'] as num).toDouble();
      }

      return {
        'avg': total / reviewSnapshot.docs.length,
        'count': reviewSnapshot.docs.length,
      };
    }
  } catch (e) {
    print('Lỗi lấy đánh giá: $e');
    return {'avg': 0.0, 'count': 0};
  }
}

  Widget _ratingCard(String title, String message, double avgRating, int reviewCount) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 3))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 5),
                Text(message, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 8),
                Row(children: _buildStarIcons(avgRating)),
                if (reviewCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text("$reviewCount đánh giá", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ),
              ],
            ),
          ),
          Column(
            children: [
              Text(avgRating > 0 ? avgRating.toStringAsFixed(1) : "-", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const Icon(Icons.star, color: Colors.amber, size: 32),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStarIcons(double rating) {
    return List.generate(5, (i) {
      if (i < rating.floor()) return const Icon(Icons.star, color: Colors.amber, size: 24);
      if (i < rating) return const Icon(Icons.star_half, color: Colors.amber, size: 24);
      return const Icon(Icons.star_border, color: Colors.amber, size: 24);
    });
  }

  String _getMotivationMessage(double rating) {
    if (rating >= 4.8) return "Xuất sắc! Giữ vững phong độ nhé!";
    if (rating >= 4.5) return "Rất tốt! Tiếp tục phát huy!";
    if (rating >= 4.0) return "Tốt! Cố gắng hơn nữa nhé!";
    if (rating >= 3.5) return "Khá ổn định, có thể cải thiện thêm!";
    return "Cần cải thiện chất lượng dịch vụ!";
  }

  // ==================== PHẦN 3: DOANH THU ====================
  Widget _buildRevenueCharts() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return const SizedBox();

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfDay = DateTime(now.year, now.month, now.day);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Expanded(child: _revenuePieChart("Tháng ${DateFormat('MM').format(now)}", startOfMonth, DateTime(now.year, now.month + 1, 1))),
        Expanded(child: _revenuePieChart("Hôm nay ${DateFormat('dd/MM').format(now)}", startOfDay, startOfDay.add(const Duration(days: 1)))),
      ],
    );
  }

  Widget _revenuePieChart(String title, DateTime start, DateTime end) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<Map<String, double>>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('owner_id', isEqualTo: FirebaseFirestore.instance.doc('users/$userId'))
          .where('status', isEqualTo: 'completed')
          .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .where('created_at', isLessThan: Timestamp.fromDate(end))
          .snapshots()
          .asyncMap((snapshot) async {
        double football = 0, billiard = 0;
        for (var doc in snapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final amount = (data['total_price'] as num?)?.toDouble() ?? 0;
          final fieldRef = data['field_id'] as DocumentReference?;
          if (fieldRef != null) {
            final fieldSnap = await fieldRef.get();
            if (fieldSnap.exists) {
              final sport = (fieldSnap['sport']?.toString() ?? '').toLowerCase();
              if (sport.contains('bóng') || sport.contains('football')) football += amount;
              else if (sport.contains('bida') || sport.contains('billiard')) billiard += amount;
            }
          }
        }
        return {'football': football, 'billiard': billiard};
      }),
      builder: (context, snapshot) {
        final data = snapshot.data ?? {'football': 0.0, 'billiard': 0.0};
        return _PieChart(title: title, football: data['football']!, billiard: data['billiard']!);
      },
    );
  }
 
 
  // ==================== CÁC WIDGET HỖ TRỢ ====================
  Widget _buildMenuItem(IconData icon, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 3)),
            ]),
            child: Icon(icon, color: Colors.blueAccent, size: 28),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
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
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 3))],
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.blueAccent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(location, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(details, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Column(
              children: [
                Text(sub, style: const TextStyle(fontWeight: FontWeight.bold)),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// BIỂU ĐỒ TRÒN
class _PieChart extends StatelessWidget {
  final String title;
  final double football;
  final double billiard;

  const _PieChart({required this.title, required this.football, required this.billiard});

  @override
  Widget build(BuildContext context) {
    final total = football + billiard;
    if (total == 0) {
      return Column(
        children: [
          SizedBox(width: 120, height: 120, child: PieChart(PieChartData(sections: [PieChartSectionData(value: 1, color: Colors.grey[300]!, title: '')]))),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const Text("0đ", style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      );
    }

    return Column(
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: PieChart(PieChartData(
            sectionsSpace: 2,
            sections: [
              PieChartSectionData(
                value: football,
                color: Colors.green,
                title: "${(football / total * 100).toStringAsFixed(0)}%",
                titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
              PieChartSectionData(
                value: billiard,
                color: Colors.orange,
                title: "${(billiard / total * 100).toStringAsFixed(0)}%",
                titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          )),
        ),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        Text(NumberFormat.currency(locale: 'vi', symbol: 'đ').format(total), style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}