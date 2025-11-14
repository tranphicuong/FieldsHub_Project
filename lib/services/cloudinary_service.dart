import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CloudinaryService {
  static const String cloudName = 'dbvydjyb6';
  static const String uploadPreset = 'field_upload';

  static final cloudinary = CloudinaryPublic(cloudName, uploadPreset);
  static final firestore = FirebaseFirestore.instance;

  static Future<String?> uploadUserAvatar({
    required File imageFile,
    required String userId,
    required BuildContext context,
  }) async {
    try {
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      final imageUrl = response.secureUrl;

      await firestore.collection('users').doc(userId).update({
        'avatar': imageUrl,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cập nhật ảnh đại diện thành công!'),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 50, left: 20, right: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
      return imageUrl;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi upload: $e')));
      }
      return null;
    }
  }

  static Future<String?> uploadFieldImage({
    required File imageFile,
    required String fieldId,
    required BuildContext context,
  }) async {
    try {
      final response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      final imageUrl = response.secureUrl;

      await firestore.collection('fields').doc(fieldId).update({
        'image': imageUrl,
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cập nhật ảnh sân thành công!')),
        );
      }
      return imageUrl;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi upload: $e')));
      }
      return null;
    }
  }
}
