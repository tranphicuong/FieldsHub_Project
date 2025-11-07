import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DanhSachSanScreen extends StatefulWidget {
  const DanhSachSanScreen({super.key, this.initialFilter});
  final String? initialFilter;
  @override
  State<DanhSachSanScreen> createState() => _DanhSachSanScreenState();
}

class _DanhSachSanScreenState extends State<DanhSachSanScreen> {
  final fieldsRef = FirebaseFirestore.instance.collection('fields');

  // Hàm hiển thị hộp thoại thêm/sửa sân
  void _showFieldDialog({String? fieldId, Map<String, dynamic>? fieldData}) {
    final tenController = TextEditingController(text: fieldData?['name'] ?? '');
    final diaChiController =
        TextEditingController(text: fieldData?['diaChi'] ?? '');
    final giaController =
        TextEditingController(text: fieldData?['price']?.toString() ?? '');
    final cocController =
        TextEditingController(text: fieldData?['deposit_percent']?.toString() ?? '');
    final anhController =
        TextEditingController(text: fieldData?['image'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(fieldId == null ? "Thêm sân mới" : "Cập nhật thông tin sân"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tenController,
                decoration: const InputDecoration(labelText: "Tên sân"),
              ),
              TextField(
                controller: diaChiController,
                decoration: const InputDecoration(labelText: "Địa chỉ *"),
              ),
              TextField(
                controller: giaController,
                decoration: const InputDecoration(labelText: "Giá (đ/giờ) *"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: cocController,
                decoration: const InputDecoration(labelText: "Cọc (%)"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: anhController,
                decoration: const InputDecoration(labelText: "Link ảnh (URL)"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Hủy"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (giaController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("⚠️ Vui lòng nhập giá!")),
                );
                return;
              }
              if (diaChiController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("⚠️ Vui lòng nhập địa chỉ!")),
                );
                return;
              }

              final user = FirebaseAuth.instance.currentUser;
              if (user == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("❌ Lỗi: chưa đăng nhập.")),
                );
                return;
              }
              final newData = {
                'name': tenController.text.trim(),
                'ownerId': user.uid,
                'diaChi': diaChiController.text.trim(),
                'price': giaController.text.trim(),
                'deposit_percent': cocController.text.trim().isEmpty
                    ? 0
                    : int.tryParse(cocController.text.trim()) ?? 0,
                'image': anhController.text.trim(),
                'createdAt': fieldData?['createdAt'] ?? FieldValue.serverTimestamp(),
              };

              try {
                if (fieldId == null) {
                  // Thêm mới
                  final newFieldRef = await fieldsRef.add(newData);
                  fieldId = newFieldRef.id;
                  await FirebaseFirestore.instance
                      .collection('prices')
                      .doc(fieldId)
                      .set({
                    'field_id': fieldsRef.doc(fieldId),
                    'price_amount': int.tryParse(giaController.text.trim()) ?? 0,
                    'start_time': '00:00', // 24/24
                    'end_time': '23:59',   // 24/24
                    'percentage_price_change': 0, // Giá cố định
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("✅ Thêm sân thành công!")),
                  );
                } else {
                  // Cập nhật
                  await fieldsRef.doc(fieldId).update(newData);
                  await FirebaseFirestore.instance
                      .collection('prices')
                      .doc(fieldId)
                      .set({
                    'field_id': fieldsRef.doc(fieldId),
                    'price_amount': int.tryParse(giaController.text.trim()) ?? 0,
                    'start_time': '00:00', // 24/24
                    'end_time': '23:59',   // 24/24
                    'percentage_price_change': 0, // Giá cố định
                  }, SetOptions(merge: true));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("✅ Cập nhật sân thành công!")),
                  );
                }
                if (mounted) {
                  setState(() {});
                  Navigator.pop(ctx);
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("❌ Lỗi: $e")),
                );
              }
            },
            child: Text(fieldId == null ? "Lưu" : "Cập nhật"),
          ),
        ],
      ),
    );
  }

  // Hàm xóa sân
  void _deleteField(String fieldId, String ten) async {
    fieldId = fieldId.replaceFirst('fields/', '');
    final confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xóa sân"),
        content: Text("Bạn có chắc chắn muốn xóa sân '$ten' không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await fieldsRef.doc(fieldId).delete();
        await FirebaseFirestore.instance.collection('prices').doc(fieldId).delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ Đã xóa sân '$ten'")),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Lỗi khi xóa sân: $e")),
        );
      }
    }
  }

  // Hàm lấy giá từ "prices" dựa trên fieldId
  Future<int?> _fetchPrice(String fieldId) async {
    print('Fetching price for field_id: $fieldId');
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('prices')
          .doc(fieldId.replaceFirst('fields/', ''))
          .get();
      if (docSnapshot.exists) {
        print('Found price data: ${docSnapshot.data()}');
        return docSnapshot.data()?['price_amount'] as int?;
      } else {
        print('No price data found for field_id: $fieldId');
        return null;
      }
    } catch (e) {
      print('Error fetching price: $e');
      return null;
    }
  }

  Future<String> _fetchAddressForField(Map<String, dynamic> fieldData, String fieldId) async {
  String address = (fieldData['diaChi'] as String?) ?? '';
  if (address.isEmpty || address == '—') {
    try {
      // Lấy tham chiếu area_id từ document field
      dynamic areaRef = fieldData['area_id'];
      DocumentSnapshot? areaDoc;

      if (areaRef is DocumentReference) {
        areaDoc = await areaRef.get();
      } else if (areaRef is String) {
        areaDoc = await FirebaseFirestore.instance
            .collection('areas')
            .doc(areaRef)
            .get();
      }

      // Nếu tìm được document area thì lấy địa chỉ
      address = (areaDoc?.data() as Map<String, dynamic>?)?['address'] as String? ??
          'Không có địa chỉ';
    } catch (e) {
      debugPrint('Lỗi fetch address cho field $fieldId: $e');
      address = 'Không xác định';
    }
  }
  return address;
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD7EDFF),
      appBar: AppBar(
        title: const Text("Danh sách sân",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: const Color(0xFFD7EDFF),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            tooltip: "Thêm sân mới",
            onPressed: () => _showFieldDialog(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: fieldsRef.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("Chưa có sân nào.", style: TextStyle(fontSize: 16)),
            );
          }

          final fields = snapshot.data!.docs;

          return ListView.builder(
            itemCount: fields.length,
            itemBuilder: (context, index) {
              final doc = fields[index];
              final data = doc.data() as Map<String, dynamic>;
              final fieldId = 'fields/${doc.id}';

              final ten = data['name'] ?? 'Không tên';
              final diaChi = data['diaChi'] ?? 'Chưa có địa chỉ';
              final anh = data['image'];
              final coc = data['deposit_percent']?.toString() ?? '0';
              final giaTuData = data['price']?.toString() ?? '0';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: (anh != null && anh.isNotEmpty)
                        ? Image.network(
                            anh,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image, size: 50),
                          )
                        : const Icon(Icons.sports_soccer, size: 50),
                  ),
                  title: Text(ten,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                     FutureBuilder<String>(
  future: _fetchAddressForField(data, doc.id),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Text(
        "🏠 Địa chỉ: Đang tải...",
        style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
      );
    }
    if (snapshot.hasError) {
      return const Text(
        "🏠 Địa chỉ: Lỗi khi tải",
        style: TextStyle(fontSize: 13, color: Colors.red),
      );
    }
    final address = snapshot.data ?? 'Không xác định';
    return Text(
      "🏠 Địa chỉ: $address",
      style: const TextStyle(fontSize: 13),
    );
  },
),

                      FutureBuilder<int?>(
                        future: _fetchPrice(fieldId),
                        builder: (context, priceSnapshot) {
                          if (priceSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Text("💰 Giá: $giaTuData đ/giờ",
                                style: const TextStyle(fontSize: 13));
                          }
                          if (priceSnapshot.hasError || !priceSnapshot.hasData) {
                            return Text("💰 Giá: Lỗi hoặc không tìm thấy",
                                style: const TextStyle(fontSize: 13, color: Colors.red));
                          }
                          final gia = priceSnapshot.data?.toString() ?? giaTuData;
                          return Text("💰 Giá: $gia đ/giờ",
                              style: const TextStyle(fontSize: 13));
                        },
                      ),
                      Text("💵 Cọc: $coc %",
                          style: const TextStyle(fontSize: 13)),
                      const Text("🕒 Giờ hoạt động: 00:00-23:59",
                          style: TextStyle(fontSize: 13)),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        tooltip: "Sửa sân",
                        onPressed: () =>
                            _showFieldDialog(fieldId: doc.id, fieldData: data),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: "Xóa sân",
                        onPressed: () => _deleteField(fieldId, ten),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}