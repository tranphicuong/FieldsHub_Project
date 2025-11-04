import 'dart:convert';
import 'package:http/http.dart' as http;

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
    final url = Uri.parse("https://otp-server.onrender.com/send-otp");

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': receiverEmail, 'otp': otp}),
    );

    if (response.statusCode != 200) {
      final error = jsonDecode(response.body)['error'] ?? response.body;
      throw Exception('Gửi OTP thất bại: $error');
    }
  }
}
