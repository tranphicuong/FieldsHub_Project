import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:fieldshub/owner/ManageFieldScreen.dart';
import 'package:fieldshub/owner/OrderScreen.dart';
import 'package:fieldshub/owner/RevenueReportScreen.dart';
import 'package:fieldshub/owner/ReviewScreen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F3FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF004A8E),
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: Colors.black),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "xin chào",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  "Nguyen Van A",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.chat_bubble_outline, color: Colors.white),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Just for you",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),

            // --- Đánh giá ---
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Đánh Giá Tháng 9",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "tiếp tục giữ vững phong độ bạn nhé",
                          style: TextStyle(fontSize: 13),
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber),
                            Icon(Icons.star, color: Colors.amber),
                            Icon(Icons.star, color: Colors.amber),
                            Icon(Icons.star, color: Colors.amber),
                            Icon(Icons.star_half, color: Colors.amber),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Column(
                    children: [
                      Text(
                        "4.8",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(Icons.star, color: Colors.amber, size: 32),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- Menu 4 chức năng ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMenuItem(
                  Icons.bar_chart,
                  "Doanh Thu",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RevenueReportScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  Icons.receipt_long,
                  "Đơn Đặt",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const OrdersMainScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  Icons.list_alt,
                  "Danh sách Sân",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ManageFieldScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  Icons.star_rate,
                  "Đánh Giá",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DanhGiaCuaToiScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 20),

            // --- Danh sách sân ---
            _buildFieldItem(
              icon: Icons.sports_soccer,
              title: "Sân Bóng",
              location: "702, Nguyễn Giáp, Hiệp Phú, Thủ Đức",
              details: "5:00 - 23:00",
              sub: "5 Sân",
            ),
            _buildFieldItem(
              icon: Icons.sports_bar,
              title: "Bàn Bida",
              location: "702, Nguyễn Giáp, Hiệp Phú, Thủ Đức",
              details: "24/24",
              sub: "10 Bàn",
            ),

            const SizedBox(height: 15),
            const Text(
              "Dashboard",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),

            const SizedBox(height: 15),

            // --- Biểu đồ ---
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _PieChart(title: "Doanh Thu Tháng 9"),
                _PieChart(title: "Doanh Thu Ngày 18/9"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.blueAccent, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  static Widget _buildFieldItem({
    required IconData icon,
    required String title,
    required String location,
    required String details,
    required String sub,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 40, color: Colors.blueAccent),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  location,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  details,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                sub,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 3),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ],
      ),
    );
  }
}

class _PieChart extends StatelessWidget {
  final String title;
  const _PieChart({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(value: 40, color: Colors.red, title: ''),
                PieChartSectionData(value: 30, color: Colors.blue, title: ''),
                PieChartSectionData(value: 30, color: Colors.grey, title: ''),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }
}
