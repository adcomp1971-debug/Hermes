# Hermes Box — что изменено и почему

## Исправлено (ломало запуск)
1. **Несуществующие образы** `hermes-agent/hermes` и `hermes-agent/guardrails`
   заменены на реальные `build:`-контексты (`./hermes-agent`, `./rag`).
   Раньше `docker pull` падал у всех — стек не стартовал в принципе.
2. **Сломанный Ollama healthcheck** (`curl / → 404`) из-за которого open-webui
   с `condition: service_healthy` висел вечно. Заменён на проверку через
   `ollama --version`.
3. Удалена устаревшая строка `version: "3.9"` (Compose v2 ругается).

## Безопасность (дискредитировало security-позиционирование)
4. **Убран `/var/run/docker.sock`** из агента. Даже `:ro` это полный root
   над хостом — недопустимо для продукта про приватность.
5. **`WEBUI_SECRET_KEY`** больше нельзя оставить как `change-me`:
   compose требует значение (`:?`), setup.sh генерирует через `openssl rand`.
6. Tailscale: убран `SYS_MODULE`, добавлен `TS_USERSPACE=true`.

## Добавлено (без этого продукт был пустым)
7. **Реальный агент** (`hermes-agent/app.py`): FastAPI + /health + /chat,
   Telegram-бот с обязательным allowlist по ID (пустой список = отказ всем).
8. **RAG-сервис** (`rag/app.py`) — чат по своим документам, полностью локально.
   Это и есть причина брать self-hosted AI. txt/md/pdf → эмбеддинги через
   Ollama → косинусный поиск → grounded-ответ с указанием источника.
   Без внешней векторной БД (numpy на диске) — едет на офисном железе.

## Убрано
9. Фейковый `dashboard` (nginx, отдававший скриншоты) — создавал ложное
   впечатление мониторинга.
10. `guardrails` как отдельный заявленный сервис — PII-regex это не защита.
    Не обещаем то, за что не можем отвечать.
11. Enterprise/H100-тир — нереалистичен для соло-поддержки.

## Как поднять
```
./setup.sh
docker exec hermes-ollama ollama pull qwen2.5:7b
docker exec hermes-ollama ollama pull nomic-embed-text
# положить документы в ./documents/, затем:
curl -X POST http://localhost:8002/ingest
```
