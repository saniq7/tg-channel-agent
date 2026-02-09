-- TG Channel Agent: RPC функции для semantic search
-- Дата: 2026-02-09

-- Семантический поиск референсов
CREATE OR REPLACE FUNCTION match_refs(
    query_embedding vector(1536),
    match_count INT DEFAULT 5,
    match_threshold FLOAT DEFAULT 0.7
) RETURNS TABLE (
    id UUID,
    text TEXT,
    source_channel TEXT,
    tags TEXT[],
    notes TEXT,
    similarity FLOAT
) AS $$
    SELECT 
        r.id, 
        r.text, 
        r.source_channel, 
        r.tags,
        r.notes,
        1 - (r.embedding <=> query_embedding) as similarity
    FROM refs r
    WHERE r.embedding IS NOT NULL
      AND 1 - (r.embedding <=> query_embedding) > match_threshold
    ORDER BY r.embedding <=> query_embedding
    LIMIT match_count;
$$ LANGUAGE sql STABLE;

-- Семантический поиск идей
CREATE OR REPLACE FUNCTION match_ideas(
    query_embedding vector(1536),
    match_count INT DEFAULT 5,
    match_threshold FLOAT DEFAULT 0.7,
    status_filter TEXT DEFAULT NULL
) RETURNS TABLE (
    id UUID,
    text TEXT,
    source TEXT,
    status TEXT,
    similarity FLOAT
) AS $$
    SELECT 
        i.id, 
        i.text, 
        i.source, 
        i.status,
        1 - (i.embedding <=> query_embedding) as similarity
    FROM ideas i
    WHERE i.embedding IS NOT NULL
      AND 1 - (i.embedding <=> query_embedding) > match_threshold
      AND (status_filter IS NULL OR i.status = status_filter)
    ORDER BY i.embedding <=> query_embedding
    LIMIT match_count;
$$ LANGUAGE sql STABLE;

-- Семантический поиск постов
CREATE OR REPLACE FUNCTION match_posts(
    query_embedding vector(1536),
    match_count INT DEFAULT 5,
    match_threshold FLOAT DEFAULT 0.7
) RETURNS TABLE (
    id UUID,
    text TEXT,
    status TEXT,
    published_at TIMESTAMPTZ,
    similarity FLOAT
) AS $$
    SELECT 
        p.id, 
        p.text, 
        p.status,
        p.published_at,
        1 - (p.embedding <=> query_embedding) as similarity
    FROM posts p
    WHERE p.embedding IS NOT NULL
      AND 1 - (p.embedding <=> query_embedding) > match_threshold
    ORDER BY p.embedding <=> query_embedding
    LIMIT match_count;
$$ LANGUAGE sql STABLE;

-- Семантический поиск терминов
CREATE OR REPLACE FUNCTION match_terms(
    query_embedding vector(1536),
    match_count INT DEFAULT 5,
    match_threshold FLOAT DEFAULT 0.7
) RETURNS TABLE (
    id UUID,
    term TEXT,
    definition TEXT,
    usage_examples TEXT[],
    similarity FLOAT
) AS $$
    SELECT 
        t.id, 
        t.term, 
        t.definition,
        t.usage_examples,
        1 - (t.embedding <=> query_embedding) as similarity
    FROM terms t
    WHERE t.embedding IS NOT NULL
      AND 1 - (t.embedding <=> query_embedding) > match_threshold
    ORDER BY t.embedding <=> query_embedding
    LIMIT match_count;
$$ LANGUAGE sql STABLE;

-- Семантический поиск правил
CREATE OR REPLACE FUNCTION match_rules(
    query_embedding vector(1536),
    match_count INT DEFAULT 10,
    match_threshold FLOAT DEFAULT 0.6,
    category_filter TEXT DEFAULT NULL
) RETURNS TABLE (
    id UUID,
    category TEXT,
    rule TEXT,
    priority INT,
    similarity FLOAT
) AS $$
    SELECT 
        r.id, 
        r.category, 
        r.rule,
        r.priority,
        1 - (r.embedding <=> query_embedding) as similarity
    FROM rules r
    WHERE r.embedding IS NOT NULL
      AND r.active = true
      AND 1 - (r.embedding <=> query_embedding) > match_threshold
      AND (category_filter IS NULL OR r.category = category_filter)
    ORDER BY r.embedding <=> query_embedding
    LIMIT match_count;
$$ LANGUAGE sql STABLE;

-- Комбинированный поиск по всем источникам для RAG
CREATE OR REPLACE FUNCTION rag_search(
    query_embedding vector(1536),
    refs_count INT DEFAULT 3,
    ideas_count INT DEFAULT 2,
    posts_count INT DEFAULT 2,
    match_threshold FLOAT DEFAULT 0.6
) RETURNS TABLE (
    source_type TEXT,
    id UUID,
    text TEXT,
    metadata JSONB,
    similarity FLOAT
) AS $$
    -- Референсы
    SELECT 
        'ref'::TEXT as source_type,
        r.id,
        r.text,
        jsonb_build_object('channel', r.source_channel, 'tags', r.tags) as metadata,
        1 - (r.embedding <=> query_embedding) as similarity
    FROM refs r
    WHERE r.embedding IS NOT NULL
      AND 1 - (r.embedding <=> query_embedding) > match_threshold
    ORDER BY r.embedding <=> query_embedding
    LIMIT refs_count
    
    UNION ALL
    
    -- Идеи
    SELECT 
        'idea'::TEXT,
        i.id,
        i.text,
        jsonb_build_object('source', i.source, 'status', i.status) as metadata,
        1 - (i.embedding <=> query_embedding)
    FROM ideas i
    WHERE i.embedding IS NOT NULL
      AND 1 - (i.embedding <=> query_embedding) > match_threshold
    ORDER BY i.embedding <=> query_embedding
    LIMIT ideas_count
    
    UNION ALL
    
    -- Посты
    SELECT 
        'post'::TEXT,
        p.id,
        p.text,
        jsonb_build_object('status', p.status, 'published_at', p.published_at) as metadata,
        1 - (p.embedding <=> query_embedding)
    FROM posts p
    WHERE p.embedding IS NOT NULL
      AND p.status = 'published'
      AND 1 - (p.embedding <=> query_embedding) > match_threshold
    ORDER BY p.embedding <=> query_embedding
    LIMIT posts_count
    
    ORDER BY similarity DESC;
$$ LANGUAGE sql STABLE;
