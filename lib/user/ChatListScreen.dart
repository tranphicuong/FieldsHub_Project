import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'chat_screen.dart';
import 'package:fieldshub/Database/database.dart';
import 'package:fieldshub/utils/user_cache.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final Map<String, Map<String, String>> _userInfoCache = {};
  bool _isPreloading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tin nhắn',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: Database.getConversationsStream(_currentUserId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Lỗi: ${snapshot.error}'),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmpty();
          }

          final convs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return !Database.isConversationDeleted(data, _currentUserId);
          }).toList();

          if (convs.isEmpty) return _buildEmpty();

          // Preload user info trong background
          _preloadUserInfos(convs);

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: convs.length,
            itemBuilder: (context, index) {
              final convDoc = convs[index];
              final conv = convDoc.data() as Map<String, dynamic>;
              final convId = convDoc.id;

              final users = List<String>.from(conv['users'] ?? []);
              final otherUserId = users.firstWhere(
                (id) => id != _currentUserId,
                orElse: () => '',
              );

              final fieldId = (conv['fieldId'] as DocumentReference?)?.id ??
                  conv['fieldId']?.toString() ??
                  '';

              final fieldName = conv['fieldName']?.toString() ?? 'Sân bóng';
              final lastMessage = (conv['lastMessage'] as String?) ?? '';
              final lastTime = (conv['lastMessageAt'] as Timestamp?)?.toDate();
              final unreadCount =
                  (conv['unreadCount'] as Map<String, dynamic>?)?[_currentUserId] ?? 0;

              // Lấy từ cache local
              String displayName = conv['ownerName']?.toString() ?? 'Chủ sân';
              String displayAvatar = (conv['ownerAvatar'] as String?) ?? '';

              if (_userInfoCache.containsKey(otherUserId) &&
                  otherUserId.isNotEmpty) {
                displayName = _userInfoCache[otherUserId]!['name']!;
                displayAvatar = _userInfoCache[otherUserId]!['avatar']!;
              }

              return _buildChatTile(
                convId: convId,
                name: displayName,
                avatarUrl: displayAvatar,
                lastMessage: lastMessage,
                lastTime: lastTime,
                unreadCount: unreadCount,
                fieldId: fieldId,
                fieldName: fieldName,
                otherUserId: otherUserId,
              );
            },
          );
        },
      ),
    );
  }

  /// Preload tất cả user info trong background
  void _preloadUserInfos(List<QueryDocumentSnapshot> convs) {
    if (_isPreloading) return;

    _isPreloading = true;

    // Lấy danh sách user IDs cần load
    final userIdsToLoad = <String>[];
    for (final convDoc in convs) {
      final conv = convDoc.data() as Map<String, dynamic>;
      final users = List<String>.from(conv['users'] ?? []);
      final otherUserId = users.firstWhere(
        (id) => id != _currentUserId,
        orElse: () => '',
      );

      if (otherUserId.isNotEmpty &&
          !_userInfoCache.containsKey(otherUserId)) {
        userIdsToLoad.add(otherUserId);
      }
    }

    // Load tất cả user info cùng lúc
    if (userIdsToLoad.isNotEmpty) {
      Future.wait(userIdsToLoad.map((uid) => UserCache.getUserInfo(uid)))
          .then((results) {
        if (mounted) {
          setState(() {
            for (int i = 0; i < userIdsToLoad.length; i++) {
              _userInfoCache[userIdsToLoad[i]] = results[i];
            }
            _isPreloading = false;
          });
        }
      }).catchError((e) {
        _isPreloading = false;
      });
    } else {
      _isPreloading = false;
    }
  }

  Widget _buildChatTile({
    required String convId,
    required String name,
    required String avatarUrl,
    required String lastMessage,
    required DateTime? lastTime,
    required int unreadCount,
    required String fieldId,
    required String fieldName,
    required String otherUserId,
  }) {
    final timeStr = lastTime != null ? _formatTime(lastTime) : '';
    final displayAvatar =
        avatarUrl.trim().isNotEmpty ? '$avatarUrl?w=100,h=100,c_fill' : '';

    return Dismissible(
      key: Key(convId),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 36),
      ),
      confirmDismiss: (_) async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Xóa cuộc trò chuyện?'),
            content: const Text('Tin nhắn sẽ bị xóa khỏi danh sách của bạn.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        if (confirm == true) {
          try {
            await Database.deleteConversation(
              convId: convId,
              userId: _currentUserId,
            );
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Lỗi xóa: $e')),
              );
            }
          }
        }
        return false;
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: displayAvatar.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: displayAvatar,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    memCacheWidth: 112,
                    memCacheHeight: 112,
                    placeholder: (_, __) => Container(
                      width: 56,
                      height: 56,
                      color: Colors.grey[300],
                      child: const Icon(Icons.person),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 56,
                      height: 56,
                      color: Colors.grey[300],
                      child: const Icon(Icons.person),
                    ),
                  )
                : Container(
                    width: 56,
                    height: 56,
                    color: Colors.grey[300],
                    child: const Icon(Icons.person, size: 32),
                  ),
          ),
          title: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          subtitle: Text(
            lastMessage.isEmpty ? 'Bắt đầu trò chuyện...' : lastMessage,
            style: TextStyle(
              color:
                  lastMessage.isEmpty ? Colors.grey[500] : Colors.black87,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                timeStr,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              if (unreadCount > 0) ...[
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 20, minHeight: 20),
                  child: Center(
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  fieldId: fieldId,
                  fieldName: fieldName,
                  otherUserId: otherUserId,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Chưa có tin nhắn nào',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'Bắt đầu trò chuyện với chủ sân hoặc khách hàng!',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(time.year, time.month, time.day);

    if (date == today) return DateFormat('HH:mm').format(time);
    if (date == today.subtract(const Duration(days: 1))) return 'Hôm qua';
    return DateFormat('dd/MM').format(time);
  }

  @override
  void dispose() {
    _userInfoCache.clear();
    super.dispose();
  }
}