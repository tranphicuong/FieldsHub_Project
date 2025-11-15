// lib/user/chat_list_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fieldshub/user/chat_screen.dart';
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
          if (snapshot.hasError) return _buildError();
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
            return _buildEmpty();

          final convs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return !Database.isConversationDeleted(data, _currentUserId);
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: convs.length,
            itemBuilder: (context, index) {
              final conv = convs[index].data() as Map<String, dynamic>;
              final convId = convs[index].id;
              final ownerName = conv['ownerName']?.toString() ?? 'Chủ sân';
              final ownerAvatar = (conv['avatar'] as String?) ?? '';
              final lastMessage = conv['lastMessage'] ?? '';
              final lastTime = (conv['lastMessageAt'] as Timestamp?)?.toDate();
              final unreadCount =
                  (conv['unreadCount']
                      as Map<String, dynamic>?)?[_currentUserId] ??
                  0;

              return _buildChatTile(
                convId: convId,
                name: ownerName,
                avatarUrl: ownerAvatar,
                lastMessage: lastMessage,
                lastTime: lastTime,
                unreadCount: unreadCount,
                otherUserId: '',
                onDelete: () => _deleteConversation(convId),
                onTap: () {
                  final fieldId =
                      (convs[index].data() as Map<String, dynamic>?)?['fieldId']
                          as String?;
                  if (fieldId == null) return;

                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) =>
                          ChatScreen(fieldId: fieldId, fieldName: ownerName),
                      transitionsBuilder: (_, animation, __, child) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                    ),
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
    required String otherUserId,
    required VoidCallback onDelete,
    required VoidCallback onTap, // THÊM
  }) {
    final timeStr = lastTime != null ? _formatLastMessageTime(lastTime) : '';

    return Dismissible(
      key: Key(convId),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Xóa cuộc trò chuyện?'),
            content: const Text('Bạn có chắc muốn xóa cuộc trò chuyện này?'),
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
          await Database.deleteConversation(
            convId: convId,
            userId: _currentUserId,
          );
          onDelete();
        }
        return false;
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: CachedNetworkImage(
              imageUrl: avatarUrl,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.person),
              ),
              errorWidget: (_, __, ___) => Container(
                color: Colors.grey[300],
                child: const Icon(Icons.person),
              ),
            ),
          ),
          title: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
          subtitle: Text(
            lastMessage.isEmpty ? 'Bắt đầu trò chuyện...' : lastMessage,
            style: TextStyle(
              color: lastMessage.isEmpty ? Colors.grey[500] : Colors.black87,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ],
            ],
          ),
          onTap: onTap, // DÙNG onTap
        ),
      ),
    );
  }

  void _deleteConversation(String convId) {
    setState(() {}); // Cập nhật UI
  }

  Widget _buildError() => const Center(child: Text('Lỗi kết nối'));

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 16),
        const Text('Chưa có tin nhắn nào', style: TextStyle(fontSize: 16)),
        const Text(
          'Bắt đầu trò chuyện với chủ sân!',
          style: TextStyle(color: Colors.grey),
        ),
      ],
    ),
  );

  String _formatLastMessageTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(time.year, time.month, time.day);

    if (date == today) return DateFormat('HH:mm').format(time);
    if (date == yesterday) return 'Hôm qua';
    if (date.difference(today).inDays > -7)
      return DateFormat('EEE').format(time);
    return DateFormat('dd/MM').format(time);
  }
}
