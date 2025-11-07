import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DanhGiaCuaToiScreen extends StatelessWidget {
  const DanhGiaCuaToiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text("Vui lòng đăng nhập để xem đánh giá của bạn.")),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFD7EDFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD7EDFF),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Đánh giá của Tôi",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reviews')
            .where('user_id', isEqualTo: FirebaseFirestore.instance.doc('/users/${currentUser.uid}'))
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rate_review_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text("Bạn chưa có đánh giá nào.", style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                ],
              ),
            );
          }

          final reviews = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: reviews.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _ReviewItemWidget(reviewDoc: reviews[index]),
          );
        },
      ),
    );
  }
}

class _ReviewItemWidget extends StatelessWidget {
  final QueryDocumentSnapshot reviewDoc;
  const _ReviewItemWidget({required this.reviewDoc});

  @override
  Widget build(BuildContext context) {
    final data = reviewDoc.data() as Map<String, dynamic>;

    // Xử lý field_id và booking_id (string path)
    final String? fieldIdPath = data['field_id']?.toString();
    final String? bookingIdPath = data['booking_id']?.toString();

    final DocumentReference? fieldRef = fieldIdPath != null ? FirebaseFirestore.instance.doc(fieldIdPath) : null;
    final DocumentReference? bookingRef = bookingIdPath != null ? FirebaseFirestore.instance.doc(bookingIdPath) : null;

    // Xác định người dùng hiện tại
    final userRef = data['user_id'];
    final String userPath = userRef is DocumentReference ? userRef.path : userRef.toString();
    final bool isMe = userPath == '/users/${FirebaseAuth.instance.currentUser?.uid}';

    return FutureBuilder<List<DocumentSnapshot?>>(
      future: Future.wait([
        fieldRef?.get() ?? Future.value(null),
        bookingRef?.get() ?? Future.value(null),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingCard();
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return _buildErrorCard();
        }

        final fieldSnap = snapshot.data![0];
        final bookingSnap = snapshot.data![1];

        final fieldName = _getFieldName(fieldSnap);
        final fieldImage = _getFieldImage(fieldSnap);
        final address = _getAddress(bookingSnap);
        final comment = data['comment']?.toString() ?? 'Không có bình luận';
        final rating = (data['rating'] as num?)?.toDouble() ?? 0.0;
        final createdAt = (data['created_at'] as Timestamp?)?.toDate();

        return _buildReviewCard(
          fieldName: fieldName,
          fieldImage: fieldImage,
          comment: comment,
          rating: rating,
          createdAt: createdAt,
          address: address,
          isMe: isMe,
          userName: isMe ? "Bạn" : (data['user_name']?.toString() ?? 'Ẩn danh'),
          userAvatar: data['user_avatar']?.toString(),
        );
      },
    );
  }

  String _getFieldName(DocumentSnapshot? snap) {
    if (snap == null || !snap.exists) return 'Sân không xác định';
    final data = snap.data() as Map<String, dynamic>;
    return data['name']?.toString() ?? 'Không tên sân';
  }

  String? _getFieldImage(DocumentSnapshot? snap) {
    if (snap == null || !snap.exists) return null;
    final data = snap.data() as Map<String, dynamic>;
    return data['image']?.toString() ?? data['photoUrl']?.toString();
  }

  String _getAddress(DocumentSnapshot? snap) {
    if (snap == null || !snap.exists) return 'Chưa có địa chỉ';
    final data = snap.data() as Map<String, dynamic>;
    return data['address']?.toString() ?? 'Chưa có địa chỉ';
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: const Text("Lỗi tải dữ liệu", style: TextStyle(color: Colors.red), textAlign: TextAlign.center),
    );
  }

  Widget _buildReviewCard({
    required String fieldName,
    required String? fieldImage,
    required String comment,
    required double rating,
    required DateTime? createdAt,
    required String address,
    required bool isMe,
    required String userName,
    required String? userAvatar,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ảnh sân
          if (fieldImage != null && fieldImage.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: fieldImage,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 160,
                  color: Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 160,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Tên sân
          Text(
            fieldName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black87),
          ),

          const SizedBox(height: 8),

          // Bình luận
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              '"$comment"',
              style: const TextStyle(fontSize: 14.5, color: Colors.black87, fontStyle: FontStyle.italic, height: 1.5),
            ),
          ),

          const SizedBox(height: 12),

          // Sao đánh giá (hỗ trợ nửa sao)
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < rating.floor()
                    ? Icons.star
                    : (i < rating ? Icons.star_half : Icons.star_border),
                color: Colors.amber[600],
                size: 23,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Địa chỉ
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  address,
                  style: TextStyle(fontSize: 13.5, color: Colors.grey[700]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // Ngày đánh giá
          if (createdAt != null) ...[
            const SizedBox(height: 6),
            Text(
              "Ngày: ${DateFormat('dd/MM/yyyy – HH:mm').format(createdAt)}",
              style: TextStyle(fontSize: 12.5, color: Colors.grey[500]),
            ),
          ],

          const SizedBox(height: 12),

          // Avatar + Tên người đánh giá
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey[200],
                backgroundImage: userAvatar?.isNotEmpty == true
                    ? CachedNetworkImageProvider(userAvatar!)
                    : null,
                child: userAvatar?.isEmpty ?? true
                    ? const Icon(Icons.person, color: Colors.grey, size: 20)
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                userName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isMe ? Colors.blue[800] : Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
      ],
    );
  }
}