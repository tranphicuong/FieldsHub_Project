import express from "express";
import cors from "cors";
import admin from "firebase-admin";
import fs from "fs";
import sgMail from "@sendgrid/mail"; 

const app = express();
app.use(cors());
app.use(express.json());


let serviceAccount;
try {
  serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);
} catch (err) {
  serviceAccount = JSON.parse(fs.readFileSync("./serviceAccountKey.json", "utf-8"));
}
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });


if (!process.env.SENDGRID_API_KEY) {
  console.error("❌ LỖI: SENDGRID_API_KEY không tồn tại trong môi trường!");
  process.exit(1);
}
sgMail.setApiKey(process.env.SENDGRID_API_KEY);
console.log("✅ SENDGRID_API_KEY đã load:", process.env.SENDGRID_API_KEY.substring(0, 10) + "...");


app.get("/", (req, res) => {
  res.json({ status: "OTP Server OK", sendgrid: true });
});

app.post("/send-otp", async (req, res) => {
  const { email, otp } = req.body;
  console.log("📨 Gửi OTP đến:", email);

  if (!email || !otp) {
    return res.status(400).json({ success: false, error: "Thiếu dữ liệu" });
  }

  try {
    const msg = {
      to: email,
      from: {
        email: "noreply@fieldshub.app", 
        name: "Fields Sport",
      },
      subject: "Mã OTP Xác Thực Fields Sport",
      html: `
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
    };

    const [response] = await sgMail.send(msg);
    console.log("✅ SENDGRID RESPONSE:", response.statusCode);
    console.log("📤 GỬI THÀNH CÔNG ĐẾN:", email);

    res.json({ success: true });
  } catch (error) {
    console.error("❌ LỖI GỬI EMAIL:", error.message);
    if (error.response) {
      console.error("SendGrid Error Body:", error.response.body);
    }
    res.status(500).json({ success: false, error: error.message });
  }
});


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
  console.log(`🚀 Server chạy tại port ${PORT}`);
});
