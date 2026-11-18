# Fat Fighting — GitHub + Vercel + Supabase

- **Supabase** (โปรเจ็กต์ `FatFighting`): ฐานข้อมูล + login ผู้ดูแล + realtime
- **Vercel**: เสิร์ฟเว็บ static (โฟลเดอร์ `public/`)
- **GitHub**: เก็บโค้ด และ Vercel deploy อัตโนมัติเมื่อ push

ผู้ชมอ่านข้อมูลได้โดยไม่ต้อง login; เขียนได้เฉพาะผู้ใช้ที่อยู่ในตาราง `admins` (บังคับด้วย Row Level Security ในฐานข้อมูล ไม่ใช่แค่ซ่อนปุ่มในหน้าเว็บ)

## สิทธิ์ผู้ใช้
| บทบาท | ทำได้ |
|---|---|
| ผู้ชม (ไม่ login) | ดูแดชบอร์ด/อันดับ/รายละเอียด |
| กรรมการ (judge) | ดูทั้งหมด + **บันทึกผลการชั่งน้ำหนักเท่านั้น** |
| Admin | ทุกอย่าง + ลงทะเบียน/ตั้งค่า/ลบ + **สร้าง-ลบ-รีเซ็ตรหัสผ่านกรรมการ** (แท็บ 👥 ผู้ใช้งาน) |

สิทธิ์บังคับด้วย RLS ในฐานข้อมูล การสร้างผู้ใช้กรรมการทำผ่าน Edge Function `manage-users` (ตรวจซ้ำว่าผู้เรียกเป็น Admin; โค้ดอยู่ใน `supabase/functions/manage-users/` และ deploy แล้วบนโปรเจ็กต์ FatFighting)
ฐานข้อมูลบันทึกด้วยว่าใครบันทึกผลแต่ละรอบ (`checkins.updated_by`, `updated_at`)

## 1) สร้าง Admin (ทำครั้งเดียว)
1. Supabase Dashboard → Authentication → Users → **Add user** (ใส่อีเมล/รหัสผ่าน ติ๊ก *Auto Confirm User*)
2. SQL Editor → รันไฟล์ `supabase/make_admin.sql` (แก้อีเมลก่อน)
3. แนะนำ: Authentication → Sign In / Providers → ปิด *Allow new users to sign up*

## 2) Push ขึ้น GitHub
```bash
cd ff-supabase-vercel
git init && git add . && git commit -m "Fat Fighting"
git branch -M main
git remote add origin https://github.com/<ชื่อคุณ>/fat-fighting.git   # สร้าง repo เปล่าบน github.com ก่อน
git push -u origin main
```

## 3) Deploy บน Vercel
Vercel → Add New → Project → เลือก repo `fat-fighting` → Framework: **Other** → Deploy (ไม่ต้องตั้ง Environment Variables เพราะค่า Supabase public อยู่ใน `public/config.js`)

## หมายเหตุ
- ใช้ HTTPS เสมอ (Vercel ให้อัตโนมัติ)
- ย้ายไป Supabase โปรเจ็กต์อื่น: แก้ `public/config.js` และรัน `supabase/migrations/*.sql`
- รูปผู้สมัครเก็บเป็น data-URL ขนาด 96×96 ในคอลัมน์ `participants.photo`
