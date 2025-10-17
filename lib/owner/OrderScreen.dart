import 'package:flutter/material.dart';

class OrdersMainScreen extends StatefulWidget {
  const OrdersMainScreen({super.key});

  @override
  State<OrdersMainScreen> createState() => _OrdersMainScreenState();
}

class _OrdersMainScreenState extends State<OrdersMainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> orders = [
    {
      "name": "Trương Ngọc Doanh",
      "phone": "0987-123-456",
      "note": "khách hàng có 3 số chú ý",
      "method": "Thanh Toán: 100.000vnđ",
      "time": "16:00(19/5/2025)-18:00(19/5/2025)",
      "address": "702, đường Nguyễn Giáp, phường Hiệp Phú, TP. Thủ Đức",
      "status": "Cọc trước",
      "statusColor": Colors.red,
      "type": "Bida",
      "id": "8891"
    },
    {
      "name": "Bùi Thành Nhật",
      "phone": "0987-123-456",
      "note": "khách hàng có 3 số chú ý",
      "method": "Thanh Toán: 350.000vnđ",
      "time": "16:00(19/5/2025)-18:00(19/5/2025)",
      "address": "702, Nguyễn Giáp, Hiệp Phú, Thủ Đức",
      "status": "Đã thanh toán",
      "statusColor": Colors.green,
      "type": "Bóng Đá",
      "id": "2211"
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( // ✅ Thay Container bằng Scaffold
      backgroundColor: const Color(0xFFB7D8F9),
      body: SafeArea(
        child: Column(
          children: [
            // --- AppBar tự thiết kế ---
            Container(
              color: const Color(0xFF004A8E),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Đơn đặt của tôi',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.blue, width: 1),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.warning_amber_rounded,
                            color: Colors.blue, size: 18),
                        SizedBox(width: 4),
                        Text(
                          "Báo lỗi",
                          style: TextStyle(color: Colors.blue, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // --- TabBar ---
            Container(
              color: const Color(0xFFE8F3FF),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.black87,
                indicator: BoxDecoration(
                  color: Colors.blue[700],
                  borderRadius: BorderRadius.circular(8),
                ),
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                tabs: const [
                  Tab(text: "Chờ xác nhận"),
                  Tab(text: "Đã xác nhận"),
                  Tab(text: "Đang sử dụng"),
                  Tab(text: "Lịch sử"),
                ],
              ),
            ),

            // --- Nội dung Tab ---
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOrderList("Chờ xác nhận"),
                  _buildOrderList("Đã xác nhận"),
                  _buildOrderList("Đang sử dụng"),
                  _buildOrderList("Lịch sử"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(String status) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(order["name"],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(order["id"],
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black54)),
                ],
              ),
              Text(order["phone"], style: const TextStyle(fontSize: 12)),
              Text("Note: ${order["note"]}",
                  style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Text("Phương thức thanh toán: ",
                      style: TextStyle(fontSize: 12)),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF3FB),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      order["method"],
                      style:
                          const TextStyle(fontSize: 12, color: Colors.black87),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 4),
              Text(order["time"],
                  style: const TextStyle(fontSize: 12, color: Colors.black87)),
              Text(order["address"],
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order["status"],
                    style: TextStyle(
                        color: order["statusColor"],
                        fontWeight: FontWeight.bold,
                        fontSize: 13),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[700],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      order["type"],
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  )
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
