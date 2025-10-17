import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileMainScreen extends StatefulWidget {
  const ProfileMainScreen({super.key});

  @override
  State<ProfileMainScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileMainScreen> {
  bool isEditing = false;
  String gender = "Nam";
  File? _imageFile;

  // Controller cho các trường thông tin
  final TextEditingController nameController =
      TextEditingController(text: "Nguyễn Văn A");
  final TextEditingController birthController =
      TextEditingController(text: "1/1/2000");
  final TextEditingController phoneController =
      TextEditingController(text: "0123456789");
  final TextEditingController addressController =
      TextEditingController(text: "59/3/1a, Thôn phước lộc 2, xã Eaphê, tỉnh Đắk Lắk");

  // Hàm chọn ảnh đại diện
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // Hiển thị hộp thoại chọn ảnh
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn ảnh sẵn có'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Hủy'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[0xFF004A8E],
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 19, 153, 215),
        centerTitle: true,
        elevation: 0,
        title: const Text(
          "Hồ sơ cá nhân",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Ảnh đại diện
            Column(
              children: [
                GestureDetector(
                  onTap: _showImagePickerOptions,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue[200],
                    backgroundImage:
                        _imageFile != null ? FileImage(_imageFile!) : null,
                    child: _imageFile == null
                        ? const Icon(Icons.person, size: 70, color: Colors.white)
                        : null,
                  ),
                ),
                TextButton(
                  onPressed: _showImagePickerOptions,
                  child: const Text("Sửa", style: TextStyle(color: Colors.black54)),
                ),
              ],
            ),
            

            const Divider(thickness: 1, color: Colors.black26),
            const SizedBox(height: 10),

            // Các ô nhập liệu
            _buildTextField("Tên", nameController, enabled: isEditing),
            const SizedBox(height: 10),
            _buildTextField("Năm sinh", birthController, enabled: isEditing),
            const SizedBox(height: 10),
            _buildTextField("Sđt", phoneController, enabled: isEditing),
            const SizedBox(height: 10),

            // Giới tính
            Align(
              alignment: Alignment.centerLeft,
              child: const Text("Giới tính",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            Row(
              children: [
                Radio(
                  value: "Nam",
                  groupValue: gender,
                  onChanged: isEditing
                      ? (value) => setState(() => gender = value.toString())
                      : null,
                ),
                const Text("Nam"),
                const SizedBox(width: 20),
                Radio(
                  value: "Nữ",
                  groupValue: gender,
                  onChanged: isEditing
                      ? (value) => setState(() => gender = value.toString())
                      : null,
                ),
                const Text("Nữ"),
              ],
            ),
            const SizedBox(height: 10),

            // Địa chỉ
            _buildTextField("Địa chỉ", addressController,
                enabled: isEditing, maxLines: 2),
            const SizedBox(height: 20),

            const SizedBox(height: 20),

            // Nút chỉnh sửa thông tin
            ElevatedButton.icon(
              onPressed: () => setState(() => isEditing = !isEditing),
              icon: const Icon(Icons.edit),
              label: Text(isEditing ? "Lưu thông tin" : "Chỉnh sửa thông tin"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pink[100],
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
              ),
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),

    );
  }

  // Ô nhập liệu có label
  Widget _buildTextField(String label, TextEditingController controller,
      {bool enabled = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}
