import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fieldshub/user/payment_screen.dart';
import 'package:fieldshub/user/chat_screen.dart';

class FieldBookingCard extends StatefulWidget {
  final Map<String, dynamic> fieldData;
  final String fieldId;

  const FieldBookingCard({
    Key? key,
    required this.fieldData,
    required this.fieldId,
  }) : super(key: key);

  @override
  State<FieldBookingCard> createState() => _FieldBookingCardState();
}

class _FieldBookingCardState extends State<FieldBookingCard> {
  DateTime? selectedDate;
  String? selectedTime;
  String paymentMethod = 'Cọc';
  Set<String> bookedSlots = {};
  final List<String> timeSlots = _generateHalfHourSlots();

  static List<String> _generateHalfHourSlots() {
    final slots = <String>[];
    for (int h = 0; h < 24; h++) {
      for (int m = 0; m < 60; m += 30) {
        slots.add(
          '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}',
        );
      }
    }
    return slots;
  }

  Future<void> _fetchBookedSlots(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final fieldRef = FirebaseFirestore.instance
          .collection('fields')
          .doc(widget.fieldId);

      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('field_id', isEqualTo: fieldRef)
          .get();

      final slots = <String>{};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final ts = data['start_time'] as Timestamp?;
        final status = data['status'] as String?;

        if (ts == null || status == null) continue;
        if (!['Chờ xác nhận', 'Đã xác nhận'].contains(status)) continue;

        final dt = ts.toDate();
        if (dt.isAfter(startOfDay) && dt.isBefore(endOfDay)) {
          slots.add(dt.toString().substring(11, 16));
        }
      }
      setState(() => bookedSlots = slots);
    } catch (e) {
      debugPrint('Lỗi lấy slot: $e');
    }
  }

  Future<double> _getFieldPrice() async {
    try {
      final pricesRef = FirebaseFirestore.instance.collection('prices');
      final fieldRef = FirebaseFirestore.instance
          .collection('fields')
          .doc(widget.fieldId);
      final snapshot = await pricesRef
          .where('field_id', isEqualTo: fieldRef)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        final price = snapshot.docs.first['price_amount'];
        if (price is num) return price.toDouble();
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  void _resetSelection() {
    setState(() {
      selectedDate = null;
      selectedTime = null;
      paymentMethod = 'Cọc';
      bookedSlots.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.fieldData;
    final name = data['name'] ?? 'Không tên';
    final description = data['description'] ?? '';
    final ownerId = data['owner_id']?.toString() ?? '';

    String openTime = '—', closeTime = '—';
    try {
      final openRaw = data['open_time'];
      if (openRaw is Timestamp)
        openTime = openRaw.toDate().toString().substring(11, 16);
      else if (openRaw is String)
        openTime = openRaw;

      final closeRaw = data['close_time'];
      if (closeRaw is Timestamp)
        closeTime = closeRaw.toDate().toString().substring(11, 16);
      else if (closeRaw is String)
        closeTime = closeRaw;
    } catch (e) {}

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 6,
      child: ExpansionTile(
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                "https://cdn.tuoitre.vn/471584752817336320/2023/12/28/san-bong-da-17037384362191179016543.jpg",
                width: 100,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 100,
                  height: 80,
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Giờ mở cửa: $openTime - $closeTime",
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  FutureBuilder<double>(
                    future: _getFieldPrice(),
                    builder: (context, snapshot) {
                      final price = snapshot.data ?? 0;
                      return Text(
                        "Giá: ${NumberFormat('#,###', 'vi_VN').format(price)} VNĐ/giờ",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      
                      OutlinedButton.icon(
                        
                        onPressed: () {
                          
                          
                          if (ownerId.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Không tìm thấy chủ sân"),
                              ),
                            );
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                fieldId: widget.fieldId,
                                fieldName: name,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_outline, size: 16),
                        label: const Text("Chat"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue,
                          side: const BorderSide(color: Colors.blue),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("Đánh giá sân"),
                              content: const Text(
                                "Chưa có đánh giá nào.\nTính năng đang được phát triển.",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text("Đóng"),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: const Icon(Icons.star_outline, size: 16),
                        label: const Text("Đánh giá"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange,
                          side: const BorderSide(color: Colors.orange),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        children: [
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedDate == null
                          ? "Chưa chọn ngày"
                          : "Ngày: ${DateFormat('dd/MM/yyyy').format(selectedDate!)}",
                      style: const TextStyle(fontSize: 14),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(
                            const Duration(days: 30),
                          ),
                        );
                        if (picked != null) {
                          setState(() => selectedDate = picked);
                          await _fetchBookedSlots(picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: const Text("Chọn ngày"),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                const Text(
                  "Chọn giờ:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: timeSlots.map((time) {
                      final isBooked = bookedSlots.contains(time);
                      final isStart = selectedTime?.startsWith(time) ?? false;
                      final isEnd = selectedTime?.endsWith(time) ?? false;
                      return GestureDetector(
                        onTap: isBooked
                            ? null
                            : () {
                                setState(() {
                                  if (selectedTime == null) {
                                    selectedTime = "$time - ?";
                                  } else if (selectedTime!.endsWith('?')) {
                                    final start = selectedTime!.split(' - ')[0];
                                    final end =
                                        timeSlots.indexOf(time) >=
                                            timeSlots.indexOf(start)
                                        ? time
                                        : start;
                                    selectedTime = "$start - $end";
                                  } else {
                                    selectedTime = "$time - ?";
                                  }
                                });
                              },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isBooked
                                ? Colors.grey[300]
                                : (isStart || isEnd)
                                ? Colors.blue
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            time,
                            style: TextStyle(
                              color: isBooked
                                  ? Colors.grey[600]
                                  : (isStart || isEnd)
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                if (selectedTime != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      "Đã chọn: $selectedTime",
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                const SizedBox(height: 12),
                const Text(
                  "Hình thức thanh toán:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    Radio<String>(
                      value: "Cọc",
                      groupValue: paymentMethod,
                      onChanged: (v) => setState(() => paymentMethod = v!),
                    ),
                    const Text("Cọc 20%"),
                    const SizedBox(width: 20),
                    Radio<String>(
                      value: "Trả hết",
                      groupValue: paymentMethod,
                      onChanged: (v) => setState(() => paymentMethod = v!),
                    ),
                    const Text("Trả hết"),
                  ],
                ),

                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () async {
                      if (selectedDate == null ||
                          selectedTime == null ||
                          selectedTime!.endsWith('?')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Vui lòng chọn ngày và giờ"),
                          ),
                        );
                        return;
                      }

                      final parts = selectedTime!.split(' - ');
                      final start = DateTime(
                        selectedDate!.year,
                        selectedDate!.month,
                        selectedDate!.day,
                        int.parse(parts[0].split(':')[0]),
                        int.parse(parts[0].split(':')[1]),
                      );
                      final end = parts.length > 1 && parts[1] != '?'
                          ? DateTime(
                              selectedDate!.year,
                              selectedDate!.month,
                              selectedDate!.day,
                              int.parse(parts[1].split(':')[0]),
                              int.parse(parts[1].split(':')[1]),
                            )
                          : start.add(const Duration(hours: 1));

                      final pricePerHour = await _getFieldPrice();
                      final hours = end.difference(start).inMinutes / 60.0;
                      final amount = pricePerHour * hours;

                      String address = data['address'] ?? '';
                      if (address.isEmpty) {
                        final fieldDoc = await FirebaseFirestore.instance
                            .collection('fields')
                            .doc(widget.fieldId)
                            .get();
                        final areaRef = fieldDoc.data()?['area_id'];
                        if (areaRef != null) {
                          final areaDoc = areaRef is DocumentReference
                              ? await areaRef.get()
                              : await FirebaseFirestore.instance
                                    .collection('areas')
                                    .doc(areaRef)
                                    .get();
                          address =
                              (areaDoc.data()
                                  as Map<String, dynamic>?)?['address'] ??
                              'Không có địa chỉ';
                        }
                      }

                      // RESET SAU KHI CHUYỂN
                      _resetSelection();

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PaymentPage(
                            amount: amount,
                            paymentMethod: paymentMethod,
                            fieldId: widget.fieldId,
                            startTime: start,
                            endTime: end,
                            fieldName: name,
                            address: address,
                          ),
                        ),
                      );
                    },
                    child: const Text("Xác nhận đặt sân"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
