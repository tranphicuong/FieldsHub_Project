import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
class RevenueReportScreen extends StatefulWidget {
  const RevenueReportScreen({Key? key}) : super(key: key);

  @override
  State<RevenueReportScreen> createState() => _RevenueReportScreenState();
}

class _RevenueReportScreenState extends State<RevenueReportScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7F0FA),
      appBar: AppBar(
        backgroundColor: Colors.lightBlue.shade700,
        title: const Text('Báo cáo doanh thu'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[100],
                foregroundColor: Colors.blue[900],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {},
              icon: const Icon(Icons.warning_amber_rounded, size: 18),
              label: const Text('Báo Lỗi', style: TextStyle(fontSize: 13)),
            ),
          ),
        ],
      ),

      // 📊 Nội dung chính
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Dashboard",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // --- Biểu đồ tròn ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPieChart("Doanh Thu Tháng 9"),
                _buildPieChart("Doanh Thu Ngày 18/9"),
              ],
            ),

            const SizedBox(height: 24),

            // --- Biểu đồ cột ---
            const Text(
              "Doanh thu bán hàng trung bình theo giờ",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 280,
              child: BarChart(
                BarChartData(
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, _) {
                          switch (value.toInt()) {
                            case 0:
                              return const Text('8h');
                            case 1:
                              return const Text('9h');
                            case 2:
                              return const Text('10h');
                            case 3:
                              return const Text('11h');
                            case 4:
                              return const Text('12h');
                            case 5:
                              return const Text('13h');
                            case 6:
                              return const Text('14h');
                            default:
                              return const Text('');
                          }
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  barGroups: [
                    for (int i = 0; i < 7; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: (i % 2 == 0 ? 9 : 5).toDouble(),
                            color: Colors.blue,
                            width: 14,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
            _buildLegend(),
          ],
        ),
      ),
    );
  }

  // --- Biểu đồ tròn mẫu ---
  Widget _buildPieChart(String title) {
    return Column(
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(color: Colors.red, value: 60, radius: 40),
                PieChartSectionData(color: Colors.blue, value: 25, radius: 40),
                PieChartSectionData(color: Colors.grey, value: 15, radius: 40),
              ],
              centerSpaceRadius: 0,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // --- Chú thích ---
  Widget _buildLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Row(
          children: [
            Icon(Icons.square, color: Colors.blue, size: 14),
            SizedBox(width: 6),
            Text("Doanh thu bao gồm thuế"),
          ],
        ),
        Row(
          children: [
            Icon(Icons.square, color: Colors.blueAccent, size: 14),
            SizedBox(width: 6),
            Text("Doanh thu bán hàng trung bình theo giờ"),
          ],
        ),
        Row(
          children: [
            Icon(Icons.circle, color: Colors.red, size: 10),
            SizedBox(width: 6),
            Text("Tổng doanh thu trong một giờ"),
          ],
        ),
      ],
    );
  }
}
