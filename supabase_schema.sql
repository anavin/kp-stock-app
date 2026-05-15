-- =====================================================================
-- Lab Parfumo — King Power Stock Management
-- Supabase Database Schema (with Role-Based Security)
-- =====================================================================
-- วิธีใช้: คัดลอกไฟล์นี้ทั้งหมด → ไปที่ Supabase Dashboard
-- → SQL Editor → New Query → วาง → Run
-- =====================================================================

-- 1) ตาราง app_state เก็บ state ทั้งหมดของแอป (1 row เดียว)
CREATE TABLE IF NOT EXISTS public.app_state (
  id           int          PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  data         jsonb        NOT NULL DEFAULT '{}'::jsonb,
  version      bigint       NOT NULL DEFAULT 1,
  updated_at   timestamptz  NOT NULL DEFAULT now(),
  updated_by   uuid         REFERENCES auth.users(id) ON DELETE SET NULL
);

-- 2) ตาราง audit_log เก็บประวัติการเปลี่ยนแปลง
CREATE TABLE IF NOT EXISTS public.audit_log (
  id           bigserial    PRIMARY KEY,
  action       text         NOT NULL,
  user_id      uuid         REFERENCES auth.users(id) ON DELETE SET NULL,
  user_email   text,
  data_size    int,
  summary      text,
  created_at   timestamptz  NOT NULL DEFAULT now()
);

-- 3) Trigger: อัพเดท updated_at + version อัตโนมัติ
CREATE OR REPLACE FUNCTION public.update_app_state_meta()
RETURNS trigger AS $$
BEGIN
  NEW.updated_at := now();
  NEW.version    := OLD.version + 1;
  NEW.updated_by := auth.uid();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_app_state_meta ON public.app_state;
CREATE TRIGGER trg_app_state_meta
  BEFORE UPDATE ON public.app_state
  FOR EACH ROW EXECUTE FUNCTION public.update_app_state_meta();

-- 4) สร้าง row เริ่มต้น
INSERT INTO public.app_state (id, data) VALUES (1, '{}'::jsonb)
ON CONFLICT (id) DO NOTHING;

-- =====================================================================
-- ROLE-BASED ACCESS CONTROL
-- =====================================================================
-- Roles: admin (full), manager (read+write), staff (read only)
-- Role อยู่ใน auth.users.raw_user_meta_data->>'role'
-- ตั้งตอน signup ผ่านแอป หรือแก้ใน Authentication → Users → Edit
-- =====================================================================

-- Helper function: ดึง role ของ user ปัจจุบัน
CREATE OR REPLACE FUNCTION public.current_role()
RETURNS text AS $$
  SELECT COALESCE(
    (auth.jwt() -> 'user_metadata' ->> 'role'),
    'staff'  -- default ถ้าไม่ได้ตั้ง
  );
$$ LANGUAGE sql STABLE;

-- Helper function: เช็คว่า user เป็น admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean AS $$
  SELECT public.current_role() = 'admin';
$$ LANGUAGE sql STABLE;

-- Helper function: เช็คว่า user แก้ข้อมูลได้
-- admin + manager แก้ได้, staff อ่านอย่างเดียว
CREATE OR REPLACE FUNCTION public.can_write()
RETURNS boolean AS $$
  SELECT public.current_role() IN ('admin','manager');
$$ LANGUAGE sql STABLE;

ALTER TABLE public.app_state ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;

-- ลบ policy เก่าและใหม่ (กันรันซ้ำ)
DROP POLICY IF EXISTS "app_state read for authenticated" ON public.app_state;
DROP POLICY IF EXISTS "app_state write for authenticated" ON public.app_state;
DROP POLICY IF EXISTS "app_state read all authenticated" ON public.app_state;
DROP POLICY IF EXISTS "app_state write for admin/manager" ON public.app_state;
DROP POLICY IF EXISTS "audit_log read for authenticated" ON public.audit_log;
DROP POLICY IF EXISTS "audit_log insert for authenticated" ON public.audit_log;
DROP POLICY IF EXISTS "audit_log read all" ON public.audit_log;
DROP POLICY IF EXISTS "audit_log insert self" ON public.audit_log;

-- READ: ทุก authenticated user อ่านได้
CREATE POLICY "app_state read all authenticated" ON public.app_state
  FOR SELECT TO authenticated USING (true);

-- WRITE: เฉพาะ admin หรือ manager เท่านั้น
CREATE POLICY "app_state write for admin/manager" ON public.app_state
  FOR UPDATE TO authenticated
  USING (public.can_write())
  WITH CHECK (public.can_write());

-- audit_log: ทุก user อ่านได้ และเขียนได้ (เพื่อบันทึก action ของตัวเอง)
CREATE POLICY "audit_log read all" ON public.audit_log
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "audit_log insert self" ON public.audit_log
  FOR INSERT TO authenticated WITH CHECK (true);

-- ===================================================================
-- เปิด Realtime (idempotent — รันซ้ำได้)
-- ===================================================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
      AND schemaname = 'public'
      AND tablename = 'app_state'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.app_state;
  END IF;
END $$;

-- ===================================================================
-- การตั้ง role ให้ user
-- ===================================================================
-- วิธีที่ 1: ผ่านแอป — เลือก role ตอน Sign Up (default จะเก็บใน user_metadata.role)
--
-- วิธีที่ 2: ผ่าน Dashboard
--   Authentication → Users → คลิก user → User metadata → ใส่:
--   {"role": "admin"}    หรือ
--   {"role": "manager"}  หรือ
--   {"role": "staff"}
--
-- วิธีที่ 3: SQL (เปลี่ยนอีเมล + role ตามต้องการ)
-- UPDATE auth.users SET raw_user_meta_data = raw_user_meta_data || '{"role":"admin"}'::jsonb
-- WHERE email = 'admin@yourcompany.com';

-- ===================================================================
-- USER MANAGEMENT FUNCTIONS (เรียกจากแอปได้ — เฉพาะ admin)
-- ===================================================================

-- list_users — ดึงรายชื่อ users ทั้งหมด (admin only)
CREATE OR REPLACE FUNCTION public.list_users()
RETURNS TABLE (
  id uuid,
  email text,
  role text,
  branch_code text,
  created_at timestamptz,
  last_sign_in_at timestamptz,
  email_confirmed boolean
)
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: admin only';
  END IF;
  RETURN QUERY
  SELECT
    u.id,
    u.email::text,
    COALESCE(u.raw_user_meta_data->>'role', 'staff') AS role,
    COALESCE(u.raw_user_meta_data->>'branch_code', '') AS branch_code,
    u.created_at,
    u.last_sign_in_at,
    (u.email_confirmed_at IS NOT NULL) AS email_confirmed
  FROM auth.users u
  ORDER BY u.created_at DESC;
END;
$$ LANGUAGE plpgsql;

-- update_user_role — แก้ role/branch ของ user (admin only)
CREATE OR REPLACE FUNCTION public.update_user_role(
  target_user_id uuid,
  new_role text,
  new_branch text DEFAULT ''
)
RETURNS jsonb
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: admin only';
  END IF;
  IF new_role NOT IN ('admin','manager','staff') THEN
    RAISE EXCEPTION 'Invalid role';
  END IF;
  UPDATE auth.users
  SET raw_user_meta_data = COALESCE(raw_user_meta_data, '{}'::jsonb)
    || jsonb_build_object('role', new_role, 'branch_code', new_branch)
  WHERE id = target_user_id;
  RETURN jsonb_build_object('success', true);
END;
$$ LANGUAGE plpgsql;

-- delete_user — ลบ user (admin only, ลบตัวเองไม่ได้)
CREATE OR REPLACE FUNCTION public.delete_user(target_user_id uuid)
RETURNS jsonb
SECURITY DEFINER
SET search_path = public, auth
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Unauthorized: admin only';
  END IF;
  IF target_user_id = auth.uid() THEN
    RAISE EXCEPTION 'Cannot delete yourself';
  END IF;
  DELETE FROM auth.users WHERE id = target_user_id;
  RETURN jsonb_build_object('success', true);
END;
$$ LANGUAGE plpgsql;

-- ===================================================================
-- รักษาความปลอดภัยเพิ่มเติม (ทางเลือก)
-- ===================================================================
-- ลบ policy แล้วเปลี่ยนเป็นจำกัดเฉพาะอีเมลในไวท์ลิสต์:
--
-- DROP POLICY "app_state write for admin/manager" ON public.app_state;
-- CREATE POLICY "app_state write for whitelist" ON public.app_state
--   FOR UPDATE TO authenticated
--   USING (auth.jwt() ->> 'email' LIKE '%@labparfumo.com'
--          AND public.can_write())
--   WITH CHECK (auth.jwt() ->> 'email' LIKE '%@labparfumo.com'
--               AND public.can_write());
