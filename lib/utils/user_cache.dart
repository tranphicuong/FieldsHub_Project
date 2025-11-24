import 'package:fieldshub/Database/database.dart';

/// Cache user info để tránh query Firestore nhiều lần
class UserCache {
  static final Map<String, Map<String, String>> _cache = {};
  static final Map<String, DateTime> _expiry = {};
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Lấy thông tin user (từ cache hoặc Firestore)
  static Future<Map<String, String>> getUserInfo(String uid) async {
    if (uid.isEmpty || uid == 'null' || uid == 'undefined') {
      return {'name': 'Khách hàng', 'avatar': ''};
    }

    // Kiểm tra cache
    if (_cache.containsKey(uid)) {
      final expireTime = _expiry[uid];
      if (expireTime != null && DateTime.now().isBefore(expireTime)) {
        return _cache[uid]!; // Trả về từ cache
      }
    }

    // Fetch từ Firestore nếu chưa có cache hoặc hết hạn
    try {
      final info = await Database.getOtherUserInfo(uid);
      
      // Lưu vào cache
      _cache[uid] = info;
      _expiry[uid] = DateTime.now().add(_cacheDuration);
      
      return info;
    } catch (e) {
      // Trả về default nếu lỗi
      return {'name': 'Khách hàng', 'avatar': ''};
    }
  }

  /// Xóa toàn bộ cache
  static void clear() {
    _cache.clear();
    _expiry.clear();
  }
  
  /// Xóa cache của 1 user cụ thể
  static void clearUser(String uid) {
    _cache.remove(uid);
    _expiry.remove(uid);
  }
  
  /// Preload nhiều user cùng lúc
  static Future<void> preloadUsers(List<String> uids) async {
    final futures = uids
        .where((uid) => uid.isNotEmpty && !_cache.containsKey(uid))
        .map((uid) => getUserInfo(uid));
    
    await Future.wait(futures);
  }
}