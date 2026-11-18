// Admin-only user management for judges (กรรมการ). Uses the service role, so it re-checks that the caller is an admin.
import { createClient } from "npm:@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (b: unknown, s = 200) =>
  new Response(JSON.stringify(b), { status: s, headers: { ...cors, "Content-Type": "application/json" } });
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return json({ error: "method not allowed" }, 405);

  const svc = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  // 1) caller must be a signed-in admin
  const jwt = (req.headers.get("Authorization") || "").replace(/^Bearer\s+/i, "");
  const { data: u, error: ue } = await svc.auth.getUser(jwt);
  if (ue || !u?.user) return json({ error: "unauthorized" }, 401);
  const { data: adm } = await svc.from("admins").select("user_id").eq("user_id", u.user.id).maybeSingle();
  if (!adm) return json({ error: "เฉพาะ Admin เท่านั้น" }, 403);

  let b: any;
  try { b = await req.json(); } catch { return json({ error: "bad json" }, 400); }
  const isJudge = async (id: string) =>
    !!(await svc.from("judges").select("user_id").eq("user_id", id).maybeSingle()).data;

  // 2) actions
  if (b.action === "create") {
    const name = String(b.display_name || "").trim();
    const email = String(b.email || "").trim().toLowerCase();
    const password = String(b.password || "");
    if (!name || name.length > 80) return json({ error: "กรุณากรอกชื่อกรรมการ (ไม่เกิน 80 ตัวอักษร)" }, 400);
    if (!EMAIL.test(email)) return json({ error: "อีเมลไม่ถูกต้อง" }, 400);
    if (password.length < 8) return json({ error: "รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร" }, 400);
    const { data, error } = await svc.auth.admin.createUser({
      email, password, email_confirm: true, user_metadata: { display_name: name },
    });
    if (error || !data?.user) return json({ error: error?.message || "สร้างผู้ใช้ไม่สำเร็จ" }, 400);
    const { error: ie } = await svc.from("judges").insert({
      user_id: data.user.id, display_name: name, email, created_by: u.user.id,
    });
    if (ie) { await svc.auth.admin.deleteUser(data.user.id); return json({ error: ie.message }, 400); }
    return json({ ok: true, user_id: data.user.id });
  }

  if (b.action === "delete" || b.action === "reset_password") {
    const id = String(b.user_id || "");
    if (!UUID.test(id)) return json({ error: "invalid user_id" }, 400);
    if (!(await isJudge(id))) return json({ error: "ไม่พบกรรมการคนนี้" }, 404);
    if (b.action === "delete") {
      const { error } = await svc.auth.admin.deleteUser(id);
      return error ? json({ error: error.message }, 400) : json({ ok: true });
    }
    const password = String(b.password || "");
    if (password.length < 8) return json({ error: "รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร" }, 400);
    const { error } = await svc.auth.admin.updateUserById(id, { password });
    return error ? json({ error: error.message }, 400) : json({ ok: true });
  }

  return json({ error: "unknown action" }, 400);
});
