import 'package:flutter/material.dart';
import 'ManageFieldScreen.dart'; // nhớ import file này

class DanhSachSanScreen extends StatefulWidget {
  const DanhSachSanScreen({super.key});

  @override
  State<DanhSachSanScreen> createState() => _DanhSachSanScreenState();
}

class _DanhSachSanScreenState extends State<DanhSachSanScreen> {
  // Danh sách sân (có thể sau này load từ database)
  List<Map<String, String>> sanList = [
    {
      "ten": "Trương Định: Số 2",
      "diaChi": "40/18 Gò Lấp, Tân Phú, HCM",
      "khungGio": "09:00 - 23:00",
      "gia": "150000",
      "soDienThoai": "0123456789",
      "coc": "50000",
      "ghiChu": "Sân có mái che"
    },
    {
      "ten": "Trị Thiên: Số 1",
      "diaChi": "20A Trị Thiện, Tân Phú, HCM",
      "khungGio": "06:00 - 22:00",
      "gia": "120000",
      "soDienThoai": "0987654321",
      "coc": "40000",
      "ghiChu": "Sân nhỏ, sạch sẽ"
    },
    {
      "ten": "Trị Thiên: Số 2",
      "diaChi": "20A Trị Thiện, Tân Phú, HCM",
      "khungGio": "08:00 - 22:30",
      "gia": "130000",
      "soDienThoai": "0911222333",
      "coc": "45000",
      "ghiChu": "Sân rộng, thoáng mát"
    },
  ];

  // Hàm xóa sân
  void _xoaSan(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text("Bạn có chắc muốn xóa sân này không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          TextButton(
            onPressed: () {
              setState(() {
                sanList.removeAt(index);
              });
              Navigator.pop(ctx);
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // Hàm sửa sân
  void _suaSan(Map<String, String> san) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ManageFieldScreen(fieldData: san)),
    );

    // Sau khi quay lại, có thể cập nhật lại danh sách nếu cần
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD7EDFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD7EDFF),
        elevation: 0,
        title: const Text(
          "Danh sách sân",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: ListView.builder(
          itemCount: sanList.length,
          itemBuilder: (context, index) {
            final item = sanList[index];
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['ten'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(item['diaChi'] ?? ''),
                  Text("Khung giờ: ${item['khungGio'] ?? ''}"),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: () => _suaSan(item),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          minimumSize: const Size(60, 35),
                        ),
                        child: const Text("Sửa", style: TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () => _xoaSan(index),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          minimumSize: const Size(60, 35),
                        ),
                        child: const Text("Xóa", style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
