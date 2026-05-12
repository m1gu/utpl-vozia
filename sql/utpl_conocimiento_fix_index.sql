-- ============================================================
-- UTPL - Fix RAG index para pocos datos
-- ============================================================

-- 1. Eliminar el indice ivfflat que no funciona con pocos datos
DROP INDEX IF EXISTS idx_conocimiento_embedding;

-- 2. La busqueda exacta con el operador <=> funciona sin indice
--    Con 173 chunks es instantaneo. Recrear indice cuando haya 1000+ filas.
--    Para recrear en el futuro:
--    CREATE INDEX idx_conocimiento_embedding ON utpl_conocimiento 
--        USING ivfflat (embedding vector_cosine_ops) WITH (lists = 10);
