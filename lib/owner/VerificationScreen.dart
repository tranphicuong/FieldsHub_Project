import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class VerificationScreen extends StatefulWidget {
  const VerificationScreen({super.key});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  XFile? _frontId;
  XFile? _backId;
  XFile? _businessLicense;

  final ImagePicker _picker = ImagePicker();

  // Chọn ảnh (chạy được cả web và mobile)
  Future<void> _pickImage(ImageSource source, String type) async {
    final XFile? pickedFile =
        await _picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        switch (type) {
          case 'front':
            _frontId = pickedFile;
            break;
          case 'back':
            _backId = pickedFile;
            break;
          case 'license':
            _businessLicense = pickedFile;
            break;
        }
      });
    }
  }

  // Hộp thoại chọn ảnh
  void _showImagePickerOptions(String type) {
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
                _pickImage(ImageSource.gallery, type);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera, type);
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

  // Gửi xác minh
  void _submitVerification() {
    if (_frontId == null || _backId == null || _businessLicense == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng tải lên đầy đủ 3 hình ảnh!')),
      );
      return;
    }

    // ✅ Khi đủ 3 ảnh → chuyển sang màn hình chính
    Navigator.pushReplacementNamed(context, '/main');
  }

  Widget _buildImageBox(String title, XFile? imageFile, String type) {
    ImageProvider? imageProvider;
    if (imageFile != null) {
      if (kIsWeb) {
        imageProvider = NetworkImage(imageFile.path);
      } else {
        imageProvider = FileImage(File(imageFile.path));
      }
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showImagePickerOptions(type),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              imageFile != null
                  ? Image(image: imageProvider!, height: 150, fit: BoxFit.cover)
                  : Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: const Center(
                        child: Icon(Icons.camera_alt,
                            color: Colors.grey, size: 40),
                      ),
                    ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () => _showImagePickerOptions(type),
                icon: const Icon(Icons.upload),
                label: const Text("Chọn ảnh"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(150, 40),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Xác minh thông tin"),
        backgroundColor: const Color(0xFF004A8E),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildImageBox("CCCD mặt trước", _frontId, 'front'),
            _buildImageBox("CCCD mặt sau", _backId, 'back'),
            _buildImageBox("Giấy phép kinh doanh", _businessLicense, 'license'),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _submitVerification,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF004A8E),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                "Hoàn tất xác minh",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
      ),
    );
  }
}
