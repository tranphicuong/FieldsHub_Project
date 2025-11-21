import 'dart:async';
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

class _ChatScreenState extends State<ChatScreen>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {

  @override
  bool get wantKeepAlive => true;

  final TextEditingController _messageController = TextEditingController();
  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  String? _ownerId;
  String? _convId;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _messageController.addListener(() => setState(() {}));
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    final ownerId = await Database.getFieldOwnerId(widget.fieldId);
    if (!mounted) return;

    if (ownerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy chủ sân')));
      Navigator.pop(context);
      return;
    }

    setState(() {
      _ownerId = ownerId;
      _convId = Database.getConversationId(_currentUserId, _ownerId!);
    });
  }

  void _sendMessage() async {
    if (_convId == null) return;
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    await Database.sendMessage(
      convId: _convId!,
      text: text,
      senderId: _currentUserId,
      receiverId: _ownerId!,
      fieldId: widget.fieldId,
      fieldName: widget.fieldName,
    );

    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(0,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _convId != null) {
      unawaited(Database.markConversationAsRead(
          convId: _convId!, userId: _currentUserId));
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Bắt buộc cho KeepAlive

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat với ${widget.fieldName}'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: _convId == null
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
          : StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('conversations')
                  .doc(_convId)
                  .snapshots(),
              builder: (context, convSnapshot) {
                // SỬA LỖI TẠI ĐÂY: ép kiểu đúng và kiểm tra null
                final data = convSnapshot.data?.data();
                final bool isDeleted = data is Map<String, dynamic>
                    ? Database.isConversationDeleted(data, _currentUserId)
                    : false;

                final bool showEmpty = !convSnapshot.hasData ||
                    !convSnapshot.data!.exists ||
                    isDeleted;

                return Column(
                  children: [
                    Expanded(
                      child: showEmpty
                          ? const Center(
                              child: Text(
                                'Bắt đầu cuộc trò chuyện!',
                                style: TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                            )
                          : StreamBuilder<QuerySnapshot>(
                              stream: Database.getMessagesStream(_convId!),
                              builder: (context, msgSnapshot) {
                                if (!msgSnapshot.hasData ||
                                    msgSnapshot.data!.docs.isEmpty) {
                                  return const Center(
                                    child: Text(
                                      'Bắt đầu cuộc trò chuyện!',
                                      style: TextStyle(color: Colors.grey, fontSize: 16),
                                    ),
                                  );
                                }

                                final messages = msgSnapshot.data!.docs;

                                return ListView.builder(
                                  controller: _scrollController,
                                  reverse: true,
                                  padding: const EdgeInsets.all(12),
                                  itemCount: messages.length,
                                  itemBuilder: (context, index) {
                                    final msg = messages[index].data()
                                        as Map<String, dynamic>;
                                    final msgId = messages[index].id;
                                    final isMe = msg['senderId'] == _currentUserId;
                                    final text = msg['text'] as String? ?? '';
                                    final time = (msg['createdAt'] as Timestamp?)
                                        ?.toDate();
                                    final seen = (msg['seenBy'] as Map?)
                                            ?[_currentUserId] !=
                                        null;
                                    final deleted = (msg['deletedBy'] as Map?)
                                            ?[_currentUserId] ==
                                        true;
                                    if (deleted) return const SizedBox.shrink();

                                    return GestureDetector(
                                      onLongPress: isMe
                                          ? () => _showDeleteDialog(context, msgId)
                                          : null,
                                      child: Align(
                                        alignment: isMe
                                            ? Alignment.centerRight
                                            : Alignment.centerLeft,
                                        child: Container(
                                          constraints: BoxConstraints(
                                              maxWidth: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.75),
                                          margin: const EdgeInsets.only(bottom: 8),
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: isMe
                                                ? Colors.blue[600]
                                                : Colors.grey[300],
                                            borderRadius:
                                                BorderRadius.circular(16),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: isMe
                                                ? CrossAxisAlignment.end
                                                : CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                text,
                                                style: TextStyle(
                                                    color: isMe
                                                        ? Colors.white
                                                        : Colors.black87,
                                                    fontSize: 15),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    time != null
                                                        ? _formatTime(time)
                                                        : '',
                                                    style: TextStyle(
                                                        color: isMe
                                                            ? Colors.white70
                                                            : Colors.black54,
                                                        fontSize: 11),
                                                  ),
                                                  if (isMe) ...[
                                                    const SizedBox(width: 4),
                                                    Icon(
                                                      seen
                                                          ? Icons.done_all
                                                          : Icons.done,
                                                      size: 14,
                                                      color: seen
                                                          ? Colors.white
                                                          : Colors.white70,
                                                    ),
                                                  ]
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

                    // Ô NHẬP TIN NHẮN
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
                              constraints: const BoxConstraints(
                                  minHeight: 48, maxHeight: 130),
                              child: TextField(
                                controller: _messageController,
                                enabled: _convId != null,
                                textInputAction: TextInputAction.newline,
                                keyboardType: TextInputType.multiline,
                                maxLines: null,
                                decoration: InputDecoration(
                                  hintText: _convId == null
                                      ? 'Đang kết nối...'
                                      : 'Nhập tin nhắn...',
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(24),
                                      borderSide: BorderSide.none),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    borderSide: const BorderSide(
                                        color: Colors.blue, width: 2),
                                  ),
                                ),
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          CircleAvatar(
                            radius: 22,
                            backgroundColor:
                                _messageController.text.trim().isNotEmpty &&
                                        _convId != null
                                    ? Colors.blue[600]
                                    : Colors.grey[400],
                            child: IconButton(
                              icon: const Icon(Icons.send,
                                  color: Colors.white, size: 20),
                              onPressed: _messageController.text.trim().isNotEmpty &&
                                      _convId != null
                                  ? _sendMessage
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(time.year, time.month, time.day);
    final hm =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
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
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              await Database.deleteMessage(
                  convId: _convId!, messageId: msgId, userId: _currentUserId);
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
    _messageController.removeListener(() {});
    _messageController.dispose();
    _scrollController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}