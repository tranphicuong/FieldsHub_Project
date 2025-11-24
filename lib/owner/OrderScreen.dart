import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Định dạng thời gian

class OrdersMainScreen extends StatefulWidget {
  const OrdersMainScreen({super.key});

  @override
  State<OrdersMainScreen> createState() => _OrdersMainScreenState();
}

class _OrdersMainScreenState extends State<OrdersMainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isDebugMode = true; // Chế độ debug (true: lấy tất cả đơn)

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    print("User ID hiện tại: ${_auth.currentUser?.uid}");
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 🔹 Stream lấy danh sách bookings theo trạng thái
  Stream<QuerySnapshot> _getBookingsStream(String statusFilter) {
  final currentUser = _auth.currentUser;
  if (currentUser == null) return const Stream.empty();

  final collection = FirebaseFirestore.instance.collection('pending_payments');

  // Debug mode (chỉ để test)
  if (_isDebugMode) {
    return collection.orderBy('created_at', descending: true).snapshots();
  }

  // CHUẨN CHO 4 TAB – DÙNG status LÀ CHUỖI
  if (statusFilter == "Lịch sử") {
    return collection
        .where('owner_id', isEqualTo: currentUser.uid)
        .where('status_string', whereIn: ['Hoàn thành', 'Bị từ chối'])
        .orderBy('created_at', descending: true)
        .snapshots();
  } else {
    return collection
        .where('owner_id', isEqualTo: currentUser.uid)
        .where('status_string', isEqualTo: statusFilter)
        .orderBy('created_at', descending: true)
        .snapshots();
  }
}

  /// 🔹 Hàm định dạng Timestamp -> String
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "N/A";
    final DateTime dateTime = timestamp.toDate();
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  

  /// 🔹 Màu trạng thái
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Chờ xác nhận':
        return Colors.orange;
      case 'Đã xác nhận':
        return Colors.green;
      case 'Đang sử dụng':
        return Colors.blue;
      case 'Hoàn thành':
        return Colors.grey;
      case 'Bị từ chối':
        return Colors.red;
      default:
        return Colors.black54;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB7D8F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF004A8E),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Row(
          children: [
            Icon(Icons.sports_soccer, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Quản lý đơn đặt sân',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: const Color(0xFFE8F3FF),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicator: BoxDecoration(
                color: Colors.blue[700],
                borderRadius: BorderRadius.circular(8),
              ),
              tabs: const [
                Tab(text: "Chờ xác nhận"),
                Tab(text: "Đã xác nhận"),
                Tab(text: "Đang sử dụng"),
                Tab(text: "Lịch sử"),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBookingTab("Chờ xác nhận"),
          _buildBookingTab("Đã xác nhận"),
          _buildBookingTab("Đang sử dụng"),
          _buildBookingTab("Lịch sử"),
        ],
      ),
    );
  }

  /// 🔹 Hiển thị danh sách đơn
  Widget _buildBookingTab(String statusFilter) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getBookingsStream(statusFilter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('Không có đơn $statusFilter'));
        }

        final bookings = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final data = bookings[index].data() as Map<String, dynamic>;
            final docId = bookings[index].id;

            final startTime = _formatTimestamp(data['start_time'] as Timestamp?);
            final endTime = _formatTimestamp(data['end_time'] as Timestamp?);
            final fieldName = data['field_name'] ?? 'Tên sân không xác định';
            final address = data['address'] as String? ?? 'Không có địa chỉ';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fieldName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Địa chỉ: $address'),
                  Text('Khung giờ: $startTime - $endTime'),
                  Text('Thanh toán: ${data['payment_method'] ?? 'Phương thức không xác định'}'),
                  Text(
                    'Số tiền: ${NumberFormat.currency(locale: 'vi', symbol: 'đ').format(data['total_amount'] ?? data['amount'] ?? 0)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        data['status'] ?? 'Trạng thái không xác định',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(data['status'] ?? ''),
                        ),
                      ),
                      if (data['status'] == 'Chờ xác nhận')
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () => _confirmBooking(context, docId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              child: const Text("Xác nhận",
                                  style: TextStyle(color: Colors.white)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _rejectBooking(context, docId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              ),
                              child: const Text("Từ chối",
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
/// Gửi thông báo realtime cho người dùng
/// Gửi thông báo realtime cho người dùng - ĐÃ SỬA
Future<void> _sendNotificationToUser({
  required String userId,
  required String title,
  required String subtitle,
  required Map<String, dynamic> extraData,
}) async {
  try {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    await FirebaseFirestore.instance.collection('notifications').add({
      'user_id': userRef,
      'title': title,
      'subtitle': subtitle,
      'field_name': extraData['field_name'] ?? '',
      'address': extraData['address'] ?? '',
      
      // ✅ LƯU RIÊNG start_time và end_time
      'start_time': extraData['start_time'],  // Timestamp
      'end_time': extraData['end_time'],      // Timestamp
      
      'payment_method': extraData['payment_method'] ?? '',
      'field_id': extraData['field_id'],
      'is_read': false,
      'created_at': FieldValue.serverTimestamp(),
    });
    
    print('✅ Đã gửi thông báo cho user: $userId');
  } catch (e) {
    print('❌ Lỗi gửi thông báo: $e');
  }
}

/// ✅ XÁC NHẬN ĐƠN - Đã sửa
Future<void> _confirmBooking(BuildContext context, String bookingId) async {
  try {
    final bookingDoc = await FirebaseFirestore.instance
        .collection('pending_payments')
        .doc(bookingId)
        .get();

    if (!bookingDoc.exists) return;

    final data = bookingDoc.data()!;
    final userId = data['user_id'] as String;

    // 1. Cập nhật trạng thái đơn
    await FirebaseFirestore.instance
        .collection('pending_payments')
        .doc(bookingId)
        .update({
      'status': 'Đã xác nhận',
      'status_string': 'Đã xác nhận',
      'status_id': FirebaseFirestore.instance.doc('status/2'),
      'updated_at': FieldValue.serverTimestamp(),
    });

    // 2. GỬI THÔNG BÁO CHO KHÁCH HÀNG
    await _sendNotificationToUser(
      userId: userId,
      title: "Đơn đặt sân được xác nhận ",
      subtitle: "Chủ sân đã chấp nhận đơn đặt sân của bạn",
      extraData: {
        'field_name': data['field_name'] ?? '',
        'address': data['address'] ?? '',
        'start_time': data['start_time'],  // ✅ Gửi riêng
        'end_time': data['end_time'],      // ✅ Gửi riêng
        'payment_method': data['payment_method'] ?? '',
        'field_id': data['field_id'],
      },
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xác nhận & gửi thông báo cho khách!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    print('❌ Lỗi xác nhận đơn: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }
}

/// ❌ TỪ CHỐI ĐƠN - Đã sửa
Future<void> _rejectBooking(BuildContext context, String bookingId) async {
  try {
    final bookingDoc = await FirebaseFirestore.instance
        .collection('pending_payments')
        .doc(bookingId)
        .get();

    if (!bookingDoc.exists) return;

    final data = bookingDoc.data()!;
    final userId = data['user_id'] as String;

    // 1. Cập nhật trạng thái
    await FirebaseFirestore.instance
        .collection('pending_payments')
        .doc(bookingId)
        .update({
      'status': 'Bị từ chối',
      'status_string': 'Bị từ chối',
      'status_id': FirebaseFirestore.instance.doc('status/3'),
      'updated_at': FieldValue.serverTimestamp(),
    });

    // 2. GỬI THÔNG BÁO TỪ CHỐI
    await _sendNotificationToUser(
      userId: userId,
      title: "Đơn đặt sân bị từ chối ❌",
      subtitle: "Rất tiếc, chủ sân đã từ chối đơn của bạn",
      extraData: {
        'field_name': data['field_name'] ?? '',
        'address': data['address'] ?? '',
        'start_time': data['start_time'],  // ✅ Gửi riêng
        'end_time': data['end_time'],      // ✅ Gửi riêng
        'payment_method': data['payment_method'] ?? '',
        'field_id': data['field_id'],
      },
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã từ chối & gửi thông báo cho khách!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    print('❌ Lỗi từ chối đơn: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
    }