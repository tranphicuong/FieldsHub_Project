import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart'; // Cần thiết cho initializeDateFormatting
import 'firebase_options.dart';
import 'user/login_screen.dart';
import 'owner/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // FIX HOÀN HẢO CHO TẤT CẢ NỀN TẢNG (Android, iOS, Web)
  if (kIsWeb) {
    // Web: dùng vi_VN (file có sẵn trên mạng)
    await initializeDateFormatting('vi_VN');
  } else {
    // Android/iOS: chỉ cần 'vi' là đủ, không bị lỗi PathNotFound
    await initializeDateFormatting('vi');
  }

  // Khởi tạo Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FieldsHub - Trung tâm thể thao online',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/main': (context) => const MainScreen(),
      },
    );
  }
}