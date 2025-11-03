import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'FieldListScreen.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // để dùng kIsWeb


class ManageFieldScreen extends StatefulWidget {
  final Map<String, dynamic>? fieldData; // Dữ liệu sân nếu đang sửa

  const ManageFieldScreen({super.key, this.fieldData});

  @override
  State<ManageFieldScreen> createState() => _ManageFieldScreenState();
}

class _ManageFieldScreenState extends State<ManageFieldScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController depositController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  final ImagePicker picker = ImagePicker();
  XFile? _selectedImageFile;
  String? selectedCategory;
  String? fieldId; // ID của sân để liên kết với giá
  String? areaId = "/areas/m7MXj6UwRGwOxt4ilk0A"; // Mặc định, sẽ cập nhật nếu cần

  bool _isLoading = false; // Trạng thái đang lưu
  late Future<List<String>> _sportsCategories;
  late Future<DocumentReference?> _fieldPriceRef; // Tham chiếu giá

  @override
  void initState() {
    super.initState();
    _sportsCategories = _fetchSportsCategories();
    fieldId = widget.fieldData?['id'] ?? ''; // Lấy ID sân nếu có
    _fieldPriceRef = _fetchFieldPriceRef(fieldId); // Lấy tham chiếu giá
    if (widget.fieldData != null) {
      nameController.text = widget.fieldData!['name'] ?? '';
      addressController.text = widget.fieldData!['diaChi'] ?? '';
      // Lấy giá từ tham chiếu nếu có
      _loadPriceFromRef(widget.fieldData!['price'] as DocumentReference?);
      phoneController.text = widget.fieldData!['soDienThoai'] ?? '';
      depositController.text = widget.fieldData!['deposit']?.toString() ?? '';
      noteController.text = widget.fieldData!['note'] ?? '';
      selectedCategory = widget.fieldData!['sport'];
      areaId = widget.fieldData!['area_id'] ?? "/areas/m7MXj6UwRGwOxt4ilk0A"; // Lấy area_id hiện tại
    }
  }

  Future<List<String>> _fetchSportsCategories() async {
    final querySnapshot = await FirebaseFirestore.instance.collection('sports').get();
    return querySnapshot.docs.map((doc) => doc.id).toList();
  }

  Future<DocumentReference?> _fetchFieldPriceRef(String? fieldId) async {
    if (fieldId == null || fieldId.isEmpty) return null;
    final querySnapshot = await FirebaseFirestore.instance
        .collection('prices')
        .where('field_id', isEqualTo: FirebaseFirestore.instance.doc('fields/$fieldId'))
        .limit(1)
        .get();
    return querySnapshot.docs.isNotEmpty ? querySnapshot.docs.first.reference : null;
  }

  void _loadPriceFromRef(DocumentReference? priceRef) async {
    if (priceRef == null) return;
    final priceDoc = await priceRef.get();
    if (priceDoc.exists) {
      final priceData = priceDoc.data() as Map<String, dynamic>?;
      if (priceData != null) {
        final price = priceData['price_amount']?.toString() ?? '';
        if (priceController.text.isEmpty) {
          setState(() {
            priceController.text = price;
          });
        }
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              const ListTile(
                title: Center(
                  child: Text(
                    'Chọn hình sân',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              ListTile(
                title: const Center(
                  child: Text('Chọn ảnh từ thư viện',
                      style: TextStyle(color: Colors.blue)),
                ),
                onTap: () async {
                  final picked = await picker.pickImage(source: ImageSource.gallery);
                  if (picked != null) {
                    setState(() => _selectedImageFile = picked);
                  }
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Center(
                    child: Text('Chụp ảnh mới',
                        style: TextStyle(color: Colors.blue))),
                onTap: () async {
                  final picked = await picker.pickImage(source: ImageSource.camera);
                  if (picked != null) {
                    setState(() => _selectedImageFile = picked);
                  }
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Center(
                    child: Text('Hủy', style: TextStyle(color: Colors.red))),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveField() async {
    if (nameController.text.isEmpty ||
        addressController.text.isEmpty ||
        priceController.text.isEmpty ||
        phoneController.text.isEmpty ||
        selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Vui lòng nhập đủ thông tin bắt buộc")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Vui lòng đăng nhập")),
        );
        return;
      }

      String? imageUrl = widget.fieldData?['image'];

      if (_selectedImageFile != null) {
        final fileName = 'fields/${DateTime.now().millisecondsSinceEpoch}.jpg';
        final storageRef = FirebaseStorage.instance.ref().child(fileName);

        UploadTask uploadTask;
        if (kIsWeb) {
          final bytes = await _selectedImageFile!.readAsBytes();
          uploadTask = storageRef.putData(bytes);
        } else {
          uploadTask = storageRef.putFile(File(_selectedImageFile!.path));
        }

        final snapshot = await uploadTask.whenComplete(() {});
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      final price = int.tryParse(priceController.text.trim()) ?? 0;
      final fieldData = {
        "area_id": areaId, // Sử dụng areaId đã cập nhật
        "open_time": Timestamp.fromDate(DateTime(1970, 1, 1)), // Biểu thị 24/24
        "close_time": Timestamp.fromDate(DateTime(9999, 12, 31)), // Biểu thị 24/24
        "description": noteController.text.trim(),
        "name": nameController.text.trim(),
        "diaChi": addressController.text.trim(),
        "phone": phoneController.text.trim(),
        "sport": selectedCategory!,
        "deposit_percent": double.tryParse(depositController.text.trim()) ?? 0,
        "image": imageUrl ?? '',
        "ownerId": user.uid,
        "createdAt": FieldValue.serverTimestamp(),
      };

      final fieldsRef = FirebaseFirestore.instance.collection("fields");
      DocumentReference fieldRef;

      if (widget.fieldData == null) {
        // Thêm sân mới và lấy ID
        fieldRef = await fieldsRef.add(fieldData);
        fieldId = fieldRef.id;
      } else {
        await fieldsRef.doc(widget.fieldData!['id']).update(fieldData);
        fieldId = widget.fieldData!['id'];
      }

      // Cập nhật hoặc tạo tài liệu trong collection "areas"
      final areasRef = FirebaseFirestore.instance.collection("areas");
      final areaDocRef = areasRef.doc(areaId?.split('/').last); // Lấy ID từ areaId
      await areaDocRef.set({
        "address": addressController.text.trim(), // Cập nhật địa chỉ
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // Merge để không ghi đè các trường khác

      // Lưu hoặc cập nhật giá trong "prices" với tham chiếu
      final priceData = {
        "field_id": fieldsRef.doc(fieldId), // Tham chiếu đến sân
        "price_amount": price,
        "start_time": "00:00", // Lưu 00:00
        "end_time": "23:59",   // Lưu 23:59
        "percentage_price_change": 0, // Giá cố định
      };

      await FirebaseFirestore.instance
          .collection('prices')
          .doc(fieldId)
          .set(priceData, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Đã lưu sân và cập nhật khu vực thành công")),
      );

      // Làm mới danh sách sau khi lưu thành công
      if (mounted) {
        Navigator.pop(context, true); // Trả về true để báo hiệu cập nhật
      }
    } catch (e) {
      debugPrint("Lỗi lưu sân: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Lỗi: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffd6ecff),
      appBar: AppBar(
        backgroundColor: const Color(0xffd6ecff),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.fieldData == null ? "Thêm sân mới" : "Sửa thông tin sân",
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DanhSachSanScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Danh sách sân đã có",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<DocumentReference?>(
              future: _fieldPriceRef,
              builder: (context, priceSnapshot) {
                if (priceSnapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                if (priceSnapshot.hasData && priceSnapshot.data != null) {
                  return FutureBuilder<DocumentSnapshot>(
                    future: priceSnapshot.data!.get(),
                    builder: (context, priceDocSnapshot) {
                      if (priceDocSnapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      if (priceDocSnapshot.hasData && priceDocSnapshot.data!.exists) {
                        final priceData = priceDocSnapshot.data!.data() as Map<String, dynamic>?;
                        final price = priceData?['price_amount']?.toString() ?? '';
                        if (priceController.text.isEmpty) {
                          priceController.text = price;
                        }
                      }
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            FutureBuilder<List<String>>(
                              future: _sportsCategories,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const CircularProgressIndicator();
                                }
                                if (snapshot.hasError) {
                                  return const Text("Lỗi khi tải danh mục");
                                }
                                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                  return const Text("Không có danh mục");
                                }
                                return DropdownButtonFormField<String>(
                                  value: selectedCategory,
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  hint: const Text("Chọn danh mục"),
                                  items: snapshot.data!
                                      .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                                      .toList(),
                                  onChanged: (value) => setState(() => selectedCategory = value),
                                );
                              },
                            ),
                            _buildTextField("Nhập tên sân", nameController),
                            _buildTextField("Nhập địa chỉ sân", addressController),
                            _buildTextField("Nhập giá tiền/giờ", priceController,
                                keyboardType: TextInputType.number),
                            _buildTextField("Nhập số điện thoại", phoneController,
                                keyboardType: TextInputType.phone),
                            _buildTextField("Nhập mức cọc (%)", depositController,
                                keyboardType: TextInputType.number),
                            _buildTextField("Nhập ghi chú sân", noteController),
                            const SizedBox(height: 10),
                            GestureDetector(
                              onTap: _showImagePickerOptions,
                              child: Column(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.black26),
                                    ),
                                    child: _buildImagePreview(),
                                  ),
                                  const SizedBox(height: 4),
                                  const Text("Thêm ảnh"),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 30, vertical: 10),
                                  ),
                                  child: const Text("HỦY"),
                                ),
                                const SizedBox(width: 20),
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _saveField,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 30, vertical: 10),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text("LƯU"),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      FutureBuilder<List<String>>(
                        future: _sportsCategories,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const CircularProgressIndicator();
                          }
                          if (snapshot.hasError) {
                            return const Text("Lỗi khi tải danh mục");
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Text("Không có danh mục");
                          }
                          return DropdownButtonFormField<String>(
                            value: selectedCategory,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            hint: const Text("Chọn danh mục"),
                            items: snapshot.data!
                                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                                .toList(),
                            onChanged: (value) => setState(() => selectedCategory = value),
                          );
                        },
                      ),
                      _buildTextField("Nhập tên sân", nameController),
                      _buildTextField("Nhập địa chỉ sân", addressController),
                      _buildTextField("Nhập giá tiền/giờ", priceController,
                          keyboardType: TextInputType.number),
                      _buildTextField("Nhập số điện thoại", phoneController,
                          keyboardType: TextInputType.phone),
                      _buildTextField("Nhập mức cọc (%)", depositController,
                          keyboardType: TextInputType.number),
                      _buildTextField("Nhập ghi chú sân", noteController),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: _showImagePickerOptions,
                        child: Column(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.black26),
                              ),
                              child: _buildImagePreview(),
                            ),
                            const SizedBox(height: 4),
                            const Text("Thêm ảnh"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 10),
                            ),
                            child: const Text("HỦY"),
                          ),
                          const SizedBox(width: 20),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _saveField,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 30, vertical: 10),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text("LƯU"),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_selectedImageFile != null) {
      return FutureBuilder<Uint8List>(
        future: _selectedImageFile!.readAsBytes(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(snapshot.data!, fit: BoxFit.cover),
            );
          }
          return const CircularProgressIndicator();
        },
      );
    }
    if (widget.fieldData?['image'] != null &&
        widget.fieldData!['image'].toString().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(widget.fieldData!['image'], fit: BoxFit.cover),
      );
    }
    return const Icon(Icons.camera_alt, size: 30);
  }
}