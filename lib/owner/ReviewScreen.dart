
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DanhGiaCuaToiScreen extends StatelessWidget {
  final dynamic ownerUserId; // Hỗ trợ String hoặc DocumentReference
  const DanhGiaCuaToiScreen({super.key, required this.ownerUserId});

  @override
  Widget build(BuildContext context) {
    // Chuyển thành DocumentReference nếu là String
    final DocumentReference ownerRef = ownerUserId is String
        ? FirebaseFirestore.instance.collection('users').doc(ownerUserId)
        : ownerUserId as DocumentReference;

    return Scaffold(
      backgroundColor: const Color(0xFFD7EDFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD7EDFF),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Đánh giá sân của chủ",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('fields')
            .where('owner_id', isEqualTo: ownerRef)
            .snapshots(),
        builder: (context, fieldSnapshot) {
          if (fieldSnapshot.hasError) {
            return _buildErrorWidget(context, fieldSnapshot.error.toString());
          }
          if (fieldSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!fieldSnapshot.hasData || fieldSnapshot.data!.docs.isEmpty) {
            return _buildEmptyWidget("Chủ sân này chưa có sân nào.");
          }

          final fieldDocs = fieldSnapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: fieldDocs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final fieldDoc = fieldDocs[index];
              final fieldRef = fieldDoc.reference;
              final fieldData = fieldDoc.data() as Map<String, dynamic>;
              final fieldName = fieldData['name']?.toString() ?? 'Sân không tên';
              final fieldImage = _getImageUrl(fieldData);

              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('reviews')
                    .where('field_id', isEqualTo: fieldRef)
                    .snapshots(),
                builder: (context, reviewSnapshot) {
                  final reviewCount = reviewSnapshot.data?.docs.length ?? 0;
                  final avgRating = _calculateAverageRating(reviewSnapshot.data?.docs);

                  return _FieldReviewSummaryCard(
                    fieldRef: fieldRef,
                    fieldName: fieldName,
                    fieldImage: fieldImage,
                    reviewCount: reviewCount,
                    avgRating: avgRating,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  double _calculateAverageRating(List<QueryDocumentSnapshot>? docs) {
    if (docs == null || docs.isEmpty) return 0.0;
    double total = 0;
    for (var doc in docs) {
      total += (doc['rating'] as num?)?.toDouble() ?? 0.0;
    }
    return total / docs.length;
  }

  String? _getImageUrl(Map<String, dynamic> data) {
    final image = data['image']?.toString();
    final photoUrl = data['photoUrl']?.toString();
    return image?.isNotEmpty == true ? image : (photoUrl?.isNotEmpty == true ? photoUrl : null);
  }

  Widget _buildErrorWidget(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 60),
          const SizedBox(height: 16),
          const Text("Lỗi tải dữ liệu", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(error, style: const TextStyle(color: Colors.red, fontSize: 13)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => DanhGiaCuaToiScreen(ownerUserId: ownerUserId)),
            ),
            child: const Text("Thử lại"),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_soccer, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

// Widget tóm tắt sân + đánh giá (có onTap dẫn đến màn hình chi tiết)
class _FieldReviewSummaryCard extends StatelessWidget {
  final DocumentReference fieldRef;
  final String fieldName;
  final String? fieldImage;
  final int reviewCount;
  final double avgRating;

  const _FieldReviewSummaryCard({
    required this.fieldRef,
    required this.fieldName,
    this.fieldImage,
    required this.reviewCount,
    required this.avgRating,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DanhGiaSanScreen(
              fieldRef: fieldRef,
              fieldName: fieldName,
              fieldImage: fieldImage,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            ClipRRect(
  borderRadius: BorderRadius.circular(12),
  child: fieldImage != null && fieldImage!.isNotEmpty
      ? CachedNetworkImage(
          imageUrl: fieldImage!,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            color: Colors.grey[200],
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          errorWidget: (_, __, ___) => Container(
            color: Colors.grey[200],
            child: const Icon(Icons.broken_image, color: Colors.grey),
          ),
        )
      : Container(
          width: 80,
          height: 80,
          color: Colors.grey[200],
          child: const Icon(Icons.image_not_supported, color: Colors.grey),
        ),
),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(fieldName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        "${avgRating.toStringAsFixed(1)} ($reviewCount đánh giá)",
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text("Nhấn để xem tất cả đánh giá", style: TextStyle(fontSize: 13, color: Colors.blue)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// Màn hình chi tiết đánh giá của 1 sân
class DanhGiaSanScreen extends StatelessWidget {
  final DocumentReference fieldRef;
  final String fieldName;
  final String? fieldImage;

  const DanhGiaSanScreen({
    super.key,
    required this.fieldRef,
    required this.fieldName,
    this.fieldImage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD7EDFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFD7EDFF),
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Đánh giá: $fieldName",
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reviews')
            .where('field_id', isEqualTo: fieldRef)
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _buildErrorWidget(context, snapshot.error.toString());
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyWidget("Chưa có đánh giá nào cho sân này.");
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

  Widget _buildErrorWidget(BuildContext context, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 60),
          const SizedBox(height: 16),
          const Text("Lỗi tải dữ liệu", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(error, style: const TextStyle(color: Colors.red, fontSize: 13)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => DanhGiaSanScreen(fieldRef: fieldRef, fieldName: fieldName, fieldImage: fieldImage)),
            ),
            child: const Text("Thử lại"),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.rate_review_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        ],
      ),
    );
  }
}

// Widget hiển thị từng đánh giá (giữ nguyên, đã có logic hiển thị sao)
class _ReviewItemWidget extends StatelessWidget {
  final QueryDocumentSnapshot reviewDoc;
  const _ReviewItemWidget({required this.reviewDoc});

  @override
  Widget build(BuildContext context) {
    final data = reviewDoc.data() as Map<String, dynamic>;

    final DocumentReference? fieldRef = _getRef(data['field_id']);
    final DocumentReference? bookingRef = _getRef(data['booking_id']);
    final DocumentReference? userRef = _getRef(data['user_id']);

    final bool isMe = userRef?.id == FirebaseAuth.instance.currentUser?.uid;

    return FutureBuilder<List<DocumentSnapshot?>>(
      future: Future.wait([
        fieldRef?.get() ?? Future.value(null),
        bookingRef?.get() ?? Future.value(null),
        userRef?.get() ?? Future.value(null),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return _buildLoadingCard();
        if (snapshot.hasError || !snapshot.hasData) return _buildErrorCard();

        final fieldSnap = snapshot.data![0];
        final bookingSnap = snapshot.data![1];
        final userSnap = snapshot.data![2];

        final fieldName = _getFieldName(fieldSnap);
        final fieldImage = _getFieldImage(fieldSnap);
        final address = _getAddress(bookingSnap);
        final comment = data['comment']?.toString() ?? 'Không có bình luận';
        final rating = (data['rating'] as num?)?.toDouble() ?? 0.0; // Rating từ DB (1-5 sao)
        final createdAt = (data['created_at'] as Timestamp?)?.toDate();

        final userName = isMe
            ? "Bạn"
            : (userSnap?.data() as Map<String, dynamic>?)?['name']?.toString() ?? 'Ẩn danh';
        final userAvatar = (userSnap?.data() as Map<String, dynamic>?)?['avatar']?.toString();

        return _buildReviewCard(
          fieldName: fieldName,
          fieldImage: fieldImage,
          comment: comment,
          rating: rating, // Sử dụng rating để "gán sao"
          createdAt: createdAt,
          address: address,
          isMe: isMe,
          userName: userName,
          userAvatar: userAvatar,
        );
      },
    );
  }

  DocumentReference? _getRef(dynamic value) {
    if (value is DocumentReference) return value;
    if (value is String && value.isNotEmpty) return FirebaseFirestore.instance.doc(value);
    return null;
  }

  String _getFieldName(DocumentSnapshot? snap) {
    if (snap == null || !snap.exists) return 'Sân không xác định';
    final data = snap.data() as Map<String, dynamic>;
    return data['name']?.toString() ?? 'Không tên sân';
  }

  String? _getFieldImage(DocumentSnapshot? snap) {
    if (snap == null || !snap.exists) return null;
    final data = snap.data() as Map<String, dynamic>;
    final image = data['image']?.toString();
    final photoUrl = data['photoUrl']?.toString();
    return image?.isNotEmpty == true ? image : (photoUrl?.isNotEmpty == true ? photoUrl : null);
  }

  String _getAddress(DocumentSnapshot? snap) {
    if (snap == null || !snap.exists) return 'Chưa có địa chỉ';
    final data = snap.data() as Map<String, dynamic>;
    return data['address']?.toString() ?? 'Chưa có địa chỉ';
  }

  Widget _buildLoadingCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );

  Widget _buildErrorCard() => Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: const Text("Lỗi tải dữ liệu", style: TextStyle(color: Colors.red), textAlign: TextAlign.center),
      );

  Widget _buildReviewCard({
    required String fieldName,
    required String? fieldImage,
    required String comment,
    required double rating, // Gán rating từ DB để hiển thị sao
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
          if (fieldImage != null && fieldImage.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: fieldImage,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.grey[200], height: 160, child: const Center(child: CircularProgressIndicator(strokeWidth: 2))),
                errorWidget: (_, __, ___) => Container(color: Colors.grey[200], height: 160, child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 40)),
              ),
            ),
          const SizedBox(height: 12),
          Text(fieldName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.black87)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey.shade300)),
            child: Text('"$comment"', style: const TextStyle(fontSize: 14.5, color: Colors.black87, fontStyle: FontStyle.italic, height: 1.5)),
          ),
          const SizedBox(height: 12),
          // PHẦN GÁN SAO: Hiển thị rating từ DB (1-5 sao)
          Row(
            children: List.generate(
              5,
              (i) => i < rating.floor()
                  ? const Icon(Icons.star, color: Colors.amber, size: 23) // Sao đầy
                  : i < rating
                      ? const Icon(Icons.star_half, color: Colors.amber, size: 23) // Sao nửa
                      : const Icon(Icons.star_border, color: Colors.amber, size: 23), // Sao rỗng
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(child: Text(address, style: TextStyle(fontSize: 13.5, color: Colors.grey[700]), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          if (createdAt != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text("Ngày: ${DateFormat('dd/MM/yyyy – HH:mm').format(createdAt)}", style: TextStyle(fontSize: 12.5, color: Colors.grey[500])),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.grey[200],
                backgroundImage: userAvatar?.isNotEmpty == true ? CachedNetworkImageProvider(userAvatar!) : null,
                child: userAvatar?.isEmpty ?? true ? const Icon(Icons.person, color: Colors.grey, size: 20) : null,
              ),
              const SizedBox(width: 8),
              Text(userName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isMe ? Colors.blue[800]! : Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4))],
      );
}