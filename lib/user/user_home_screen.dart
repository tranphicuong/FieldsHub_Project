import 'dart:io';
import 'package:fieldshub/user/chat_screen.dart';
import 'package:fieldshub/user/payment_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({Key? key}) : super(key: key);

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  String selectedCategory = "all";
  int selectedTab = 0;
  String userName = ' ';
  final currentUser = FirebaseAuth.instance.currentUser;

  RangeValues _priceRange = const RangeValues(100000, 200000);
  RangeValues _timeRange = const RangeValues(6, 22);
  Set<String> _selectedDistricts = {};
  int _selectedRating = 0;

  final Map<String, DateTime?> selectedDates = {};
  final Map<String, String?> selectedTimes = {};
  final Map<String, String> paymentMethods = {};

  final List<String> timeSlots = [
    "06:00",
    "07:00",
    "08:00",
    "09:00",
    "10:00",
    "11:00",
    "12:00",
    "13:00",
    "14:00",
    "15:00",
    "16:00",
    "17:00",
    "18:00",
    "19:00",
    "20:00",
    "21:00",
  ];

  // State cho ProfileMainScreen
  bool isEditing = false;
  String gender = "Nam";
  File? _imageFile;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController birthController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (currentUser == null) return;
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();
    if (userDoc.exists) {
      setState(() {
        final data = userDoc.data()!;
        userName = data['name'] ?? '';
        nameController.text = data['name'] ?? '';
        phoneController.text = data['phone'] ?? '';
        addressController.text = data['address'] ?? '';
        gender = data['gender'] ?? 'Nam';

        if(data['dob'] != null){
          DateTime dob = (data['dob'] as Timestamp).toDate();
          birthController.text = "${dob.day}/${dob.month}/${dob.year}";
        }else{
          birthController.text ="";
        }
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn ảnh sẵn có'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Chụp ảnh'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Hủy'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveUserData() async {
    if (currentUser == null) return;
    try {
      Timestamp? dobTimestamp;
      if(birthController.text.isNotEmpty){
        final parts = birthController.text.split('/');

        if(parts.length==3){
          int day = int.parse(parts[0]);
          int month = int.parse(parts[1]);
          int year = int.parse(parts[2]);
          dobTimestamp = Timestamp.fromDate(DateTime(year,month,day));
        }
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .update({
        'name': nameController.text,
        'dob': dobTimestamp,
        'phone': phoneController.text,
        'address': addressController.text,
        'gender': gender,
      });
      setState(() {
        isEditing = false;
        userName = nameController.text;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu thông tin thành công')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi lưu thông tin: $e')),
      );
    }
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {bool enabled = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          selectedTab == 3 ? Colors.lightBlue[0xFF004A8E] : Colors.blue[50],
      appBar: AppBar(
        backgroundColor:
            selectedTab == 3 ? const Color.fromARGB(255, 19, 153, 215) : Colors.blue[800],
        elevation: 0,
        title: selectedTab == 3
            ? const Text(
                "Hồ sơ cá nhân",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
              )
              : selectedTab ==2 ? const Text(
                "Thông báo",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              )
            : Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 22,
                    child: Icon(Icons.person, color: Colors.blue),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Xin chào",
                        style: TextStyle(fontSize: 13, color: Colors.white),
                      ),
                      Text(
                        userName.isNotEmpty ? userName : "Đang tải...",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
        actions: selectedTab != 3
            ? [
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                ChatScreen(fieldId: "default", fieldName: "Hỗ trợ chung")));
                  },
                ),
                const SizedBox(width: 8),
              ]
            : null,
      ),
      body: selectedTab == 4
          ? const _BookingHistoryTab()
          : selectedTab ==2 ?  _NotificationsTab(userId: currentUser?.uid ??'')
          : selectedTab == 1
              ? const _SearchTab()
              : selectedTab == 3
                  ? SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              GestureDetector(
                                onTap: _showImagePickerOptions,
                                child: CircleAvatar(
                                  radius: 50,
                                  backgroundColor: Colors.blue[200],
                                  backgroundImage:
                                      _imageFile != null ? FileImage(_imageFile!) : null,
                                  child: _imageFile == null
                                      ? const Icon(Icons.person,
                                          size: 70, color: Colors.white)
                                      : null,
                                ),
                              ),
                              TextButton(
                                onPressed: _showImagePickerOptions,
                                child: const Text("Sửa",
                                    style: TextStyle(color: Colors.black54)),
                              ),
                            ],
                          ),
                          const Divider(thickness: 1, color: Colors.black26),
                          const SizedBox(height: 10),
                          _buildTextField("Tên", nameController,
                              enabled: isEditing),
                          const SizedBox(height: 10),
                          _buildTextField("Năm sinh", birthController,
                              enabled: isEditing),
                          const SizedBox(height: 10),
                          _buildTextField("Số điện thoại", phoneController,
                              enabled: isEditing),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: const Text("Giới tính",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Row(
                            children: [
                              Radio(
                                value: "Nam",
                                groupValue: gender,
                                onChanged: isEditing
                                    ? (value) => setState(() => gender = value.toString())
                                    : null,
                              ),
                              const Text("Nam"),
                              const SizedBox(width: 20),
                              Radio(
                                value: "Nữ",
                                groupValue: gender,
                                onChanged: isEditing
                                    ? (value) => setState(() => gender = value.toString())
                                    : null,
                              ),
                              const Text("Nữ"),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _buildTextField("Địa chỉ", addressController,
                              enabled: isEditing, maxLines: 2),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed:
                                isEditing ? _saveUserData : () => setState(() => isEditing = true),
                            icon: const Icon(Icons.edit),
                            label: Text(isEditing ? "Lưu thông tin" : "Chỉnh sửa thông tin"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink[100],
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15)),
                            ),
                          ),
                          const SizedBox(height: 50),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        if (selectedTab == 0) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Danh mục",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.filter_alt,
                                    color: Color.fromARGB(255, 148, 147, 147),
                                  ),
                                  onPressed: () {
                                    _showFilterSheet(context);
                                  },
                                ),
                              ],
                            ),
                          ),
                          _buildCategoryBar(),
                        ],
                        Expanded(child: _buildFieldList()),
                      ],
                    ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildCategoryBar() {
    return Container(
      width: double.infinity,
      color: Colors.blue[800],
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('sports').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Không có danh mục",
                style: TextStyle(color: Colors.white),
              ),
            );
          }
          final categories = [
            {'id': 'all', 'name': 'Tất cả'},
            ...snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>?;
              return {'id': doc.id, 'name': data?['name'] ?? 'Không tên'};
            }),
          ];
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: categories.map((cat) {
                final selected = selectedCategory == cat['id'];
                return GestureDetector(
                  onTap: () {
                    setState(() => selectedCategory = cat['id']!);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? Colors.white : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white),
                    ),
                    child: Text(
                      cat['name']!,
                      style: TextStyle(
                        color: selected ? Colors.blue[800] : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFieldList() {
    final query = selectedCategory == 'all'
        ? FirebaseFirestore.instance.collection('fields')
        : FirebaseFirestore.instance
            .collection('fields')
            .where('sport', isEqualTo: selectedCategory);
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text("Không có sân nào trong danh mục này"),
          );
        }
        final docs = snapshot.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _buildFieldCard(data);
          },
        );
      },
    );
  }

  Widget _buildFieldCard(Map<String, dynamic> data) {
    final fieldId = data['id'] ?? data['name'];
    final selectedDate = selectedDates[fieldId];
    final selectedTime = selectedTimes[fieldId];
    final paymentMethod = paymentMethods[fieldId] ?? "Cọc";
    final name = data['name'] ?? 'Không tên';
    final description = data['description'] ?? '';
    final price = data['price'] ?? '0';
    String openTime = '—';
    String closeTime = '—';
    try {
      final openRaw = data['open_time'];
      if (openRaw is Timestamp) {
        openTime = openRaw.toDate().toString().substring(11, 16);
      } else if (openRaw is String) {
        openTime = openRaw;
      }
      final closeRaw = data['close_time'];
      if (closeRaw is Timestamp) {
        closeTime = closeRaw.toDate().toString().substring(11, 16);
      } else if (closeRaw is String) {
        closeTime = closeRaw;
      }
    } catch (e) {
      debugPrint('Lỗi đọc thời gian: $e');
    }
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      elevation: 3,
      child: ExpansionTile(
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                "https://cdn.tuoitre.vn/471584752817336320/2023/12/28/san-bong-da-17037384362191179016543.jpg",
                width: 100,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 100,
                  height: 80,
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Giờ mở cửa: $openTime - $closeTime",
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Giá: $price VNĐ/giờ",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      const Text("5.0", style: TextStyle(fontSize: 13)),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 199, 113, 90),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                            ),
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => ChatScreen(
                                          fieldId: fieldId, fieldName: name)));
                            },
                            child: const Text(
                              "Hỗ trợ",
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                            ),
                            onPressed: () {},
                            child: const Text(
                              "Xem đánh giá",
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                            ),
                            onPressed: () {},
                            child: const Text(
                              "Đặt sân",
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        maintainState: true,
        children: [
          const Divider(),
          StatefulBuilder(
            builder: (context, setInnerState) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Chọn ngày:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedDates[fieldId] == null
                              ? "Chưa chọn ngày"
                              : "Ngày: ${DateFormat('dd/MM/yyyy').format(selectedDates[fieldId]!)}",
                          style: const TextStyle(fontSize: 14),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            final now = DateTime.now();
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: now,
                              firstDate: now,
                              lastDate: now.add(const Duration(days: 30)),
                            );
                            if (picked != null) {
                              setInnerState(() {
                                selectedDates[fieldId] = picked;
                              });
                            }
                          },
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: const Text("Chọn ngày"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Chọn giờ:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: timeSlots.map((time) {
                          final isSelectedStart =
                              selectedTimes[fieldId]?.startsWith(time) ?? false;
                          final isSelectedEnd =
                              selectedTimes[fieldId]?.endsWith(time) ?? false;
                          return GestureDetector(
                            onTap: () {
                              setInnerState(() {
                                if (selectedTimes[fieldId] == null) {
                                  selectedTimes[fieldId] = "$time - ?";
                                } else if (selectedTimes[fieldId]!.endsWith("?")) {
                                  final start =
                                      selectedTimes[fieldId]!.split(" - ")[0];
                                  final end = timeSlots.indexOf(time) >=
                                          timeSlots.indexOf(start)
                                      ? time
                                      : start;
                                  selectedTimes[fieldId] = "$start - $end";
                                } else {
                                  selectedTimes[fieldId] = "$time - ?";
                                }
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: (isSelectedStart || isSelectedEnd)
                                    ? Colors.blue
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: (isSelectedStart || isSelectedEnd)
                                      ? Colors.blue
                                      : Colors.grey[300]!,
                                ),
                              ),
                              child: Text(
                                time,
                                style: TextStyle(
                                  color: (isSelectedStart || isSelectedEnd)
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (selectedTimes[fieldId] != null)
                      Text(
                        "Khung giờ đã chọn: ${selectedTimes[fieldId]}",
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: 12),
                    const Text(
                      "Hình thức thanh toán:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        Radio<String>(
                          value: "Cọc",
                          groupValue: paymentMethods[fieldId] ?? "Cọc",
                          onChanged: (value) {
                            setInnerState(() => paymentMethods[fieldId] = value!);
                          },
                        ),
                        const Text("Cọc 20%"),
                        const SizedBox(width: 20),
                        Radio<String>(
                          value: "Trả hết",
                          groupValue: paymentMethods[fieldId],
                          onChanged: (value) {
                            setInnerState(() => paymentMethods[fieldId] = value!);
                          },
                        ),
                        const Text("Trả hết"),
                      ],
                    ),
                    if ((paymentMethods[fieldId] ?? "Cọc") == "Cọc") ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Số tiền cọc (20%):"),
                          Text(
                            "${(int.tryParse(price) ?? 0 * 0.2).toStringAsFixed(0)} VNĐ",
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const PaymentPage()),
                          );
                          if (selectedDate == null || selectedTime == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Vui lòng chọn ngày và giờ")),
                            );
                            return;
                          }
                          debugPrint(
                              "Đặt sân $name vào ${DateFormat('dd/MM/yyyy').format(selectedDates[fieldId]!)} - $selectedTime");
                          debugPrint("Hình thức thanh toán: $paymentMethod");
                        },
                        child: const Text(
                          "Xác nhận đặt sân",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: selectedTab,
      selectedItemColor: Colors.blue[800],
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        setState(() {
          selectedTab = index;
        });
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Trang chủ"),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: "Tìm kiếm"),
        BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none), label: "Thông báo"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Tài khoản"),
        BottomNavigationBarItem(
            icon: Icon(Icons.history), label: "Lịch sử đặt sân"),
      ],
    );
  }

  void _showFilterSheet(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Filter',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.white,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              height: double.infinity,
              child: StatefulBuilder(
                builder: (context, setModalState) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Bộ lọc nâng cao",
                                style: TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close),
                              ),
                            ],
                          ),
                          const Divider(),
                          Text(
                            "Giá (${_priceRange.start.toStringAsFixed(0)}đ - ${_priceRange.end.toStringAsFixed(0)}đ)",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          RangeSlider(
                            values: _priceRange,
                            min: 0,
                            max: 1000000,
                            divisions: 20,
                            activeColor: Colors.blue,
                            inactiveColor: Colors.grey[300],
                            labels: RangeLabels(
                              "${_priceRange.start.toStringAsFixed(0)}đ",
                              "${_priceRange.end.toStringAsFixed(0)}đ",
                            ),
                            onChanged: (val) {
                              setModalState(() => _priceRange = val);
                            },
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Giờ hoạt động (${_timeRange.start.toInt()}h - ${_timeRange.end.toInt()}h)",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          RangeSlider(
                            values: _timeRange,
                            min: 0,
                            max: 24,
                            divisions: 24,
                            activeColor: Colors.green,
                            inactiveColor: Colors.grey[300],
                            labels: RangeLabels(
                              "${_timeRange.start.toInt()}h",
                              "${_timeRange.end.toInt()}h",
                            ),
                            onChanged: (val) {
                              setModalState(() => _timeRange = val);
                            },
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "Quận",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final d in [
                                'Thủ Đức',
                                'Gò Vấp',
                                'Bình Thạnh',
                                'Quận 1',
                                'Quận 3',
                                'Quận 10'
                              ])
                                FilterChip(
                                  label: Text(d),
                                  selected: _selectedDistricts.contains(d),
                                  onSelected: (selected) {
                                    setModalState(() {
                                      if (selected) {
                                        _selectedDistricts.add(d);
                                      } else {
                                        _selectedDistricts.remove(d);
                                      }
                                    });
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "Đánh giá",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Row(
                            children: List.generate(5, (index) {
                              final star = index + 1;
                              return IconButton(
                                onPressed: () {
                                  setModalState(() =>
                                      _selectedRating =
                                          _selectedRating == star ? 0 : star);
                                },
                                icon: Icon(
                                  Icons.star,
                                  color: _selectedRating >= star
                                      ? Colors.amber
                                      : Colors.grey,
                                ),
                              );
                            }),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () {
                                  setModalState(() {
                                    _priceRange = const RangeValues(0, 1000000);
                                    _timeRange = const RangeValues(6, 22);
                                    _selectedDistricts.clear();
                                    _selectedRating = 0;
                                  });
                                },
                                child: const Text("Thiết lập lại"),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red),
                                onPressed: () {
                                  setState(() {});
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  "Áp dụng",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position:
              Tween(begin: const Offset(1, 0), end: Offset.zero).animate(anim1),
          child: child,
        );
      },
    );
  }
}

class _BookingHistoryTab extends StatefulWidget {
  const _BookingHistoryTab({Key? key}) : super(key: key);

  @override
  State<_BookingHistoryTab> createState() => _BookingHistoryTabState();
}

class _BookingHistoryTabState extends State<_BookingHistoryTab>
    with SingleTickerProviderStateMixin {
  String selectedStatus = "Tất cả";
  final currentUser = FirebaseAuth.instance.currentUser;

  final List<String> statusTabs = [
    "Tất cả",
    "Chờ xác nhận",
    "Đã xác nhận",
    "Đã hủy",
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.blue[100],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: statusTabs.map((status) {
              final selected = selectedStatus == status;
              return GestureDetector(
                onTap: () => setState(() => selectedStatus = status),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: selected ? Colors.blue[800]! : Colors.transparent,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: selected ? Colors.blue[800] : Colors.black54,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .where('userId', isEqualTo: currentUser?.uid)
                .limit(20)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text("Lỗi tải lịch sử đặt sân: ${snapshot.error}"),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("Chưa có lịch sử đặt sân"));
              }
              final bookings = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                if (selectedStatus == "Tất cả") return true;
                return data['status'] == selectedStatus;
              }).toList();
              if (bookings.isEmpty) {
                return const Center(
                  child: Text("Không có đặt sân nào trong mục này"),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final booking = bookings[index].data() as Map<String, dynamic>;
                  return _buildBookingCard(booking, bookings[index].id);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking, String bookingId) {
    final date = booking['date'] is Timestamp
        ? DateFormat('dd/MM/yyyy').format(booking['date'].toDate())
        : booking['date']?.toString() ?? '—';
    final time = booking['time'] ?? '—';
    final status = booking['status'] ?? 'Không xác định';
    final price = booking['price']?.toString() ?? '0';
    final priceValue = int.tryParse(price) ?? 0;
    final fieldName = booking['fieldName'] ?? 'Không tên';
    final address = booking['address'] ?? '—';
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 10),
      backgroundColor: Colors.white,
      collapsedBackgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              fieldName,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.blue[100],
              foregroundColor: Colors.blue[800],
            ),
            onPressed: () {
              // TODO: Triển khai xem chi tiết
            },
            child: const Text("Xem chi tiết"),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$date, $time", style: const TextStyle(color: Colors.black87)),
          Text(
            status,
            style: TextStyle(
              color: status == "Đã hủy"
                  ? Colors.red
                  : status == "Chờ xác nhận"
                      ? Colors.orange
                      : Colors.green,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text("$price VNĐ", style: const TextStyle(color: Colors.red)),
        ],
      ),
      children: [
        const Divider(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Mã đặt: #$bookingId"),
              Text("Địa chỉ: $address"),
              Text(
                "Số tiền còn lại: ${(priceValue * 0.8).toStringAsFixed(0)} VNĐ",
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      // TODO: Triển khai chức năng đánh giá
                    },
                    child: const Text("Đánh giá"),
                  ),
                  const SizedBox(width: 8),
                  if (status == "Chờ xác nhận")
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () async {
                        try {
                          await FirebaseFirestore.instance
                              .collection('bookings')
                              .doc(bookingId)
                              .update({'status': 'Đã hủy'});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("Đã hủy đặt sân thành công")),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Lỗi hủy đặt sân: $e")),
                          );
                        }
                      },
                      child: const Text("Hủy đặt sân"),
                    ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[800]),
                    onPressed: () {
                      // TODO: Triển khai chức năng tóm tắt
                    },
                    child: const Text("Tóm tắt"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SearchTab extends StatefulWidget {
  const _SearchTab({Key? key}) : super(key: key);

  @override
  State<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<_SearchTab> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  final Map<String, DateTime?> selectedDates = {};
  final Map<String, String?> selectedTimes = {};
  final Map<String, String> paymentMethods = {};
  final List<String> timeSlots = [
    "06:00",
    "07:00",
    "08:00",
    "09:00",
    "10:00",
    "11:00",
    "12:00",
    "13:00",
    "14:00",
    "15:00",
    "16:00",
    "17:00",
    "18:00",
    "19:00",
    "20:00",
    "21:00",
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Tìm kiếm sân...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value.toLowerCase();
              });
            },
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('fields').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Text("Lỗi tải dữ liệu: ${snapshot.error}"),
                );
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("Không có sân nào"));
              }
              final fields = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = data['name']?.toString().toLowerCase() ?? '';
                final description =
                    data['description']?.toString().toLowerCase() ?? '';
                return name.contains(searchQuery) || description.contains(searchQuery);
              }).toList();
              if (fields.isEmpty) {
                return const Center(child: Text("Không tìm thấy sân nào"));
              }
              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: fields.length,
                itemBuilder: (context, index) {
                  final data = fields[index].data() as Map<String, dynamic>;
                  return _buildFieldCard(data, fields[index].id);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFieldCard(Map<String, dynamic> data, String fieldId) {
    final selectedDate = selectedDates[fieldId];
    final selectedTime = selectedTimes[fieldId];
    final paymentMethod = paymentMethods[fieldId] ?? "Cọc";
    final name = data['name'] ?? 'Không tên';
    final description = data['description'] ?? '';
    final price = data['price'] ?? '0';
    String openTime = '—';
    String closeTime = '—';
    try {
      final openRaw = data['open_time'];
      if (openRaw is Timestamp) {
        openTime = openRaw.toDate().toString().substring(11, 16);
      } else if (openRaw is String) {
        openTime = openRaw;
      }
      final closeRaw = data['close_time'];
      if (closeRaw is Timestamp) {
        closeTime = closeRaw.toDate().toString().substring(11, 16);
      } else if (closeRaw is String) {
        closeTime = closeRaw;
      }
    } catch (e) {
      debugPrint('Lỗi đọc thời gian: $e');
    }
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      elevation: 3,
      child: ExpansionTile(
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                "https://cdn.tuoitre.vn/471584752817336320/2023/12/28/san-bong-da-17037384362191179016543.jpg",
                width: 100,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 100,
                  height: 80,
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Giờ mở cửa: $openTime - $closeTime",
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Giá: $price VNĐ/giờ",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      const Text("5.0", style: TextStyle(fontSize: 13)),
                      const Spacer(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 199, 113, 90),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                            ),
                            onPressed: () {},
                            child: const Text(
                              "Hỗ trợ",
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                            ),
                            onPressed: () {},
                            child: const Text(
                              "Xem đánh giá",
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextButton(
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                            ),
                            onPressed: () {},
                            child: const Text(
                              "Đặt sân",
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        maintainState: true,
        children: [
          const Divider(),
          StatefulBuilder(
            builder: (context, setInnerState) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Chọn ngày:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          selectedDates[fieldId] == null
                              ? "Chưa chọn ngày"
                              : "Ngày: ${DateFormat('dd/MM/yyyy').format(selectedDates[fieldId]!)}",
                          style: const TextStyle(fontSize: 14),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () async {
                            final now = DateTime.now();
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: now,
                              firstDate: now,
                              lastDate: now.add(const Duration(days: 30)),
                            );
                            if (picked != null) {
                              setInnerState(() {
                                selectedDates[fieldId] = picked;
                              });
                            }
                          },
                          icon: const Icon(Icons.calendar_today, size: 18),
                          label: const Text("Chọn ngày"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Chọn giờ:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: timeSlots.map((time) {
                          final isSelectedStart =
                              selectedTimes[fieldId]?.startsWith(time) ?? false;
                          final isSelectedEnd =
                              selectedTimes[fieldId]?.endsWith(time) ?? false;
                          return GestureDetector(
                            onTap: () {
                              setInnerState(() {
                                if (selectedTimes[fieldId] == null) {
                                  selectedTimes[fieldId] = "$time - ?";
                                } else if (selectedTimes[fieldId]!.endsWith("?")) {
                                  final start =
                                      selectedTimes[fieldId]!.split(" - ")[0];
                                  final end = timeSlots.indexOf(time) >=
                                          timeSlots.indexOf(start)
                                      ? time
                                      : start;
                                  selectedTimes[fieldId] = "$start - $end";
                                } else {
                                  selectedTimes[fieldId] = "$time - ?";
                                }
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: (isSelectedStart || isSelectedEnd)
                                    ? Colors.blue
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: (isSelectedStart || isSelectedEnd)
                                      ? Colors.blue
                                      : Colors.grey[300]!,
                                ),
                              ),
                              child: Text(
                                time,
                                style: TextStyle(
                                  color: (isSelectedStart || isSelectedEnd)
                                      ? Colors.white
                                      : Colors.black,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (selectedTimes[fieldId] != null)
                      Text(
                        "Khung giờ đã chọn: ${selectedTimes[fieldId]}",
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    const SizedBox(height: 12),
                    const Text(
                      "Hình thức thanh toán:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        Radio<String>(
                          value: "Cọc",
                          groupValue: paymentMethods[fieldId] ?? "Cọc",
                          onChanged: (value) {
                            setInnerState(() => paymentMethods[fieldId] = value!);
                          },
                        ),
                        const Text("Cọc 20%"),
                        const SizedBox(width: 20),
                        Radio<String>(
                          value: "Trả hết",
                          groupValue: paymentMethods[fieldId],
                          onChanged: (value) {
                            setInnerState(() => paymentMethods[fieldId] = value!);
                          },
                        ),
                        const Text("Trả hết"),
                      ],
                    ),
                    if ((paymentMethods[fieldId] ?? "Cọc") == "Cọc") ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Số tiền cọc (20%):"),
                          Text(
                            "${(int.tryParse(price) ?? 0 * 0.2).toStringAsFixed(0)} VNĐ",
                            style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const PaymentPage()),
                          );
                          if (selectedDate == null || selectedTime == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Vui lòng chọn ngày và giờ")),
                            );
                            return;
                          }
                          debugPrint(
                              "Đặt sân $name vào ${DateFormat('dd/MM/yyyy').format(selectedDates[fieldId]!)} - $selectedTime");
                          debugPrint("Hình thức thanh toán: $paymentMethod");
                        },
                        child: const Text(
                          "Xác nhận đặt sân",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

//
class _NotificationsTab extends StatefulWidget {
  final String userId;

  const _NotificationsTab({required this.userId, Key? key}) : super(key: key);

  @override
  State<_NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<_NotificationsTab> {
  late final ValueNotifier<List<bool>> _expanded;

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
          return const Center(child: Text('Không có thông báo'));
        }

        final notifications = snapshot.data!.docs;
        if (_expanded.value.length < notifications.length) {
          _expanded.value = List<bool>.filled(notifications.length, false);
        } else if (_expanded.value.length > notifications.length) {
          _expanded.value = _expanded.value.sublist(0, notifications.length);
        }

        return ValueListenableBuilder<List<bool>>(
          valueListenable: _expanded,
          builder: (context, expanded, child) {
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final data = notifications[index].data() as Map<String, dynamic>;
                final docId = notifications[index].id;
                 final titleText = data['title'] ?? 'Thông báo';
                final subtitle = data['subtitle'] ?? '';
                final fieldName = data['field_name'] ?? '';
                final address = data['address'] ?? '';
                final timeSlot = data['time_slot'] ?? '';
                final paymentMethod = data['payment_method'] ?? '';

                DateTime createdAt;
                if (data['created_at'] is Timestamp) {
                  createdAt = (data['created_at'] as Timestamp).toDate();
                } else if (data['created_at'] is String) {
                  createdAt = DateTime.parse(data['created_at'] as String);
                } else {
                  createdAt = DateTime.now(); 
                }

                final isRead = data['is_read'] ?? false;
                final shortText = '$subtitle - $fieldName';
                final fullText = '''
                $subtitle
                $fieldName
                Địa chỉ: $address
                Khung giờ: $timeSlot
                Hình thức thanh toán: $paymentMethod
                ''';

                return _buildNotificationCard(
                  context,
                  index: index,
                  title: '$titleText - ${DateFormat('dd/MM/yyyy HH:mm').format(createdAt)}',
                  shortText: shortText,
                  fullText: fullText,
                  isRead: isRead,
                  docId: docId,
                  expanded: expanded[index],
                  onTap: () {
                    final newExpanded = List<bool>.from(expanded);
                    newExpanded[index] = !expanded[index];
                    _expanded.value = newExpanded;
                    if (!isRead) {
                      _markAsRead(context, docId);
                    }
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : Colors.yellow[50]!,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 3))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isRead ? Colors.black : Colors.blue[800]!,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: Text(shortText),
              secondChild: Text(fullText),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Icon(
                expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: const Color(0xFF004A8E),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _markAsRead(BuildContext context, String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(docId)
          .update({'is_read': true});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi đánh dấu đã đọc: $e')),
      );
    }
  }
}