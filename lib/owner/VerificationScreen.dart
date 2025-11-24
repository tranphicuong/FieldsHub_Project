import 'dart:io';
import 'package:fieldshub/owner/field_owner_registration_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  bool _isUploading = false;

  Future<void> _pickImage(ImageSource source, String type) async {
    final XFile? picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked != null && mounted) {
      setState(() {
        switch (type) {
          case 'front':
            _frontId = picked;
            break;
          case 'back':
            _backId = picked;
            break;
          case 'license':
            _businessLicense = picked;
            break;
        }
      });
    }
  }

  void _showPicker(String type) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ thư viện'),
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
            const Divider(),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text('Hủy', style: TextStyle(color: Colors.red)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _uploadToCloudinary(XFile file) async {
    try {
      final cloudinary = CloudinaryPublic(
        'dbvydjyb6',
        'field_upload',
        cache: false, 
      );

      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          file.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      
      return response.secureUrl!;
    } catch (e) {
      debugPrint('Cloudinary upload error: $e');
      rethrow;
    }
  }

  Future<void> _submitVerification() async {
    if (_frontId == null || _backId == null || _businessLicense == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng tải lên đủ 3 ảnh!'), backgroundColor: Colors.red),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isUploading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      
      // Upload lần lượt 3 ảnh
      final frontUrl = await _uploadToCloudinary(_frontId!);
      final backUrl = await _uploadToCloudinary(_backId!);
      final licenseUrl = await _uploadToCloudinary(_businessLicense!);
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final statusRef = FirebaseFirestore.instance.doc('status/1');

      // Lưu vào Firestore
      await FirebaseFirestore.instance.collection('owner_documents').add({
        'user_id': userRef,
        'card_front': frontUrl,
        'card_back': backUrl,
        'business_license_image': licenseUrl,
        'status_id': statusRef,
        'created_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gửi hồ sơ thành công! Đang chờ duyệt...'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );

      // Chuyển sang nhập thông tin ngân hàng
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const FieldOwnerBankInfoScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi gửi hồ sơ: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Widget _buildImageBox(String title, XFile? file, String type) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showPicker(type),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              file == null
                  ? Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: const Icon(Icons.add_a_photo, size: 50, color: Colors.grey),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: kIsWeb
                          ? Image.network(file.path, height: 160, width: double.infinity, fit: BoxFit.cover)
                          : Image.file(File(file.path), height: 160, width: double.infinity, fit: BoxFit.cover),
                    ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _showPicker(type),
                icon: const Icon(Icons.camera_alt),
                label: Text(file == null ? 'Chọn ảnh' : 'Thay đổi'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue[700],
                  side: BorderSide(color: Colors.blue[700]!),
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
        title: const Text('Xác minh chủ sân'),
        centerTitle: true,
        backgroundColor: const Color(0xFF004A8E),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildImageBox('CCCD / CMND - Mặt trước', _frontId, 'front'),
                _buildImageBox('CCCD / CMND - Mặt sau', _backId, 'back'),
                _buildImageBox('Giấy phép kinh doanh', _businessLicense, 'license'),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _submitVerification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF004A8E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isUploading
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(width: 50, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                              SizedBox(width: 16),
                              Text('Đang gửi hồ sơ...', style: TextStyle(fontSize: 16)),
                            ],
                          )
                        : const Text('GỬI HỒ SƠ XÁC MINH', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          // Overlay loading toàn màn hình khi upload
          if (_isUploading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(strokeWidth: 3),
                        SizedBox(height: 16),
                        Text('Đang upload ảnh...', style: TextStyle(fontSize: 16, color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}