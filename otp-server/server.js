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
const resend = new Resend(process.env.RESEND_API_KEY);

// Health Check
app.get("/", (req, res) => {
  res.json({ 
    status: "OTP Server đang chạy!", 
    time: new Date().toISOString(),
    tip: "Email vào INBOX 100% với fieldshub.app"
  });
});

// GỬI OTP – VÀO INBOX NGAY LẦN ĐẦU
app.post("/send-otp", async (req, res) => {
  const { email, otp } = req.body;
  if (!email || !otp) return res.status(400).json({ success: false, error: "Thiếu dữ liệu" });

  try {
    const { data } = await resend.emails.send({
      from: 'Fields Sport <otp@fieldshub.app>',  // DOMAIN ĐÃ VERIFY – INBOX 100%
      to: [email],
      subject: "Mã OTP Xác Thực",
      html: `
        <div style="font-family: Arial; text-align: center; padding: 20px;">
          <h2 style="color: #1a73e8;">Mã OTP của bạn</h2>
          <p style="font-size: 28px; font-weight: bold; color: #d93025; letter-spacing: 5px;">
            ${otp}
          </p>
          <p>Mã có hiệu lực trong <strong>5 phút</strong></p>
        </div>
      `,
    });
    res.json({ success: true, id: data.id });
  } catch (error) {
    console.error("Lỗi gửi email:", error);
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