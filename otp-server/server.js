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
  console.error("LỖI: RESEND_API_KEY không tồn tại! Vui lòng thêm trên Render.");
  process.exit(1);
}
console.log("RESEND_API_KEY đã load:", process.env.RESEND_API_KEY.substring(0, 10) + "...");

const resend = new Resend(process.env.RESEND_API_KEY);

// Health Check
app.get("/", (req, res) => {
  res.json({ status: "OTP Server OK", resend: !!process.env.RESEND_API_KEY });
});

// GỬI OTP
app.post("/send-otp", async (req, res) => {
  const { email, otp } = req.body;
  console.log("Request gửi OTP:", { email, otp });

  if (!email || !otp) {
    return res.status(400).json({ success: false, error: "Thiếu dữ liệu" });
  }

  try {
    console.log("Đang gửi qua Resend...");
    const response = await resend.emails.send({
      from: 'Fields Sport <otp@fieldshub.app>',
      to: [email],
      subject: "Mã OTP Xác Thực",
      html: `<h2>Mã OTP: <strong>${otp}</strong></h2><p>Hiệu lực 5 phút.</p>`,
    });

    console.log("Resend response:", response);
    res.json({ success: true });
  } catch (error) {
    console.error("Lỗi Resend:", error.message);
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