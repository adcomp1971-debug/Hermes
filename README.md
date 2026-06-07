# Hermes Box 🧠🌱

**Self-hosted AI for your office. Private. Local. Yours.**

Hermes Box — это Docker-стек, который даёт вашему офису собственный AI-ассистент. Без облаков, без утечек данных, без $20/чел/мес.

## Что внутри

```
┌─────────────────────────────────────┐
│  open-webui  ──►  ollama  ──► GPU   │  Чат-интерфейс
│      │                              │
│      ▼                              │
│  Hermes Agent (оркестратор)         │  Telegram бот + API
│      │                              │
│      ▼                              │
│  RAG (чат по документам)            │  Ответы на основе ваших файлов
│      │                              │
│      ▼                              │
│  Tailscale (VPN)                     │  Доступ из любого места
└─────────────────────────────────────┘
```

- **Ollama** — LLM-инференс (локально, GPU или CPU)
- **Open WebUI** — веб-чат для всей команды
- **Hermes Agent** — API + Telegram-бот с allowlist
- **RAG** — чат по вашим документам (txt, md, pdf)
- **Tailscale** — VPN-доступ без открытых портов

## Быстрый старт

```bash
git clone https://github.com/adcomp1971-debug/Hermes
cd Hermes
./setup.sh

# Скачать модель
docker exec hermes-ollama ollama pull qwen2.5:7b

# Скачать эмбеддинги для RAG
docker exec hermes-ollama ollama pull nomic-embed-text

# Залить документы и проиндексировать
cp my-docs/*.pdf documents/
curl -X POST http://localhost:8002/ingest
```

Открой `http://localhost:3000` — чат готов.

## Требования

| Компонент | Минимум | Рекомендуется |
|-----------|---------|---------------|
| CPU | 4 ядра | 8+ ядер |
| RAM | 8 GB | 16+ GB |
| GPU (опц.) | — | NVIDIA |
| Docker | 24+ | 24+ |
| ОС | Linux | Linux |

Без GPU работает на CPU, но медленнее. Стоимость зависит от того, какое железо уже есть у клиента.

## RAG: чат по вашим документам

Кидайте PDF, txt, md в `./documents/`, запустите индексацию — и AI отвечает на вопросы на основе этих документов, указывая источник.

```bash
curl -X POST http://localhost:8002/ingest
curl -X POST http://localhost:8002/query \
  -H "Content-Type: application/json" \
  -d '{"question": "Что написано в договоре о сроках?"}'
```

## Telegram-бот

Укажите в `.env`:
```
TELEGRAM_BOT_TOKEN=123456:ABC-DEF...
ALLOWED_TELEGRAM_IDS=123456789,987654321
```

Бот ответит только пользователям из списка. Пустой список = бот никому не отвечает.

## Структура

```
├── docker-compose.yml     # 5 сервисов
├── setup.sh               # Установка в 1 команду
├── config/
│   └── hermes.yaml        # Конфиг агента
├── hermes-agent/          # Оркестратор (FastAPI)
│   ├── app.py
│   └── Dockerfile
├── rag/                   # RAG-сервис
│   ├── app.py
│   └── Dockerfile
└── documents/             # Ваши документы
```

## Профили

| Профиль | GPU | Когда использовать |
|---------|-----|-------------------|
| `basic` | Нет | CPU-сервер, тесты |
| `gpu`   | Да | Офис с NVIDIA GPU |
| `full`  | Да | Полный стек + VPN |

Выбираются автоматически `setup.sh`, либо `docker compose --profile gpu up -d`.

## Лицензия

MIT. Делайте что хотите.
