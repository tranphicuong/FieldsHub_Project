
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:fieldshub/Database/database.dart';

class ChatScreen extends StatefulWidget {
  final String fieldId;
  final String fieldName;
  final String? otherUserId;

  const ChatScreen({
    Key? key,
    required this.fieldId,
    required this.fieldName,
    this.otherUserId,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final TextEditingController _messageController = TextEditingController();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  final ScrollController _scrollController = ScrollController();

  String? _convId;
  String? _receiverId;

  String _chatWithName = 'Đang tải...';
  String _chatWithAvatar = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _messageController.addListener(() => setState(() {}));
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    if (!mounted) return;

    try {
      String otherUserId;
      
      
      if (widget.otherUserId != null && widget.otherUserId!.isNotEmpty) {
        otherUserId = widget.otherUserId!;
        print('DEBUG: Dùng otherUserId từ params: $otherUserId');
      } 
      
      else {
        final ownerId = await Database.getFieldOwnerId(widget.fieldId);
        
        if (ownerId == null || !mounted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Không tìm thấy chủ sân')),
            );
            Navigator.pop(context);
          }
          return;
        }
        
        otherUserId = ownerId;
        
      }

      
      final convId = Database.getConversationId(_currentUserId, otherUserId);
      
      

      if (!mounted) return;

      
      final receiverId = otherUserId;

      

      
      setState(() {
        _convId = convId;
        _receiverId = receiverId;
      });

      
      final info = await Database.getOtherUserInfo(receiverId);
      if (!mounted) return;

      setState(() {
        _chatWithName = info['name'] ?? 'Người dùng';
        _chatWithAvatar = info['avatar'] ?? '';
      });

      
    } catch (e) {
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải chat: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  void _sendMessage() async {
    if (_convId == null || _receiverId == null) {
      print('DEBUG: Không thể gửi - convId=$_convId, receiverId=$_receiverId');
      return;
    }
    
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    try {
      print('DEBUG: Gửi tin nhắn - convId=$_convId, receiverId=$_receiverId');
      
      
      await Database.sendMessage(
        convId: _convId!,
        text: text,
        senderId: _currentUserId,
        receiverId: _receiverId!,
        fieldId: widget.fieldId,
        fieldName: widget.fieldName,
      );

      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      print('DEBUG: Lỗi gửi tin: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi gửi tin nhắn: $e')),
      );
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _convId != null) {
      unawaited(Database.markConversationAsRead(
        convId: _convId!,
        userId: _currentUserId,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[300],
              backgroundImage: _chatWithAvatar.isNotEmpty
                  ? NetworkImage('$_chatWithAvatar?w=100,h=100,c_fill')
                  : null,
              child: _chatWithAvatar.isEmpty
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _chatWithName,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: _convId == null || _receiverId == null
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Đang kết nối chat...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: Database.getMessagesStream(_convId!),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'Bắt đầu cuộc trò chuyện!',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        );
                      }

                      final messages = snapshot.data!.docs;

                      return ListView.builder(
                        reverse: true,
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index].data() as Map<String, dynamic>;
                          final msgId = messages[index].id;
                          final senderId = msg['senderId'] as String? ?? '';
                          final isMe = senderId == _currentUserId;
                          final text = msg['text'] as String? ?? '';
                          final time = (msg['createdAt'] as Timestamp?)?.toDate();
                          final seen = (msg['seenBy'] as Map?)?[_receiverId] != null;
                          final deleted = (msg['deletedBy'] as Map?)?[_currentUserId] == true;

                          if (deleted || senderId.isEmpty) return const SizedBox.shrink();

                          return GestureDetector(
                            onLongPress: isMe
                                ? () => _showDeleteDialog(context, msgId)
                                : null,
                            child: Align(
                              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                                ),
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isMe ? Colors.blue[600] : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      text,
                                      style: TextStyle(
                                        color: isMe ? Colors.white : Colors.black87,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          time != null ? _formatTime(time) : '',
                                          style: TextStyle(
                                            color: isMe ? Colors.white70 : Colors.black54,
                                            fontSize: 11,
                                          ),
                                        ),
                                        if (isMe) ...[
                                          const SizedBox(width: 4),
                                          Icon(
                                            seen ? Icons.done_all : Icons.done,
                                            size: 14,
                                            color: seen ? Colors.white : Colors.white70,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                Container(
                  padding: EdgeInsets.only(
                    left: 12,
                    right: 12,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                    top: 12,
                  ),
                  color: Colors.grey[100],
                  child: Row(
                    children: [
                      Expanded(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 48, maxHeight: 130),
                          child: TextField(
                            controller: _messageController,
                            enabled: _convId != null,
                            textInputAction: TextInputAction.newline,
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                            decoration: InputDecoration(
                              hintText: 'Nhập tin nhắn...',
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: const BorderSide(color: Colors.blue, width: 2),
                              ),
                            ),
                            onSubmitted: (_) => _convId != null ? _sendMessage() : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: _convId != null && _messageController.text.trim().isNotEmpty
                            ? Colors.blue[600]
                            : Colors.grey[400],
                        child: IconButton(
                          icon: const Icon(Icons.send, color: Colors.white, size: 20),
                          onPressed: _convId != null && _messageController.text.trim().isNotEmpty ? _sendMessage : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(time.year, time.month, time.day);
    final hm = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    if (date == today) return hm;
    if (date == today.subtract(const Duration(days: 1))) return 'Hôm qua $hm';
    return '${time.day}/${time.month} $hm';
  }

  void _showDeleteDialog(BuildContext context, String msgId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa tin nhắn?'),
        content: const Text('Tin nhắn sẽ bị xóa với bạn.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              try {
                if (_convId != null) {
                  await Database.deleteMessage(
                    convId: _convId!,
                    messageId: msgId,
                    userId: _currentUserId,
                  );
                }
                Navigator.pop(context);
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi xóa tin nhắn: $e')),
                );
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}