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
        email: "fieldssport101025@gmail.com",
        name: "Fields Sport",
      },
      subject: "Mã OTP Xác Thực Fields Sport",
      html: `<h1>${otp}</h1>`,
    };

    const [response] = await sgMail.send(msg);
    console.log("✅ SENDGRID RESPONSE:", response.statusCode);
    return res.json({ success: true });
  } catch (error) {
    console.error("❌ LỖI GỬI EMAIL:", error);
    if (error.response) console.error("SendGrid Error Body:", error.response.body);
    // luôn trả về phản hồi để client không bị treo
    return res.status(500).json({
      success: false,
      error: error.message,
      body: error.response?.body || null,
    });
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
