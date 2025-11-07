import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fieldshub/user/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  String? userName; // Biến để lưu tên người dùng
  bool isDarkMode = false; // Trạng thái chế độ sáng/tối

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Tải tên người dùng
    _loadThemePreference(); // Tải trạng thái theme
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        userName = 'Khách';
      });
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        setState(() {
          userName = userDoc.data()?['name'] ?? 'Khách';
        });
      } else {
        setState(() {
          userName = 'Khách';
        });
      }
    } catch (e) {
      print("Error loading user data: $e");
      setState(() {
        userName = 'Khách';
      });
    }
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  Future<void> _toggleTheme(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = value;
    });
    await prefs.setBool('isDarkMode', value);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: Builder(
        builder: (context) => Scaffold(
          backgroundColor: isDarkMode ? Colors.grey[850] : const Color(0xFFB7D8F9),
          appBar: AppBar(
            backgroundColor: isDarkMode ? Colors.grey[700] : const Color(0xFFD7EDFF),
            elevation: 0,
            title: const Text(
              "Cài đặt",
              style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Thông tin tài khoản ---
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: isDarkMode ? Colors.black12 : Colors.grey.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: isDarkMode ? Colors.blueGrey : Colors.blue,
                          child: const Icon(Icons.person, color: Colors.white, size: 30),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName ?? "Nguyen Van A",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isDarkMode ? Colors.white : Colors.black),
                              ),
                              Text(
                                "Quản lý cơ sở - Sân & Bida",
                                style: TextStyle(
                                    color: isDarkMode ? Colors.white70 : Colors.grey,
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),
                  Text(
                    "Cài đặt tài khoản",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDarkMode ? Colors.white : Colors.black),
                  ),
                  const SizedBox(height: 10),
                  _buildSettingItem(Icons.lock_outline, "Đổi mật khẩu",
                      onTap: () {}, isDarkMode: isDarkMode),
                  _buildSettingItem(Icons.language, "Ngôn ngữ",
                      onTap: () {}, isDarkMode: isDarkMode),
                  _buildSettingItem(
                      Icons.dark_mode_outlined,
                      "Chế độ sáng/tối",
                      onTap: () {
                        _showThemeDialog();
                      },
                      isDarkMode: isDarkMode),

                  const SizedBox(height: 25),
                  Text(
                    "Hỗ trợ & thông tin",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDarkMode ? Colors.white : Colors.black),
                  ),
                  const SizedBox(height: 10),

                  _buildSettingItem(Icons.help_outline, "Trung tâm hỗ trợ",
                      onTap: () {}, isDarkMode: isDarkMode),
                  _buildSettingItem(Icons.privacy_tip_outlined, "Chính sách bảo mật",
                      onTap: () {}, isDarkMode: isDarkMode),
                  _buildSettingItem(Icons.info_outline, "Giới thiệu ứng dụng",
                      onTap: () {}, isDarkMode: isDarkMode),
                  _buildSettingItem(Icons.feedback_outlined, "Gửi phản hồi",
                      onTap: () {}, isDarkMode: isDarkMode),

                  const SizedBox(height: 25),
                  Center(
  child: ElevatedButton.icon(
    onPressed: () async {
      final shouldLogout = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Xác nhận đăng xuất'),
          content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Đăng xuất'),
            ),
          ],
        ),
      );

      if (shouldLogout == true) {
        await FirebaseAuth.instance.signOut();
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            ),
            (route) => false, // Xóa hết stack cũ để không quay lại được
          );
        }
      }
    },
    icon: const Icon(Icons.logout, color: Colors.white),
    label: const Text(
      "Đăng xuất",
      style: TextStyle(color: Colors.white),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.redAccent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
    ),
  ),
),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget con tái sử dụng cho từng dòng cài đặt
  Widget _buildSettingItem(IconData icon, String title,
      {VoidCallback? onTap, required bool isDarkMode}) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: isDarkMode ? Colors.black12 : Colors.grey.withOpacity(0.15),
              blurRadius: 4,
              offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: isDarkMode ? Colors.white : Colors.blue),
        title: Text(
            title,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Chọn chế độ"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: const Text("Chế độ sáng"),
              onTap: () {
                _toggleTheme(false);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text("Chế độ tối"),
              onTap: () {
                _toggleTheme(true);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}