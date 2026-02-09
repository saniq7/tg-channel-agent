# Настройка Supabase

## Шаг 1: Получить токен доступа

1. Открыть https://app.supabase.com/account/tokens
2. Создать новый токен
3. Сохранить в переменную окружения:
   ```bash
   export SUPABASE_ACCESS_TOKEN="ваш_токен"
   ```

## Шаг 2: Авторизация CLI

```bash
supabase login
```

Или через переменную:
```bash
supabase projects list  # проверка что работает
```

## Шаг 3: Связать с проектом

```bash
cd /path/to/tg-channel-agent

# Посмотреть список проектов
supabase projects list

# Связать (нужен project-ref)
supabase link --project-ref <project-ref>
```

## Шаг 4: Выполнить миграции

```bash
# Применить все миграции
supabase db push

# Или через SQL Editor в dashboard:
# Скопировать содержимое supabase/migrations/*.sql
```

## Альтернатива: через SQL Editor

Если CLI не нужен, можно выполнить SQL напрямую:

1. Открыть Supabase Dashboard → SQL Editor
2. Скопировать `supabase/migrations/001_initial_schema.sql`
3. Выполнить
4. Скопировать `supabase/migrations/002_rpc_functions.sql`
5. Выполнить

## Проверка

После выполнения миграций:

```sql
-- Проверить таблицы
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public';

-- Проверить что vector extension включен
SELECT * FROM pg_extension WHERE extname = 'vector';

-- Проверить RPC функции
SELECT routine_name FROM information_schema.routines 
WHERE routine_schema = 'public' AND routine_type = 'FUNCTION';
```
