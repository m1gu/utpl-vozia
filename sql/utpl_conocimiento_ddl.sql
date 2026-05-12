-- ============================================================
-- UTPL - Base de Conocimiento RAG (pgvector + FTS hibrido)
-- ============================================================

-- 1. Extension pgvector
CREATE EXTENSION IF NOT EXISTS vector;

-- 2. Tabla de conocimiento
CREATE TABLE IF NOT EXISTS utpl_conocimiento (
    id BIGSERIAL PRIMARY KEY,
    modalidad VARCHAR(50) NOT NULL,     -- MODALIDAD EN LINEA, POSGRADO, TECNOLOGICO, general
    fuente VARCHAR(255),                -- nombre del archivo .docx
    titulo VARCHAR(500),                -- titulo del chunk/seccion
    contenido TEXT NOT NULL,            -- texto del chunk
    embedding vector(1536),             -- OpenAI text-embedding-3-small
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Indices
CREATE INDEX IF NOT EXISTS idx_conocimiento_modalidad ON utpl_conocimiento(modalidad);
CREATE INDEX IF NOT EXISTS idx_conocimiento_embedding
    ON utpl_conocimiento USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

-- 4. Funcion de busqueda hibrida (pgvector + texto)
CREATE OR REPLACE FUNCTION buscar_conocimiento_utpl(
    query_embedding vector(1536),
    p_modalidad VARCHAR DEFAULT NULL,
    p_limit INT DEFAULT 3
)
RETURNS TABLE(
    id BIGINT,
    titulo VARCHAR,
    contenido TEXT,
    fuente VARCHAR,
    similitud FLOAT
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        c.id,
        c.titulo,
        c.contenido,
        c.fuente,
        (1 - (c.embedding <=> query_embedding))::FLOAT AS similitud
    FROM utpl_conocimiento c
    WHERE (p_modalidad IS NULL OR c.modalidad = p_modalidad OR c.modalidad = 'general')
      AND c.embedding IS NOT NULL
    ORDER BY c.embedding <=> query_embedding
    LIMIT p_limit;
END;
$$;
