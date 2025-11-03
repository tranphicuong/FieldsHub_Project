import 'package:fieldshub/Database/database.dart';
import 'package:fieldshub/user/chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fieldshub/widget/field_booking_card.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({Key? key}) : super(key: key);

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  String selectedCategory = "all";
  String userName = ' ';
  final currentUser = FirebaseAuth.instance.currentUser;

  RangeValues _priceRange = const RangeValues(100000, 200000);
  RangeValues _timeRange = const RangeValues(6, 22);

  Set<String> _selectedDistricts = {};
  int _selectedRating = 0;
  bool _isFilterApplied = false;

  late final List<String> timeSlots;

  @override
  void initState() {
    super.initState();

    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (currentUser == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();
      if (doc.exists) {
        setState(() {
          userName = doc.data()?['name'] ?? 'Người dùng';
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải thông tin người dùng: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: _buildAppBar(),
      body: _buildHomeTab(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.blue[800],
      elevation: 0,
      title: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white,
            radius: 22,
            child: Icon(Icons.person, color: Colors.blue),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Xin chào",
                style: TextStyle(fontSize: 13, color: Colors.white),
              ),
              Text(
                userName.isNotEmpty ? userName : "Đang tải...",
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ChatScreen(
                  fieldId: "default",
                  fieldName: "Hỗ trợ chung",
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHomeTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Danh mục",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.filter_alt,
                  color: Color.fromARGB(255, 148, 147, 147),
                ),
                onPressed: () => _showFilterSheet(context),
              ),
            ],
          ),
        ),
        _buildCategoryBar(),
        Expanded(child: _buildFieldList()),
      ],
    );
  }

  Widget _buildCategoryBar() {
    return Container(
      width: double.infinity,
      color: Colors.blue[800],
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('sports').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Không có danh mục",
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final categories = [
            {'id': 'all', 'name': 'Tất cả'},
            ...snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return {'id': doc.id, 'name': data['name'] ?? 'Không tên'};
            }),
          ];

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: categories.map((cat) {
                final isSelected = selectedCategory == cat['id'];
                return GestureDetector(
                  onTap: () => setState(() => selectedCategory = cat['id']!),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white),
                    ),
                    child: Text(
                      cat['name']!,
                      style: TextStyle(
                        color: isSelected ? Colors.blue[800] : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFieldList() {
    final baseQuery = selectedCategory == 'all'
        ? FirebaseFirestore.instance.collection('fields')
        : FirebaseFirestore.instance
              .collection('fields')
              .where('sport', isEqualTo: selectedCategory);

    return StreamBuilder<QuerySnapshot>(
      stream: baseQuery.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Không có sân nào"));
        }

        final docs = snapshot.data!.docs;

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: Future.wait(
            docs.map((doc) async {
              final data = doc.data() as Map<String, dynamic>;
              final price = (data['price'] ?? 0).toDouble();

              final openTs = data['open_time'] as Timestamp?;
              final closeTs = data['close_time'] as Timestamp?;
              final open = openTs?.toDate().hour ?? 0;
              final close = closeTs?.toDate().hour ?? 24;

              final address = await Database.getFieldAddress(doc.id);
              final avgRating = await Database.getFieldAverageRating(doc.id);

              return {
                'doc': doc,
                'data': data,
                'price': price,
                'open': open,
                'close': close,
                'address': address,
                'rating': avgRating,
              };
            }),
          ),
          builder: (context, futureSnapshot) {
            if (futureSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final List<Map<String, dynamic>> enrichedData =
                futureSnapshot.data ?? [];

            if (_isFilterApplied) {
              enrichedData.removeWhere((item) {
                final matchPrice =
                    item['price'] >= _priceRange.start &&
                    item['price'] <= _priceRange.end;
                final matchTime =
                    _timeRange.start >= item['open'] &&
                    _timeRange.end <= item['close'];
                final matchDistrict =
                    _selectedDistricts.isEmpty ||
                    _selectedDistricts.contains(item['address']);
                final matchRating =
                    _selectedRating == 0 || item['rating'] >= _selectedRating;

                return !(matchPrice &&
                    matchTime &&
                    matchDistrict &&
                    matchRating);
              });
            }

            if (enrichedData.isEmpty) {
              return const Center(child: Text("Không có sân phù hợp"));
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: enrichedData.length,
              itemBuilder: (context, index) {
                final item = enrichedData[index];
                final doc = item['doc'] as DocumentSnapshot;
                final data = Map<String, dynamic>.from(item['data'] as Map);
                data['id'] = doc.id;
                data['average_rating'] = item['rating'];
                return FieldBookingCard(fieldData: data, fieldId: doc.id);
              },
            );
          },
        );
      },
    );
  }

  void _showFilterSheet(BuildContext context) {
    String _formatMoney(double value) {
      final int v = value.toInt();
      final s = v.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (m) => '.',
      );
      return "$s đ";
    }

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Filter',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.white,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              height: double.infinity,
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Bộ lọc nâng cao",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                          const Divider(),

                          Text(
                            "Giá (${_formatMoney(_priceRange.start)} - ${_formatMoney(_priceRange.end)})",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          RangeSlider(
                            values: _priceRange,
                            min: 0,
                            max: 1000000,
                            divisions: 20,
                            activeColor: Colors.blue,
                            inactiveColor: Colors.grey[300],
                            labels: RangeLabels(
                              _formatMoney(_priceRange.start),
                              _formatMoney(_priceRange.end),
                            ),
                            onChanged: (val) =>
                                setModalState(() => _priceRange = val),
                          ),

                          const SizedBox(height: 20),

                          Text(
                            "Giờ hoạt động (${_timeRange.start.toInt()}h - ${_timeRange.end.toInt()}h)",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          RangeSlider(
                            values: _timeRange,
                            min: 0,
                            max: 24,
                            divisions: 24,
                            activeColor: Colors.green,
                            inactiveColor: Colors.grey[300],
                            labels: RangeLabels(
                              "${_timeRange.start.toInt()}h",
                              "${_timeRange.end.toInt()}h",
                            ),
                            onChanged: (val) =>
                                setModalState(() => _timeRange = val),
                          ),

                          const SizedBox(height: 20),

                          const Text(
                            "Khu vực",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final d in [
                                'Thủ Đức',
                                'Gò Vấp',
                                'Bình Thạnh',
                                'Quận 1',
                                'Quận 3',
                                'Quận 10',
                              ])
                                FilterChip(
                                  label: Text(d),
                                  selected: _selectedDistricts.contains(d),
                                  onSelected: (selected) {
                                    setModalState(() {
                                      if (selected)
                                        _selectedDistricts.add(d);
                                      else
                                        _selectedDistricts.remove(d);
                                    });
                                  },
                                ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          const Text(
                            "Đánh giá",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Row(
                            children: List.generate(5, (index) {
                              final star = index + 1;
                              return IconButton(
                                onPressed: () => setModalState(
                                  () => _selectedRating =
                                      _selectedRating == star ? 0 : star,
                                ),
                                icon: Icon(
                                  Icons.star,
                                  color: _selectedRating >= star
                                      ? Colors.amber
                                      : Colors.grey,
                                ),
                              );
                            }),
                          ),

                          const SizedBox(height: 20),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () {
                                  setModalState(() {
                                    _priceRange = const RangeValues(0, 1000000);
                                    _timeRange = const RangeValues(6, 22);
                                    _selectedDistricts.clear();
                                    _selectedRating = 0;
                                  });
                                  setState(() => _isFilterApplied = false);
                                  Navigator.pop(context);
                                },
                                child: const Text("Thiết lập lại"),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () {
                                  setState(() => _isFilterApplied = true);
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  "Áp dụng",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(anim1),
          child: child,
        );
      },
    );
  }
}
