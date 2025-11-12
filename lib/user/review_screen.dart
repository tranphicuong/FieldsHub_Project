import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fieldshub/Database/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:intl/intl.dart';

class ReviewScreen extends StatefulWidget {
  final String fieldId;
  final String bookingId;
  final String fieldName;
  final String fieldImage;

  const ReviewScreen({
    super.key,
    required this.fieldId,
    required this.bookingId,
    required this.fieldName,
    required this.fieldImage,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  double _userRating = 0;
  final TextEditingController _controller = TextEditingController();
  bool _isWriting = false;
  final currentUser = FirebaseAuth.instance.currentUser;

  bool get _canWriteReview => widget.bookingId.isNotEmpty;

  String _getRatingText(double rating) {
    if (rating >= 4.5) return "Xuất sắc";
    if (rating >= 4) return "Rất tốt";
    if (rating >= 3) return "Tốt";
    if (rating >= 2) return "Trung bình";
    return "Kém";
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4) return Colors.green;
    if (rating >= 3) return Colors.blue;
    if (rating >= 2) return Colors.orange;
    return Colors.red;
  }

  void _sendReview() async {
    if (_controller.text.trim().isEmpty || _userRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Vui lòng chọn sao và viết đánh giá"),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.only(bottom: 50, left: 20, right: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() => _isWriting = false);

    try {
      await Database.addReview(
        fieldId: widget.fieldId,
        bookingId: widget.bookingId,
        rating: _userRating,
        comment: _controller.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Cảm ơn bạn đã đánh giá!"),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 50, left: 20, right: 20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
        setState(() => _isWriting = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffeaf2fb),
      appBar: AppBar(
        backgroundColor: const Color(0xff1b5eaa),
        title: const Text(
          "Đánh giá sân",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.fieldImage.isNotEmpty
                        ? widget.fieldImage
                        : "https://cdn.tuoitre.vn/471584752817336320/2023/12/28/san-bong-da-17037384362191179016543.jpg",
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.sports_soccer,
                        size: 40,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.fieldName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FutureBuilder<double>(
                        future: Database.getFieldAverageRating(widget.fieldId),
                        builder: (context, snapshot) {
                          final avgRating = snapshot.data ?? 0.0;

                          return Row(
                            children: [
                              RatingBarIndicator(
                                rating: avgRating,
                                itemBuilder: (context, _) =>
                                    const Icon(Icons.star, color: Colors.amber),
                                itemSize: 20,
                                itemCount: 5,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                avgRating > 0
                                    ? avgRating.toStringAsFixed(1)
                                    : "Chưa có",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getRatingText(avgRating),
                                style: TextStyle(
                                  color: _getRatingColor(avgRating),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (_canWriteReview && !_isWriting)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _isWriting = true),
                icon: const Icon(Icons.edit, color: Colors.blue),
                label: const Text(
                  "Viết đánh giá",
                  style: TextStyle(color: Colors.blue),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.blue),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

          if (_isWriting)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Đánh giá của bạn",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: RatingBar.builder(
                      initialRating: 0,
                      minRating: 1,
                      itemCount: 5,
                      itemSize: 40,
                      itemBuilder: (context, _) =>
                          const Icon(Icons.star, color: Colors.amber),
                      onRatingUpdate: (rating) =>
                          setState(() => _userRating = rating),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _controller,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Chia sẻ trải nghiệm của bạn...',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _sendReview,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[800],
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Gửi đánh giá",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () => setState(() {
                          _isWriting = false;
                          _userRating = 0;
                          _controller.clear();
                        }),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.grey),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text("Hủy"),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: Database.getReviewsByField(widget.fieldId),
              builder: (context, snapshot) {
                final currentData = snapshot.data ?? [];

                if (snapshot.connectionState == ConnectionState.waiting &&
                    currentData.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (currentData.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.rate_review_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Chưa có đánh giá nào",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: currentData.length,
                  itemBuilder: (context, index) {
                    final r = currentData[index];
                    final isMe =
                        (r['user_id'] as DocumentReference?)?.id ==
                        currentUser?.uid;
                    final userName = isMe
                        ? "Bạn"
                        : (r['user_name'] ?? 'Ẩn danh');
                    final date = r['created_at'] != null
                        ? DateFormat('dd/MM/yyyy').format(r['created_at'])
                        : 'Không rõ';

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.blue[50] : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: isMe
                            ? Border.all(color: Colors.blue, width: 1)
                            : null,
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 4),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.grey[200],
                            backgroundImage:
                                r['user_avatar'].toString().isNotEmpty
                                ? NetworkImage(r['user_avatar'])
                                : null,
                            child: r['user_avatar'].toString().isEmpty
                                ? const Icon(Icons.person, color: Colors.grey)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      userName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: isMe
                                            ? Colors.blue[800]
                                            : Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      date,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                RatingBarIndicator(
                                  rating:
                                      (r['rating'] as num?)?.toDouble() ?? 0,
                                  itemBuilder: (context, _) => const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                  ),
                                  itemSize: 18,
                                  itemCount: 5,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  r['comment'],
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
