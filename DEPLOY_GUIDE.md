# คู่มือ Deploy ผ่าน GitHub Pages

ระบบนี้เป็น HTML ไฟล์เดียว — เหมาะกับ **GitHub Pages** ซึ่ง:
- ฟรี ไม่จำกัด traffic
- HTTPS อัตโนมัติ
- รองรับ custom domain
- ไม่ต้อง build/compile
- Push ไฟล์ใหม่ → อัพเดทอัตโนมัติใน 30 วินาที

---

## ขั้นที่ 1 — เตรียมไฟล์

ในเครื่องของคุณ สร้างโฟลเดอร์ใหม่ ใส่ไฟล์ 3 ไฟล์:

```
kp-stock-app/
├── index.html          ← เปลี่ยนชื่อจาก kp_stock_app.html
├── README.md
└── supabase_schema.sql
```

> สำคัญ: ต้องชื่อ `index.html` เท่านั้น GitHub Pages จะหาไฟล์นี้เป็นหน้าแรก

```bash
# บน Mac/Linux
cp kp_stock_app.html index.html

# บน Windows
ren kp_stock_app.html index.html
```

---

## ขั้นที่ 2 — สร้าง Repository

1. ไปที่ https://github.com/new (ต้องมีบัญชี GitHub ก่อน — สมัครฟรี)
2. ตั้งชื่อ repo: เช่น `kp-stock-app` หรือ `lab-parfumo`
3. เลือก **Public** (สำหรับใช้ Pages ฟรี) — ถ้าอยาก Private ต้องใช้ GitHub Pro ($4/เดือน)
4. **อย่าติ๊ก** "Add a README" — เราจะ push เอง
5. กด **Create repository**

---

## ขั้นที่ 3 — Push ไฟล์ขึ้น GitHub

### วิธี A — ใช้ GitHub Desktop (แนะนำสำหรับมือใหม่)

1. ดาวน์โหลด https://desktop.github.com/
2. เปิดโปรแกรม → Sign in ด้วย GitHub
3. File → Add Local Repository → เลือกโฟลเดอร์ `kp-stock-app`
4. กด "create a repository" → กด **Publish repository** → uncheck "Keep this code private"
5. ทุกครั้งที่แก้ไฟล์ → กด **Commit to main** แล้ว **Push origin**

### วิธี B — ใช้ Terminal

```bash
cd path/to/kp-stock-app

git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/kp-stock-app.git
git push -u origin main
```

แทน `YOUR_USERNAME` ด้วยชื่อ GitHub ของคุณ

---

## ขั้นที่ 4 — เปิด GitHub Pages

1. ใน repo บน GitHub → คลิก **Settings** (เมนูบนขวา)
2. ที่เมนูซ้ายล่าง คลิก **Pages**
3. ที่ "Build and deployment":
   - **Source**: เลือก **Deploy from a branch**
   - **Branch**: เลือก **main** / **/ (root)** → กด **Save**
4. รอ 1-2 นาที → refresh หน้า Pages
5. จะเห็นข้อความ: **"Your site is live at https://YOUR_USERNAME.github.io/kp-stock-app/"**

ลองคลิกลิงก์ — โปรแกรมจะเปิดได้เลย

---

## ขั้นที่ 5 — เพิ่ม URL เข้า Supabase Whitelist

⚠️ **สำคัญ** — Supabase จะ block requests จากเว็บไซต์ที่ไม่ได้อนุญาต ต้องเพิ่ม URL ก่อน:

1. ไปที่ Supabase Dashboard → เลือก project ของคุณ
2. **Authentication** → **URL Configuration**
3. ที่ **Site URL** ใส่: `https://YOUR_USERNAME.github.io/kp-stock-app/`
4. ที่ **Redirect URLs** เพิ่ม: `https://YOUR_USERNAME.github.io/kp-stock-app/*`
5. กด **Save**

ถ้าใช้ custom domain ในขั้นต่อไป ให้เพิ่ม URL ของ domain นั้นด้วย

---

## ขั้นที่ 6 — Custom Domain (ทางเลือก)

ถ้าอยากใช้โดเมนของตัวเอง เช่น `stock.labparfumo.com`:

1. ที่ DNS ของโดเมน เพิ่ม CNAME record:
   ```
   Type:  CNAME
   Name:  stock
   Value: YOUR_USERNAME.github.io
   ```
2. กลับไปที่ GitHub repo → **Settings → Pages**
3. ที่ "Custom domain" ใส่: `stock.labparfumo.com` → กด Save
4. รอ DNS propagate (ปกติ 5-30 นาที)
5. ติ๊ก **Enforce HTTPS** เมื่อพร้อม

---

## วิธีอัพเดทโปรแกรม

เมื่อมีการแก้ HTML:

### ทาง A — GitHub Desktop
1. แก้ไฟล์ในเครื่อง
2. เปิด GitHub Desktop → ใส่ commit message → **Commit to main**
3. กด **Push origin**
4. รอ 30 วินาที → refresh เว็บไซต์ — เห็นการเปลี่ยนแปลง

### ทาง B — แก้ใน GitHub โดยตรง
1. เปิด `index.html` ในเว็บ GitHub → กดปุ่มดินสอ (Edit)
2. แก้ → Commit changes
3. รอ 30 วินาที → refresh

### ทาง C — Terminal
```bash
cd kp-stock-app
# แก้ไฟล์
git add .
git commit -m "อัพเดท UI ใบเบิก"
git push
```

---

## เพิ่มความปลอดภัย (แนะนำ)

### 1. ซ่อน Supabase URL/Key จากผู้ใช้ทั่วไป

ปกติ user ต้องกรอกเอง แต่ถ้าอยากให้กรอกอัตโนมัติ:

แก้ในไฟล์ `index.html` หา `loadCloud` หรือเพิ่มที่ส่วน `initCloud`:

```javascript
// Auto-fill if not set
if(!localStorage.getItem("kp_supabase_url")){
  localStorage.setItem("kp_supabase_url", "https://YOUR_PROJECT.supabase.co");
  localStorage.setItem("kp_supabase_key", "YOUR_ANON_KEY");
}
```

⚠️ **Anon key ปลอดภัยที่จะอยู่ใน code** — Supabase ออกแบบมาให้ public key
แต่ต้องตั้ง RLS policies ใน database ให้รัดกุม (มี SQL ใน `supabase_schema.sql` แล้ว)

### 2. จำกัดเฉพาะอีเมลของบริษัท

ใน Supabase → Authentication → Policies → SQL Editor รัน:

```sql
-- ลบ policy เดิม
DROP POLICY IF EXISTS "app_state write for authenticated" ON public.app_state;

-- อนุญาตเฉพาะอีเมล @yourcompany.com
CREATE POLICY "app_state write for company emails" ON public.app_state
  FOR UPDATE TO authenticated
  USING (auth.jwt() ->> 'email' LIKE '%@yourcompany.com')
  WITH CHECK (auth.jwt() ->> 'email' LIKE '%@yourcompany.com');
```

### 3. ใช้ Branch Protection (สำหรับทีม)

ใน repo → Settings → Branches → Add rule for `main`:
- ติ๊ก **Require pull request reviews**
- ป้องกันไม่ให้ใครก็ได้ push โดยตรง

---

## เปรียบเทียบกับทางเลือกอื่น

| Hosting | ฟรี | HTTPS | Custom Domain | ความเร็ว | ความซับซ้อน |
|---|---|---|---|---|---|
| **GitHub Pages** (แนะนำ) | ✓ | ✓ | ✓ | เร็ว | ง่ายที่สุด |
| **Cloudflare Pages** | ✓ | ✓ | ✓ | เร็วมาก | ปานกลาง |
| **Vercel** | ✓ | ✓ | ✓ | เร็วมาก | ง่าย |
| **Netlify** | ✓ | ✓ | ✓ | เร็ว | ง่าย |

> ถ้าอยากได้ความเร็วสุดและ analytics → Cloudflare Pages ดีกว่า แต่ setup ซับซ้อนกว่านิดหน่อย

---

## Troubleshooting

| ปัญหา | สาเหตุ / วิธีแก้ |
|---|---|
| 404 Page Not Found | ไฟล์ไม่ได้ชื่อ `index.html` หรือ Pages ยังไม่ build เสร็จ |
| Supabase login ไม่ทำงาน | ยังไม่ได้ใส่ URL ใน Site URL whitelist |
| HTTPS Mixed Content error | มี resource โหลดผ่าน http:// — ต้อง https:// เท่านั้น |
| อัพเดทแล้วไม่เห็นการเปลี่ยนแปลง | Browser cache — กด Ctrl+Shift+R |
| เห็นว่า "Page build failure" | ลองใส่ไฟล์ `.nojekyll` (เปล่า ๆ) ใน root |

---

## สรุปขั้นตอนแบบเร็ว ๆ

```bash
# 1. สร้างโฟลเดอร์ และ rename ไฟล์
mkdir kp-stock-app && cd kp-stock-app
cp /path/to/kp_stock_app.html ./index.html

# 2. Init git และ push
git init
git add .
git commit -m "Initial"
git branch -M main
git remote add origin https://github.com/USERNAME/kp-stock-app.git
git push -u origin main

# 3. ไปที่ Settings → Pages → enable
# 4. เพิ่ม URL ใน Supabase whitelist
# 5. เปิดที่ https://USERNAME.github.io/kp-stock-app/
```

ใช้เวลาทั้งหมดประมาณ **10 นาที**
