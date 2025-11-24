import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CloudinaryService {
  static const String cloudName = 'dbvydjyb6';
  static const String uploadPreset = 'field_upload';

  static final cloudinary = CloudinaryPublic(cloudName, uploadPreset);
  static final firestore = FirebaseFirestore.instance;

  // Upload avatar người dùng
  static Future<String?> uploadUserAvatar({
    required File imageFile,
    required String userId,
    required BuildContext context,
  }) async {
    try {
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          resourceType: CloudinaryResourceType.Image, // ĐÃ SỬA: Dùng trực tiếp
        ),
      );

      final imageUrl = response.secureUrl;
      if (imageUrl == null) throw Exception('Upload thất bại: không có URL');

      await firestore.collection('users').doc(userId).update({
        'avatar': imageUrl,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cập nhật ảnh đại diện thành công!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 50, left: 20, right: 20),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      return imageUrl;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi upload: $e'), backgroundColor: Colors.red),
        );
      }
      debugPrint('Upload avatar error: $e');
      return null;
    }
  }

  // Upload ảnh sân
  static Future<String?> uploadFieldImage({
    required File imageFile,
    required String fieldId,
    required BuildContext context,
  }) async {
    try {
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          resourceType: CloudinaryResourceType.Image, // ĐÃ SỬA
        ),
      );

      final imageUrl = response.secureUrl;
      if (imageUrl == null) throw Exception('Upload thất bại: không có URL');

     await firestore.collection('fields').doc(fieldId).set({
  'image': imageUrl,
}, SetOptions(merge: true));

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cập nhật ảnh sân thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      return imageUrl;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi upload: $e'), backgroundColor: Colors.red),
        );
      }
      debugPrint('Upload field error: $e');
      return null;
    }
  }
    // THÊM HÀM MỚI: Upload 3 ảnh xác minh chủ sân (CCCD + Giấy phép kinh doanh)
  static Future<List<String>?> uploadVerificationImages({
    required XFile frontId,
    required XFile backId,
    required XFile businessLicense,
    required BuildContext context,
  }) async {
    try {
      // Khởi tạo lại cloudinary mỗi lần (rất quan trọng khi chạy Web)
      final cloudinary = CloudinaryPublic(
        cloudName,
        uploadPreset,
        cache: false, // Fix lỗi "uploadFile is undefined" trên Web
      );

      final List<String> urls = [];

      // Upload từng ảnh
      final frontResponse = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          frontId.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      final backResponse = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          backId.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );
      final licenseResponse = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          businessLicense.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      urls.add(frontResponse.secureUrl!);
      urls.add(backResponse.secureUrl!);
      urls.add(licenseResponse.secureUrl!);

      // Thông báo thành công
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload 3 ảnh thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      return urls; // Trả về [frontUrl, backUrl, licenseUrl]
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi upload ảnh xác minh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('Verification upload error: $e');
      return null;
    }
  }
}