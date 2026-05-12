-- ============================================================
-- UTPL_INGRESO_LEAD - Schema requerido
-- Agrega id_negocio como columna UNIQUE a utpl_registros
-- para que el flujo UTPL_INGRESO_LEAD pueda hacer upsert
-- ============================================================

-- 1. Agregar columna id_negocio
ALTER TABLE public.utpl_registros
ADD COLUMN IF NOT EXISTS id_negocio VARCHAR(100);

-- 2. Agregar constraint UNIQUE para el upsert
ALTER TABLE public.utpl_registros
ADD CONSTRAINT utpl_registros_id_negocio_unique UNIQUE (id_negocio);

-- 3. Indice para busquedas por id_negocio
CREATE INDEX IF NOT EXISTS idx_utpl_registros_id_negocio
ON public.utpl_registros (id_negocio);
