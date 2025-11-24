import 'package:http/http.dart' as http;

class ApiService {

  static const String baseUrl = "https://fieldshub-project.onrender.com";

  // gửi OTP qua sendgrid node server
  static Uri sendOtp() {
    return Uri.parse("$baseUrl/send-otp");
  }

  // reset password firebase auth server
  static Uri resetPassword() {
    return Uri.parse("$baseUrl/reset-password");
  }

  // test server
  static Future<bool> checkServer() async {
    try {
      final res = await http.get(Uri.parse(baseUrl));
      if (res.statusCode == 200) return true;
      return false;
    } catch (e) {
      return false;
    }
  }
}