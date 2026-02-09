# Архитектура TG Channel Agent

## Обзор

```
Telegram Bot → n8n Workflows → LLM (Claude) + RAG (Supabase/pgvector) → Response
```

## Компоненты

### Telegram Bot
- Команды: /ref, /idea, /write, /edit, /check
- Webhook в n8n

### n8n Workflows
- Refs Pipeline: сохранение референсов
- Ideas Pipeline: сохранение идей
- Write Pipeline: генерация постов с RAG
- Edit Pipeline: итеративная редактура
- Check Pipeline: финальные проверки

### Supabase
- 6 таблиц: refs, ideas, posts, terms, rules, sessions
- pgvector для semantic search
- RPC функции для RAG

### GitHub
- /prompts — системные промпты
- /rules — правила в YAML
- Синхронизация в Supabase для runtime

## Схема данных

См. файл проекта: `/projects/tg-channel-agent.md`
