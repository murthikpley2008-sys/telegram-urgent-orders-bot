# Запуск бота в облаке через GitHub Actions

Бот будет отправлять напоминания **«ВКЛЮЧИ СРОЧНЫЕ ЗАКАЗЫ»** в **9:00, 12:00, 15:00, 18:00** по Москве — даже когда ваш ПК выключен.

GitHub Actions запускает скрипт по расписанию на своих серверах.

---

## Шаг 1. Подготовка (на вашем ПК)

У вас уже есть:
- токен бота (`config.json` или `bot-token.txt`)
- ваш Chat ID (`config.json`)
- текст сообщения (`message.txt`)

Узнать значения для GitHub Secrets:

```powershell
.\show-github-secrets.bat
```

Или откройте `config.json` и скопируйте:
- `botToken` → секрет **TELEGRAM_BOT_TOKEN**
- `chatId` → секрет **TELEGRAM_CHAT_ID**

---

## Шаг 2. Создайте репозиторий на GitHub

1. Откройте https://github.com/new
2. **Repository name:** `telegram-urgent-orders-bot` (или любое имя)
3. **Public** или **Private** — оба варианта работают
4. **Не** ставьте галочки README / .gitignore / license (файлы уже есть локально)
5. Нажмите **Create repository**

---

## Шаг 3. Загрузите код на GitHub

### Вариант A — автоматически (скрипт)

В папке проекта запустите:

```powershell
.\deploy-github.ps1
```

Скрипт инициализирует git, сделает первый коммит и подскажет команды для push.

### Вариант B — вручную

```powershell
cd C:\Users\murth_yp24zx8\Projects\telegram-urgent-orders-bot

git init
git add .
git commit -m "Initial commit: Telegram reminder bot with GitHub Actions"
git branch -M main
git remote add origin https://github.com/ВАШ_ЛОГИН/telegram-urgent-orders-bot.git
git push -u origin main
```

> **Важно:** `config.json`, `bot-token.txt`, `.env` в `.gitignore` — токены **не попадут** в репозиторий.

---

## Шаг 4. Добавьте секреты в GitHub

1. Откройте репозиторий на GitHub
2. **Settings** → **Secrets and variables** → **Actions**
3. **New repository secret**

| Имя секрета | Значение |
|-------------|----------|
| `TELEGRAM_BOT_TOKEN` | токен из BotFather |
| `TELEGRAM_CHAT_ID` | ваш chat id (число) |

---

## Шаг 5. Проверьте, что workflow включён

1. Вкладка **Actions**
2. Слева: **Telegram reminders**
3. Если спрашивает «Enable workflows» — нажмите **Enable**

---

## Шаг 6. Тестовый запуск

1. **Actions** → **Telegram reminders**
2. **Run workflow** → **Run workflow**
3. Через 10–30 секунд откройте последний run — должно быть зелёное ✓
4. В Telegram должно прийти сообщение **«ВКЛЮЧИ СРОЧНЫЕ ЗАКАЗЫ»**

---

## Расписание (Москва)

| Время (MSK) | Cron (UTC) |
|-------------|------------|
| 09:00 | 06:00 |
| 12:00 | 09:00 |
| 15:00 | 12:00 |
| 18:00 | 15:00 |

Файл: `.github/workflows/reminders.yml`

---

## Отключите локальный бот (чтобы не было дублей)

Если бот запущен на ПК **и** в GitHub — сообщения придут дважды.

```powershell
.\stop.bat
```

Или удалите задачу автозапуска:

```powershell
.\uninstall-scheduler.ps1
```

---

## Важные нюансы GitHub Actions

1. **Задержка:** cron может сработать с опозданием 5–15 минут — это нормально для GitHub.
2. **Неактивный репозиторий:** если 60 дней не было коммитов, расписание отключается. Раз в пару месяцев сделайте любой коммит или вручную запустите workflow.
3. **Private repo:** на бесплатном акунте лимит минут Actions — для 4 сообщений в день этого более чем достаточно.

---

## Структура облачной части

```
.github/workflows/reminders.yml   ← расписание GitHub Actions
cloud/send_reminder.py            ← отправка в Telegram
message.txt                       ← текст напоминания
```

---

## Если что-то не работает

| Проблема | Решение |
|----------|---------|
| Workflow не запускается | Actions → Enable workflows |
| Ошибка «TELEGRAM_BOT_TOKEN required» | Проверьте секреты в Settings → Secrets |
| Сообщение не приходит | Запустите workflow вручную, смотрите лог run |
| Два сообщения сразу | Остановите локальный бот (`stop.bat`) |
| Неверное время | Cron в UTC; Москва = UTC+3 |
