# KaoBot

```
██╗  ██╗ █████╗  ██████╗ ██████╗  ██████╗ ████████╗
██║ ██╔╝██╔══██╗██╔═══██╗██╔══██╗██╔═══██╗╚══██╔══╝
█████╔╝ ███████║██║   ██║██████╔╝██║   ██║   ██║
██╔═██╗ ██╔══██║██║   ██║██╔══██╗██║   ██║   ██║
██║  ██╗██║  ██║╚██████╔╝██████╔╝╚██████╔╝   ██║
╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═════╝ ╚═════╝   ╚═╝
```

---

## ◆ PULSE

Shared expenses die in group chats: a message of who owes what, buried
under memes, forgotten by payday. KaoBot turns the household group chat
into a ledger. Type `rice 60`, send the bank slip photo and watch Gemini
read the amount off it, ask `/summary` and get the truth - who spent,
who paid, what is still owed. One bot in the group, each chat with its
own isolated ledger, no webhook, no public IP, no excuses.

| Ledger ▣ | Slips ▣ | Credit ▣ | Isolation ▣ |
|---|---|---|---|

*The core loop - log, read, settle, summarize - is sealed and serving.*

> Built with Rust 2024 + Teloxide, stored in Supabase, reading slips
> through Gemini Vision - long polling, so it runs anywhere.
>
> **suradet-ps**, artifact keeper

---

## ◆ IGNITION

Five keys, one container.

```
⟫ docker compose up --build
```

Send any message in the group, read the `chat_id` from the logs, lock it
into `.env`, then:

```
⟫ docker compose up -d --build
```

<details>
<summary>Setup</summary>

1. Create the bot with [@BotFather](https://t.me/botfather) (`/newbot`)
   and make it **Admin** in the group - required to read group messages.
2. Create a [Supabase](https://supabase.com) project, run `schema.sql`
   in the SQL Editor, copy the Project URL and anon key.
3. Create a Gemini API key at
   [aistudio.google.com/app/apikey](https://aistudio.google.com/app/apikey)
   (free tier covers 1,500 requests/day).
4. `cp .env.example .env` and fill:

```
TELOXIDE_TOKEN=<from BotFather>
SUPABASE_URL=<project URL>
SUPABASE_ANON_KEY=<anon key>
GEMINI_API_KEY=<your key>
ALLOWED_CHAT_ID=          # leave empty for now
```

</details>

---

## ◆ ANATOMY

Five small files, one honest boundary: the chat says it, the ledger
remembers it.

- **Parses** - `parser.rs` reads `item amount` from plain text: `rice 60`,
  `coffee 65.50`, `household supplies 320`. Multi-word names and Thai
  text parse; amounts must be above zero and under a million; anything
  else is silently ignored - no noise, no false entries.
- **Reads** - `slip.rs` sends a bank transfer screenshot to Gemini
  Vision and gets the amount back. The image is temporary and never
  stored; when the machine cannot read the slip, the human still has
  `/paid <amount>`.
- **Ledgers** - `supabase.rs` writes expenses, payments, and credit
  against `chat_id`: every group has its own ledger, and overpayment
  becomes credit that future expenses consume automatically.
- **Settles** - `/paid 500` clears all pending items; an overpayment is
  kept honestly as credit instead of vanishing into the void.
- **Answers** - `/summary`, `/today` (Asia/Bangkok time), `/history`,
  `/cancel <id>`, `/clear` - the commands of a household that keeps its
  books.

---

## ◆ RITUALS

**The core ceremony** - the daily ledger:

1. Type it: `rice 60`. The parser understands; the entry lands.
2. Pay it: send the slip photo. Gemini reads the amount and settles the
   balance automatically - or the `/paid` fallback speaks for it.
3. Ask it: `/summary` reports every pending item with its total. Who
   owes what is no longer a memory, it is a query.
4. Close it: overpaid? The excess waits as credit and eats the next
   expense on its own.

**The ceremony of the slip** - the receipt is read by a machine and seen
by no one else. The image goes to Gemini for a moment and is never
stored; the ledger keeps only the number.

**The ceremony of the group** - `ALLOWED_CHAT_ID` locks the bot to one
chat. A ledger is only honest when it is private, and only useful when
it is exactly where the household already talks.

---

## ◆ ECHOES

**Where this artifact is heading**

```
logging   ▸ "item amount" parsing, Thai and multi-word ───────────── ▸ sealed
reading   ▸ Gemini slip OCR with /paid fallback ───────────────────── ▸ sealed
settling  ▸ payments, credit carry-over, per-chat ledgers ─────────── ▸ sealed
asking    ▸ summary, today, history, cancel, clear ────────────────── ▸ sealed
```

**Raising the artifact** - the schema is `schema.sql`, the config is
`.env.example`, the gates are `cargo test`, `cargo clippy --all-targets
-- -D warnings`, and `cargo fmt`. Open an issue first to discuss a
change.

**Status** - CI gates every push. [Watch the gates](.github/workflows).

---

```
  ─────────────────────────────────────────
   A household that keeps its books
   has nothing to fight about.
  ─────────────────────────────────────────
```

MIT License.