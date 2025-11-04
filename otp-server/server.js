import express from "express";
import nodemailer from "nodemailer";
import cors from "cors";
import admin from "firebase-admin";
import fs from "fs";

const app = express();
app.use(cors());
app.use(express.json());

// Firebase Admin SDK
let serviceAccount;
try {
  serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);
} catch (err) {
  console.log("Đang đọc file local (dev only)...");
  serviceAccount = JSON.parse(fs.readFileSync("./serviceAccountKey.json", "utf-8"));
}

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

// Route gửi OTP

app.post("/send-otp", async (req, res) => {
  const { email, otp } = req.body;
  if (!email || !otp) return res.status(400).json({ success: false, error: "Thiếu email hoặc OTP" });

  try {
    const resend = require('resend').Resend(process.env.RESEND_API_KEY);

    const { data, error } = await resend.emails.send({
      from: 'Fields Sport <noreply@fieldssport.com>', 
      to: [email],
      subject: "Mã OTP Xác Thực",
      html: `<h2>Mã OTP của bạn</h2><p><strong>${otp}</strong></p><p>Hiệu lực 5 phút.</p>`,
    });

    if (error) {
      console.error("Lỗi Resend:", error);
      return res.status(500).json({ success: false, error: error.message });
    }

    res.json({ success: true });
  } catch (error) {
    console.error("Lỗi gửi email:", error);
    res.status(500).json({ success: false, error: error.message });
  }
});

// Route reset password
app.post("/reset-password", async (req, res) => {
  const { email, newPassword } = req.body;

  try {
    const user = await admin.auth().getUserByEmail(email);
    await admin.auth().updateUser(user.uid, { password: newPassword });
    res.json({ success: true, message: "Đổi mật khẩu thành công" });
  } catch (error) {
    console.error("Lỗi reset password:", error);
    res.status(400).json({ success: false, message: error.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, "0.0.0.0", () => {
  console.log(`Server chạy tại port ${PORT}`);
});