-- TG Channel Agent: Начальная схема данных
-- Дата: 2026-02-09

-- Включить pgvector (если не включен)
CREATE EXTENSION IF NOT EXISTS vector;

-- Референсы (чужие посты)
CREATE TABLE refs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    source_channel TEXT,           -- откуда форвард
    source_message_id BIGINT,      -- id сообщения
    text TEXT NOT NULL,            -- текст поста
    author TEXT,                   -- автор (если известен)
    tags TEXT[],                   -- теги для фильтрации
    embedding vector(1536),        -- OpenAI embedding
    notes TEXT,                    -- мои заметки
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Идеи (сырые мысли)
CREATE TABLE ideas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    text TEXT NOT NULL,            -- текст идеи
    source TEXT,                   -- откуда: voice, text, forward
    status TEXT DEFAULT 'raw',     -- raw → in_progress → used → archived
    embedding vector(1536),
    related_refs UUID[],           -- связанные референсы
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Мои посты (история)
CREATE TABLE posts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    text TEXT NOT NULL,            -- финальный текст
    telegram_message_id BIGINT,    -- id в канале (после публикации)
    status TEXT DEFAULT 'draft',   -- draft → review → published
    source_idea_id UUID REFERENCES ideas(id),
    embedding vector(1536),
    stats JSONB,                   -- views, reactions (если тянуть)
    published_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Словарь терминов
CREATE TABLE terms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    term TEXT NOT NULL UNIQUE,     -- термин
    definition TEXT NOT NULL,      -- определение
    usage_examples TEXT[],         -- примеры использования
    avoid TEXT[],                  -- чего избегать
    embedding vector(1536),
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Правила стиля (быстро доступные)
CREATE TABLE rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    category TEXT NOT NULL,        -- structure, tone, formatting, anti-patterns
    rule TEXT NOT NULL,            -- текст правила
    priority INT DEFAULT 0,        -- вес при применении
    active BOOLEAN DEFAULT true,
    embedding vector(1536),        -- для контекстного поиска правил
    git_ref TEXT,                  -- ссылка на файл в git (если есть)
    created_at TIMESTAMPTZ DEFAULT now()
);

-- Сессии редактуры
CREATE TABLE sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    post_id UUID REFERENCES posts(id),
    idea_id UUID REFERENCES ideas(id),
    state JSONB NOT NULL,          -- текущее состояние диалога
    history JSONB[],               -- история итераций
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now()
);

-- Лог версий промптов (аудит)
CREATE TABLE prompt_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    file_path TEXT NOT NULL,       -- prompts/system/writer.md
    git_sha TEXT NOT NULL,         -- commit hash
    content TEXT NOT NULL,         -- полный текст
    synced_at TIMESTAMPTZ DEFAULT now()
);

-- Индексы для vector search
-- Используем HNSW для лучшей производительности (альтернатива ivfflat)
CREATE INDEX refs_embedding_idx ON refs 
    USING hnsw (embedding vector_cosine_ops);
CREATE INDEX ideas_embedding_idx ON ideas 
    USING hnsw (embedding vector_cosine_ops);
CREATE INDEX posts_embedding_idx ON posts 
    USING hnsw (embedding vector_cosine_ops);
CREATE INDEX terms_embedding_idx ON terms 
    USING hnsw (embedding vector_cosine_ops);
CREATE INDEX rules_embedding_idx ON rules 
    USING hnsw (embedding vector_cosine_ops);

-- Дополнительные индексы
CREATE INDEX refs_tags_idx ON refs USING gin(tags);
CREATE INDEX ideas_status_idx ON ideas(status);
CREATE INDEX posts_status_idx ON posts(status);
CREATE INDEX rules_category_idx ON rules(category);
CREATE INDEX rules_active_idx ON rules(active);
