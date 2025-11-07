import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FieldOwnerRegistrationScreen extends StatefulWidget {
  const FieldOwnerRegistrationScreen({Key? key}) : super(key: key);

  @override
  _FieldOwnerRegistrationScreenState createState() => _FieldOwnerRegistrationScreenState();
}

class _FieldOwnerRegistrationScreenState extends State<FieldOwnerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bankIdController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountHolderController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _bankIdController.dispose();
    _accountNumberController.dispose();
    _accountHolderController.dispose();
    super.dispose();
  }

  Future<void> _saveBankInfo() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'bank_id': _bankIdController.text.trim(),
            'bank_account': _accountNumberController.text.trim(),
            'account_holder': _accountHolderController.text.trim(),
            'role': 'field_owner', // Đánh dấu là chủ sân
            'created_at': Timestamp.now(),
          }, SetOptions(merge: true)); // Merge để không ghi đè thông tin khác

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã lưu thông tin tài khoản ngân hàng')),
          );
          Navigator.pushReplacementNamed(context, '/home'); // Chuyển về HomeScreen
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi lưu thông tin: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký thông tin chủ sân'),
        backgroundColor: const Color(0xFF0B5EA8),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vui lòng nhập thông tin tài khoản ngân hàng để nhận thanh toán:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _bankIdController,
                  decoration: const InputDecoration(
                    labelText: 'Mã BIN Ngân hàng (6 chữ số)',
                    border: OutlineInputBorder(),
                    hintText: 'Ví dụ: 970436 (Vietcombank)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mã BIN';
                    }
                    if (value.length != 6) {
                      return 'Mã BIN phải là 6 chữ số';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _accountNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Số tài khoản',
                    border: OutlineInputBorder(),
                    hintText: 'Ví dụ: 123456789012',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập số tài khoản';
                    }
                    if (value.length < 10 || value.length > 14) {
                      return 'Số tài khoản phải từ 10-14 chữ số';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _accountHolderController,
                  decoration: const InputDecoration(
                    labelText: 'Tên chủ tài khoản',
                    border: OutlineInputBorder(),
                    hintText: 'Ví dụ: Nguyễn Văn A',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập tên chủ tài khoản';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                Center(
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          ),
                          onPressed: _saveBankInfo,
                          child: const Text(
                            'Lưu thông tin',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}