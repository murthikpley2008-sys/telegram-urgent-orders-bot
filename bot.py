import json
import logging
import os
from pathlib import Path

from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
from dotenv import load_dotenv
from telegram import Update
from telegram.ext import Application, CommandHandler, ContextTypes
from zoneinfo import ZoneInfo

load_dotenv()

BOT_TOKEN = os.getenv("BOT_TOKEN")
TIMEZONE = os.getenv("TIMEZONE", "Europe/Moscow")
CHAT_ID_FILE = Path("chat_id.json")
MESSAGE = "ВКЛЮЧИ СРОЧНЫЕ ЗАКАЗЫ"
REMINDER_HOURS = (9, 12, 15, 18)

logging.basicConfig(
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
    level=logging.INFO,
)
logger = logging.getLogger(__name__)


def load_chat_id() -> int | None:
    if CHAT_ID_FILE.exists():
        data = json.loads(CHAT_ID_FILE.read_text(encoding="utf-8"))
        return data.get("chat_id")

    env_id = os.getenv("CHAT_ID")
    return int(env_id) if env_id else None


def save_chat_id(chat_id: int) -> None:
    CHAT_ID_FILE.write_text(
        json.dumps({"chat_id": chat_id}, ensure_ascii=False),
        encoding="utf-8",
    )


async def start(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    chat_id = update.effective_chat.id
    save_chat_id(chat_id)
    await update.message.reply_text(
        "Готово! Буду напоминать каждые 3 часа с 9:00 до 19:00:\n"
        "9:00, 12:00, 15:00, 18:00\n\n"
        f"Ваш chat_id: {chat_id}"
    )


async def send_reminder(application: Application) -> None:
    chat_id = load_chat_id()
    if not chat_id:
        logger.warning("Chat ID not set. Send /start to the bot first.")
        return

    await application.bot.send_message(chat_id=chat_id, text=MESSAGE)
    logger.info("Reminder sent to chat_id=%s", chat_id)


def setup_scheduler(application: Application) -> AsyncIOScheduler:
    tz = ZoneInfo(TIMEZONE)
    scheduler = AsyncIOScheduler(timezone=tz)

    for hour in REMINDER_HOURS:
        scheduler.add_job(
            send_reminder,
            CronTrigger(hour=hour, minute=0, timezone=tz),
            args=[application],
            id=f"reminder_{hour}",
            replace_existing=True,
        )

    return scheduler


def main() -> None:
    if not BOT_TOKEN:
        raise SystemExit("Set BOT_TOKEN in .env file")

    application = Application.builder().token(BOT_TOKEN).build()
    application.add_handler(CommandHandler("start", start))

    scheduler = setup_scheduler(application)

    async def post_init(app: Application) -> None:
        scheduler.start()
        logger.info(
            "Scheduler started. Reminders at %s (%s)",
            ", ".join(f"{h}:00" for h in REMINDER_HOURS),
            TIMEZONE,
        )

    application.post_init = post_init
    application.run_polling()


if __name__ == "__main__":
    main()
