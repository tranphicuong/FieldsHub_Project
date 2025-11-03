import 'dart:convert';
import 'package:http/http.dart' as http;

class EmailService {
  static String generateOtp() {
    final otp = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
    return otp;
  }

  static Future<void> sendOtpEmail({
    required String receiverEmail,
    required String otp,
  }) async {
    final url = Uri.parse("http://10.0.2.2:3000/send-otp");
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': receiverEmail, 'otp': otp}),
    );

    if (response.statusCode != 200) {
      throw Exception('Gửi OTP thất bại: ${response.body}');
    }
  }
}
