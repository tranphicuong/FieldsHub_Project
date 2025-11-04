import 'dart:io';
import 'package:fieldshub/user/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isEditing = false;
  String gender = "Nam";
  File? _imageFile;

  final currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController birthController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  
  Future<void> _loadUserData() async {
    try {
      if (currentUser == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get();

      if (!mounted || !userDoc.exists) return;
      final data = userDoc.data();
      if (data == null) return;

      nameController.text = data['name'] ?? '';
      phoneController.text = data['phone'] ?? '';
      addressController.text = data['address'] ?? '';
      gender = data['gender'] ?? 'Nam';

      if (data['dob'] != null) {
        if (data['dob'] is Timestamp) {
          final dob = (data['dob'] as Timestamp).toDate();
          birthController.text = "${dob.day}/${dob.month}/${dob.year}";
        } else if (data['dob'] is String) {
          birthController.text = data['dob'];
        } else {
          birthController.text = "";
        }
      } else {
        birthController.text = "";
      }

      if (mounted) setState(() {});
    } catch (e, stack) {
      debugPrint('🔥 Lỗi khi tải dữ liệu người dùng: $e');
      debugPrintStack(stackTrace: stack);
    }
  }

  // 🔹 Chọn ảnh có kiểm tra lỗi & quyền
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: source);
      if (!mounted) return;
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('⚠️ Lỗi chọn ảnh: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể mở máy ảnh hoặc thư viện.')),
      );
    }
  }

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

  // 🔹 Lưu thông tin người dùng
  Future<void> _saveUserData() async {
    if (currentUser == null) return;
    try {
      Timestamp? dobTimestamp;
      if (birthController.text.isNotEmpty) {
        final parts = birthController.text.split('/');
        if (parts.length == 3) {
          final day = int.tryParse(parts[0]);
          final month = int.tryParse(parts[1]);
          final year = int.tryParse(parts[2]);
          if (day != null && month != null && year != null) {
            dobTimestamp = Timestamp.fromDate(DateTime(year, month, day));
          }
        }
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .update({
            'name': nameController.text,
            'dob': dobTimestamp,
            'phone': phoneController.text,
            'address': addressController.text,
            'gender': gender,
          });

      if (!mounted) return;
      setState(() => isEditing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Đã lưu thông tin thành công'),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 50, left: 20, right: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi lưu thông tin: $e')));
    }
  }

  // 🔹 Widget nhập liệu
  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool enabled = false,
    int maxLines = 1,
  }) {
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

  @override
  void dispose() {
    nameController.dispose();
    birthController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1399D7),
        elevation: 0,
        title: const Text(
          "Hồ sơ cá nhân",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _showImagePickerOptions,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.blue[200],
                backgroundImage: _imageFile != null
                    ? FileImage(_imageFile!)
                    : null,
                child: _imageFile == null
                    ? const Icon(Icons.person, size: 70, color: Colors.white)
                    : null,
              ),
            ),
            TextButton(
              onPressed: _showImagePickerOptions,
              child: const Text("Sửa", style: TextStyle(color: Colors.black54)),
            ),
            const Divider(thickness: 1, color: Colors.black26),
            const SizedBox(height: 10),

            _buildTextField("Tên", nameController, enabled: isEditing),
            const SizedBox(height: 10),
            _buildTextField("Năm sinh", birthController, enabled: isEditing),
            const SizedBox(height: 10),
            _buildTextField(
              "Số điện thoại",
              phoneController,
              enabled: isEditing,
            ),
            const SizedBox(height: 10),

            Align(
              alignment: Alignment.centerLeft,
              child: const Text(
                "Giới tính",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Row(
              children: [
                Radio(
                  value: "Nam",
                  groupValue: gender,
                  onChanged: isEditing
                      ? (value) => setState(() => gender = value as String)
                      : null,
                ),
                const Text("Nam"),
                const SizedBox(width: 20),
                Radio(
                  value: "Nữ",
                  groupValue: gender,
                  onChanged: isEditing
                      ? (value) => setState(() => gender = value as String)
                      : null,
                ),
                const Text("Nữ"),
              ],
            ),
            const SizedBox(height: 10),

            _buildTextField(
              "Địa chỉ",
              addressController,
              enabled: isEditing,
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Xác nhận đăng xuất'),
                          content: const Text(
                            'Bạn có chắc chắn muốn đăng xuất không?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text('Hủy'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text('Đăng xuất'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        await FirebaseAuth.instance.signOut();
                        if (!mounted) return;
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Đăng xuất'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isEditing
                        ? _saveUserData
                        : () => setState(() => isEditing = true),
                    icon: const Icon(Icons.edit),
                    label: Text(
                      isEditing ? "Lưu thông tin" : "Chỉnh sửa thông tin",
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink[100],
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
