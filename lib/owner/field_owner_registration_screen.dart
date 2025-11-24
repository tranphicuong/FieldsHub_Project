import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fieldshub/owner/VerificationPendingScreen.dart';

class FieldOwnerBankInfoScreen extends StatefulWidget {
  const FieldOwnerBankInfoScreen({super.key});

  @override
  State<FieldOwnerBankInfoScreen> createState() => _FieldOwnerBankInfoScreenState();
}

class _FieldOwnerBankInfoScreenState extends State<FieldOwnerBankInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountNumber = TextEditingController();
  String? _selectedBank;
  bool _isLoading = false;

  final List<Map<String, String>> banks = [
    {'name': 'Vietcombank', 'bin': '970436'},
    {'name': 'BIDV', 'bin': '970418'},
    {'name': 'VietinBank', 'bin': '970415'},
    {'name': 'Agribank', 'bin': '970405'},
    {'name': 'MB Bank', 'bin': '970422'},
    {'name': 'Techcombank', 'bin': '970407'},
    {'name': 'ACB', 'bin': '970416'},
    {'name': 'Sacombank', 'bin': '970403'},
    {'name': 'VPBank', 'bin': '970432'},
    {'name': 'SHB', 'bin': '970443'},
    {'name': 'TPBank', 'bin': '970423'},
    {'name': 'HDBank', 'bin': '970437'},
  ];

  Future<void> _saveBankInfo() async {
    if (!_formKey.currentState!.validate() || _selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngân hàng và nhập số tài khoản!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final bank = banks.firstWhere((b) => b['name'] == _selectedBank);

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'bank_name': _selectedBank,
        'bank_bin': bank['bin'],
        'bank_account': _accountNumber.text.trim(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      // Chuyển sang màn hình chờ duyệt
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const VerificationPendingScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thông tin thanh toán'), backgroundColor: const Color(0xFF004A8E), foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedBank,
                decoration: const InputDecoration(labelText: 'Ngân hàng', border: OutlineInputBorder()),
                items: banks.map((b) => DropdownMenuItem(value: b['name'], child: Text(b['name']!))).toList(),
                onChanged: (v) => setState(() => _selectedBank = v),
                validator: (v) => v == null ? 'Vui lòng chọn ngân hàng' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _accountNumber,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Số tài khoản', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Vui lòng nhập số tài khoản' : null,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveBankInfo,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Gửi thông tin', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}