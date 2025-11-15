// lib/user/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fieldshub/Database/database.dart';

class ChatScreen extends StatefulWidget {
  final String fieldId;
  final String fieldName;

  const ChatScreen({
    Key? key,
    required this.fieldId,
    required this.fieldName,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final TextEditingController _messageController = TextEditingController();
  late final String _currentUserId;
  late final String _ownerId;     // <-- CHỦ SÂN (đúng người)
  late final String _convId;
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentUserId = FirebaseAuth.instance.currentUser!.uid;
    _initOwnerId(); // LẤY CHỦ SÂN TRƯỚC
  }

  // BƯỚC 1: LẤY ownerId TỪ fieldId
  Future<void> _initOwnerId() async {
    final ownerId = await Database.getFieldOwnerId(widget.fieldId);
    if (ownerId == null || !mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy chủ sân')),
      );
      Navigator.pop(context);
      return;
    }

    setState(() {
      _ownerId = ownerId;
      _convId = Database.getConversationId(_currentUserId, _ownerId);
    });

    await _initConversation(); // BƯỚC 2: TẠO/TÌM CONVERSATION
  }

  // BƯỚC 2: TẠO HOẶC LẤY CONVERSATION
  Future<void> _initConversation() async {
    try {
      await Database.createOrGetConversation(
        currentUserId: _currentUserId,
        fieldId: widget.fieldId,
        fieldName: widget.fieldName,
      );

      await Database.markConversationAsRead(convId: _convId, userId: _currentUserId);
      setState(() => _isLoading = false);

      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khởi tạo chat: $e')),
      );
    }
  }

  // GỬI TIN NHẮN
  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    try {
      await Database.sendMessage(
        convId: _convId,
        text: text,
        senderId: _currentUserId,
        receiverId: _ownerId, // <-- ĐÚNG NGƯỜI NHẬN
      );
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gửi tin nhắn thất bại')),
      );
    }
  }

  // SCROLL XUỐNG DƯỚI
  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
   );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isLoading) {
      Database.markConversationAsRead(convId: _convId, userId: _currentUserId);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat với ${widget.fieldName}'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Column(
        children: [
          // === DANH SÁCH TIN NHẮN ===
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: Database.getMessagesStream(_convId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text('Lỗi kết nối: ${snapshot.error}'),
                        TextButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'Bắt đầu cuộc trò chuyện!',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                  );
                }

                final messages = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>;
                    final msgId = messages[index].id;
                    final isMe = msg['senderId'] == _currentUserId;
                    final text = msg['text'] as String? ?? '';
                    final time = (msg['createdAt'] as Timestamp?)?.toDate();
                    final seen = (msg['seenBy'] as Map?)?[_currentUserId] != null;
                    final deleted = (msg['deletedBy'] as Map?)?[_currentUserId] == true;

                    if (deleted) return const SizedBox.shrink();

                    return GestureDetector(
                      onLongPress: isMe ? () => _showDeleteDialog(context, msgId) : null,
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
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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

          // === Ô NHẬP TIN NHẮN ===
          Container(
            padding: EdgeInsets.only(
              left: 8,
              right: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 8,
              top: 8,
            ),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    decoration: InputDecoration(
                      hintText: 'Aa',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.attach_file),
                        onPressed: () {
                          // TODO: Gửi ảnh
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blue[600],
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ĐỊNH DẠNG THỜI GIAN
  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(time.year, time.month, time.day);
    final hm = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    if (date == today) return hm;
    if (date == today.subtract(const Duration(days: 1))) return 'Hôm qua $hm';
    return '${time.day}/${time.month} $hm';
  }

  // XÓA TIN NHẮN
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
              await Database.deleteMessage(convId: _convId, messageId: msgId, userId: _currentUserId);
              Navigator.pop(context);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}