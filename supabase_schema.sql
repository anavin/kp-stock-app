-- =====================================================================
-- Lab Parfumo — King Power Stock Management
-- Supabase Database Schema
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

-- 2) ตาราง audit_log เก็บประวัติการเปลี่ยนแปลง (สำหรับติดตาม/ย้อนกลับ)
CREATE TABLE IF NOT EXISTS public.audit_log (
  id           bigserial    PRIMARY KEY,
  action       text         NOT NULL,        -- 'push' | 'pull' | 'init'
  user_id      uuid         REFERENCES auth.users(id) ON DELETE SET NULL,
  user_email   text,
  data_size    int,
  summary      text,                          -- เช่น "saved slip RNG-25-12-30-001"
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
-- Row Level Security (RLS) — สิทธิ์การเข้าถึง
-- =====================================================================
-- เฉพาะผู้ที่ login (authenticated) เท่านั้นที่อ่าน/เขียนได้
-- =====================================================================

ALTER TABLE public.app_state ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;

-- ลบ policy เก่า (ถ้ามี) เพื่อกัน duplicate ตอนรันซ้ำ
DROP POLICY IF EXISTS "app_state read for authenticated" ON public.app_state;
DROP POLICY IF EXISTS "app_state write for authenticated" ON public.app_state;
DROP POLICY IF EXISTS "audit_log read for authenticated" ON public.audit_log;
DROP POLICY IF EXISTS "audit_log insert for authenticated" ON public.audit_log;

CREATE POLICY "app_state read for authenticated" ON public.app_state
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "app_state write for authenticated" ON public.app_state
  FOR UPDATE TO authenticated USING (true) WITH CHECK (true);

CREATE POLICY "audit_log read for authenticated" ON public.audit_log
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "audit_log insert for authenticated" ON public.audit_log
  FOR INSERT TO authenticated WITH CHECK (true);

-- =====================================================================
-- (ทางเลือก) จำกัดสิทธิ์เฉพาะอีเมลในรายชื่อ
-- ถ้าต้องการ uncomment ส่วนนี้แล้วแก้รายชื่ออีเมลที่อนุญาต
-- =====================================================================
-- DROP POLICY "app_state write for authenticated" ON public.app_state;
-- CREATE POLICY "app_state write for allowed emails" ON public.app_state
--   FOR UPDATE TO authenticated
--   USING (auth.jwt() ->> 'email' IN ('owner@example.com', 'manager@example.com'))
--   WITH CHECK (auth.jwt() ->> 'email' IN ('owner@example.com', 'manager@example.com'));

-- =====================================================================
-- เปิด Realtime สำหรับตาราง app_state (ทำในหน้า Dashboard ก็ได้)
-- =====================================================================
ALTER PUBLICATION supabase_realtime ADD TABLE public.app_state;
