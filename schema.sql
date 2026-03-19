-- ============================================
-- KaoBot Database Schema
-- Run this in Supabase SQL Editor
-- ============================================

-- Table: expenses (รายการค่าใช้จ่าย)
CREATE TABLE IF NOT EXISTS expenses (
    id          BIGSERIAL PRIMARY KEY,
    item        TEXT        NOT NULL,           -- ชื่อรายการ เช่น "ข้าว"
    amount      NUMERIC(10,2) NOT NULL,         -- จำนวนเงิน เช่น 60.00
    paid_by     TEXT        NOT NULL DEFAULT 'wife',  -- ใครจ่าย
    chat_id     BIGINT      NOT NULL,           -- Telegram chat ID
    message_id  BIGINT,                        -- Telegram message ID (สำหรับ dedup)
    is_cleared  BOOLEAN     NOT NULL DEFAULT FALSE,  -- เคลียร์แล้วหรือยัง
    cleared_at  TIMESTAMPTZ,                   -- เวลาที่เคลียร์
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table: payments (บันทึกการโอนเงิน)
CREATE TABLE IF NOT EXISTS payments (
    id           BIGSERIAL PRIMARY KEY,
    amount       NUMERIC(10,2) NOT NULL,        -- ยอดที่โอน
    method       TEXT NOT NULL DEFAULT 'slip',  -- 'slip' | 'manual'
    slip_image   TEXT,                          -- base64 หรือ URL รูปสลิป (optional)
    chat_id      BIGINT NOT NULL,
    message_id   BIGINT,
    note         TEXT,                          -- หมายเหตุ เช่น ข้อมูลจากสลิป
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index สำหรับ query เร็ว
CREATE INDEX IF NOT EXISTS idx_expenses_chat_id     ON expenses(chat_id);
CREATE INDEX IF NOT EXISTS idx_expenses_is_cleared  ON expenses(is_cleared);
CREATE INDEX IF NOT EXISTS idx_expenses_created_at  ON expenses(created_at);
CREATE INDEX IF NOT EXISTS idx_payments_chat_id     ON payments(chat_id);

-- View: ยอดค้างชำระ (ใช้ใน /summary command)
CREATE OR REPLACE VIEW pending_summary AS
SELECT
    chat_id,
    COUNT(*)            AS item_count,
    SUM(amount)         AS total_amount,
    MIN(created_at)     AS oldest_expense,
    MAX(created_at)     AS latest_expense
FROM expenses
WHERE is_cleared = FALSE
GROUP BY chat_id;

-- Table: credit_balance (ยอดเงินที่โอนมาเกินค้าง — นำไปหักรายการถัดไปอัตโนมัติ)
CREATE TABLE IF NOT EXISTS credit_balance (
    chat_id     BIGINT        PRIMARY KEY,      -- 1 row ต่อ 1 chat
    balance     NUMERIC(10,2) NOT NULL DEFAULT 0.00,
    updated_at  TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_credit_balance_chat_id ON credit_balance(chat_id);

ALTER TABLE credit_balance ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow all for anon" ON credit_balance FOR ALL USING (true);

-- View: สรุปรายวัน
CREATE OR REPLACE VIEW daily_summary AS
SELECT
    chat_id,
    DATE(created_at AT TIME ZONE 'Asia/Bangkok') AS expense_date,
    COUNT(*)        AS item_count,
    SUM(amount)     AS total_amount
FROM expenses
WHERE is_cleared = FALSE
GROUP BY chat_id, DATE(created_at AT TIME ZONE 'Asia/Bangkok')
ORDER BY expense_date DESC;

-- ============================================
-- Row Level Security (แนะนำให้เปิด)
-- ============================================
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;

-- Policy: อนุญาต service_role ทำได้ทุกอย่าง (bot ใช้ anon key ก็ได้สำหรับ dev)
-- สำหรับ production ควรสร้าง service_role key แยก
CREATE POLICY "Allow all for anon" ON expenses FOR ALL USING (true);
CREATE POLICY "Allow all for anon" ON payments FOR ALL USING (true);
