import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // Thêm để định dạng Timestamp

class OrdersMainScreen extends StatefulWidget {
  const OrdersMainScreen({super.key});

  @override
  State<OrdersMainScreen> createState() => _OrdersMainScreenState();
}

class _OrdersMainScreenState extends State<OrdersMainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isDebugMode = true; // Chế độ gỡ lỗi, có thể tắt sau khi xong

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

  Stream<QuerySnapshot> _getBookingsStream(String statusFilter) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      print("Không có người dùng được xác thực!");
      return const Stream.empty();
    }
    print("Truy vấn với user_id: /users/${currentUser.uid}, status_filter: $statusFilter");

    if (_isDebugMode) {
      return FirebaseFirestore.instance
          .collection('bookings')
          .orderBy('created_at', descending: true)
          .snapshots();
    } else {
      if (statusFilter == "Lịch sử") {
        // "Lịch sử" bao gồm các trạng thái đã kết thúc
        return FirebaseFirestore.instance
            .collection('bookings')
            .where('user_id', isEqualTo: '/users/${currentUser.uid}')
            .where('status', whereIn: ['Hoàn thành', 'Bị từ chối'])
            .orderBy('created_at', descending: true)
            .snapshots();
      } else {
        return FirebaseFirestore.instance
            .collection('bookings')
            .where('user_id', isEqualTo: '/users/${currentUser.uid}')
            .where('status', isEqualTo: statusFilter)
            .orderBy('created_at', descending: true)
            .snapshots();
      }
    }
  }

  // Định dạng Timestamp thành chuỗi ngày giờ
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return "N/A";
    final DateTime dateTime = timestamp.toDate();
    return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
  }

  // Lấy địa chỉ từ collection fields dựa trên field_name
  Future<String> _getAddressFromField(String? fieldName) async {
    if (fieldName == null || fieldName.isEmpty) return "Địa chỉ không xác định";
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('fields')
          .where('name', isEqualTo: fieldName)
          .limit(1)
          .get();
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first['diaChi'] ?? "Địa chỉ không xác định";
      }
      return "Địa chỉ không xác định";
    } catch (e) {
      print("Lỗi khi lấy địa chỉ từ fields: $e");
      return "Địa chỉ không xác định";
    }
  }

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
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: const Color(0xFF004A8E),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: const [
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
            ),
            Container(
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
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBookingTab("Chờ xác nhận"),
                  _buildBookingTab("Đã xác nhận"),
                  _buildBookingTab("Đang sử dụng"),
                  _buildBookingTab("Lịch sử"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingTab(String statusFilter) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getBookingsStream(statusFilter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          print("Không có dữ liệu cho trạng thái: $statusFilter");
          return Center(child: Text('Không có đơn $statusFilter'));
        }

        final bookings = snapshot.data!.docs;
        print("Số lượng booking: ${bookings.length} cho trạng thái: $statusFilter");
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final data = bookings[index].data() as Map<String, dynamic>;
            final docId = bookings[index].id;
            print("Dữ liệu booking $index: $data");

            // Định dạng khung giờ
            String startTime = _formatTimestamp(data['start_time'] as Timestamp?);
            String endTime = _formatTimestamp(data['end_time'] as Timestamp?);
            String fieldName = data['field_name'] ?? 'Tên sân không xác định';

            return FutureBuilder<String>(
              future: _getAddressFromField(fieldName),
              builder: (context, addressSnapshot) {
                if (addressSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                String address = addressSnapshot.data ?? "Địa chỉ không xác định";

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2)),
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
                                  onPressed: () => _confirmBooking(context, docId, data),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  ),
                                  child: const Text("Xác nhận",
                                      style: TextStyle(color: Colors.white)),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () => _rejectBooking(context, docId, data),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding:
                                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
              }
            );
          },
        );
      },
    );
  }

  /// ✅ Xác nhận đơn đặt sân
  Future<void> _confirmBooking(
      BuildContext context, String bookingId, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
        'status': 'Đã xác nhận',
        'status_id': '/status/confirmed',
        'updated_at': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('notifications').add({
        'title': 'Đơn đặt sân đã được xác nhận!',
        'subtitle': data['field_name'] ?? '',
        'field_name': data['field_name'] ?? '',
        'address': data['address'] ?? '',
        'time_slot': '${data['start_time']} - ${data['end_time']}',
        'payment_method': data['payment_method'] ?? '',
        'is_read': false,
        'created_at': FieldValue.serverTimestamp(),
        'user_id': data['user_id'],
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Đã xác nhận đơn thành công')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi xác nhận đơn: $e')),
      );
    }
  }

  /// ❌ Từ chối đơn đặt sân
  Future<void> _rejectBooking(
      BuildContext context, String bookingId, Map<String, dynamic> data) async {
    try {
      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
        'status': 'Bị từ chối',
        'status_id': '/status/rejected',
        'updated_at': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('notifications').add({
        'title': 'Đơn đặt sân đã bị từ chối',
        'subtitle': data['field_name'] ?? '',
        'field_name': data['field_name'] ?? '',
        'address': data['address'] ?? '',
        'time_slot': '${data['start_time']} - ${data['end_time']}',
        'payment_method': data['payment_method'] ?? '',
        'is_read': false,
        'created_at': FieldValue.serverTimestamp(),
        'user_id': data['user_id'],
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Đã từ chối đơn đặt sân')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi từ chối đơn: $e')),
      );
    }
  }
}