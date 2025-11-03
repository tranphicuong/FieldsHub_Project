// lib/Database/reset_password_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'email_sevice.dart';

class ResetPasswordService {
  static String? _otpSent;
  static DateTime? _otpExpire;

  /// Gửi OTP qua email
  static Future<void> sendOtp(String email) async {
    if (email.isEmpty) throw Exception("Email không được để trống");

    final otp = EmailService.generateOtp();
    await EmailService.sendOtpEmail(receiverEmail: email, otp: otp);

    _otpSent = otp;
    _otpExpire = DateTime.now().add(const Duration(minutes: 5));
  }

  /// Xác thực OTP và đổi mật khẩu
  static Future<void> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    // Kiểm tra OTP
    if (_otpSent == null) throw Exception("Chưa gửi mã OTP");
    if (DateTime.now().isAfter(_otpExpire!)) throw Exception("Mã OTP đã hết hạn");
    if (otp.trim() != _otpSent) throw Exception("Mã OTP không chính xác");

    // Gọi API backend
    final response = await http.post(
      Uri.parse('http://10.0.2.2:3000/reset-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'newPassword': newPassword}),
    );

    final result = jsonDecode(response.body);
    if (!(result['success'] == true)) {
      throw Exception(result['message'] ?? "Đổi mật khẩu thất bại");
    }

    // Xóa OTP sau khi thành công
    _otpSent = null;
    _otpExpire = null;
  }
}