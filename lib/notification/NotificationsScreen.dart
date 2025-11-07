import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  // Helper: convert many possible time_slot representations to a readable string
  String formatTimeSlot(dynamic timeSlot) {
    final DateFormat fmt = DateFormat('dd/MM HH:mm');

    DateTime? fromTs;
    DateTime? toTs;

    try {
      // 1) If it's a Firestore Timestamp
      if (timeSlot is Timestamp) {
        fromTs = timeSlot.toDate();
        return fmt.format(fromTs);
      }

      // 2) If it's a list/array [start, end] where items might be Timestamp or map
      if (timeSlot is List && timeSlot.isNotEmpty) {
        dynamic a = timeSlot[0];
        dynamic b = timeSlot.length > 1 ? timeSlot[1] : null;

        DateTime? parseSingle(dynamic x) {
          if (x == null) return null;
          if (x is Timestamp) return x.toDate();
          if (x is Map && x['seconds'] != null) {
            final secs = x['seconds'];
            final nanos = x['nanoseconds'] ?? 0;
            return DateTime.fromMillisecondsSinceEpoch(secs * 1000 + (nanos ~/ 1000000));
          }
          return null;
        }

        fromTs = parseSingle(a);
        toTs = parseSingle(b);

        if (fromTs != null && toTs != null) {
          return '${fmt.format(fromTs)} - ${fmt.format(toTs)}';
        } else if (fromTs != null) {
          return fmt.format(fromTs);
        }
      }

      // 3) If it's a Map that contains seconds/nanoseconds (single or start/end)
      if (timeSlot is Map) {
        // Possible shapes: { 'start': Timestamp or map, 'end': ... } or single { 'seconds': ..., 'nanoseconds': ... }
        DateTime? tryFromMap(Map m) {
          if (m['seconds'] != null) {
            final secs = m['seconds'];
            final nanos = m['nanoseconds'] ?? 0;
            return DateTime.fromMillisecondsSinceEpoch(secs * 1000 + (nanos ~/ 1000000));
          }
          return null;
        }

        if (timeSlot['start'] != null || timeSlot['end'] != null) {
          final s = timeSlot['start'];
          final e = timeSlot['end'];
          DateTime? sd = s is Timestamp ? s.toDate() : (s is Map ? tryFromMap(s) : null);
          DateTime? ed = e is Timestamp ? e.toDate() : (e is Map ? tryFromMap(e) : null);
          if (sd != null && ed != null) return '${fmt.format(sd)} - ${fmt.format(ed)}';
          if (sd != null) return fmt.format(sd);
        }

        // single timestamp map
        final single = tryFromMap(timeSlot);
        if (single != null) return fmt.format(single);
      }

      // 4) If it's a string that contains Timestamp(...) occurrences (like screenshot)
      if (timeSlot is String) {
        // try to extract seconds=NUMBER patterns (two of them ideally)
        final RegExp re = RegExp(r'seconds\s*=\s*(\d+)');
        final matches = re.allMatches(timeSlot).toList();
        if (matches.isNotEmpty) {
          List<DateTime> dates = [];
          for (final m in matches) {
            final secStr = m.group(1);
            if (secStr != null) {
              final secs = int.tryParse(secStr);
              if (secs != null) {
                dates.add(DateTime.fromMillisecondsSinceEpoch(secs * 1000));
              }
            }
          }
          if (dates.length >= 2) {
            return '${fmt.format(dates[0])} - ${fmt.format(dates[1])}';
          } else if (dates.length == 1) {
            return fmt.format(dates[0]);
          }
        }

        // if it's already a readable string, just return it trimmed
        if (timeSlot.trim().isNotEmpty) {
          return timeSlot.trim();
        }
      }
    } catch (e) {
      // ignore parse errors and fall through
    }

    return 'Không xác định';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 19, 153, 215),
        elevation: 0,
        title: const Text(
          "Thông báo",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
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

    final currentUserRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('user_id', isEqualTo: currentUserRef)
          .orderBy('created_at', descending: true)
          .snapshots(),
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
                final rawTimeSlot = data['time_slot']; // raw value from Firestore
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
                  if (address.isEmpty && data['field_id'] != null) {
                    try {
                      dynamic fieldRef = data['field_id'];
                      DocumentSnapshot? fieldDoc;
                      if (fieldRef is DocumentReference) {
                        fieldDoc = await fieldRef.get();
                      } else if (fieldRef is String) {
                        fieldDoc = await FirebaseFirestore.instance.collection('fields').doc(fieldRef).get();
                      }
                      if (fieldDoc != null && fieldDoc.exists) {
                        final fieldData = fieldDoc.data() as Map<String, dynamic>?;
                        dynamic areaRef = fieldData?['area_id'];
                        DocumentSnapshot? areaDoc;
                        if (areaRef is DocumentReference) {
                          areaDoc = await areaRef.get();
                        } else if (areaRef is String) {
                          areaDoc = await FirebaseFirestore.instance.collection('areas').doc(areaRef).get();
                        }
                        address = (areaDoc?.data() as Map<String, dynamic>?)?['address'] ?? 'Không có địa chỉ';
                      }
                    } catch (e) {
                      address = 'Không xác định';
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

                    // Format time slot using helper
                    final formattedTimeSlot = formatTimeSlot(rawTimeSlot);

                    final fullText = '''
$subtitle
$fieldName
Địa chỉ: $address
Khung giờ: $formattedTimeSlot
Hình thức thanh toán: $paymentMethod
'''.trim();

                    return _buildNotificationCard(
                      context,
                      index: index,
                      title: '$titleText - ${DateFormat('dd/MM HH:mm').format(createdAt)}',
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
          if (value && !isRead) {
            onTap();
          }
        },
      ),
    );
  }

  Future<void> _markAsRead(BuildContext context, String docId) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').doc(docId).update({'is_read': true});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi đánh dấu đã đọc: $e')),
        );
      }
    }
  }
}
