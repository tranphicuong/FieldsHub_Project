// lib/screens/orders_main_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class OrdersMainScreen extends StatefulWidget {
  const OrdersMainScreen({super.key});

  @override
  State<OrdersMainScreen> createState() => _OrdersMainScreenState();
}

class _OrdersMainScreenState extends State<OrdersMainScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String _selectedStatus = 'Tất cả';

  final List<String> _statusOptions = [
    'Tất cả',
    'Chờ xác nhận',
    'Đã xác nhận',
    'Đang sử dụng',
    'Hoàn thành',
    'Bị từ chối',
  ];

  /// Lấy trạng thái thực tế dựa trên thời gian
  String _getRealTimeStatus(Map<String, dynamic> data) {
    final status = data['status'] as String?;
    if (status != 'Đã xác nhận') return status ?? 'Không rõ';

    final startTime = (data['start_time'] as Timestamp?)?.toDate();
    final endTime = (data['end_time'] as Timestamp?)?.toDate();
    if (startTime == null || endTime == null) return status ?? 'Không rõ';

    final now = DateTime.now();

    if (now.isBefore(startTime)) {
      return 'Đã xác nhận'; // Chưa tới giờ
    } else if (now.isAfter(startTime) && now.isBefore(endTime)) {
      return 'Đang sử dụng'; // Đang trong khung giờ
    } else if (now.isAfter(endTime)) {
      return 'Hoàn thành'; // Đã qua khung giờ
    }

    return status ?? 'Không rõ';
  }

  Stream<QuerySnapshot> _getBookingsStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    Query query = FirebaseFirestore.instance
        .collection('pending_payments')
        .where('owner_id', isEqualTo: user.uid)
        .orderBy('created_at', descending: true);

    if (_selectedStatus != 'Tất cả') {
      // Lọc theo trạng thái gốc (trên Firestore)
      if (_selectedStatus == 'Đang sử dụng' || _selectedStatus == 'Hoàn thành') {
        query = query.where('status', isEqualTo: 'Đã xác nhận');
      } else {
        query = query.where('status', isEqualTo: _selectedStatus);
      }
    }

    return query.snapshots();
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "Chưa có";
    return DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate());
  }

  String _formatCurrency(num amount) {
    return NumberFormat.currency(locale: 'vi', symbol: 'đ').format(amount);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Chờ xác nhận': return Colors.orange;
      case 'Đã xác nhận': return Colors.green;
      case 'Đang sử dụng': return Colors.blue;
      case 'Hoàn thành': return Colors.grey;
      case 'Bị từ chối': return Colors.red;
      default: return Colors.black54;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB7D8F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF004A8E),
        elevation: 0,
        
        title: const Row(
          children: [
            Icon(Icons.sports_soccer, color: Colors.white),
            SizedBox(width: 10),
            Text('Quản lý đơn đặt sân',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.white, size: 28),
            onSelected: (value) => setState(() => _selectedStatus = value),
            itemBuilder: (context) => _statusOptions.map((s) => PopupMenuItem(
              value: s,
              child: Row(
                children: [
                  if (_selectedStatus == s) const Icon(Icons.check, color: Colors.blue),
                  if (_selectedStatus == s) const SizedBox(width: 8),
                  Text(s, style: TextStyle(fontWeight: _selectedStatus == s ? FontWeight.bold : null)),
                ],
              ),
            )).toList(),
          ),
          const SizedBox(width: 12),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(Icons.tune, color: Colors.blue),
                const SizedBox(width: 10),
                Text("Đang hiển thị: $_selectedStatus",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        key: ValueKey(_selectedStatus),
        stream: _getBookingsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.blue));
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 90, color: Colors.grey[400]),
                  const SizedBox(height: 20),
                  Text(
                    _selectedStatus == 'Tất cả'
                        ? 'Chưa có đơn đặt sân nào'
                        : 'Không có đơn "$_selectedStatus"',
                    style: const TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          var bookings = snapshot.data!.docs;

          // LỌC THEO TRẠNG THÁI THỰC TẾ (Đang sử dụng / Hoàn thành)
          if (_selectedStatus == 'Đang sử dụng' || _selectedStatus == 'Hoàn thành') {
            bookings = bookings.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final realStatus = _getRealTimeStatus(data);
              return realStatus == _selectedStatus;
            }).toList();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final data = bookings[index].data() as Map<String, dynamic>;
              final docId = bookings[index].id;

              final fieldName = data['field_name'] ?? 'Sân bóng';
              final address = data['address'] ?? 'Không có địa chỉ';
              final startTime = _formatTimestamp(data['start_time'] as Timestamp?);
              final endTime = _formatTimestamp(data['end_time'] as Timestamp?);
              final paymentMethod = data['payment_method'] ?? 'Chưa chọn';

              final totalAmount = (data['total_amount'] ?? data['amount'] ?? 0) as num;
              final depositAmount = (data['deposit_amount'] ?? 0) as num;

              // TRẠNG THÁI HIỂN THỊ = TRẠNG THÁI THỰC TẾ
              final displayStatus = _getRealTimeStatus(data);

              return Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                margin: const EdgeInsets.only(bottom: 14),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(fieldName, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),

                      _buildInfoRow(Icons.location_on, 'Địa chỉ', address),
                      _buildInfoRow(Icons.access_time, 'Khung giờ', '$startTime - $endTime'),
                      _buildInfoRow(Icons.payment, 'Thanh toán', paymentMethod),

                      const SizedBox(height: 12),

                      Align(
                        alignment: Alignment.centerRight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Tổng tiền sân: ${_formatCurrency(totalAmount)}',
                              style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Đã cọc: ${_formatCurrency(depositAmount)}',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ],
                        ),
                      ),

                      const Divider(height: 30),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: _getStatusColor(displayStatus).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              displayStatus,
                              style: TextStyle(fontWeight: FontWeight.bold, color: _getStatusColor(displayStatus), fontSize: 15),
                            ),
                          ),

                          // Chỉ hiện nút khi còn "Chờ xác nhận"
                          if (data['status'] == 'Chờ xác nhận')
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: () => _confirmBooking(context, docId),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                                  child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  onPressed: () => _rejectBooking(context, docId),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                                  child: const Text('Từ chối', style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }

  Future<void> _sendNotificationToUser({
    required String userId,
    required String title,
    required String subtitle,
    required Map<String, dynamic> extraData,
  }) async {
    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

      // Format khung giờ để hiển thị trong thông báo
      final startTime = extraData['start_time'] as Timestamp?;
      final endTime = extraData['end_time'] as Timestamp?;
      String timeSlot = '';
      
      if (startTime != null && endTime != null) {
        final start = DateFormat('HH:mm dd/MM/yyyy').format(startTime.toDate());
        final end = DateFormat('HH:mm dd/MM/yyyy').format(endTime.toDate());
        timeSlot = '$start - $end';
      }

      await FirebaseFirestore.instance.collection('notifications').add({
        'user_id': userRef,
        'title': title,
        'subtitle': subtitle,
        'field_name': extraData['field_name'] ?? '',
        'address': extraData['address'] ?? '',
        'time_slot': timeSlot, // Thêm khung giờ đã format
        'start_time': extraData['start_time'],
        'end_time': extraData['end_time'],
        'payment_method': extraData['payment_method'] ?? '',
        'field_id': extraData['field_id'],
        'is_read': false,
        'created_at': FieldValue.serverTimestamp(),
      });
      
    } catch (e) {
      print('❌ Lỗi gửi thông báo: $e');
    }
  }

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