import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fieldshub/user/chat_screen.dart';
import 'package:fieldshub/Database/database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentPage extends StatefulWidget {
  final double amount;
  final double totalAmount;
  final String paymentMethod;
  final String? fieldId;
  final DateTime startTime;
  final DateTime endTime;
  final String? fieldName;
  final String? address;

  const PaymentPage({
    super.key,
    required this.amount,
    required this.totalAmount,
    required this.paymentMethod,
    required this.fieldId,
    required this.startTime,
    required this.endTime,
    this.fieldName,
    this.address,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  Duration _remaining = const Duration(minutes: 15);
  Timer? _timer;
  StreamSubscription<DocumentSnapshot>? _listener;

  String _bookingCode = '';
  String _qrUrl = '';
  String _pendingId = '';
  bool _isPaid = false;
  bool _isLoading = true;

  final NumberFormat fmt = NumberFormat('#,###', 'vi_VN');
  final CollectionReference _statusRef = FirebaseFirestore.instance.collection(
    'status',
  );

  @override
  void initState() {
    super.initState();
    _bookingCode = _generateCode();
    _createPendingImmediately();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _listener?.cancel();
    super.dispose();
  }

  String _generateCode() {
    const chars = '0123456789';
    final rnd = Random.secure();
    return '#FH${List.generate(6, (_) => chars[rnd.nextInt(chars.length)]).join()}';
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() {
        if (_remaining.inSeconds <= 0 && !_isPaid) {
          t.cancel();
          _cancelPending();
          Navigator.pop(context);
        } else {
          _remaining -= const Duration(seconds: 1);
        }
      });
    });
  }

  String _formatTime(Duration d) =>
      '${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  
  Future<void> _createPendingImmediately() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final ownerId = await Database.getFieldOwnerId(widget.fieldId!);
      if (ownerId == null) throw "Không tìm thấy chủ sân";

      final ownerDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(ownerId)
          .get();
      final ownerData = ownerDoc.data() ?? {};
      final bankBin = (ownerData['bank_bin'] ?? '').toString().trim();
      final bankAccount = (ownerData['bank_account'] ?? '').toString().trim();
      final ownerName = ownerData['name']?.toString().trim().isNotEmpty == true
          ? ownerData['name']
          : "CHU SAN";

      if (bankBin.isEmpty || bankAccount.isEmpty) {
        throw "Chủ sân chưa cập nhật ngân hàng";
      }

      final bankMap = {
        "970415": "techcombank",
        "970423": "bidv",
        "970426": "vietinbank",
        "970432": "vpbank",
        "970436": "vietcombank",
        "970437": "mb",
        "970454": "acb",
        "970407": "agribank",
        "970456": "sacombank",
      };
      final shortName = bankMap[bankBin] ?? "vietcombank";

      final qrUrl =
          "https://img.vietqr.io/image/$shortName-$bankAccount-compact2.png?"
          "amount=${widget.amount.toInt()}&addInfo=${Uri.encodeComponent(_bookingCode)}&accountName=${Uri.encodeComponent(ownerName)}";

      // TẠO DOCUMENT PENDING NGAY
      final ref = await FirebaseFirestore.instance
          .collection('pending_payments')
          .add({
            'booking_code': _bookingCode,
            'amount': widget.amount.toInt(),
            'user_id': user.uid,
            'owner_id': ownerId,
            'field_id': widget.fieldId,
            'field_name': widget.fieldName ?? 'Sân bóng',
            'address': widget.address ?? '',
            'start_time': Timestamp.fromDate(widget.startTime),
            'end_time': Timestamp.fromDate(widget.endTime),
            'total_amount': widget.totalAmount,
            'deposit_amount': widget.amount,
            'payment_method': widget.paymentMethod,
            'qr_url': qrUrl,
            'status_id': _statusRef.doc('1'),
            'status': 'Chờ xác nhận',
            'created_at': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;
      setState(() {
        _qrUrl = qrUrl;
        _pendingId = ref.id;
        _isLoading = false;
      });
      try {
        final ownerId = await Database.getFieldOwnerId(widget.fieldId!);
        if (ownerId != null && ownerId != user.uid) {
          await Database.sendNotification(
            userId: ownerId,
            title: "Có đơn đặt sân mới!",
            subtitle:
                "Sân: ${widget.fieldName ?? 'Sân bóng'}\n"
                "Địa chỉ: ${widget.address ?? ''}\n"
                "Giờ: ${DateFormat('HH:mm').format(widget.startTime)} - ${DateFormat('HH:mm').format(widget.endTime)}\n"
                "Ngày: ${DateFormat('dd/MM/yyyy').format(widget.startTime)}\n"
                "Mã đặt: $_bookingCode\n"
                "Tiền cọc: ${fmt.format(widget.amount.toInt())}₫\n"
                "Hình thức: ${widget.paymentMethod == 'Cọc' ? 'Chuyển khoản cọc' : 'Thanh toán toàn bộ'}",
            bookingCode: _bookingCode,
          );
        }
      } catch (e) {
        debugPrint("Lỗi gửi thông báo cho chủ sân: $e");
      }
      _listener = ref.snapshots().listen((snapshot) async {
        if (!snapshot.exists || _isPaid || !mounted) return;
        final statusRef = snapshot.get('status_id') as DocumentReference?;
        if (statusRef?.path == 'status/2') {
          setState(() => _isPaid = true);
          _timer?.cancel();
          await _createRealBooking();
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
        );
        Navigator.pop(context);
      }
    }
  }

  
  Future<void> _createRealBooking() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final address =
          widget.address ?? await Database.getFieldAddress(widget.fieldId!);

      final bookingId = await Database.createBooking(
        userId: user.uid,
        fieldId: widget.fieldId,
        fieldName: widget.fieldName ?? '',
        address: address,
        startTime: widget.startTime,
        endTime: widget.endTime,
        totalAmount: widget.totalAmount,
        depositAmount: widget.amount,
        paymentMethod: widget.paymentMethod,
        bookingCode: _bookingCode,
      );

      await Database.createPayment(
        bookingId: bookingId,
        amount: widget.amount,
        qrCodeUrl: _qrUrl,
        statusKey: 'paid',
      );

      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .update({
            'status_id': _statusRef.doc('2'),
            'status': 'Đã xác nhận',
            'updated_at': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Thanh toán thành công! Đơn đã được tạo"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 50, left: 20, right: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  Future<void> _cancelPending() async {
    if (_pendingId.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('pending_payments')
          .doc(_pendingId)
          .update({
            'status_id': _statusRef.doc('3'), // 3 = Đã hủy
            'status': 'Đã hủy',
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thanh toán "),
        backgroundColor: const Color(0xFF0B5EA8),
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFE7F0F9),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.fieldName ?? 'Sân bóng',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.address ?? '',
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "${DateFormat('HH:mm').format(widget.startTime)} - ${DateFormat('HH:mm').format(widget.endTime)} • ${DateFormat('dd/MM/yyyy').format(widget.startTime)}",
                            style: const TextStyle(fontSize: 18),
                          ),
                          const Divider(height: 32),
                          Text(
                            "Số tiền: ${fmt.format(widget.amount.toInt())} ₫",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Hình thức: ${widget.paymentMethod}",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          const Text(
                            "QUÉT MÃ ĐỂ CHUYỂN KHOẢN",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              _qrUrl,
                              width: 280,
                              height: 280,
                              fit: BoxFit.contain,
                              loadingBuilder: (_, child, __) => child,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.error,
                                size: 80,
                                color: Colors.red,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SelectableText(
                            "Nội dung: $_bookingCode",
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 30),
                          Text(
                            _formatTime(_remaining),
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const Text("Thời gian còn lại"),
                          const SizedBox(height: 20),
                          if (!_isPaid) ...[
                            const CircularProgressIndicator(),
                            const SizedBox(height: 12),
                            const Text(
                              "Đang chờ chủ sân xác nhận...",
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ] else ...[
                            const Icon(
                              Icons.check_circle,
                              size: 80,
                              color: Colors.green,
                            ),
                            const Text(
                              "ĐÃ NHẬN TIỀN – ĐƠN ĐÃ TẠO!",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.chat),
                          label: const Text("Liên hệ chủ sân"),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                fieldId: widget.fieldId!,
                                fieldName: widget.fieldName ?? '',
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () async {
                          final bool? confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              title: const Row(
                                children: [
                                  Icon(
                                    Icons.warning_amber_rounded,
                                    color: Colors.orange,
                                    size: 28,
                                  ),
                                  SizedBox(width: 10),
                                  Text("Xác nhận hủy đặt sân?"),
                                ],
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Bạn có chắc muốn hủy đơn đặt sân này không?",
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "• Mã đặt: $_bookingCode\n• Số tiền: ${fmt.format(widget.amount.toInt())}₫",
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "Sau khi hủy, bạn sẽ không thể khôi phục lại đơn này.",
                                    style: TextStyle(
                                      color: Colors.red[600],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text(
                                    "Giữ lại",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: const Text(
                                    "Hủy đơn",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await _cancelPending();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Đã hủy đơn đặt sân"),
                                  backgroundColor: Colors.orange,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              Navigator.pop(context);
                            }
                          }
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          "Hủy đơn",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}