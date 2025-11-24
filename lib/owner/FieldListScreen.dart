import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'ManageFieldScreen.dart';

class DanhSachSanScreen extends StatefulWidget {
  const DanhSachSanScreen({super.key, this.initialFilter});
  final String? initialFilter;

  @override
  State<DanhSachSanScreen> createState() => _DanhSachSanScreenState();
}

class _DanhSachSanScreenState extends State<DanhSachSanScreen> {
  final fieldsRef = FirebaseFirestore.instance.collection('fields');

  // MỞ MÀN HÌNH QUẢN LÝ SÂN (giữ nguyên logic cũ)
  void _openManageFieldScreen({String? fieldId, Map<String, dynamic>? fieldData}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManageFieldScreen(
          fieldData: fieldData != null ? {...fieldData, 'id': fieldId} : null,
        ),
      ),
    );
    if (result == true && mounted) setState(() {});
  }

  // XÓA SÂN (giữ nguyên như cũ)
  void _deleteField(String fieldId, String ten) async {
    fieldId = fieldId.replaceFirst('fields/', '');
    final confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xóa sân"),
        content: Text("Bạn có chắc chắn muốn xóa sân '$ten' không?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Hủy")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Xóa", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await fieldsRef.doc(fieldId).delete();
        await FirebaseFirestore.instance.collection('prices').doc(fieldId).delete();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Đã xóa sân '$ten'")));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi khi xóa sân: $e")));
      }
    }
  }

  // LẤY ĐỊA CHỈ (giữ nguyên logic cũ)
  Future<String> _fetchAddressForField(Map<String, dynamic> fieldData, String fieldId) async {
    String address = (fieldData['diaChi'] as String?) ?? '';
    if (address.isEmpty || address == '—') {
      try {
        dynamic areaRef = fieldData['area_id'];
        DocumentSnapshot? areaDoc;
        if (areaRef is DocumentReference) {
          areaDoc = await areaRef.get();
        }
        address = (areaDoc?.data() as Map<String, dynamic>?)?['address'] as String? ?? 'Không có địa chỉ';
      } catch (e) {
        address = 'Không xác định';
      }
    }
    return address;
  }

  // LẤY GIÁ (giữ nguyên như cũ)
  Future<int?> _fetchPrice(String fieldId) async {
    try {
      final docSnapshot = await FirebaseFirestore.instance
          .collection('prices')
          .doc(fieldId.replaceFirst('fields/', ''))
          .get();
      if (docSnapshot.exists) {
        return docSnapshot.data()?['price_amount'] as int?;
      }
    } catch (e) {
      debugPrint('Error fetching price: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final String? filter = widget.initialFilter;

    return Scaffold(
      backgroundColor: const Color(0xFFD7EDFF),
      appBar: AppBar(
        title: Text(
          filter != null ? "Danh sách sân $filter" : "Danh sách sân",
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: const Color(0xFFD7EDFF),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            tooltip: "Thêm sân mới",
            onPressed: () => _openManageFieldScreen(), // ĐÃ THAY DIALOG CŨ
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        // FIX DUY NHẤT: Lọc theo sport nếu có initialFilter
        stream: (filter == null || filter.isEmpty)
            ? fieldsRef.orderBy('createdAt', descending: true).snapshots()
            : fieldsRef
                .where('sport', isEqualTo: filter)
                .orderBy('createdAt', descending: true)
                .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                filter != null ? "Chưa có sân $filter nào." : "Chưa có sân nào.",
                style: const TextStyle(fontSize: 16),
              ),
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
              final anh = data['image'];
              final coc = data['deposit_percent']?.toString() ?? '0';
              final giaTuData = data['price']?.toString() ?? '0';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: (anh != null && anh.toString().isNotEmpty)
                        ? Image.network(
                            anh,
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 50),
                          )
                        : const Icon(Icons.sports_soccer, size: 50),
                  ),
                  title: Text(ten, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<String>(
                        future: _fetchAddressForField(data, doc.id),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Text("Địa chỉ: Đang tải...", style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic));
                          }
                          final address = snapshot.data ?? 'Không xác định';
                          return Text("Địa chỉ: $address", style: const TextStyle(fontSize: 13));
                        },
                      ),
                      FutureBuilder<int?>(
                        future: _fetchPrice(fieldId),
                        builder: (context, priceSnapshot) {
                          if (priceSnapshot.connectionState == ConnectionState.waiting) {
                            return Text("Giá: $giaTuData đ/giờ", style: const TextStyle(fontSize: 13));
                          }
                          final gia = priceSnapshot.data?.toString() ?? giaTuData;
                          return Text("Giá: $gia đ/giờ", style: const TextStyle(fontSize: 13));
                        },
                      ),
                      Text("Cọc: $coc %", style: const TextStyle(fontSize: 13)),
                      const Text("Giờ hoạt động: 00:00-23:59", style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        tooltip: "Sửa sân",
                        onPressed: () => _openManageFieldScreen(fieldId: doc.id, fieldData: data), // ĐÃ THAY
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