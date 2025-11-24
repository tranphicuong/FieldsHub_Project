import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fieldshub/owner/ChatListScreen.dart';
import 'package:fieldshub/owner/ManageFieldScreen.dart';
import 'package:fieldshub/owner/OrderScreen.dart';
import 'package:fieldshub/owner/RevenueReportScreen.dart';
import 'package:fieldshub/owner/ReviewScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:fieldshub/owner/FieldListScreen.dart'; // DanhSachSanScreen

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? userName;
  String userAvatar = '';
  int _unreadMessagesCount = 0;
  int _unreadNotificationsCount = 0;

  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'vi', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _listenToUnreadNotifications();
    _listenToUnreadMessages();
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

  void _listenToUnreadMessages() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    FirebaseFirestore.instance
        .collection('conversations')
        .where('users', arrayContains: user.uid)
        .snapshots()
        .listen((snapshot) async {
      int totalUnread = 0;
      for (var convDoc in snapshot.docs) {
        final convId = convDoc.id;
        final messagesSnap = await FirebaseFirestore.instance
            .collection('conversations')
            .doc(convId)
            .collection('messages')
            .where('senderId', isNotEqualTo: user.uid)
            .where('isRead', isEqualTo: false)
            .get();
        totalUnread += messagesSnap.docs.length;
      }
      if (mounted) {
        setState(() => _unreadMessagesCount = totalUnread);
      }
    });
  }

  // LẤY TÊN MÔN THỂ THAO CHUẨN
  Future<String> _getSportName(dynamic fieldRef) async {
    if (fieldRef == null) return 'Khác';

    DocumentReference? sportRef;
    if (fieldRef is DocumentReference && fieldRef.parent.id == 'sports') {
      sportRef = fieldRef;
    } else if (fieldRef is String && fieldRef.contains('sports/')) {
      sportRef = FirebaseFirestore.instance.doc(fieldRef);
    } else if (fieldRef is String) {
      sportRef = FirebaseFirestore.instance.doc('sports/$fieldRef');
    }

    if (sportRef == null) return 'Khác';

    try {
      final doc = await sportRef.get();
      if (!doc.exists) return 'Khác';
      final name = (doc['name'] as String?)?.trim();
      final lower = name?.toLowerCase() ?? '';

      if (lower.contains('bóng đá') || lower.contains('bongda')) return 'Bóng đá';
      if (lower.contains('cầu lông') || lower.contains('caulong')) return 'Cầu lông';
      if (lower.contains('bóng chuyền') || lower.contains('bongchuyen')) return 'Bóng chuyền';
      if (lower.contains('bida')) return 'Bida';
      return name ?? 'Khác';
    } catch (e) {
      return 'Khác';
    }
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
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatListScreen())),
                ),
                if (_unreadMessagesCount > 0)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                      child: Text(
                        _unreadMessagesCount > 99 ? '99+' : '$_unreadMessagesCount',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
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

            // ĐÁNH GIÁ THÁNG
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
                    MaterialPageRoute(builder: (_) => DanhGiaCuaToiScreen(ownerUserId: FirebaseAuth.instance.currentUser!.uid)),
                  );
                }),
              ],
            ),
            const SizedBox(height: 20),

            // TỔNG SỐ SÂN
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

            // 2 BIỂU ĐỒ DOANH THU SIÊU ĐẸP
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _revenuePieChart("Tháng ${DateFormat('MM').format(DateTime.now())}", isToday: false),
                  _revenuePieChart("Hôm nay ${DateFormat('dd/MM').format(DateTime.now())}", isToday: true),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

 Widget _revenuePieChart(String title, {required bool isToday}) {
  final userId = FirebaseAuth.instance.currentUser!.uid;

  final nowVN = DateTime.now().toLocal();
  final startOfDay = DateTime(nowVN.year, nowVN.month, nowVN.day);
  final startOfMonth = DateTime(nowVN.year, nowVN.month, 1);
  final start = isToday ? startOfDay : startOfMonth;
  final end = isToday ? startOfDay.add(const Duration(days: 1)) : DateTime(nowVN.year, nowVN.month + 1, 1);

  return StreamBuilder<Map<String, double>>(
    stream: FirebaseFirestore.instance
        .collectionGroup('pending_payments')
        .where('owner_id', isEqualTo: userId)
        .where('status', whereIn: ['Chờ xác nhận', 'Đã xác nhận'])
        .snapshots()
        .asyncMap((pendingSnap) async {
      // Lấy bookings realtime (dùng snapshots thay vì get())
      final bookingStream = FirebaseFirestore.instance
          .collection('bookings')
          .where('owner_id', isEqualTo: userId)
          .where('status', isEqualTo: 'Đã xác nhận')
          .snapshots();

      final bookingSnap = await bookingStream.first; // Lấy snapshot đầu tiên

      Map<String, double> result = {};

      // Tiền cọc
      for (var doc in pendingSnap.docs) {
        final data = doc.data();
        final ts = (data['created_at'] as Timestamp?)?.toDate();
        if (ts == null) continue;
        final timeVN = ts.add(const Duration(hours: 7));
        if (timeVN.isBefore(start) || timeVN.isAfter(end)) continue;

        final deposit = (data['deposit_amount'] as num?)?.toDouble() ?? 0.0;
        final sport = await _getSportName(data['sport_id'] ?? data['field_id']);
        result[sport] = (result[sport] ?? 0) + deposit;
      }

      // Tiền còn lại từ bookings
      for (var doc in bookingSnap.docs) {
  final data = doc.data();
  final ts = (data['updated_at'] as Timestamp?)?.toDate();
  if (ts == null) continue;
  final timeVN = ts.add(const Duration(hours: 7));

  // SỬA CHỖ NÀY: Chỉ lọc ngày khi isToday = true
  // Với biểu đồ tháng → vẫn tính booking của cả tháng (không cần kiểm tra giờ)
  if (isToday) {
    if (timeVN.isBefore(start) || timeVN.isAfter(end)) continue;
  } else {
    // Chỉ cần cùng tháng + năm là được tính vào biểu đồ tháng
    final nowVN = DateTime.now().toLocal();
    if (timeVN.year != nowVN.year || timeVN.month != nowVN.month) continue;
  }

  final price = (data['price'] as num?)?.toDouble() ?? 0.0;
  final depositPaid = (data['deposit_paid'] as num?)?.toDouble() ?? 0.0; // ← SỬA CHÍNH TẢ TỪ depoist_paid → deposit_paid
  final remaining = price - depositPaid;
  if (remaining <= 0) continue;

  final sport = await _getSportName(data['sport_id']);
  result[sport] = (result[sport] ?? 0) + remaining;
}

      return result;
    }).handleError((e) {
      return <String, double>{};
    }),

    builder: (context, snapshot) {
      if (!snapshot.hasData || snapshot.connectionState == ConnectionState.waiting) {
        return _buildLoadingPieChart(title);
      }

      final data = snapshot.data!;
      final total = data.values.fold(0.0, (a, b) => a + b);

      if (total == 0) {
        return _buildZeroChart(title);
      }

      return _MultiSportPieChart(title: title, sportRevenue: data);
    },
  );
}

// Thêm widget này vào cuối class để hiển thị 0đ đẹp hơn
Widget _buildZeroChart(String title) {
  return Column(
    children: [
      Container(
        width: 130,
        height: 130,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[200],
          border: Border.all(color: Colors.grey.shade400, width: 12),
        ),
        child: const Center(
          child: Text('0đ', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.grey)),
        ),
      ),
      const SizedBox(height: 12),
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      const Text('Chưa có doanh thu', style: TextStyle(fontSize: 12, color: Colors.grey)),
    ],
  );
}

// Widget loading đẹp mắt khi đang tải
Widget _buildLoadingPieChart(String title) {
  return Column(
    children: [
      Container(
        width: 130,
        height: 130,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey[200],
          border: Border.all(color: Colors.grey.shade400, width: 12),
        ),
        child: Center(
          child: Text('0đ', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.grey[600])),
        ),
      ),
      const SizedBox(height: 12),
      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      const Text('Đang tải...', style: TextStyle(fontSize: 12, color: Colors.grey)),
    ],
  );
}

  // TỔNG SỐ SÂN
  Stream<Map<String, int>> _getTotalFieldCounts() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return Stream.value({'Bóng Đá': 0, 'Bida': 0});

    return FirebaseFirestore.instance
        .collection('fields')
        .snapshots()
        .asyncMap((snapshot) async {
      int footballCount = 0;
      int billiardCount = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        dynamic ownerId = data['owner_id'];
        bool isOwner = false;
        if (ownerId is String) {
          isOwner = (ownerId == userId);
        } else if (ownerId is DocumentReference) {
          isOwner = (ownerId.id == userId);
        }
        if (!isOwner) continue;

        final sport = (data['sport']?.toString() ?? '').toLowerCase();
        final sportId = (data['sport_id']?.toString() ?? '').toLowerCase();

        if (sport.contains('bóng') || sportId.contains('bongda')) {
          footballCount++;
        } else if (sport.contains('bida') || sportId.contains('bida')) {
          billiardCount++;
        }
      }
      return {'Bóng Đá': footballCount, 'Bida': billiardCount};
    });
  }

  // MENU NHANH
  Widget _buildMenuItem(IconData icon, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 3))]),
            child: Icon(icon, color: Colors.blueAccent, size: 28),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // CARD SÂN
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

  // ĐÁNH GIÁ THÁNG (giữ nguyên code cũ của bạn)
  Widget _buildMonthlyRatingCard() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return _ratingCard("Đánh Giá Tháng Này", "Đăng nhập để xem", 0.0, 0);
    }

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);

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

  Future<Map<String, dynamic>> _fetchMonthlyRating(String userId, DateTime startOfMonth) async {
    try {
      final fieldSnapshot = await FirebaseFirestore.instance
          .collection('fields')
          .where('owner_id', whereIn: [userId, FirebaseFirestore.instance.doc('users/$userId')])
          .get();

      if (fieldSnapshot.docs.isEmpty) return {'avg': 0.0, 'count': 0};

      final fieldIds = fieldSnapshot.docs.map((e) => e.reference).toList();

      try {
        final reviewSnapshot = await FirebaseFirestore.instance
            .collection('reviews')
            .where('field_id', whereIn: fieldIds)
            .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
            .orderBy('created_at', descending: true)
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
}

// BIỂU ĐỒ TRÒN SIÊU ĐẸP + 0Đ TO RÕ
class _MultiSportPieChart extends StatelessWidget {
  final String title;
  final Map<String, double> sportRevenue;

  const _MultiSportPieChart({required this.title, required this.sportRevenue});

  Color _getSportColor(String sport) {
    final s = sport.toLowerCase();
    if (s.contains('bóng đá') || s.contains('bongda')) return Colors.green.shade600;
    if (s.contains('cầu lông') || s.contains('caulong')) return Colors.blue.shade600;
    if (s.contains('bóng chuyền') || s.contains('bongchuyen')) return Colors.purple.shade600;
    if (s.contains('bida')) return Colors.brown.shade600;
    return Colors.grey.shade600;
  }

  @override
  Widget build(BuildContext context) {
    final total = sportRevenue.values.fold(0.0, (a, b) => a + b);
    final formatter = NumberFormat.currency(locale: 'vi', symbol: 'đ');

    if (total == 0) {
      return Column(
        children: [
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
              border: Border.all(color: Colors.grey.shade400, width: 12),
            ),
            child: const Center(
              child: Text(
                '0đ',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const Text('Chưa có doanh thu', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      );
    }

    final sections = sportRevenue.entries.map((e) {
      final percentage = (e.value / total) * 100;
      return PieChartSectionData(
        value: e.value,
        color: _getSportColor(e.key),
        title: percentage >= 8 ? '${percentage.toStringAsFixed(0)}%' : '',
        titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        radius: 44,
      );
    }).toList();

    return Column(
      children: [
        SizedBox(
          width: 130,
          height: 130,
          child: PieChart(PieChartData(
            sections: sections,
            centerSpaceRadius: 38,
            sectionsSpace: 3,
          )),
        ),
        const SizedBox(height: 10),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        Text(
          formatter.format(total),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green),
        ),
      ],
    );
  }
}