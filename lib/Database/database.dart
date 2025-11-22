import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

class Database {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // dang nhap
  static Future<Map<String, dynamic>?> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;
      final userDoc = await _firestore.collection('users').doc(uid).get();

      if (!userDoc.exists) return null;

      final data = userDoc.data();
      if (data == null) return null;

      final rolePath = data['role_id'];
      if (rolePath == null) return null;

      final DocumentReference roleRef = rolePath is DocumentReference
          ? rolePath
          : _firestore.doc(rolePath);
      final roleDoc = await roleRef.get();

      if (!roleDoc.exists) return null;

      final roleData = roleDoc.data() as Map<String, dynamic>?;
      final roleName = roleData?['name'] as String? ?? '';

      return {
        'uid': uid,
        'email': data['email'] ?? data['e-mail'],
        'role': roleName,
        'data': data,
      };
    } on FirebaseAuthException catch (e) {
      return Future.error(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw Exception('Đăng nhập thất bại: $e');
    }
  }
  //dang ky

  static Future<String?> registerUser({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user!.uid;

      await _firestore.collection('users').doc(uid).set({
        'name': name,
        'phone': phone,
        'email': email,
        'address': '',
        'avatar': '',
        'dob': null,
        'gender': '',
        'role_id': _firestore.collection('roles').doc('3'),
        'createdAt': FieldValue.serverTimestamp(),
      });

      return uid;
    } on FirebaseAuthException catch (e) {
      return Future.error(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw Exception('Đăng ký thất bại: $e');
    }
  }

  //cap nhat vai tro
  static Future<void> updateUserRole({
    required String uid,
    required DocumentReference roleRef,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'role_id': roleRef,
      });
    } catch (e) {
      throw Exception('Cập nhật vai trò thất bại: $e');
    }
  }

  //gui email dat lai mat khau
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      return Future.error(_getAuthErrorMessage(e.code));
    } catch (e) {
      throw Exception('Gửi email thất bại: $e');
    }
  }

  //dat lai mat khau
  static Future<void> resetPassword({required String newPassword}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Không có người dùng đang đăng nhập');
      await user.updatePassword(newPassword);
    } catch (e) {
      throw Exception('Đổi mật khẩu thất bại: $e');
    }
  }

  //lay du lieu nguoi dung
  static Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      throw Exception('Lấy dữ liệu thất bại: $e');
    }
  }

  //dang xuat
  static Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Đăng xuất thất bại: $e');
    }
  }

  // hien thi loi xac thuc
  static String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Tài khoản không tồn tại';
      case 'wrong-password':
        return 'Mật khẩu không đúng';
      case 'invalid-email':
        return 'Email không hợp lệ';
      case 'email-already-in-use':
        return 'Email đã được sử dụng';
      case 'weak-password':
        return 'Mật khẩu quá yếu (ít nhất 6 ký tự)';
      case 'requires-recent-login':
        return 'Vui lòng đăng nhập lại để thực hiện thao tác này';
      case 'invalid-credential':
        return 'Email hoặc mật khẩu không chính xác';
      case 'network-request-failed':
        return 'Không thể kết nối mạng. Vui lòng kiểm tra Internet.';
      default:
        return 'Đã xảy ra lỗi: $code';
    }
  }

  //booking
  static Future<String> createBooking({
    required String userId,
    required String? fieldId,
    required String fieldName,
    required String address,
    required DateTime startTime,
    required DateTime endTime,
    required double totalAmount,
    required double depositAmount,
    required String paymentMethod,
    required String bookingCode,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final fieldRef = fieldId != null
          ? _firestore.collection('fields').doc(fieldId)
          : null;

      final Map<String, dynamic> statusMap = {
        "pending": {'id': '1', 'name': 'Chờ xác nhận'},
        "paid": {'id': '2', 'name': 'Đã thanh toán'},
        "unpaid": {'id': '3', 'name': 'Chưa thanh toán'},
        "cancelled": {'id': '4', 'name': 'Đã hủy'},
        "approved": {'id': '5', 'name': 'Đã xác nhận'},
        "completed": {'id': '6', 'name': 'Hoàn thành'},
        "using": {'id': '7', 'name': 'Đang sử dụng'},
        "rejected": {'id': '8', 'name': 'Bị từ chối'},
      };

      final statusData = statusMap['pending']!;

      final docRef = await _firestore.collection('bookings').add({
        'user_id': userRef,
        'field_id': fieldRef,
        'field_name': fieldName,
        'address': address,
        'start_time': Timestamp.fromDate(startTime),
        'end_time': Timestamp.fromDate(endTime),
        'total_amount': totalAmount,
        'deposit_amount': depositAmount,
        'payment_method': paymentMethod,
        'booking_code': bookingCode,
        'status_id': _firestore.collection('status').doc(statusData['id']),
        'status': statusData['name'],
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Tạo booking thất bại: $e');
    }
  }

  //cap nhat trang thai booking
  static Future<void> updateBookingStatus({
    required String bookingId,
    required String statusKey,
  }) async {
    try {
      final Map<String, dynamic> statusMap = {
        "pending": {'id': '1', 'name': 'Chờ xác nhận'},
        "paid": {'id': '2', 'name': 'Đã thanh toán'},
        "unpaid": {'id': '3', 'name': 'Chưa thanh toán'},
        "cancelled": {'id': '4', 'name': 'Đã hủy'},
        "approved": {'id': '5', 'name': 'Đã xác nhận'},
        "completed": {'id': '6', 'name': 'Hoàn thành'},
        "using": {'id': '7', 'name': 'Đang sử dụng'},
        "rejected": {'id': '8', 'name': 'Bị từ chối'},
      };

      final statusData = statusMap[statusKey] ?? statusMap['pending']!;

      await _firestore.collection('bookings').doc(bookingId).update({
        'status_id': _firestore.collection('status').doc(statusData['id']),
        'status': statusData['name'],
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Cập nhật trạng thái booking thất bại: $e');
    }
  }

  //lay booking
  static Future<Map<String, dynamic>?> getBooking(String bookingId) async {
    try {
      final doc = await _firestore.collection('bookings').doc(bookingId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      throw Exception('Lấy booking thất bại: $e');
    }
  }

  //payment
  static Future<String> createPayment({
    required String bookingId,
    required double amount,
    required String qrCodeUrl,
    required String statusKey,
  }) async {
    try {
      final Map<String, String> statusMap = {
        "pending": '1',
        "paid": '2',
        "cancelled": '4',
      };

      final docRef = await _firestore.collection('payments').add({
        'booking_id': _firestore.collection('bookings').doc(bookingId),
        'amount': amount,
        'qr_code': qrCodeUrl,
        'status_id': _firestore
            .collection('status')
            .doc(statusMap[statusKey] ?? '1'),
        'created_at': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Tạo payment thất bại: $e');
    }
  }

  //cap nhat trang thai payment
  static Future<void> updatePaymentStatus({
    required String paymentId,
    required String statusKey,
  }) async {
    try {
      final Map<String, String> statusMap = {
        "pending": '1',
        "paid": '2',
        "cancelled": '4',
      };

      final updateData = <String, dynamic>{
        'status_id': _firestore
            .collection('status')
            .doc(statusMap[statusKey] ?? '1'),
      };

      if (statusKey == 'paid') {
        updateData['paid_at'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection('payments').doc(paymentId).update(updateData);
    } catch (e) {
      throw Exception('Cập nhật payment thất bại: $e');
    }
  }

  //lay payment theo booking id
  static Future<Map<String, dynamic>?> getPaymentByBookingId(
    String bookingId,
  ) async {
    try {
      final snap = await _firestore
          .collection('payments')
          .where(
            'booking_id',
            isEqualTo: _firestore.collection('bookings').doc(bookingId),
          )
          .limit(1)
          .get();

      return snap.docs.isNotEmpty ? snap.docs.first.data() : null;
    } catch (e) {
      throw Exception('Lấy payment thất bại: $e');
    }
  }

  // notifications

  static Future<void> sendNotification({
    required String userId,
    required String title,
    required String subtitle,
    String? fieldName,
    String? address,
    String? timeSlot,
    String? paymentMethod,
    String? bookingCode,
  }) async {
    return _sendNotificationWithFCM(
      userId: userId,
      title: title,
      body: subtitle,
      data: {
        'field_name': fieldName ?? '',
        'address': address ?? '',
        'time_slot': timeSlot ?? '',
        'payment_method': paymentMethod ?? '',
        'booking_code': bookingCode ?? '',
        'click_action': 'FLUTTER_NOTIFICATION_CLICK',
      },
    );
  }

  // Hàm phụ – gửi cả vào Firestore + FCM push thật
  static Future<void> _sendNotificationWithFCM({
    required String userId,
    required String title,
    required String body,
    required Map<String, String> data,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);

      // 1. Lưu thông báo vào Firestore (để hiển thị trong app)
      await _firestore.collection('notifications').add({
        'user_id': userRef,
        'title': title.trim(),
        'subtitle': body.trim(),
        'field_name': data['field_name']?.trim() ?? '',
        'address': data['address']?.trim() ?? '',
        'time_slot': data['time_slot']?.trim() ?? '',
        'payment_method': data['payment_method']?.trim() ?? '',
        'booking_code': data['booking_code']?.trim() ?? '',
        'is_read': false,
        'created_at': FieldValue.serverTimestamp(),
      });

      // 2. Gửi push thật lên điện thoại qua FCM
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcm_token'] as String?;

      if (fcmToken != null && fcmToken.isNotEmpty) {
        await _firestore.collection('fcm_messages').add({
          'to': fcmToken,
          'notification': {'title': title, 'body': body},
          'data': data,
          'time_to_live': 86400, // 24h
        });
      }
    } catch (e) {
      developer.log('Gửi thông báo thất bại (không ảnh hưởng app): $e');
    }
  }

  // danh dau da doc thong bao
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'is_read': true,
      });
    } catch (e) {
      throw Exception('Đánh dấu đã đọc thất bại: $e');
    }
  }

  // lay stream thong bao
  static Stream<QuerySnapshot> getNotificationsStream(String userId) {
    final userRef = _firestore.collection('users').doc(userId);
    return _firestore
        .collection('notifications')
        .where('user_id', isEqualTo: userRef)
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  // lay chu san bong
  static Future<String?> getFieldOwnerId(String fieldId) async {
    try {
      final fieldDoc = await _firestore.collection('fields').doc(fieldId).get();
      if (!fieldDoc.exists) return null;

      final data = fieldDoc.data()!;
      for (final key in [
        'owner',
        'owner_id',
        'ownerId',
        'ownerUid',
        'owner_ref',
        'ownerRef',
        'user_id',
        'userId',
      ]) {
        final value = data[key];
        if (value != null) {
          if (value is DocumentReference) return value.id;
          if (value is String) return value;
        }
      }

      final areaRef = data['area_id'];
      if (areaRef != null) {
        DocumentSnapshot? areaDoc;
        if (areaRef is DocumentReference) {
          areaDoc = await areaRef.get();
        } else if (areaRef is String) {
          areaDoc = await _firestore.collection('areas').doc(areaRef).get();
        }

        final areaData = areaDoc?.data() as Map<String, dynamic>?;
        final areaOwner = areaData?['owner_id'];
        if (areaOwner is DocumentReference) return areaOwner.id;
        if (areaOwner is String) return areaOwner;
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  // ghi danh gia review
  static Future<void> addReview({
    required String fieldId,
    required String bookingId,
    required double rating,
    required String comment,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception("User chưa đăng nhập");

      await _firestore.collection('reviews').add({
        'field_id': _firestore.collection('fields').doc(fieldId),
        'booking_id': _firestore.collection('bookings').doc(bookingId),
        'user_id': _firestore.collection('users').doc(user.uid),
        'rating': rating,
        'comment': comment,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      developer.log('❌ Lỗi khi thêm review: $e');
      rethrow;
    }
  }

  // doc review theo san bong
  static Stream<List<Map<String, dynamic>>> getReviewsByField(String fieldId) {
    final fieldRef = _firestore.collection('fields').doc(fieldId);

    return _firestore
        .collection('reviews')
        .where('field_id', isEqualTo: fieldRef)
        .orderBy('created_at', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final List<Map<String, dynamic>> reviews = [];

          for (final doc in snapshot.docs) {
            final data = doc.data();
            final userRef = data['user_id'] as DocumentReference?;

            String userName = 'Ẩn danh';
            String userAvatar = '';

            if (userRef != null) {
              try {
                final userSnap = await userRef.get();
                if (userSnap.exists) {
                  final userData = userSnap.data() as Map<String, dynamic>?;
                  userName = userData?['name'] ?? 'Ẩn danh';
                  userAvatar = userData?['avatar'] ?? '';
                }
              } catch (e) {
                developer.log('Lỗi lấy user: $e');
              }
            }

            reviews.add({
              'id': doc.id,
              'rating': data['rating'] ?? 0,
              'comment': data['comment'] ?? '',
              'created_at': (data['created_at'] as Timestamp?)?.toDate(),
              'user_name': userName,
              'user_avatar': userAvatar,
              'user_id': userRef,
            });
          }

          return reviews;
        });
  }

  // kiem tra da review chua
  static Future<bool> hasUserReviewedBooking({
    required String bookingId,
    required String userId,
  }) async {
    try {
      final bookingRef = _firestore.collection('bookings').doc(bookingId);
      final userRef = _firestore.collection('users').doc(userId);

      final snap = await _firestore
          .collection('reviews')
          .where('booking_id', isEqualTo: bookingRef)
          .where('user_id', isEqualTo: userRef)
          .limit(1)
          .get();

      return snap.docs.isNotEmpty;
    } catch (e) {
      developer.log('Lỗi kiểm tra review: $e');
      return true;
    }
  }

  // lay anh san bong
  static Future<String> getFieldImage(String fieldId) async {
    try {
      final doc = await _firestore.collection('fields').doc(fieldId).get();
      if (!doc.exists) return 'https://via.placeholder.com/150';

      final data = doc.data()!;
      final imageUrl = data['image'] as String?;

      return imageUrl?.isNotEmpty == true
          ? '$imageUrl?w_600,h_400,c_fill,f_auto' // CDN + resize
          : 'https://via.placeholder.com/150';
    } catch (e) {
      return 'https://via.placeholder.com/150';
    }
  }

  // tinh diem danh gia trung binh
  static Future<double> getFieldAverageRating(String fieldId) async {
    try {
      final fieldRef = _firestore.collection('fields').doc(fieldId);
      final snap = await _firestore
          .collection('reviews')
          .where('field_id', isEqualTo: fieldRef)
          .get();

      if (snap.docs.isEmpty) return 0.0;

      final total = snap.docs
          .map((doc) => (doc.data()['rating'] as num?)?.toDouble() ?? 0)
          .reduce((a, b) => a + b);

      return total / snap.docs.length;
    } catch (e) {
      developer.log('Lỗi tính rating: $e');
      return 0.0;
    }
  }

  //lay dia chi tu area
  static Future<String> getFieldAddress(String fieldId) async {
    try {
      final fieldDoc = await _firestore.collection('fields').doc(fieldId).get();
      if (!fieldDoc.exists) return '';

      final data = fieldDoc.data()!;
      final areaRef = data['area_id'];
      if (areaRef == null) return '';

      final DocumentSnapshot areaDoc;
      if (areaRef is DocumentReference) {
        areaDoc = await areaRef.get();
      } else if (areaRef is String) {
        areaDoc = await _firestore.collection('areas').doc(areaRef).get();
      } else {
        return '';
      }

      if (!areaDoc.exists) return '';

      final areaData = areaDoc.data() as Map<String, dynamic>?;
      final address = areaData?['address'] as String?;

      return address?.trim() ?? '';
    } catch (e) {
      developer.log('Lỗi lấy địa chỉ: $e');
      return '';
    }
  }

  //lay gia
  static Future<double> getFieldPrice(String fieldId) async {
    try {
      final fieldRef = _firestore.collection('fields').doc(fieldId);
      final snap = await _firestore
          .collection('prices')
          .where('field_id', isEqualTo: fieldRef)
          .get();

      if (snap.docs.isEmpty) return 0.0;

      double total = 0;
      for (var doc in snap.docs) {
        final num? price = doc.data()['price_amount'];
        if (price != null) total += price.toDouble();
      }

      return total / snap.docs.length;
    } catch (e) {
      return 0.0;
    }
  }

  static Future<Map<String, double>> getPricesForFields(
    List<String> fieldIds,
  ) async {
    if (fieldIds.isEmpty) return {};

    try {
      final fieldRefs = fieldIds
          .map((id) => _firestore.collection('fields').doc(id))
          .toList();

      final snap = await _firestore
          .collection('prices')
          .where('field_id', whereIn: fieldRefs)
          .get();

      final Map<String, List<double>> tempPrices = {};

      for (var doc in snap.docs) {
        final data = doc.data();
        final fieldRef = data['field_id'];
        if (fieldRef is DocumentReference) {
          final fieldId = fieldRef.id;
          final price = (data['price_amount'] as num?)?.toDouble();
          if (price != null) {
            tempPrices.putIfAbsent(fieldId, () => []).add(price);
          }
        }
      }

      final Map<String, double> avgPrices = {};
      tempPrices.forEach((id, prices) {
        final avg = prices.reduce((a, b) => a + b) / prices.length;
        avgPrices[id] = avg;
      });

      return avgPrices;
    } catch (e) {
      return {};
    }
  }

  //tao id cho 2 user
  static String getConversationId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  //tao chat neu chua ton tai
  static Future<String> createOrGetConversation({
    required String currentUserId,
    required String fieldId,
    required String fieldName,
  }) async {
    final ownerId = await getFieldOwnerId(fieldId);
    if (ownerId == null) throw Exception("Không tìm thấy chủ sân");

    final convId = getConversationId(currentUserId, ownerId);
    final convRef = _firestore.collection('conversations').doc(convId);

    final doc = await convRef.get();
    if (doc.exists) return convId; // Đã tồn tại, trả về

    // Nếu chưa tồn tại, trả về convId mà không tạo document
    return convId;
  }

  // Hàm mới: Tạo conversation khi gửi tin nhắn đầu tiên
  static Future<void> _createConversationIfNotExists({
    required String convId,
    required String currentUserId,
    required String fieldId,
    required String fieldName,
  }) async {
    final convRef = _firestore.collection('conversations').doc(convId);
    final doc = await convRef.get();

    if (doc.exists) return; // Đã tồn tại, không cần tạo

    // Tạo conversation khi gửi tin nhắn đầu tiên
    final ownerId = await getFieldOwnerId(fieldId);
    if (ownerId == null) throw Exception("Không tìm thấy chủ sân");

    final ownerDoc = await _firestore.collection('users').doc(ownerId).get();
    final ownerData = ownerDoc.data() ?? {};
    final ownerName = ownerData['name']?.toString() ?? 'Chủ sân';
    final ownerAvatar = (ownerData['avatar'] as String?)?.trim() ?? '';

    await convRef.set({
      'users': [currentUserId, ownerId],
      'fieldId': _firestore.collection('fields').doc(fieldId),
      'fieldName': fieldName,
      'ownerName': ownerName,
      'ownerAvatar': ownerAvatar,
      'lastMessage': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastSender': '',
      'createdAt': FieldValue.serverTimestamp(),
      'unreadCount': {currentUserId: 0, ownerId: 0},
      'deletedBy': {currentUserId: false, ownerId: false},
    });
  }

  // Sửa hàm sendMessage - tạo conversation khi gửi tin nhắn đầu tiên
  static Future<void> sendMessage({
    required String convId,
    required String text,
    required String senderId,
    required String receiverId,
    required String fieldId,
    required String fieldName,
  }) async {
    final convRef = _firestore.collection('conversations').doc(convId);

    final doc = await convRef.get();
    if (!doc.exists) {
      // Tạo conversation nếu chưa tồn tại
      await _createConversationIfNotExists(
        convId: convId,
        currentUserId: senderId,
        fieldId: fieldId,
        fieldName: fieldName,
      );
    }

    final msgRef = convRef.collection('messages').doc();
    final batch = _firestore.batch();

    batch.set(msgRef, {
      'text': text.trim(),
      'senderId': senderId,
      'type': 'text',
      'createdAt': FieldValue.serverTimestamp(),
      'seenBy': {senderId: FieldValue.serverTimestamp(), receiverId: null},
      'deletedBy': {senderId: false, receiverId: false},
      'field_id': _firestore.collection('fields').doc(fieldId),
    });

    batch.update(convRef, {
      'lastMessage': text.trim(),
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastSender': senderId,
      'unreadCount.$receiverId': FieldValue.increment(1),
      'unreadCount.$senderId': 0,
      'deletedBy.$senderId': false,
      'deletedBy.$receiverId': false,
    });

    await batch.commit();
  }

  //strem danh sach tin nhan
  static Stream<QuerySnapshot> getMessagesStream(String convId) {
    return _firestore
        .collection('conversations')
        .doc(convId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  //stream danh sach cuoc tro chuyen cua user
  static Stream<QuerySnapshot> getConversationsStream(String userId) {
    return _firestore
        .collection('conversations')
        .where('users', arrayContains: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots();
  }

  //lay ten nguoi dung tu id
  static Future<String> getUserName(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data()?['name'] ?? 'Người dùng';
    } catch (e) {
      return 'Người dùng';
    }
  }

  //xoa tin nhan
  static Future<void> deleteMessage({
    required String convId,
    required String messageId,
    required String userId,
  }) async {
    final msgRef = _firestore
        .collection('conversations')
        .doc(convId)
        .collection('messages')
        .doc(messageId);

    await msgRef.update({'deletedBy.$userId': true});
  }

  //xoa cuoc tro chuyen
static Future<void> deleteConversation({
  required String convId,
  required String userId,
}) async {
  try {
    final convRef = _firestore.collection('conversations').doc(convId);
    final convSnap = await convRef.get();
    
    if (!convSnap.exists) return;
    
    final convData = convSnap.data() as Map<String, dynamic>;
    final deletedBy = Map<String, dynamic>.from(convData['deletedBy'] ?? {});
    final users = List<String>.from(convData['users'] ?? []);
    
    // Đánh dấu user hiện tại đã xóa
    deletedBy[userId] = true;
    
    // Kiểm tra xem tất cả users đã xóa chưa
    bool allUsersDeleted = users.every((uid) => deletedBy[uid] == true);
    
    if (allUsersDeleted) {

      
      // Xóa tất cả messages trong conversation
      final messagesSnap = await convRef.collection('messages').get();
      final batch = _firestore.batch();
      
      for (final doc in messagesSnap.docs) {
        batch.delete(doc.reference);
      }
      
      // Xóa conversation document
      batch.delete(convRef);
      
      await batch.commit();
      
    } else {
      
      
      await convRef.update({
        'deletedBy.$userId': true,
        'unreadCount.$userId': 0,
      });
      
      
      final messagesSnap = await convRef
          .collection('messages')
          .where('deletedBy.$userId', isEqualTo: false)
          .get();
      
      if (messagesSnap.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in messagesSnap.docs) {
          batch.update(doc.reference, {'deletedBy.$userId': true});
        }
        await batch.commit();
      }
    }
  } catch (e) {
    developer.log('Lỗi xóa conversation: $e');
    rethrow;
  }
}

  //kiem tra xoa
  static bool isConversationDeleted(Map<String, dynamic> conv, String userId) {
    return (conv['deletedBy'] as Map<String, dynamic>?)?[userId] == true;
  }

  //lay ten va anh chu san
  static Future<Map<String, String>> getFieldOwnerInfo(String fieldId) async {
    final ownerId = await getFieldOwnerId(fieldId);
    if (ownerId == null) return {'name': 'Chủ sân', 'avatar': ''};

    try {
      final doc = await _firestore.collection('users').doc(ownerId).get();
      if (!doc.exists) return {'name': 'Chủ sân', 'avatar': ''};

      final data = doc.data()!;
      return {
        'name': data['name']?.toString() ?? 'Chủ sân',
        'avatar': (data['avatar'] as String?) ?? '',
      };
    } catch (e) {
      return {'name': 'Chủ sân', 'avatar': ''};
    }
  }

  // danh dau cuoc tro chuyen da doc
  static Future<void> markConversationAsRead({
    required String convId,
    required String userId,
  }) async {
    try {
      final convRef = _firestore.collection('conversations').doc(convId);

      // Reset số tin chưa đọc
      await convRef.update({'unreadCount.$userId': 0}).catchError((e) {
        developer.log('Lỗi update unreadCount: $e');
      });

      // Cập nhật seenBy cho tất cả tin nhắn chưa được đọc
      QuerySnapshot messagesSnap;
      try {
        messagesSnap = await convRef
            .collection('messages')
            .where('senderId', isNotEqualTo: userId)
            .where('seenBy.$userId', isEqualTo: null)
            .get();
      } catch (e) {
        developer.log('Lỗi lấy messages: $e');
        return; // Thoát nếu không lấy được messages
      }

      if (messagesSnap.docs.isEmpty) return;

      // Dùng batch thay vì transaction (an toàn hơn)
      final batch = _firestore.batch();
      for (final doc in messagesSnap.docs) {
        batch.update(doc.reference, {
          'seenBy.$userId': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      developer.log('markConversationAsRead error: $e');
      // Không throw exception để không làm gián đoạn quá trình
    }
  }

  String generateVietQR({
    required String bankBin,
    required String accountNumber,
    required String accountName,
    required double amount,
    required String description,
  }) {
    String normalizedName = accountName
        .toUpperCase()
        .replaceAll(RegExp(r'[ÀÁÂÃÄÅàáâãäå]'), 'A')
        .replaceAll(RegExp(r'[ÈÉÊËèéêë]'), 'E')
        .replaceAll(RegExp(r'[ÌÍÎÏìíîï]'), 'I')
        .replaceAll(RegExp(r'[ÒÓÔÕÖòóôõö]'), 'O')
        .replaceAll(RegExp(r'[ÙÚÛÜùúûü]'), 'U')
        .replaceAll(RegExp(r'[Đđ]'), 'D')
        .replaceAll(RegExp(r'[^A-Z0-9 ]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');

    String payload = "000201";
    payload += "010212";
    payload += "0010A0000007270129";

    String bankInfo = "00${bankBin.length.toString().padLeft(2, '0')}$bankBin";
    bankInfo +=
        "01${accountNumber.length.toString().padLeft(2, '0')}$accountNumber";
    payload +=
        "38${(bankInfo.length + 4).toString().padLeft(2, '0')}00${bankInfo.length.toString().padLeft(2, '0')}$bankInfo";

    payload += "52049399";
    payload += "5303704";

    // Số tiền
    String amountStr = amount.toInt().toString();
    payload += "54${amountStr.length.toString().padLeft(2, '0')}$amountStr";

    payload += "5802VN";

    // Tên chủ tài khoản
    payload +=
        "59${normalizedName.length.toString().padLeft(2, '0')}$normalizedName";

    // Nội dung chuyển khoản
    String descField =
        "07${description.length.toString().padLeft(2, '0')}$description";
    payload += "62${descField.length.toString().padLeft(2, '0')}$descField";

    // CRC
    payload += "6304";
    String crc = _calculateCRC16(payload);
    return payload + crc;
  }

  String _calculateCRC16(String data) {
    int crc = 0xFFFF;
    for (int i = 0; i < data.length; i++) {
      crc ^= (data.codeUnitAt(i) << 8);
      for (int j = 0; j < 8; j++) {
        if ((crc & 0x8000) != 0) {
          crc = (crc << 1) ^ 0x1021;
        } else {
          crc <<= 1;
        }
        crc &= 0xFFFF;
      }
    }
    return crc.toRadixString(16).toUpperCase().padLeft(4, '0');
  }
  
  
  // lay ten va anh nguoi dung khac
  static Future<Map<String, String>> getOtherUserInfo(String uid) async {
    
    if (uid.isEmpty || uid == 'null' || uid == 'undefined') {
      return {'name': 'Khách hàng', 'avatar': ''};
    }

    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        return {'name': 'Khách hàng', 'avatar': ''};
      }

      final data = doc.data()!;
      final name = data['name']?.toString();
      final avatar = (data['avatar'] as String?)?.trim();

      return {
        'name': name?.isNotEmpty == true ? name! : 'Khách hàng',
        'avatar': avatar?.isNotEmpty == true ? avatar! : '',
      };
    } catch (e) {
      developer.log('getOtherUserInfo error (uid: $uid): $e');
      return {'name': 'Khách hàng', 'avatar': ''};
    }
  }
}
