class ApiService {
  static const String baseUrl = 'https://fieldshub-project.onrender.com';

  static Uri sendOtp() => Uri.parse('$baseUrl/send-otp');
  static Uri resetPassword() => Uri.parse('$baseUrl/reset-password');
}