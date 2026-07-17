import json
import os
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timedelta, timezone
from pathlib import Path

MOSCOW_TZ = timezone(timedelta(hours=3))

REMINDER_HOURS = (9, 12, 15, 18)

WINDOW_MINUTES = 45
DEDUP_FILE = Path(__file__).resolve().parent.parent / ".last-reminder"


def load_message() -> str:
    default = "VKLYUCHI SROCHNYE ZAKAZY"
    message_path = Path(__file__).resolve().parent.parent / "message.txt"

    if message_path.exists():
        text = message_path.read_text(encoding="utf-8").strip()
        if text:
            return text

    return os.environ.get("REMINDER_MESSAGE", default)


def should_send_now(now: datetime, last_sent_key: str | None) -> str | None:
    if now.hour not in REMINDER_HOURS or now.minute > WINDOW_MINUTES:
        return None

    sent_key = f"{now.strftime('%Y-%m-%d')}-{now.hour}"
    if sent_key == last_sent_key:
        return None

    return sent_key


def load_last_sent() -> str | None:
    if not DEDUP_FILE.exists():
        return None

    try:
        data = json.loads(DEDUP_FILE.read_text(encoding="utf-8"))
        return data.get("last_sent_key")
    except (json.JSONDecodeError, OSError):
        return None


def save_last_sent(key: str) -> None:
    DEDUP_FILE.write_text(
        json.dumps({"last_sent_key": key}, ensure_ascii=False),
        encoding="utf-8",
    )


def send_telegram_message(token: str, chat_id: str, message: str) -> None:
    url = f"https://api.telegram.org/bot{token}/sendMessage"
    payload = urllib.parse.urlencode(
        {"chat_id": chat_id, "text": message}
    ).encode("utf-8")

    request = urllib.request.Request(url, data=payload, method="POST")

    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            result = json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        raise SystemExit(f"Telegram API error: {body}") from exc

    if not result.get("ok"):
        raise SystemExit(f"Telegram API returned error: {result}")


def main() -> None:
    token = os.environ.get("TELEGRAM_BOT_TOKEN", "").strip()
    chat_id = os.environ.get("TELEGRAM_CHAT_ID", "").strip()

    if not token or not chat_id:
        raise SystemExit("TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID are required.")

    now = datetime.now(MOSCOW_TZ)

    if os.environ.get("FORCE_SEND", "").lower() in ("1", "true", "yes"):
        message = load_message()
        send_telegram_message(token, chat_id, message)
        save_last_sent(f"{now.strftime('%Y-%m-%d')}-{now.hour}")
        print(f"Force-sent reminder at {now.strftime('%Y-%m-%d %H:%M')} MSK.")
        return

    last_sent = load_last_sent()
    sent_key = should_send_now(now, last_sent)

    if not sent_key:
        print(
            f"Not reminder time or already sent. "
            f"Now: {now.strftime('%Y-%m-%d %H:%M')} MSK, last_sent: {last_sent}."
        )
        return

    message = load_message()
    send_telegram_message(token, chat_id, message)
    save_last_sent(sent_key)
    print(f"Reminder sent at {now.strftime('%Y-%m-%d %H:%M')} MSK (key={sent_key}).")


if __name__ == "__main__":
    main()
