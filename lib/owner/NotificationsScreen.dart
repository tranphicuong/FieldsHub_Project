import 'package:flutter/material.dart';


class NotificationsMainScreen extends StatefulWidget {
  const NotificationsMainScreen({super.key});

  @override
  State<NotificationsMainScreen> createState() => _NotificationsMainScreenState();
}

class _NotificationsMainScreenState extends State<NotificationsMainScreen> {
  // Danh sách trạng thái mở/đóng cho từng thông báo
  final List<bool> _expanded = [false, false];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB7D8F9),
      appBar: AppBar(
        title: const Text('Thông báo'),
        backgroundColor: const Color(0xFF004A8E),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildNotificationCard(
            context,
            index: 0,
            title: 'Thông tin đặt sân ngày 22/09/2025',
            shortText: 'Xác nhận đặt sân thành công\nSân TDC ...',
            fullText:
                'Xác nhận đặt sân thành công\nSân TDC Thủ Đức\nĐịa chỉ: 456 Lê Văn Việt, Thủ Đức\nKhung giờ: 19:00 - 21:00\nThanh toán: Chuyển khoản',
          ),
          _buildNotificationCard(
            context,
            index: 1,
            title: 'Thông tin đặt sân ngày 20/09/2025',
            shortText:
                'Xác nhận đặt sân thành công\nSân TDC Thủ Đức\nĐịa chỉ: 123 Nguyễn Thượng Hiền...',
            fullText:
                'Xác nhận đặt sân thành công\nSân TDC Thủ Đức\nĐịa chỉ: 123 Nguyễn Thượng Hiền, P5\nKhung giờ: 18:30 - 20:00\nHình thức thanh toán: Trả hết\nGhi chú: Sân 7 người',
          ),
        ],
      ),
      
);

  }

  Widget _buildNotificationCard(
    BuildContext context, {
    required int index,
    required String title,
    required String shortText,
    required String fullText,
  }) {
    final bool isExpanded = _expanded[index];

    return GestureDetector(
      onTap: () {
        setState(() {
          _expanded[index] = !isExpanded;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 3))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),

            // Hiển thị nội dung ngắn hoặc đầy đủ
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: Text(shortText),
              secondChild: Text(fullText),
            ),

            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerRight,
              child: Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                color: const Color(0xFF004A8E),
              ),
            )
          ],
        ),
      ),
    );
  }
}
