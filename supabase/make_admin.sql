-- 1) สร้างผู้ใช้ใน Supabase Dashboard > Authentication > Users > Add user (ติ๊ก Auto Confirm User)
-- 2) แก้อีเมลด้านล่างแล้วรันใน SQL Editor เพื่อให้ผู้ใช้นั้นเป็น Admin
insert into public.admins (user_id)
select id from auth.users where email = 'admin@example.com'
on conflict do nothing;
