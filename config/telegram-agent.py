#!/usr/bin/env python3
"""
telegram-agent.py — Persistent Claude ↔ Telegram bridge agent.

Claude'u stream-json modunda açar, Telegram mesajlarını direkt session'a
yazar, cevabı Telegram'a gönderir. Tek process, kesintisiz session context.

Kullanım:
    python3 config/telegram-agent.py [proje_dizini]

Aliases:
    tgbot-agent    → bu scripti başlatır
    tgbot-stop     → durdurur
"""

import json, os, sys, subprocess, time, signal, threading, urllib.request, urllib.parse
from pathlib import Path
from datetime import datetime

# ── Config ──────────────────────────────────────────────────────────────────

PROJECT_DIR = sys.argv[1] if len(sys.argv) > 1 else os.path.expanduser("~/Projects/claude-config")
LOG_FILE = os.path.expanduser("~/.watchdog/telegram-agent.log")
OFFSET_FILE = os.path.expanduser("~/.watchdog/telegram_offset")
HEARTBEAT_FILE = "/tmp/watchdog/telegram-agent.json"

# Load secrets
def load_secrets():
    paths = [
        os.path.expanduser("~/Projects/claude-config/claude-secrets/secrets.env"),
        os.path.expanduser("~/.claude/secrets/secrets.env"),
    ]
    secrets = {}
    for p in paths:
        if os.path.exists(p):
            for line in open(p):
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    k, v = line.split("=", 1)
                    secrets[k.strip()] = v.strip().strip('"').strip("'")
    return secrets

secrets = load_secrets()
BOT_TOKEN = secrets.get("TELEGRAM_BOT_TOKEN", "")
CHAT_ID = secrets.get("TELEGRAM_CHAT_ID", "")
API = f"https://api.telegram.org/bot{BOT_TOKEN}"

if not BOT_TOKEN or not CHAT_ID:
    print("❌ TELEGRAM_BOT_TOKEN / TELEGRAM_CHAT_ID eksik", file=sys.stderr)
    sys.exit(1)

# ── Logging ─────────────────────────────────────────────────────────────────

os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)
os.makedirs(os.path.dirname(HEARTBEAT_FILE), exist_ok=True)

def log(msg):
    ts = datetime.now().strftime("%H:%M:%S")
    line = f"{ts}: {msg}"
    print(line)
    with open(LOG_FILE, "a") as f:
        f.write(line + "\n")

def heartbeat(status, step="idle"):
    try:
        with open(HEARTBEAT_FILE, "w") as f:
            json.dump({
                "task": "telegram-agent",
                "step": step,
                "status": status,
                "ts": datetime.now().isoformat(),
                "project": PROJECT_DIR,
            }, f)
    except:
        pass

# ── Telegram helpers ────────────────────────────────────────────────────────

def tg_request(method, data=None):
    url = f"{API}/{method}"
    if data:
        data = urllib.parse.urlencode(data).encode()
    try:
        req = urllib.request.Request(url, data=data)
        with urllib.request.urlopen(req, timeout=10) as resp:
            return json.loads(resp.read())
    except Exception as e:
        log(f"TG API error ({method}): {e}")
        return None

def tg_send(text, reply_markup=None):
    """Send message to Telegram, split if too long."""
    MAX = 4000
    chunks = [text[i:i+MAX] for i in range(0, len(text), MAX)]
    for i, chunk in enumerate(chunks):
        data = {
            "chat_id": CHAT_ID,
            "text": chunk,
            "parse_mode": "Markdown",
        }
        if reply_markup and i == len(chunks) - 1:
            data["reply_markup"] = reply_markup
        tg_request("sendMessage", data)

def tg_send_file(filepath, caption="Çıktı"):
    """Send file via multipart form."""
    import io
    boundary = "----PythonBoundary"
    body = io.BytesIO()

    def write(s):
        body.write(s.encode() if isinstance(s, str) else s)

    write(f"--{boundary}\r\nContent-Disposition: form-data; name=\"chat_id\"\r\n\r\n{CHAT_ID}\r\n")
    write(f"--{boundary}\r\nContent-Disposition: form-data; name=\"caption\"\r\n\r\n{caption}\r\n")

    fname = os.path.basename(filepath)
    write(f"--{boundary}\r\nContent-Disposition: form-data; name=\"document\"; filename=\"{fname}\"\r\nContent-Type: application/octet-stream\r\n\r\n")
    with open(filepath, "rb") as f:
        write(f.read())
    write(f"\r\n--{boundary}--\r\n")

    req = urllib.request.Request(
        f"{API}/sendDocument",
        data=body.getvalue(),
        headers={"Content-Type": f"multipart/form-data; boundary={boundary}"},
    )
    try:
        urllib.request.urlopen(req, timeout=30)
    except Exception as e:
        log(f"Send file error: {e}")

def tg_typing():
    tg_request("sendChatAction", {"chat_id": CHAT_ID, "action": "typing"})

KEYBOARD = json.dumps({
    "keyboard": [[{"text": "📊 Durum"}, {"text": "📁 Projeler"}],
                  [{"text": "📋 Log"}, {"text": "⏹ Durdur"}]],
    "resize_keyboard": True, "persistent": True
})

# ── Claude stream-json process ──────────────────────────────────────────────

claude_proc = None
claude_lock = threading.Lock()
response_buffer = []
response_event = threading.Event()

def start_claude():
    """Start claude in streaming JSON mode."""
    global claude_proc
    model = os.environ.get("CLAUDE_TG_MODEL", "haiku")
    log(f"Claude agent başlatılıyor → {PROJECT_DIR} (model: {model})")
    claude_proc = subprocess.Popen(
        ["claude", "-p", "--continue",
         "--model", model,
         "--input-format", "stream-json",
         "--output-format", "stream-json",
         "--verbose",
         "--no-session-persistence"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        cwd=PROJECT_DIR,
        text=False,
    )
    # Start output reader thread
    threading.Thread(target=read_claude_output, daemon=True).start()
    threading.Thread(target=read_claude_stderr, daemon=True).start()
    log("Claude agent hazır")

def read_claude_output():
    """Read claude stdout (stream-json) and collect assistant messages."""
    global claude_proc
    for line in claude_proc.stdout:
        try:
            data = json.loads(line.decode("utf-8", errors="replace"))
            msg_type = data.get("type", "")

            if msg_type == "assistant":
                # Full assistant message
                content = data.get("message", {}).get("content", [])
                text_parts = []
                for block in content:
                    if isinstance(block, dict) and block.get("type") == "text":
                        text_parts.append(block["text"])
                    elif isinstance(block, str):
                        text_parts.append(block)
                if text_parts:
                    response_buffer.append("\n".join(text_parts))
                    response_event.set()

            elif msg_type == "content_block_delta":
                # Streaming delta
                delta = data.get("delta", {})
                if delta.get("type") == "text_delta":
                    pass  # We wait for full message

            elif msg_type == "result":
                # Final result
                result_text = data.get("result", "")
                if result_text and not response_buffer:
                    response_buffer.append(result_text)
                response_event.set()

        except (json.JSONDecodeError, UnicodeDecodeError):
            pass

def read_claude_stderr():
    """Read claude stderr for errors."""
    global claude_proc
    for line in claude_proc.stderr:
        msg = line.decode("utf-8", errors="replace").strip()
        if msg:
            log(f"[claude stderr] {msg}")

def send_to_claude(text):
    """Send a user message to claude via stream-json."""
    global claude_proc, response_buffer

    if claude_proc is None or claude_proc.poll() is not None:
        log("Claude process yok veya öldü, yeniden başlatılıyor...")
        start_claude()

    response_buffer.clear()
    response_event.clear()

    msg = json.dumps({
        "type": "user",
        "message": {"role": "user", "content": text}
    }) + "\n"

    with claude_lock:
        try:
            claude_proc.stdin.write(msg.encode("utf-8"))
            claude_proc.stdin.flush()
        except (BrokenPipeError, OSError) as e:
            log(f"Claude stdin error: {e}, restarting...")
            start_claude()
            claude_proc.stdin.write(msg.encode("utf-8"))
            claude_proc.stdin.flush()

    # Wait for response (max 5 min)
    response_event.wait(timeout=300)

    if response_buffer:
        return "\n".join(response_buffer)
    return "(Yanıt alınamadı — timeout veya hata)"

# ── Telegram polling ────────────────────────────────────────────────────────

def get_offset():
    try:
        return int(open(OFFSET_FILE).read().strip())
    except:
        return 0

def save_offset(offset):
    with open(OFFSET_FILE, "w") as f:
        f.write(str(offset))

def skip_old_messages():
    """Skip to latest message on startup."""
    resp = tg_request("getUpdates", {"offset": -1})
    if resp and resp.get("result"):
        latest = resp["result"][-1]["update_id"] + 1
        save_offset(latest)
        return latest
    return get_offset()

def parse_update(update):
    """Parse a Telegram update into (type, text, extras)."""
    msg = update.get("message", {})
    cb = update.get("callback_query", {})

    if cb:
        tg_request("answerCallbackQuery", {"callback_query_id": cb["id"]})
        return "CB", cb.get("data", ""), {}

    chat_id = str(msg.get("chat", {}).get("id", ""))
    if chat_id != CHAT_ID:
        return None, None, {}

    if msg.get("photo"):
        photos = msg["photo"]
        file_id = photos[-1]["file_id"]  # largest
        caption = msg.get("caption", "")
        return "PHOTO", caption or "Bu resmi analiz et", {"file_id": file_id}

    if msg.get("document"):
        doc = msg["document"]
        return "DOC", msg.get("caption", "Bu dosyayı analiz et"), {
            "file_id": doc["file_id"],
            "file_name": doc.get("file_name", "file"),
        }

    if msg.get("voice") or msg.get("audio"):
        return "VOICE", "", {"file_id": (msg.get("voice") or msg.get("audio", {})).get("file_id", "")}

    text = msg.get("text", "")
    return "TEXT", text, {}

def handle_message(msg_type, text, extras):
    """Handle a parsed message."""
    global PROJECT_DIR

    if not text and msg_type == "TEXT":
        return

    log(f"[{msg_type}] {text[:100]}")
    heartbeat("running", f"handling: {text[:50]}")

    # Normalize button texts
    if "Durum" in text:
        text = "/status"
    elif "Projeler" in text:
        text = "/projects"
    elif "Durdur" in text:
        text = "/stop"
    elif "Log" in text:
        text = "/log"

    # Built-in commands
    if text == "/stop":
        tg_send("🔴 Agent durduruluyor.")
        cleanup()
        sys.exit(0)

    elif text == "/status":
        tg_send(f"🟢 *Agent Aktif*\n"
                f"Proje: `{os.path.basename(PROJECT_DIR)}`\n"
                f"Saat: `{datetime.now().strftime('%H:%M:%S')}`\n"
                f"Claude PID: `{claude_proc.pid if claude_proc else 'yok'}`",
                KEYBOARD)
        return

    elif text == "/projects":
        projects_dir = os.path.expanduser("~/Projects")
        dirs = sorted([d for d in os.listdir(projects_dir)
                      if os.path.isdir(os.path.join(projects_dir, d))])[:15]
        tg_send("📁 *Projeler*\n```\n" + "\n".join(dirs) + "\n```", KEYBOARD)
        return

    elif text.startswith("/cd "):
        new = text[4:].strip()
        full = os.path.expanduser(f"~/Projects/{new}")
        if os.path.isdir(full):
            PROJECT_DIR = full
            # Restart claude in new dir
            if claude_proc and claude_proc.poll() is None:
                claude_proc.terminate()
            start_claude()
            tg_send(f"📁 Proje değişti: `{new}`", KEYBOARD)
        else:
            tg_send(f"❌ Bulunamadı: `{new}`", KEYBOARD)
        return

    elif text == "/log":
        try:
            lines = open(LOG_FILE).readlines()[-30:]
            tg_send("📋 *Son 30 satır log:*\n```\n" + "".join(lines) + "```", KEYBOARD)
        except:
            tg_send("📋 Log boş.", KEYBOARD)
        return

    elif text in ("/help", "/start"):
        tg_send("🤖 *Claude Agent Bot*\n\n"
                "Serbest metin → Claude'a iletilir (aynı session)\n"
                "`/status` — Durum\n"
                "`/projects` — Projeler\n"
                "`/cd <proje>` — Proje değiştir\n"
                "`/log` — Loglar\n"
                "`/stop` — Durdur", KEYBOARD)
        return

    # Photo handling
    if msg_type == "PHOTO":
        file_id = extras.get("file_id", "")
        tg_typing()
        tg_send("🖼️ _Resim alındı, analiz ediliyor..._")
        # Download and describe
        prompt = f"[Kullanıcı bir resim gönderdi] {text}"
        result = send_to_claude(prompt)
        send_result(result)
        return

    # Document handling
    if msg_type == "DOC":
        tg_typing()
        fname = extras.get("file_name", "dosya")
        tg_send(f"📄 _Dosya alındı: `{fname}` — işleniyor..._")
        prompt = f"[Kullanıcı '{fname}' dosyası gönderdi] {text}"
        result = send_to_claude(prompt)
        send_result(result)
        return

    # Voice
    if msg_type == "VOICE":
        tg_send("🎤 _Ses mesajı alındı ama henüz desteklenmiyor._", KEYBOARD)
        return

    # Free text → Claude
    tg_typing()
    result = send_to_claude(text)
    send_result(result)

def send_result(result):
    """Send claude result back to Telegram."""
    if len(result) > 3500:
        # Write to temp file and send as document
        tmp = "/tmp/claude-tg-output.txt"
        with open(tmp, "w") as f:
            f.write(result)
        tg_send_file(tmp, f"Çıktı ({len(result)} karakter)")
    else:
        tg_send(f"✅ *Tamamlandı*\n\n```\n{result}\n```", KEYBOARD)

# ── Main loop ───────────────────────────────────────────────────────────────

def cleanup(*args):
    global claude_proc
    log("Kapanıyor...")
    if claude_proc and claude_proc.poll() is None:
        claude_proc.terminate()
        try:
            claude_proc.wait(timeout=5)
        except:
            claude_proc.kill()
    heartbeat("stopped")

signal.signal(signal.SIGTERM, lambda *a: (cleanup(), sys.exit(0)))
signal.signal(signal.SIGINT, lambda *a: (cleanup(), sys.exit(0)))

def main():
    log(f"Telegram Agent başlatılıyor → {PROJECT_DIR}")

    # Start Claude
    start_claude()

    # Skip old messages
    offset = skip_old_messages()

    # Send startup message
    tg_send(f"🟢 *Claude Agent bağlandı*\n"
            f"Proje: `{os.path.basename(PROJECT_DIR)}`\n"
            f"Mesaj yaz → direkt Claude'a gider (aynı session).", KEYBOARD)

    log(f"Polling başladı (offset={offset})")
    heartbeat("running", "polling")

    while True:
        try:
            resp = tg_request("getUpdates", {
                "offset": offset,
                "timeout": 5,
                "allowed_updates": "message,callback_query",
            })

            if not resp or not resp.get("result"):
                continue

            for update in resp["result"]:
                update_id = update["update_id"]
                offset = update_id + 1
                save_offset(offset)

                msg_type, text, extras = parse_update(update)
                if msg_type and text is not None:
                    handle_message(msg_type, text, extras)

            heartbeat("running", "polling")

        except KeyboardInterrupt:
            break
        except Exception as e:
            log(f"Poll error: {e}")
            time.sleep(3)

    cleanup()

if __name__ == "__main__":
    main()
