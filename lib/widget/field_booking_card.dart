import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fieldshub/user/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';
import 'package:fieldshub/user/review_screen.dart';
import 'package:fieldshub/user/payment_screen.dart';
import 'package:fieldshub/Database/database.dart';

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
        final startTs = data['start_time'] as Timestamp?;
        final endTs = data['end_time'] as Timestamp?;
        final status = data['status'] as String?;

        if (startTs == null || endTs == null || status == null) continue;
        if (![
          'Chờ xác nhận',
          'Đã xác nhận',
          'Đã thanh toán',
          'Đang sử dụng',
        ].contains(status))
          continue;

        final startDt = startTs.toDate();
        final endDt = endTs.toDate();

        if (startDt.isBefore(endOfDay) && endDt.isAfter(startOfDay)) {
          DateTime current = DateTime(
            startDt.year,
            startDt.month,
            startDt.day,
            startDt.hour,
            startDt.minute,
          );

          while (current.isBefore(endDt)) {
            final slot = current.toString().substring(11, 16);
            slots.add(slot);
            current = current.add(const Duration(minutes: 30));
          }
        }
      }

      if (mounted) {
        setState(() {
          bookedSlots = slots;
          selectedTime = null;
        });
      }
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
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 8,
      clipBehavior: Clip.hardEdge,
      child: ExpansionTile(
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                data['image']?.toString().isNotEmpty == true
                    ? data['image']
                    : "https://cdn.tuoitre.vn/471584752817336320/2023/12/28/san-bong-da-17037384362191179016543.jpg",
                width: 100,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 100,
                  height: 80,
                  color: Colors.grey[300],
                  child: const Icon(Icons.sports_soccer, color: Colors.grey),
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

                  FutureBuilder<double>(
                    future: Database.getFieldAverageRating(widget.fieldId),
                    builder: (context, snapshot) {
                      final rating = snapshot.data ?? 0.0;
                      return Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          RatingBarIndicator(
                            rating: rating,
                            itemBuilder: (context, _) =>
                                const Icon(Icons.star, color: Colors.amber),
                            itemSize: 16,
                            itemCount: 5,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating > 0 ? rating.toStringAsFixed(1) : "Chưa có",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (rating > 0)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Text(
                                "• Đã có đánh giá",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
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
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
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

                          label: const Text("Chat"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue,
                            side: const BorderSide(color: Colors.blue),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ReviewScreen(
                                  fieldId: widget.fieldId,
                                  bookingId: '',
                                  fieldName: name,
                                  fieldImage: data['image'] ?? '',
                                ),
                              ),
                            );
                          },

                          label: const Text("Xem đánh giá"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange,
                            side: const BorderSide(color: Colors.orange),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
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
                      icon: const Icon(Icons.calendar_today, size: 13),
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
                                    final startIndex = timeSlots.indexOf(start);
                                    final endIndex = timeSlots.indexOf(time);

                                    if (endIndex <= startIndex) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Giờ kết thúc phải sau giờ bắt đầu",
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                          margin: const EdgeInsets.only(
                                            bottom: 50,
                                            left: 20,
                                            right: 20,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    for (
                                      int i = startIndex;
                                      i < endIndex;
                                      i++
                                    ) {
                                      if (bookedSlots.contains(timeSlots[i])) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "Khung giờ này đã được đặt!",
                                            ),
                                            behavior: SnackBarBehavior.floating,
                                            margin: const EdgeInsets.only(
                                              bottom: 50,
                                              left: 20,
                                              right: 20,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                    }

                                    selectedTime = "$start - $time";
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
                                : Colors.green[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isBooked
                                  ? Colors.grey
                                  : (isStart || isEnd)
                                  ? Colors.blue
                                  : Colors.green,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                time,
                                style: TextStyle(
                                  color: isBooked
                                      ? Colors.grey[600]
                                      : (isStart || isEnd)
                                      ? Colors.white
                                      : Colors.green[800],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (isBooked) ...[const SizedBox(width: 4)],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                if (selectedTime != null && !selectedTime!.endsWith('?'))
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Đã chọn:",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue),
                          ),
                          child: Text(
                            selectedTime!,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ],
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
                          SnackBar(
                            content: Text("Vui lòng chọn đầy đủ khung giờ"),
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
                        return;
                      }

                      final parts = selectedTime!.split(' - ');
                      final startStr = parts[0];
                      final endStr = parts[1];
                      final startIdx = timeSlots.indexOf(startStr);
                      final endIdx = timeSlots.indexOf(endStr);

                      for (int i = startIdx; i < endIdx; i++) {
                        if (bookedSlots.contains(timeSlots[i])) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Khung giờ đã bị đặt! Vui lòng chọn lại.",
                              ),
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
                          return;
                        }
                      }

                      final start = DateTime(
                        selectedDate!.year,
                        selectedDate!.month,
                        selectedDate!.day,
                        int.parse(startStr.split(':')[0]),
                        int.parse(startStr.split(':')[1]),
                      );
                      final end = DateTime(
                        selectedDate!.year,
                        selectedDate!.month,
                        selectedDate!.day,
                        int.parse(endStr.split(':')[0]),
                        int.parse(endStr.split(':')[1]),
                      );

                      final pricePerHour = await _getFieldPrice();
                      if (pricePerHour <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Không lấy được giá sân"),
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
                        return;
                      }

                      final hours = end.difference(start).inMinutes / 60.0;
                      final totalAmount = pricePerHour * hours;
                      final depositAmount = paymentMethod == "Cọc"
                          ? totalAmount * 0.2
                          : totalAmount;

                      String address = data['address'] ?? '';
                      if (address.isEmpty) {
                        try {
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
                        } catch (e) {
                          address = 'Không có địa chỉ';
                        }
                      }

                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PaymentPage(
                            amount: depositAmount,
                            totalAmount: totalAmount,
                            paymentMethod: paymentMethod,
                            fieldId: widget.fieldId,
                            startTime: start,
                            endTime: end,
                            fieldName: name,
                            address: address,
                          ),
                        ),
                      ).then((_) {
                        _resetSelection();
                      });
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