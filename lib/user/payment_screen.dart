import 'dart:async';
import 'package:fieldshub/user/user_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({Key? key}) : super(key: key);

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

enum PaymentState { showingQR, waitingConfirmation, cancelled }

class _PaymentPageState extends State<PaymentPage> {
  PaymentState _state = PaymentState.showingQR;

  final String fieldName = "Sân TDC Thủ Đức";
  final String address = "123, Nguyễn Thường Hiền, P5";
  final String timeRange = "18:00 - 19:30, 24/09/2025";
  final int totalAmount = 104000;
  final String txCode = "#123456";

  String paymentType = "Cọc"; // "Cọc" hoặc "Trả hết"
  final int depositAmount = 40000; // Số tiền cọc

  Duration _remaining = const Duration(hours: 2);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
          _state = PaymentState.cancelled;
        }
      });
    });
  }

  String _formatDuration(Duration d) {
    final two = (int n) => n.toString().padLeft(2, '0');
    return "${two(d.inHours)}:${two(d.inMinutes.remainder(60))}:${two(d.inSeconds.remainder(60))}";
  }

  void _onConfirmPayment() => setState(() => _state = PaymentState.waitingConfirmation);

  Future<void> _onCancelPressed() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Thông báo"),
        content: const Text("Bạn có chắc chắn muốn hủy thanh toán không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Không")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Có"),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() => _state = PaymentState.cancelled);
      _timer?.cancel();
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
          /// --- THÔNG TIN SÂN ---
          Text(fieldName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(address, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 6),
          Text(timeRange, style: const TextStyle(color: Colors.black87)),
          const SizedBox(height: 6),
          Text(
            "Tổng tiền: ${numberFormat.format(totalAmount)} VNĐ",
            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          /// --- HÌNH THỨC THANH TOÁN ---
          Row(
            children: [
              const Text("Hình thức: "),
              DropdownButton<String>(
                value: paymentType,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: "Cọc", child: Text("Cọc")),
                  DropdownMenuItem(value: "Trả hết", child: Text("Trả hết")),
                ],
                onChanged: (val) {
                  setState(() => paymentType = val!);
                },
              ),
            ],
          ),
          if (paymentType == "Cọc") ...[
            const SizedBox(height: 4),
            Text("Đã cọc: ${numberFormat.format(depositAmount)} VNĐ",
                style: const TextStyle(color: Colors.blue)),
            Text("Còn lại: ${numberFormat.format(remainingAmount)} VNĐ",
                style: const TextStyle(color: Colors.orange)),
          ],

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 10),

          /// --- QR CODE ---
          Center(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: QrImageView(
                data: "$fieldName|$timeRange|${DateTime.now().millisecondsSinceEpoch}",
                size: MediaQuery.of(context).size.width * 0.45,
                backgroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),

          /// --- THỜI GIAN & TRẠNG THÁI ---
          Center(
            child: Column(
              children: [
                Text(
                  _formatDuration(_remaining),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            const Text("Đang chờ chủ sân xác nhận",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Số tiền cần thanh toán: ${NumberFormat('#,###', 'vi_VN').format(totalAmount)} VNĐ"),
            const SizedBox(height: 4),
            Text("Mã đơn: $txCode", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Đã gửi yêu cầu liên hệ chủ sân (demo).")),
                );
              },
              child: const Text("Liên hệ chủ sân"),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const UserHomeScreen()),
                );
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
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.close, size: 70, color: Colors.red),
            const SizedBox(height: 10),
            const Text("Thanh toán đã hủy",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                    children: [
                      _buildPaymentCard(),
                      _buildBottomButtonsQR(),
                    ],
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
