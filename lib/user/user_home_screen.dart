import 'package:fieldshub/Database/database.dart';
import 'package:fieldshub/user/chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fieldshub/widget/field_booking_card.dart';
import 'package:fieldshub/user/filter_dialog.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({Key? key}) : super(key: key);

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  String selectedCategory = "all";
  String userName = ' ';
  String userAvatar = '';
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
          userAvatar = doc.data()?['avatar'] ?? '';
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
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white,
            backgroundImage: userAvatar.isNotEmpty
                ? NetworkImage(
                    '$userAvatar?w=100,h=100,c_fill',
                  ) // Resize nhỏ cho avatar
                : null,
            child: userAvatar.isEmpty
                ? const Icon(Icons.person, color: Colors.blue)
                : null,
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
                onPressed: () async {
                  final result = await showFilterDialog(
                    context: context,
                    priceRange: _priceRange,
                    timeRange: _timeRange,
                    selectedDistricts: _selectedDistricts,
                    selectedRating: _selectedRating,
                  );

                  if (result != null) {
                    setState(() {
                      _priceRange = result.priceRange;
                      _timeRange = result.timeRange;
                      _selectedDistricts = result.selectedDistricts;
                      _selectedRating = result.selectedRating;
                      _isFilterApplied = true;
                    });
                  }
                },
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
              final double price = await Database.getFieldPrice(doc.id);

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
              enrichedData.retainWhere((item) {
                final double price = item['price'];
                final int open = item['open'];
                final int close = item['close'];
                final String district = item['address'] ?? '';
                final double rating = item['rating'] ?? 0;

                final matchPrice =
                    price >= _priceRange.start && price <= _priceRange.end;

                final matchTime =
                    !(close < _timeRange.start || open > _timeRange.end);

                final matchDistrict =
                    _selectedDistricts.isEmpty ||
                    _selectedDistricts.contains(district);

                final matchRating =
                    _selectedRating == 0 || rating >= _selectedRating;

                return matchPrice && matchTime && matchDistrict && matchRating;
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
}
