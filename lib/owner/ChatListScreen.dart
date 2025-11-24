
import 'package:fieldshub/user/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fieldshub/Database/database.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tin nhắn', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: Database.getConversationsStream(_currentUserId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Lỗi kết nối'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmpty();
          }

          final convs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return !Database.isConversationDeleted(data, _currentUserId);
          }).toList();

          if (convs.isEmpty) return _buildEmpty();

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: convs.length,
            itemBuilder: (context, index) {
              final convDoc = convs[index];
              final conv = convDoc.data() as Map<String, dynamic>;
              final convId = convDoc.id;

              // Lấy danh sách user trong cuộc trò chuyện
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
              final unreadCount = (conv['unreadCount'] as Map<String, dynamic>?)?[_currentUserId] ?? 0;

              
              String fallbackName = conv['ownerName']?.toString() ?? 'Chủ sân';
              String fallbackAvatar = (conv['ownerAvatar'] as String?) ?? '';

              return FutureBuilder<Map<String, String>>(
                future: Database.getOtherUserInfo(otherUserId),
                builder: (context, userSnap) {
                  String displayName = fallbackName;
                  String displayAvatar = fallbackAvatar;

                  if (userSnap.hasData && otherUserId.isNotEmpty) {
                    displayName = userSnap.data!['name']!;
                    displayAvatar = userSnap.data!['avatar']!;
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
          );
        },
      ),
    );
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
    final displayAvatar = avatarUrl.trim().isNotEmpty
        ? '$avatarUrl?w=100,h=100,c_fill'
        : '';

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
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        if (confirm == true) {
          await Database.deleteConversation(convId: convId, userId: _currentUserId);
        }
        return false;
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: CachedNetworkImage(
              imageUrl: displayAvatar,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(color: Colors.grey[300], child: const Icon(Icons.person)),
              errorWidget: (_, __, ___) => Container(color: Colors.grey[300], child: const Icon(Icons.person)),
            ),
          ),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          subtitle: Text(
            lastMessage.isEmpty ? 'Bắt đầu trò chuyện...' : lastMessage,
            style: TextStyle(color: lastMessage.isEmpty ? Colors.grey[500] : Colors.black87, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(timeStr, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              if (unreadCount > 0) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ],
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => ChatScreen(
                  fieldId: fieldId,
                  fieldName: fieldName,
                  otherUserId: otherUserId,
                ),
                transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
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
          const Text('Chưa có tin nhắn nào', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          const Text('Bắt đầu trò chuyện với chủ sân hoặc khách hàng!', style: TextStyle(color: Colors.grey)),
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
}