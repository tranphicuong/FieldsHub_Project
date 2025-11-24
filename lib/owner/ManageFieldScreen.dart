import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'FieldListScreen.dart';
import 'package:fieldshub/services/cloudinary_service.dart';

class ManageFieldScreen extends StatefulWidget {
  final Map<String, dynamic>? fieldData;
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
  XFile? _pickedImageFile;          // Dùng XFile → chạy được cả Web
  bool _isUploadingImage = false;   // Loading khi upload

  String? selectedCategory;
  String? fieldId;
  String areaId = "/areas/m7MXj6UwRGwOxt4ilk0A";

  bool _isLoading = false;
  late Future<List<String>> _sportsCategories;

  @override
  void initState() {
    super.initState();
    _sportsCategories = _fetchSportsCategories();

    if (widget.fieldData != null) {
      final data = widget.fieldData!;
      fieldId = data['id']?.toString();
      nameController.text = data['name'] ?? '';
      phoneController.text = data['soDienThoai'] ?? '';
      depositController.text = data['deposit']?.toString() ?? '';
      noteController.text = data['note'] ?? '';
      selectedCategory = data['sport'];

      // Load địa chỉ từ area_id
      if (data['area_id'] is DocumentReference) {
        areaId = (data['area_id'] as DocumentReference).path;
        FirebaseFirestore.instance.doc(areaId).get().then((doc) {
          if (doc.exists && mounted) {
            setState(() => addressController.text = doc['address'] ?? '');
          }
        });
      }

      // Load giá từ prices (dùng fieldId)
      if (fieldId != null) {
        FirebaseFirestore.instance.collection('prices').doc(fieldId).get().then((doc) {
          if (doc.exists && mounted) {
            final price = doc['price_amount']?.toString() ?? '';
            if (priceController.text.isEmpty) setState(() => priceController.text = price);
          }
        });
      }
    }
  }

  Future<List<String>> _fetchSportsCategories() async {
    final snap = await FirebaseFirestore.instance.collection('sports').get();
    return snap.docs.map((e) => e.id).toList();
  }

  // ===================== CHỌN ẢNH =====================
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text("Chọn ảnh sân", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text("Thư viện ảnh"),
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text("Chụp ảnh"),
              onTap: () => _pickImage(ImageSource.camera),
            ),
            if (_pickedImageFile != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("Xóa ảnh", style: TextStyle(color: Colors.red)),
                onTap: () {
                  setState(() => _pickedImageFile = null);
                  Navigator.pop(context);
                },
              ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text("Hủy"),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    Navigator.pop(context);
    final XFile? picked = await picker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1200,
    );
    if (picked != null) {
      setState(() => _pickedImageFile = picked);
    }
  }

  // ===================== UPLOAD ẢNH =====================
  // UPLOAD ẢNH QUA CLOUDINARY (chỉ gọi service của bạn)
  Future<String?> _uploadImageToCloudinary(String fieldId) async {
    if (_pickedImageFile == null) return null;

    setState(() => _isUploadingImage = true);

    try {
      // Cloudinary chấp nhận cả XFile.path trên Web và Mobile
      final file = File(_pickedImageFile!.path);
      final url = await CloudinaryService.uploadFieldImage(
        imageFile: file,
        fieldId: fieldId,
        context: context,
      );
      return url;
    } catch (e) {
      debugPrint("Lỗi upload Cloudinary: $e");
      return null;
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  // ===================== LƯU SÂN =====================
  Future<void> _saveField() async {
    if (nameController.text.trim().isEmpty ||
        addressController.text.trim().isEmpty ||
        priceController.text.trim().isEmpty ||
        phoneController.text.trim().isEmpty ||
        selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Vui lòng nhập đủ thông tin bắt buộc")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final ownerRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final fieldsRef = FirebaseFirestore.instance.collection("fields");
      final price = int.tryParse(priceController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

      late DocumentReference fieldRef;
      String currentFieldId;

      // Bước 1: Tạo ID trước để dùng cho upload ảnh
      if (widget.fieldData == null) {
        fieldRef = fieldsRef.doc(); // Tạo ID ngay
        currentFieldId = fieldRef.id;
      } else {
        currentFieldId = widget.fieldData!['id'];
        fieldRef = fieldsRef.doc(currentFieldId);
      }

      // Bước 2: Upload ảnh nếu có
      String? imageUrl;
      if (_pickedImageFile != null) {
        imageUrl = await _uploadImageToCloudinary(currentFieldId);
        if (imageUrl == null) {
          setState(() => _isLoading = false);
          return;
        }
      }

      // Bước 3: Dữ liệu sân
      final fieldData = {
        "area_id": FirebaseFirestore.instance.doc(areaId),
        "open_time": Timestamp.fromDate(DateTime.now().copyWith(hour: 0, minute: 0)),
        "close_time": Timestamp.fromDate(DateTime.now().copyWith(hour: 23, minute: 59)),
        "description": noteController.text.trim(),
        "name": nameController.text.trim(),
        "phone": phoneController.text.trim(),
        "sport": selectedCategory!,
        "sport_id": "sports/$selectedCategory",
        "deposit_percent": double.tryParse(depositController.text) ?? 0,
        "image": imageUrl ?? widget.fieldData?['image'] ?? '',
        "owner_id": ownerRef,
        if (widget.fieldData == null) "createdAt": FieldValue.serverTimestamp(),
      };

      // Bước 4: Lưu sân
      if (widget.fieldData == null) {
        await fieldRef.set(fieldData);
      } else {
        await fieldRef.update(fieldData);
      }

      // Cập nhật area + giá (giữ nguyên logic cũ)
      if (areaId == "/areas/m7MXj6UwRGwOxt4ilk0A") {
        final newArea = await FirebaseFirestore.instance.collection('areas').add({
          "address": addressController.text.trim(),
          "owner_id": ownerRef,
          "createdAt": FieldValue.serverTimestamp(),
        });
        await fieldRef.update({"area_id": newArea});
      } else {
        await FirebaseFirestore.instance.doc(areaId).set({
          "address": addressController.text.trim(),
          "updatedAt": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await FirebaseFirestore.instance.collection('prices').doc(currentFieldId).set({
        "field_id": fieldRef,
        "price_amount": price,
        "start_time": "00:00",
        "end_time": "23:59",
        "percentage_price_change": 0,
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã lưu sân thành công!")));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Lỗi: $e");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        title: Text(widget.fieldData == null ? "Thêm sân mới" : "Sửa thông tin sân"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Nút xem danh sách sân
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DanhSachSanScreen())),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Danh sách sân đã có", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Form chính (giữ nguyên giao diện cũ của bạn)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // Danh mục
                  FutureBuilder<List<String>>(
                    future: _sportsCategories,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const CircularProgressIndicator();
                      return DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        hint: const Text("Chọn danh mục"),
                        items: snapshot.data!.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (v) => setState(() => selectedCategory = v),
                      );
                    },
                  ),

                  _buildTextField("Nhập tên sân", nameController),
                  _buildTextField("Nhập địa chỉ sân", addressController),
                  _buildTextField("Nhập giá tiền/giờ", priceController, keyboardType: TextInputType.number),
                  _buildTextField("Nhập số điện thoại", phoneController, keyboardType: TextInputType.phone),
                  _buildTextField("Nhập mức cọc (%)", depositController, keyboardType: TextInputType.number),
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
                        const Text("Thêm ảnh", style: TextStyle(color: Colors.blue)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                        ),
                        child: const Text("HỦY"),
                      ),
                      const SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _saveField,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text("LƯU"),
                      ),
                    ],
                  ),
                ],
              ),
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

  // ===================== HIỂN THỊ ẢNH =====================
  Widget _buildImagePreview() {
    if (_isUploadingImage) {
      return const Center(child: CircularProgressIndicator(color: Colors.blue));
    }

    if (_pickedImageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: kIsWeb
            ? FutureBuilder<Uint8List>(
                future: _pickedImageFile!.readAsBytes(),
                builder: (_, snap) {
                  if (snap.hasData) return Image.memory(snap.data!, fit: BoxFit.cover);
                  return const CircularProgressIndicator();
                },
              )
            : Image.file(File(_pickedImageFile!.path), fit: BoxFit.cover),
      );
    }

    final oldUrl = widget.fieldData?['image'] as String?;
    if (oldUrl != null && oldUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(oldUrl, fit: BoxFit.cover,
          loadingBuilder: (_, child, progress) => progress == null ? child : const CircularProgressIndicator(),
          errorBuilder: (_, __, ___) => const Icon(Icons.error),
        ),
      );
    }

    return const Icon(Icons.camera_alt, size: 30, color: Colors.grey);
  }
}