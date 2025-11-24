import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fieldshub/Database/api_service.dart';

class EmailService {
  static String generateOtp() {
    final otp = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
    return otp;
  }

  static Future<void> sendOtpEmail({
    required String receiverEmail,
    required String otp,
  }) async {
    final response = await http.post(
      ApiService.sendOtp(),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': receiverEmail, 'otp': otp}),
    );

    // Kiểm tra statusCode
    if (response.statusCode != 200) {
      final error = jsonDecode(response.body)['error'] ?? 'HTTP ${response.statusCode}';
      throw Exception('Gửi OTP thất bại: $error');
    }

    // Kiểm tra body.success
    final result = jsonDecode(response.body);
    if (result['success'] != true) {
      throw Exception('Gửi OTP thất bại: ${result['error'] ?? 'Unknown error'}');
    }
  }
}