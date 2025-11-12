import 'package:cloud_firestore/cloud_firestore.dart';
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

  // HÀM CHUẨN HÓA GIỜ VIỆT NAM
  DateTime _toVietnamTime(Timestamp? timestamp) {
    if (timestamp == null) return DateTime.now();
    return timestamp.toDate().add(const Duration(hours: 7)); // UTC → GMT+7
  }

  DateTime _vietnamNow() => DateTime.now();

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
    _autoFixOldData();
    _listenToRevenueUpdates();
  }

  void _initializeHourlyBarData() {
    hourlyBarData = List.generate(24, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [BarChartRodData(toY: 0, color: Colors.transparent)],
      );
    });
  }

  Future<void> _autoFixOldData() async {
    try {
      final fieldsSnap = await _firestore.collection('fields').get();

      for (var fieldDoc in fieldsSnap.docs) {
        final fieldData = fieldDoc.data();
        final fieldId = fieldDoc.id;

        if (!fieldData.containsKey('sport_id') || fieldData['sport_id'] == null) {
          String sportKey = 'Khác';
          final name = fieldData['name']?.toString() ?? '';
          final oldSport = fieldData['sport']?.toString() ?? '';

          if (name.contains('Bóng') || name.contains('Sân 5') || name.contains('Sân 7') || oldSport == 'BongDa') {
            sportKey = 'BongDa';
          } else if (name.contains('Cầu') || oldSport == 'CauLong') {
            sportKey = 'CauLong';
          } else if (name.contains('Chuyền') || oldSport == 'BongChuyen') {
            sportKey = 'BongChuyen';
          } else if (name.contains('Bida')) {
            sportKey = 'Bida';
          }

          final sportRef = 'sports/$sportKey';
          await fieldDoc.reference.set({'sport_id': sportRef}, SetOptions(merge: true));
        }

        final sportId = fieldData['sport_id'] ??
            (fieldData['sport'] != null ? 'sports/${_mapOldSport(fieldData['sport'])}' : 'sports/Khác');

        final bookingsSnap = await _firestore
            .collection('bookings')
            .where('field_id', isEqualTo: _firestore.doc('fields/$fieldId'))
            .get();

        for (var bookingDoc in bookingsSnap.docs) {
          final bookingData = bookingDoc.data();
          if (!bookingData.containsKey('sport_id')) {
            await bookingDoc.reference.set({'sport_id': sportId}, SetOptions(merge: true));
          }
        }
      }
    } catch (e) {
      debugPrint('Lỗi tự động fix: $e');
    }
  }

  String _mapOldSport(dynamic oldSport) {
    if (oldSport == 'BongDa') return 'BongDa';
    if (oldSport == 'CauLong') return 'CauLong';
    if (oldSport == 'BongChuyen') return 'BongChuyen';
    if (oldSport == 'Bida') return 'Bida';
    return 'Khác';
  }

  // REALTIME: HÔM NAY + THÁNG
  void _listenToRevenueUpdates() {
    final startOfDay = _startOfDayVN();
    final endOfDay = _endOfDayVN();

    // CHUYỂN VỀ UTC ĐỂ LỌC CHÍNH XÁC TRÊN FIRESTORE
    final startOfDayUtc = startOfDay.subtract(const Duration(hours: 7));
    final endOfDayUtc = endOfDay.subtract(const Duration(hours: 7));

    _firestore
        .collection('bookings')
        .where('status', isEqualTo: 'Đã xác nhận')
        .where('start_time', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDayUtc))
        .where('start_time', isLessThanOrEqualTo: Timestamp.fromDate(endOfDayUtc))
        .snapshots()
        .listen((snapshot) async {
      // XỬ LÝ DELTA (realtime)
      for (var change in snapshot.docChanges) {
        final data = change.doc.data() as Map<String, dynamic>?;
        if (data == null) continue;

        final startTimeLocal = _toVietnamTime(data['start_time']);
        final hour = startTimeLocal.hour;
        final price = (data['price'] as num?)?.toDouble() ?? 0;
        final sportId = data['sport_id'];

        if (hour < 0 || hour >= 24) continue;

        if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
          await _updateHourlyBarForBooking(hour, price, sportId, isAdd: true);
          _todayTotal += price;
        } else if (change.type == DocumentChangeType.removed) {
          await _updateHourlyBarForBooking(hour, price, sportId, isAdd: false);
          _todayTotal -= price;
        }
      }

      // Cập nhật biểu đồ tròn + fallback
      await _updateDailyPieChart(snapshot);
      await _updateHourlyBarChart(snapshot);
    });

    // THÁNG NÀY
    final startOfMonth = DateTime(_vietnamNow().year, _vietnamNow().month, 1);
    final endOfMonth = DateTime(_vietnamNow().year, _vietnamNow().month + 1, 0, 23, 59, 59);

    final startOfMonthUtc = startOfMonth.subtract(const Duration(hours: 7));
    final endOfMonthUtc = endOfMonth.subtract(const Duration(hours: 7));

    _firestore
        .collection('bookings')
        .where('status', isEqualTo: 'Đã xác nhận')
        .where('start_time', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonthUtc))
        .where('start_time', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonthUtc))
        .snapshots()
        .listen((snapshot) {
      _updateMonthlyPieChart(snapshot);
      _updateMonthlyTotal(snapshot);
    });
  }

  // CẬP NHẬT 1 CỘT GIỜ (realtime)
  Future<void> _updateHourlyBarForBooking(int hour, double price, dynamic sportId, {required bool isAdd}) async {
  final sportName = await _getSportName(sportId);
  final color = _getSportColor(sportName);

  setState(() {
    final newHourlyData = List<BarChartGroupData>.from(hourlyBarData);
    final currentGroup = newHourlyData[hour];
    final currentRods = List<BarChartRodData>.from(currentGroup.barRods);

    int sportIndex = currentRods.indexWhere((rod) => rod.color == color);

    double currentValue = sportIndex >= 0 ? currentRods[sportIndex].toY : 0;
    double newValue = isAdd ? currentValue + price : currentValue - price;
    if (newValue < 0) newValue = 0;

    if (sportIndex >= 0) {
      currentRods[sportIndex] = BarChartRodData(toY: newValue, color: color, width: 14);
    } else if (newValue > 0) {
      currentRods.add(BarChartRodData(toY: newValue, color: color, width: 14));
    } else if (sportIndex >= 0 && newValue == 0) {
      currentRods.removeAt(sportIndex);
    }

    newHourlyData[hour] = BarChartGroupData(
      x: hour,
      barRods: currentRods.isNotEmpty
          ? currentRods
          : [BarChartRodData(toY: 0, color: Colors.transparent)],
    );

    hourlyBarData = newHourlyData; // ← Quan trọng: gán lại list mới
  });
}

  Future<String> _getSportName(dynamic sportId) async {
    if (sportId == null) return 'Khác';
    String path = sportId is DocumentReference ? sportId.path : sportId.toString();
    if (_sportCache.containsKey(path)) return _sportCache[path]!;

    try {
      final doc = await _firestore.doc(path).get();
      if (doc.exists) {
        final name = (doc.data() as Map<String, dynamic>)['name']?.toString() ?? 'Khác';
        _sportCache[path] = name;
        return name;
      }
    } catch (e) {
      debugPrint('Lỗi lấy sport: $e');
    }
    _sportCache[path] = 'Khác';
    return 'Khác';
  }

  Color _getSportColor(String sport) {
    final normalized = sport.trim().toLowerCase().replaceAll(' ', '');
    if (normalized.contains('bóngđá') || normalized.contains('bongda')) return Colors.green.shade600;
    if (normalized.contains('cầulông') || normalized.contains('caulong')) return Colors.blue.shade600;
    if (normalized.contains('bóngchuyền') || normalized.contains('bongchuyen')) return Colors.purple.shade600;
    if (normalized.contains('bida')) return Colors.brown.shade600;
    return Colors.grey.shade600;
  }

  // BIỂU ĐỒ TRÒN HÔM NAY
  Future<void> _updateDailyPieChart(QuerySnapshot snapshot) async {
    double total = 0;
    final Map<String, double> sportRevenue = {};

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final price = (data['price'] as num?)?.toDouble() ?? 0;
      final sportId = data['sport_id'];
      final sportName = await _getSportName(sportId);

      total += price;
      sportRevenue[sportName] = (sportRevenue[sportName] ?? 0) + price;
    }

    if (mounted) {
      setState(() {
        _todayTotal = total;
        dailyPieData = sportRevenue.entries.map((e) {
          final percentage = total > 0 ? (e.value / total) * 100 : 0;
          return PieChartSectionData(
            color: _getSportColor(e.key),
            value: e.value,
            title: '${percentage.toStringAsFixed(0)}%',
            radius: 45,
            titleStyle: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
          );
        }).toList();

        if (dailyPieData.isEmpty) {
          dailyPieData = [PieChartSectionData(color: Colors.grey.shade400, value: 100, title: '0%', radius: 45)];
        }
      });
    }
  }

  // BIỂU ĐỒ TRÒN THÁNG
  Future<void> _updateMonthlyPieChart(QuerySnapshot snapshot) async {
    double total = 0;
    final Map<String, double> sportRevenue = {};

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final price = (data['price'] as num?)?.toDouble() ?? 0;
      final sportId = data['sport_id'];
      final sportName = await _getSportName(sportId);

      total += price;
      sportRevenue[sportName] = (sportRevenue[sportName] ?? 0) + price;
    }

    if (mounted) {
      setState(() {
        monthlyPieData = sportRevenue.entries.map((e) {
          final percentage = total > 0 ? (e.value / total) * 100 : 0;
          return PieChartSectionData(
            color: _getSportColor(e.key),
            value: e.value,
            title: '${percentage.toStringAsFixed(0)}%',
            radius: 40,
            titleStyle: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
          );
        }).toList();

        if (monthlyPieData.isEmpty) {
          monthlyPieData = [PieChartSectionData(color: Colors.grey.shade400, value: 100, title: '0%', radius: 40)];
        }
      });
    }
  }

  void _updateMonthlyTotal(QuerySnapshot snapshot) {
    double total = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final price = (data['price'] as num?)?.toDouble() ?? 0;
      total += price;
    }
    if (mounted) setState(() => _monthlyTotal = total);
  }

  // BIỂU ĐỒ CỘT GIỜ (fallback)
  Future<void> _updateHourlyBarChart(QuerySnapshot snapshot) async {
  final Map<int, Map<String, double>> hourlyBySport = {};

  for (var doc in snapshot.docs) {
    final data = doc.data() as Map<String, dynamic>;
    final startTimeLocal = _toVietnamTime(data['start_time']);
    final hour = startTimeLocal.hour;
    final price = (data['price'] as num?)?.toDouble() ?? 0;
    final sportId = data['sport_id'];
    final sportName = await _getSportName(sportId);

    hourlyBySport.putIfAbsent(hour, () => {});
    hourlyBySport[hour]![sportName] = (hourlyBySport[hour]![sportName] ?? 0) + price;
  }

  if (mounted) {
    setState(() {
      hourlyBarData = List.generate(24, (i) {
        final hourData = hourlyBySport[i] ?? {};
        final rods = hourData.entries.map((e) {
          return BarChartRodData(toY: e.value, color: _getSportColor(e.key), width: 14);
        }).toList();

        return BarChartGroupData(
          x: i,
          barRods: rods.isNotEmpty ? rods : [BarChartRodData(toY: 0, color: Colors.transparent)],
        );
      });
    });
  }
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
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Dashboard", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 20),

              // BIỂU ĐỒ TRÒN HÔM NAY
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        "Doanh thu hôm nay - ${DateFormat('dd/MM/yyyy').format(_vietnamNow())}",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 180,
                        child: PieChart(
                          PieChartData(sections: dailyPieData, centerSpaceRadius: 30, sectionsSpace: 2),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Tổng: ${_currencyFormat.format(_todayTotal)}",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // TỔNG THÁNG
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Doanh thu tháng này", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(
                        _currencyFormat.format(_monthlyTotal),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // BIỂU ĐỒ CỘT GIỜ
              const Text("Doanh thu theo giờ (0h - 23h)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                            alignment: BarChartAlignment.center,
                            borderData: FlBorderData(show: false),
                            gridData: FlGridData(show: true, drawVerticalLine: false),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) {
                                    if (value.toInt() % 2 == 0) {
                                      return Text('${value.toInt()}h', style: const TextStyle(fontSize: 10));
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  interval: 50000,
                                  getTitlesWidget: (value, meta) {
                                    if (value == 0) return const Text('0');
                                    return Text('${(value / 1000).toStringAsFixed(0)}K',
                                        style: const TextStyle(fontSize: 10));
                                  },
                                ),
                              ),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            barGroups: hourlyBarData,
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (_) => Colors.black87,
                                getTooltipItem: (group, _, rod, __) {
                                  final hour = group.x;
                                  final sport = _getSportFromColor(rod.color!);
                                  return BarTooltipItem(
                                    '$hour:00\n${_currencyFormat.format(rod.toY)}\n($sport)',
                                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  );
                                },
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
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _legendItem(Icons.square, Colors.green.shade600, "Bóng đá"),
            _legendItem(Icons.square, Colors.blue.shade600, "Cầu lông"),
            _legendItem(Icons.square, Colors.purple.shade600, "Bóng chuyền"),
            _legendItem(Icons.square, Colors.brown.shade600, "Bida"),
            _legendItem(Icons.square, Colors.grey.shade600, "Khác"),
            const SizedBox(height: 8),
            const Text("Chạm vào cột để xem chi tiết", style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(IconData icon, Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _getSportFromColor(Color color) {
    if (color == Colors.green.shade600) return 'Bóng đá';
    if (color == Colors.blue.shade600) return 'Cầu lông';
    if (color == Colors.purple.shade600) return 'Bóng chuyền';
    if (color == Colors.brown.shade600) return 'Bida';
    return 'Khác';
  }
}