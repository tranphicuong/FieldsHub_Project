import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:fieldshub/user/chat_screen.dart';
import 'package:fieldshub/Database/database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentPage extends StatefulWidget {
  final String? bookingId;
  final double amount;          // TIỀN CẦN THANH TOÁN (20% hoặc 100%)
  final double totalAmount;     // TỔNG TIỀN
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
    required this.totalAmount,
    required this.paymentMethod,
    this.fieldId,
    this.startTime,
    this.endTime,
    this.fieldName,
    this.address,
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
  String? _paymentId;

  String fieldName = 'Đang tải...';
  String address = '—';
  String timeRange = '—';
  String txCode = '';
  String paymentType = '';
  String _bookingCode = '';

  @override
  void initState() {
    super.initState();

    if (widget.startTime == null || widget.endTime == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Dữ liệu đặt sân không hợp lệ")),
        );
        Navigator.pop(context);
      });
      return;
    }

    paymentType = widget.paymentMethod;
    txCode = "#${DateTime.now().millisecondsSinceEpoch.toString().substring(0, 6)}";
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
      final data = await Database.getBooking(idToLoad);
      if (data != null && mounted) {
        final fetchedAddress = await Database.getFieldAddress(widget.fieldId?? '');
        setState(() {
          fieldName = data['field_name'] ?? widget.fieldName ?? 'Không tên';
          address = fetchedAddress;
          try {
            final start = (data['start_time'] as Timestamp).toDate();
            final end = (data['end_time'] as Timestamp).toDate();
            timeRange =
                "${start.toString().substring(11, 16)} - ${end.toString().substring(11, 16)}, ${DateFormat('dd/MM/yyyy').format(start)}";
          } catch (_) {}
        });
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
    return '#FH${List.generate(6, (_) => chars[rnd.nextInt(chars.length)]).join()}';
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

  void _onConfirmPayment() async {
  setState(() => _state = PaymentState.waitingConfirmation);

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  String? errorMsg;
  final bookingCode = _generateBookingCode();

  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Vui lòng đăng nhập');

    final fetchedAddress =
        widget.address ?? await Database.getFieldAddress(widget.fieldId ?? '' );

    final qrData = "$fieldName|$timeRange|$txCode";
    final qrUrl =
        "https://api.qrserver.com/v1/create-qr-code/?data=${Uri.encodeComponent(qrData)}&size=300x300";

    final bookingId = await Database.createBooking(
      userId: user.uid,
      fieldId: widget.fieldId,
      fieldName: widget.fieldName ?? '',
      address: fetchedAddress,
      startTime: widget.startTime!,
      endTime: widget.endTime!,
      price: widget.amount,
      paymentMethod: widget.paymentMethod,
      bookingCode: bookingCode,
    );

    _localBookingId = bookingId;

    final paymentId = await Database.createPayment(
      bookingId: bookingId,
      amount: widget.amount,
      qrCodeUrl: qrUrl,
      statusKey: 'pending',
    );

    _paymentId = paymentId;
    if (mounted) setState(() => _bookingCode = bookingCode);

    await Database.sendNotification(
      userId: user.uid,
      title: 'Yêu cầu thanh toán đã gửi',
      subtitle: 'Vui lòng thanh toán qua mã QR',
      fieldName: widget.fieldName,
      address: fetchedAddress,
      timeSlot: timeRange,
      paymentMethod: widget.paymentMethod,
      bookingCode: bookingCode,
    );

    final ownerId = await Database.getFieldOwnerId(widget.fieldId!);
    if (ownerId != null) {
      await Database.sendNotification(
        userId: ownerId,
        title: 'Yêu cầu thanh toán mới',
        subtitle: 'Khách đã tạo mã QR thanh toán',
        fieldName: widget.fieldName,
        address: fetchedAddress,
        timeSlot: timeRange,
        paymentMethod: widget.paymentMethod,
      );
    }

    if (mounted) {
      Navigator.pop(context);
    }
  } catch (e) {
    errorMsg = e.toString();
  }

  if (mounted && errorMsg != null) {
    Navigator.pop(context); 
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Lỗi'),
        content: Text(errorMsg ?? 'Đã có lỗi xảy ra. Vui lòng thử lại.'),
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
  Future<void> _updateBookingStatus(String statusKey) async {
    final id = widget.bookingId ?? _localBookingId;
    if (id == null) return;

    try {
      await Database.updateBookingStatus(bookingId: id, statusKey: statusKey);

      final paymentData = await Database.getPaymentByBookingId(id);
      if (paymentData != null) {
        final paymentSnap = await FirebaseFirestore.instance
            .collection('payments')
            .where(
              'booking_id',
              isEqualTo: FirebaseFirestore.instance
                  .collection('bookings')
                  .doc(id),
            )
            .limit(1)
            .get();

        if (paymentSnap.docs.isNotEmpty) {
          final paymentId = paymentSnap.docs.first.id;
          await Database.updatePaymentStatus(
            paymentId: paymentId,
            statusKey: statusKey == 'paid' ? 'paid' : 'cancelled',
          );
        }
      }

      if (statusKey == 'cancelled') {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await Database.sendNotification(
            userId: user.uid,
            title: 'Thanh toán đã hủy',
            subtitle: 'Giao dịch đã bị hủy hoặc hết hạn',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Future<void> _onCancelPressed() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
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

    if (result == true && mounted) {
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
    );
  }

  Widget _buildPaymentCard() {
    final numberFormat = NumberFormat('#,###', 'vi_VN');
    final depositAmount = paymentType == "Cọc" ? widget.amount.toInt() : 0;
    final remainingAmount = widget.totalAmount.toInt() - depositAmount;

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
          Text(fieldName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(address, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 6),
          Text(timeRange, style: const TextStyle(color: Colors.black87)),
          const SizedBox(height: 6),
          Text(
            "Tổng tiền: ${numberFormat.format(widget.totalAmount.toInt())} VNĐ",
            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(children: [const Text("Hình thức: "), Text(paymentType)]),

          if (paymentType == "Cọc") ...[
            const SizedBox(height: 4),
            Text("Đã cọc: ${numberFormat.format(depositAmount)} VNĐ", style: const TextStyle(color: Colors.blue)),
            Text("Còn lại: ${numberFormat.format(remainingAmount)} VNĐ", style: const TextStyle(color: Colors.orange)),
          ],

          if (paymentType == "Trả hết") ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: const Text("Thanh toán toàn bộ", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
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
                Text(_formatDuration(_remaining), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("Trạng thái giao dịch: Đang chờ xác nhận", style: TextStyle(color: Colors.grey.shade700, fontSize: 14)),
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
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _onConfirmPayment,
              child: const Text("Xác nhận", style: TextStyle(fontSize: 16)),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.access_time_outlined, size: 70, color: Colors.blue),
            const SizedBox(height: 10),
            const Text("Đang chờ chủ sân xác nhận", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Số tiền: ${NumberFormat('#,###', 'vi_VN').format(widget.totalAmount.toInt())} VNĐ"),
            const SizedBox(height: 4),
            Text("Mã đơn: ${_bookingCode.isNotEmpty ? _bookingCode : txCode}", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
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
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text("Quay lại trang chủ"),
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
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.close, size: 70, color: Colors.red),
            const SizedBox(height: 10),
            const Text("Thanh toán đã hủy", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Giao dịch đã bị hủy hoặc hết thời gian."),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _onBackToQR,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
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
                ? Column(key: const ValueKey('qr'), children: [_buildPaymentCard(), _buildBottomButtonsQR()])
                : _state == PaymentState.waitingConfirmation
                    ? _buildWaitingScreen()
                    : _buildCancelledScreen(),
          ),
        ),
      ),
    );
  }
}