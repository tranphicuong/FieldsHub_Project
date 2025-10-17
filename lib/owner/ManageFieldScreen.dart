import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'FieldListScreen.dart';

class ManageFieldScreen extends StatefulWidget {
  final Map<String, String>? fieldData; // Dữ liệu sân nếu đang sửa

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
  File? _selectedImage;

  String? selectedCategory;

  @override
  void initState() {
    super.initState();
    // ✅ Nạp dữ liệu cũ khi chỉnh sửa
    if (widget.fieldData != null) {
      nameController.text = widget.fieldData!['ten'] ?? '';
      addressController.text = widget.fieldData!['diaChi'] ?? '';
      priceController.text = widget.fieldData!['gia'] ?? '';
      phoneController.text = widget.fieldData!['soDienThoai'] ?? '';
      depositController.text = widget.fieldData!['coc'] ?? '';
      noteController.text = widget.fieldData!['ghiChu'] ?? '';
      selectedCategory = widget.fieldData!['danhMuc'];
    }
  }

  /// ✅ Mở bottom sheet chọn ảnh
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
                  final picked =
                      await picker.pickImage(source: ImageSource.gallery);
                  if (picked != null) {
                    setState(() => _selectedImage = File(picked.path));
                  }
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: const Center(
                    child: Text('Chụp ảnh mới',
                        style: TextStyle(color: Colors.blue))),
                onTap: () async {
                  final picked =
                      await picker.pickImage(source: ImageSource.camera);
                  if (picked != null) {
                    setState(() => _selectedImage = File(picked.path));
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

  /// ✅ Khi nhấn nút Lưu
  void _saveField() {
    if (nameController.text.isEmpty || addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập đủ thông tin bắt buộc")),
      );
      return;
    }

    final fieldData = {
      "ten": nameController.text,
      "diaChi": addressController.text,
      "gia": priceController.text,
      "soDienThoai": phoneController.text,
      "coc": depositController.text,
      "ghiChu": noteController.text,
      "danhMuc": selectedCategory ?? '',
    };

    Navigator.pop(context, fieldData); // ✅ Trả dữ liệu về
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
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const DanhSachSanScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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

            /// FORM
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildDropdown(),
                  _buildTextField("Nhập tên sân", nameController),
                  _buildTextField("Nhập địa chỉ sân", addressController),
                  _buildTextField("Nhập giá tiền/giờ", priceController,
                      keyboardType: TextInputType.number),
                  _buildTextField("Nhập số điện thoại", phoneController,
                      keyboardType: TextInputType.phone),
                  _buildTextField("Nhập mức cọc", depositController,
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
                          child: _selectedImage == null
                              ? const Icon(Icons.camera_alt, size: 30)
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(_selectedImage!,
                                      fit: BoxFit.cover),
                                ),
                        ),
                        const SizedBox(height: 4),
                        const Text("Thêm ảnh"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  /// Nút hủy/lưu
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
                        onPressed: _saveField,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 10),
                        ),
                        child: const Text("LƯU"),
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

  /// Widget ô nhập liệu
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

  /// Dropdown chọn danh mục sân
  Widget _buildDropdown() {
    final List<String> items = ['Bóng đá', 'Bi-a', 'Cầu lông'];

    return DropdownButtonFormField<String>(
      value: selectedCategory,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      hint: const Text("Chọn danh mục"),
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: (value) => setState(() => selectedCategory = value),
    );
  }
}
