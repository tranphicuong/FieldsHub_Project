import express from "express";
import cors from "cors";
import admin from "firebase-admin";
import sgMail from "@sendgrid/mail";

const app = express();
app.use(cors());
app.use(express.json());

// Firebase service account JSON ENV
let serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_KEY);

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

// SENDGRID INIT
if (!process.env.SENDGRID_API_KEY) {
  console.error("❌ SENDGRID_API_KEY not found!");
  process.exit(1);
}
sgMail.setApiKey(process.env.SENDGRID_API_KEY);

app.get("/", (req, res) => {
  res.json({ status: "OTP Server OK", sendgrid: true });
});

app.post("/send-otp", async (req, res) => {
  const { email, otp } = req.body;
  console.log("📨 send OTP:", email);

  if (!email || !otp) {
    return res.status(400).json({ success: false, error: "missing data" });
  }

  try {
    const msg = {
      to: email,
      from: {
        email: "fieldssport101025@gmail.com",
        name: "Fields Sport",
      },
      subject: "Mã OTP Xác Thực Fields Sport",
      html: `
    <div style="font-family: Arial, sans-serif; background-color:#f9fafb; padding:20px;">
      <div style="max-width:600px; margin:auto; background:#ffffff; border-radius:10px; padding:30px; box-shadow:0 2px 5px rgba(0,0,0,0.1);">
        <h2 style="color:#1a73e8; text-align:center;">Xác Thực Tài Khoản Fields Sport</h2>

        <p>Xin chào <strong>người dùng Fields Sport</strong>,</p>
        <p>Chúng tôi nhận được yêu cầu đăng ký hoặc đăng nhập vào hệ thống của bạn. 
        Để đảm bảo an toàn cho tài khoản, vui lòng nhập mã OTP bên dưới để xác nhận.</p>

        <div style="text-align:center; margin: 30px 0;">
          <h1 style="color:#d93025; letter-spacing:6px; font-size:36px;">${otp}</h1>
        </div>

        <p>Mã OTP này chỉ có hiệu lực trong <strong>5 phút</strong>. 
        Nếu bạn không yêu cầu xác thực, vui lòng bỏ qua email này. 
        Đừng chia sẻ mã OTP với bất kỳ ai để bảo vệ tài khoản của bạn.</p>

        <hr style="border:none; border-top:1px solid #ddd; margin:30px 0;">
        <p style="font-size:13px; color:#555;">
          Cảm ơn bạn đã sử dụng <strong>Fields Sport</strong> — nền tảng đặt sân thể thao trực tuyến nhanh chóng, tiện lợi và đáng tin cậy.<br>
          Nếu có bất kỳ thắc mắc nào, hãy liên hệ với đội ngũ hỗ trợ qua email: 
          <a href="mailto:fieldssport101025@gmail.com">fieldssport101025@gmail.com</a>.
        </p>

        <p style="font-size:12px; color:#999; text-align:center;">
          Email này được gửi tự động. Vui lòng không trả lời lại tin nhắn này.
        </p>
      </div>
    </div>
  `,
    };

    await sgMail.send(msg);
    return res.json({ success: true });
  } catch (err) {
    console.error("SENDGRID ERROR", err.response?.body || err.message);
    return res.status(500).json({ success: false, error: err.message });
  }
});

app.post("/reset-password", async (req, res) => {
  const { email, newPassword } = req.body;

  if (!email || !newPassword) return res.status(400).json({ success: false });

  if (newPassword.length < 8)
    return res.status(400).json({ success: false, error: "password must >= 8" });

  try {
    const user = await admin.auth().getUserByEmail(email);
    await admin.auth().updateUser(user.uid, { password: newPassword });
    res.json({ success: true });
  } catch (error) {
    res.status(400).json({ success: false, error: error.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, "0.0.0.0", () => console.log("🚀 Server start", PORT));
