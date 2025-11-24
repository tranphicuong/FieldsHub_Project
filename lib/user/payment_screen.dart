import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:fieldshub/user/chat_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentPage extends StatefulWidget {
  final String? bookingId;
  final double amount;
  final String paymentMethod;

  final String? fieldId;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? fieldName;
  final String? address;

  const PaymentPage({
    super.key,
    this.bookingId,
    required this.amount,
    required this.paymentMethod,
    this.fieldId,
    this.startTime,
    this.endTime,
    this.fieldName,
    this.address, required double totalAmount,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

enum PaymentState { showingQR, waitingConfirmation, cancelled }

class _PaymentPageState extends State<PaymentPage> {
  PaymentState _state = PaymentState.showingQR;
  Duration _remaining = const Duration(hours: 2);
  Timer? _timer;
  String? _localBookingId;

  String fieldName = 'Đang tải...';
  String address = '—';
  String timeRange = '—';
  int totalAmount = 0;
  String txCode = '';
  String paymentType = '';
  String _bookingCode = '';

  @override
  void initState() {
    super.initState();
    paymentType = widget.paymentMethod;
    totalAmount = widget.amount.toInt();
    txCode =
        "#${DateTime.now().millisecondsSinceEpoch.toString().substring(0, 6)}";
    _loadBookingData();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  

  Future<void> _loadBookingData() async {
    final idToLoad = widget.bookingId ?? _localBookingId;
    if (idToLoad != null) {
      final bookingDoc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(idToLoad)
          .get();
      if (bookingDoc.exists) {
        final data = bookingDoc.data()!;
        dynamic fieldRef = data['field_id'];
        DocumentSnapshot? fieldDoc;
        if (fieldRef is DocumentReference) {
          fieldDoc = await fieldRef.get();
        } else if (fieldRef is String) {
          fieldDoc = await FirebaseFirestore.instance
              .collection('fields')
              .doc(fieldRef)
              .get();
        }
        final fieldData = fieldDoc != null && fieldDoc.exists
            ? fieldDoc.data() as Map<String, dynamic>?
            : null;

        String fetchedAddress = '-';
        if (fieldData != null && fieldData.containsKey('area_id')) {
          dynamic areaRef = fieldData['area_id'];
          DocumentSnapshot? areaDoc;
          if (areaRef is DocumentReference) {
            areaDoc = await areaRef.get();
          }
          final data = areaDoc?.data() as Map<String, dynamic>?;
          fetchedAddress = data?['address'] ?? 'Không có địa chỉ';
        } else if (data.containsKey('address')) {
          fetchedAddress = data['address'] ?? '';
        }

        if (mounted) {
          setState(() {
            fieldName = fieldData != null
                ? (fieldData['name'] ?? 'Không tên')
                : (widget.fieldName ?? 'Không tên');
            address = fetchedAddress;
            try {
              final startTime = (data['start_time'] as Timestamp).toDate();
              final endTime = (data['end_time'] as Timestamp).toDate();
              timeRange =
                  "${startTime.toString().substring(11, 16)} - ${endTime.toString().substring(11, 16)}, ${DateFormat('dd/MM/yyyy').format(startTime)}";
            } catch (_) {}
          });
        }
      }
    } else {
      if (mounted) {
        setState(() {
          fieldName = widget.fieldName ?? fieldName;
          address = widget.address ?? address;
          if (widget.startTime != null && widget.endTime != null) {
            final s = widget.startTime!;
            final e = widget.endTime!;
            timeRange =
                "${s.toString().substring(11, 16)} - ${e.toString().substring(11, 16)}, ${DateFormat('dd/MM/yyyy').format(s)}";
          }
        });
      }
    }
  }

  String _generateBookingCode() {
    const chars = '0123456789';
    final rnd = Random.secure();
    final code = List.generate(
      6,
      (_) => chars[rnd.nextInt(chars.length)],
    ).join();
    return '#FH$code';
  }

  void _startCountdown() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_remaining.inSeconds > 0) {
          _remaining = _remaining - const Duration(seconds: 1);
        } else {
          t.cancel();
          _updateBookingStatus('cancelled');
          _state = PaymentState.cancelled;
        }
      });
    });
  }

  String _formatDuration(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}";
  }

  Future<void> _updateBookingStatus(String statusKey) async {
    try {
      final Map<String, dynamic> statusMap = {
        "pending": '1',
        'paid': '2',
        'unpaid': '3',
        'cancelled': '4',
        'approved': '5',
        'completed': '6',
        'using': '7',
      };
      final String statusId = statusMap[statusKey] ?? '1';
      final String? idToUpdate = widget.bookingId ?? _localBookingId;

      if (idToUpdate != null) {
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(idToUpdate)
            .update({
              'status_id': FirebaseFirestore.instance
                  .collection('status')
                  .doc(statusId),
            });
      }

      if (statusKey == 'cancelled') {
        try {
          final idToRead = widget.bookingId ?? _localBookingId;
          if (idToRead == null) return;

          final bookingDoc = await FirebaseFirestore.instance
              .collection('bookings')
              .doc(idToRead)
              .get();

          if (bookingDoc.exists) {
            final data = bookingDoc.data();
            dynamic fieldRef = data?['field_id'];
            DocumentSnapshot? fieldDoc;

            if (fieldRef is DocumentReference) {
              fieldDoc = await fieldRef.get();
            } else if (fieldRef is String) {
              fieldDoc = await FirebaseFirestore.instance
                  .collection('fields')
                  .doc(fieldRef)
                  .get();
            }
            String fetchedAddress = '';
            if (fieldDoc != null && fieldDoc.exists) {
              final fieldData = fieldDoc.data() as Map<String, dynamic>?;
              if (fieldData != null && fieldData.containsKey('area_id')) {
                dynamic areaRef = fieldData['area_id'];
                DocumentSnapshot? areaDoc;
                if (areaRef is DocumentReference) {
                  areaDoc = await areaRef.get();
                }
                final areaData = areaDoc?.data() as Map<String, dynamic>?;
                fetchedAddress = areaData?['address'] ?? '';
              }
            }
            String recipientId = '';
            if (fieldDoc != null && fieldDoc.exists) {
              final fdata = fieldDoc.data();
              if (fdata is Map<String, dynamic>) {
                dynamic ownerCandidate;
                for (final k in [
                  'owner',
                  'owner_id',
                  'ownerId',
                  'ownerUid',
                  'owner_ref',
                  'ownerRef',
                  'user_id',
                  'userId',
                ]) {
                  if (fdata.containsKey(k)) {
                    ownerCandidate = fdata[k];
                    break;
                  }
                }
                if (ownerCandidate != null) {
                  if (ownerCandidate is DocumentReference) {
                    recipientId = ownerCandidate.id;
                  } else if (ownerCandidate is String) {
                    recipientId = ownerCandidate;
                  }
                }
              }
            }

            if (recipientId.isEmpty) {
              final userCandidate = data?['user_id'];
              if (userCandidate is DocumentReference) {
                recipientId = userCandidate.id;
              } else if (userCandidate is String) {
                recipientId = userCandidate;
              }
            }

            if (recipientId.isNotEmpty) {
              final userRef = FirebaseFirestore.instance
                  .collection('users')
                  .doc(recipientId);

              final fieldName = data?['field_name'] ?? '';
              final address = fetchedAddress;
              String timeSlot = '';
              try {
                final start = (data?['start_time'] as Timestamp).toDate();
                final end = (data?['end_time'] as Timestamp).toDate();
                timeSlot =
                    '${DateFormat('dd/MM/yyyy').format(start)} ${start.toString().substring(11, 16)} - ${end.toString().substring(11, 16)}';
              } catch (_) {}
              final paymentMethod = data?['payment_method'] ?? '';
              // 🔹 Lấy owner_id từ field hoặc area
String ownerId = '';
if (widget.fieldId != null) {
  final fdoc = await FirebaseFirestore.instance
      .collection('fields')
      .doc(widget.fieldId)
      .get();

  if (fdoc.exists) {
    final fdata = fdoc.data();

    if (fdata != null && fdata.containsKey('owner_id')) {
      final ownerRef = fdata['owner_id'];
      if (ownerRef is DocumentReference) ownerId = ownerRef.id;
      else if (ownerRef is String) ownerId = ownerRef;
    } else if (fdata != null && fdata.containsKey('area_id')) {
      final areaRef = fdata['area_id'];
      DocumentSnapshot? areaDoc;
      if (areaRef is DocumentReference) areaDoc = await areaRef.get();
      final areaData = areaDoc?.data() as Map<String, dynamic>?;
      final areaOwner = areaData?['owner_id'];
      if (areaOwner is DocumentReference) ownerId = areaOwner.id;
      else if (areaOwner is String) ownerId = areaOwner;
    }
  }
}

              await FirebaseFirestore.instance.collection('notifications').add({
                'owner_id': ownerId.isNotEmpty
      ? FirebaseFirestore.instance.collection('users').doc(ownerId)
      : null,
                'user_id': userRef,
                'title': 'Thanh toán bị hủy',
                'subtitle': 'Một yêu cầu đặt sân đã bị hủy',
                'field_name': fieldName,
                'address': address,
                'time_slot': timeSlot,
                'payment_method': paymentMethod,
                'created_at': Timestamp.now(),
                'is_read': false,
              });
            }
          }
        } catch (e) {
          debugPrint('❌ Failed to create cancellation notification: $e');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi cập nhật trạng thái: $e')));
      }
    }
  }

  void _onConfirmPayment() async {
    setState(() => _state = PaymentState.waitingConfirmation);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    String? bookingId = widget.bookingId ?? _localBookingId;
    String? errorMsg;
    String bookingCode = '';
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        errorMsg = 'Vui lòng đăng nhập trước khi đặt sân';
        throw Exception(errorMsg);
      }

      try {
        final fieldRef = widget.fieldId != null
            ? FirebaseFirestore.instance
                  .collection('fields')
                  .doc(widget.fieldId)
            : null;

        bookingCode = _generateBookingCode();

        String fetchedAddress = widget.address ?? '';
        if (fetchedAddress.isEmpty && widget.fieldId != null) {
          final fieldDoc = await FirebaseFirestore.instance
              .collection('fields')
              .doc(widget.fieldId)
              .get();
          if (fieldDoc.exists) {
            final fieldData = fieldDoc.data();
            if (fieldData != null && fieldData.containsKey('area_id')) {
              dynamic areaRef = fieldData['area_id'];
              DocumentSnapshot? areaDoc;
              if (areaRef is DocumentReference) {
                areaDoc = await areaRef.get();
              } else if (areaRef is String) {
                areaDoc = await FirebaseFirestore.instance
                    .collection('areas')
                    .doc(areaRef)
                    .get();
              }
              final areaData = areaDoc?.data() as Map<String, dynamic>?;
              fetchedAddress = areaData?['address'] ?? 'Không có địa chỉ';
            }
          }
        }
String? sportId;
if (widget.fieldId != null) {
  final fieldDoc = await FirebaseFirestore.instance
      .collection('fields')
      .doc(widget.fieldId)
      .get();

  if (fieldDoc.exists) {
    final fieldData = fieldDoc.data()!;
    sportId = fieldData['sport_id']?.toString(); // String hoặc DocumentReference
  }
}
        final bookingData = <String, dynamic>{
          'user_id': FirebaseFirestore.instance.collection('users').doc(currentUser.uid),
          'field_id': fieldRef,
          'field_name': widget.fieldName ?? widget.fieldId ?? '',
          'address': fetchedAddress,
          'start_time': widget.startTime != null
              ? Timestamp.fromDate(widget.startTime!)
              : null,
          'end_time': widget.endTime != null
              ? Timestamp.fromDate(widget.endTime!)
              : null,
          'price': widget.amount,
          'payment_method': widget.paymentMethod,
          'booking_code': bookingCode,
          'status': 'Chờ xác nhận',
          'status_id': FirebaseFirestore.instance.collection('status').doc('1'),
          'created_at': Timestamp.now(),
          'sport_id': sportId,
        };

        final docRef = await FirebaseFirestore.instance
            .collection('bookings')
            .add(bookingData);
        if (docRef.id.isEmpty) {
          errorMsg = 'Lỗi: không thể tạo booking';
          throw Exception(errorMsg);
        } else {
          bookingId = docRef.id;
          _localBookingId = bookingId;
        }

        try {
          final userRef = FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid);
          final userNotif = await FirebaseFirestore.instance
              .collection('notifications')
              .add({
                'user_id': userRef,
                'title': 'Yêu cầu đặt sân đã được gửi',
                'subtitle': 'Yêu cầu đặt sân của bạn đã được tạo',
                'field_name': widget.fieldName ?? '',
                'address': fetchedAddress,
                'time_slot': widget.startTime != null && widget.endTime != null
                    ? '${DateFormat('dd/MM/yyyy').format(widget.startTime!)} ${widget.startTime!.toString().substring(11, 16)} - ${widget.endTime!.toString().substring(11, 16)}'
                    : '',
                'payment_method': widget.paymentMethod,
                'booking_code': bookingCode,
                'created_at': Timestamp.now(),
                'is_read': false,
              });
          debugPrint('Created user notification: ${userNotif.id}');
        } catch (e) {
          debugPrint('Failed to create notification for user: $e');
        }

        setState(() {
          _bookingCode = bookingCode;
        });

        try {
          String recipientId = '';
          if (widget.fieldId != null) {
            final fdoc = await FirebaseFirestore.instance
                .collection('fields')
                .doc(widget.fieldId)
                .get();
            if (fdoc.exists) {
              final fdata = fdoc.data();
              if (fdata is Map<String, dynamic>) {
                dynamic ownerCandidate;
                for (final k in [
                  'owner',
                  'owner_id',
                  'ownerId',
                  'ownerUid',
                  'owner_ref',
                  'ownerRef',
                  'user_id',
                  'userId',
                ]) {
                  if (fdata.containsKey(k)) {
                    ownerCandidate = fdata[k];
                    break;
                  }
                }
                if (ownerCandidate != null) {
                  if (ownerCandidate is DocumentReference)
                    recipientId = ownerCandidate.id;
                  else if (ownerCandidate is String)
                    recipientId = ownerCandidate;
                }
              }
            }
            // 🔽 Nếu chưa tìm được chủ sân trong "fields", thử lấy từ "areas"
if (recipientId.isEmpty && fdoc.exists) {
  final fdata = fdoc.data() as Map<String, dynamic>?;
  if (fdata != null && fdata.containsKey('area_id')) {
    dynamic areaRef = fdata['area_id'];
    DocumentSnapshot? areaDoc;
    if (areaRef is DocumentReference) {
      areaDoc = await areaRef.get();
    } else if (areaRef is String) {
      areaDoc = await FirebaseFirestore.instance
          .collection('areas')
          .doc(areaRef)
          .get();
    }

    final areaData = areaDoc?.data() as Map<String, dynamic>?;
    if (areaData != null) {
      final ownerCandidate = areaData['owner_id'];
      if (ownerCandidate is DocumentReference) {
        recipientId = ownerCandidate.id;
      } else if (ownerCandidate is String) {
        recipientId = ownerCandidate;
      }
    }
  }
}

          }

          if (recipientId.isNotEmpty) {
            final userRefDoc = FirebaseFirestore.instance
                .collection('users')
                .doc(recipientId);
            final timeSlot = widget.startTime != null && widget.endTime != null
                ? '${DateFormat('dd/MM/yyyy').format(widget.startTime!)} ${widget.startTime!.toString().substring(11, 16)} - ${widget.endTime!.toString().substring(11, 16)}'
                : '';
           // 🔹 Tìm owner_id từ field hoặc area
String ownerId = '';
if (widget.fieldId != null) {
  final fdoc = await FirebaseFirestore.instance
      .collection('fields')
      .doc(widget.fieldId)
      .get();

  if (fdoc.exists) {
    final fdata = fdoc.data();
    if (fdata != null && fdata.containsKey('owner_id')) {
      final ownerRef = fdata['owner_id'];
      if (ownerRef is DocumentReference) ownerId = ownerRef.id;
      else if (ownerRef is String) ownerId = ownerRef;
    } else if (fdata != null && fdata.containsKey('area_id')) {
      final areaRef = fdata['area_id'];
      DocumentSnapshot? areaDoc;
      if (areaRef is DocumentReference) areaDoc = await areaRef.get();
      else if (areaRef is String) {
        areaDoc = await FirebaseFirestore.instance
            .collection('areas')
            .doc(areaRef)
            .get();
      }
      final areaData = areaDoc?.data() as Map<String, dynamic>?;
      final areaOwner = areaData?['owner_id'];
      if (areaOwner is DocumentReference) ownerId = areaOwner.id;
      else if (areaOwner is String) ownerId = areaOwner;
    }
  }
}

// 🔹 Gửi thông báo có owner_id rõ ràng
if (recipientId.isNotEmpty) {
  final ownerRef = FirebaseFirestore.instance.collection('users').doc(recipientId);
  final userRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);

  final notifDoc = await FirebaseFirestore.instance
      .collection('notifications')
      .add({
        'owner_id': FirebaseFirestore.instance.collection('users').doc(ownerId),
        'user_id': userRef,
        'title': 'Đơn đặt sân mới',
        'subtitle': 'Người dùng đã yêu cầu đặt sân',
        'field_name': widget.fieldName ?? '',
        'address': fetchedAddress,
        'time_slot': timeSlot,
        'payment_method': widget.paymentMethod,
        'created_at': Timestamp.now(),
        'is_read': false,
      });

  debugPrint('✅ Created booking notification for owner: $recipientId');
} else {
  debugPrint('⚠️ Không tìm thấy owner_id để gửi thông báo');
}

           
          } else {
            errorMsg = 'Lưu ý: không tìm thấy chủ sân để gửi thông báo';
          }
        } catch (e) {
          debugPrint('Failed to create booking notification: $e');
          errorMsg = e.toString();
        }
      } catch (e, st) {
        debugPrint('Failed to create booking: $e\n$st');
        errorMsg = e.toString();
      }
    } catch (e) {
      debugPrint('Error in _onConfirmPayment outer try: $e');
      errorMsg ??= e.toString();
    }

    try {
      if (bookingId != null) {
        await _updateBookingStatus('pending');
      }
    } catch (e) {
      debugPrint('Failed to update booking status: $e');
      errorMsg ??= e.toString();
    }

    if (mounted) Navigator.of(context).pop();
    if (!mounted) return;
    if (errorMsg != null) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Lỗi'),
          content: Text(errorMsg ?? 'Có lỗi xảy ra'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
      setState(() => _state = PaymentState.showingQR);
    }
  }

  Future<void> _onCancelPressed() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Thông báo"),
        content: const Text("Bạn có chắc chắn muốn hủy thanh toán không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Không"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Có"),
          ),
        ],
      ),
    );

    if (result == true) {
      if (!mounted) return;
      setState(() => _state = PaymentState.cancelled);
      _timer?.cancel();
      await _updateBookingStatus('cancelled');
    }
  }

  void _onBackToQR() {
    setState(() {
      _state = PaymentState.showingQR;
      _remaining = const Duration(hours: 2);
      _startCountdown();
    });
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF0B5EA8),
      title: const Text("Thanh toán"),
      centerTitle: true,
      elevation: 4,
      actions: [],
    );
  }

  Widget _buildPaymentCard() {
    final numberFormat = NumberFormat('#,###', 'vi_VN');
    final depositAmount = paymentType == "Cọc"
        ? (totalAmount * 0.2).toInt()
        : 0;
    final remainingAmount = totalAmount - depositAmount;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fieldName,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(address, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 6),
          Text(timeRange, style: const TextStyle(color: Colors.black87)),
          const SizedBox(height: 6),
          Text(
            "Tổng tiền: ${numberFormat.format(totalAmount)} VNĐ",
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          Row(children: [const Text("Hình thức: "), Text(paymentType)]),
          if (paymentType == "Cọc") ...[
            const SizedBox(height: 4),
            Text(
              "Đã cọc: ${numberFormat.format(depositAmount)} VNĐ",
              style: const TextStyle(color: Colors.blue),
            ),
            Text(
              "Còn lại: ${numberFormat.format(remainingAmount)} VNĐ",
              style: const TextStyle(color: Colors.orange),
            ),
          ],

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 10),

          Center(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: QrImageView(
                data: "$fieldName|$timeRange|$txCode",
                size: MediaQuery.of(context).size.width * 0.45,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),

          Center(
            child: Column(
              children: [
                Text(
                  _formatDuration(_remaining),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Trạng thái giao dịch: Đang chờ xác nhận",
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButtonsQR() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _onConfirmPayment,
              child: const Text("Xác nhận"),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _onCancelPressed,
              child: const Text("Hủy"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingScreen() {
    return Center(
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.access_time_outlined,
              size: 70,
              color: Colors.blue,
            ),
            const SizedBox(height: 10),
            const Text(
              "Đang chờ chủ sân xác nhận",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Số tiền cần thanh toán: ${NumberFormat('#,###', 'vi_VN').format(totalAmount)} VNĐ",
            ),
            const SizedBox(height: 4),
            Text(
              "Mã đơn: ${_bookingCode.isNotEmpty ? _bookingCode : txCode}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(
                      fieldId: widget.fieldId ?? 'unknown',
                      fieldName: widget.fieldName ?? fieldName,
                    ),
                  ),
                );
              },
              child: const Text("Liên hệ chủ sân"),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text("Quay lại"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCancelledScreen() {
    return Center(
      child: Container(
        width: 300,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.close, size: 70, color: Colors.red),
            const SizedBox(height: 10),
            const Text(
              "Thanh toán đã hủy",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text("Giao dịch đã bị hủy hoặc hết thời gian."),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _onBackToQR,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text("Tạo giao dịch mới"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: const Color(0xFFE7F0F9),
      body: SafeArea(
        child: SingleChildScrollView(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _state == PaymentState.showingQR
                ? Column(
                    key: const ValueKey('qr'),
                    children: [_buildPaymentCard(), _buildBottomButtonsQR()],
                  )
                : _state == PaymentState.waitingConfirmation
                ? _buildWaitingScreen()
                : _buildCancelledScreen(),
          ),
        ),
      ),
    );
  }
}
