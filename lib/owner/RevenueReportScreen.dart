import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class RevenueReportScreen extends StatefulWidget {
  const RevenueReportScreen({Key? key}) : super(key: key);

  @override
  State<RevenueReportScreen> createState() => _RevenueReportScreenState();
}

class _RevenueReportScreenState extends State<RevenueReportScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<PieChartSectionData> monthlyPieData = [];
  List<PieChartSectionData> dailyPieData = [];
  List<BarChartGroupData> hourlyBarData = [];

  double _todayTotal = 0;
  double _monthlyTotal = 0;

  final Map<String, String> _sportCache = {};
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'vi', symbol: 'đ');

  DateTime _toVietnamTime(Timestamp? timestamp) {
    if (timestamp == null) return DateTime.now();
    return timestamp.toDate().add(const Duration(hours: 7));
  }

  DateTime _vietnamNow() => DateTime.now().toLocal();

  DateTime _startOfDayVN() {
    final now = _vietnamNow();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime _endOfDayVN() {
    final now = _vietnamNow();
    return DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  @override
  void initState() {
    super.initState();
    _initializeHourlyBarData();
    _listenToAllRevenueSources();
  }

  void _initializeHourlyBarData() {
    hourlyBarData = List.generate(24, (i) {
      return BarChartGroupData(x: i, barRods: [BarChartRodData(toY: 0, color: Colors.transparent)]);
    });
  }

  // CHÍNH LÀ HÀM QUAN TRỌNG NHẤT: LẤY DOANH THU TỪ CẢ 2 NGUỒN
  void _listenToAllRevenueSources() {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    final startOfDay = _startOfDayVN();
    final endOfDay = _endOfDayVN();
    final startOfDayUtc = startOfDay.subtract(const Duration(hours: 7));
    final endOfDayUtc = endOfDay.subtract(const Duration(hours: 7));

    // 1. Tiền cọc từ pending_payments (TIỀN THỰC TẾ ĐÃ VÀO)
    _firestore
        .collection('pending_payments')
        .where('owner_id', isEqualTo: userId)
        .where('status', whereIn: ['Chờ xác nhận', 'Đã xác nhận']) // Đã cọc tiền
        .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDayUtc))
        .snapshots()
        .listen((snapshot) async {
      await _processPendingPayments(snapshot, isToday: true);
    });

    // 2. Tiền còn lại từ bookings (khi xác nhận xong)
    _firestore
        .collection('bookings')
        .where('owner_id', isEqualTo: userId)
        .where('status', isEqualTo: 'Đã xác nhận')
        .where('updated_at', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDayUtc))
        .where('updated_at', isLessThanOrEqualTo: Timestamp.fromDate(endOfDayUtc))
        .snapshots()
        .listen((snapshot) async {
      await _processConfirmedBookings(snapshot);
    });

    // THÁNG NÀY: CỘNG CẢ CỌC + XÁC NHẬN
    final startOfMonth = DateTime(_vietnamNow().year, _vietnamNow().month, 1);
    final startOfMonthUtc = startOfMonth.subtract(const Duration(hours: 7));

    _firestore
        .collection('pending_payments')
        .where('owner_id', isEqualTo: userId)
        .where('status', whereIn: ['Chờ xác nhận', 'Đã xác nhận'])
        .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonthUtc))
        .snapshots()
        .listen((snapshot) => _processPendingPayments(snapshot, isToday: false));

    _firestore
        .collection('bookings')
        .where('owner_id', isEqualTo: userId)
        .where('status', isEqualTo: 'Đã xác nhận')
        .where('updated_at', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonthUtc))
        .snapshots()
        .listen((snapshot) => _processConfirmedBookings(snapshot));
  }

  // XỬ LÝ TIỀN CỌC
  Future<void> _processPendingPayments(QuerySnapshot snapshot, {required bool isToday}) async {
  double addedToday = 0;
  double addedMonth = 0;
  final Map<String, double> sportRevenue = {};
  final Map<int, Map<String, double>> hourlyData = {};

  for (var doc in snapshot.docs) {
    final data = doc.data() as Map<String, dynamic>;
    final deposit = (data['deposit_amount'] ?? data['amount'] ?? 0).toDouble();
    
    final createdAt = _toVietnamTime(data['created_at'] as Timestamp?);
    final hour = (createdAt.hour - 7 + 24) % 24;
    final sportName = await _getSportName(data['sport_id'] ?? data['field_id']);

    // Luôn tính vào tháng
    addedMonth += deposit;
    _monthlyTotal += deposit; // ← Đảm bảo cộng vào tổng tháng

    if (isToday) {
      addedToday += deposit;
      sportRevenue[sportName] = (sportRevenue[sportName] ?? 0) + deposit;

      hourlyData.putIfAbsent(hour, () => {});
      hourlyData[hour]![sportName] = (hourlyData[hour]![sportName] ?? 0) + deposit;
    }
  }

  if (mounted) {
    setState(() {
      if (isToday) {
        _todayTotal += addedToday;
        _updatePieChart(sportRevenue, true);
        _updateHourlyBar(hourlyData);
      }
      // Không cần else vì _monthlyTotal đã được cộng trực tiếp ở trên
    });
  }
}

  // XỬ LÝ ĐƠN ĐÃ XÁC NHẬN (tiền còn lại)
  Future<void> _processConfirmedBookings(QuerySnapshot snapshot, {bool isToday = true}) async {
  double addedToday = 0;
  final Map<String, double> sportRevenue = {};
  final Map<int, Map<String, double>> hourlyData = {};

  for (var doc in snapshot.docs) {
    final data = doc.data() as Map<String, dynamic>;
    final price = (data['price'] as num?)?.toDouble() ?? 0;
    
    final confirmedTime = _toVietnamTime(data['updated_at'] as Timestamp?);
    final hour = (confirmedTime.hour - 7 + 24) % 24;
    final sportName = await _getSportName(data['sport_id']);

    // Luôn tính vào tháng
    _monthlyTotal += price;

    if (isToday) {
      addedToday += price;
      sportRevenue[sportName] = (sportRevenue[sportName] ?? 0) + price;

      hourlyData.putIfAbsent(hour, () => {});
      hourlyData[hour]![sportName] = (hourlyData[hour]![sportName] ?? 0) + price;
    }
  }

  if (mounted && isToday) {
    setState(() {
      _todayTotal += addedToday;
      _updatePieChart(sportRevenue, true);
      _updateHourlyBar(hourlyData);
    });
  }
  // Không cần setState nếu không phải hôm nay → tránh rebuild liên tục
}
  void _updatePieChart(Map<String, double> sportRevenue, bool isDaily) {
    final total = sportRevenue.values.fold(0.0, (a, b) => a + b);
    final List<PieChartSectionData> sections = sportRevenue.entries.map((e) {
      final percentage = total > 0 ? (e.value / total) * 100 : 0;
      return PieChartSectionData(
        color: _getSportColor(e.key),
        value: e.value,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 45,
        titleStyle: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
      );
    }).toList();

    if (sections.isEmpty) {
      sections.add(PieChartSectionData(color: Colors.grey.shade400, value: 100, title: '0%'));
    }

    if (mounted) {
      setState(() {
        if (isDaily) {
          dailyPieData = sections;
          if (total > _todayTotal) _todayTotal = total;
        } else {
          monthlyPieData = sections;
        }
      });
    }
  }

  void _updateHourlyBar(Map<int, Map<String, double>> hourlyData) {
  final newHourly = List<BarChartGroupData>.from(hourlyBarData);

  for (var entry in hourlyData.entries) {
    final hour = entry.key;
    final sportMap = entry.value;
    
    // Tạo các cột cho từng môn thể thao
    final rods = sportMap.entries.map((e) {
      return BarChartRodData(
        toY: e.value,
        color: _getSportColor(e.key),
        width: 14,
        borderRadius: BorderRadius.circular(4), // Bo góc cho đẹp
      );
    }).toList();

    // Cập nhật hoặc gộp với dữ liệu cũ nếu đã có
    if (newHourly[hour].barRods.first.toY > 0) {
      // Gộp dữ liệu mới với cũ
      final existingRods = newHourly[hour].barRods;
      final mergedRods = <BarChartRodData>[];
      
      for (var newRod in rods) {
        final existingRod = existingRods.firstWhere(
          (r) => r.color == newRod.color,
          orElse: () => BarChartRodData(toY: 0, color: newRod.color),
        );
        mergedRods.add(BarChartRodData(
          toY: existingRod.toY + newRod.toY,
          color: newRod.color,
          width: 14,
          borderRadius: BorderRadius.circular(4),
        ));
      }
      
      newHourly[hour] = BarChartGroupData(x: hour, barRods: mergedRods);
    } else {
      // Chưa có dữ liệu, thêm mới
      newHourly[hour] = BarChartGroupData(
        x: hour,
        barRods: rods.isNotEmpty ? rods : [BarChartRodData(toY: 0, color: Colors.transparent)],
      );
    }
  }

  if (mounted) setState(() => hourlyBarData = newHourly);
}

  // THAY TOÀN BỘ HÀM NÀY
Future<String> _getSportName(dynamic fieldRef) async {
  if (fieldRef == null) return 'Khác';

  DocumentReference? sportRef;

  // 1. Nếu là DocumentReference
  if (fieldRef is DocumentReference) {
    if (fieldRef.parent.id == 'sports') {
      sportRef = fieldRef;
    } else if (fieldRef.parent.id == 'fields') {
      final fieldDoc = await fieldRef.get();
      if (!fieldDoc.exists) return 'Khác';
      final data = fieldDoc.data() as Map<String, dynamic>;
      final sportId = data['sport_id'];
      if (sportId is DocumentReference && sportId.parent.id == 'sports') {
        sportRef = sportId;
      } else if (sportId is String && sportId.contains('sports/')) {
        sportRef = _firestore.doc(sportId);
      }
    }
  }
  // 2. Nếu là String
  else if (fieldRef is String) {
    if (fieldRef.contains('sports/')) {
      sportRef = _firestore.doc(fieldRef);
    } else {
      // Tự động thêm prefix nếu chỉ có ID như "BongDa"
      sportRef = _firestore.doc('sports/$fieldRef');
    }
  }

  if (sportRef == null) return 'Khác';

  final cacheKey = sportRef.path;
  if (_sportCache.containsKey(cacheKey)) {
    return _sportCache[cacheKey]!;
  }

  try {
    final doc = await sportRef.get();
    if (!doc.exists) {
      _sportCache[cacheKey] = 'Khác';
      return 'Khác';
    }

    final name = (doc['name'] as String?)?.trim();
    if (name == null || name.isEmpty) {
      _sportCache[cacheKey] = 'Khác';
      return 'Khác';
    }
    
    // Chuẩn hóa tên để hiển thị đẹp + dễ match màu
    final normalized = switch (doc.id.toLowerCase()) {
      'BongDa' => 'Bóng đá',
      'CauLong' => 'Cầu lông',
      'BongChuyen' => 'Bóng chuyền',
      'bida' => 'Bida',
      _ => name,
    };

    _sportCache[cacheKey] = normalized;
    return normalized;
  } catch (e) {
    return 'Khác';
  }
}

// VÀ THAY HÀM MÀU BẰNG CÁI NÀY (dùng doc.id thay vì name)
Color _getSportColor(String sportName) {
  // Dùng tên đã chuẩn hóa hoặc fallback bằng logic cũ
  final s = sportName.toLowerCase();

  if (s.contains('bóng đá') || s.contains('bongda')) return Colors.green.shade600;
  if (s.contains('cầu lông') || s.contains('caulong')) return Colors.blue.shade600;
  if (s.contains('bóng chuyền') || s.contains('bongchuyen')) return Colors.purple.shade600;
  if (s.contains('bida')) return Colors.brown.shade600;

  return Colors.grey.shade600;
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE7F0FA),
      appBar: AppBar(
        backgroundColor: Colors.lightBlue.shade700,
        title: const Text('Báo cáo doanh thu', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async => setState(() {}),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Dashboard Doanh Thu", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text("Hôm nay - ${DateFormat('dd/MM/yyyy').format(_vietnamNow())}",
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      SizedBox(height: 180, child: PieChart(PieChartData(sections: dailyPieData, centerSpaceRadius: 30))),
                      const SizedBox(height: 12),
                      Text("Tổng thu: ${_currencyFormat.format(_todayTotal)}",
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Doanh thu tháng này", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      Text(_currencyFormat.format(_monthlyTotal),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),
              const Text("Doanh thu theo giờ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    height: 340,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: 24 * 40,
                        child: BarChart(
                          BarChartData(
                            barGroups: hourlyBarData,
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (v, _) => v.toInt() % 2 == 0 ? Text('${v.toInt()}h') : const SizedBox(),
                              )),
                              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                            ),
                            barTouchData: BarTouchData(
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                                  '${group.x}:00\n${_currencyFormat.format(rod.toY)}',
                                  const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
              _buildLegend(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _legendItem("Bóng đá", Colors.green.shade600),
            _legendItem("Cầu lông", Colors.blue.shade600),
            _legendItem("Bóng chuyền", Colors.purple.shade600),
            _legendItem("Bida", Colors.brown.shade600),
            _legendItem("Khác", Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [Container(width: 16, height: 16, color: color), const SizedBox(width: 8), Text(text)]),
    );
  }
}