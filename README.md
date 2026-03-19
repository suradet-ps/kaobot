# 🤖 KaoBot — Telegram Expense Tracker

> บอท Telegram สำหรับบันทึกค่าใช้จ่ายในครอบครัว
> A Telegram bot for tracking shared family expenses — built with **Rust**, **Supabase**, and **Gemini Vision AI**.

[![Rust](https://img.shields.io/badge/rust-1.85%2B-orange)](https://www.rust-lang.org/)
[![Edition](https://img.shields.io/badge/edition-2024-blue)](https://doc.rust-lang.org/edition-guide/rust-2024/)

---

## ✨ Features

| Feature              | How to use                        |
| -------------------- | --------------------------------- |
| บันทึกรายจ่าย        | พิมพ์ `ข้าว 60` หรือ `กาแฟ 65.50` |
| ดูยอดรวมค้างชำระ     | `/summary`                        |
| รายการวันนี้         | `/today`                          |
| 10 รายการล่าสุด      | `/history`                        |
| โอนเงินด้วยตัวเลข    | `/paid 500`                       |
| ส่งสลิปอ่านอัตโนมัติ | ส่งรูปสลิปใน chat                 |
| ยกเลิกรายการ         | `/cancel 42`                      |
| เคลียร์ทุกรายการ     | `/clear`                          |

---

## 🏗️ Project Structure

```
kaobot/
├── src/
│   ├── main.rs         # Entry point, config, message routing dispatcher
│   ├── commands.rs     # Bot command handlers (/summary, /paid, /cancel, …)
│   ├── parser.rs       # Parse "ข้าว 60" text format into (item, amount)
│   ├── supabase.rs     # Supabase REST API client (expenses & payments)
│   └── slip.rs         # Gemini Vision API — read transfer slip images
├── schema.sql          # Supabase PostgreSQL schema (run once)
├── Cargo.toml          # Rust dependencies & release profile
├── Cargo.lock          # Pinned dependency versions
├── rust-toolchain.toml # Pins stable toolchain + clippy/rustfmt
├── .cargo/
│   └── config.toml     # -D warnings flag & lint alias
├── Dockerfile          # Multi-stage Docker build
├── docker-compose.yml  # Docker Compose for production
├── .dockerignore
├── .env.example        # Environment variable template
└── .gitignore
```

---

## 🌊 Architecture & Flow

```
┌─────────────────────────────────────────────────────────────┐
│                        Telegram Chat                        │
└──────────────────────┬──────────────────┬───────────────────┘
                       │ text message     │ photo (slip)
                       ▼                  ▼
              ┌────────────────┐  ┌────────────────────┐
              │  parser.rs     │  │   slip.rs           │
              │ parse_expense()│  │ Gemini Vision API   │
              │ "ข้าว 60"      │  │ → amount: 500       │
              └───────┬────────┘  └────────┬────────────┘
                      │                    │
                      ▼                    ▼
              ┌────────────────────────────────────┐
              │           supabase.rs              │
              │  insert_expense()                  │
              │  insert_payment() + clear_all()    │
              │  get_pending_total()               │
              └────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │  Supabase DB    │
                    │  (PostgreSQL)   │
                    │  expenses       │
                    │  payments       │
                    │  pending_summary│
                    └─────────────────┘

Bot replies:
  "✅ บันทึกแล้ว: ข้าว 60 บาท | ยอดค้าง: 185 บาท"
  "🎉 อ่านสลิปสำเร็จ! โอน 500 บาท | เคลียร์ 8 รายการ"
```

---

## 📋 Prerequisites

| Tool                    | Version         | Notes                                                                                       |
| ----------------------- | --------------- | ------------------------------------------------------------------------------------------- |
| Docker & Docker Compose | any recent      | สำหรับ dev และ production                                                                   |
| Rust                    | 1.85+           | ต้องการเฉพาะถ้ารันแบบ native (ไม่ใช้ Docker)                                                |
| Supabase account        | free tier works | [supabase.com](https://supabase.com)                                                        |
| Telegram Bot Token      | —               | จาก [@BotFather](https://t.me/botfather)                                                    |
| Google Gemini API Key   | —               | จาก [aistudio.google.com/app/apikey](https://aistudio.google.com/app/apikey) — มี free tier |

---

## 🚀 Setup (ทำครั้งเดียว)

### ขั้นที่ 1 — สร้าง Telegram Bot

1. เปิด Telegram → ค้นหา **[@BotFather](https://t.me/botfather)**
2. พิมพ์ `/newbot` → ตั้งชื่อตามต้องการ → ได้ **token** มา เก็บไว้ก่อน
3. **เพิ่ม bot เข้ากลุ่ม** Telegram ของครอบครัว
4. **ตั้ง bot เป็น Admin** ในกลุ่ม → Settings → Administrators → Add Admin
   > ⚠️ ถ้าไม่ตั้งเป็น Admin bot จะอ่านข้อความในกลุ่มไม่ได้

### ขั้นที่ 2 — สร้าง Supabase Project

1. ไปที่ [supabase.com](https://supabase.com) → **New project**
2. เข้า **SQL Editor** → วางโค้ดจาก `schema.sql` ทั้งหมด → **Run**
3. ไปที่ **Settings → API** → copy สองค่านี้:
   - **Project URL** → ใส่ใน `SUPABASE_URL`
   - **anon public** key → ใส่ใน `SUPABASE_ANON_KEY`

### ขั้นที่ 3 — ขอ Gemini API Key

1. ไปที่ [aistudio.google.com/app/apikey](https://aistudio.google.com/app/apikey)
2. คลิก **Create API key** → copy key ที่ได้
3. ใส่ใน `GEMINI_API_KEY`
   > Free tier รองรับ 1,500 requests/วัน เกินพอสำหรับการใช้งานในครอบครัว

### ขั้นที่ 4 — ตั้งค่า Environment

```bash
cd kaobot
cp .env.example .env
```

เปิดไฟล์ `.env` แล้วกรอกค่าต่างๆ:

```env
TELOXIDE_TOKEN=1234567890:ABCdefGHIjklMNOpqrSTUvwxYZ
SUPABASE_URL=https://xxxxxxxxxxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbGci...
GEMINI_API_KEY=AIzaSy...
ALLOWED_CHAT_ID=          # ← เว้นว่างไว้ก่อน จะได้ค่านี้ในขั้นถัดไป
```

### ขั้นที่ 5 — รัน Bot ครั้งแรกเพื่อหา Chat ID

```bash
docker compose up --build
```

รอจน log แสดงว่า bot พร้อมทำงาน:

```
INFO kaobot: 🤖 KaoBot starting...
INFO kaobot: ⚠️  ALLOWED_CHAT_ID not set — bot will respond to ALL chats
INFO kaobot: Send a message in your group to see the chat_id in logs
```

จากนั้น **ไปที่กลุ่ม Telegram แล้วพิมพ์ข้อความอะไรก็ได้** เช่น `test`

กลับมาดู log จะเห็น:

```
INFO kaobot: Message from chat_id: -1001234567890
```

> Chat ID ของกลุ่มจะขึ้นต้นด้วย `-100` เสมอ

### ขั้นที่ 6 — ตั้งค่า Chat ID และ Restart

1. หยุด bot ก่อน: กด `Ctrl+C` หรือ `docker compose down`
2. เปิด `.env` แล้วใส่ค่า `ALLOWED_CHAT_ID`:

```env
ALLOWED_CHAT_ID=-1001234567890
```

3. รัน bot ใหม่:

```bash
docker compose up -d --build
```

ตอนนี้ bot จะตอบเฉพาะกลุ่มนั้นเท่านั้น

---

## 🧪 ทดสอบ Bot ทีละฟีเจอร์

Bot พร้อมใช้งานทันทีหลัง restart ไม่ต้องทำขั้นตอนเพิ่มเติมใดๆ ทดสอบได้เลยใน **กลุ่ม Telegram** ที่เพิ่ม bot ไว้:

### ✅ ทดสอบ 1 — บันทึกรายจ่าย (พิมพ์ข้อความปกติ)

พิมพ์ในกลุ่ม:

```
ข้าว 60
```

Bot ควรตอบ:

```
✅ บันทึกแล้ว: ข้าว 60 บาท
💰 ยอดค้าง: 60 บาท
```

ลองพิมพ์เพิ่ม:

```
กาแฟ 65
ของใช้ในบ้าน 320
```

### ✅ ทดสอบ 2 — ดูรายการ

```
/summary
```

→ แสดงทุกรายการที่ค้างชำระพร้อมยอดรวม

```
/today
```

→ แสดงเฉพาะรายการวันนี้

```
/history
```

→ แสดง 10 รายการล่าสุด

### ✅ ทดสอบ 3 — ยกเลิกรายการ

ดู id จาก `/summary` แล้วพิมพ์:

```
/cancel 1
```

→ ลบรายการ id 1 ออก

### ✅ ทดสอบ 4 — บันทึกการโอนเงินด้วยตัวเลข

```
/paid 445
```

→ บันทึกว่าโอนเงิน 445 บาท + เคลียร์รายการทั้งหมด

### ✅ ทดสอบ 5 — ส่งสลิป (อ่านด้วย Gemini Vision)

ส่งรูปภาพสลิปโอนเงิน (screenshot จากแอปธนาคาร) เข้ากลุ่ม

Bot ควรตอบ:

```
🎉 อ่านสลิปสำเร็จ!
💸 ยอดโอน: 500 บาท
📋 เคลียร์ 3 รายการ
📝 โอนเงิน 500 บาท เมื่อ 25/06 14:30
ยอดตรงพอดี! 🎯
```

> ถ้าอ่านไม่ได้ bot จะบอกให้ใช้ `/paid <จำนวน>` แทน

### ✅ ทดสอบ 6 — ดูคำสั่งทั้งหมด

```
/help
```

---

## 🐳 Docker Workflow

### ดู logs แบบ real-time

```bash
docker compose logs -f
```

### หยุด bot

```bash
docker compose down
```

### รัน bot ใหม่หลังแก้ไข .env

```bash
docker compose down && docker compose up -d --build
```

### ดูสถานะ container

```bash
docker compose ps
```

---

## 🦀 Running Natively (ไม่ใช้ Docker)

```bash
# ติดตั้ง Rust (ถ้ายังไม่มี)
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# รัน development
cargo run

# Build สำหรับ production
cargo build --release
./target/release/kaobot
```

---

## 🧑‍💻 Development Commands

```bash
# รัน unit tests (10 tests)
cargo test

# ตรวจ lint และ warnings
cargo clippy --all-targets -- -D warnings

# จัด format code
cargo fmt

# ตรวจ format โดยไม่แก้ไขไฟล์
cargo fmt --check
```

---

## 🤖 Bot Commands Reference

| Command      | Description                              |
| ------------ | ---------------------------------------- |
| `ข้าว 60`    | บันทึกรายจ่าย: ชื่อรายการ + จำนวนเงิน    |
| `กาแฟ 65.50` | รองรับทศนิยม                             |
| `/help`      | แสดงคำสั่งทั้งหมด                        |
| `/summary`   | รายการค้างชำระทั้งหมดพร้อมยอดรวม         |
| `/today`     | รายการวันนี้ (เวลา Asia/Bangkok)         |
| `/history`   | 10 รายการล่าสุด                          |
| `/paid 500`  | บันทึกการโอน 500 ฿ และเคลียร์ทุกรายการ   |
| `/cancel 42` | ยกเลิกรายการ id 42                       |
| `/clear`     | เคลียร์ทุกรายการ (ไม่บันทึก payment)     |
| _(ส่งรูป)_   | Gemini อ่านยอดจากสลิปและเคลียร์อัตโนมัติ |

### รูปแบบการกรอกรายจ่าย

```
<ชื่อรายการ> <จำนวนเงิน>

ตัวอย่าง:
  ข้าว 60
  กาแฟ 65.50
  ของใช้ในบ้าน 1200
  ค่าน้ำมัน 450.75
```

- ชื่อรายการมีเว้นวรรคได้ รองรับภาษาไทย
- จำนวนเงินต้องมากกว่า 0 และไม่เกิน 1,000,000
- รองรับทศนิยมสูงสุด 2 ตำแหน่ง
- ข้อความที่ไม่ตรงรูปแบบจะถูกเพิกเฉย ไม่กวนการสนทนาปกติ

---

## 🗄️ Database Schema

รัน `schema.sql` ใน Supabase SQL Editor ครั้งเดียวเพื่อสร้าง:

| Object            | Type  | Purpose                     |
| ----------------- | ----- | --------------------------- |
| `expenses`        | table | รายการค่าใช้จ่ายแต่ละรายการ |
| `payments`        | table | บันทึกการโอนเงิน/ชำระ       |
| `pending_summary` | view  | รวมยอดค้างชำระแยกตาม chat   |
| `daily_summary`   | view  | สรุปรายวัน                  |

---

## 🔧 Troubleshooting

### Bot ไม่ตอบข้อความในกลุ่ม

1. ตรวจสอบว่า bot เป็น **Admin** ในกลุ่มแล้วหรือยัง
2. ตรวจสอบ `TELOXIDE_TOKEN` ใน `.env` ว่าถูกต้อง
3. ตรวจสอบ `ALLOWED_CHAT_ID` — ต้องตรงกับ chat id ของกลุ่ม (ขึ้นต้น `-100`)
4. ดู logs: `docker compose logs -f`

### Bot ตอบใน DM แต่ไม่ตอบในกลุ่ม

- Bot ไม่ได้เป็น Admin ในกลุ่ม → ไปที่ Group Settings → Administrators → Add Administrator

### หา Chat ID ไม่เจอใน log

- ตรวจสอบว่า `ALLOWED_CHAT_ID` ใน `.env` เว้นว่างอยู่ (ไม่ใส่ค่า)
- ส่งข้อความจาก **ภายในกลุ่ม** ไม่ใช่ DM กับ bot
- รัน `docker compose logs -f` แล้วค่อยส่งข้อความ

### "SUPABASE_URL must be set" หรือ "GEMINI_API_KEY must be set"

- ไฟล์ `.env` ไม่ถูกโหลด — ตรวจสอบว่าไฟล์อยู่ใน directory เดียวกับ `docker-compose.yml`
- ตรวจสอบว่าไม่มีช่องว่างหน้า/หลัง `=` ใน `.env`

### บันทึกรายจ่ายแล้ว bot ตอบ "❌ บันทึกไม่สำเร็จ"

- ตรวจสอบว่ารัน `schema.sql` ใน Supabase แล้ว
- ตรวจสอบ `SUPABASE_URL` และ `SUPABASE_ANON_KEY` ว่าถูกต้อง
- เข้า Supabase Dashboard → **Table Editor** → ตรวจสอบว่ามีตาราง `expenses` และ `payments`
- ตรวจ RLS policies: Supabase → **Authentication → Policies** → ตารางทั้งสองต้องมี policy "Allow all for anon"

### Slip reading ตอบ "อ่านยอดไม่ได้"

- ตรวจสอบ `GEMINI_API_KEY` ว่าถูกต้องและยังมี quota
- ส่งรูป **screenshot** ตรงๆ จากแอปธนาคาร อย่าถ่ายรูปจากหน้าจอ (quality ต่ำเกินไป)
- ใช้ `/paid <จำนวน>` เป็น fallback ได้เสมอ

### Docker build ช้ามากหรือ fail

```bash
# ล้าง cache แล้ว build ใหม่
docker compose down
docker system prune -f
docker compose up --build
```

---

## 📝 Notes

- Bot ใช้ **Long Polling** — ไม่ต้องมี public IP หรือ webhook
- รูปสลิปถูกส่งให้ Gemini API อ่านชั่วคราว ไม่ได้เก็บไว้ที่ใด
- ถ้าอ่านสลิปไม่ได้ ใช้ `/paid <จำนวน>` เป็น fallback ได้เสมอ
- ข้อมูลทั้งหมดเก็บใน Supabase (PostgreSQL) ของคุณเอง ดู dashboard ได้ตลอดเวลา
- รองรับหลายกลุ่มพร้อมกัน แต่ละ `chat_id` มี ledger แยกกัน
- `ALLOWED_CHAT_ID` ไม่บังคับ แต่แนะนำให้ตั้งเพื่อป้องกันการใช้งานจากกลุ่มอื่น
