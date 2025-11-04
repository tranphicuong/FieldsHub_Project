import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fieldshub/Database/api_service.dart';

class EmailService {
  static String generateOtp() {
    final otp = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000))
        .toString();
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

  if (response.statusCode != 200) {
    final error = jsonDecode(response.body)['error'] ?? response.body;
    throw Exception('Gửi OTP thất bại: $error');
  }
}
}
