// lib/screens/notifications_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fieldshub/Database/database.dart';

class NotificationsScreen extends StatefulWidget {
  final String userId;
  const NotificationsScreen({required this.userId, Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final ValueNotifier<List<bool>> _expanded;
  final Map<String, String> _addressCache = {};

  @override
  void initState() {
    super.initState();
    _expanded = ValueNotifier<List<bool>>([]);
  }

  @override
  void dispose() {
    _expanded.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 19, 153, 215),
        elevation: 0,
        title: const Text(
          "Thông báo",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (widget.userId.isEmpty) {
      return const Center(child: Text('Không có thông báo để hiển thị'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: Database.getNotificationsStream(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Lỗi tải thông báo: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.notifications_off, size: 60, color: Colors.grey),
                SizedBox(height: 16),
                Text('Chưa có thông báo nào', style: TextStyle(fontSize: 16)),
              ],
            ),
          );
        }

        final notifications = snapshot.data!.docs;
        if (_expanded.value.length != notifications.length) {
          _expanded.value = List<bool>.filled(notifications.length, false);
        }

        return ValueListenableBuilder<List<bool>>(
          valueListenable: _expanded,
          builder: (context, expanded, child) {
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final doc = notifications[index];
                final data = doc.data() as Map<String, dynamic>;
                final docId = doc.id;
                final titleText = data['title'] ?? 'Thông báo';
                final subtitle = data['subtitle'] ?? '';
                final fieldName = data['field_name'] ?? '';
                final timeSlot = data['time_slot'] ?? '';
                final paymentMethod = data['payment_method'] ?? '';
                final isRead = data['is_read'] ?? false;

                DateTime createdAt;
                try {
                  createdAt = (data['created_at'] as Timestamp).toDate();
                } catch (_) {
                  createdAt = DateTime.now();
                }

                Future<String> addressFuture() async {
                  if (_addressCache.containsKey(docId)) {
                    return _addressCache[docId]!;
                  }

                  String address = data['address'] ?? '';
                  if (address.isEmpty) {
                    final fieldId = data['field_id'];
                    String? fieldIdStr;

                    if (fieldId is DocumentReference) {
                      fieldIdStr = fieldId.id;
                    } else if (fieldId is String) {
                      fieldIdStr = fieldId;
                    }

                    if (fieldIdStr != null && fieldIdStr.isNotEmpty) {
                      address = await Database.getFieldAddress(fieldIdStr);
                    }
                  }

                  _addressCache[docId] = address;
                  return address;
                }

                return FutureBuilder<String>(
                  future: addressFuture(),
                  builder: (context, addrSnap) {
                    final address = addrSnap.data ?? 'Đang tải...';
                    final shortText = '$subtitle - $fieldName';
                    final fullText =
                        '''
                    $subtitle
                    $fieldName
                    Địa chỉ: $address
                    Khung giờ: $timeSlot
                    Hình thức thanh toán: $paymentMethod
                    '''
                            .trim();

                    return _buildNotificationCard(
                      context,
                      index: index,
                      title:
                          '$titleText - ${DateFormat('dd/MM HH:mm').format(createdAt)}',
                      shortText: shortText,
                      fullText: fullText,
                      isRead: isRead,
                      docId: docId,
                      expanded: expanded[index],
                      onTap: () {
                        final newExpanded = List<bool>.from(_expanded.value);
                        newExpanded[index] = !expanded[index];
                        _expanded.value = newExpanded;
                        if (!isRead) _markAsRead(context, docId);
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationCard(
    BuildContext context, {
    required int index,
    required String title,
    required String shortText,
    required String fullText,
    required bool isRead,
    required String docId,
    required bool expanded,
    required VoidCallback onTap,
  }) {
    return Card(
      color: isRead ? Colors.white : const Color(0xFFF5F5F5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 1,
      child: ExpansionTile(
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isRead ? Colors.black54 : Colors.black87,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          shortText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isRead ? Colors.black54 : Colors.black87,
            fontSize: 13,
          ),
        ),
        trailing: Icon(
          expanded ? Icons.expand_less : Icons.expand_more,
          color: isRead ? Colors.black54 : Colors.black87,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Text(
              fullText,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                height: 1.5,
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
        onExpansionChanged: (value) {
          if (value && !isRead) onTap();
        },
      ),
    );
  }

  Future<void> _markAsRead(BuildContext context, String docId) async {
    try {
      await Database.markNotificationAsRead(docId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi đánh dấu đã đọc: $e')));
      }
    }
  }
}
