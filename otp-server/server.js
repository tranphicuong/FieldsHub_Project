import express from "express";
import cors from "cors";
import admin from "firebase-admin";
import { Resend } from 'resend';
import fs from "fs";

const app = express();
app.use(cors());
app.use(express.json());

// Firebase Admin
let serviceAccount;
try {
  serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);
} catch (err) {
  serviceAccount = JSON.parse(fs.readFileSync("./serviceAccountKey.json", "utf-8"));
}
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

// Resend
if (!process.env.RESEND_API_KEY) {
  console.error("LỖI: RESEND_API_KEY không tồn tại!");
  process.exit(1);
}
console.log("RESEND_API_KEY đã load:", process.env.RESEND_API_KEY.substring(0, 10) + "...");

const resend = new Resend(process.env.RESEND_API_KEY);

// Health Check
app.get("/", (req, res) => {
  res.json({ status: "OTP Server OK", resend: true });
});

app.post("/send-otp", async (req, res) => {
  const { email, otp } = req.body;
  console.log("Gửi OTP đến:", email);

  if (!email || !otp) {
    return res.status(400).json({ success: false, error: "Thiếu dữ liệu" });
  }

  try {
    console.log("BẮT ĐẦU GỌI RESEND API...");

    // KHAI BÁO response TRƯỚC KHI DÙNG
    const response = await resend.emails.send({
      from: 'Fields Sport <onboarding@resend.dev>',
      to: [email],
      subject: 'Mã OTP Xác Thực Fields Sport',
      reply_to: 'support@fieldshub.app',
      html: `
        <!DOCTYPE html>
        <html>
        <body style="font-family: Arial, sans-serif; text-align: center; padding: 20px;">
          <h2 style="color: #1a73e8;">Xác Thực Tài Khoản</h2>
          <p>Mã OTP của bạn là:</p>
          <h1 style="font-size: 36px; color: #d93025; letter-spacing: 8px;">${otp}</h1>
          <p><strong>Hiệu lực trong 5 phút</strong></p>
          <p style="font-size: 12px; color: #666;">
            Đây là email tự động. Vui lòng không trả lời.
          </p>
        </body>
        </html>
      `,
    });

    // BÂY GIỜ MỚI LOG
    console.log("RESEND RESPONSE:", JSON.stringify(response, null, 2));

    if (response.error) {
      throw new Error(`Resend Error: ${response.error.message}`);
    }

    console.log("GỬI THÀNH CÔNG! ID:", response.data?.id);
    res.json({ success: true, id: response.data?.id });

  } catch (error) {
    console.error("=== LỖI GỌI RESEND ===");
    console.error("Message:", error.message);
    console.error("Stack:", error.stack);
    console.error("=== KẾT THÚC LỖI ===");
    res.status(500).json({ success: false, error: error.message });
  }
});
// Reset Password
app.post("/reset-password", async (req, res) => {
  const { email, newPassword } = req.body;
  try {
    const user = await admin.auth().getUserByEmail(email);
    await admin.auth().updateUser(user.uid, { password: newPassword });
    res.json({ success: true });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, "0.0.0.0", () => {
  console.log(`Server chạy tại port ${PORT}`);
});