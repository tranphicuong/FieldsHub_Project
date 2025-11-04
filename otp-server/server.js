import express from "express";
import nodemailer from "nodemailer";
import cors from "cors";
import admin from "firebase-admin";
import { Resend } from 'resend'; // ĐÚNG: import ES Module
import fs from "fs";

const app = express();
app.use(cors());
app.use(express.json());

// Firebase Admin
let serviceAccount;
try {
  serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);
} catch (err) {
  console.log("Đang đọc file local (dev only)...");
  serviceAccount = JSON.parse(fs.readFileSync("./serviceAccountKey.json", "utf-8"));
}
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });

// Resend
const resend = new Resend(process.env.RESEND_API_KEY); // ĐÚNG

// Health Check
app.get("/", (req, res) => {
  res.json({ status: "OTP Server chạy tốt!", time: new Date().toISOString() });
});

// Gửi OTP
app.post("/send-otp", async (req, res) => {
  const { email, otp } = req.body;
  if (!email || !otp) return res.status(400).json({ success: false, error: "Thiếu dữ liệu" });

  try {
    const { data, error } = await resend.emails.send({
      from: 'Fields Sport <onboarding@resend.dev>', // DÙNG DEFAULT DOMAIN
      to: [email],
      subject: "Mã OTP Xác Thực",
      html: `<h2>Mã OTP: <strong>${otp}</strong></h2><p>Hiệu lực 5 phút.</p>`,
    });

    if (error) throw error;

    console.log("Email sent:", data);
    res.json({ success: true });
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