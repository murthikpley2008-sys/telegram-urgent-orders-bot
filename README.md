# Telegram Urgent Orders Bot

Бот-напоминалка, который отправляет сообщение **«ВКЛЮЧИ СРОЧНЫЕ ЗАКАЗЫ»** в Telegram по расписанию.

## Расписание

| Время (МСК) | Cron (UTC) |
|-------------|------------|
| 09:00 | 06:00 |
| 12:00 | 09:00 |
| 15:00 | 12:00 |
| 18:00 | 15:00 |

## Как это работает

Бот запускается через **GitHub Actions** — работает **24/7**, даже когда ПК выключен.

При наступлении расписания GitHub Actions запускает скрипт `cloud/send_reminder.py`, который отправляет сообщение в Telegram через API.

## Структура проекта

```
├── .github/workflows/reminders.yml   # Расписание GitHub Actions
├── cloud/send_reminder.py            # Скрипт отправки (stdlib only, без зависимостей)
├── message.txt                       # Текст напоминания
├── bot.py                            # Python-бот (локальный запуск)
├── run-bot.ps1                       # PowerShell-бот (локальный запуск)
├── requirements.txt                  # Зависимости для bot.py
└── .env.example                      # Шаблон переменных окружения
```

## Быстрый старт

### 1. Создайте бота в BotFather

1. Откройте [@BotFather](https://t.me/BotFather) в Telegram
2. Отправьте `/newbot`
3. Задайте имя и username
4. Скопируйте полученный **токен**

### 2. Узнайте свой Chat ID

1. Откройте [@userinfobot](https://t.me/userinfobot) в Telegram
2. Отправьте любое сообщение
3. Скопируйте ваш **Id** (число)

### 3. Настройте GitHub Secrets

В репозитории: **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

| Имя секрета | Значение |
|-------------|----------|
| `TELEGRAM_BOT_TOKEN` | Токен от BotFather |
| `TELEGRAM_CHAT_ID` | Ваш Chat ID |

### 4. Включите workflow

**Actions** → **Telegram reminders** → **Enable workflows** → **Run workflow**

## Изменение текста сообщения

Отредактируйте файл `message.txt` и закоммитьте изменения — GitHub Actions автоматически подхватит новый текст.

## Нюансы

- **Задержка GitHub Actions:** cron может сработать с опозданием 5–15 минут — это нормально.
- **Неактивный репозиторий:** если 60 дней не было коммитов, расписание отключается. Делайте коммит раз в пару месяцев или запускайте workflow вручную.
- **Private repo:** на бесплатном аккаунте есть лимит минут Actions — для 4 сообщений в день этого более чем достаточно.
