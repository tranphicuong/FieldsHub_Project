import 'package:flutter/material.dart';

class DanhGiaCuaToiScreen extends StatelessWidget {
  const DanhGiaCuaToiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> danhGiaList = [
      {
        "ten": "Trương Ngọc Doanh",
        "soHieu": "8891",
        "note": "Khách hàng có 1 số chú ý",
        "gia": "350.000đ",
        "comment": "Dịch vụ chăm sóc khách hàng tốt, bàn đánh oke, giá thành ổn",
        "diaChi": "702, Võ Văn Ngân, phường Hiệp Phú, TP Thủ Đức",
        "rating": 5.0,
      },
      {
        "ten": "Trương Ngọc Doanh",
        "soHieu": "8891",
        "note": "Khách hàng có 1 số chú ý",
        "gia": "350.000đ",
        "comment": "Dịch vụ rất tốt, nhân viên thân thiện, sân đẹp",
        "diaChi": "702, Võ Văn Ngân, phường Hiệp Phú, TP Thủ Đức",
        "rating": 4.5,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFD7EDFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD7EDFF),
        elevation: 0,
        title: const Text(
          "Đánh giá của Tôi",
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 1,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
              icon: const Icon(Icons.warning_amber_rounded,
                  color: Colors.blueAccent, size: 18),
              label: const Text(
                "Báo lỗi",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),

      // --- BODY ---
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            // --- Thẻ đánh giá tổng quan ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 5,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("Đánh Giá Tổng quan",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 6),
                        Text("Tiếp tục giữ vững phong độ bạn nhé",
                            style:
                                TextStyle(color: Colors.grey, fontSize: 14)),
                        SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 20),
                            Icon(Icons.star, color: Colors.amber, size: 20),
                            Icon(Icons.star, color: Colors.amber, size: 20),
                            Icon(Icons.star, color: Colors.amber, size: 20),
                            Icon(Icons.star_half, color: Colors.amber, size: 20),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("4.9",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 26)),
                      Icon(Icons.star, color: Colors.amber, size: 28),
                      Text("202 comments",
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 15),

            // --- Bộ lọc đánh giá ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("Đánh giá của khách hàng",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text("All  ⭐ 5  ⭐ 4  ⭐ 3  ⭐ 2  ⭐ 1",
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),

            const SizedBox(height: 10),

            // --- Danh sách đánh giá ---
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: danhGiaList.length,
              itemBuilder: (context, index) {
                final item = danhGiaList[index];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 5,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Header ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item['ten'],
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            item['soHieu'],
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),
                      Text(
                        "Note: ${item['note']}",
                        style: const TextStyle(
                            color: Colors.red, fontWeight: FontWeight.w500),
                      ),
                      Text("Giá: ${item['gia']}",
                          style: const TextStyle(
                              color: Colors.black, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text("Comment: ${item['comment']}"),
                      const SizedBox(height: 4),
                      Text(item['diaChi'],
                          style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),

                      // --- Nút và sao ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              minimumSize: const Size(60, 30),
                            ),
                            child: const Text("Bida",
                                style: TextStyle(color: Colors.white)),
                          ),
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                i < item['rating'] ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
