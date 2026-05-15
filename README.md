# Lab Parfumo — KP Stock Management

ระบบบริหารสต๊อก-การขายน้ำหอม Lab Parfumo สำหรับ King Power 6 สาขา

🌐 **Live Demo**: https://YOUR_USERNAME.github.io/kp-stock-app/

## ฟีเจอร์

- 📊 Dashboard สรุปยอดขาย/สต๊อก/สินค้าใกล้หมด
- 📝 บันทึกใบเบิกพร้อม PO + Delivery No. อัตโนมัติ
- 📦 ติดตามสต๊อกรายสาขา real-time
- 💰 บันทึกการขายและรายงานวิเคราะห์
- 📈 รายงานมาตรฐาน (รายเดือน, top sellers, slow movers, turnover)
- ⚙️ Master Data Editor — แก้สินค้า/สาขาผ่าน UI
- 👥 User Roles — Admin/Manager/Staff
- 📄 Export PDF + Print
- 🔍 Barcode Scanner
- ☁️ Cloud Sync ผ่าน Supabase
- 📱 Mobile Responsive

## เทคโนโลยี

- Frontend: HTML + Vanilla JS (ไม่ต้อง build)
- Charts: Chart.js
- PDF: jsPDF + html2canvas
- Backend: Supabase (PostgreSQL + Auth + Realtime)

## ติดตั้ง

ดูคำแนะนำเต็มที่ [DEPLOY_GUIDE.md](./DEPLOY_GUIDE.md)

ขั้นตอนแบบเร็ว:

1. ตั้งค่า Supabase project แล้วรัน `supabase_schema.sql`
2. Deploy ผ่าน GitHub Pages (Settings → Pages → main branch)
3. เพิ่ม URL ใน Supabase Auth → URL Configuration
4. เปิดเว็บ → ใส่ Supabase URL + Anon Key ในหน้าตั้งค่า

## License

MIT — ใช้ได้อิสระทั้งเชิงพาณิชย์และส่วนตัว
