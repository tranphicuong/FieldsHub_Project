import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'user/login_screen.dart';
import 'owner/main_screen.dart'; // Import MainScreen

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      title: 'FieldsHub Trung tâm thể thao online',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/main': (context) => const MainScreen(), 
      },
    );
  }
}