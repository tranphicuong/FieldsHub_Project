import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fieldshub/Database/database.dart';
import 'package:fieldshub/user/review_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookingHistoryScreen extends StatefulWidget {
  const BookingHistoryScreen({Key? key}) : super(key: key);

  @override
  State<BookingHistoryScreen> createState() => _BookingHistoryScreenState();
}

class _BookingHistoryScreenState extends State<BookingHistoryScreen>
    with SingleTickerProviderStateMixin {
  String selectedStatus = "Tất cả";
  final currentUser = FirebaseAuth.instance.currentUser;

  final List<String> statusTabs = [
    "Tất cả",
    "Chờ xác nhận",
    "Đã xác nhận",
    "Đã hủy",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 19, 153, 215),
        elevation: 0,
        title: const Text(
          "Lịch sử đặt sân",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Container(
            color: Colors.blue[100],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: statusTabs.map((status) {
                final selected = selectedStatus == status;
                return GestureDetector(
                  onTap: () => setState(() => selectedStatus = status),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: selected
                              ? Colors.blue[800]!
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: selected ? Colors.blue[800] : Colors.black54,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('bookings')
                  .where(
                    'user_id',
                    isEqualTo: FirebaseFirestore.instance
                        .collection('users')
                        .doc(currentUser!.uid),
                  )
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text("Lỗi tải lịch sử đặt sân: ${snapshot.error}"),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Chưa có lịch sử đặt sân"));
                }
                final docs = snapshot.data!.docs;
                final bookings = docs.map((d) => d).where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (selectedStatus == "Tất cả") return true;
                  return (data['status'] ?? '') == selectedStatus;
                }).toList();
                bookings.sort((a, b) {
                  final ad = (a.data() as Map<String, dynamic>)['created_at'];
                  final bd = (b.data() as Map<String, dynamic>)['created_at'];
                  if (ad is Timestamp && bd is Timestamp) {
                    return bd.compareTo(ad);
                  }
                  return 0;
                });
                if (bookings.isEmpty) {
                  return const Center(
                    child: Text("Không có đặt sân nào trong mục này"),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(10),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final bookingDoc = bookings[index];
                    return FutureBuilder<Widget>(
                      future: _buildBookingCardFuture(
                        bookingDoc.data() as Map<String, dynamic>,
                        bookingDoc.id,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Card(
                            child: ListTile(title: Text('Đang tải...')),
                          );
                        }
                        return snapshot.data ?? const SizedBox.shrink();
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<Widget> _buildBookingCardFuture(
    Map<String, dynamic> booking,
    String bookingId,
  ) async {
    String address = (booking['address'] as String?) ?? '';
    if (address.isEmpty || address == '—') {
      try {
        dynamic fieldRef = booking['field_id'];
        DocumentSnapshot? fieldDoc;
        if (fieldRef is DocumentReference) {
          fieldDoc = await fieldRef.get();
        } else if (fieldRef is String) {
          fieldDoc = await FirebaseFirestore.instance
              .collection('fields')
              .doc(fieldRef)
              .get();
        }
        if (fieldDoc != null && fieldDoc.exists) {
          final fieldData = fieldDoc.data() as Map<String, dynamic>?;
          dynamic areaRef = fieldData?['area_id'];
          DocumentSnapshot? areaDoc;
          if (areaRef is DocumentReference) {
            areaDoc = await areaRef.get();
          } else if (areaRef is String) {
            areaDoc = await FirebaseFirestore.instance
                .collection('areas')
                .doc(areaRef)
                .get();
          }
          address =
              (areaDoc?.data() as Map<String, dynamic>?)?['address']
                  as String? ??
              'Không có địa chỉ';
        }
      } catch (e) {
        debugPrint('Lỗi fetch address cho booking $bookingId: $e');
        address = 'Không xác định';
      }
    }

    String dateText = '—';
    String timeText = '—';
    try {
      if (booking['start_time'] is Timestamp) {
        final start = (booking['start_time'] as Timestamp).toDate();
        dateText = DateFormat('dd/MM/yyyy').format(start);
        String endPart = '';
        if (booking['end_time'] is Timestamp) {
          final end = (booking['end_time'] as Timestamp).toDate();
          endPart = ' - ${end.toString().substring(11, 16)}';
        }
        timeText = '${start.toString().substring(11, 16)}$endPart';
      }
    } catch (_) {
      debugPrint('Lỗi xử lý thời gian cho booking $bookingId');
    }

    final status = booking['status'] as String? ?? 'Không xác định';

    final fieldNameText =
        booking['field_name'] as String? ??
        booking['fieldName'] as String? ??
        'Không tên';
    final bookingCode =
        booking['booking_code'] as String? ??
        booking['bookingCode'] as String? ??
        bookingId;

    final totalAmount = (booking['total_amount'] as num?)?.toDouble() ?? 0.0;
    final depositAmount =
        (booking['deposit_amount'] as num?)?.toDouble() ?? 0.0;
    final paymentMethod = booking['payment_method'] as String? ?? 'Cọc';

    final remainingAmount = paymentMethod == "Cọc"
        ? (totalAmount - depositAmount).toInt()
        : 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          backgroundColor: Colors.white,
          collapsedBackgroundColor: Colors.white,
          iconColor: Colors.blue[700],
          collapsedIconColor: Colors.blue[700],
          childrenPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  fieldNameText,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Text(
                "$dateText, $timeText",
                style: const TextStyle(color: Colors.black87, fontSize: 13),
              ),
              const SizedBox(height: 2),
              Text(
                status,
                style: TextStyle(
                  color: status == "Đã hủy"
                      ? Colors.red
                      : status == "Chờ xác nhận"
                      ? Colors.orange
                      : Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "${NumberFormat('#,###', 'vi_VN').format(depositAmount)} VNĐ",
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          children: [
            const Divider(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Mã đặt: $bookingCode",
                  style: const TextStyle(fontSize: 13),
                ),
                Text("Địa chỉ: $address", style: const TextStyle(fontSize: 13)),
                Text(
                  paymentMethod == "Cọc"
                      ? "Số tiền còn lại: ${NumberFormat('#,###', 'vi_VN').format(remainingAmount)} VNĐ"
                      : "Đã thanh toán toàn bộ",
                  style: TextStyle(
                    fontSize: 13,
                    color: paymentMethod == "Cọc"
                        ? Colors.orange
                        : Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),
                Row(
                  children: [
                    if (status == "Đã xác nhận")
                      FutureBuilder<bool>(
                        future: Database.hasUserReviewedBooking(
                          bookingId: bookingId,
                          userId: currentUser!.uid,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return SizedBox(
                              width: 100,
                              child: OutlinedButton.icon(
                                onPressed: null,
                                icon: Icon(Icons.rate_review, size: 16),
                                label: Text("Đang tải..."),
                              ),
                            );
                          }

                          final hasReviewed = snapshot.data ?? false;

                          if (hasReviewed) {
                            return Chip(
                              label: Text(
                                "Đã đánh giá",
                                style: TextStyle(fontSize: 12),
                              ),
                              backgroundColor: Colors.grey[200],
                              avatar: Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.green,
                              ),
                            );
                          }

                          return OutlinedButton.icon(
                            icon: const Icon(Icons.rate_review, size: 18),
                            label: const Text("Đánh giá"),
                            onPressed: () async {
                              final fieldImage = await Database.getFieldImage(
                                booking['field_id'] is DocumentReference
                                    ? booking['field_id'].id
                                    : booking['field_id']?.toString() ?? '',
                              );

                              if (!mounted) return;

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ReviewScreen(
                                    fieldId:
                                        booking['field_id'] is DocumentReference
                                        ? booking['field_id'].id
                                        : booking['field_id']?.toString() ?? '',
                                    bookingId: bookingId,
                                    fieldName: fieldNameText,
                                    fieldImage: fieldImage,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    if (status == "Chờ xác nhận") ...[
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.cancel, size: 18),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          if (!mounted) return;
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Xác nhận'),
                              content: const Text(
                                'Bạn có chắc chắn muốn hủy đặt sân này?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Không'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Có'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true && mounted) {
                            try {
                              await Database.updateBookingStatus(
                                bookingId: bookingId,
                                 statusKey: 'cancelled');
                             
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Đã hủy đặt sân thành công"),
                                    behavior: SnackBarBehavior.floating,
                                    margin: const EdgeInsets.only(
                                      bottom: 50,
                                      left: 20,
                                      right: 20,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Lỗi hủy đặt sân: $e"),
                                  ),
                                );
                              }
                            }
                          }
                        },
                        label: const Text("Hủy đặt sân"),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
