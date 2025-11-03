import express from "express";
import nodemailer from "nodemailer";
import cors from "cors";
import admin from "firebase-admin";
import fs from "fs";

const app = express();
app.use(cors());
app.use(express.json());

const serviceAccount = JSON.parse(
  process.env.FIREBASE_SERVICE_ACCOUNT_KEY || fs.readFileSync("./serviceAccountKey.json", "utf-8")
);
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

app.post("/send-otp", async (req, res) => {
  const { email, otp } = req.body;

  try {
    const transporter = nodemailer.createTransport({
      service: "gmail",
      auth: {
        user: "fieldssport101025@gmail.com",
        pass: "jgur vyio dona gslg",
      },
    });

    const mailOptions = {
      from: "fieldssport101025@gmail.com",
      to: email,
      subject: "Mã OTP xác thực",
      text: `Mã OTP của bạn là: ${otp}. Mã có hiệu lực trong 5 phút.`,
    };

    await transporter.sendMail(mailOptions);
    res.json({ success: true });
  } catch (error) {
    console.error(error);
    res.json({ success: false, error: error.message });
  }
});
app.post("/reset-password", async (req, res) => {
  const { email, newPassword } = req.body;

  try {
    const user = await admin.auth().getUserByEmail(email);
    await admin.auth().updateUser(user.uid, {
      password: newPassword,
    });
    res.json({ success: true, message: "Đổi mật khẩu thành công" });
  } catch (error) {
    console.error("❌ Lỗi reset password:", error);
    res.status(400).json({ success: false, message: error.message });
  }
});
const PORT = process.env.PORT || 3000;

app.listen(PORT, "0.0.0.0", () => {
  console.log(`✅ Server đang chạy tại http://0.0.0.0:${PORT}`);
});
