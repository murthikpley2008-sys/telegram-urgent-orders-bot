import json
import os
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path


def load_message() -> str:
    default = "VKLYUCHI SROCHNYE ZAKAZY"
    message_path = Path(__file__).resolve().parent.parent / "message.txt"

    if message_path.exists():
        text = message_path.read_text(encoding="utf-8").strip()
        if text:
            return text

    return os.environ.get("REMINDER_MESSAGE", default)


def main() -> None:
    token = os.environ.get("TELEGRAM_BOT_TOKEN", "").strip()
    chat_id = os.environ.get("TELEGRAM_CHAT_ID", "").strip()

    if not token or not chat_id:
        raise SystemExit("TELEGRAM_BOT_TOKEN and TELEGRAM_CHAT_ID are required.")

    message = load_message()
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

    print("Reminder sent successfully.")


if __name__ == "__main__":
    main()
